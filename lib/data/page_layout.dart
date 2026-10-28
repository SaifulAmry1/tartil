// Menyusun satu halaman mushaf: baris-baris kata sesuai mushaf Madinah
// 15 baris, ditambah kepala surah dan basmalah.
import 'quran_data.dart';

enum RowKind { surahHeader, bismillah, line }

class PageToken {
  final Ayah ayah;

  /// Teks token; untuk penanda akhir ayat berisi nomor ayat.
  final String text;

  /// Posisi karakter awal token di teks ayat (-1 untuk penanda akhir ayat).
  final int charStart;

  const PageToken(this.ayah, this.text, this.charStart);

  bool get isAyahEnd => charStart < 0;
}

class PageRow {
  final RowKind kind;

  /// Baris ke-n (0..14) di halaman untuk baris kata, dipakai untuk 8 blok.
  final int lineInPage;
  final int surah;
  final List<PageToken> tokens;

  /// Baris kata ditulis di tengah (tidak dirata kanan-kiri), seperti
  /// halaman 1-2 dan baris pendek penutup surah di mushaf Madinah.
  bool centered = false;

  PageRow(this.kind, this.lineInPage, this.surah, [List<PageToken>? tokens])
      : tokens = tokens ?? [];
}

/// Baris penutup surah dengan huruf sebanyak ini atau kurang ditulis di
/// tengah. Baris penuh berisi sekitar 35-45 huruf.
const centeredLineMaxLetters = 22;

int _letters(String s) => s.runes
    .where((c) => (c >= 0x0621 && c <= 0x064A) || (c >= 0x0671 && c <= 0x06D3))
    .length;

List<PageRow> buildPage(QuranData q, int page) {
  final rows = <PageRow>[];
  int? currentLine;
  for (final ai in q.ayahIndicesOnPage(page)) {
    final ayah = q.ayahs[ai];
    final toks = ayah.tokens;
    var offset = 0;
    for (var t = 0; t < toks.length; t++) {
      final line = ayah.tokenLines[t];
      final start = offset;
      offset += toks[t].length + 1;
      if (q.lines[line][0] != page) continue;
      if (ayah.number == 1 && t == 0) {
        rows.add(PageRow(RowKind.surahHeader, -1, ayah.surah));
        if (ayah.bismillah.isNotEmpty) {
          rows.add(PageRow(RowKind.bismillah, -1, ayah.surah));
        }
        currentLine = null;
      }
      if (currentLine != line) {
        rows.add(PageRow(RowKind.line, q.lines[line][1], ayah.surah));
        currentLine = line;
      }
      rows.last.tokens.add(PageToken(ayah, toks[t], start));
      if (t == toks.length - 1) {
        rows.last.tokens.add(PageToken(ayah, '${ayah.number}', -1));
      }
    }
  }
  for (final r in rows) {
    if (r.kind != RowKind.line) continue;
    final last = r.tokens.last;
    final endsSurah = last.isAyahEnd && last.ayah.number == q.surah(last.ayah.surah).ayahCount;
    final letters = r.tokens.where((t) => !t.isAyahEnd).fold(0, (a, t) => a + _letters(t.text));
    r.centered = page <= 2 || (endsSurah && letters <= centeredLineMaxLetters);
  }
  return rows;
}

/// Blok warna (0..7) untuk baris ke-n dari 15 baris per halaman.
int blockOfLine(int lineInPage) {
  final b = lineInPage * 8 ~/ 15;
  return b > 7 ? 7 : b;
}
