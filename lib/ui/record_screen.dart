import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../core/recitation_check.dart';
import '../data/quran_data.dart';
import '../models/profile.dart';
import '../services/asr.dart';
import '../services/store.dart';
import '../teks.dart';
import 'theme.dart';

/// Rekam murojaah satu bacaan lalu periksa kata yang salah atau terlewat.
/// Tanpa [surah], layar ini menjadi "Uji suara" dengan pilihan surah.
class RecordScreen extends StatefulWidget {
  final AppState app;
  final Profile? profile;
  final int? surah;
  final int? fromAyah;
  final int? toAyah;

  const RecordScreen({
    super.key,
    required this.app,
    this.profile,
    this.surah,
    this.fromAyah,
    this.toAyah,
  });

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

enum _Phase { siap, merekam, memproses, hasil }

class _RecordScreenState extends State<RecordScreen> {
  final _rec = AudioRecorder();
  late int _surah = widget.surah ?? 112;
  late int _from = widget.fromAyah ?? 1;
  late int _to = widget.toAyah ?? widget.app.quran.surah(_surah).ayahCount;
  _Phase _phase = _Phase.siap;
  bool? _modelOk;
  bool _prompt = false;
  String? _error;
  String _heard = '';
  CheckResult? _result;
  DateTime? _startedAt;
  Duration _recLen = Duration.zero;
  Duration _procLen = Duration.zero;
  Timer? _ticker;

  QuranData get quran => widget.app.quran;
  bool get _testMode => widget.surah == null;

  @override
  void initState() {
    super.initState();
    Asr.available().then((ok) => setState(() => _modelOk = ok));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _rec.dispose();
    super.dispose();
  }

  List<String> get _expected => [
        for (final a in quran.ayahRange(_surah, _from, _to)) ...splitWords(a.text),
      ];

  Future<void> _start() async {
    setState(() => _error = null);
    if (!await _rec.hasPermission()) {
      setState(() => _error = Teks.izinMikrofon);
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/murojaah_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        noiseSuppress: true,
      ),
      path: path,
    );
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recLen = DateTime.now().difference(_startedAt!));
    });
    setState(() => _phase = _Phase.merekam);
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    final path = await _rec.stop();
    _recLen = DateTime.now().difference(_startedAt!);
    setState(() => _phase = _Phase.memproses);
    if (path == null) {
      setState(() {
        _phase = _Phase.siap;
        _error = 'Rekaman gagal disimpan.';
      });
      return;
    }
    final t0 = DateTime.now();
    try {
      final text = await Asr.transcribe(
        path,
        prompt: _prompt ? _expected.join(' ') : null,
      );
      _procLen = DateTime.now().difference(t0);
      final result = compareRecitation(_expected, splitWords(text));
      if (widget.profile != null) {
        await widget.app.saveScore(widget.profile!, _surah, result.score);
      }
      setState(() {
        _heard = text;
        _result = result;
        _phase = _Phase.hasil;
      });
    } catch (e) {
      setState(() {
        _phase = _Phase.siap;
        _error = '$e';
      });
    } finally {
      try {
        await File(path).delete();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = quran.surah(_surah);
    return Scaffold(
      appBar: AppBar(title: Text(_testMode ? Teks.ujiSuara : Teks.rekamMurojaah)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_testMode) ...[
            const Text(Teks.ujiSuaraKet),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _surah,
              decoration: const InputDecoration(labelText: Teks.pilihSurah),
              items: [
                for (final x in quran.surahs)
                  DropdownMenuItem(value: x.number, child: Text('${x.number}. ${x.name}')),
              ],
              onChanged: _phase == _Phase.merekam || _phase == _Phase.memproses
                  ? null
                  : (v) => setState(() {
                        _surah = v!;
                        _from = 1;
                        _to = quran.surah(v).ayahCount;
                        _result = null;
                        _phase = _Phase.siap;
                      }),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(Teks.petunjukTeks),
              subtitle: const Text(Teks.petunjukTeksKet),
              value: _prompt,
              onChanged: (v) => setState(() => _prompt = v),
            ),
          ] else
            Text('${s.name} · ${Teks.ayat(_from, _to)}',
                style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (_modelOk == false)
            _notice(Teks.modelTidakAda, TartilColors.merah)
          else
            _controls(),
          if (_error != null) _notice(_error!, TartilColors.merah),
          if (_result != null) ..._resultView(_result!),
        ],
      ),
    );
  }

  Widget _controls() {
    switch (_phase) {
      case _Phase.siap:
      case _Phase.hasil:
        return FilledButton.icon(
          onPressed: _modelOk == true ? _start : null,
          icon: const Icon(Icons.mic),
          label: const Text(Teks.mulaiRekam),
        );
      case _Phase.merekam:
        return Column(children: [
          Text('${Teks.merekam} ${_recLen.inMinutes}:${(_recLen.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 18, color: TartilColors.merah)),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: TartilColors.merah),
            onPressed: _stop,
            icon: const Icon(Icons.stop),
            label: const Text(Teks.berhenti),
          ),
        ]);
      case _Phase.memproses:
        return const Column(children: [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text(Teks.memproses),
        ]);
    }
  }

  Widget _notice(String text, Color color) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(text, style: TextStyle(color: color)),
      );

  List<Widget> _resultView(CheckResult r) {
    final wrong = r.words.where((w) => w.status == WordStatus.salah).toList();
    final missed = r.words.where((w) => w.status == WordStatus.terlewat).toList();
    return [
      const SizedBox(height: 20),
      Row(children: [
        Rub(
          size: 64,
          child: Text('${r.score}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TartilColors.hijau)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            wrong.isEmpty && missed.isEmpty ? Teks.semuaBenar : Teks.hasil,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ]),
      if (widget.profile != null && r.score < Profile.weakThreshold)
        _notice(Teks.surahLemah, TartilColors.oranye),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            textDirection: TextDirection.rtl,
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final w in r.words)
                Text(
                  w.expected,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 24,
                    height: 1.9,
                    color: switch (w.status) {
                      WordStatus.benar => Colors.black87,
                      WordStatus.salah => TartilColors.merah,
                      WordStatus.terlewat => TartilColors.oranye,
                    },
                    decoration: w.status == WordStatus.benar ? null : TextDecoration.underline,
                  ),
                ),
            ],
          ),
        ),
      ),
      for (final w in wrong)
        ListTile(
          leading: const Icon(Icons.close, color: TartilColors.merah),
          title: Text('${Teks.kataSalah}: ${Teks.seharusnya} ${w.expected}', textDirection: TextDirection.ltr),
          subtitle: Text('${Teks.terdengar}: ${w.heard}'),
        ),
      for (final w in missed)
        ListTile(
          leading: const Icon(Icons.remove_circle_outline, color: TartilColors.oranye),
          title: Text('${Teks.kataTerlewat}: ${w.expected}'),
        ),
      if (r.extra.isNotEmpty)
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: const Text(Teks.kataTambahan),
          subtitle: Text(r.extra.join(' '), textDirection: TextDirection.rtl),
        ),
      ExpansionTile(
        title: const Text(Teks.detailTeknis),
        children: [
          ListTile(title: Text(Teks.waktuProses(_recLen, _procLen))),
          ListTile(title: Text(_heard, textDirection: TextDirection.rtl)),
        ],
      ),
    ];
  }
}
