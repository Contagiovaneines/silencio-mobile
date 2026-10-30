// Minimal one-atlas/uncompressed-layer Tiled JSON loader for Flame 1.38.2.
// It is an example, not the SILÊNCIO runtime map loader.
import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';

Future<void> addGroundLayer(
  FlameGame game, {
  required String mapAsset,
  required String tilesAsset,
}) async {
  final map =
      jsonDecode(await rootBundle.loadString(mapAsset)) as Map<String, dynamic>;
  if (map['orientation'] != 'isometric') {
    throw FormatException('Expected an isometric Tiled map: $mapAsset');
  }
  final ground = (map['layers'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .firstWhere((layer) => layer['name'] == 'Ground');
  if (ground['encoding'] == 'base64' || ground['compression'] != null) {
    throw const FormatException(
      'Example only accepts uncompressed Tiled JSON data',
    );
  }
  final gids = (ground['data'] as List<dynamic>).cast<int>();
  final columns = map['width'] as int;
  final tileWidth = map['tilewidth'] as int;
  final tileHeight = map['tileheight'] as int;
  final tileset = (map['tilesets'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .single;
  final firstGid = tileset['firstgid'] as int;
  final image = await game.images.load(tilesAsset);
  final sheet = SpriteSheet(
    image: image,
    srcSize: Vector2(tileWidth.toDouble(), tileHeight.toDouble()),
  );

  for (var index = 0; index < gids.length; index++) {
    final gid = gids[index];
    if (gid == 0) continue;
    final x = index % columns;
    final y = index ~/ columns;
    final position = Vector2((x - y) * tileWidth / 2, (x + y) * tileHeight / 2);
    game.world.add(
      SpriteComponent(
        sprite: sheet.getSpriteById(gid - firstGid),
        position: position,
        size: Vector2(tileWidth.toDouble(), tileHeight.toDouble()),
        anchor: Anchor.center,
        priority: x + y,
      ),
    );
  }
}
