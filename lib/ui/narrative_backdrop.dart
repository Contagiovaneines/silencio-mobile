import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Illustrations are confined to presentation; world geometry remains playable.
class NarrativeBackdrop extends StatelessWidget {
  const NarrativeBackdrop({
    super.key,
    required this.asset,
    this.progress = 0,
    this.reducedMotion = false,
    this.fit = BoxFit.cover,
  });
  final String asset;
  final double progress;
  final bool reducedMotion;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final t = reducedMotion ? 0.0 : progress.clamp(0.0, 1.0);
    return ClipRect(
      child: Transform.scale(
        scale: reducedMotion ? 1 : 1.04,
        child: Transform.translate(
          offset: Offset(math.sin(t * math.pi / 2) * 12, -t * 5),
          child: Image.asset(
            asset,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: 1600,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: Color(0xff102029)),
          ),
        ),
      ),
    );
  }
}
