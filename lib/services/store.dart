// Penyimpanan lokal semua profil (tanpa login, tanpa server).
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/cycle.dart';
import '../data/quran_data.dart';
import '../models/profile.dart';
import 'notifications.dart';

class AppState extends ChangeNotifier {
  static const _key = 'profil_v1';

  final QuranData quran;
  final SharedPreferences _prefs;
  final List<Profile> profiles = [];

  AppState._(this.quran, this._prefs);

  static Future<AppState> load() async {
    final quran = QuranData.parse(
        await rootBundle.loadString('assets/quran/quran.json'));
    final prefs = await SharedPreferences.getInstance();
    final s = AppState._(quran, prefs);
    final raw = prefs.getString(_key);
    if (raw != null) {
      for (final p in jsonDecode(raw) as List) {
        s.profiles.add(Profile.fromJson(p as Map<String, dynamic>));
      }
    }
    s.refreshAll();
    return s;
  }

  Future<void> _save() async {
    await _prefs.setString(
        _key, jsonEncode([for (final p in profiles) p.toJson()]));
    notifyListeners();
  }

  /// Pastikan jadwal tiap profil sesuai tanggal hari ini (hari terlewat,
  /// siklus baru).
  void refreshAll() {
    var changed = false;
    for (final p in profiles) {
      changed |= _refresh(p);
    }
    if (changed) _save();
  }

  bool _refresh(Profile p) {
    final today = DateTime.now();
    final surahs = quran.durations(p.range);
    final before = p.cycle == null ? null : jsonEncode(p.cycle!.toJson());
    p.cycle = p.cycle == null
        ? Cycle.create(surahs, p.cycleDays, today, weakSurahs: p.weakSurahs)
        : p.cycle!.reconcile(today, surahs, weakSurahs: p.weakSurahs);
    return before != jsonEncode(p.cycle!.toJson());
  }

  Future<void> upsert(Profile p, {bool resetCycle = false}) async {
    if (resetCycle) p.cycle = null;
    final i = profiles.indexWhere((x) => x.id == p.id);
    if (i < 0) {
      profiles.add(p);
    } else {
      profiles[i] = p;
    }
    _refresh(p);
    await _save();
    await Notifications.schedule(p, profiles.indexOf(p));
  }

  Future<void> remove(Profile p) async {
    await Notifications.cancel(profiles.indexOf(p));
    profiles.remove(p);
    await _save();
    // Indeks notifikasi bergeser; jadwalkan ulang semuanya.
    await Notifications.rescheduleAll(profiles);
  }

  Future<void> setDayDone(Profile p, int dayIndex, bool done) async {
    p.cycle!.days[dayIndex].doneAt = done ? DateTime.now() : null;
    await _save();
  }

  Future<void> saveScore(Profile p, int surah, int score) async {
    final wasWeak = p.weakSurahs.contains(surah);
    p.scores[surah] = score;
    if (!wasWeak && score < Profile.weakThreshold && p.cycle != null) {
      p.cycle!.addWeak(surah, quran.durations(p.range), DateTime.now());
    }
    await _save();
  }
}
