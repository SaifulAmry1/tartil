import 'package:flutter/material.dart';

import '../core/cycle.dart';
import '../data/quran_data.dart';
import '../models/profile.dart';
import '../services/notifications.dart';
import '../services/store.dart';
import '../teks.dart';
import 'widgets.dart';

class ProfileForm extends StatefulWidget {
  final AppState app;
  final Profile? profile;

  const ProfileForm({super.key, required this.app, this.profile});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile?.name ?? '');
  late final _days = TextEditingController(text: '${widget.profile?.cycleDays ?? 12}');
  late bool _byJuz = widget.profile?.range.isJuz ?? true;
  late final Set<int> _juz = {...?widget.profile?.range.juz};
  late int _from = widget.profile?.range.fromSurah ?? 78;
  late int _to = widget.profile?.range.toSurah ?? 114;
  late TimeOfDay _time = TimeOfDay(
    hour: widget.profile?.reminderHour ?? 19,
    minute: widget.profile?.reminderMinute ?? 0,
  );
  late final Set<int> _off = {...widget.profile?.offDays ?? {Profile.defaultOffDay}};
  String? _juzError;

  @override
  void initState() {
    super.initState();
    if (widget.profile == null) _juz.addAll([29, 30]);
  }

  @override
  void dispose() {
    _name.dispose();
    _days.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _juzError = _byJuz && _juz.isEmpty ? Teks.juzKosong : null);
    if (!_form.currentState!.validate() || _juzError != null) return;
    final range = _byJuz
        ? HafalanRange.juz(_juz.toList()..sort())
        : HafalanRange.surah(_from <= _to ? _from : _to, _from <= _to ? _to : _from);
    final days = int.parse(_days.text);
    final old = widget.profile;
    final reset = old == null ||
        old.cycleDays != days ||
        old.range.toJson().toString() != range.toJson().toString();
    final p = old ?? Profile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '',
      range: range,
      cycleDays: days,
    );
    p
      ..name = _name.text.trim()
      ..range = range
      ..cycleDays = days
      ..reminderHour = _time.hour
      ..reminderMinute = _time.minute;
    final c = p.cycle;
    final offChanged = p.offDays.length != _off.length || !p.offDays.containsAll(_off);
    p.offDays = {..._off};
    if (!reset && offChanged && c != null) {
      // Hari libur berubah: kemajuan tetap, tanggal tiap hari disesuaikan.
      p.cycle = Cycle(Cycle.firstWorkday(c.start, p.offDays), c.days,
          number: c.number, offDays: p.offDays);
    }
    await Notifications.requestPermission();
    await widget.app.upsert(p, resetCycle: reset);
    if (!mounted) return;
    if (old != null && reset) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Teks.mulaiUlangSiklus)));
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(Teks.konfirmasiHapus(widget.profile!.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text(Teks.batal)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text(Teks.ya)),
        ],
      ),
    );
    if (ok != true) return;
    await widget.app.remove(widget.profile!);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final surahs = widget.app.quran.surahs;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile == null ? Teks.profilBaru : Teks.ubahProfil),
        actions: [
          if (widget.profile != null)
            IconButton(tooltip: Teks.hapus, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: Teks.nama, prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v == null || v.trim().isEmpty ? Teks.namaKosong : null,
            ),
            const SizedBox(height: 20),
            Text(Teks.rentang, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text(Teks.perJuz)),
                ButtonSegment(value: false, label: Text(Teks.perSurah)),
              ],
              selected: {_byJuz},
              onSelectionChanged: (s) => setState(() => _byJuz = s.first),
            ),
            const SizedBox(height: 12),
            if (_byJuz) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var j = 1; j <= 30; j++)
                    FilterChip(
                      label: Text('$j'),
                      selected: _juz.contains(j),
                      onSelected: (on) => setState(() => on ? _juz.add(j) : _juz.remove(j)),
                    ),
                ],
              ),
              if (_juzError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_juzError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
            ] else ...[
              DropdownButtonFormField<int>(
                initialValue: _from,
                isExpanded: true,
                decoration: const InputDecoration(labelText: Teks.dariSurah),
                items: [for (final s in surahs) DropdownMenuItem(value: s.number, child: Text('${s.number}. ${s.name}'))],
                onChanged: (v) => setState(() => _from = v!),
              ),
              DropdownButtonFormField<int>(
                initialValue: _to,
                isExpanded: true,
                decoration: const InputDecoration(labelText: Teks.sampaiSurah),
                items: [for (final s in surahs) DropdownMenuItem(value: s.number, child: Text('${s.number}. ${s.name}'))],
                onChanged: (v) => setState(() => _to = v!),
              ),
            ],
            const SizedBox(height: 20),
            TextFormField(
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: Teks.jumlahHari, prefixIcon: Icon(Icons.calendar_month)),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < 1 || n > 365 ? Teks.hariTidakSah : null;
              },
            ),
            const SizedBox(height: 20),
            Text(Teks.hariLibur, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            const Text(Teks.hariLiburKet, style: TextStyle(color: Colors.black54, fontSize: 12.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var w = DateTime.monday; w <= DateTime.sunday; w++)
                  FilterChip(
                    label: Text(namaHariKe(w)),
                    selected: _off.contains(w),
                    // Minimal satu hari dalam sepekan tetap hari murojaah.
                    onSelected: (on) => setState(() {
                      if (!on) {
                        _off.remove(w);
                      } else if (_off.length < 6) {
                        _off.add(w);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text(Teks.pengingat),
              trailing: Text(_time.format(context), style: Theme.of(context).textTheme.titleMedium),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: _time);
                if (t != null) setState(() => _time = t);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text(Teks.simpan)),
          ],
        ),
      ),
    );
  }
}
