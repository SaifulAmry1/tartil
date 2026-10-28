// Pengingat harian per profil, dijadwalkan di perangkat (tanpa server).
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/profile.dart';
import '../teks.dart';

class Notifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    // Versi web hanya pratinjau: pengingat ada di APK Android.
    if (kIsWeb) throw UnsupportedError('Notifikasi hanya di Android');
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (e) {
      debugPrint('Zona waktu: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  static Future<void> requestPermission() async {
    if (kIsWeb) return;
    await init();
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static int _id(int index) => 1000 + index;

  static Future<void> schedule(Profile p, int index) async {
    try {
      await init();
      final now = tz.TZDateTime.now(tz.local);
      var at = tz.TZDateTime(tz.local, now.year, now.month, now.day,
          p.reminderHour, p.reminderMinute);
      if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: _id(index),
        title: Teks.notifJudul(p.name),
        body: Teks.notifIsi,
        scheduledDate: at,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'pengingat_murojaah',
            Teks.kanalNama,
            channelDescription: Teks.kanalKet,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Gagal menjadwalkan pengingat: $e');
    }
  }

  static Future<void> cancel(int index) async {
    try {
      await init();
      await _plugin.cancel(id: _id(index));
    } catch (e) {
      debugPrint('Gagal membatalkan pengingat: $e');
    }
  }

  static Future<void> rescheduleAll(List<Profile> profiles) async {
    try {
      await init();
      await _plugin.cancelAll();
      for (var i = 0; i < profiles.length; i++) {
        await schedule(profiles[i], i);
      }
    } catch (e) {
      debugPrint('Gagal menjadwalkan ulang: $e');
    }
  }
}
