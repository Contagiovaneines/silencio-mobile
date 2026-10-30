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
    this.atlasIndex,
    this.atlasColumns = 1,
    this.atlasRows = 1,
    this.atlasAspect = 1.7758,
  });
  final String asset;
  final double progress;
  final bool reducedMotion;
  final BoxFit fit;
  final int? atlasIndex;
  final int atlasColumns, atlasRows;
  final double atlasAspect;
  @override
  Widget build(BuildContext context) {
    final t = reducedMotion ? 0.0 : progress.clamp(0.0, 1.0);
    return ClipRect(
      child: Transform.scale(
        scale: reducedMotion ? 1 : 1.04,
        child: Transform.translate(
          offset: Offset(math.sin(t * math.pi / 2) * 12, -t * 5),
          child: atlasIndex == null
              ? Image.asset(
                  asset,
                  fit: fit,
                  width: double.infinity,
                  height: double.infinity,
                  cacheWidth: 1600,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: Color(0xff102029)),
                )
              : LayoutBuilder(
                  builder: (context, bounds) {
                    assert(
                      atlasIndex! >= 0 &&
                          atlasIndex! < atlasColumns * atlasRows,
                    );
                    final cellAspect = atlasAspect * atlasRows / atlasColumns;
                    final scale = math.max(
                      bounds.maxWidth / cellAspect,
                      bounds.maxHeight,
                    );
                    final cellWidth = cellAspect * scale;
                    final cellHeight = scale;
                    final column = atlasIndex! % atlasColumns;
                    final row = atlasIndex! ~/ atlasColumns;
                    final width = cellWidth * atlasColumns;
                    final height = cellHeight * atlasRows;
                    final x =
                        -column * cellWidth - (cellWidth - bounds.maxWidth) / 2;
                    final y =
                        -row * cellHeight - (cellHeight - bounds.maxHeight) / 2;
                    return ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: width,
                        maxWidth: width,
                        minHeight: height,
                        maxHeight: height,
                        child: Transform.translate(
                          offset: Offset(x, y),
                          child: Image.asset(
                            asset,
                            fit: BoxFit.fill,
                            width: width,
                            height: height,
                            cacheWidth: 1600,
                            excludeFromSemantics: true,
                            errorBuilder: (_, _, _) =>
                                const ColoredBox(color: Color(0xff102029)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
