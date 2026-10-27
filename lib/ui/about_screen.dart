import 'package:flutter/material.dart';

import '../data/quran_data.dart';
import '../teks.dart';
import 'theme.dart';

class AboutScreen extends StatelessWidget {
  final QuranData quran;
  const AboutScreen({super.key, required this.quran});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Teks.tentang)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(child: Rub(size: 72)),
          const SizedBox(height: 8),
          const Center(
            child: Text('${Teks.appName}: ${Teks.kepanjangan}',
                textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          const Text('Sumber data dan lisensi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          for (final e in quran.sources.entries)
            ListTile(title: Text(e.key), subtitle: Text(e.value)),
          const ListTile(
            title: Text('font'),
            subtitle: Text('Amiri Quran, (c) The Amiri Project Authors, SIL Open Font License 1.1'),
          ),
          const ListTile(
            title: Text('pengenal suara'),
            subtitle: Text('whisper.cpp (MIT) dengan model tarteel-ai/whisper-base-ar-quran, '
                'berjalan di perangkat tanpa internet.'),
          ),
          const ListTile(
            title: Text('catatan'),
            subtitle: Text('Tata letak 8 blok warna terinspirasi mushaf hafalan 8 blok, '
                'dibuat ulang dari data terbuka. Bukan salinan mushaf cetak mana pun.'),
          ),
        ],
      ),
    );
  }
}
