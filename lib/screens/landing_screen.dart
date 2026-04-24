import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  final WidgetBuilder nextScreenBuilder;

  const LandingScreen({super.key, required this.nextScreenBuilder});

  void _handleStartTap(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) =>
            nextScreenBuilder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleSize = (screenWidth * 0.11).clamp(44.0, 72.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleStartTap(context),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _StoreStyleIcon(size: 260),
                    const SizedBox(height: 34),
                    Text(
                      'Quick Split Bill',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: titleSize,
                        height: 0.98,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tap anywhere to begin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFB8B8B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreStyleIcon extends StatelessWidget {
  final double size;

  const _StoreStyleIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDFDF9), Color(0xFFF4F3EA)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: CustomPaint(painter: _GooglePlayIconPainter()),
    );
  }
}

class _GooglePlayIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;
    final strokeWidth = size.width * 0.15;

    // Base green color
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8A9A5B);

    // Highlight and shadow paints
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          strokeWidth *
          0.8 // Thinner highlight
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFB3C083);

    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          strokeWidth *
          0.5 // Thinner shadow
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF6B7846);

    // Function to draw a ring with gradient
    void drawRing(Path path, Offset centerOffset) {
      // Main color
      canvas.drawPath(path, basePaint);

      // Shadow
      canvas.save();
      canvas.translate(0, strokeWidth * 0.15);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();

      // Highlight
      canvas.save();
      canvas.translate(0, -strokeWidth * 0.15);
      canvas.drawPath(path, highlightPaint);
      canvas.restore();
    }

    // Right ring (bottom layer)
    final rightRingPath = Path()
      ..addArc(
        Rect.fromCircle(
          center: Offset(center.dx + radius * 0.6, center.dy),
          radius: radius,
        ),
        -2.4,
        5.5,
      );
    drawRing(rightRingPath, Offset(center.dx + radius * 0.6, center.dy));

    // Left ring (top layer)
    final leftRingPath = Path()
      ..addArc(
        Rect.fromCircle(
          center: Offset(center.dx - radius * 0.6, center.dy),
          radius: radius,
        ),
        0.7,
        5.5,
      );
    drawRing(leftRingPath, Offset(center.dx - radius * 0.6, center.dy));

    // Checkmark
    final checkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..color = const Color(0xFFD4A373)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(size.width * 0.42, size.height * 0.5)
      ..lineTo(size.width * 0.52, size.height * 0.6)
      ..lineTo(size.width * 0.65, size.height * 0.4);

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
