// Sinkron laporan ke Firestore (paket gratis Firebase) lewat REST, tanpa
// plugin native. HP anak masuk secara anonim dan menulis dokumen
// pantau/<kunci acak>; orang tua yang memegang link bisa membacanya.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/report.dart';

class Sync {
  // Konfigurasi web Firebase proyek tartil. Bukan rahasia: akses diatur
  // oleh aturan keamanan Firestore.
  static const _apiKey = 'AIzaSyAilKAZ-7a50XLHmVV2cXS8LQ2_uuN7QLg';
  static const _project = 'tartil-a61d1';
  static const _docs =
      'https://firestore.googleapis.com/v1/projects/$_project/databases/(default)/documents/pantau';

  static const _uidKey = 'sinkron_uid';
  static const _refreshKey = 'sinkron_refresh';

  static String? _idToken;
  static DateTime _expires = DateTime(2000);

  /// Kunci dokumen baru: 128 bit acak, sulit ditebak.
  static String newId() {
    final r = Random.secure();
    return base64Url.encode(List.generate(16, (_) => r.nextInt(256))).replaceAll('=', '');
  }

  static Future<(String uid, String token)> _auth() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_uidKey);
    if (uid != null && _idToken != null && DateTime.now().isBefore(_expires)) {
      return (uid, _idToken!);
    }
    final refresh = prefs.getString(_refreshKey);
    if (uid != null && refresh != null) {
      final res = await http.post(
        Uri.parse('https://securetoken.googleapis.com/v1/token?key=$_apiKey'),
        body: {'grant_type': 'refresh_token', 'refresh_token': refresh},
      );
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        _setToken(j['id_token'] as String, j['expires_in'] as String);
        await prefs.setString(_refreshKey, j['refresh_token'] as String);
        return (uid, _idToken!);
      }
    }
    final res = await http.post(
      Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'returnSecureToken': true}),
    );
    if (res.statusCode != 200) throw Exception('Masuk sinkron gagal (${res.statusCode})');
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    _setToken(j['idToken'] as String, j['expiresIn'] as String);
    await prefs.setString(_uidKey, j['localId'] as String);
    await prefs.setString(_refreshKey, j['refreshToken'] as String);
    return (j['localId'] as String, _idToken!);
  }

  static void _setToken(String token, String expiresIn) {
    _idToken = token;
    _expires = DateTime.now().add(Duration(seconds: int.parse(expiresIn) - 120));
  }

  /// Kirim laporan terbaru. Mengembalikan false bila gagal (mis. tanpa
  /// internet); pemanggil mencoba lagi pada perubahan berikutnya.
  static Future<bool> push(String id, Laporan l) async {
    try {
      final (uid, token) = await _auth();
      final res = await http.patch(
        Uri.parse('$_docs/$id'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'fields': {
            'owner': {'stringValue': uid},
            'data': {'stringValue': jsonEncode(l.toJson())},
            'updated': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
          },
        }),
      );
      if (res.statusCode != 200) debugPrint('Sinkron ${res.statusCode}: ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Sinkron gagal: $e');
      return false;
    }
  }

  /// Hapus laporan saat profil dihapus.
  static Future<void> remove(String id) async {
    try {
      final (_, token) = await _auth();
      await http.delete(Uri.parse('$_docs/$id'), headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      debugPrint('Hapus laporan gagal: $e');
    }
  }

  /// Ambil laporan (untuk orang tua). Null bila tidak ada atau gagal.
  static Future<Laporan?> fetch(String id) async {
    try {
      final res = await http.get(Uri.parse('$_docs/$id'));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final data = (j['fields'] as Map)['data']['stringValue'] as String;
      return Laporan.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Ambil laporan gagal: $e');
      return null;
    }
  }
}
