import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/models/campaign.dart';
import 'package:silencio/services/save_repository.dart';
import 'package:silencio/ui/game_shell.dart';

void main() {
  testWidgets('chapter completion and chapter two entry fit portrait screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final s = await GameSession.load(
      SaveRepository(await SharedPreferences.getInstance()),
    );
    s.startNew();
    s.finishOpening();
    s.campaign.events.addAll([
      'phone',
      'key',
      'adapter',
      'delivered',
      'news',
      'alley',
      'resolved',
      'pulse',
      'night',
      'finish',
    ]);
    s.phase = PlayPhase.complete;
    await tester.pumpWidget(MaterialApp(home: GameShell(session: s)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    final play = find.text('Jogar fase 02 · 02:00');
    await tester.ensureVisible(play);
    await tester.tap(play);
    await tester.pump();
    expect(s.campaign.inChapterTwo, isTrue);
    expect(s.phase, PlayPhase.dialogue);
    expect(find.textContaining('01:58'), findsWidgets);
    expect(tester.takeException(), isNull);
    while (s.phase == PlayPhase.dialogue) {
      s.nextLine();
    }
    s.campaign.mark('chapter2_complete');
    s.phase = PlayPhase.complete;
    s.notifyListeners();
    await tester.pump();
    expect(find.text('FASE 02 CONCLUÍDA'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    s.dispose();
  });
}
