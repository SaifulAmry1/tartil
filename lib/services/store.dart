// Penyimpanan lokal semua profil (tanpa login, tanpa server).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/cycle.dart';
import '../core/report.dart';
import '../core/schedule.dart';
import '../data/quran_data.dart';
import '../models/profile.dart';
import '../models/recording_log.dart';
import '../teks.dart';
import 'notifications.dart';
import 'sync.dart';

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
    _syncSoon();
  }

  String rangeLabel(Profile p) {
    final r = p.range;
    return r.isJuz
        ? Teks.rentangJuz(r.juz)
        : Teks.rentangSurah(quran.surah(r.fromSurah!).name, quran.surah(r.toSurah!).name);
  }

  // --- Sinkron pantauan orang tua ---

  /// Waktu sinkron berhasil terakhir per profil (sesi ini).
  final Map<String, DateTime> lastSync = {};

  /// Profil yang sinkron terakhirnya gagal (mis. tanpa internet).
  final Set<String> syncFailed = {};
  Timer? _syncTimer;

  void _syncSoon() {
    if (!profiles.any((p) => p.syncId != null)) return;
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 2), syncAll);
  }

  Future<void> syncAll() async {
    for (final p in [...profiles]) {
      if (p.syncId != null && p.cycle != null) await syncProfile(p);
    }
  }

  Future<bool> syncProfile(Profile p) async {
    final ok = await Sync.push(p.syncId!, Laporan.of(p, rangeLabel(p), DateTime.now()));
    if (ok) {
      lastSync[p.id] = DateTime.now();
      syncFailed.remove(p.id);
    } else {
      syncFailed.add(p.id);
    }
    notifyListeners();
    return ok;
  }

  /// Aktifkan pantauan orang tua untuk profil ini (sekali saja).
  Future<void> enableSync(Profile p) async {
    if (p.syncId != null) return;
    p.syncId = Sync.newId();
    await _prefs.setString(
        _key, jsonEncode([for (final x in profiles) x.toJson()]));
    notifyListeners();
    await syncProfile(p);
  }

  /// Pastikan jadwal tiap profil sesuai tanggal hari ini (hari terlewat,
  /// siklus baru).
  void refreshAll() {
    _syncSoon();
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
    if (p.syncId != null) unawaited(Sync.remove(p.syncId!));
    profiles.remove(p);
    await _save();
    // Indeks notifikasi bergeser; jadwalkan ulang semuanya.
    await Notifications.rescheduleAll(profiles);
  }

  Future<void> setDayDone(Profile p, int dayIndex, bool done) async {
    p.cycle!.days[dayIndex].setDone(done, DateTime.now());
    await _save();
  }

  Future<void> setUnitDone(Profile p, int dayIndex, Unit unit, bool done) async {
    p.cycle!.days[dayIndex].setUnitDone(unit, done, DateTime.now());
    await _save();
  }

  Future<void> saveScore(Profile p, int surah, int score, {RecordingLog? log}) async {
    if (log != null) {
      p.recordings.insert(0, log);
      if (p.recordings.length > Profile.maxRecordings) {
        p.recordings.removeRange(Profile.maxRecordings, p.recordings.length);
      }
    }
    final wasWeak = p.weakSurahs.contains(surah);
    p.scores[surah] = score;
    if (!wasWeak && score < Profile.weakThreshold && p.cycle != null) {
      p.cycle!.addWeak(surah, quran.durations(p.range), DateTime.now());
    }
    await _save();
  }
}
