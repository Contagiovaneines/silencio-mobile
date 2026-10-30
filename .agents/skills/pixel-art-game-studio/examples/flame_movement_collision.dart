// Small Flame 1.38.2 component example: delta-time movement and overlap detection.
// Collision callbacks are not a navigation solver; production movement must resolve/block motion.
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

class CollisionPreviewGame extends FlameGame with HasCollisionDetection {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    world.add(MovingBody(position: Vector2(80, 90)));
    world.add(StaticObstacle(position: Vector2(100, 90)));
    camera.viewfinder.zoom = 1.0;
  }
}

class MovingBody extends PositionComponent with CollisionCallbacks {
  MovingBody({required super.position})
    : super(size: Vector2.all(32), anchor: Anchor.center);

  final Vector2 input = Vector2(1, 0);
  bool touchingObstacle = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(size: Vector2(20, 12), position: Vector2(6, 18)));
  }

  @override
  void update(double dt) {
    position += input.normalized() * 40 * dt;
    touchingObstacle = false;
    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    touchingObstacle = true;
    super.onCollision(points, other);
  }
}

class StaticObstacle extends PositionComponent {
  StaticObstacle({required super.position})
    : super(size: Vector2.all(32), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }
}
