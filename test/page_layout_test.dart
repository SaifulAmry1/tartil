import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tartil/data/page_layout.dart';
import 'package:tartil/data/quran_data.dart';

void main() {
  final quran = QuranData.parse(File('assets/quran/quran.json').readAsStringSync());

  test('halaman 1 (Al-Fatihah): kepala surah lalu 7 ayat', () {
    final rows = buildPage(quran, 1);
    expect(rows.first.kind, RowKind.surahHeader);
    final ends = rows.expand((r) => r.tokens).where((t) => t.isAyahEnd).length;
    expect(ends, 7);
  });

  test('halaman 604: tiga surah terakhir dengan basmalah', () {
    final rows = buildPage(quran, 604);
    expect(rows.where((r) => r.kind == RowKind.surahHeader).map((r) => r.surah),
        [112, 113, 114]);
    expect(rows.where((r) => r.kind == RowKind.bismillah).length, 3);
  });

  test('setiap kata Al-Qur\'an muncul tepat sekali di seluruh halaman', () {
    var count = 0;
    for (var p = 1; p <= quran.pageCount; p++) {
      for (final r in buildPage(quran, p)) {
        count += r.tokens.where((t) => !t.isAyahEnd).length;
        if (r.kind == RowKind.line) {
          expect(r.lineInPage, inInclusiveRange(0, 14));
        }
      }
    }
    expect(count, quran.ayahs.fold(0, (a, x) => a + x.tokens.length));
  });

  test('pembagian 8 blok', () {
    expect([for (var l = 0; l < 15; l++) blockOfLine(l)],
        [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7]);
  });

  test('baris pendek penutup surah di tengah, baris lain rata kanan-kiri', () {
    List<bool> centered(int page) => [
          for (final r in buildPage(quran, page))
            if (r.kind == RowKind.line) r.centered,
        ];
    // Halaman 603: An-Nasr dan Al-Masad ditutup baris pendek.
    final p603 = buildPage(quran, 603).where((r) => r.kind == RowKind.line).toList();
    final masadLast = p603.lastWhere((r) => r.surah == 111);
    expect(masadLast.centered, isTrue);
    expect(p603.where((r) => r.surah == 111 && r != masadLast).every((r) => !r.centered), isTrue);
    expect(centered(1).every((c) => c), isTrue);
    expect(centered(50).any((c) => c), isFalse);
    // Di seluruh mushaf hanya sedikit baris di luar halaman 1-2 yang di tengah.
    var count = 0;
    for (var p = 3; p <= 604; p++) {
      count += centered(p).where((c) => c).length;
    }
    expect(count, 10);
  });
}
