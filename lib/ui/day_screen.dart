import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/cycle.dart';
import '../core/schedule.dart';
import '../models/profile.dart';
import '../services/store.dart';
import '../teks.dart';
import 'plan_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// Rincian satu hari siklus. Geser kiri-kanan untuk pindah hari. Hari yang
/// akan datang boleh dimurojaah lebih awal lalu ditandai selesai.
class DayScreen extends StatefulWidget {
  final AppState app;
  final Profile profile;
  final int index;

  const DayScreen({super.key, required this.app, required this.profile, required this.index});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  late final _pages = PageController(initialPage: widget.index);
  late int _index = widget.index;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int delta) => _pages.animateToPage(_index + delta,
      duration: const Duration(milliseconds: 250), curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.app,
      builder: (context, _) {
        final c = widget.profile.cycle!;
        return Scaffold(
          appBar: AppBar(
            title: Text(Teks.hariKe(_index + 1, c.length)),
            actions: [
              IconButton(
                tooltip: Teks.hariSebelumnya,
                onPressed: _index > 0 ? () => _go(-1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: Teks.hariBerikutnya,
                onPressed: _index < c.length - 1 ? () => _go(1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          // Bisa digeser dengan jari maupun mouse (versi web).
          body: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
            ),
            child: PageView.builder(
              controller: _pages,
              itemCount: c.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _DayPage(app: widget.app, profile: widget.profile, index: i),
            ),
          ),
        );
      },
    );
  }
}

class _DayPage extends StatelessWidget {
  final AppState app;
  final Profile profile;
  final int index;

  const _DayPage({required this.app, required this.profile, required this.index});

  @override
  Widget build(BuildContext context) {
    final c = profile.cycle!;
    final d = c.days[index];
    final now = DateTime.now();
    final date = c.dateOf(index);
    final today = c.indexOf(now).clamp(0, c.length - 1);
    final future = index > today || (index == today && c.isOff(now));
    final past = index < today;

    final (String label, Color color, IconData icon) = d.done
        ? (future ? Teks.selesaiLebihAwal : Teks.lapSelesai, TartilColors.hijau, Icons.verified)
        : d.missed
            ? (Teks.terlewat, Colors.blueGrey, Icons.event_busy)
            : future
                ? (Teks.hariLagi(daysBetween(now, date)), TartilColors.emas, Icons.upcoming_outlined)
                : past
                    ? (Teks.lapBelum, Colors.black45, Icons.radio_button_unchecked)
                    : (Teks.lapHariIni, TartilColors.hijau, Icons.today);

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tanggalHari(date), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ]),
          ),
          Text(Teks.menit(dayLoad(d.units)), style: const TextStyle(color: Colors.black54)),
        ]),
      ),
      if (future && !d.done)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(Teks.lebihAwalKet(namaHari(date)), style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ),
      const SizedBox(height: 14),
      if (d.missed)
        const Card(child: ListTile(title: Text(Teks.terlewat)))
      else if (d.units.isEmpty)
        const Card(child: ListTile(title: Text(Teks.libur)))
      else
        for (final u in d.units) UnitCard(app: app, profile: profile, unit: u),
      const SizedBox(height: 8),
      if (!d.missed && d.units.isNotEmpty)
        d.done
            ? OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () => app.setDayDone(profile, index, false),
                icon: const Icon(Icons.undo),
                label: const Text(Teks.batalSelesai),
              )
            : FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => app.setDayDone(profile, index, true),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(future ? Teks.tandaiLebihAwal : Teks.tandaiSelesai,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
      const SizedBox(height: 16),
      Center(
        child: Text(Teks.geserHari, style: const TextStyle(color: Colors.black38, fontSize: 12)),
      ),
    ]);
  }
}
