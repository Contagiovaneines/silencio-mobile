import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silencio/ui/menu_atmosphere.dart';

void main() {
  test(
    'menu atmosphere paints across aspect ratios and honors reduced motion',
    () {
      const sizes = [Size(360, 800), Size(768, 1024), Size(1366, 768)];
      for (final size in sizes) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        const animated = MenuAtmospherePainter(
          progress: .4,
          reducedMotion: false,
        );
        const still = MenuAtmospherePainter(progress: .4, reducedMotion: true);

        animated.paint(canvas, size);
        still.paint(canvas, size);
        recorder.endRecording().dispose();
      }
    },
  );

  test('atmosphere repaints only when its animation state changes', () {
    const current = MenuAtmospherePainter(progress: .2, reducedMotion: false);
    const same = MenuAtmospherePainter(progress: .2, reducedMotion: false);
    const advanced = MenuAtmospherePainter(progress: .3, reducedMotion: false);
    const reduced = MenuAtmospherePainter(progress: .2, reducedMotion: true);

    expect(current.shouldRepaint(same), isFalse);
    expect(current.shouldRepaint(advanced), isTrue);
    expect(current.shouldRepaint(reduced), isTrue);
  });
}
