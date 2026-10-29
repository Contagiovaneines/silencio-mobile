import 'package:flutter_test/flutter_test.dart';
import 'package:silencio/game/world_atmosphere.dart';
import 'package:silencio/game/world_model.dart';
import 'package:silencio/models/campaign.dart';

void main() {
  test('night fades gradually and sewer habitat rejects daylight', () {
    final a = WorldAtmosphere();
    a.update(.1, storyNight: true);
    expect(a.nightBlend, inExclusiveRange(0, 1));
    for (var i = 0; i < 600; i++) {
      a.update(1 / 60, storyNight: true);
    }
    expect(a.isNight, true);
    expect(habitatAllowsActivity(InfectedHabitat.sewer, light: 1), false);
    expect(habitatAllowsActivity(InfectedHabitat.sewer, light: 0), true);
  });
  test('ladder elevates along declared support and returns to ground', () {
    final c = Campaign()
      ..floor = 0
      ..x = 10.7
      ..y = 22.5;
    final w = WorldModel(c);
    expect(w.climbLadder(), true);
    for (var i = 0; i < 210; i++) {
      w.update(1 / 60);
    }
    expect(w.onRoof, true);
    expect(w.playerElevation, 56);
    final x = c.x;
    w.moveTo(12, 25);
    w.setInput(1, 0);
    w.update(.1);
    expect(c.x, x);
    expect(w.climbLadder(), true);
    for (var i = 0; i < 210; i++) {
      w.update(1 / 60);
    }
    expect(w.onRoof, false);
    expect(w.playerElevation, 0);
    expect(w.canStand(c.x, c.y), true);
  });
  test('exhaustion latch lasts until full stamina and critical injury limits speed', () {
    final c = Campaign()..stamina = 0;
    final w = WorldModel(c);
    w.update(.1);
    expect(w.recoveringBreath, true);
    for (var i = 0; i < 600; i++) {
      w.update(1 / 60);
    }
    expect(c.stamina, 100);
    expect(w.recoveringBreath, false);
    c.health = 20;
    w.running = true;
    expect(w.severelyHurt, true);
    expect(w.effectiveRunning, false);
  });
}
