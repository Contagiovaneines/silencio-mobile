import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/models/campaign.dart';
import 'package:silencio/services/save_repository.dart';
import 'package:silencio/ui/game_shell.dart';

void main() {
  testWidgets(
    'full settings are available from pause without resuming the world',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      rootBundle.evict('assets/data/chapter_01.json');
      SharedPreferences.setMockInitialValues({
        'silencio.language': 'en',
        'silencio.sound': false,
        'silencio.music': true,
        'silencio.audioEffects': true,
      });
      final store = await SharedPreferences.getInstance();
      final s = await GameSession.load(SaveRepository(store));
      s.startNew();
      s.finishOpening();
      s.pause();
      final campaign = s.campaign.encode();
      await tester.pumpWidget(MaterialApp(home: GameShell(session: s)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Settings'));
      await tester.pump();
      final ambient = find.widgetWithText(SwitchListTile, 'Ambient audio');
      expect(tester.widget<SwitchListTile>(ambient).onChanged, isNull);
      expect(tester.widget<SwitchListTile>(ambient).value, isTrue);
      await tester.tap(find.text('Enable audio'));
      await tester.pump();
      expect(tester.widget<SwitchListTile>(ambient).onChanged, isNotNull);
      expect(store.getBool('silencio.music'), isTrue);
      await tester.ensureVisible(find.text('High contrast panels'));
      await tester.tap(find.text('High contrast panels'));
      await tester.pump();
      expect(store.getBool('silencio.highContrast'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(s.phase, PlayPhase.paused);
      expect(find.text('The city can wait.'), findsOneWidget);
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.ensureVisible(find.text('Back to pause'));
      await tester.tap(find.text('Back to pause'));
      await tester.pump();
      expect(s.phase, PlayPhase.paused);
      expect(find.text('The city can wait.'), findsOneWidget);
      expect(s.campaign.encode(), campaign);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
    },
  );
}
