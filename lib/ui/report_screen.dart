import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../core/report.dart';
import '../data/surah_names.dart';
import '../models/profile.dart';
import '../services/store.dart';
import '../teks.dart';
import 'theme.dart';
import 'widgets.dart';

String _surah(int n) => surahNames[n - 1];

/// Ringkasan singkat untuk dikirim lewat WhatsApp atau aplikasi lain.
String ringkasanLaporan(Laporan l) {
  final st = l.stats;
  final today = l.offToday
      ? Teks.liburHariIni(namaHari(l.generated))
      : l.today == DayStatus.selesai
          ? Teks.lapHariIniSelesai
          : Teks.lapHariIniBelum;
  return [
    Teks.lapJudul(l.name, l.range),
    tanggalHari(l.generated),
    '${Teks.hariKe(st.today + 1, l.length)} · ${Teks.siklusKe(l.cycleNumber)}',
    Teks.lapAngka(st.done, l.length, st.missed, st.streak),
    today,
    if (l.weak.isNotEmpty) '${Teks.perluDiulang}: ${l.weak.map((s) => '${_surah(s)} (${l.scores[s]})').join(', ')}',
    '',
    '${Teks.lapLihat}: ${l.url}',
  ].join('\n');
}

/// Layar di HP anak: QR dan link yang dibagikan ke orang tua.
class ShareReportScreen extends StatelessWidget {
  final AppState app;
  final Profile profile;
  final String rangeLabel;

  const ShareReportScreen({super.key, required this.app, required this.profile, required this.rangeLabel});

