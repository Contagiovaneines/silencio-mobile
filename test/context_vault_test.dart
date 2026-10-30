import 'package:flutter_test/flutter_test.dart';
import 'package:silencio/game/world_model.dart';
import 'package:silencio/models/campaign.dart';

void main() {
  test(
    'contextual vault crosses only the low wall and keeps a safe save anchor',
    () {
      final c = Campaign()
        ..floor = 0
        ..x = 7.4
        ..y = 25.3
        ..backpackEquipped = false;
      c.mark('weapon');
      final w = WorldModel(c);
      expect(w.canVault, isTrue);
      expect(w.vault(), isTrue);
      expect(w.vault(), isFalse);
      for (var i = 0; i < 20; i++) {
        w.update(1 / 60);
      }
      expect(w.playerElevation, greaterThan(15));
      expect(w.playerDrawPosition.dy, greaterThan(25.3));
      expect(w.canStand(c.x, c.y), isTrue);
      expect(Campaign.decode(c.encode()).y, 25.3);
      for (var i = 0; i < 60; i++) {
        w.update(1 / 60);
      }
      expect(c.y, greaterThan(26));
      expect(w.playerElevation, 0);
      expect(w.canStand(c.x, c.y), isTrue);
      expect(c.has('weapon'), isTrue);
      expect(c.backpackEquipped, isFalse);
      expect(w.vault(), isTrue);
      for (var i = 0; i < 60; i++) {
        w.update(1 / 60);
      }
      expect(c.y, lessThan(25.65));
    },
  );
  test('jump is unavailable away from the contextual low wall', () {
    final w = WorldModel(Campaign());
    expect(w.canVault, isFalse);
    expect(w.vault(), isFalse);
  });
}
