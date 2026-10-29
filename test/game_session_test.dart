import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/game/world_model.dart';
import 'package:silencio/models/campaign.dart';
import 'package:silencio/services/save_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameSession s;
  late SaveRepository r;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    r = SaveRepository(await SharedPreferences.getInstance());
    s = await GameSession.load(r);
  });
  tearDown(() => s.dispose());
  void endDialogue() {
    while (s.phase == PlayPhase.dialogue) {
      s.nextLine();
    }
  }

  void at(PointKind kind) {
    final p = s.world.allPlaces.firstWhere((v) => v.kind == kind);
    if (kind == PointKind.bed) {
      s.campaign
        ..floor = 2
        ..x = 4.3
        ..y = 5.65;
      return;
    }
    if (kind == PointKind.key) {
      s.campaign
        ..floor = 2
        ..x = 9
        ..y = 4.85;
      return;
    }
    if (kind == PointKind.adapter) {
      s.campaign
        ..floor = 2
        ..x = 8.8
        ..y = 5.5;
      return;
    }
    s.campaign
      ..floor = p.floor
      ..x = p.x
      ..y = p.y + 1;
  }

  test('first phase requires delivery, nonlethal encounter, pulse, message and returning home', () async {
    s.startNew();
    expect(s.phase, PlayPhase.opening);
    s.finishOpening();
    s.phone();
    endDialogue();
    at(PointKind.key);
    s.interact();
    for (var i = 0; i < 50; i++) {
      s.tick(.02);
    }
    at(PointKind.adapter);
    s.interact();
    for (var i = 0; i < 50; i++) {
      s.tick(.02);
    }
    at(PointKind.merchant);
    s.interact();
    endDialogue();
    expect(s.campaign.has('delivered'), isTrue);
    at(PointKind.television);
    s.interact();
    for (var i = 0; i < 3; i++) {
      s.advanceNews();
    }
    expect(s.campaign.has('news'), isTrue);
    s.campaign.mark('alley');
    at(PointKind.gate);
    s.interact();
    expect(s.campaign.has('resolved'), isTrue);
    at(PointKind.crossing);
    s.interact();
    expect(s.phase, PlayPhase.pulse);
    s.tick(2.1);
    endDialogue();
    expect(s.campaign.has('pulse'), isTrue);
    expect(s.campaign.finished, isFalse);
    s.phone();
    endDialogue();
    expect(s.campaign.has('night'), isTrue);
    at(PointKind.bed);
    s.interact();
    expect(s.phase, PlayPhase.complete);
    await s.save();
    expect(r.load()!.finished, isTrue);
  });
  test(
    'authorized loot and optional help are idempotent across reloads',
    () async {
      s.startNew();
      s.finishOpening();
      at(PointKind.sedan);
      s.interact();
      expect(s.campaign.bandages, 0);
      s.campaign.events.addAll(['adapter', 'delivered']);
      at(PointKind.sedan);
      s.interact();
      for (var i = 0; i < 50; i++) {
        s.tick(.02);
      }
      s.interact();
      expect(s.campaign.bandages, 1);
      await s.save();
      final loaded = r.load()!;
      expect(loaded.has('loot'), isTrue);
      s.world.restore(loaded);
      at(PointKind.neighbor);
      s.interact();
      endDialogue();
      expect(s.campaign.has('help_ines'), isTrue);
      expect(s.campaign.bandages, 1);
    },
  );
  test(
    'map and reading pause enemy attacks; retry restores safe checkpoint',
    () async {
      s.startNew();
      s.finishOpening();
      await s.checkpoint();
      s.campaign.mark('alley');
      s.campaign
        ..floor = 0
        ..x = 38
        ..y = 26.5;
      s.world.enemyX = 38.7;
      s.world.enemyY = 26.5;
      s.map();
      for (var i = 0; i < 200; i++) {
        s.tick(.02);
      }
      expect(s.campaign.health, 100);
      s.closePanel();
      s.campaign.health = 0;
      s.tick(.02);
      expect(s.phase, PlayPhase.defeated);
      await s.save();
      await s.retry();
      expect(s.campaign.health, 100);
      expect(s.campaign.has('alley'), isFalse);
    },
  );
  test('old beta slot and malformed progress are preserved', () async {
    await r.preferences.setString('silencio.campaign.v1', 'old-beta');
    await r.preferences.setString(SaveRepository.key, 'broken');
    expect(r.load(), isNull);
    expect(r.warning, isNotNull);
    expect(r.preferences.getString(SaveRepository.key), 'broken');
    expect(r.preferences.getString('silencio.campaign.v1'), 'old-beta');
  });
}
