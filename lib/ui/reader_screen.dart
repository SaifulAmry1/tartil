import 'package:flutter/material.dart';

import '../data/page_layout.dart';
import '../data/quran_data.dart';
import '../teks.dart';
import 'tajweed_style.dart';
import 'theme.dart';

/// Tampilan mushaf per halaman dengan 8 blok warna dan warna tajwid.
/// [highlight] menandai rentang ayat yang sedang dimurojaah.
class ReaderScreen extends StatefulWidget {
  final QuranData quran;
  final int startPage;
  final ({int surah, int from, int to})? highlight;
  final String? title;

  const ReaderScreen({
    super.key,
    required this.quran,
    required this.startPage,
    this.highlight,
    this.title,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final PageController _pages =
      PageController(initialPage: widget.startPage - 1);
  late int _page = widget.startPage;
  bool _tajwid = true;
  bool _blok = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? Teks.bacaMushaf),
        actions: [
          IconButton(
            tooltip: Teks.keteranganTajwid,
            icon: const Icon(Icons.palette_outlined),
            onPressed: _showLegend,
          ),
          PopupMenuButton<String>(
            onSelected: (v) => setState(() {
              if (v == 'tajwid') _tajwid = !_tajwid;
              if (v == 'blok') _blok = !_blok;
            }),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(value: 'tajwid', checked: _tajwid, child: const Text(Teks.tajwid)),
              CheckedPopupMenuItem(value: 'blok', checked: _blok, child: const Text(Teks.blok)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pages,
              reverse: true, // halaman berikutnya di kiri, seperti mushaf
              itemCount: widget.quran.pageCount,
              onPageChanged: (i) => setState(() => _page = i + 1),
              itemBuilder: (_, i) => _MushafPage(
                quran: widget.quran,
                page: i + 1,
                tajwid: _tajwid,
                blok: _blok,
                highlight: widget.highlight,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: TartilColors.hijauMuda,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              '${Teks.halaman(_page)} · Juz ${_juzOfPage(_page)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: TartilColors.hijau, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  int _juzOfPage(int page) {
    final idx = widget.quran.ayahIndicesOnPage(page);
    return idx.isEmpty ? 0 : widget.quran.ayahs[idx.first].juz;
  }

  void _showLegend() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(Teks.keteranganTajwid, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final s in tajweedStyles.values)
            ListTile(
              dense: true,
              leading: CircleAvatar(radius: 10, backgroundColor: s.color),
              title: Text(s.label),
            ),
        ],
      ),
    );
  }
}

class _MushafPage extends StatelessWidget {
  final QuranData quran;
  final int page;
  final bool tajwid;
  final bool blok;
  final ({int surah, int from, int to})? highlight;

  const _MushafPage({
    required this.quran,
    required this.page,
    required this.tajwid,
    required this.blok,
    this.highlight,
  });

  bool _inHighlight(Ayah a) {
    final h = highlight;
    return h != null && a.surah == h.surah && a.number >= h.from && a.number <= h.to;
  }

  @override
  Widget build(BuildContext context) {
    final rows = buildPage(quran, page);
    return LayoutBuilder(builder: (context, box) {
      final fontSize = (box.maxWidth / 17).clamp(16.0, 34.0);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: TartilColors.emas, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            children: [for (final r in rows) _row(r, fontSize, box.maxWidth - 44)],
          ),
        ),
      );
    });
  }

  Widget _row(PageRow r, double fontSize, double lineWidth) {
    switch (r.kind) {
      case RowKind.surahHeader:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: TartilColors.hijauMuda,
            border: Border.all(color: TartilColors.emas),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Rub(size: 22),
              const SizedBox(width: 10),
              Text('سورة ${quran.surah(r.surah).arabicName}',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontFamily: 'AmiriQuran', fontSize: fontSize * 0.9, color: TartilColors.hijau)),
              const SizedBox(width: 10),
              const Rub(size: 22),
            ],
          ),
        );
      case RowKind.bismillah:
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(quran.ayahs.first.text,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: 'AmiriQuran', fontSize: fontSize * 0.9, height: 1.9)),
        );
      case RowKind.line:
        final bg = blok ? TartilColors.blok[blockOfLine(r.lineInPage)] : Colors.transparent;
        // Baris penuh dirata kanan-kiri seperti mushaf; baris pendek
        // (akhir surah) di tengah. Baris yang terlalu panjang diperkecil.
        final full = r.tokens.length >= 5;
        return Container(
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: full ? lineWidth : 0),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: full
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.center,
                  children: [
                    for (final t in r.tokens)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: fontSize * 0.1),
                        child: _token(t, fontSize),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }

  Widget _token(PageToken t, double fontSize) {
    final hl = _inHighlight(t.ayah);
    final base = TextStyle(
      fontFamily: 'AmiriQuran',
      fontSize: fontSize,
      height: 2.0,
      color: Colors.black,
      backgroundColor: hl ? const Color(0x33FFD54F) : null,
    );
    if (t.isAyahEnd) {
      return Text('۝${arabicDigits(int.parse(t.text))}',
          textDirection: TextDirection.rtl,
          style: base.copyWith(color: TartilColors.hijau));
    }
    if (!tajwid || t.ayah.tajweed.isEmpty) {
      return Text(t.text, textDirection: TextDirection.rtl, style: base);
    }
    // Warna per karakter sesuai anotasi tajwid yang mengenai token ini.
    final colors = List<Color?>.filled(t.text.length, null);
    final end = t.charStart + t.text.length;
    for (final a in t.ayah.tajweed) {
      if (a.end <= t.charStart || a.start >= end) continue;
      final style = tajweedStyles[quran.rules[a.rule]];
      if (style == null) continue;
      for (var c = a.start; c < a.end; c++) {
        if (c >= t.charStart && c < end) colors[c - t.charStart] = style.color;
      }
    }
    final spans = <TextSpan>[];
    var runStart = 0;
    for (var i = 1; i <= t.text.length; i++) {
      if (i == t.text.length || colors[i] != colors[runStart]) {
        // ZWJ di batas warna menjaga sambungan huruf Arab antar span.
        final pre = runStart > 0 ? '\u200D' : '';
        final post = i < t.text.length ? '\u200D' : '';
        spans.add(TextSpan(
          text: '$pre${t.text.substring(runStart, i)}$post',
          style: colors[runStart] == null ? null : TextStyle(color: colors[runStart]),
        ));
        runStart = i;
      }
    }
    return Text.rich(TextSpan(style: base, children: spans),
        textDirection: TextDirection.rtl);
  }
}
