import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/models/campaign.dart';
import 'package:silencio/services/save_repository.dart';
import 'package:silencio/ui/game_shell.dart';

void main() {
  for (final size in [const Size(832, 384), const Size(1366, 768)]) {
    testWidgets(
      'opening, keyboard, map and portraits at ${size.width}x${size.height}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        rootBundle.evict('assets/data/chapter_01.json');
        SharedPreferences.setMockInitialValues({});
        final s = await GameSession.load(
          SaveRepository(await SharedPreferences.getInstance()),
        );
        await tester.pumpWidget(MaterialApp(home: GameShell(session: s)));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Configurações'));
        await tester.pump();
        expect(s.phase, PlayPhase.menuSettings);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Voltar ao menu'));
        await tester.tap(find.text('Voltar ao menu'));
        await tester.pump();
        await tester.tap(find.text('Jornada'));
        await tester.pump();
        await tester.tap(find.text('02:00'));
        await tester.pump();
        expect(
          find.textContaining('ainda não está implementado'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Voltar'));
        await tester.pump();
        await tester.tap(find.text('Novo jogo'));
        await tester.pump();
        expect(find.text('Pular abertura'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Pular abertura'));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
        await tester.pump();
        expect(
          find.textContaining('2º ANDAR · APARTAMENTO 203'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
        expect(s.world.inputX, greaterThan(0));
        expect(s.world.inputY, lessThan(0));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
        expect(s.world.inputX, 0);
        s.phone();
        await tester.pump();
        expect(find.textContaining('Você passa perto'), findsOneWidget);
        expect(tester.takeException(), isNull);
        s.closePanel();
        s.pause();
        await tester.pump();
        expect(find.text('Sons e ambiente'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        s.dispose();
      },
    );
  }
}
