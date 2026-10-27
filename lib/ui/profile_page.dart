import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/store.dart';
import '../teks.dart';
import 'about_screen.dart';
import 'profile_form.dart';
import 'record_screen.dart';
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
        : Teks.rentangSurah(app.quran.surah(r.fromSurah!).name, app.quran.surah(r.toSurah!).name);
    final jam = '${p.reminderHour.toString().padLeft(2, '0')}:${p.reminderMinute.toString().padLeft(2, '0')}';
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        HeaderBackground(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(children: [
                ProfileAvatar(profile: p, radius: 42, ring: true),
                const SizedBox(height: 12),
                Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('$range · ${Teks.siklusHari(p.cycleDays)}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 2),
                Text(Teks.pengingatJam(jam), style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ProfileForm(app: app, profile: p))),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text(Teks.pengaturanProfil),
                ),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionTitle(Teks.gantiProfil),
            _card([
              for (final x in app.profiles)
                ListTile(
                  leading: ProfileAvatar(profile: x, radius: 18),
                  title: Text(x.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_summary(x)),
                  trailing: x.id == p.id
                      ? const Icon(Icons.check_circle, color: TartilColors.hijau)
                      : const Icon(Icons.chevron_right),
                  onTap: () => app.setActive(x),
                ),
              ListTile(
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: TartilColors.hijauMuda,
                  child: Icon(Icons.add, color: TartilColors.hijau),
                ),
                title: const Text(Teks.tambahProfil, style: TextStyle(color: TartilColors.hijau, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileForm(app: app))),
              ),
            ]),
            const SectionTitle(Teks.lainnya),
            _card([
              ListTile(
                leading: const Icon(Icons.graphic_eq, color: TartilColors.hijau),
                title: const Text(Teks.ujiSuara),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecordScreen(app: app))),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: TartilColors.hijau),
                title: const Text(Teks.tentang),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AboutScreen(quran: app.quran))),
              ),
            ]),
            const SizedBox(height: 16),
            const Center(child: Text('${Teks.appName} · ${Teks.kepanjangan}', style: TextStyle(color: Colors.black38, fontSize: 12))),
          ]),
        ),
      ],
    );
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
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 64),
            children[i],
          ],
        ]),
      );
}
