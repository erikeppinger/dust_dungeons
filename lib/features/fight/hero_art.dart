import 'package:flutter/material.dart';

/// Free avatar choices (more come with the shop in 0.5.1).
const avatarSkins = [
  Color(0xFFFFE0BD),
  Color(0xFFFFCC80),
  Color(0xFFE0A370),
  Color(0xFFB07A4F),
  Color(0xFF7A4E2D),
];
const avatarHair = [
  Color(0xFF5D4037),
  Color(0xFF212121),
  Color(0xFFFBC02D),
  Color(0xFFD84315),
  Color(0xFF9E9E9E),
  Color(0xFF7B1FA2),
];
const avatarCapes = [
  Color(0xFF00897B),
  Color(0xFF1E88E5),
  Color(0xFFE53935),
  Color(0xFF8E24AA),
  Color(0xFFFB8C00),
  Color(0xFF43A047),
];

Color _pick(List<Color> colors, int index) =>
    colors[index.clamp(0, colors.length - 1)];

/// The player's hero, drawn from simple shapes.
class HeroArt extends StatelessWidget {
  const HeroArt({
    super.key,
    required this.skin,
    required this.hair,
    required this.cape,
    this.size = 88,
    this.semanticLabel,
  });

  final int skin, hair, cape;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    image: semanticLabel != null,
    child: CustomPaint(
      size: Size(size, size * 96 / 88),
      painter: _HeroPainter(
        _pick(avatarSkins, skin),
        _pick(avatarHair, hair),
        _pick(avatarCapes, cape),
      ),
    ),
  );
}

class _HeroPainter extends CustomPainter {
  _HeroPainter(this.skin, this.hair, this.cape);

  final Color skin, hair, cape;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 88);
    // The mop over the shoulder.
    canvas.save();
    canvas.translate(66, 40);
    canvas.rotate(0.31);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2.5, -32, 5, 70),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF8D6E63),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 26, 18, 12),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF90A4AE),
    );
    canvas.restore();
    // Cape, body, head, hair, face.
    final capePath = Path()
      ..moveTo(22, 50)
      ..quadraticBezierTo(44, 40, 66, 50)
      ..lineTo(72, 92)
      ..lineTo(16, 92)
      ..close();
    canvas.drawPath(capePath, Paint()..color = cape);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(28, 50, 32, 38),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFFFFB74D),
    );
    canvas.drawCircle(const Offset(44, 30), 20, Paint()..color = skin);
    final hairPath = Path()
      ..moveTo(24, 26)
      ..quadraticBezierTo(44, 4, 64, 26)
      ..quadraticBezierTo(54, 18, 44, 20)
      ..quadraticBezierTo(34, 18, 24, 26)
      ..close();
    canvas.drawPath(hairPath, Paint()..color = hair);
    final ink = Paint()..color = const Color(0xFF1A1C18);
    canvas.drawCircle(const Offset(37, 31), 2.6, ink);
    canvas.drawCircle(const Offset(51, 31), 2.6, ink);
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(44, 38), width: 12, height: 8),
      0.2,
      2.7,
      false,
      ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HeroPainter old) =>
      old.skin != skin || old.hair != hair || old.cape != cape;
}
