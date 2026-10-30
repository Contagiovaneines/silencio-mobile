import 'package:flutter_test/flutter_test.dart';
import 'package:silencio/game/world_model.dart';
import 'package:silencio/models/campaign.dart';

void main() {
  test('shop contents appear after entering, while collision stays fixed', () {
    const shopFurniture = {'shelf', 'fridge', 'counter'};
    final campaign = Campaign()
      ..floor = 0
      ..x = 28
      ..y = 25;
    final world = WorldModel(campaign);
    expect(
      world.visibleFurniture.where((f) => shopFurniture.contains(f.kind)),
      isEmpty,
    );
    expect(world.visiblePeople.where((p) => p.id == 'orlando'), isEmpty);
    expect(world.canStand(25, 19), isFalse);
    expect(world.canTravel(const Offset(28, 25), const Offset(28, 23)), isTrue);
    campaign.y = 23;
    expect(
      world.visibleFurniture.where((f) => shopFurniture.contains(f.kind)),
      hasLength(shopFurniture.length),
    );
    expect(world.visiblePeople.where((p) => p.id == 'orlando'), isNotEmpty);
    expect(world.canStand(25, 19), isFalse);
  });
}
