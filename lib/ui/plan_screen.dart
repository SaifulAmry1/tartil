import 'package:flutter/material.dart';

import '../core/schedule.dart';
import '../core/stats.dart';
import '../models/profile.dart';
import '../services/store.dart';
import '../teks.dart';
import 'day_screen.dart';
import 'reader_screen.dart';
import 'record_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// Kartu satu bacaan: nama surah, rentang ayat, durasi, nilai, aksi.
class UnitCard extends StatelessWidget {
  final AppState app;
  final Profile profile;
  final Unit unit;

  /// Hari siklus tempat bacaan ini; bila diisi, kartu punya tombol
  /// tandai selesai per surah.
  final int? dayIndex;

  const UnitCard({super.key, required this.app, required this.profile, required this.unit, this.dayIndex});

  @override
  Widget build(BuildContext context) {
    final s = app.quran.surah(unit.surah);
    final score = profile.scores[unit.surah];
    final range = unit.isWhole ? '${s.ayahCount} ayat' : Teks.ayat(unit.fromAyah, unit.toAyah);
    final day = dayIndex == null ? null : profile.cycle!.days[dayIndex!];
    final canTick = day != null && !day.missed;
    final done = day != null && day.isUnitDone(unit);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFEFF7F3) : Colors.white,
        border: done ? Border.all(color: TartilColors.hijau.withValues(alpha: 0.35)) : null,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 6),
        child: Column(children: [
          Row(children: [
            Rub(
              size: 42,
              color: done ? TartilColors.hijau : TartilColors.emas,
              child: done
                  ? const Icon(Icons.check, size: 18, color: TartilColors.hijau)
                  : Text('${s.number}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TartilColors.hijau)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(s.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
                  ),
                  if (unit.review) ...[
                    const SizedBox(width: 6),
                    _tag(Teks.ulang, const Color(0xFFFFF1E6), TartilColors.oranye),
                  ],
                ]),
                const SizedBox(height: 2),
                Text('$range · ${Teks.menit(unit.seconds)}',
                    style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(s.arabicName,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, color: TartilColors.hijau)),
              if (score != null)
                _tag(Teks.nilai(score),
                    score < Profile.weakThreshold ? const Color(0xFFFFF1E6) : TartilColors.hijauMuda,
                    score < Profile.weakThreshold ? TartilColors.oranye : TartilColors.hijau),
            ]),
          ]),
          const Divider(height: 18),
          Row(children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.auto_stories_outlined, size: 20),
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
            ),
            Container(width: 1, height: 24, color: Colors.black12),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.mic_none_rounded, size: 20),
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
            ),
            if (canTick) ...[
              Container(width: 1, height: 24, color: Colors.black12),
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: done ? TartilColors.hijau : Colors.black54),
                  icon: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 20),
                  label: Text(done ? Teks.sudah : Teks.selesai),
                  onPressed: () => app.setUnitDone(profile, dayIndex!, unit, !done),
                ),
              ),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _tag(String t, Color bg, Color fg) => Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(t, style: TextStyle(fontSize: 11.5, color: fg, fontWeight: FontWeight.w600)),
      );
}

/// Seluruh hari dalam siklus, dengan status tiap hari.
class SchedulePage extends StatelessWidget {
  final AppState app;
  final Profile profile;

  const SchedulePage({super.key, required this.app, required this.profile});

  @override
  Widget build(BuildContext context) {
    final cycle = profile.cycle!;
    final now = DateTime.now();
    final st = CycleStats.of(cycle, now);
    return Scaffold(
      appBar: AppBar(
        title: const Text(Teks.semuaJadwal),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('${Teks.siklusKe(cycle.number)} · ${Teks.hariDari(st.done, cycle.length)}',
                style: const TextStyle(color: Colors.white70)),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        itemCount: cycle.length,
        itemBuilder: (context, i) {
          final d = cycle.days[i];
          final date = cycle.dateOf(i);
          final isToday = i == st.today && !cycle.isOff(now);
          final names = d.units.map((u) {
            final n = app.quran.surah(u.surah).name;
            final part = u.isWhole ? '' : ' (${u.fromAyah}-${u.toAyah})';
            return '$n$part${u.review ? ' (${Teks.ulang.toLowerCase()})' : ''}';
          }).join(', ');
          final (Color dot, IconData? icon) = d.done
              ? (TartilColors.hijau, Icons.check)
              : d.missed
                  ? (Colors.grey, Icons.close)
                  : d.partial
                      ? (const Color(0xFF7FBF9F), Icons.timelapse)
                  : isToday
                      ? (TartilColors.emas, null)
                      : (const Color(0xFFE5DCC5), null);
          return IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                width: 36,
                child: Column(children: [
                  Container(width: 2, height: 14, color: i == 0 ? Colors.transparent : const Color(0xFFE5DCC5)),
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: dot,
                    child: icon != null
                        ? Icon(icon, size: 15, color: Colors.white)
                        : Text('${i + 1}', style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w700)),
                  ),
                  Expanded(child: Container(width: 2, color: i == cycle.length - 1 ? Colors.transparent : const Color(0xFFE5DCC5))),
                ]),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DayScreen(app: app, profile: profile, index: i),
                  )),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isToday ? TartilColors.hijauMuda : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isToday ? TartilColors.hijau.withValues(alpha: 0.4) : const Color(0x11000000)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text('${namaHari(date)}, ${tanggalPendek(date)}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text(Teks.menit(dayLoad(d.units)), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ]),
                      const SizedBox(height: 4),
                      Text(d.missed ? Teks.terlewat : (names.isEmpty ? Teks.libur : names),
                          style: TextStyle(color: d.missed ? Colors.black45 : Colors.black87, fontSize: 13.5)),
                    ]),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}
