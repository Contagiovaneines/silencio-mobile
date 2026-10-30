import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/game/world_model.dart';
import 'package:silencio/models/campaign.dart';
import 'package:silencio/services/save_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('aim preserves facing when backing away and prevents sprinting', () {
    final c = Campaign()
      ..x = 6
      ..y = 6;
    final w = WorldModel(c);
    w.aimAt(9, 6);
    w.sprintHeld = true;
    w.setInput(-1, 0);
    w.update(.1);
    expect(c.x, lessThan(6));
    expect(w.facingX, greaterThan(.99));
    expect(w.effectiveRunning, isFalse);
    expect((c.x - 6).abs(), lessThan(.2));
    w.endAim();
    expect(w.effectiveRunning, isTrue);
  });

  test(
    'click action approaches physically and manual movement cancels it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final s = await GameSession.load(
        SaveRepository(await SharedPreferences.getInstance()),
      );
      addTearDown(s.dispose);
      s.startNew();
      s.finishOpening();
      final key = s.world.places.firstWhere((p) => p.kind == PointKind.key);
      s.interact(key);
      expect(s.campaign.has('key'), isFalse);
      s.approachAndInteract(key);
      expect(s.campaign.has('key'), isFalse);
      for (var i = 0; i < 600 && !s.campaign.has('key'); i++) {
        s.tick(1 / 60);
      }
      expect(s.campaign.has('key'), isTrue);
      final adapter = s.world.places.firstWhere(
        (p) => p.kind == PointKind.adapter,
      );
      for (var i = 0; i < 60; i++) {
        s.tick(1 / 60);
      }
      s.campaign
        ..x = 5
        ..y = 7;
      s.approachAndInteract(adapter);
      expect(s.approachTarget, isNotNull);
      s.world.setInput(-1, 0);
      s.tick(1 / 60);
      expect(s.approachTarget, isNull);
      expect(s.campaign.has('adapter'), isFalse);
      s.world.aimAt(8, 6);
      s.world.sprintHeld = true;
      s.pause();
      expect(s.world.aiming, isFalse);
      expect(s.world.sprintHeld, isFalse);
    },
  );
  test(
    'manual aim can miss without turning or damaging a target behind Caio',
    () {
      final c = Campaign()
        ..floor = 0
        ..x = 38
        ..y = 25;
      c.events.addAll(['alley', 'weapon']);
      final w = WorldModel(c);
      w.aimAt(38, 20);
      expect(w.attack(), isTrue);
      w.update(.12);
      w.update(.12);
      w.update(.12);
      w.update(.12);
      expect(c.enemyHealth, 100);
      expect(w.sounds, contains('swing'));
      expect(w.facingY, lessThan(0));
    },
  );

  test('close-range attack assist faces Davi and refuses empty swings', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await GameSession.load(
      SaveRepository(await SharedPreferences.getInstance()),
    );
    addTearDown(s.dispose);
    s.startNew();
    s.finishOpening();
    s.campaign
      ..floor = 0
      ..x = 38
      ..y = 29
      ..weaponEquipped = true
      ..events.addAll(['alley', 'weapon']);
    s.world
      ..enemyX = 39
      ..enemyY = 29
      ..facingX = -1
      ..facingY = 0;

    s.attack();

    expect(s.world.action, 'attack');
    expect(s.world.facingX, greaterThan(.99));

    s.world
      ..action = 'idle'
      ..playerAttackCooldown = 0
      ..enemyX = 42;
    final stamina = s.campaign.stamina;
    s.attack();
    expect(s.world.action, 'idle');
    expect(s.campaign.stamina, stamina);
  });
}
