import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/services/save_repository.dart';
import 'package:silencio/ui/game_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('enemy health and attack control appear only for the encounter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final session = await GameSession.load(
      SaveRepository(await SharedPreferences.getInstance()),
    );
    await tester.pumpWidget(MaterialApp(home: GameShell(session: session)));
    session
      ..startNew()
      ..finishOpening();
    session.campaign
      ..x = 38
      ..y = 29
      ..floor = 0;
    await tester.pump();

    expect(find.byKey(const ValueKey('enemy-health')), findsNothing);
    expect(find.text('Atacar'), findsNothing);

    session.campaign.events.addAll(['alley', 'weapon']);
    session.notifyListeners();
    await tester.pump();

    expect(find.byKey(const ValueKey('enemy-health')), findsOneWidget);
    expect(find.text('DAVI · 100%'), findsOneWidget);
    expect(find.text('Atacar'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
}
