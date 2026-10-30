import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/models/campaign.dart';
import 'package:silencio/services/save_repository.dart';
import 'package:silencio/ui/game_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HUD is compact and mobile controls can be repositioned', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(832, 384);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final store = await SharedPreferences.getInstance();
    final session = await GameSession.load(SaveRepository(store));
    session.startNew();
    session.finishOpening();
    await tester.pumpWidget(MaterialApp(home: GameShell(session: session)));
    await tester.pump(const Duration(milliseconds: 100));

    final hud = tester.getSize(find.byKey(const Key('game-hud-card')));
    expect(hud.width, lessThanOrEqualTo(390));
    expect(hud.height, lessThanOrEqualTo(105));
    expect(
      tester.widget<Text>(find.byKey(const Key('hud-objective'))).maxLines,
      2,
    );
    expect(find.text('Caminhando'), findsNothing);
    expect(find.byKey(const Key('game-notice')), findsNothing);

    session.tell('Ação concluída.');
    await tester.pump();
    expect(tester.getSize(find.byKey(const Key('game-notice'))).width, lessThanOrEqualTo(440));
    expect(tester.takeException(), isNull);

    session.pause();
    await tester.pump();
    final pause = tester.getSize(find.byKey(const Key('pause-card')));
    expect(pause.width, lessThanOrEqualTo(440));
    expect(pause.height, lessThanOrEqualTo(352));
    expect(
      find.image(const AssetImage('assets/images/menu_santa_aurora_v2.png')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Editar controles'));
    await tester.tap(find.text('Editar controles'));
    await tester.pump();
    expect(session.phase, PlayPhase.playing);
    expect(find.text('Arraste para organizar'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('control-movement')),
      const Offset(32, -18),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(store.getDouble('silencio.control.movement.x'), greaterThan(.16));
    expect(store.getDouble('silencio.control.movement.y'), lessThan(.82));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
}
