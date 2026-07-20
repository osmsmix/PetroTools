import 'package:flutter/material.dart';

/// The PetroTools horizontal lockup: drop mark + wordmark.
///
/// Drawn natively (instead of an SVG asset) so it stays crisp at any size and
/// the wordmark uses the app font.
class LogoLockup extends StatelessWidget {
  final double height;

  const LogoLockup({super.key, this.height = 40});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomPaint(
          size: Size(height * _DropMarkPainter.aspectRatio, height),
          painter: const _DropMarkPainter(),
        ),
        SizedBox(width: height * 0.25),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Petro', style: TextStyle(color: Color(0xFFE8EEF4))),
              TextSpan(text: 'Tools', style: TextStyle(color: Color(0xFF4FC3F7))),
            ],
          ),
          style: TextStyle(
            fontSize: height * 0.58,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// Paints the droplet with the nodal curve and operating-point dot.
///
/// Design space is a 204x306 drop plus an 8-unit margin on each side for the
/// stroke, giving a 220x322 canvas.
class _DropMarkPainter extends CustomPainter {
  static const aspectRatio = 220 / 322;

  const _DropMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 322;
    canvas.scale(s);
    canvas.translate(8, 8);

    final drop = Path()
      ..moveTo(102, 0)
      ..cubicTo(102, 0, 0, 128, 0, 204)
      ..arcToPoint(const Offset(204, 204), radius: const Radius.circular(102), clockwise: false)
      ..cubicTo(204, 128, 102, 0, 102, 0)
      ..close();

    canvas.drawPath(drop, Paint()..color = const Color(0xFF0E2230));
    canvas.drawPath(
      drop,
      Paint()
        ..color = const Color(0xFF4FC3F7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeJoin = StrokeJoin.round,
    );

    final curve = Path()
      ..moveTo(38, 172)
      ..quadraticBezierTo(128, 185, 166, 268);
    canvas.drawPath(
      curve,
      Paint()
        ..color = const Color(0xFFFFB74D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(const Offset(166, 268), 14, Paint()..color = const Color(0xFF69F0AE));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
