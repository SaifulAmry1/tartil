import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/profile.dart';
import 'theme.dart';

const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Ahad'];

String tanggalPanjang(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';

String tanggalPendek(DateTime d) => '${d.day} ${_bulan[d.month - 1].substring(0, 3)}';

String namaHari(DateTime d) => _hari[d.weekday - 1];

/// Nama hari dari nomor DateTime.weekday (1 = Senin).
String namaHariKe(int weekday) => _hari[weekday - 1];

/// Contoh: "Rabu, 28 Okt 2026".
String tanggalHari(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1].substring(0, 3)} ${d.year}';

/// Contoh: "28 Okt 2026, 19.30".
String waktuPendek(DateTime d) =>
    '${tanggalPendek(d)} ${d.year}, ${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';

/// Avatar bulat berisi huruf awal nama profil, warnanya tetap per profil.
class ProfileAvatar extends StatelessWidget {
  final Profile profile;
  final double radius;
  final bool ring;

  const ProfileAvatar({super.key, required this.profile, this.radius = 20, this.ring = false});

  static const _colors = [
    Color(0xFF0F5C4A), Color(0xFF8E5B1F), Color(0xFF2B5C8A),
    Color(0xFF7A3E6B), Color(0xFF4F6B2B), Color(0xFF9C3D3D),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[profile.id.hashCode.abs() % _colors.length];
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        profile.name.isEmpty ? '?' : profile.name.characters.first.toUpperCase(),
        style: TextStyle(color: Colors.white, fontSize: radius * 0.9, fontWeight: FontWeight.w700),
      ),
    );
    if (!ring) return avatar;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: TartilColors.emas),
      child: avatar,
    );
  }
}

/// Cincin kemajuan dengan teks di tengah.
class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final Widget child;
  final Color color;
  final Color track;

  const ProgressRing({
    super.key,
    required this.value,
    required this.child,
    this.size = 96,
    this.color = TartilColors.emas,
    this.track = const Color(0x33FFFFFF),
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(value.clamp(0, 1), color, track),
          child: Center(child: child),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;
  _RingPainter(this.value, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, p..color = track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color;
}

/// Kotak statistik kecil di dasbor.
class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatTile({super.key, required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
        ]),
      );
}

/// Judul bagian dengan aksi opsional.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Row(children: [
          Container(width: 4, height: 18, decoration: BoxDecoration(color: TartilColors.emas, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700))),
          ?trailing,
        ]),
      );
}

/// Latar kepala halaman: gradasi hijau dengan ornamen bintang delapan.
class HeaderBackground extends StatelessWidget {
  final Widget child;
  const HeaderBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B4A3B), Color(0xFF13735C)],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Stack(children: [
          Positioned(right: -30, top: -20, child: Opacity(opacity: 0.12, child: Rub(size: 170, color: Colors.white))),
          Positioned(left: -20, bottom: -30, child: Opacity(opacity: 0.08, child: Rub(size: 110, color: Colors.white))),
          child,
        ]),
      );
}
