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
  static const _activeKey = 'profil_aktif';

  final QuranData quran;
  final SharedPreferences _prefs;
  final List<Profile> profiles = [];
  String? _activeId;

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
    s._activeId = prefs.getString(_activeKey);
    s.refreshAll();
    return s;
  }

  /// Profil yang sedang dipakai di beranda (default: profil pertama).
  Profile? get active {
    if (profiles.isEmpty) return null;
    return profiles.firstWhere((p) => p.id == _activeId,
        orElse: () => profiles.first);
  }

  Future<void> setActive(Profile p) async {
    _activeId = p.id;
    await _prefs.setString(_activeKey, p.id);
    notifyListeners();
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
    // Selalu bangun ulang tampilan: tanggal di layar bisa sudah berganti.
    changed ? _save() : notifyListeners();
  }

  bool _refresh(Profile p) {
    final today = DateTime.now();
    final surahs = quran.durations(p.range);
    final before = p.cycle == null ? null : jsonEncode(p.cycle!.toJson());
    p.cycle = p.cycle == null
        ? Cycle.create(surahs, p.cycleDays, today,
            weakSurahs: p.weakSurahs, offDays: p.offDays)
        : p.cycle!.reconcile(today, surahs, weakSurahs: p.weakSurahs);
    return before != jsonEncode(p.cycle!.toJson());
  }

  Future<void> upsert(Profile p, {bool resetCycle = false}) async {
    if (resetCycle) p.cycle = null;
    final i = profiles.indexWhere((x) => x.id == p.id);
    if (i < 0) {
      profiles.add(p);
      _activeId = p.id;
      await _prefs.setString(_activeKey, p.id);
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
