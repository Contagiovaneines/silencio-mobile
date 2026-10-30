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
    s.campaign
      ..floor = p.floor
      ..x = p.x
      ..y = p.y;
  }

  test('opening handoff does not duplicate the objective in a toast', () {
    s.startNew();
    s.finishOpening();
    expect(s.phase, PlayPhase.playing);
    expect(s.campaign.objective, contains('celular'));
    expect(s.notice, isEmpty);
  });

  test('apartment television and light switch toggle independently', () {
    s.startNew();
    s.finishOpening();
    final television = s.world.allPlaces.singleWhere(
      (p) => p.kind == PointKind.homeTelevision,
    );
    s.campaign
      ..floor = television.floor
      ..x = television.x
      ..y = television.y;
    s.interact(television);
    expect(s.campaign.has('home_tv_on'), isTrue);
    expect(s.campaign.has('news'), isFalse);
    s.interact(television);
    expect(s.campaign.has('home_tv_on'), isFalse);

    final switchPoint = s.world.allPlaces.singleWhere(
      (p) => p.kind == PointKind.lightSwitch,
    );
    s.campaign
      ..x = switchPoint.x
      ..y = switchPoint.y;
    s.interact(switchPoint);
    expect(s.campaign.has('home_lights_off'), isTrue);
    s.interact(switchPoint);
    expect(s.campaign.has('home_lights_off'), isFalse);
  });

  test(
    'notebook interaction seats Caio at the desk instead of changing actor',
    () {
      s.startNew();
      s.finishOpening();
      final notebook = s.world.allPlaces.singleWhere(
        (p) => p.kind == PointKind.notebook,
      );
      s.campaign
        ..floor = 2
        ..x = notebook.x
        ..y = notebook.y;
      s.interact(notebook);
      expect(s.world.resting, 'typing');
      expect(s.world.restAnchor, const Offset(7.3, 3.85));
      s.closePanel();
      expect(s.world.resting, isNull);
    },
  );

  test(
    'bathroom door opens in place and does not trigger a building transition',
    () {
      s.startNew();
      s.finishOpening();
      final bathroomDoor = s.world.allPlaces.singleWhere(
        (p) => p.kind == PointKind.buildingDoor && p.id == 'banheiro',
      );
      s.campaign
        ..floor = 2
        ..x = bathroomDoor.x
        ..y = bathroomDoor.y + .8;
      s.interact(bathroomDoor);
      expect(s.world.doorIsOpen('banheiro'), isTrue);
      expect(s.phase, PlayPhase.playing);
      expect(s.campaign.floor, 2);
    },
  );

  test(
    'first phase follows V3 and completes when the player boards the bus',
    () async {
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
      at(PointKind.bus);
      for (var i = 0; i < 24; i++) {
        s.tick(.12);
      }
      expect(s.campaign.has('bus_arrived'), isTrue);
      s.interact();
      endDialogue();
      for (var i = 0; s.phase == PlayPhase.transit && i < 30; i++) {
        s.tick(.12);
      }
      expect(s.phase, PlayPhase.complete);
      expect(s.campaign.has('bus'), isTrue);
      expect(s.campaign.has('finish'), isTrue);
      await s.save();
      expect(r.load()!.finished, isTrue);
    },
  );

  test('bus cannot arrive or board before pulse and Helena message', () {
    s.startNew();
    s.finishOpening();
    s.campaign.events.addAll(['delivered', 'news', 'resolved']);
    at(PointKind.bus);
    for (var i = 0; i < 40; i++) {
      s.tick(.12);
    }
    expect(s.campaign.has('bus_arrived'), isFalse);
    s.interact();
    expect(s.phase, PlayPhase.playing);
    expect(s.campaign.has('bus'), isFalse);
    expect(s.campaign.finished, isFalse);
  });
  test('optional Bia reply is written, journaled and saved', () async {
    s.startNew();
    s.finishOpening();
    s.campaign.events.addAll([
      'adapter',
      'delivered',
      'news',
      'resolved',
      'pulse',
    ]);
    at(PointKind.busPassenger);
    s.interact();
    expect(s.phase, PlayPhase.dialogue);
    expect(s.currentLine?.speaker, 'BIA');
    expect(s.currentLine?.mode, 'mensagem escrita');
    endDialogue();
    expect(s.campaign.has('answered_bia'), isTrue);
    expect(
      s.campaign.entries.any((entry) => entry.id == 'answered_bia'),
      isTrue,
    );
    await s.save();
    final saved = Campaign.decode(r.preferences.getString(SaveRepository.key)!);
    expect(saved.has('answered_bia'), isTrue);
  });

  test('bed remains rest and save interaction after V3 bus ending', () {
    s.startNew();
    s.finishOpening();
    s.campaign.events.addAll([
      'delivered',
      'news',
      'resolved',
      'pulse',
      'night',
    ]);
    at(PointKind.bed);
    s.interact();
    expect(s.phase, PlayPhase.objectPanel);
    expect(s.campaign.finished, isFalse);
    expect(s.campaign.has('finish'), isFalse);
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
    'wooden weapon pickup is physical and persists in the existing save',
    () async {
      s.startNew();
      s.finishOpening();
      s.campaign
        ..floor = 0
        ..x = 31.7
        ..y = 26.5;
      final pickup = s.world.nearby;
      expect(pickup?.kind, PointKind.weapon);
      s.interact();
      expect(s.campaign.has('weapon'), isTrue);
      for (var frame = 0; frame < 45; frame++) {
        s.tick(1 / 60);
      }
      await s.save();
      expect(r.load()?.has('weapon'), isTrue);
      expect(s.world.nearby?.kind, isNot(PointKind.weapon));
    },
  );
  test(
    'partial melee damage resumes from a save without healing Davi',
    () async {
      s.startNew();
      s.finishOpening();
      s.campaign
        ..floor = 0
        ..x = 38
        ..y = 29;
      s.campaign.events.addAll(['alley', 'weapon']);
      s.world
        ..enemyX = 39
        ..enemyY = 29
        ..enemyStun = 20;
      expect(s.world.attack(), isTrue);
      for (var frame = 0; frame < 30; frame++) {
        s.tick(1 / 60);
      }
      expect(s.world.enemyHealth, 75);
      await s.save();
      final loaded = r.load()!;
      expect(loaded.enemyHealth, 75);
      s.world.restore(loaded);
      expect(s.world.enemyHealth, 75);
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
