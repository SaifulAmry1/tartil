import 'package:flutter/material.dart';

import '../core/cycle.dart';
import '../core/schedule.dart';
import '../models/profile.dart';
import '../services/store.dart';
import '../teks.dart';
import 'profile_form.dart';
import 'reader_screen.dart';
import 'record_screen.dart';
import 'theme.dart';

/// Jadwal murojaah satu profil: bacaan hari ini dan seluruh siklus.
class PlanScreen extends StatelessWidget {
  final AppState app;
  final Profile profile;

  const PlanScreen({super.key, required this.app, required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final cycle = profile.cycle!;
        final today = cycle.indexOf(DateTime.now()).clamp(0, cycle.length - 1);
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(profile.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ProfileForm(app: app, profile: profile))),
                ),
              ],
              bottom: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: TartilColors.emas,
                tabs: [Tab(text: Teks.jadwalHariIni), Tab(text: Teks.semuaJadwal)],
              ),
            ),
            body: TabBarView(children: [
              _Today(app: app, profile: profile, dayIndex: today),
              _AllDays(app: app, profile: profile, today: today),
            ]),
          ),
        );
      },
    );
  }
}

class _Today extends StatelessWidget {
  final AppState app;
  final Profile profile;
  final int dayIndex;

  const _Today({required this.app, required this.profile, required this.dayIndex});

  @override
  Widget build(BuildContext context) {
    final cycle = profile.cycle!;
    final day = cycle.days[dayIndex];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          const Rub(size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(Teks.hariKe(dayIndex + 1, cycle.length), style: Theme.of(context).textTheme.titleLarge),
              Text('${Teks.siklusKe(cycle.number)} · ${Teks.menit(dayLoad(day.units))}'),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        if (day.units.isEmpty) const ListTile(title: Text(Teks.libur)),
        for (final u in day.units) UnitCard(app: app, profile: profile, unit: u),
        const SizedBox(height: 16),
        if (day.done) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: TartilColors.hijauMuda, borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.check_circle, color: TartilColors.hijau),
              SizedBox(width: 10),
              Expanded(child: Text(Teks.alhamdulillah)),
            ]),
          ),
          TextButton(
            onPressed: () => app.setDayDone(profile, dayIndex, false),
            child: const Text(Teks.batalSelesai),
          ),
        ] else
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => app.setDayDone(profile, dayIndex, true),
            icon: const Icon(Icons.check),
            label: const Text(Teks.tandaiSelesai, style: TextStyle(fontSize: 18)),
          ),
      ],
    );
  }
}

class UnitCard extends StatelessWidget {
  final AppState app;
  final Profile profile;
  final Unit unit;

  const UnitCard({super.key, required this.app, required this.profile, required this.unit});

  @override
  Widget build(BuildContext context) {
    final s = app.quran.surah(unit.surah);
    final score = profile.scores[unit.surah];
    final range = unit.isWhole ? '${s.ayahCount} ayat' : Teks.ayat(unit.fromAyah, unit.toAyah);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('${s.number}. ${s.name}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
            Text(s.arabicName,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, color: TartilColors.hijau)),
          ]),
          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text('$range · ${Teks.menit(unit.seconds)}'),
            if (unit.review)
              const Chip(label: Text(Teks.ulang), visualDensity: VisualDensity.compact),
            if (score != null)
              Chip(
                label: Text(Teks.nilai(score)),
                visualDensity: VisualDensity.compact,
                backgroundColor: score < Profile.weakThreshold ? const Color(0xFFFFE0CC) : TartilColors.hijauMuda,
              ),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton.icon(
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text(Teks.baca),
              onPressed: () {
                final (first, _) = app.quran.pagesOf(unit.surah, unit.fromAyah, unit.toAyah);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ReaderScreen(
                    quran: app.quran,
                    startPage: first,
                    title: s.name,
                    highlight: (surah: unit.surah, from: unit.fromAyah, to: unit.toAyah),
                  ),
                ));
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.mic_none),
              label: const Text(Teks.rekam),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => RecordScreen(
                  app: app,
                  profile: profile,
                  surah: unit.surah,
                  fromAyah: unit.fromAyah,
                  toAyah: unit.toAyah,
                ),
              )),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _AllDays extends StatelessWidget {
  final AppState app;
  final Profile profile;
  final int today;

  const _AllDays({required this.app, required this.profile, required this.today});

  @override
  Widget build(BuildContext context) {
    final Cycle cycle = profile.cycle!;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cycle.length,
      itemBuilder: (context, i) {
        final d = cycle.days[i];
        final names = d.units.map((u) {
          final n = app.quran.surah(u.surah).name;
          final part = u.isWhole ? '' : ' (${u.fromAyah}-${u.toAyah})';
          return '$n$part${u.review ? ' [${Teks.ulang}]' : ''}';
        }).join(', ');
        final date = cycle.start.add(Duration(days: i));
        return Card(
          color: i == today ? TartilColors.hijauMuda : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: d.done
                  ? TartilColors.hijau
                  : d.missed
                      ? Colors.grey
                      : TartilColors.emas.withValues(alpha: 0.25),
              foregroundColor: d.done ? Colors.white : Colors.black87,
              child: d.done ? const Icon(Icons.check) : Text('${i + 1}'),
            ),
            title: Text(d.missed ? Teks.terlewat : (names.isEmpty ? Teks.libur : names)),
            subtitle: Text('${date.day}/${date.month} · ${Teks.menit(dayLoad(d.units))}'),
          ),
        );
      },
    );
  }
}
