// Ringkasan satu rekaman murojaah: nilai serta kata yang salah atau
// terlewat. Disimpan agar bisa dilihat ulang dan dikirim ke orang tua.
import '../core/recitation_check.dart';

class RecordingLog {
  /// Batas kata salah/terlewat yang disimpan per rekaman.
  static const maxWords = 8;

  final int surah;
  final int fromAyah;
  final int toAyah;
  final int score;
  final DateTime at;

  /// Pasangan [seharusnya, terdengar].
  final List<List<String>> wrong;
  final List<String> missed;

  const RecordingLog({
    required this.surah,
    required this.fromAyah,
    required this.toAyah,
    required this.score,
    required this.at,
    this.wrong = const [],
    this.missed = const [],
  });

  factory RecordingLog.of(CheckResult r, int surah, int from, int to, DateTime at) => RecordingLog(
        surah: surah,
        fromAyah: from,
        toAyah: to,
        score: r.score,
        at: at,
        wrong: [
          for (final w in r.words.where((w) => w.status == WordStatus.salah).take(maxWords))
            [w.expected, w.heard ?? ''],
        ],
        missed: [
          for (final w in r.words.where((w) => w.status == WordStatus.terlewat).take(maxWords)) w.expected,
        ],
      );

  Map<String, dynamic> toJson() => {
        's': surah,
        'a': [fromAyah, toAyah],
        'n': score,
        't': at.millisecondsSinceEpoch ~/ 1000,
        if (wrong.isNotEmpty) 'w': wrong,
        if (missed.isNotEmpty) 'm': missed,
      };

  factory RecordingLog.fromJson(Map<String, dynamic> j) {
    final a = j['a'] as List;
    return RecordingLog(
      surah: j['s'] as int,
      fromAyah: a[0] as int,
      toAyah: a[1] as int,
      score: j['n'] as int,
      at: DateTime.fromMillisecondsSinceEpoch((j['t'] as int) * 1000),
      wrong: [for (final w in j['w'] as List? ?? const []) [for (final x in w as List) x as String]],
      missed: [for (final x in j['m'] as List? ?? const []) x as String],
    );
  }
}
