import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/report.dart';
import '../data/surah_names.dart';
import '../models/profile.dart';
import '../models/recording_log.dart';
import '../services/store.dart';
import '../services/sync.dart';
import '../teks.dart';
import 'theme.dart';
import 'widgets.dart';

String _surah(int n) => surahNames[n - 1];

/// Ringkasan singkat untuk dikirim lewat WhatsApp atau aplikasi lain.
String ringkasanLaporan(Laporan l, String url) {
  final st = l.stats;
  final today = l.offToday
      ? Teks.liburHariIni(namaHari(l.generated))
      : l.today == DayStatus.selesai
          ? Teks.lapHariIniSelesai
          : Teks.lapHariIniBelum;
  final last = l.recordings.isEmpty ? null : l.recordings.first;
  return [
    Teks.lapJudul(l.name, l.range),
    tanggalHari(l.generated),
    '${Teks.hariKe(st.today + 1, l.length)} · ${Teks.siklusKe(l.cycleNumber)}',
    Teks.lapAngka(st.done, l.length, st.missed, st.streak),
    today,
    if (last != null) Teks.lapRekamanTerakhir(_surah(last.surah), last.score),
    if (l.weak.isNotEmpty) '${Teks.perluDiulang}: ${l.weak.map((s) => '${_surah(s)} (${l.scores[s]})').join(', ')}',
    '',
    '${Teks.lapLihat}: $url',
  ].join('\n');
}

/// Layar di HP anak: QR dan link pantauan yang dibagikan ke orang tua.
class ShareReportScreen extends StatefulWidget {
  final AppState app;
  final Profile profile;

  const ShareReportScreen({super.key, required this.app, required this.profile});

  @override
  State<ShareReportScreen> createState() => _ShareReportScreenState();
}

