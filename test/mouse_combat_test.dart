import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/services/save_repository.dart';
import 'package:silencio/ui/game_shell.dart';

void main() {
  testWidgets('right hold aims, but a shot without an encounter does nothing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final s = await GameSession.load(
      SaveRepository(await SharedPreferences.getInstance()),
    );
    s.startNew();
    s.finishOpening();
    s.campaign
      ..floor = 0
      ..x = 38
      ..y = 25;
    s.campaign.events.addAll(['alley', 'weapon']);
    await tester.pumpWidget(MaterialApp(home: GameShell(session: s)));
    await tester.pump(const Duration(milliseconds: 100));
    const point = Offset(650, 350);
    await tester.sendEventToBinding(
      const PointerDownEvent(
        pointer: 7,
        kind: PointerDeviceKind.mouse,
        position: point,
        buttons: kSecondaryMouseButton,
      ),
    );
    expect(s.world.aiming, isTrue);
    // Additional mouse buttons arrive as move events while a button is held.
    await tester.sendEventToBinding(
      const PointerMoveEvent(
        pointer: 7,
        kind: PointerDeviceKind.mouse,
        position: point,
        buttons: kSecondaryMouseButton | kPrimaryMouseButton,
      ),
    );
    expect(s.world.action, 'idle');
    await tester.sendEventToBinding(
      const PointerUpEvent(
        pointer: 7,
        kind: PointerDeviceKind.mouse,
        position: point,
      ),
    );
    expect(s.world.aiming, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });
}
