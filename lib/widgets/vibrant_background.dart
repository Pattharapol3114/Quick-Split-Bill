import 'package:flutter/material.dart';

class VibrantBackground extends StatelessWidget {
  final Widget child;

  const VibrantBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF38237A), Color(0xFF1650D2), Color(0xFFDE6FB0)],
        ),
      ),
      child: child,
    );
  }
}
