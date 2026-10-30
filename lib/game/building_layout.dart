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
    this.leafHeight = 53,
  });
  final String id;
  final int floor;
  final Offset center, inside, outside;
  final bool locked;

  /// Door panels stay just below the building's 58 px wall height.
  final double leafHeight;
  Rect get collider => Rect.fromCenter(center: center, width: 1.8, height: .36);
}

class BuildingWindow {
  const BuildingWindow(this.id, this.floor, this.center);
  final String id;
  final int floor;
  final Offset center;
  Rect get collider =>
      Rect.fromLTRB(center.dx - .45, 9.82, center.dx + .45, 10.18);
}

class ResidentialLayout {
  static const wallHeight = 58.0;
  static const footprint = Rect.fromLTRB(2, 2, 24, 16);
  static const corridor = Rect.fromLTRB(2, 10, 24, 16);
  static const apartment103 = Rect.fromLTRB(2, 2, 12, 10);
  static const apartment102 = Rect.fromLTRB(12, 2, 18, 10);
  static const apartment101 = Rect.fromLTRB(18, 2, 24, 10);
  static const apartment203 = Rect.fromLTRB(2, 2, 12, 10);
  static const apartment202 = Rect.fromLTRB(12, 2, 18, 10);
  static const apartment201 = Rect.fromLTRB(18, 2, 24, 10);
  static const bathroom = Rect.fromLTRB(8, 7, 12, 10);
  static const down = Offset(10, 14.5);
  static const up = Offset(4.7, 14.5);
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

  static const windows = [
    BuildingWindow('103', 1, Offset(10.6, 10)),
    BuildingWindow('102', 1, Offset(16.7, 10)),
    BuildingWindow('101', 1, Offset(22.7, 10)),
    BuildingWindow('203', 2, Offset(10.6, 10)),
    BuildingWindow('202', 2, Offset(16.7, 10)),
    BuildingWindow('201', 2, Offset(22.7, 10)),
  ];

  static Rect? unitAt(int floor, Offset position) {
    final units = switch (floor) {
      1 => const [apartment103, apartment102, apartment101],
      2 => const [apartment203, apartment202, apartment201],
      _ => const <Rect>[],
    };
    for (final unit in units) {
      if (unit.contains(position)) return unit;
    }
    return null;
  }

  static BuildingDoor door(String id) => doors.firstWhere((d) => d.id == id);
  static Iterable<Rect> partitions(int floor) sync* {
    if (floor == 2) {
      // Apartment 203 has distinct bedroom, living and kitchen zones. Leave
      // generous doorless passages through each divider for mobile navigation.
      yield const Rect.fromLTRB(1.98, 5.38, 4.65, 5.66);
      yield const Rect.fromLTRB(7.82, 1.98, 8.1, 4.75);
      yield const Rect.fromLTRB(7.82, 5.85, 8.1, 7.0);
      yield const Rect.fromLTRB(7.82, 7, 8.18, 10);
      yield const Rect.fromLTRB(8, 6.82, 8.1, 7.18);
      yield const Rect.fromLTRB(9.9, 6.82, 12, 7.18);
    }
    // The front wall has openings supplied by the door definitions.
    if (floor > 0) {
      final units = [
        apartment203,
        const Rect.fromLTRB(12, 2, 18, 10),
        const Rect.fromLTRB(18, 2, 24, 10),
      ];
      for (var index = 0; index < units.length; index++) {
        final unit = units[index];
        yield Rect.fromLTRB(unit.left, 1.82, unit.right, 2.18);
        yield Rect.fromLTRB(unit.left - .18, 2, unit.left + .18, 10);
        final x = unit == apartment203 ? 7.0 : unit.center.dx;
        final openings = <({double center, double width})>[
          (center: x, width: 1.8),
          (
            center: windows[floor == 1 ? index : index + 3].center.dx,
            width: .9,
          ),
        ]..sort((a, b) => a.center.compareTo(b.center));
        var left = unit.left;
        for (final opening in openings) {
          final openingLeft = opening.center - opening.width / 2;
          final openingRight = opening.center + opening.width / 2;
          if (openingLeft > left) {
            yield Rect.fromLTRB(left, 9.82, openingLeft, 10.18);
          }
          left = openingRight;
        }
        if (left < unit.right) {
          yield Rect.fromLTRB(left, 9.82, unit.right, 10.18);
        }
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



