import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:silencio/services/audio_mix.dart';

void main() {
  test(
    'all simulation cues have an audio asset, including window and swing',
    () {
      for (final name in [
        'rain',
        'step',
        'phone',
        'pickup',
        'heal',
        'alert',
        'bird',
        'dog',
        'cat',
        'engine',
        'hit',
        'push',
        'door',
        'pulse',
        'window',
        'swing',
      ]) {
        expect(
          File('assets/audio/$name.wav').existsSync(),
          isTrue,
          reason: name,
        );
      }
    },
  );

  test(
    'animal cues cannot pile up while distinct footsteps remain audible',
    () {
      final mix = AudioMix();
      expect(mix.allow('cat', 1), isTrue);
      expect(mix.allow('cat', 1.1), isFalse);
      expect(mix.allow('dog', 1.1), isTrue);
      expect(mix.allow('cat', 4), isTrue);
      expect(mix.allow('step', 4), isTrue);
      expect(mix.allow('step', 4.01), isFalse);
      expect(mix.allow('step', 4.3), isTrue);
    },
  );

  test('mix keeps footsteps below impacts and rain subdued indoors', () {
    expect(AudioMix.volume('step'), lessThan(AudioMix.volume('hit')));
    expect(
      AudioMix.ambientVolume(indoors: true),
      lessThan(AudioMix.ambientVolume(indoors: false)),
    );
  });
}
