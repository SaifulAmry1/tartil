import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tartil/data/quran_data.dart';
import 'package:tartil/ui/reader_screen.dart';

void main() {
  final quran = QuranData.parse(File('assets/quran/quran.json').readAsStringSync());

  for (final page in [1, 2, 582, 604]) {
    testWidgets('halaman $page tampil tanpa galat tata letak', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: ReaderScreen(quran: quran, startPage: page),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Halaman $page · Juz ${quran.ayahs[quran.ayahIndicesOnPage(page).first].juz}'), findsOneWidget);
    });
  }
}
