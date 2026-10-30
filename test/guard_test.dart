import 'package:flutter_test/flutter_test.dart';
import 'package:silencio/game/world_model.dart';
import 'package:silencio/models/campaign.dart';

void main() {
  WorldModel ready(bool toward) {
    final c = Campaign()
      ..floor = 0
      ..x = 38
      ..y = 25;
    c.events.add('alley');
    final w = WorldModel(c)
      ..enemyX = 38
      ..enemyY = 25.9
      ..attackWindup = .01
      ..guarding = true
      ..facingX = 0
      ..facingY = toward ? 1 : -1;
    return w;
  }

  test('guard reduces frontal damage at stamina cost without erasing risk', () {
    final w = ready(true);
    w.update(.02);
    expect(w.campaign.health, 97);
    expect(w.campaign.stamina, lessThan(89));
    expect(w.action, 'block');
    expect(w.campaign.injured, isFalse);
  });
  test('guard cannot block an attack from behind', () {
    final w = ready(false);
    w.update(.02);
    expect(w.campaign.health, 88);
    expect(w.action, 'hurt');
  });
}