class _ShareReportScreenState extends State<ShareReportScreen> {
  AppState get app => widget.app;
  Profile get p => widget.profile;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    if (p.syncId == null) {
      await app.enableSync(p);
    } else {
      await app.syncProfile(p);
    }
    if (mounted) setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final l = Laporan.of(p, app.rangeLabel(p), DateTime.now());
        final id = p.syncId;
        final url = id == null ? l.url : Laporan.liveUrl(id);
        final last = app.lastSync[p.id];
        final (statusText, statusColor, statusIcon) = _syncing
            ? (Teks.sinkronProses, Colors.black54, Icons.sync)
            : app.syncFailed.contains(p.id) || last == null
                ? (Teks.sinkronGagal, TartilColors.oranye, Icons.cloud_off)
                : (Teks.sinkronOk(waktuPendek(last)), TartilColors.hijau, Icons.cloud_done);
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
                    size: 240,
                    errorCorrectionLevel: id == null ? QrErrorCorrectLevel.L : QrErrorCorrectLevel.M,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: TartilColors.hijau),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0B3D31)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Flexible(child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12.5))),
                if (!_syncing && (app.syncFailed.contains(p.id) || last == null))
                  TextButton(onPressed: _sync, child: const Text(Teks.cobaLagi)),
              ]),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () => SharePlus.instance.share(ShareParams(text: ringkasanLaporan(l, url))),
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
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(laporan: l, live: true))),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text(Teks.lihatLaporan),
              ),
              const SizedBox(height: 12),
              const Text(Teks.pantauOrtuCatatan, style: TextStyle(color: Colors.black45, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}

/// Laporan yang dilihat orang tua (versi web) atau pratinjaunya di HP anak.
class ReportScreen extends StatelessWidget {
  final Laporan laporan;

  /// Data dari sinkron otomatis (bukan potret saat dibagikan).
  final bool live;
  final Future<void> Function()? onRefresh;

  const ReportScreen({super.key, required this.laporan, this.live = false, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l = laporan;
    final st = l.stats;
    final now = DateTime.now();
    final staleDays = daysBetweenLocal(l.generated, now);
    final stamp = live ? Teks.lapDiperbarui(waktuPendek(l.generated)) : Teks.lapDibuat(waktuPendek(l.generated));
    final (todayText, todayColor, todayIcon) = l.offToday
        ? (Teks.liburHariIni(namaHari(l.generated)), TartilColors.oranye, Icons.beach_access_outlined)
        : l.today == DayStatus.selesai
            ? (Teks.lapHariIniSelesai, TartilColors.hijau, Icons.verified)
            : (Teks.lapHariIniBelum, Colors.redAccent, Icons.schedule);

    final list = ListView(padding: EdgeInsets.zero, physics: const AlwaysScrollableScrollPhysics(), children: [
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
                const Expanded(
                  child: Text(Teks.lapNamaHalaman,
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                if (onRefresh != null)
                  IconButton(
                    tooltip: Teks.muatUlang,
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
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
                    Text(stamp, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
              child: Text(live ? Teks.lapTanpaAktivitas(staleDays) : Teks.lapKedaluwarsa(staleDays),
                  style: const TextStyle(fontSize: 13)),
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
          if (l.recordings.isNotEmpty) ...[
            const SectionTitle(Teks.lapRekaman),
            for (final r in l.recordings) _RecordingCard(r),
          ],
          const SectionTitle(Teks.lapRiwayat),
          for (var i = 0; i < l.length; i++) _dayRow(l, i, i == st.today && !l.offToday),
          const SizedBox(height: 16),
          const Center(
            child: Text('${Teks.appName} · ${Teks.kepanjangan}', style: TextStyle(color: Colors.black38, fontSize: 12)),
          ),
        ]),
      ),
    ]);

    return Scaffold(body: onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list));
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

/// Satu hasil rekaman: nilai, lalu kata yang salah beserta yang benar.
class _RecordingCard extends StatelessWidget {
  final RecordingLog r;
  const _RecordingCard(this.r);

  @override
  Widget build(BuildContext context) {
    final good = r.score >= Profile.weakThreshold;
    const arab = TextStyle(fontFamily: 'Hafs', fontSize: 20, height: 1.7);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x11000000)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: (good ? TartilColors.hijau : TartilColors.oranye).withValues(alpha: 0.14),
            child: Text('${r.score}',
                style: TextStyle(fontWeight: FontWeight.w800, color: good ? TartilColors.hijau : TartilColors.oranye)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_surah(r.surah)} · ${Teks.ayat(r.fromAyah, r.toAyah)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(waktuPendek(r.at), style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ]),
          ),
        ]),
        if (r.wrong.isEmpty && r.missed.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(Teks.semuaBenar, style: TextStyle(color: TartilColors.hijau)),
          ),
        for (final w in r.wrong)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              const Icon(Icons.close, size: 18, color: TartilColors.merah),
              const SizedBox(width: 6),
              Text('${Teks.seharusnya} ', style: const TextStyle(fontSize: 12.5)),
              Text(w[0], textDirection: TextDirection.rtl, style: arab.copyWith(color: TartilColors.hijau)),
              if (w[1].isNotEmpty) ...[
                Text(', ${Teks.terdengar} ', style: const TextStyle(fontSize: 12.5)),
                Flexible(child: Text(w[1], textDirection: TextDirection.rtl, style: arab.copyWith(color: TartilColors.merah))),
              ],
            ]),
          ),
        for (final m in r.missed)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              const Icon(Icons.remove_circle_outline, size: 18, color: TartilColors.oranye),
              const SizedBox(width: 6),
              Text('${Teks.kataTerlewat}: ', style: const TextStyle(fontSize: 12.5)),
              Text(m, textDirection: TextDirection.rtl, style: arab),
            ]),
          ),
      ]),
    );
  }
}

/// Selisih hari kalender (waktu setempat).
int daysBetweenLocal(DateTime a, DateTime b) =>
    DateTime(b.year, b.month, b.day).difference(DateTime(a.year, a.month, a.day)).inDays;

/// Aplikasi khusus versi web untuk orang tua: link laporan (?r=) atau
/// link pantauan (?p=) yang disimpan di browser dan selalu terbaru.
class ReportApp extends StatelessWidget {
  final Laporan? laporan;
  final String? syncId;
  final TransitionBuilder? builder;
  const ReportApp({super.key, this.laporan, this.syncId, this.builder});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '${Teks.lapNamaHalaman} · ${Teks.appName}',
        debugShowCheckedModeBanner: false,
        theme: tartilTheme(),
        builder: builder,
        home: syncId != null
            ? ParentHome(openId: syncId)
            : laporan == null
                ? const _Message(Teks.lapRusak)
                : ReportScreen(laporan: laporan!),
      );
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(text, textAlign: TextAlign.center))),
      );
}

