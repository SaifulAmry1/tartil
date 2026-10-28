import 'package:flutter/material.dart';

import '../core/cycle.dart';
import '../core/schedule.dart';
import '../core/stats.dart';
import '../models/profile.dart';
import '../services/store.dart';
import '../teks.dart';
import 'day_screen.dart';
import 'plan_screen.dart';
import 'report_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// Beranda: ringkasan siklus, statistik, dan murojaah hari ini.
class DashboardPage extends StatelessWidget {
  final AppState app;
  final Profile profile;
  final VoidCallback onOpenSchedule;

  const DashboardPage({super.key, required this.app, required this.profile, required this.onOpenSchedule});

  @override
  Widget build(BuildContext context) {
    final cycle = profile.cycle!;
    final now = DateTime.now();
    final st = CycleStats.of(cycle, now);
    final day = cycle.days[st.today];
    final off = cycle.isOff(now);
    final scores = profile.scores.values;
    final avg = scores.isEmpty ? '-' : '${(scores.reduce((a, b) => a + b) / scores.length).round()}';
    final weak = profile.weakSurahs.toList()..sort();

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: HeaderBackground(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Rub(size: 26, color: TartilColors.emas),
                  const SizedBox(width: 8),
                  const Text(Teks.appName,
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  const Spacer(),
                  IconButton(
                    tooltip: Teks.pantauAnak,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.family_restroom, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const ParentHome(inApp: true),
                    )),
                  ),
                  IconButton(
                    tooltip: Teks.pantauOrtu,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.qr_code_2, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ShareReportScreen(app: app, profile: profile),
                    )),
                  ),
                ]),
                const SizedBox(height: 18),
                const Text(Teks.salam, style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(profile.name,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(children: [
                    ProgressRing(
                      value: st.done / cycle.length,
                      size: 92,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${(st.done * 100 / cycle.length).round()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        Text(Teks.hariDari(st.done, cycle.length),
                            style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tanggalHari(now),
                            style: const TextStyle(color: TartilColors.emas, fontSize: 13.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(Teks.hariKe(st.today + 1, cycle.length),
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          _pill(Teks.siklusKe(cycle.number)),
                          _pill(_rangeLabel()),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        sliver: SliverList.list(children: [
          Row(children: [
            Expanded(child: StatTile(icon: Icons.local_fire_department, value: '${st.streak}', label: Teks.hariBeruntun, color: TartilColors.oranye)),
            const SizedBox(width: 10),
            Expanded(child: StatTile(icon: Icons.task_alt, value: '${st.done}', label: Teks.hariSelesai, color: TartilColors.hijau)),
            const SizedBox(width: 10),
            Expanded(child: StatTile(icon: Icons.event_busy, value: '${st.missed}', label: Teks.hariTerlewat, color: Colors.blueGrey)),
            const SizedBox(width: 10),
            Expanded(child: StatTile(icon: Icons.star_rounded, value: avg, label: Teks.rataNilai, color: TartilColors.emas)),
          ]),
          if (off) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFFF6E0), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.beach_access_outlined, color: TartilColors.oranye),
                const SizedBox(width: 10),
                Expanded(child: Text(Teks.liburHariIni(namaHari(now)), style: const TextStyle(fontWeight: FontWeight.w600))),
              ]),
            ),
          ],
          SectionTitle(off ? '${Teks.liburBesok} · ${tanggalHari(cycle.dateOf(st.today))}' : Teks.jadwalHariIni,
              trailing: Text(Teks.menit(dayLoad(day.units)), style: const TextStyle(color: Colors.black54))),
          if (day.units.isEmpty) const Card(child: ListTile(title: Text(Teks.libur))),
          for (final u in day.units) UnitCard(app: app, profile: profile, unit: u, dayIndex: st.today),
          if (!off) ...[
            const SizedBox(height: 8),
            _doneButton(context, st.today, day.done),
          ],
          if (day.done || off) _aheadButton(context, cycle, st.today + (off ? 0 : 1)),
          if (weak.isNotEmpty) ...[
            const SectionTitle(Teks.perluDiulang),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in weak)
                Chip(
                  avatar: const Icon(Icons.replay, size: 16, color: TartilColors.oranye),
                  label: Text('${app.quran.surah(s).name} · ${profile.scores[s]}'),
                  backgroundColor: const Color(0xFFFFF1E6),
                  side: BorderSide.none,
                ),
            ]),
          ],
          SectionTitle(Teks.berikutnya,
              trailing: TextButton(onPressed: onOpenSchedule, child: const Text(Teks.semuaJadwal))),
          SizedBox(
            height: 128,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = st.today + 1; i < cycle.length && i <= st.today + 6; i++)
                  GestureDetector(
                    onTap: () => _openDay(context, i),
                    child: _UpcomingCard(app: app, profile: profile, index: i, now: now),
                  ),
              ],
            ),
          ),
          const SectionTitle(Teks.pantauAnakJudul),
          const ChildrenCard(),
        ]),
      ),
    ]);
  }

  String _rangeLabel() {
    final r = profile.range;
    return r.isJuz ? Teks.rentangJuz(r.juz) : Teks.rentangSurah(app.quran.surah(r.fromSurah!).name, app.quran.surah(r.toSurah!).name);
  }

  void _openDay(BuildContext context, int i) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => DayScreen(app: app, profile: profile, index: i)));

  /// Tombol menuju hari berikutnya yang belum selesai, untuk murojaah lebih.
  Widget _aheadButton(BuildContext context, Cycle cycle, int from) {
    int? next;
    for (var i = from; i < cycle.length; i++) {
      if (!cycle.days[i].done && cycle.days[i].units.isNotEmpty) {
        next = i;
        break;
      }
    }
    if (next == null) return const SizedBox.shrink();
    final target = next;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () => _openDay(context, target),
        icon: const Icon(Icons.fast_forward_rounded),
        label: const Text(Teks.lanjutBesok),
      ),
    );
  }

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 12)),
      );

  Widget _doneButton(BuildContext context, int index, bool done) {
    if (done) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: TartilColors.hijauMuda, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(Icons.verified, color: TartilColors.hijau),
          const SizedBox(width: 10),
          const Expanded(child: Text(Teks.alhamdulillah, style: TextStyle(fontWeight: FontWeight.w600))),
          TextButton(onPressed: () => app.setDayDone(profile, index, false), child: const Text(Teks.batal)),
        ]),
      );
    }
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () => app.setDayDone(profile, index, true),
      icon: const Icon(Icons.check_circle_outline),
      label: Text(_partialLabel(index) ?? Teks.tandaiSelesai,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
    );
  }

  /// "2 dari 4 bacaan selesai" bila sebagian surah sudah dicentang.
  String? _partialLabel(int index) {
    final d = profile.cycle!.days[index];
    if (!d.partial) return null;
    final n = d.units.where(d.isUnitDone).length;
    return '${Teks.tandaiSemua} ($n/${d.units.length})';
  }
}

class _UpcomingCard extends StatelessWidget {
  final AppState app;
  final Profile profile;
  final int index;
  final DateTime now;

  const _UpcomingCard({required this.app, required this.profile, required this.index, required this.now});

  @override
  Widget build(BuildContext context) {
    final c = profile.cycle!;
    final d = c.days[index];
    final date = c.dateOf(index);
    final names = d.units.map((u) => app.quran.surah(u.surah).name).toSet().toList();
    return Container(
      width: 168,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TartilColors.emas.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(daysBetween(now, date) == 1 ? Teks.besok : namaHari(date),
              style: const TextStyle(fontWeight: FontWeight.w700, color: TartilColors.hijau)),
          const Spacer(),
          Text(tanggalPendek(date), style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ]),
        const SizedBox(height: 6),
        Expanded(
          child: Text(names.isEmpty ? Teks.libur : names.join(', '),
              maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
        ),
        Text(Teks.menit(dayLoad(d.units)), style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ]),
    );
  }
}
