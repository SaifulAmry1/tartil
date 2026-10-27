import 'dart:math' as math;

import 'package:flutter/material.dart';

class TartilColors {
  static const hijau = Color(0xFF0F5C4A);
  static const hijauMuda = Color(0xFFE3F1EC);
  static const emas = Color(0xFFC9A227);
  static const krem = Color(0xFFFBF7EE);
  static const merah = Color(0xFFC62828);
  static const oranye = Color(0xFFE67E22);

  /// Warna latar 8 blok per halaman (meniru gaya mushaf hafalan 8 blok).
  static const blok = [
    Color(0xFFFFE0E0),
    Color(0xFFFFF0CC),
    Color(0xFFE6F5D0),
    Color(0xFFD6F0F5),
    Color(0xFFE0E4FF),
    Color(0xFFF1DFF7),
    Color(0xFFFFE6D1),
    Color(0xFFDDF3E6),
  ];
}

ThemeData tartilTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: TartilColors.hijau,
    primary: TartilColors.hijau,
    secondary: TartilColors.emas,
    surface: TartilColors.krem,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: TartilColors.krem,
    appBarTheme: const AppBarTheme(
      backgroundColor: TartilColors.hijau,
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: TartilColors.emas.withValues(alpha: 0.35)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TartilColors.hijau,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

/// Bintang delapan (rub el hizb) sebagai ornamen islami.
class Rub extends StatelessWidget {
  final double size;
  final Color color;
  final Widget? child;

  const Rub({super.key, this.size = 40, this.color = TartilColors.emas, this.child});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RubPainter(color),
          child: Center(child: child),
        ),
      );
}

class _RubPainter extends CustomPainter {
  final Color color;
  _RubPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * 0.86;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.06;
    for (final rot in [0.0, math.pi / 4]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = rot + i * math.pi / 2 + math.pi / 4;
        final p = c + Offset(math.cos(a), math.sin(a)) * r;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(c, r * 0.42, paint..strokeWidth = size.shortestSide * 0.03);
  }

  @override
  bool shouldRepaint(_RubPainter old) => old.color != color;
}

/// Angka Arab-Indonesia (٠١٢...) untuk nomor ayat.
String arabicDigits(int n) => n
    .toString()
    .split('')
    .map((d) => String.fromCharCode(0x0660 + int.parse(d)))
    .join();