/// Daftar anak yang dipantau orang tua. Setiap link yang pernah dipindai
/// tersimpan di browser ini.
class ParentHome extends StatefulWidget {
  final String? openId;
  const ParentHome({super.key, this.openId});

  @override
  State<ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<ParentHome> {
  static const _key = 'pantau_anak';
  List<String> _ids = [];
  final Map<String, Laporan?> _data = {};
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _init();
    // Perbarui sendiri selama halaman terbuka.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _ids = prefs.getStringList(_key) ?? [];
      final id = widget.openId;
      if (id != null && !_ids.contains(id)) {
        _ids.insert(0, id);
        await prefs.setStringList(_key, _ids);
      }
    } catch (_) {
      if (widget.openId != null && _ids.isEmpty) _ids = [widget.openId!];
    }
    await _load();
    final id = widget.openId;
    if (id != null && _data[id] != null && _ids.length == 1 && mounted) _open(id);
  }

  Future<void> _load() async {
    final results = await Future.wait(_ids.map(Sync.fetch));
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < _ids.length; i++) {
        // Pertahankan data lama bila pengambilan gagal sesaat.
        _data[_ids[i]] = results[i] ?? _data[_ids[i]];
      }
      _loading = false;
    });
  }

  Future<void> _remove(String id) async {
    setState(() {
      _ids.remove(id);
      _data.remove(id);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _ids);
    } catch (_) {}
  }

  void _open(String id) => Navigator.push(context, MaterialPageRoute(builder: (_) => _LiveReport(id: id, initial: _data[id])));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.zero, physics: const AlwaysScrollableScrollPhysics(), children: [
          HeaderBackground(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Rub(size: 26, color: TartilColors.emas),
                    SizedBox(width: 8),
                    Text(Teks.appName,
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  ]),
                  const SizedBox(height: 16),
                  const Text(Teks.ortuJudul, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(Teks.ortuKet(_ids.length), style: const TextStyle(color: Colors.white70)),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_loading) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
              if (!_loading && _ids.isEmpty) const Text(Teks.ortuKosong, textAlign: TextAlign.center),
              for (final id in _ids) _childCard(id),
              const SizedBox(height: 12),
              const Text(Teks.ortuCatatan, style: TextStyle(color: Colors.black45, fontSize: 12)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _childCard(String id) {
    final l = _data[id];
    if (l == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_off, color: TartilColors.oranye),
          title: const Text(Teks.ortuBelumAda),
          trailing: IconButton(tooltip: Teks.hapus, icon: const Icon(Icons.close), onPressed: () => _remove(id)),
        ),
      );
    }
    final st = l.stats;
    final (txt, col) = l.offToday
        ? (Teks.lapLibur, TartilColors.oranye)
        : l.today == DayStatus.selesai
            ? (Teks.lapSelesai, TartilColors.hijau)
            : (Teks.lapBelum, Colors.redAccent);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _open(id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            ProgressRing(
              value: st.done / l.length,
              size: 58,
              track: const Color(0x22000000),
              child: Text('${(st.done * 100 / l.length).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Text('${Teks.hariKe(st.today + 1, l.length)} · ${l.range}', style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: col.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text('${Teks.lapHariIni}: $txt', style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(Teks.lapDiperbarui(waktuPendek(l.generated)),
                        overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                  ),
                ]),
              ]),
            ),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    );
  }
}

/// Laporan satu anak yang memperbarui sendiri tiap menit.
class _LiveReport extends StatefulWidget {
  final String id;
  final Laporan? initial;
  const _LiveReport({required this.id, this.initial});

  @override
  State<_LiveReport> createState() => _LiveReportState();
}

class _LiveReportState extends State<_LiveReport> {
  late Laporan? _l = widget.initial;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _load());
    if (_l == null) _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final l = await Sync.fetch(widget.id);
    if (l != null && mounted) setState(() => _l = l);
  }

  @override
  Widget build(BuildContext context) => _l == null
      ? const Scaffold(body: Center(child: CircularProgressIndicator()))
      : ReportScreen(laporan: _l!, live: true, onRefresh: _load);
}
