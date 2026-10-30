import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/services/save_repository.dart';
import 'package:silencio/ui/game_shell.dart';
import 'package:silencio/ui/narrative_backdrop.dart';

void main() {
  for (final size in [const Size(360, 800), const Size(800, 360)]) {
    testWidgets('English menu and five contained opening panels at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Do not reuse a cached asset Future created in another test's fake zone.
      rootBundle.evict('assets/data/chapter_01.json');
      SharedPreferences.setMockInitialValues({
        'silencio.language': 'en',
        'silencio.text': true,
        'silencio.highContrast': true,
      });
      final s = await GameSession.load(
        SaveRepository(await SharedPreferences.getInstance()),
      );
      await tester.pumpWidget(MaterialApp(home: GameShell(session: s)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('New game'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('menu-continue')))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
      s.startNew();
      await tester.pump();
      final cityPlaceholder = tester.widget<Image>(
        find.byKey(const ValueKey('opening-city-placeholder')),
      );
      expect(
        (cityPlaceholder.image as AssetImage).assetName,
        'assets/images/video_placeholder_01_abertura_v01.png',
      );
      expect(find.text('SANTA AURORA · 07:12'), findsOneWidget);
      s.nextOpening();
      await tester.pump();
      const openingAssets = [
        'assets/images/opening_storyboard_v1.png',
        'assets/images/opening_storyboard_v1.png',
        'assets/images/opening_storyboard_v1.png',
        'assets/images/opening_subject07_v1.png',
        'assets/images/opening_storyboard_v1.png',
      ];
      const storyboardCells = [0, 1, 2, null, 3];
      for (var page = 0; page < 5; page++) {
        expect(s.openingPage, page);
        final backdrop = tester.widget<NarrativeBackdrop>(
          find.byType(NarrativeBackdrop),
        );
        expect(backdrop.asset, openingAssets[page]);
        expect(backdrop.atlasIndex, storyboardCells[page]);
        expect(backdrop.fit, BoxFit.contain);
        await rootBundle.load(openingAssets[page]);
        final imageBottom = tester
            .getBottomLeft(find.byType(NarrativeBackdrop))
            .dy;
        final textTop = tester
            .getTopLeft(find.text(GameSession.openingEn[page].$2))
            .dy;
        expect(textTop, greaterThanOrEqualTo(imageBottom));
        expect(find.text('Skip opening'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (page < 4) {
          s.nextOpening();
          await tester.pump();
        }
      }
      s.finishOpening();
      await tester.pump();
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(find.text('STAMINA'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
    });
  }
}
