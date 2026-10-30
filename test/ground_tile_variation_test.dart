import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:silencio/game/ground_tile_variation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'concrete tile selection is coordinate stable and distributes variants',
    () {
      final samples = {
        for (var y = 0; y < 40; y++)
          for (var x = 0; x < 50; x++) ConcreteTileVariation.at(x, y),
      };

      expect(ConcreteTileVariation.at(8, 12), ConcreteTileVariation.at(8, 12));
      expect(samples, containsAll([0, 1, 2, 3]));
      for (final variant in samples) {
        expect(variant, inInclusiveRange(0, ConcreteTileVariation.count - 1));
      }

      var horizontalChanges = 0;
      var horizontalPairs = 0;
      for (var y = 0; y < 16; y++) {
        for (var x = 0; x < 15; x++) {
          horizontalPairs++;
          if (ConcreteTileVariation.at(x, y) !=
              ConcreteTileVariation.at(x + 1, y)) {
            horizontalChanges++;
          }
        }
      }
      expect(horizontalChanges / horizontalPairs, greaterThan(0.6));
    },
  );

  test(
    'all generated concrete variants are included in the Flutter bundle',
    () async {
      final manifest = jsonDecode(
        await rootBundle.loadString('assets/data/phase_assets.json'),
      ) as Map<String, dynamic>;

      for (var index = 0; index < ConcreteTileVariation.count; index++) {
        final asset = manifest['tile_concrete_$index'] as String;
        expect(await rootBundle.load('assets/images/$asset'), isNotNull);
      }
    },
  );
}
