import 'package:flutter/material.dart';

import '../data/quran_data.dart';
import '../teks.dart';
import 'reader_screen.dart';
import 'theme.dart';

/// Daftar surah untuk membuka mushaf.
class MushafIndexPage extends StatefulWidget {
  final QuranData quran;
  const MushafIndexPage({super.key, required this.quran});

  @override
  State<MushafIndexPage> createState() => _MushafIndexPageState();
}

class _MushafIndexPageState extends State<MushafIndexPage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = widget.quran;
    final query = _q.toLowerCase().replaceAll(RegExp(r"[-' ]"), '');
    final list = q.surahs.where((s) =>
        query.isEmpty ||
        '${s.number}' == query ||
        s.name.toLowerCase().replaceAll(RegExp(r"[-' ]"), '').contains(query)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(Teks.navMushaf),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: Teks.cariSurah,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
        itemCount: list.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
        itemBuilder: (context, i) {
          final s = list[i];
          final (page, _) = q.pagesOf(s.number, 1, 1);
          return ListTile(
            leading: Rub(
              size: 40,
              child: Text('${s.number}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TartilColors.hijau)),
            ),
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Juz ${q.ayah(s.number, 1).juz} · ${Teks.infoSurah(s.ayahCount, page)}'),
            trailing: Text(s.arabicName,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, color: TartilColors.hijau)),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ReaderScreen(quran: q, startPage: page, title: s.name),
            )),
          );
        },
      ),
    );
  }
}
