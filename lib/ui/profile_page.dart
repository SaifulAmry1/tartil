import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/store.dart';
import '../teks.dart';
import 'about_screen.dart';
import 'profile_form.dart';
import 'record_screen.dart';
import 'report_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// Halaman profil: profil aktif, ganti/tambah profil, pengaturan lain.
class ProfilePage extends StatelessWidget {
  final AppState app;
  const ProfilePage({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final p = app.active!;
    final r = p.range;
    final range = r.isJuz
        ? Teks.rentangJuz(r.juz)
        : Teks.rentangSurah(
            app.quran.surah(r.fromSurah!).name,
            app.quran.surah(r.toSurah!).name,
          );
    final jam =
        '${p.reminderHour.toString().padLeft(2, '0')}:${p.reminderMinute.toString().padLeft(2, '0')}';
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        HeaderBackground(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ProfileAvatar(profile: p, radius: 42, ring: true),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$range · ${Teks.siklusHari(p.cycleDays)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Teks.pengingatJam(jam),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileForm(app: app, profile: p),
                        ),
                      ),
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text(Teks.pengaturanProfil),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(Teks.siklus),
              _card([
                ListTile(
                  leading: const Icon(Icons.autorenew, color: TartilColors.hijau),
                  title: Text(Teks.siklusHari(p.cycleDays)),
                  subtitle: Text('$range · ${Teks.hariLibur}: ${p.offDays.isEmpty ? '-' : (p.offDays.toList()..sort()).map(namaHariKe).join(', ')}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickCycle(context, p),
                ),
              ]),
              const SectionTitle(Teks.gantiProfil),
              _card([
                for (final x in app.profiles)
                  ListTile(
                    leading: ProfileAvatar(profile: x, radius: 18),
                    title: Text(
                      x.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(_summary(x)),
                    trailing: x.id == p.id
                        ? const Icon(
                            Icons.check_circle,
                            color: TartilColors.hijau,
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () => app.setActive(x),
                  ),
                ListTile(
                  leading: const CircleAvatar(
                    radius: 18,
                    backgroundColor: TartilColors.hijauMuda,
                    child: Icon(Icons.add, color: TartilColors.hijau),
                  ),
                  title: const Text(
                    Teks.tambahProfil,
                    style: TextStyle(
                      color: TartilColors.hijau,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileForm(app: app)),
                  ),
                ),
              ]),
              const SectionTitle(Teks.lainnya),
              _card([
                ListTile(
                  leading: const Icon(
                    Icons.qr_code_2,
                    color: TartilColors.hijau,
                  ),
                  title: const Text(Teks.pantauOrtu),
                  subtitle: const Text(Teks.kirimLaporan),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShareReportScreen(app: app, profile: p),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.graphic_eq,
                    color: TartilColors.hijau,
                  ),
                  title: const Text(Teks.ujiSuara),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RecordScreen(app: app)),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: TartilColors.hijau,
                  ),
                  title: const Text(Teks.tentang),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AboutScreen(quran: app.quran),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  '${Teks.appName} · ${Teks.kepanjangan}',
                  style: TextStyle(color: Colors.black38, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const _cycleChoices = [7, 10, 12, 14, 15, 20, 30];

  Future<void> _pickCycle(BuildContext context, Profile p) async {
    final n = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Teks.pilihSiklus, style: Theme.of(c).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(Teks.pilihSiklusKet, style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final d in _cycleChoices)
              ChoiceChip(
                label: Text('$d hari'),
                selected: d == p.cycleDays,
                onSelected: (_) => Navigator.pop(c, d),
              ),
            ActionChip(
              label: const Text(Teks.lainnyaSiklus),
              onPressed: () => Navigator.pop(c, -1),
            ),
          ]),
        ]),
      ),
    );
    if (n == null || n == p.cycleDays || !context.mounted) return;
    if (n == -1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileForm(app: app, profile: p)));
      return;
    }
    if (p.cycle!.days.any((d) => d.done)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(Teks.konfirmasiSiklus(n)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text(Teks.batal)),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text(Teks.ya)),
          ],
        ),
      );
      if (ok != true) return;
    }
    p.cycleDays = n;
    await app.upsert(p, resetCycle: true);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Teks.mulaiUlangSiklus)));
    }
  }

  String _summary(Profile x) {
    final c = x.cycle;
    if (c == null) return '';
    final i = c.indexOf(DateTime.now()).clamp(0, c.length - 1);
    return Teks.hariKe(i + 1, c.length);
  }

  Widget _card(List<Widget> children) => Material(
    color: Colors.white,
    elevation: 2,
    shadowColor: const Color(0x33000000),
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 64),
          children[i],
        ],
      ],
    ),
  );
}
