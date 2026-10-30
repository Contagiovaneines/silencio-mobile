import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/models/campaign.dart';
import 'package:silencio/services/save_repository.dart';
import 'package:silencio/ui/game_shell.dart';

void main() {
  testWidgets('landscape phone uses the compact two-column menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(936, 432);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final session = await GameSession.load(
      SaveRepository(await SharedPreferences.getInstance()),
    );

    await tester.pumpWidget(MaterialApp(home: GameShell(session: session)));
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byKey(const Key('menu-wide-layout')), findsOneWidget);
    expect(
      tester.getBottomRight(find.byKey(const Key('menu-extras'))).dy,
      lessThanOrEqualTo(412),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  for (final size in [
    const Size(360, 800),
    const Size(768, 1024),
    const Size(1366, 768),
  ]) {
    testWidgets('cinematic menu fits $size and keeps Continue disabled', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      rootBundle.evict('assets/data/chapter_01.json');
      SharedPreferences.setMockInitialValues({});
      final session = await GameSession.load(
        SaveRepository(await SharedPreferences.getInstance()),
      );

      await tester.pumpWidget(MaterialApp(home: GameShell(session: session)));
      await tester.pump(const Duration(milliseconds: 80));

      expect(find.text('SILÊNCIO'), findsOneWidget);
      expect(find.text('07:12'), findsOneWidget);
      expect(find.byKey(const Key('menu-continue')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('menu-continue')))
            .onPressed,
        isNull,
      );
      expect(find.byKey(const Key('menu-new-game')), findsOneWidget);
      expect(find.byKey(const Key('menu-options')), findsOneWidget);
      expect(find.byKey(const Key('menu-extras')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('menu-extras')));
      await tester.pump();
      expect(find.text('Jornada'), findsOneWidget);
      expect(find.text('Reassistir à abertura'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      session.dispose();
    });
  }

  testWidgets('Continue resumes the real saved campaign', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    rootBundle.evict('assets/data/chapter_01.json');
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = SaveRepository(preferences);
    final saved = Campaign()..floor = 1;
    await repository.save(saved);
    final session = await GameSession.load(repository);

    await tester.pumpWidget(MaterialApp(home: GameShell(session: session)));
    await tester.pump(const Duration(milliseconds: 80));
    final continueButton = tester.widget<FilledButton>(
      find.byKey(const Key('menu-continue')),
    );
    expect(continueButton.onPressed, isNotNull);
    expect(find.textContaining(session.campaign.location), findsOneWidget);

    await tester.tap(find.byKey(const Key('menu-continue')));
    await tester.pump();
    expect(session.phase, PlayPhase.playing);
    expect(session.campaign.floor, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
}
