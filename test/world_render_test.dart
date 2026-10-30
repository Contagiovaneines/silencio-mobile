import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/models/campaign.dart';
import 'package:silencio/game/building_layout.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/game/silencio_game.dart';
import 'package:silencio/services/save_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scene in [
    (name: 'apartment', floor: 2, x: 6.5, y: 6.0),
    (name: 'apartment-resting', floor: 2, x: 3.55, y: 3.55),
    (name: 'corridor', floor: 2, x: 7.0, y: 12.0),
    (name: 'landing', floor: 1, x: 7.0, y: 12.0),
    (name: 'entrance', floor: 0, x: 7.0, y: 15.0),
    (name: 'exterior', floor: 0, x: 8.0, y: 18.0),
    (name: 'street', floor: 0, x: 28.0, y: 25.0),
    (name: 'shop-inside', floor: 0, x: 28.0, y: 21.0),
    (name: 'shop-exterior', floor: 0, x: 28.0, y: 25.0),
    (name: 'bus-stop', floor: 0, x: 43.5, y: 29.5),
    (name: 'combat-aim', floor: 0, x: 38.0, y: 25.0),
    (name: 'combat-attack-right', floor: 0, x: 38.0, y: 25.0),
    (name: 'fallen-enemy', floor: 0, x: 38.0, y: 26.5),
    (name: 'player-defeated', floor: 0, x: 38.0, y: 26.5),
    (name: 'night-garage', floor: 0, x: 18.0, y: 15.0),
    (name: 'night-torch', floor: 0, x: 18.0, y: 15.0),
    (name: 'night-corridor', floor: 2, x: 18.0, y: 12.0),
    (name: 'night-service-post', floor: 0, x: 42.5, y: 25.5),
  ]) {
    test(
      'render ${scene.name} keeps the building connected to the world',
      () async {
        SharedPreferences.setMockInitialValues({});
        final session = await GameSession.load(
          SaveRepository(await SharedPreferences.getInstance()),
        );
        session.startNew();
        session.finishOpening();
        session.reducedEffects = true;
        session.campaign
          ..floor = scene.floor
          ..x = scene.x
          ..y = scene.y;
        if (scene.name == 'apartment-resting') {
          session.world
            ..resting = 'lie'
            ..restAnchor = const ui.Offset(3.55, 3.55);
        }
        if (scene.name.startsWith('night-')) {
          session.campaign.events.addAll([
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
            'chapter2_started',
          ]);
          session.world.restore(session.campaign);
          if (scene.name == 'night-torch') {
            session.campaign.mark('chapter2_torch');
          }
        }
        if (scene.name.startsWith('combat-')) {
          session.campaign.events.addAll(['alley', 'weapon']);
          session.world.aimAt(38, 26.5);
          if (scene.name == 'combat-attack-right') {
            session.world.attackWindup = .25;
          }
        }
        if (scene.name == 'fallen-enemy') {
          session.campaign
            ..events.addAll(['alley', 'weapon', 'enemy_defeated', 'resolved'])
            ..enemyHealth = 0
            ..rememberDownedEnemy(const ui.Offset(39, 26.5));
          session.world.restore(session.campaign);
        }
        if (scene.name == 'player-defeated') {
          session.campaign.health = 0;
          session.tick(.02);
          expect(session.phase, PlayPhase.defeated);
        }
        final game = SilencioGame(session);
        game.onGameResize(Vector2(1280, 800));
        await game.onLoad();
        final recorder = ui.PictureRecorder();
        game.render(ui.Canvas(recorder));
        final picture = recorder.endRecording();
        final image = await picture.toImage(1280, 800);
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        if (scene.name == 'apartment') {
          final camera = game.iso(scene.x, scene.y);
          int brightestChannelAtWorld(double x, double y) {
            final screen =
                (game.iso(x, y) - camera) * game.zoom +
                const ui.Offset(640, 424);
            final index = (screen.dy.toInt() * 1280 + screen.dx.toInt()) * 4;
            return [
              bytes!.getUint8(index),
              bytes.getUint8(index + 1),
              bytes.getUint8(index + 2),
            ].reduce(math.max);
          }

          int brightestChannelAtScreen(ui.Offset screen) {
            final index = (screen.dy.toInt() * 1280 + screen.dx.toInt()) * 4;
            return [
              bytes!.getUint8(index),
              bytes.getUint8(index + 1),
              bytes.getUint8(index + 2),
            ].reduce(math.max);
          }

          expect(
            brightestChannelAtWorld(19, 5),
            lessThan(100),
            reason: 'The neighboring apartment must not render through 203.',
          );
          expect(
            brightestChannelAtWorld(7, 12),
            greaterThan(60),
            reason: 'A short connected hallway landing should ground the apartment doorway.',
          );
          expect(
            brightestChannelAtWorld(18, 12),
            lessThan(100),
            reason:
                'The hallway past the apartment threshold must remain hidden.',
          );
          expect(
            brightestChannelAtWorld(5.85, 6.85),
            greaterThan(145),
            reason: 'The living-room rug should have a visible center motif.',
          );
          final lowerFacade =
              (game.iso(7, ResidentialLayout.footprint.bottom) - camera) *
                  game.zoom +
              const ui.Offset(640, 424) +
              ui.Offset(0, 48 * game.zoom);
          expect(
            brightestChannelAtScreen(lowerFacade),
            greaterThan(60),
            reason: 'The apartment cutaway should show its facade below the floor, not float in empty space.',
          );
          final groundLevelFacade =
              (game.iso(7, ResidentialLayout.footprint.bottom) - camera) *
                  game.zoom +
              const ui.Offset(640, 424) +
              ui.Offset(0, 110 * game.zoom);
          expect(
            brightestChannelAtScreen(groundLevelFacade),
            greaterThan(60),
            reason: 'A second-floor apartment needs facade support down to street level.',
          );
          final sharedBuildingFacade =
              (game.iso(14, ResidentialLayout.footprint.bottom) - camera) *
                  game.zoom +
              const ui.Offset(640, 424) +
              ui.Offset(0, 22 * game.zoom);
          expect(
            brightestChannelAtScreen(sharedBuildingFacade),
            greaterThan(60),
            reason: 'The apartment cutaway must be supported by the full building footprint, not a floating single-unit box.',
          );
          final streetBelowApartment =
              (game.iso(8, 18) - camera) * game.zoom +
              const ui.Offset(640, 424) +
              ui.Offset(0, ResidentialLayout.wallHeight * 2 * game.zoom);
          expect(
            brightestChannelAtScreen(streetBelowApartment),
            greaterThan(60),
            reason: 'The second-floor cutaway should reveal the real ground plane below the facade instead of empty void.',
          );
          final firstFacadeWindow =
              (game.iso(7.5, ResidentialLayout.footprint.bottom) +
                      const ui.Offset(0, 31) -
                      camera) *
                  game.zoom +
              const ui.Offset(640, 424);
          var facadeGlassPixels = 0;
          for (
            var y = firstFacadeWindow.dy.floor() - 12;
            y < firstFacadeWindow.dy.floor() + 13;
            y++
          ) {
            for (
              var x = firstFacadeWindow.dx.floor() - 12;
              x < firstFacadeWindow.dx.floor() + 13;
              x++
            ) {
              final i = (y * 1280 + x) * 4;
              final r = bytes!.getUint8(i),
                  g = bytes.getUint8(i + 1),
                  b = bytes.getUint8(i + 2);
              if (r > 45 && r < 150 && g > 65 && b > 70 && b < 165) {
                facadeGlassPixels++;
              }
            }
          }
          expect(
            facadeGlassPixels,
            greaterThan(25),
            reason: 'The second-floor cutaway facade needs visible glazed windows, not crossed placeholder marks.',
          );
        }
        if (scene.name == 'corridor') {
          final camera = game.iso(scene.x, scene.y);
          final closedApartment =
              (game.iso(15, 5) - camera) * game.zoom +
              const ui.Offset(640, 424);
          final closedApartmentIndex =
              (closedApartment.dy.toInt() * 1280 + closedApartment.dx.toInt()) *
              4;
          expect(
            bytes!.getUint8(closedApartmentIndex + 2),
            greaterThan(70),
            reason: 'An unoccupied apartment must be capped from the hallway so its floor and props do not show through.',
          );
          final window = game.iso(10.6, 10) - const ui.Offset(0, 31);
          final screen =
              (window - camera) * game.zoom + const ui.Offset(640, 424);
          var framePixels = 0;
          for (var y = screen.dy.toInt() - 24; y < screen.dy + 24; y++) {
            for (var x = screen.dx.toInt() - 14; x < screen.dx + 14; x++) {
              final i = (y * 1280 + x) * 4;
              final r = bytes.getUint8(i),
                  g = bytes.getUint8(i + 1),
                  b = bytes.getUint8(i + 2);
              if (r > 205 &&
                  r < 235 &&
                  g > 190 &&
                  g < 225 &&
                  b > 155 &&
                  b < 200) {
                framePixels++;
              }
            }
          }
          expect(
            framePixels,
            greaterThan(8),
            reason: 'A window must sit on its current floor wall, not float above its roof.',
          );
          final interactiveWindow =
              (game.iso(10.6, 10) - const ui.Offset(0, 20) - camera) *
                  game.zoom +
              const ui.Offset(640, 424);
          final reflection =
              interactiveWindow + ui.Offset(-4 * game.zoom, -19 * game.zoom);
          final reflectionIndex =
              (reflection.dy.toInt() * 1280 + reflection.dx.toInt()) * 4;
          final reflectionRgb = [
            bytes.getUint8(reflectionIndex),
            bytes.getUint8(reflectionIndex + 1),
            bytes.getUint8(reflectionIndex + 2),
          ];
          final glassBody =
              interactiveWindow + ui.Offset(-4 * game.zoom, -7 * game.zoom);
          final glassBodyIndex =
              (glassBody.dy.toInt() * 1280 + glassBody.dx.toInt()) * 4;
          final glassBodyRgb = [
            bytes.getUint8(glassBodyIndex),
            bytes.getUint8(glassBodyIndex + 1),
            bytes.getUint8(glassBodyIndex + 2),
          ];
          double luminance(List<int> rgb) =>
              .2126 * rgb[0] + .7152 * rgb[1] + .0722 * rgb[2];
          expect(
            luminance(reflectionRgb),
            greaterThan(luminance(glassBodyRgb) + 20),
            reason:
                'The sheen must read brighter than the unreflected glass pane.',
          );
        }
        final tag = Platform.environment['SILENCIO_RENDER_TAG'] ?? 'current';
        final directory = Directory('tools/art/out/world-review')
          ..createSync(recursive: true);
        File('${directory.path}/${scene.name}-$tag.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
        // The occupied unit gets a compact facade and threshold context without
        // revealing its neighbors or the whole surrounding floor.
        var visible = 0;
        for (var y = 620; y < 720; y++) {
          for (var x = 200; x < 1080; x++) {
            final i = (y * 1280 + x) * 4;
            if (bytes!.getUint8(i) > 35 || bytes.getUint8(i + 1) > 48) {
              visible++;
            }
          }
        }
        image.dispose();
        picture.dispose();
        game.onDispose();
        session.dispose();
        if (scene.name == 'apartment') {
          expect(
            visible,
            inInclusiveRange(15000, 110000),
            reason: 'Show a grounded facade while keeping neighboring interiors hidden.',
          );
        } else {
          expect(
            visible,
            greaterThan(18000),
            reason: 'The building must remain connected to its surroundings.',
          );
        }
      },
    );
  }
}
