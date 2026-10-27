import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tartil/data/quran_data.dart';

void main() {
  final quran = QuranData.parse(File('assets/quran/quran.json').readAsStringSync());

  test('jumlah surah, ayat, dan halaman', () {
    expect(quran.surahs.length, 114);
    expect(quran.ayahs.length, 6236);
    expect(quran.pageCount, 604);
    expect(quran.surah(67).name, 'Al-Mulk');
    expect(quran.ayah(67, 1).juz, 29);
    expect(quran.ayah(78, 1).page, 582);
    expect(quran.ayah(78, 1).juz, 30);
  });

  test('basmalah ada di ayat 1 kecuali Al-Fatihah dan At-Taubah', () {
    expect(quran.ayah(1, 1).bismillah, isEmpty);
    expect(quran.ayah(9, 1).bismillah, isEmpty);
    expect(quran.ayah(114, 1).bismillah, isNotEmpty);
  });

  test('anotasi tajwid berada di dalam teks ayat', () {
    for (final a in quran.ayahs) {
      for (final t in a.tajweed) {
        expect(t.end <= a.text.length, isTrue);
        expect(t.start < t.end, isTrue);
      }
      expect(a.tokenLines.length, a.tokens.length);
    }
  });
}
