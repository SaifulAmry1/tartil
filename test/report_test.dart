import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tartil/core/cycle.dart';
import 'package:tartil/core/report.dart';
import 'package:tartil/data/quran_data.dart';
import 'package:tartil/models/profile.dart';
import 'package:tartil/models/recording_log.dart';

void main() {
  final quran = QuranData.parse(File('assets/quran/quran.json').readAsStringSync());

  Profile profile(List<int> juz, int days) {
    final range = HafalanRange.juz(juz);
    return Profile(id: '1', name: 'Rafka', range: range, cycleDays: days)
      ..cycle = Cycle.create(quran.durations(range), days, DateTime(2026, 10, 28), offDays: {7})
      ..scores = {78: 72, 80: 95};
  }

  test('laporan dikodekan ke link lalu dibaca kembali', () {
    final p = profile([29, 30], 12);
    p.cycle!.days[0].doneAt = DateTime(2026, 10, 28, 19);
    p.cycle!.days[1].missed = true;
    final l = Laporan.of(p, 'Juz 29, 30', DateTime(2026, 10, 30, 20, 15));
    expect(l.url.length, lessThan(1600));
    final back = Laporan.decode(Uri.parse(l.url).queryParameters['r']!)!;
    expect(back.name, 'Rafka');
    expect(back.range, 'Juz 29, 30');
    expect(back.days.take(3), [DayStatus.selesai, DayStatus.terlewat, DayStatus.belum]);
    expect(back.surahs, l.surahs);
    expect(back.weak, [78]);
    expect(back.averageScore, '84');
    expect(back.stats.today, 2);
    // Ahad 1 Nov tidak dihitung: hari ke-4 Sabtu 31 Okt, hari ke-5 Senin 2 Nov.
    expect(back.dateOf(3), dateOnly(DateTime(2026, 10, 31)));
    expect(back.dateOf(4), dateOnly(DateTime(2026, 11, 2)));
  });

  test('rentang panjang: daftar surah dipangkas agar QR tetap terbaca', () {
    final p = profile([for (var j = 1; j <= 30; j++) j], 300);
    final l = Laporan.of(p, 'Juz 1-30', DateTime(2026, 10, 28));
    final back = Laporan.decode(l.encode())!;
    expect(back.surahs, isNull);
    expect(back.length, 300);
    expect(l.url.length, lessThan(1600));
  });

  test('link rusak tidak membuat aplikasi gagal', () {
    expect(Laporan.decode('bukan-laporan'), isNull);
  });

  test('hasil rekaman ikut laporan, link QR memangkasnya bila panjang', () {
    final p = profile([29, 30], 12);
    for (var i = 0; i < 20; i++) {
      p.recordings.add(RecordingLog(
        surah: 78, fromAyah: 1, toAyah: 40, score: 70, at: DateTime(2026, 10, 28, 19, i),
        wrong: [for (var k = 0; k < 8; k++) ['عَمَّ', 'عن']],
        missed: [for (var k = 0; k < 8; k++) 'يَتَسَآءَلُونَ'],
      ));
    }
    final l = Laporan.of(p, 'Juz 29, 30', DateTime(2026, 10, 28, 20));
    final full = Laporan.fromJson(l.toJson());
    expect(full.recordings.length, 20);
    expect(full.recordings.first.wrong.first, ['عَمَّ', 'عن']);
    expect(full.recordings.first.missed.length, 8);
    expect(l.encode().length, lessThanOrEqualTo(Laporan.maxData));
    expect(Laporan.decode(l.encode())!.recordings.length, lessThan(20));
    expect(Laporan.liveUrl('abc'), 'https://saifulamry1.github.io/tartil/?p=abc');
  });

  test('profil menyimpan rekaman dan kunci sinkron', () {
    final p = profile([30], 5)
      ..syncId = 'kunci'
      ..recordings = [RecordingLog(surah: 112, fromAyah: 1, toAyah: 4, score: 100, at: DateTime(2026, 10, 28))];
    final back = Profile.fromJson(p.toJson());
    expect(back.syncId, 'kunci');
    expect(back.recordings.single.surah, 112);
    expect(back.recordings.single.wrong, isEmpty);
  });
}
