// Minimal Flame 1.38.2 preview. This does not replace SILÊNCIO's actor renderer.
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';

class SpritePreviewGame extends FlameGame {
  SpritePreviewGame()
    : super(
        camera: CameraComponent.withFixedResolution(width: 320, height: 180),
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final image = await images.load('actors/caio_walk.png');
    final sheet = SpriteSheet(image: image, srcSize: Vector2(128, 144));
    world.add(
      SpriteAnimationComponent(
        animation: sheet.createAnimation(row: 4, stepTime: 0.12),
        size: Vector2(128, 144),
        position: Vector2(160, 90),
        anchor: Anchor.bottomCenter,
      ),
    );
  }
}
