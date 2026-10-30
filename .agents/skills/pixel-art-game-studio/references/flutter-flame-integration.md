# Flutter + Flame integration

The project baseline is Flutter 3.47.7, Dart 3.13.5, Flame 1.38.2. Recheck the lockfile and source
signatures before copying examples. Flame is used by `SilencioGame`, but the current game renderer
loads `ui.Image` and draws much of the isometric scene itself. Use Flame components selectively;
do not turn one illustrative example into a renderer migration.

## Character animation and camera example

This generic Flame 1.38.2 example assumes a row-per-direction atlas with equal cell dimensions.
Use a separate row per action if the game needs multiple states. Adapt the asset path, anchor and
direction-row mapping to the manifest; actor-frame rendering may need custom selection.

```dart
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';

class SpritePreviewGame extends FlameGame {
  SpritePreviewGame()
      : super(camera: CameraComponent.withFixedResolution(width: 320, height: 180));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final image = await images.load('actors/actor_caio_walk.png');
    final sheet = SpriteSheet(image: image, srcSize: Vector2(128, 144));
    final walkSouth = sheet.createAnimation(row: 4, stepTime: 0.12);
    world.add(SpriteAnimationComponent(
      animation: walkSouth,
      size: Vector2(128, 144),
      position: Vector2(160, 90),
      anchor: Anchor.bottomCenter,
    ));
  }
}
```

`FlameGame` supplies a `World` and `CameraComponent` by default. Use `HasCollisionDetection` on a
component tree only when Flame hitboxes are actually used. The game may instead keep its own
navigation/collision model; visual cutaways must not disable it.

## Minimal Tiled JSON map example without an added plugin

This small loader example is deliberately limited to one external sprite atlas and a ground
tilelayer. It demonstrates data → Flame components; extend it only for the Tiled features the map
uses. In SILÊNCIO, prefer adapting the parsed data to the existing world renderer rather than
creating a second world renderer.

```dart
import 'dart:convert';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';

Future<void> addGroundLayer(FlameGame game) async {
  final map = jsonDecode(await rootBundle.loadString('assets/maps/sample.tmj'))
      as Map<String, dynamic>;
  final ground = (map['layers'] as List).cast<Map<String, dynamic>>()
      .firstWhere((layer) => layer['name'] == 'Ground');
  final gids = (ground['data'] as List).cast<int>();
  final columns = map['width'] as int;
  final tileWidth = map['tilewidth'] as int;
  final tileHeight = map['tileheight'] as int;
  final image = await game.images.load('maps/urban_ground.png');
  final sheet = SpriteSheet(
    image: image,
    srcSize: Vector2(tileWidth.toDouble(), tileHeight.toDouble()),
  );
  const firstGid = 1; // matches the atlas tileset's firstgid in sample.tmj
  for (var index = 0; index < gids.length; index++) {
    final gid = gids[index];
    if (gid == 0) continue; // empty Tiled cell
    final x = index % columns;
    final y = index ~/ columns;
    final position = Vector2(
      (x - y) * tileWidth / 2,
      (x + y) * tileHeight / 2,
    );
    game.world.add(SpriteComponent(
      sprite: sheet.getSpriteById(gid - firstGid),
      position: position,
      size: Vector2(tileWidth.toDouble(), tileHeight.toDouble()),
      anchor: Anchor.center,
    ));
  }
}
```

This example assumes the tilelayer is uncompressed `data` in JSON and the atlas grid directly
matches the map tile dimensions. Tiled can encode layers with base64/compression, flip flags, chunks,
multiple tilesets and offsets; implement those cases explicitly or use a verified Tiled parser. The
simple snippet is not a complete Tiled runtime.

## Tiled component and exports

`TiledComponent` requires the separate `flame_tiled` package and a compatible Tiled export. It is
not available from `flame` alone and is not installed in this project baseline. Do not present a
Tiled loading snippet as runnable until that dependency and version have been verified. The provided
validator supports structural checking of `.tmj`, `.json`, `.tmx`, and `.tsx` inputs.

For mobile, check atlas dimensions/memory, image decode size, draw calls, camera bounds, touch/UI
scale and actual Android performance. Automated PNG/map checks do not establish visual or device QA.

Runnable-in-project source examples are in `examples/flame_animation_preview.dart`,
`examples/flame_movement_collision.dart`, and `examples/tiled_json_ground_loader.dart`. The sprite
example refers to the existing Caio atlas; the map loader accepts caller-supplied map and atlas
asset paths. The collision example detects overlap but deliberately does not claim to resolve or
block movement; a production solver must handle that separately.
