import '../core/cycle.dart';
import '../data/quran_data.dart';

class Profile {
  final String id;
  String name;
  HafalanRange range;
  int cycleDays;
  int reminderHour;
  int reminderMinute;
  Cycle? cycle;

  /// Nilai kelancaran terakhir per surah (0..100).
  Map<int, int> scores;

  Profile({
    required this.id,
    required this.name,
    required this.range,
    required this.cycleDays,
    this.reminderHour = 19,
    this.reminderMinute = 0,
    this.cycle,
    Map<int, int>? scores,
  }) : scores = scores ?? {};

  /// Surah dengan nilai di bawah ambang ini dijadwalkan ulang lebih sering.
  static const weakThreshold = 80;

  Iterable<int> get weakSurahs =>
      scores.entries.where((e) => e.value < weakThreshold).map((e) => e.key);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': name,
        'rentang': range.toJson(),
        'hari': cycleDays,
        'jam': reminderHour,
        'menit': reminderMinute,
        if (cycle != null) 'siklus': cycle!.toJson(),
        'nilai': {for (final e in scores.entries) '${e.key}': e.value},
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        name: j['nama'] as String,
        range: HafalanRange.fromJson(j['rentang'] as Map<String, dynamic>),
        cycleDays: j['hari'] as int,
        reminderHour: j['jam'] as int? ?? 19,
        reminderMinute: j['menit'] as int? ?? 0,
        cycle: j['siklus'] == null
            ? null
            : Cycle.fromJson(j['siklus'] as Map<String, dynamic>),
        scores: {
          for (final e in (j['nilai'] as Map? ?? {}).entries)
            int.parse(e.key as String): e.value as int,
        },
      );
}
