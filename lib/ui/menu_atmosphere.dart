import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Low-cost, deterministic weather overlay used only by the main menu.
class MenuAtmospherePainter extends CustomPainter {
  const MenuAtmospherePainter({
    required this.progress,
    required this.reducedMotion,
  });

  final double progress;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    if (reducedMotion || size.isEmpty) return;
    final t = progress * math.pi * 2;
    final shortSide = math.min(size.width, size.height);

    // The tower beacon gently pulses without obscuring the artwork.
    final beaconX = size.width / size.height > 1
        ? size.width * .76
        : size.width * .48;
    final beaconY = size.height * .115;
    final pulse = .3 + .22 * (math.sin(t) + 1) / 2;
    canvas.drawCircle(
      Offset(beaconX, beaconY),
      shortSide * (.018 + .009 * (math.sin(t) + 1) / 2),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(beaconX, beaconY),
          shortSide * .075,
          [Color.fromRGBO(255, 48, 47, pulse), const Color(0x00ff302f)],
        ),
    );

    // Broad, translucent mist bands add depth while remaining inexpensive.
    for (var i = 0; i < 3; i++) {
      final y = size.height * (.48 + i * .14) + math.sin(t + i * 1.7) * 5;
      final rect = Rect.fromCenter(
        center: Offset(size.width * (.55 + i * .12), y),
        width: size.width * (.72 - i * .08),
        height: size.height * .08,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(rect.center, rect.width * .5, const [
            Color(0x188dabc0),
            Color(0x008dabc0),
          ]),
      );
    }

    // Fixed seed/positions make rain stable between frames; only its phase moves.
    final rainPaint = Paint()
      ..color = const Color(0x3bd9e5eb)
      ..strokeWidth = math.max(0.65, shortSide / 1100)
      ..strokeCap = StrokeCap.round;
    const count = 52;
    final phase = progress * size.height * .55;
    for (var i = 0; i < count; i++) {
      final x = ((i * 97.13) % 997) / 997 * size.width;
      final baseY = ((i * 173.7) % 991) / 991 * size.height;
      final y = (baseY + phase) % (size.height + 24) - 12;
      final length = 7 + (i % 5) * 2.5;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - length * .28, y + length),
        rainPaint,
      );
    }
  }

  @override
  bool shouldRepaint(MenuAtmospherePainter oldDelegate) =>
      progress != oldDelegate.progress ||
      reducedMotion != oldDelegate.reducedMotion;
}
