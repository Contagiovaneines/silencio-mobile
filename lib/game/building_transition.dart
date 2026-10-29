import 'dart:math' as math;
import 'dart:ui';

import 'building_layout.dart';
import 'world_model.dart';

enum BuildingJourney { leaveApartment, enterApartment, downstairs, upstairs }

/// Owns one portal crossing. Stable landings, not animation frames, are saved.
class BuildingTransition {
  BuildingTransition(
    this.kind,
    this.start, {
    this.sourceFloor = 2,
    this.doorId = '203',
  });
  final BuildingJourney kind;
  final Offset start;
  final int sourceFloor;
  final String doorId;
  double elapsed = 0;
  bool _changedFloor = false;
  bool get isDoor =>
      kind == BuildingJourney.leaveApartment ||
      kind == BuildingJourney.enterApartment;
  int get targetFloor => isDoor
      ? sourceFloor
      : sourceFloor + (kind == BuildingJourney.downstairs ? -1 : 1);
  double get duration => isDoor ? 2.2 : 2.8;
  double get progress => (elapsed / duration).clamp(0, 1);
  String get caption => isDoor
      ? '${kind == BuildingJourney.leaveApartment ? 'Saindo' : 'Entrando'} · ${doorId == 'entrada'
            ? 'entrada residencial'
            : doorId == 'banheiro'
            ? 'banheiro'
            : 'apartamento $doorId'}'
      : '${kind == BuildingJourney.downstairs ? 'Descendo' : 'Subindo'} · ${sourceFloor == 0 ? 'térreo' : '$sourceFloorº andar'} ao ${targetFloor == 0 ? 'térreo' : '$targetFloorº andar'}';
  double get fade => isDoor ? 0 : (1 - (progress - .5).abs() / .12).clamp(0, 1);
  double get doorAngle {
    if (!isDoor || elapsed < .4) return 0;
    if (elapsed < 1) return (elapsed - .4) / .6;
    if (elapsed < 1.8) return 1;
    return (1 - (elapsed - 1.8) / .4).clamp(0, 1);
  }

  double get actorDrop => isDoor
      ? 0
      : (kind == BuildingJourney.downstairs ? 1 : -1) *
            (progress < .5 ? progress : progress - 1) *
            50;
  bool advance(double dt, WorldModel world) {
    final previousElapsed = elapsed;
    elapsed = math.min(duration, elapsed + dt);
    final before = Offset(world.campaign.x, world.campaign.y);
    final oldFloor = world.campaign.floor;
    late Offset next;
    if (isDoor) {
      final door = ResidentialLayout.door(doorId);
      final out = kind == BuildingJourney.leaveApartment;
      final approach = out ? door.inside : door.outside;
      final exit = out ? door.outside : door.inside;
      next = elapsed < .4
          ? Offset.lerp(start, approach, elapsed / .4)!
          : elapsed < 1
          ? approach
          : elapsed < 1.8
          ? Offset.lerp(approach, exit, (elapsed - 1) / .8)!
          : exit;
      world.setDoor(doorId, doorAngle > .1);
    } else {
      final down = kind == BuildingJourney.downstairs;
      final first = Offset(
        down ? ResidentialLayout.down.dx : ResidentialLayout.up.dx,
        15.35,
      );
      final arrival = Offset(
        down ? ResidentialLayout.up.dx : ResidentialLayout.down.dx,
        15.35,
      );
      final landing = Offset(arrival.dx, 13.3);
      if (progress < .5) {
        next = Offset.lerp(start, first, progress * 2)!;
      } else {
        if (!_changedFloor) {
          if (!world.canArrive(targetFloor, arrival)) {
            elapsed = previousElapsed;
            return false;
          }
          world.changeFloor(targetFloor, arrival);
          _changedFloor = true;
        }
        next = Offset.lerp(arrival, landing, (progress - .5) * 2)!;
      }
    }
    if (!world.canTravel(Offset(world.campaign.x, world.campaign.y), next)) {
      elapsed = previousElapsed;
      return false;
    }
    world.campaign.x = next.dx;
    world.campaign.y = next.dy;
    final delta = next - before;
    if (oldFloor == world.campaign.floor && delta.distance > .001) {
      world.walked += delta.distance;
      world.facingX = delta.dx / delta.distance;
      world.facingY = delta.dy / delta.distance;
    }
    if (elapsed >= duration) {
      if (isDoor) world.setDoor(doorId, false);
      return true;
    }
    return false;
  }
}
