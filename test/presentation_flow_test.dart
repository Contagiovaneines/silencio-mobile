import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/models/campaign.dart';
import 'package:silencio/services/save_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameSession s;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    s = await GameSession.load(
      SaveRepository(await SharedPreferences.getInstance()),
    );
  });
  tearDown(() => s.dispose());

  test('menu settings and journey return to their origin without advancing the world', () {
    final before = s.campaign.encode();
    s.menuSettings();
    s.tick(20);
    s.closePanel();
    expect(s.phase, PlayPhase.menu);
    expect(s.campaign.encode(), before);
    s.journey();
    s.tick(20);
    s.closePanel();
    expect(s.phase, PlayPhase.menu);
    expect(s.campaign.encode(), before);
    s.startNew();
    s.finishOpening();
    s.map();
    final playing = s.campaign.encode();
    s.journey();
    expect(s.journeyFromMap, isTrue);
    s.tick(20);
    s.closePanel();
    expect(s.phase, PlayPhase.map);
    expect(s.campaign.encode(), playing);
  });

  test(
    'new game shows the city prelude before story and previous returns to it',
    () {
      s.startNew();
      expect(s.openingPrelude, isTrue);
      expect(s.openingPage, 0);

      s.nextOpening();
      expect(s.openingPrelude, isFalse);
      expect(s.openingPage, 0);

      s.previousOpening();
      expect(s.openingPrelude, isTrue);
      expect(s.openingPage, 0);

      s.nextOpening();
      expect(s.openingPrelude, isFalse);
      expect(s.openingPage, 0);
    },
  );
  test('opening defaults to manual; previous, automatic and skip preserve the mission', () async {
    s.startNew();
    final before = s.campaign.encode();
    s.tick(30);
    expect(s.openingPage, 0);
    s.nextOpening();
    s.previousOpening();
    expect(s.openingPage, 0);
    s.toggleOpeningAuto();
    s.tick(8.1);
    expect(s.openingPrelude, isFalse);
    expect(s.openingPage, 0);
    s.tick(13.1);
    expect(s.openingPage, 1);
    expect(s.campaign.encode(), before);
    final loaded = await GameSession.load(
      SaveRepository(await SharedPreferences.getInstance()),
    );
    expect(loaded.openingAuto, isTrue);
    loaded.dispose();
    s.finishOpening();
    expect(s.phase, PlayPhase.playing);
    expect(s.campaign.encode(), before);
  });

  test(
    'replaying the prologue returns to menu and retains saved inventory',
    () async {
      s.campaign.events.addAll(['phone', 'key', 'adapter']);
      await s.checkpoint();
      final saved = s.repository.load()!.encode();
      s.replay();
      s.nextOpening();
      s.finishOpening();
      expect(s.phase, PlayPhase.menu);
      expect(s.repository.load()!.encode(), saved);
    },
  );
}
