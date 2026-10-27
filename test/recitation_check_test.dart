import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tartil/core/recitation_check.dart';
import 'package:tartil/data/quran_data.dart';

void main() {
  final quran = QuranData.parse(File('assets/quran/quran.json').readAsStringSync());

  test('tulisan imla\'i cocok dengan tulisan Utsmani', () {
    expect(wordSimilarity('ٱلْعَٰلَمِينَ', 'العالمين'), greaterThanOrEqualTo(matchThreshold));
    expect(wordSimilarity('ٱلصَّلَوٰةَ', 'الصلاة'), greaterThanOrEqualTo(matchThreshold));
    expect(wordSimilarity('ٱلرَّحْمَٰنِ', 'الرحمن'), 1.0);
    expect(wordSimilarity('يُؤْمِنُونَ', 'يومنون'), 1.0);
    expect(wordSimilarity('ٱلْفَلَقِ', 'الناس'), lessThan(matchThreshold));
  });

  test('bacaan sempurna Al-Ikhlas bernilai 100', () {
    final expected = [
      for (final a in quran.ayahRange(112, 1, 4)) ...splitWords(a.text),
    ];
    final heard = splitWords('قل هو الله احد الله الصمد لم يلد ولم يولد ولم يكن له كفوا احد');
    final r = compareRecitation(expected, heard);
    expect(r.score, 100);
    expect(r.extra, isEmpty);
  });

  test('kata terlewat dan salah terdeteksi', () {
    final expected = [
      for (final a in quran.ayahRange(112, 1, 4)) ...splitWords(a.text),
    ];
    // "الصمد" terlewat, "يولد" salah dibaca "يلد".
    final heard = splitWords('قل هو الله احد الله لم يلد ولم يكتب ولم يكن له كفوا احد');
    final r = compareRecitation(expected, heard);
    final missed = r.words.where((w) => w.status == WordStatus.terlewat).toList();
    final wrong = r.words.where((w) => w.status == WordStatus.salah).toList();
    expect(missed.map((w) => w.index), [5]);
    expect(wrong.length, 1);
    expect(wrong.single.heard, 'يكتب');
    expect(r.score, lessThan(100));
  });

  test('tanda waqaf tidak dihitung sebagai kata', () {
    expect(splitWords('لَا رَيْبَ ۛ فِيهِ ۛ هُدًى').length, 4);
    final a = quran.ayah(2, 2);
    expect(splitWords(a.text).length, a.wordCount);
  });
}
