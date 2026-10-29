import 'dart:ui';

/// One coordinate system for the three storeys and their exterior openings.
class BuildingDoor {
  const BuildingDoor(
    this.id,
    this.floor,
    this.center,
    this.inside,
    this.outside, {
    this.locked = false,
  });
  final String id;
  final int floor;
  final Offset center, inside, outside;
  final bool locked;
  Rect get collider => Rect.fromCenter(center: center, width: 1.8, height: .36);
}

class ResidentialLayout {
  static const footprint = Rect.fromLTRB(2, 2, 24, 16);
  static const corridor = Rect.fromLTRB(2, 10, 24, 16);
  static const apartment203 = Rect.fromLTRB(2, 2, 12, 10);
  static const bathroom = Rect.fromLTRB(8, 7, 12, 10);
  static const down = Offset(10, 14.5);
  static const up = Offset(4.7, 14.5);
  // Front openings are reused by the internal wall and the street facade.
  static const frontWindows = [
    Offset(10.6, 10),
    Offset(16.7, 10),
    Offset(22.7, 10),
  ];
  static const doors = [
    BuildingDoor('203', 2, Offset(7, 10), Offset(7, 9.15), Offset(7, 10.85)),
    BuildingDoor(
      '202',
      2,
      Offset(15, 10),
      Offset(15, 9.15),
      Offset(15, 10.85),
      locked: true,
    ),
    BuildingDoor(
      '201',
      2,
      Offset(21, 10),
      Offset(21, 9.15),
      Offset(21, 10.85),
      locked: true,
    ),
    BuildingDoor(
      '103',
      1,
      Offset(7, 10),
      Offset(7, 9.15),
      Offset(7, 10.85),
      locked: true,
    ),
    BuildingDoor(
      '102',
      1,
      Offset(15, 10),
      Offset(15, 9.15),
      Offset(15, 10.85),
      locked: true,
    ),
    BuildingDoor(
      '101',
      1,
      Offset(21, 10),
      Offset(21, 9.15),
      Offset(21, 10.85),
      locked: true,
    ),
    BuildingDoor(
      'entrada',
      0,
      Offset(7, 16),
      Offset(7, 15.15),
      Offset(7, 16.85),
    ),
    BuildingDoor('banheiro', 2, Offset(9, 7), Offset(9, 7.85), Offset(9, 6.15)),
  ];
  static BuildingDoor door(String id) => doors.firstWhere((d) => d.id == id);
  static Iterable<Rect> partitions(int floor) sync* {
    if (floor == 2) {
      yield const Rect.fromLTRB(7.82, 7, 8.18, 10);
      yield const Rect.fromLTRB(8, 6.82, 8.1, 7.18);
      yield const Rect.fromLTRB(9.9, 6.82, 12, 7.18);
    }
    // The front wall has openings supplied by the door definitions.
    if (floor > 0) {
      for (final unit in [
        apartment203,
        const Rect.fromLTRB(12, 2, 18, 10),
        const Rect.fromLTRB(18, 2, 24, 10),
      ]) {
        yield Rect.fromLTRB(unit.left, 1.82, unit.right, 2.18);
        yield Rect.fromLTRB(unit.left - .18, 2, unit.left + .18, 10);
        final x = unit == apartment203 ? 7.0 : unit.center.dx;
        yield Rect.fromLTRB(unit.left, 9.82, x - .9, 10.18);
        yield Rect.fromLTRB(x + .9, 9.82, unit.right, 10.18);
      }
      yield const Rect.fromLTRB(23.82, 2, 24.18, 16);
      yield const Rect.fromLTRB(1.82, 10, 2.18, 16);
      yield const Rect.fromLTRB(2, 15.82, 24, 16.18);
    } else {
      yield const Rect.fromLTRB(1.82, 10, 2.18, 16);
      yield const Rect.fromLTRB(2, 15.82, 6.1, 16.18);
      yield const Rect.fromLTRB(7.9, 15.82, 16, 16.18);
      // The garage has its own entrance east of the residential hall.
      yield const Rect.fromLTRB(15.82, 10, 16.18, 12);
      yield const Rect.fromLTRB(15.82, 14, 16.18, 16);
    }
  }
}