  @override
  Widget build(BuildContext context) {
    final l = Laporan.of(profile, rangeLabel, DateTime.now());
    final url = l.url;
    return Scaffold(
      appBar: AppBar(title: const Text(Teks.pantauOrtu)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(Teks.pantauOrtuKet, style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 6))],
              ),
              child: QrImageView(
                data: url,
                size: 260,
                errorCorrectionLevel: QrErrorCorrectLevel.L,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: TartilColors.hijau),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0B3D31)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text('${profile.name} · ${Teks.lapDibuat(waktuPendek(l.generated))}',
                style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: () => SharePlus.instance.share(ShareParams(text: ringkasanLaporan(l))),
            icon: const Icon(Icons.share),
            label: const Text(Teks.kirimLaporan),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Teks.linkDisalin)));
              }
            },
            icon: const Icon(Icons.link),
            label: const Text(Teks.salinLink),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(laporan: l))),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text(Teks.lihatLaporan),
          ),
          const SizedBox(height: 12),
          const Text(Teks.pantauOrtuCatatan, style: TextStyle(color: Colors.black45, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Laporan yang dilihat orang tua (versi web) atau pratinjaunya di HP anak.
class ReportScreen extends StatelessWidget {
  final Laporan laporan;
  const ReportScreen({super.key, required this.laporan});

  @override
  Widget build(BuildContext context) {
    final l = laporan;
    final st = l.stats;
    final now = DateTime.now();
    final staleDays = daysBetweenLocal(l.generated, now);
    final (todayText, todayColor, todayIcon) = l.offToday
        ? (Teks.liburHariIni(namaHari(l.generated)), TartilColors.oranye, Icons.beach_access_outlined)
        : l.today == DayStatus.selesai
            ? (Teks.lapHariIniSelesai, TartilColors.hijau, Icons.verified)
            : (Teks.lapHariIniBelum, Colors.redAccent, Icons.schedule);

    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        HeaderBackground(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  const Rub(size: 24, color: TartilColors.emas),
                  const SizedBox(width: 8),
                  const Text(Teks.lapNamaHalaman,
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 16),
                Text(l.name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                Text('${l.range} · ${Teks.siklusKe(l.cycleNumber)}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                Row(children: [
                  ProgressRing(
                    value: st.done / l.length,
                    size: 88,
                    child: Text('${(st.done * 100 / l.length).round()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tanggalHari(l.generated),
                          style: const TextStyle(color: TartilColors.emas, fontWeight: FontWeight.w600)),
                      Text(Teks.hariKe(st.today + 1, l.length),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(Teks.lapDibuat(waktuPendek(l.generated)),
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                ]),
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (staleDays >= 1)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFF1E6), borderRadius: BorderRadius.circular(14)),
                child: Text(Teks.lapKedaluwarsa(staleDays), style: const TextStyle(fontSize: 13)),
              ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: todayColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Icon(todayIcon, color: todayColor),
                const SizedBox(width: 10),
                Expanded(child: Text(todayText, style: const TextStyle(fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: StatTile(icon: Icons.local_fire_department, value: '${st.streak}', label: Teks.hariBeruntun, color: TartilColors.oranye)),
              const SizedBox(width: 10),
              Expanded(child: StatTile(icon: Icons.task_alt, value: '${st.done}', label: Teks.hariSelesai, color: TartilColors.hijau)),
              const SizedBox(width: 10),
              Expanded(child: StatTile(icon: Icons.event_busy, value: '${st.missed}', label: Teks.hariTerlewat, color: Colors.blueGrey)),
              const SizedBox(width: 10),
              Expanded(child: StatTile(icon: Icons.star_rounded, value: l.averageScore ?? '-', label: Teks.rataNilai, color: TartilColors.emas)),
            ]),
            if (l.weak.isNotEmpty) ...[
              const SectionTitle(Teks.perluDiulang),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in l.weak)
                  Chip(
                    avatar: const Icon(Icons.replay, size: 16, color: TartilColors.oranye),
                    label: Text('${_surah(s)} · ${l.scores[s]}'),
                    backgroundColor: const Color(0xFFFFF1E6),
                    side: BorderSide.none,
                  ),
              ]),
            ],
            const SectionTitle(Teks.lapRiwayat),
            for (var i = 0; i < l.length; i++) _dayRow(l, i, i == st.today && !l.offToday),
            const SizedBox(height: 16),
            const Center(
              child: Text('${Teks.appName} · ${Teks.kepanjangan}', style: TextStyle(color: Colors.black38, fontSize: 12)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _dayRow(Laporan l, int i, bool isToday) {
    final s = l.days[i];
    final (Color color, IconData icon, String label) = switch (s) {
      DayStatus.selesai => (TartilColors.hijau, Icons.check_circle, Teks.lapSelesai),
      DayStatus.terlewat => (Colors.redAccent, Icons.cancel, Teks.lapTerlewat),
      DayStatus.belum => isToday
          ? (TartilColors.emas, Icons.radio_button_checked, Teks.lapHariIni)
          : (Colors.black26, Icons.radio_button_unchecked, Teks.lapBelum),
    };
    final names = l.surahs?[i].map(_surah).join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isToday ? TartilColors.hijauMuda : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x11000000)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('${i + 1}. ${tanggalHari(l.dateOf(i))}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            if (names != null && names.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(names, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
              ),
          ]),
        ),
      ]),
    );
  }
}

/// Selisih hari kalender (waktu setempat).
int daysBetweenLocal(DateTime a, DateTime b) =>
    DateTime(b.year, b.month, b.day).difference(DateTime(a.year, a.month, a.day)).inDays;

/// Aplikasi khusus versi web saat link laporan dibuka orang tua.
class ReportApp extends StatelessWidget {
  final Laporan? laporan;
  final TransitionBuilder? builder;
  const ReportApp({super.key, required this.laporan, this.builder});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '${Teks.lapNamaHalaman} · ${Teks.appName}',
        debugShowCheckedModeBanner: false,
        theme: tartilTheme(),
        builder: builder,
        home: laporan == null
            ? const Scaffold(body: Center(child: Padding(padding: EdgeInsets.all(24), child: Text(Teks.lapRusak, textAlign: TextAlign.center))))
            : ReportScreen(laporan: laporan!),
      );
}
