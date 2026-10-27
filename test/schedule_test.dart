import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tartil/core/cycle.dart';
import 'package:tartil/core/schedule.dart';
import 'package:tartil/core/stats.dart';
import 'package:tartil/data/quran_data.dart';

void main() {
  final quran = QuranData.parse(File('assets/quran/quran.json').readAsStringSync());

  List<String> keysOf(List<List<Unit>> plan) =>
      [for (final d in plan) for (final u in d) if (!u.review) u.key];

  /// Semua ayat dalam rentang tercakup tepat sekali.
  void expectFullCoverage(List<SurahDurations> surahs, List<List<Unit>> plan) {
    final seen = <String>{};
    for (final d in plan) {
      for (final u in d.where((u) => !u.review)) {
        for (var a = u.fromAyah; a <= u.toAyah; a++) {
          expect(seen.add('${u.surah}:$a'), isTrue, reason: 'ganda ${u.surah}:$a');
        }
      }
    }
    final want = {
      for (final s in surahs)
        for (var a = s.firstAyah; a <= s.lastAyah; a++) '${s.surah}:$a',
    };
    expect(seen, want);
  }

  double spread(List<List<Unit>> plan) {
    final loads = [for (final d in plan) dayLoad(d)];
    final mean = loads.reduce((a, b) => a + b) / loads.length;
    return loads.map((l) => (l - mean).abs() / mean).reduce((a, b) => a > b ? a : b);
  }

  test('juz 29-30 dalam 12 hari: lengkap, seimbang, surah utuh', () {
    final surahs = quran.durations(const HafalanRange.juz([29, 30]));
    expect(surahs.first.surah, 67);
    expect(surahs.last.surah, 114);
    final plan = planCycle(surahs, 12);
    expect(plan.length, 12);
    expectFullCoverage(surahs, plan);
    expect(plan.every((d) => d.isNotEmpty), isTrue);
    // Tidak ada surah yang perlu dipotong di juz 29-30 untuk 12 hari.
    expect(keysOf(plan).length, surahs.length);
    expect(spread(plan), lessThan(0.10), reason: 'beban harian beda >10%');
    for (final d in plan) {
      final mins = (dayLoad(d) / 60).toStringAsFixed(1);
      // ignore: avoid_print
      print('$mins mnt: ${d.map((u) => u.surah).join(", ")}');
    }
  });

  test('juz 30 dalam 30 hari memotong surah bila terpaksa', () {
    final surahs = quran.durations(const HafalanRange.juz([30]));
    final plan = planCycle(surahs, 30);
    expectFullCoverage(surahs, plan);
    expect(plan.every((d) => d.isNotEmpty), isTrue);
  });

  test('surah panjang dipotong, potongan berurutan antar hari', () {
    final surahs = quran.durations(const HafalanRange.surah(1, 2));
    final plan = planCycle(surahs, 10);
    expectFullCoverage(surahs, plan);
    expect(spread(plan), lessThan(0.25));
    var lastFrom = 0;
    for (final d in plan) {
      for (final u in d.where((u) => u.surah == 2)) {
        expect(u.fromAyah, greaterThan(lastFrom));
        lastFrom = u.fromAyah;
      }
    }
  });

  test('rentang juz yang memotong surah (juz 27)', () {
    final surahs = quran.durations(const HafalanRange.juz([27]));
    expect(surahs.first.surah, 51);
    expect(surahs.first.firstAyah, 31);
    final plan = planCycle(surahs, 7);
    expectFullCoverage(surahs, plan);
  });

  test('hari terlewat dihitung ulang dan tetap selesai dalam siklus', () {
    final surahs = quran.durations(const HafalanRange.juz([29, 30]));
    final start = DateTime(2026, 11, 1);
    var cycle = Cycle.create(surahs, 12, start);
    cycle.days[0].doneAt = start;
    // Hari ke-2 dan ke-3 terlewat; buka aplikasi di hari ke-4.
    cycle = cycle.reconcile(DateTime(2026, 11, 4), surahs);
    expect(cycle.days[1].missed, isTrue);
    expect(cycle.days[2].missed, isTrue);
    final rest = [for (var d = 3; d < 12; d++) cycle.days[d].units];
    final all = [cycle.days[0].units, ...rest];
    expectFullCoverage(surahs, all);
    // Hitung ulang tidak berulang bila dibuka lagi di hari yang sama.
    final before = cycle.days[3].units.map((u) => u.key).toList();
    cycle = cycle.reconcile(DateTime(2026, 11, 4), surahs);
    expect(cycle.days[3].units.map((u) => u.key).toList(), before);
  });

  test('siklus berakhir lalu siklus baru dimulai', () {
    final surahs = quran.durations(const HafalanRange.juz([30]));
    final cycle = Cycle.create(surahs, 5, DateTime(2026, 11, 1));
    final next = cycle.reconcile(DateTime(2026, 11, 6), surahs);
    expect(next.number, 2);
    expect(next.start, dateOnly(DateTime(2026, 11, 6)));
  });

  test('surah lemah diulang di hari lain', () {
    final surahs = quran.durations(const HafalanRange.juz([30]));
    final cycle = Cycle.create(surahs, 10, DateTime(2026, 11, 1), weakSurahs: [78]);
    final reviews = [
      for (var d = 0; d < 10; d++)
        for (final u in cycle.days[d].units) if (u.review) (d, u),
    ];
    expect(reviews.length, 1);
    final (day, unit) = reviews.single;
    expect(unit.surah, 78);
    expect(cycle.days[day].units.where((u) => u.surah == 78 && !u.review), isEmpty);
  });

  test('simpan dan muat siklus (JSON)', () {
    final surahs = quran.durations(const HafalanRange.juz([30]));
    final cycle = Cycle.create(surahs, 7, DateTime(2026, 11, 1));
    cycle.days[0].doneAt = DateTime(2026, 11, 1, 20);
    final back = Cycle.fromJson(cycle.toJson());
    expect(back.days.length, 7);
    expect(back.days[0].done, isTrue);
    expect(back.days[3].units.map((u) => u.key), cycle.days[3].units.map((u) => u.key));
  });

  test('statistik siklus: selesai dan hari beruntun', () {
    final surahs = quran.durations(const HafalanRange.juz([30]));
    final c = Cycle.create(surahs, 10, DateTime(2026, 11, 1));
    for (final d in [0, 2, 3]) {
      c.days[d].doneAt = DateTime(2026, 11, 1 + d);
    }
    final s = CycleStats.of(c, DateTime(2026, 11, 5));
    expect(s.today, 4);
    expect(s.done, 3);
    expect(s.streak, 2);
  });
}
