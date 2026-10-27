// Data Qur'an dari assets/quran/quran.json (lihat tool/build_quran_data.py).
import 'dart:convert';

import '../core/schedule.dart';
import 'surah_names.dart';

/// Tanda waqaf, sajdah, dan rub' yang berdiri sebagai token terpisah.
const String pauseMarks = 'ۖۗۚۛۜۙۘ۩۞';

bool isMarkToken(String t) => t.length == 1 && pauseMarks.contains(t);

class Tajweed {
  final int rule;
  final int start;
  final int end;
  const Tajweed(this.rule, this.start, this.end);
}

class Ayah {
  final int surah;
  final int number;
  final String text;
  final List<Tajweed> tajweed;

  /// Nomor baris global untuk setiap token (dipisah spasi) di [text].
  final List<int> tokenLines;
  final int page;
  final int juz;

  /// Basmalah sebelum ayat 1 (kosong jika tidak ada).
  final String bismillah;

  Ayah({
    required this.surah,
    required this.number,
    required this.text,
    required this.tajweed,
    required this.tokenLines,
    required this.page,
    required this.juz,
    required this.bismillah,
  });

  List<String> get tokens => text.split(' ');

  int get wordCount => tokens.where((t) => !isMarkToken(t)).length;
}

class Surah {
  final int number;
  final String arabicName;
  final int ayahCount;
  final int firstIndex;

  const Surah(this.number, this.arabicName, this.ayahCount, this.firstIndex);

  String get name => surahNames[number - 1];
}

/// Perkiraan durasi baca (detik) per ayat sebelum ada data rekaman.
const double secondsPerWord = 0.85;
const double secondsPerAyahPause = 1.0;

double estimateAyahSeconds(Ayah a) =>
    a.wordCount * secondsPerWord + secondsPerAyahPause;

/// Rentang hafalan sebuah profil: kumpulan juz atau rentang nomor surah.
class HafalanRange {
  final List<int> juz;
  final int? fromSurah;
  final int? toSurah;

  const HafalanRange.juz(this.juz)
      : fromSurah = null,
        toSurah = null;

  const HafalanRange.surah(int from, int to)
      : juz = const [],
        fromSurah = from,
        toSurah = to;

  bool get isJuz => fromSurah == null;

  bool contains(Ayah a) => isJuz
      ? juz.contains(a.juz)
      : a.surah >= fromSurah! && a.surah <= toSurah!;

  Map<String, dynamic> toJson() =>
      isJuz ? {'juz': juz} : {'dari': fromSurah, 'sampai': toSurah};

  factory HafalanRange.fromJson(Map<String, dynamic> j) => j['juz'] != null
      ? HafalanRange.juz([for (final x in j['juz'] as List) x as int])
      : HafalanRange.surah(j['dari'] as int, j['sampai'] as int);
}

class QuranData {
  final List<Surah> surahs;
  final List<Ayah> ayahs;

  /// Per baris global: [halaman, baris ke-n dalam halaman].
  final List<List<int>> lines;
  final List<String> rules;
  final Map<String, String> sources;

  QuranData._(this.surahs, this.ayahs, this.lines, this.rules, this.sources);

  factory QuranData.parse(String jsonText) {
    final j = jsonDecode(jsonText) as Map<String, dynamic>;
    final surahs = <Surah>[];
    final ayahs = <Ayah>[];
    var idx = 0;
    final rawAyahs = j['ayahs'] as List;
    final rawSurahs = j['surahs'] as List;
    for (var s = 0; s < rawSurahs.length; s++) {
      final rs = rawSurahs[s] as List;
      final count = rs[1] as int;
      surahs.add(Surah(s + 1, rs[0] as String, count, idx));
      for (var a = 1; a <= count; a++) {
        final r = rawAyahs[idx++] as List;
        ayahs.add(Ayah(
          surah: s + 1,
          number: a,
          text: r[0] as String,
          tajweed: [
            for (final t in r[1] as List)
              Tajweed((t as List)[0] as int, t[1] as int, t[2] as int),
          ],
          tokenLines: [for (final l in r[2] as List) l as int],
          page: r[3] as int,
          juz: r[4] as int,
          bismillah: r[5] as String,
        ));
      }
    }
    return QuranData._(
      surahs,
      ayahs,
      [for (final l in j['lines'] as List) [for (final x in l as List) x as int]],
      [for (final r in j['rules'] as List) r as String],
      (j['sumber'] as Map).cast<String, String>(),
    );
  }

  Surah surah(int n) => surahs[n - 1];

  Ayah ayah(int surah, int number) =>
      ayahs[surahs[surah - 1].firstIndex + number - 1];

  List<Ayah> ayahRange(int surah, int from, int to) {
    final base = surahs[surah - 1].firstIndex;
    return ayahs.sublist(base + from - 1, base + to);
  }

  int get pageCount => lines.last[0];

  List<List<int>>? _pageAyahs;

  /// Indeks ayat (ke [ayahs]) yang punya kata di halaman [page].
  List<int> ayahIndicesOnPage(int page) {
    if (_pageAyahs == null) {
      final pa = List.generate(pageCount + 1, (_) => <int>[]);
      for (var i = 0; i < ayahs.length; i++) {
        final pages = {for (final l in ayahs[i].tokenLines) lines[l][0]};
        for (final p in pages) {
          pa[p].add(i);
        }
      }
      _pageAyahs = pa;
    }
    return _pageAyahs![page];
  }

  /// Halaman pertama dan terakhir yang memuat ayat [from]..[to] surah [surah].
  (int, int) pagesOf(int surah, int from, int to) {
    final a = ayah(surah, from), b = ayah(surah, to);
    return (lines[a.tokenLines.first][0], lines[b.tokenLines.last][0]);
  }

  /// Durasi per surah dalam rentang, siap untuk [planCycle].
  /// [measured] berisi detik per ayat hasil rekaman (kunci "surah:ayat").
  List<SurahDurations> durations(HafalanRange range,
      {Map<String, double> measured = const {}}) {
    final out = <SurahDurations>[];
    for (final s in surahs) {
      int? first;
      final secs = <double>[];
      for (final a in ayahRange(s.number, 1, s.ayahCount)) {
        if (!range.contains(a)) continue;
        // Rentang juz bisa memotong surah; ambil potongan yang berurutan.
        if (first != null && a.number != first + secs.length) break;
        first ??= a.number;
        secs.add(measured['${a.surah}:${a.number}'] ?? estimateAyahSeconds(a));
      }
      if (first != null) {
        out.add(SurahDurations(s.number, secs,
            firstAyah: first, surahAyahs: s.ayahCount));
      }
    }
    return out;
  }
}
