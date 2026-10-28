// Laporan kemajuan untuk orang tua. Seluruh isinya dikodekan ke dalam link
// (tanpa server): orang tua memindai QR dan laporan dibuka di versi web.
import 'dart:convert';

import '../models/profile.dart';
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

  Map<String, dynamic> _json({required bool withSurahs}) => {
        'v': 1,
        'n': name,
        'r': range,
        'c': cycleNumber,
        's': '${start.year}-${_pad2(start.month)}-${_pad2(start.day)}',
        'l': offDays.toList()..sort(),
        'd': days.map((s) => s.name[0]).join(),
        if (withSurahs && surahs != null) 'u': surahs,
        'x': {for (final e in scores.entries) '${e.key}': e.value},
        'g': generated.millisecondsSinceEpoch ~/ 1000,
      };

  String encode() {
    String enc(bool withSurahs) =>
        base64Url.encode(utf8.encode(jsonEncode(_json(withSurahs: withSurahs)))).replaceAll('=', '');
    final full = enc(true);
    return full.length <= maxData ? full : enc(false);
  }

  String get url => '$baseUrl?r=${encode()}';

  static Laporan? decode(String data) {
    try {
      final padded = data.padRight((data.length + 3) ~/ 4 * 4, '=');
      final j = jsonDecode(utf8.decode(base64Url.decode(padded))) as Map<String, dynamic>;
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
        generated: DateTime.fromMillisecondsSinceEpoch((j['g'] as int) * 1000),
      );
    } catch (_) {
      return null;
    }
  }
}

String _pad2(int n) => n.toString().padLeft(2, '0');
