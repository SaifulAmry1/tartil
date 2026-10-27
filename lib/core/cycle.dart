// Siklus murojaah: rencana harian, tanda selesai, dan hitung ulang
// otomatis bila ada hari terlewat.
import 'schedule.dart';

DateTime dateOnly(DateTime t) => DateTime.utc(t.year, t.month, t.day);

int daysBetween(DateTime a, DateTime b) =>
    dateOnly(b).difference(dateOnly(a)).inDays;

class DayPlan {
  List<Unit> units;
  DateTime? doneAt;

  /// Hari ini terlewat dan bacaannya sudah dipindah ke hari berikutnya.
  bool missed;

  DayPlan(this.units, {this.doneAt, this.missed = false});

  bool get done => doneAt != null;

  Map<String, dynamic> toJson() => {
        'u': [for (final u in units) u.toJson()],
        if (doneAt != null) 'd': doneAt!.toIso8601String(),
        if (missed) 'm': true,
      };

  factory DayPlan.fromJson(Map<String, dynamic> j) => DayPlan(
        [for (final u in j['u'] as List) Unit.fromJson(u as Map<String, dynamic>)],
        doneAt: j['d'] == null ? null : DateTime.parse(j['d'] as String),
        missed: j['m'] == true,
      );
}

class Cycle {
  final DateTime start;
  final List<DayPlan> days;
  final int number;

  Cycle(this.start, this.days, {this.number = 1});

  int get length => days.length;

  factory Cycle.create(
    List<SurahDurations> surahs,
    int days,
    DateTime start, {
    Iterable<int> weakSurahs = const [],
    int number = 1,
  }) {
    final plan = planCycle(surahs, days);
    addReviews(plan, _weakUnits(surahs, weakSurahs));
    return Cycle(dateOnly(start), [for (final d in plan) DayPlan(d)],
        number: number);
  }

  int indexOf(DateTime today) => daysBetween(start, today);

  DayPlan? dayAt(DateTime today) {
    final i = indexOf(today);
    return i >= 0 && i < days.length ? days[i] : null;
  }

  bool isFinished(DateTime today) => indexOf(today) >= days.length;

  /// Sesuaikan rencana dengan tanggal [today]:
  /// - siklus lewat: buat siklus baru mulai hari ini;
  /// - ada hari terlewat: pindahkan bacaannya ke sisa hari secara seimbang.
  /// Mengembalikan siklus yang berlaku (bisa objek baru).
  Cycle reconcile(
    DateTime today,
    List<SurahDurations> surahs, {
    Iterable<int> weakSurahs = const [],
  }) {
    final idx = indexOf(today);
    if (idx >= days.length) {
      return Cycle.create(surahs, days.length, today,
          weakSurahs: weakSurahs, number: number + 1);
    }
    if (idx <= 0) return this;
    final missedIdx = [
      for (var d = 0; d < idx; d++)
        if (!days[d].done && !days[d].missed && days[d].units.isNotEmpty) d,
    ];
    if (missedIdx.isEmpty) return this;

    final todayDone = days[idx].done;
    final from = todayDone ? idx + 1 : idx;
    final pending = <Unit>[
      for (final d in missedIdx) ...days[d].units.where((u) => !u.review),
      for (var d = from; d < days.length; d++)
        ...days[d].units.where((u) => !u.review),
    ];
    for (final d in missedIdx) {
      days[d].missed = true;
    }
    if (from >= days.length) {
      // Hari terakhir sudah selesai: sisa bacaan masuk ke hari ini.
      days[idx].units = [...days[idx].units, ...pending];
      return this;
    }
    final remaining = days.length - from;
    final plan = balance(pending, remaining);
    addReviews(plan, _weakUnits(surahs, weakSurahs));
    for (var k = 0; k < remaining; k++) {
      days[from + k] = DayPlan(plan[k]);
    }
    return this;
  }

  /// Tambahkan pengulangan surah yang baru dinilai lemah ke sisa hari.
  void addWeak(int surah, List<SurahDurations> surahs, DateTime today) {
    final from = indexOf(today) + 1;
    if (from >= days.length) return;
    final hasReview = [
      for (var d = from; d < days.length; d++) ...days[d].units,
    ].any((u) => u.surah == surah && u.review);
    if (hasReview) return;
    final plan = [for (final d in days) d.units];
    addReviews(plan, _weakUnits(surahs, [surah]), fromDay: from);
  }

  Map<String, dynamic> toJson() => {
        's': start.toIso8601String(),
        'n': number,
        'd': [for (final d in days) d.toJson()],
      };

  factory Cycle.fromJson(Map<String, dynamic> j) => Cycle(
        DateTime.parse(j['s'] as String),
        [for (final d in j['d'] as List) DayPlan.fromJson(d as Map<String, dynamic>)],
        number: j['n'] as int? ?? 1,
      );
}

/// Surah lemah diulang utuh jika pendek; surah panjang diulang
/// potongan pertamanya saja agar beban hari tidak melonjak.
List<Unit> _weakUnits(List<SurahDurations> surahs, Iterable<int> weak) {
  if (surahs.isEmpty) return const [];
  final weakSet = weak.toSet();
  final total = surahs.fold(0.0, (a, s) => a + s.total);
  final cap = total / surahs.length * 2;
  return [
    for (final s in surahs)
      if (weakSet.contains(s.surah))
        s.total <= cap ? s.whole() : s.split((s.total / cap).ceil()).first,
  ];
}
