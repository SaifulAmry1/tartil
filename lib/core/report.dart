// Laporan kemajuan untuk orang tua. Dikirim otomatis ke Firestore (link
// ?p=<kunci>), atau seluruh isinya dikodekan ke dalam link (?r=<data>).
import 'dart:convert';

import '../models/profile.dart';
import '../models/recording_log.dart';
import 'cycle.dart';
import 'stats.dart';

enum DayStatus { selesai, terlewat, belum }

class Laporan {
  static const baseUrl = 'https://saifulamry1.github.io/tartil/';

  /// Batas panjang data agar QR tetap mudah dipindai. Jika terlampaui,
  /// daftar surah per hari tidak ikut dikirim.
  static const maxData = 1500;

  final String name;
  final String range;
  final int cycleNumber;
  final DateTime start;
  final Set<int> offDays;
  final List<DayStatus> days;

  /// Nomor surah per hari siklus; null bila dipangkas karena terlalu panjang.
  final List<List<int>>? surahs;
  final Map<int, int> scores;

  /// Rekaman terbaru lebih dulu.
  final List<RecordingLog> recordings;
  final DateTime generated;

  Laporan({
    required this.name,
    required this.range,
    required this.cycleNumber,
    required this.start,
    required this.offDays,
    required this.days,
    required this.surahs,
    required this.scores,
    this.recordings = const [],
    required this.generated,
  });

  factory Laporan.of(Profile p, String rangeLabel, DateTime now) {
    final c = p.cycle!;
    return Laporan(
      name: p.name,
      range: rangeLabel,
      cycleNumber: c.number,
      start: c.start,
      offDays: c.offDays,
      days: [
        for (final d in c.days)
          d.done
              ? DayStatus.selesai
              : d.missed
                  ? DayStatus.terlewat
                  : DayStatus.belum,
      ],
      surahs: [
        for (final d in c.days) [for (final s in d.units.map((u) => u.surah).toSet()) s],
      ],
      scores: Map.of(p.scores),
      recordings: List.of(p.recordings),
      generated: now,
    );
  }

  /// Siklus tiruan untuk menghitung tanggal dan statistik seperti di HP anak.
  Cycle get _cycle => Cycle(
        start,
        [
          for (final s in days)
            DayPlan(const [],
                doneAt: s == DayStatus.selesai ? generated : null,
                missed: s == DayStatus.terlewat),
        ],
        number: cycleNumber,
        offDays: offDays,
      );

  int get length => days.length;
  DateTime dateOf(int i) => _cycle.dateOf(i);
  CycleStats get stats => CycleStats.of(_cycle, generated);
  bool get offToday => _cycle.isOff(generated);

  /// Status hari ini pada saat laporan dibuat.
  DayStatus get today => days[stats.today];

  String? get averageScore => scores.isEmpty
      ? null
      : '${(scores.values.reduce((a, b) => a + b) / scores.length).round()}';

  List<int> get weak =>
      (scores.entries.where((e) => e.value < Profile.weakThreshold).map((e) => e.key).toList()..sort());

  /// Rekaman yang ikut dikirim. Sinkron membawa semuanya; link QR hanya
  /// sebagian agar tetap mudah dipindai.
  Map<String, dynamic> toJson({bool withSurahs = true, int maxRecordings = Profile.maxRecordings}) => {
        'v': 1,
        'n': name,
        'r': range,
        'c': cycleNumber,
        's': '${start.year}-${_pad2(start.month)}-${_pad2(start.day)}',
        'l': offDays.toList()..sort(),
        'd': days.map((s) => s.name[0]).join(),
        if (withSurahs && surahs != null) 'u': surahs,
        'x': {for (final e in scores.entries) '${e.key}': e.value},
        if (recordings.isNotEmpty && maxRecordings > 0)
          'h': [for (final r in recordings.take(maxRecordings)) r.toJson()],
        'g': generated.millisecondsSinceEpoch ~/ 1000,
      };

  factory Laporan.fromJson(Map<String, dynamic> j) {
    final s = (j['s'] as String).split('-').map(int.parse).toList();
    return Laporan(
      name: j['n'] as String,
      range: j['r'] as String,
      cycleNumber: j['c'] as int,
      start: DateTime.utc(s[0], s[1], s[2]),
      offDays: {for (final x in j['l'] as List) x as int},
      days: [
        for (final ch in (j['d'] as String).split(''))
          DayStatus.values.firstWhere((v) => v.name[0] == ch),
      ],
      surahs: j['u'] == null
          ? null
          : [for (final d in j['u'] as List) [for (final x in d as List) x as int]],
      scores: {for (final e in (j['x'] as Map).entries) int.parse(e.key as String): e.value as int},
      recordings: [
        for (final r in j['h'] as List? ?? const []) RecordingLog.fromJson(r as Map<String, dynamic>),
      ],
      generated: DateTime.fromMillisecondsSinceEpoch((j['g'] as int) * 1000),
    );
  }

  /// Data untuk link QR tanpa sinkron, dipangkas bertahap bila terlalu panjang.
  String encode() {
    String enc(bool withSurahs, int rec) =>
        base64Url.encode(utf8.encode(jsonEncode(toJson(withSurahs: withSurahs, maxRecordings: rec)))).replaceAll('=', '');
    for (final (withSurahs, rec) in [(true, 3), (true, 1), (true, 0), (false, 0)]) {
      final e = enc(withSurahs, rec);
      if (e.length <= maxData) return e;
    }
    return enc(false, 0);
  }

  String get url => '$baseUrl?r=${encode()}';

  /// Link pantauan yang selalu terbaru (data diambil dari sinkron).
  static String liveUrl(String syncId) => '$baseUrl?p=$syncId';

  static Laporan? decode(String data) {
    try {
      final padded = data.padRight((data.length + 3) ~/ 4 * 4, '=');
      return Laporan.fromJson(jsonDecode(utf8.decode(base64Url.decode(padded))) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

String _pad2(int n) => n.toString().padLeft(2, '0');
