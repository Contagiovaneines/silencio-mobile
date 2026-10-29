import 'dart:math' as math;
import 'dart:convert';
import 'dart:async';

import 'package:flutter/services.dart';

import '../services/game_audio.dart';
import '../services/game_preferences.dart';
import 'sprite_facing.dart';
import 'actor_animation.dart';
import 'animal_behaviour.dart';

import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flame/cache.dart';
import 'package:flutter/painting.dart';

import '../models/campaign.dart';
import 'game_session.dart';
import 'world_model.dart';
import 'building_layout.dart';

class SilencioGame extends FlameGame {
  SilencioGame(this.session, {this.enableAudio = false}) {
    images = Images();
  }
  final bool enableAudio;
  final GameAudio audio = GameAudio();
  final GameSession session;
  final Map<String, ui.Image> _sprites = {};
  final Map<String, TextPainter> _labels = {};
  final Map<String, Rect> _furnitureSources = {};
  final Map<String, Rect> _homeSources = {};
  final Map<int, ui.Picture> _grounds = {};
  int _cameraFloor = 2;
  bool _ready = false, _disposed = false;
  double _cameraX = 0, _cameraY = 0;
  bool _playerActuallyMoving = false, _enemyActuallyMoving = false;
  double get zoom => (size.y / 560).clamp(.78, 1.35);
  bool get _lowQuality =>
      GamePreferences(session.repository.preferences).lowQuality;
  static const ink = Color(0xff102029);
  static const teal = Color(0xff91beb1);
  static const amber = Color(0xffdfb477);

  Offset iso(double x, double y) => Offset((x - y) * 32, (x + y) * 16);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (!await _loadSprite('props', 'props.png')) return;
    for (final direction in ['N', 'NE', 'SE', 'S', 'SW', 'W', 'NW']) {
      for (var frame = 0; frame < 6; frame++) {
        final key = 'user_caio_${direction}_$frame';
        if (!await _loadSprite(key, '$key.png')) return;
      }
    }
    final manifest = jsonDecode(
      await rootBundle.loadString('assets/data/phase_assets.json'),
    ) as Map<String, dynamic>;
    for (final entry in manifest.entries) {
      if (!await _loadSprite(entry.key, entry.value as String)) return;
    }
    final furnitureData = jsonDecode(
      await rootBundle.loadString('assets/data/apartment_furniture.json'),
    ) as Map<String, dynamic>;
    for (final entry
        in (furnitureData['sprites'] as Map<String, dynamic>).entries) {
      final values = (entry.value as List).cast<num>();
      _furnitureSources[entry.key] = Rect.fromLTWH(
        values[0].toDouble(),
        values[1].toDouble(),
        values[2].toDouble(),
        values[3].toDouble(),
      );
    }
    final poses = jsonDecode(
      await rootBundle.loadString('assets/data/caio_home_poses.json'),
    ) as Map<String, dynamic>;
    for (final e in poses.entries) {
      final v = (e.value as List).cast<num>();
      _homeSources[e.key] = Rect.fromLTWH(
        v[0].toDouble(),
        v[1].toDouble(),
        v[2].toDouble(),
        v[3].toDouble(),
      );
    }
    for (final floor in [0, 1, 2]) {
      final recorder = ui.PictureRecorder();
      _drawGround(Canvas(recorder), floor: floor);
      _grounds[floor] = recorder.endRecording();
    }
    _cameraFloor = session.campaign.floor;
    final p = iso(session.campaign.x, session.campaign.y);
    _cameraX = p.dx;
    _cameraY = p.dy;
    _ready = true;
  }

  Future<bool> _loadSprite(String key, String path) async {
    if (_disposed) return false;
    final image = await images.load(path);
    if (_disposed) return false;
    _sprites[key] = image;
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final previousTravelled = session.world.walked;
    final previousEnemyTravelled = session.world.enemyWalked;
    session.tick(dt);
    _playerActuallyMoving = session.world.walked > previousTravelled + .00001;
    _enemyActuallyMoving =
        session.world.enemyWalked > previousEnemyTravelled + .00001;
    if (enableAudio) audio.update(session);
    final p = iso(session.campaign.x, session.campaign.y);
    if (_cameraFloor != session.campaign.floor) {
      _cameraFloor = session.campaign.floor;
      _cameraX = p.dx;
      _cameraY = p.dy;
    }
    final blend = 1 - math.exp(-dt * 7);
    _cameraX += (p.dx - _cameraX) * blend;
    _cameraY += (p.dy - _cameraY) * blend;
  }

  void tapGround(Offset screen) {
    if (session.phase != PlayPhase.playing) return;
    final local =
        (screen - Offset(size.x * .5, size.y * .53)) / zoom +
        Offset(_cameraX, _cameraY);
    final x = (local.dx / 32 + local.dy / 16) / 2;
    final y = (local.dy / 16 - local.dx / 32) / 2;
    session.world.moveTo(x, y);
  }

  Paint _paint(Color color) => Paint()..color = color;
  Path _poly(List<Offset> points) => Path()..addPolygon(points, true);

  void _drawGround(Canvas c, {required int floor}) {
    for (var y = 0; y < WorldModel.height; y++) {
      for (var x = 0; x < WorldModel.width; x++) {
        if (floor > 0 &&
            !ResidentialLayout.footprint.contains(
              Offset(x.toDouble(), y.toDouble()),
            )) {
          continue;
        }
        if (floor == 0 && y < 16 && !(x >= 2 && x < 24 && y >= 10)) {
          continue;
        }
        final apartment = floor == 2 && x >= 2 && x < 12 && y >= 2 && y < 10;
        final hall = x >= 2 && x < 24 && y >= 10 && y < 16;
        final garage = x >= 12 && x < 23 && y >= 10 && y < 16;
        final shop = x >= 24 && x < 32 && y >= 17 && y < 24;
        final road = y >= 26 && y <= 30 || x >= 43 && x < 50 && y >= 16;
        final plaza = x >= 15 && x < 26 && y >= 27 && y < 36;
        final bath = floor == 2 && x >= 8 && x < 12 && y >= 7 && y < 10;
        final tile = bath
            ? 'concrete'
            : apartment
            ? 'wood'
            : hall || garage || shop || plaza
            ? 'concrete'
            : road
            ? 'asphalt'
            : y >= 16
            ? 'sidewalk'
            : 'grass';
        final p = iso(x.toDouble(), y.toDouble());
        c.drawImageRect(
          _sprites['tile_$tile']!,
          const Rect.fromLTWH(0, 0, 64, 32),
          Rect.fromLTWH(p.dx - 32, p.dy, 64, 32),
          Paint()..color = const Color(0xffa5b1aa),
        );
        c.drawPath(
          _poly([
            p,
            p + const Offset(32, 16),
            p + const Offset(0, 32),
            p + const Offset(-32, 16),
          ]),
          Paint()..color = Color.fromRGBO(7, 25, 32, apartment ? .16 : .28),
        );
        if (road && y == 28 && x % 3 == 0) {
          c.drawLine(
            p + const Offset(-8, 12),
            p + const Offset(15, 23),
            _paint(const Color(0xffb5a26b))..strokeWidth = 2,
          );
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final c = canvas;
    c.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _paint(ink));
    if (!_ready) return;
    c.save();
    c.translate(size.x * .5, size.y * .53);
    c.scale(zoom);
    c.translate(-_cameraX, -_cameraY);
    c.drawPicture(_grounds[session.campaign.floor]!);
    if (session.campaign.floor == 0) {
      _drawTower(c);
    }
    _upperLanding(c);

    _drawPath(c);
    final draws =
        <
          ({
            double depth,
            void Function() draw,
            Rect? footprint,
            Offset? position,
          })
        >[];
    for (final block in session.world.visibleBlocks.where(
      (b) => _onScreen(b.bounds),
    )) {
      draws.add((
        depth: block.interior
            ? block.bounds.left + block.bounds.top
            : block.bounds.right + block.bounds.bottom,
        footprint: block.interior ? null : block.bounds,
        position: null,
        draw: () => _building(c, block),
      ));
    }
    for (final p
        in session.campaign.floor == 0
            ? [
                const Offset(7, 18),
                const Offset(21, 18.5),
                const Offset(26, 12),
              ]
            : <Offset>[]) {
      draws.add((
        depth: p.dx + p.dy,
        footprint: null,
        position: p,
        draw: () => _lamp(c, p.dx, p.dy),
      ));
    }
    for (final place in session.world.places) {
      final animal = switch (place.kind) {
        PointKind.cat => session.world.animals.cat,
        PointKind.dog => session.world.animals.dog,
        PointKind.pigeon => session.world.animals.pigeon,
        _ => null,
      };
      final elevated = animal != null && animal.elevation > .1;
      draws.add((
        depth: place.x + place.y + (elevated ? 2 : 0),
        footprint: null,
        position: elevated ? null : Offset(place.x, place.y),
        draw: () => _place(c, place),
      ));
    }
    for (final wall in ResidentialLayout.partitions(session.campaign.floor)) {
      final center = wall.center;
      draws.add((
        depth: center.dx + center.dy,
        footprint: wall,
        position: null,
        draw: () => _structuralWall(c, wall),
      ));
    }
    for (final person in session.world.people.where(
      (p) => _onScreen(Rect.fromCircle(center: Offset(p.x, p.y), radius: 1)),
    )) {
      draws.add((
        depth: person.x + person.y,
        footprint: null,
        position: Offset(person.x, person.y),
        draw: () => _actor(c, person.id, person.x, person.y, 1, 1, false),
      ));
    }
    for (final vehicle in session.world.visibleVehicles.where(
      (v) => _onScreen(v.bounds),
    )) {
      draws.add((
        depth: vehicle.position.dx + vehicle.position.dy,
        footprint: vehicle.bounds,
        position: null,
        draw: () => _vehicle(c, vehicle),
      ));
    }
    for (final furniture in session.world.visibleFurniture.where(
      (f) => _onScreen(f.bounds),
    )) {
      final b = furniture.bounds;
      draws.add((
        depth: b.center.dx + b.center.dy,
        footprint: b,
        position: null,
        draw: () => _furniture(c, furniture),
      ));
    }
    final player = session.campaign;
    draws.add((
      depth: player.x + player.y + (session.world.playerElevation > 0 ? 3 : 0),
      footprint: null,
      position: session.world.playerElevation > 0
          ? null
          : Offset(player.x, player.y),
      draw: () {
        if (session.phase == PlayPhase.transit) return;
        _actor(
          c,
          'caio',
          player.x,
          player.y,
          session.world.facingX,
          session.world.facingY,
          session.world.moving || session.phase == PlayPhase.buildingTransition,
        );
      },
    ));
    if (session.world.encounterActive) {
      draws.add((
        depth: session.world.enemyX + session.world.enemyY,
        footprint: null,
        position: Offset(session.world.enemyX, session.world.enemyY),
        draw: () => _enemy(c),
      ));
    }
    draws.sort((a, b) => a.depth.compareTo(b.depth));
    // A building spans several tiles: its far corner alone cannot order actors.
    // Constrain only overlapping projected footprints, then draw ready nodes by depth.
    final edges = List.generate(draws.length, (_) => <int>{});
    final incoming = List.filled(draws.length, 0);
    for (var i = 0; i < draws.length; i++) {
      final bounds = draws[i].footprint;
      if (bounds == null) continue;
      for (var j = 0; j < draws.length; j++) {
        final point = draws[j].position;
        if (point == null) continue;
        final projectedX = point.dx - point.dy;
        if (projectedX < bounds.left - bounds.bottom ||
            projectedX > bounds.right - bounds.top) {
          continue;
        }
        final inFront = point.dy >= bounds.bottom || point.dx >= bounds.right;
        final from = inFront ? i : j;
        final to = inFront ? j : i;
        if (edges[from].add(to)) incoming[to]++;
      }
    }
    final remaining = List.generate(draws.length, (i) => i);
    while (remaining.isNotEmpty) {
      final index = remaining.firstWhere(
        (i) => incoming[i] == 0,
        orElse: () => remaining.first,
      );
      remaining.remove(index);
      draws[index].draw();
      for (final next in edges[index]) {
        incoming[next]--;
      }
    }
    if (session.phase != PlayPhase.buildingTransition) {
      for (final place
          in session.world.perception
              ? session.world.places
              : [if (session.world.nearby != null) session.world.nearby!]) {
        _placeLabel(c, place);
      }
    }
    if (session.world.perception) {
      final center = iso(player.x, player.y);
      c.drawOval(
        Rect.fromCenter(center: center, width: 290, height: 145),
        Paint()
          ..color = const Color(0x554bd1c0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    c.restore();
    final night = session.world.atmosphere.nightBlend;
    c.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _paint(Color.fromRGBO(7, 12, 31, night * .30)),
    );
    if (!_lowQuality &&
        session.campaign.floor == 0 &&
        !session.world.inResidence)
      _rain(c);
    if (_lowQuality) return;
    final vignette = ui.Gradient.radial(
      Offset(size.x * .5, size.y * .5),
      size.x * .65,
      [const Color(0x00102029), const Color(0x85102029)],
      [.35, 1],
    );
    c.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), Paint()..shader = vignette);
  }

  void _drawPath(Canvas c) {
    if (session.world.path.isEmpty) return;
    for (var i = 0; i < session.world.path.length; i += 2) {
      final point = session.world.path[i];
      c.drawOval(
        Rect.fromCenter(center: iso(point.dx, point.dy), width: 5, height: 3),
        _paint(const Color(0x6595c4b5)),
      );
    }
    final last = session.world.path.last;
    c.drawOval(
      Rect.fromCenter(center: iso(last.dx, last.dy), width: 23, height: 11),
      Paint()
        ..color = const Color(0xaa95c4b5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _building(Canvas c, Block block) {
    if (block.style == 6) {
      final a = iso(block.bounds.left, block.bounds.bottom);
      final b = iso(block.bounds.right, block.bounds.bottom);
      c.drawPath(
        _poly([a, b, b - Offset(0, block.height), a - Offset(0, block.height)]),
        _paint(const Color(0xff766b60)),
      );
      c.drawLine(
        a - Offset(0, block.height),
        b - Offset(0, block.height),
        _paint(const Color(0xffb8a58c))..strokeWidth = 4,
      );
      return;
    }
    if (block.style == 5) {
      _residentialExterior(c);
      return;
    }
    if (block.floor > 0 && block.style != 3) {
      _building(c, Block(block.bounds, block.name, 0, 55));
      return;
    }
    if (block.interior) {
      _room(c, block);
      return;
    }
    final b = block.bounds;
    final base = [
      iso(b.left, b.top),
      iso(b.right, b.top),
      iso(b.right, b.bottom),
      iso(b.left, b.bottom),
    ];
    final roof = base.map((p) => p - Offset(0, block.height)).toList();
    final behind =
        session.campaign.y < b.top &&
        session.campaign.y > b.top - 4 &&
        session.campaign.x > b.left - 2 &&
        session.campaign.x < b.right + 2;
    final alpha = behind ? .5 : 1.0;
    Color fade(Color color) => color.withValues(alpha: alpha);
    c.drawPath(
      _poly(base.map((p) => p + const Offset(14, 10)).toList()),
      _paint(const Color(0x49202c2c)),
    );
    c.drawPath(
      _poly([base[3], base[2], roof[2], roof[3]]),
      _paint(fade(const Color(0xff23383f))),
    );
    c.drawPath(
      _poly([base[1], base[2], roof[2], roof[1]]),
      _paint(fade(const Color(0xff334b50))),
    );
    c.drawPath(
      _poly(roof),
      _paint(
        fade(
          block.style == 1 ? const Color(0xff49615d) : const Color(0xff344e51),
        ),
      ),
    );
    c.drawPath(
      _poly(roof),
      Paint()
        ..color = fade(const Color(0xff6b7a70))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    for (var floor = 0; floor < (block.height / 32).floor(); floor++) {
      final up = 18.0 + floor * 30;
      for (var j = 1; j < 6; j++) {
        final p = Offset.lerp(base[3], base[2], j / 6)! - Offset(0, up);
        c.drawPath(
          _poly([
            p,
            p + const Offset(12, 6),
            p + const Offset(12, -6),
            p + const Offset(0, -12),
          ]),
          _paint(
            fade(
              (j + floor) % 4 == 0
                  ? const Color(0xffab9266)
                  : const Color(0xff142d36),
            ),
          ),
        );
      }
    }
    for (var j = 1; j < 5; j++) {
      final p = Offset.lerp(base[1], base[2], j / 5)! - const Offset(0, 34);
      c.drawPath(
        _poly([
          p,
          p + const Offset(-13, 6),
          p + const Offset(-13, -10),
          p + const Offset(0, -16),
        ]),
        _paint(
          fade(j.isEven ? const Color(0xff517477) : const Color(0xffbaa478)),
        ),
      );
    }
    // Roof equipment and parapet retain the same perspective as the footprint.
    final top = Offset.lerp(roof[0], roof[2], .5)!;
    c.drawPath(
      _poly([
        top + const Offset(-14, -8),
        top + const Offset(18, 7),
        top + const Offset(18, -8),
        top + const Offset(-14, -23),
      ]),
      _paint(fade(const Color(0xff22393f))),
    );
    c.drawLine(
      top + const Offset(-14, -23),
      top + const Offset(18, -8),
      _paint(fade(const Color(0xff738278)))..strokeWidth = 2,
    );
    if (block.style == 1) {
      final awning = [
        base[3] - const Offset(0, 33),
        base[2] - const Offset(0, 33),
        base[2] + const Offset(0, -24),
        base[3] + const Offset(0, -24),
      ];
      c.drawPath(_poly(awning), _paint(fade(const Color(0xff57867a))));
      for (var j = 0; j < 10; j++) {
        final a = Offset.lerp(awning[0], awning[1], j / 10)!;
        final d = Offset.lerp(awning[3], awning[2], j / 10)!;
        c.drawLine(
          a,
          d,
          _paint(fade(const Color(0xffa9b39a)))..strokeWidth = 3,
        );
      }
    }
  }

  void _drawTower(Canvas c) {
    final p = iso(52, 18);
    final path = Path()
      ..moveTo(p.dx - 17, p.dy)
      ..lineTo(p.dx, p.dy - 240)
      ..lineTo(p.dx + 17, p.dy);
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xff5b6d68)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    for (var i = 0; i < 6; i++) {
      final y = i * 34.0;
      final w = 17 * (1 - y / 240);
      c.drawLine(
        p + Offset(-w, -y),
        p + Offset(w * .8, -y - 31),
        _paint(const Color(0xff3e595a))..strokeWidth = 2,
      );
    }
    final glow = session.reducedEffects
        ? .7
        : .6 + math.sin(session.elapsed * 2) * .25;
    c.drawCircle(
      p - const Offset(0, 240),
      22,
      Paint()
        ..shader = ui.Gradient.radial(p - const Offset(0, 240), 22, [
          Color.fromRGBO(220, 133, 88, glow),
          const Color(0x00d88b60),
        ]),
    );
    c.drawCircle(p - const Offset(0, 240), 3, _paint(const Color(0xffe0a16f)));
  }

  void _lamp(Canvas c, double x, double y) {
    final p = iso(x, y);
    final night = session.world.atmosphere.nightBlend;
    if (night > .03 && !_lowQuality)
      c.drawOval(
        Rect.fromCenter(
          center: p + const Offset(18, -2),
          width: 120,
          height: 54,
        ),
        Paint()
          ..shader = ui.Gradient.radial(p + const Offset(18, -2), 65, [
            Color.fromRGBO(220, 190, 115, night * .45),
            const Color(0x00b6a371),
          ]),
      );
    c.drawLine(
      p,
      p - const Offset(0, 83),
      _paint(const Color(0xff182f38))..strokeWidth = 4,
    );
    c.drawLine(
      p - const Offset(0, 83),
      p + const Offset(17, -77),
      _paint(const Color(0xff426166))..strokeWidth = 3,
    );
    c.drawRect(
      Rect.fromLTWH(p.dx + 13, p.dy - 79, 12, 4),
      _paint(
        Color.lerp(const Color(0xff697879), const Color(0xffffdb8e), night)!,
      ),
    );
  }

  bool _onScreen(Rect footprint) {
    final points = [
      iso(footprint.left, footprint.top),
      iso(footprint.right, footprint.top),
      iso(footprint.left, footprint.bottom),
      iso(footprint.right, footprint.bottom),
    ];
    final screen = Rect.fromLTRB(
      _cameraX - size.x / zoom / 2 - 180,
      _cameraY - size.y / zoom / 2 - 180,
      _cameraX + size.x / zoom / 2 + 180,
      _cameraY + size.y / zoom / 2 + 240,
    );
    return Rect.fromLTRB(
      points.map((p) => p.dx).reduce(math.min),
      points.map((p) => p.dy).reduce(math.min),
      points.map((p) => p.dx).reduce(math.max),
      points.map((p) => p.dy).reduce(math.max),
    ).overlaps(screen);
  }

  void _upperLanding(Canvas c) {
    final floor = session.campaign.floor;
    final a = iso(2, 16), b = iso(24, 16);
    c.drawPath(
      _poly([a, b, b + const Offset(0, 28), a + const Offset(0, 28)]),
      _paint(const Color(0xff263b40)),
    );
    if (floor > 0) {
      for (var x = 2.0; x <= 24; x += .65) {
        final p = iso(x, 15.95);
        c.drawLine(
          p,
          p - const Offset(0, 30),
          _paint(const Color(0xff758985))..strokeWidth = 2,
        );
      }
      c.drawLine(
        a - const Offset(0, 30),
        b - const Offset(0, 30),
        _paint(teal)..strokeWidth = 3,
      );
    }
    for (final x in [12.5, 18.5, 23.0]) {
      final p = iso(x, 10.45);
      c.drawCircle(
        p - const Offset(0, 37),
        27,
        Paint()
          ..shader = ui.Gradient.radial(p - const Offset(0, 37), 27, [
            const Color(0x55ffd899),
            const Color(0x00ffd899),
          ]),
      );
      c.drawCircle(p - const Offset(0, 37), 3, _paint(amber));
      c.drawOval(
        Rect.fromCenter(center: p, width: 16, height: 8),
        _paint(const Color(0xff66503e)),
      );
      c.drawCircle(p - const Offset(0, 9), 9, _paint(const Color(0xff4e7350)));
    }
    final board = iso(18.5, 12);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: board - const Offset(0, 27),
          width: 24,
          height: 30,
        ),
        const Radius.circular(2),
      ),
      _paint(const Color(0xff816e53)),
    );
    c.drawRect(
      Rect.fromCenter(
        center: board - const Offset(0, 27),
        width: 17,
        height: 20,
      ),
      _paint(const Color(0xffd0c5a4)),
    );
  }

  void _structuralWall(Canvas c, Rect wall) {
    if (!_onScreen(wall)) return;
    final horizontal = wall.width > wall.height;
    final a = iso(wall.left, wall.top),
        b = horizontal
            ? iso(wall.right, wall.top)
            : iso(wall.left, wall.bottom);
    final player = Offset(session.campaign.x, session.campaign.y);
    final front = horizontal
        ? player.dy < wall.center.dy
        : player.dx < wall.center.dx;
    final inside =
        (session.campaign.floor > 0 &&
            session.campaign.y < 10 &&
            session.campaign.x < 12) ||
        (session.campaign.floor == 0 && session.world.inResidence);
    final bathroom = ResidentialLayout.bathroom.contains(player);
    final occludes = front && (inside || bathroom);
    final height =
        session.campaign.floor > 0 && horizontal && wall.center.dy > 15
        ? 12.0
        : occludes
        ? 20.0
        : 58.0;
    c.drawPath(
      _poly([a, b, b - Offset(0, height), a - Offset(0, height)]),
      _paint(
        (horizontal ? const Color(0xff817568) : const Color(0xff685f56))
            .withValues(alpha: occludes ? .42 : 1),
      ),
    );
    c.drawLine(
      a - Offset(0, height),
      b - Offset(0, height),
      _paint(const Color(0xffb1a38b))..strokeWidth = 3,
    );
    if (session.campaign.floor > 0 &&
        horizontal &&
        (wall.center.dy - 10).abs() < .3 &&
        height > 40) {
      for (final opening in ResidentialLayout.frontWindows.where(
        (p) => p.dx > wall.left && p.dx < wall.right,
      )) {
        _frontWindow(c, iso(opening.dx, opening.dy) - const Offset(0, 20));
      }
    }
    if (session.campaign.floor == 2 &&
        !horizontal &&
        wall.left < 2.1 &&
        wall.top == 2) {
      final wa = iso(2.02, 4) - const Offset(0, 18),
          wb = iso(2.02, 6.5) - const Offset(0, 18);
      c.drawPath(
        _poly([wa, wb, wb - const Offset(0, 32), wa - const Offset(0, 32)]),
        _paint(const Color(0xffdec390)),
      );
      for (var i = 1; i < 6; i++) {
        final off = Offset(0, i * 5.0);
        c.drawLine(
          wa - off,
          wb - off,
          _paint(const Color(0xff9e7c53))..strokeWidth = 1.5,
        );
      }
    }
  }

  void _frontWindow(Canvas c, Offset p) {
    c.drawPath(
      _poly([
        p + const Offset(-10, -5),
        p + const Offset(10, 5),
        p + const Offset(10, -18),
        p + const Offset(-10, -28),
      ]),
      _paint(const Color(0xffb6a078)),
    );
    c.drawLine(
      p + const Offset(-7, -6),
      p + const Offset(7, 1),
      _paint(const Color(0xff314b53))..strokeWidth = 6,
    );
    c.drawLine(
      p + const Offset(-7, -17),
      p + const Offset(7, -10),
      _paint(const Color(0xffe0bd79))..strokeWidth = 6,
    );
  }

  void _residentialExterior(Canvas c) {
    final inside = ResidentialLayout.corridor.contains(
      Offset(session.campaign.x, session.campaign.y),
    );
    if (inside) {
      _building(
        c,
        const Block(Rect.fromLTRB(2, 2, 24, 10), 'RESIDENCIAL · HALL', 0, 64),
      );
      return; // the same footprint's roof and upper floors are cut away in the hall
    }
    final b = const Rect.fromLTRB(2, 2, 24, 10);
    final left = iso(b.left, b.bottom),
        right = iso(b.right, b.bottom),
        back = iso(b.right, b.top),
        far = iso(b.left, b.top);
    const h = 196.0;
    c.drawPath(
      _poly([
        left,
        right,
        right - const Offset(0, h),
        left - const Offset(0, h),
      ]),
      _paint(const Color(0xff53605e)),
    );
    c.drawPath(
      _poly([
        right,
        back,
        back - const Offset(0, h),
        right - const Offset(0, h),
      ]),
      _paint(const Color(0xff3d4d50)),
    );
    c.drawPath(
      _poly([
        left - const Offset(0, h),
        right - const Offset(0, h),
        back - const Offset(0, h),
        far - const Offset(0, h),
      ]),
      _paint(const Color(0xff33454a)),
    );
    for (final floor in [1, 2]) {
      final rise = floor * 62.0;
      final ca = iso(2, 10) - Offset(0, rise),
          cb = iso(24, 10) - Offset(0, rise),
          cc = iso(24, 16) - Offset(0, rise),
          cd = iso(2, 16) - Offset(0, rise);
      c.drawPath(_poly([ca, cb, cc, cd]), _paint(const Color(0xff596c6a)));

      c.drawLine(
        left - Offset(0, rise),
        right - Offset(0, rise),
        _paint(const Color(0xff8a9790))..strokeWidth = 5,
      );
      for (final d in ResidentialLayout.doors.where(
        (d) => d.floor == floor && d.locked || d.id == '203' && floor == 2,
      )) {
        final p = iso(d.center.dx, d.center.dy) - Offset(0, rise);
        c.drawPath(
          _poly([
            p + const Offset(-10, -4),
            p + const Offset(10, 6),
            p + const Offset(10, -36),
            p + const Offset(-10, -46),
          ]),
          _paint(const Color(0xff564638)),
        );
        _text(c, d.id, p - const Offset(0, 24), fontSize: 8, color: amber);
      }
      for (final opening in ResidentialLayout.frontWindows) {
        _frontWindow(c, iso(opening.dx, opening.dy) - Offset(0, rise + 20));
      }
      for (var x = 2.0; x <= 24; x += 1) {
        final p = iso(x, 16) - Offset(0, rise);
        c.drawLine(
          p,
          p - const Offset(0, 22),
          _paint(const Color(0xffa0a594))..strokeWidth = 1.5,
        );
      }
      c.drawLine(
        iso(2, 16) - Offset(0, rise + 22),
        iso(24, 16) - Offset(0, rise + 22),
        _paint(teal)..strokeWidth = 2,
      );
    }
    final entrance = iso(7, 16);
    c.drawPath(
      _poly([
        entrance + const Offset(-17, -8),
        entrance + const Offset(17, 8),
        entrance + const Offset(17, -43),
        entrance + const Offset(-17, -59),
      ]),
      _paint(const Color(0xff273a3c)),
    );
    final roof = iso(17, 7) - const Offset(0, h);
    c.drawOval(
      Rect.fromCenter(center: roof, width: 38, height: 18),
      _paint(const Color(0xff1c3947)),
    );
    c.drawRect(
      Rect.fromLTWH(roof.dx - 19, roof.dy - 20, 38, 20),
      _paint(const Color(0xff244854)),
    );
    c.drawOval(
      Rect.fromCenter(
        center: roof - const Offset(0, 20),
        width: 38,
        height: 18,
      ),
      _paint(const Color(0xff40616a)),
    );
    c.drawLine(
      roof + const Offset(60, -10),
      roof + const Offset(60, -55),
      _paint(teal)..strokeWidth = 2,
    );
    c.drawLine(
      roof + const Offset(40, -42),
      roof + const Offset(80, -42),
      _paint(teal)..strokeWidth = 2,
    );
  }

  void _apartmentDoor(Canvas c, [String id = '203']) {
    final door = ResidentialLayout.door(id);
    final x = door.center.dx - .9, y = door.center.dy;
    const width = 1.8, height = 58.0;
    final transition = session.buildingTransition;
    final angle =
        (transition?.doorId == id && transition!.isDoor
            ? transition.doorAngle
            : session.world.doorIsOpen(id)
            ? 1.0
            : 0.0) *
        math.pi /
        2;
    final a = iso(x, y), b = iso(x + width, y);
    c.drawLine(
      a,
      a - const Offset(0, height + 5),
      _paint(const Color(0xffba9b70))..strokeWidth = 5,
    );
    c.drawLine(
      b,
      b - const Offset(0, height + 5),
      _paint(const Color(0xffba9b70))..strokeWidth = 5,
    );
    c.drawLine(
      a - const Offset(0, height + 5),
      b - const Offset(0, height + 5),
      _paint(const Color(0xffba9b70))..strokeWidth = 5,
    );
    final q = iso(x + math.cos(angle) * width, y - math.sin(angle) * width);
    c.drawPath(
      _poly([a, q, q - const Offset(0, height), a - const Offset(0, height)]),
      _paint(const Color(0xff715037)),
    );
    for (var i = 1; i < 5; i++) {
      final p = Offset.lerp(a, q, i / 5)!;
      c.drawLine(
        p - const Offset(0, 3),
        p - const Offset(0, height - 3),
        _paint(const Color(0xff8d6543))..strokeWidth = 1,
      );
    }
    final handle = Offset.lerp(a, q, .82)! - const Offset(0, 29);
    c.drawCircle(handle, 2.2, _paint(const Color(0xffe4bf77)));
    _text(
      c,
      id == 'entrada'
          ? 'ENTRADA'
          : id == 'banheiro'
          ? 'WC'
          : id,
      Offset.lerp(a, q, .5)! - const Offset(0, 45),
      fontSize: 10,
      color: amber,
      backing: true,
    );
  }

  void _staircase(Canvas c, Offset position, bool ascending) {
    for (var i = 7; i >= 0; i--) {
      final y = position.dy + i * .22,
          drop = ascending ? -(7 - i) * 5.0 : i * 5.0;
      final a = iso(position.dx - .7, y) + Offset(0, drop),
          b = iso(position.dx + .7, y) + Offset(0, drop);
      final d = iso(position.dx + .7, y + .22) + Offset(0, drop),
          e = iso(position.dx - .7, y + .22) + Offset(0, drop);
      c.drawPath(
        _poly([a, b, d, e]),
        _paint(i.isEven ? const Color(0xff77817c) : const Color(0xff606f6d)),
      );
      c.drawLine(e, d, _paint(const Color(0xffadb1a0))..strokeWidth = 1);
    }
    final a = iso(position.dx + .8, position.dy) - const Offset(0, 35),
        b =
            iso(position.dx + .8, position.dy + 1.8) +
            Offset(0, ascending ? -35 : 0);
    c.drawLine(a, b, _paint(const Color(0xffb3aa91))..strokeWidth = 3);
  }

  void _elevator(Canvas c) {
    final p = iso(3.3, 13.8);
    final frame = Rect.fromLTWH(p.dx - 25, p.dy - 72, 50, 72);
    c.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(3)),
      _paint(const Color(0xff273b43)),
    );
    c.drawRect(frame.deflate(5), _paint(const Color(0xff77817e)));
    c.drawLine(
      p - const Offset(0, 67),
      p - const Offset(0, 4),
      _paint(ink)..strokeWidth = 2,
    );
    _text(
      c,
      'MANUTENÇÃO',
      p - const Offset(0, 34),
      fontSize: 7,
      color: amber,
      backing: true,
    );
    _text(c, '2', p - const Offset(0, 82), fontSize: 12, color: amber);
  }

  void _room(Canvas c, Block block) {
    final b = block.bounds;
    final a = iso(b.left, b.top), d = iso(b.right, b.top);
    final h = block.height;
    for (var i = 1; block.style != 4 && i < 4; i++) {
      final w = Offset.lerp(a, d, i / 4)! - Offset(0, h * .6);
      final frame = Rect.fromCenter(center: w, width: 20, height: 25);
      c.drawRect(
        frame,
        _paint(
          block.style == 3 ? const Color(0xff44382c) : const Color(0xff8eaaa1),
        ),
      );
      if (block.style == 3) {
        c.drawRect(frame.deflate(3), _paint(const Color(0xff2b4343)));
        c.drawLine(
          w + const Offset(-6, 4),
          w + const Offset(0, -5),
          _paint(const Color(0xffb5a481))..strokeWidth = 1.5,
        );
        c.drawLine(
          w + const Offset(0, -5),
          w + const Offset(6, 4),
          _paint(const Color(0xff81977f))..strokeWidth = 1.5,
        );
      }
    }
    if (block.style == 3) {
      final a = iso(2.02, 4), b = iso(2.02, 6.5);
      final window = [
        a - const Offset(0, 18),
        b - const Offset(0, 18),
        b - const Offset(0, 50),
        a - const Offset(0, 50),
      ];
      c.drawPath(_poly(window), _paint(const Color(0xffdec390)));
      c.drawPath(
        _poly(window),
        Paint()
          ..color = const Color(0xffad9070)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      for (var i = 1; i < 5; i++) {
        final p = Offset.lerp(window[0], window[3], i / 5)!;
        final q = Offset.lerp(window[1], window[2], i / 5)!;
        c.drawLine(p, q, _paint(const Color(0xff9e7c53))..strokeWidth = 1);
      }
      final beam = [iso(2.3, 4), iso(2.3, 6.5), iso(6.5, 6.5), iso(6.5, 4)];
      c.drawPath(_poly(beam), Paint()..color = const Color(0x28edba71));
      final rug = [iso(5.2, 6), iso(7.9, 6), iso(7.9, 7.7), iso(5.2, 7.7)];
      c.drawPath(_poly(rug), _paint(const Color(0xff776b55)));
      c.drawPath(
        _poly(rug),
        Paint()
          ..color = const Color(0xffc2ab78)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    if (block.style == 3) {
      final p = iso(6.5, 4);

      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: p - const Offset(0, 21),
            width: 7,
            height: 12,
          ),
          const Radius.circular(1),
        ),
        _paint(teal),
      );
    }
  }

  void _furniture(Canvas c, Furnishing furniture) {
    final b = furniture.bounds, h = furniture.height, kind = furniture.kind;
    final source = _furnitureSources[kind];
    if (session.campaign.floor == 2 && source != null) {
      final image = _sprites['apartment_furniture']!;
      final width = (b.width + b.height) * 32 * 1.18;
      final height = width * source.height / source.width;
      final center = iso(b.center.dx, b.center.dy);
      final bottom = iso(b.right, b.bottom).dy;
      c.drawOval(
        Rect.fromCenter(
          center: center + const Offset(0, 5),
          width: width * .75,
          height: 22,
        ),
        _paint(const Color(0x45201913)),
      );
      final destination = Rect.fromLTWH(
        center.dx - width / 2,
        bottom - height,
        width,
        height,
      );
      final actor =
          iso(session.campaign.x, session.campaign.y) - const Offset(0, 35);
      final occludes =
          destination.contains(actor) &&
          session.campaign.x + session.campaign.y < b.right + b.bottom;
      c.drawImageRect(
        image,
        source,
        destination,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Color.fromRGBO(255, 255, 255, occludes ? .45 : 1),
      );
      if (session.phase == PlayPhase.objectPanel &&
          ((kind == 'wardrobe' && session.objectKind == PointKind.wardrobe) ||
              (kind == 'desk' && session.objectKind == PointKind.notebook))) {
        c.drawPath(
          _poly([
            center,
            center + const Offset(25, 12),
            center + const Offset(25, -22),
            center - const Offset(0, 34),
          ]),
          _paint(const Color(0xff332e27)),
        );
        c.drawLine(
          center - const Offset(0, 34),
          center + const Offset(25, -22),
          _paint(amber)..strokeWidth = 2,
        );
      }
      return;
    }
    if (kind == 'toilet' || kind == 'basin' || kind == 'shower') {
      final p = iso(b.center.dx, b.center.dy);
      if (kind == 'shower') {
        final corners = [
          iso(b.left, b.top),
          iso(b.right, b.top),
          iso(b.right, b.bottom),
          iso(b.left, b.bottom),
        ];
        c.drawPath(_poly(corners), _paint(const Color(0xffc3c9bf)));
        c.drawPath(
          _poly([
            corners[0],
            corners[1],
            corners[1] - Offset(0, h),
            corners[0] - Offset(0, h),
          ]),
          _paint(const Color(0x5590b5bb)),
        );
        c.drawLine(
          corners[0] - Offset(0, h),
          corners[1] - Offset(0, h),
          _paint(teal)..strokeWidth = 2,
        );
        c.drawLine(
          p - Offset(0, h),
          p - Offset(-10, h - 4),
          _paint(teal)..strokeWidth = 3,
        );
        c.drawOval(
          Rect.fromCenter(center: p - Offset(-10, h - 6), width: 12, height: 5),
          _paint(const Color(0xffc8cebf)),
        );
      } else {
        final bowl = p - Offset(0, kind == 'toilet' ? 10 : 20);
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: p - const Offset(0, 5),
              width: 12,
              height: 17,
            ),
            const Radius.circular(5),
          ),
          _paint(const Color(0xffbfc9bd)),
        );
        c.drawOval(
          Rect.fromCenter(center: bowl, width: 27, height: 16),
          _paint(const Color(0xffe4e6d9)),
        );
        c.drawOval(
          Rect.fromCenter(center: bowl, width: 16, height: 8),
          _paint(const Color(0xff718d94)),
        );
        if (kind == 'basin') {
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: p - const Offset(0, 49),
                width: 23,
                height: 27,
              ),
              const Radius.circular(3),
            ),
            _paint(const Color(0xff89a7b1)),
          );
          c.drawLine(
            bowl - const Offset(0, 4),
            bowl - const Offset(0, 12),
            _paint(teal)..strokeWidth = 3,
          );
        } else {
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: bowl + const Offset(9, -12),
                width: 14,
                height: 19,
              ),
              const Radius.circular(3),
            ),
            _paint(const Color(0xffd0d6c7)),
          );
        }
      }
      return;
    }
    final top = [
      iso(b.left, b.top),
      iso(b.right, b.top),
      iso(b.right, b.bottom),
      iso(b.left, b.bottom),
    ];
    final color = kind == 'bed'
        ? const Color(0xffa1a48b)
        : kind == 'fridge'
        ? const Color(0xffa5b2aa)
        : kind == 'sofa'
        ? const Color(0xff4e7975)
        : kind == 'shelf'
        ? const Color(0xff867c64)
        : const Color(0xff8d8b74);
    c.drawPath(
      _poly([top[3], top[2], top[2] - Offset(0, h), top[3] - Offset(0, h)]),
      _paint(Color.lerp(color, ink, .45)!),
    );
    c.drawPath(
      _poly([top[1], top[2], top[2] - Offset(0, h), top[1] - Offset(0, h)]),
      _paint(Color.lerp(color, ink, .25)!),
    );
    c.drawPath(_poly(top.map((p) => p - Offset(0, h)).toList()), _paint(color));
    if (kind == 'bed') {
      c.drawLine(
        top[0] - Offset(0, h),
        top[1] - Offset(0, h),
        _paint(const Color(0xffdedbc5))..strokeWidth = 10,
      );
      c.drawLine(
        Offset.lerp(top[0], top[3], .7)! - Offset(0, h),
        Offset.lerp(top[1], top[2], .7)! - Offset(0, h),
        _paint(const Color(0xff567b78))..strokeWidth = 14,
      );
    } else if (kind == 'shelf') {
      for (var level = 1; level < 4; level++) {
        final a = top[3] - Offset(0, level * h / 4),
            z = top[2] - Offset(0, level * h / 4);
        c.drawLine(a, z, _paint(const Color(0xffc4b58a))..strokeWidth = 2);
        for (var i = 1; i < 5; i++) {
          final p = Offset.lerp(a, z, i / 5)!;
          c.drawLine(
            p,
            p - const Offset(0, 7),
            _paint(i.isEven ? teal : amber)..strokeWidth = 4,
          );
        }
      }
    } else if (kind == 'sofa') {
      c.drawLine(
        top[0] - Offset(0, h + 9),
        top[1] - Offset(0, h + 9),
        _paint(const Color(0xff668d82))..strokeWidth = 12,
      );
      c.drawLine(
        top[3] - Offset(0, h),
        top[0] - Offset(0, h + 4),
        _paint(const Color(0xff395b57))..strokeWidth = 6,
      );
    } else if (kind == 'coffee') {
      final p = iso(b.center.dx, b.center.dy) - Offset(0, h);
      c.drawRect(
        Rect.fromCenter(center: p, width: 13, height: 8),
        _paint(const Color(0xffd0bf94)),
      );
    } else if (kind == 'fridge') {
      final p = Offset.lerp(top[2], top[3], .7)!;
      c.drawLine(
        p - Offset(0, h * .65),
        p - Offset(0, h * .4),
        _paint(ink)..strokeWidth = 2,
      );
      c.drawLine(
        top[2] - Offset(0, h * .6),
        top[3] - Offset(0, h * .6),
        _paint(const Color(0xff718e85))..strokeWidth = 1,
      );
      if (session.objectKind == PointKind.refrigerator &&
          session.phase == PlayPhase.objectPanel) {
        final p = top[3];
        c.drawPath(
          _poly([
            p,
            p + const Offset(-25, 8),
            p + Offset(-25, 8 - h),
            p - Offset(0, h),
          ]),
          _paint(const Color(0xffd5d8c8)),
        );
      }
    } else if (kind == 'kitchen') {
      final p = iso(b.center.dx, b.center.dy) - Offset(0, h);
      c.drawOval(Rect.fromCenter(center: p, width: 21, height: 9), _paint(ink));
      c.drawArc(
        Rect.fromCenter(center: p - const Offset(0, 7), width: 10, height: 12),
        math.pi,
        math.pi,
        false,
        _paint(teal)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else if (kind == 'bench') {
      for (var i = 1; i < 4; i++) {
        c.drawLine(
          Offset.lerp(top[0], top[3], i / 4)! - Offset(0, h),
          Offset.lerp(top[1], top[2], i / 4)! - Offset(0, h),
          _paint(const Color(0xff544a40))..strokeWidth = 1,
        );
      }
    }
  }

  void _vehicle(Canvas c, Vehicle vehicle) {
    final open =
        vehicle.id == 'sedan' && session.campaign.has('loot') ||
        vehicle.id == 'bus' && session.phase == PlayPhase.transit;
    final image =
        _sprites['vehicle_${vehicle.id}_${open ? 'open' : 'closed'}']!;
    final offset = vehicle.id == 'bus' && session.phase == PlayPhase.transit
        ? Offset(session.sceneTime * 8, session.sceneTime * 4)
        : Offset.zero;
    final p = iso(vehicle.position.dx, vehicle.position.dy) + offset;
    final w = vehicle.width, h = w * image.height / image.width;
    c.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(p.dx - w / 2, p.dy - h * .96, w, h),
      Paint()..filterQuality = FilterQuality.low,
    );
    if (vehicle.id == 'bus' && session.phase == PlayPhase.transit) {
      _text(
        c,
        'CAIO · EMBARCADO',
        p - Offset(0, h + 5),
        fontSize: 9,
        color: amber,
      );
    }
  }

  void _place(Canvas c, Place place) {
    final p = iso(place.x, place.y);
    switch (place.kind) {
      case PointKind.apartmentDoor:
        _apartmentDoor(c);
      case PointKind.buildingDoor:
        _apartmentDoor(c, place.id!);
      case PointKind.stairsDown:
        _staircase(c, Offset(place.x, place.y - .5), false);
      case PointKind.stairsUp:
        _staircase(c, Offset(place.x, place.y - .5), true);
      case PointKind.elevator:
        _elevator(c);

      case PointKind.television:
        _prop(c, 3, p, 48);
      case PointKind.panel:
        _prop(c, 2, p, 32);
      case PointKind.adapter:
      case PointKind.key:
      case PointKind.water:
        final name = place.kind == PointKind.adapter
            ? 'adapter'
            : place.kind == PointKind.key
            ? 'key'
            : 'water';
        final image = _sprites['item_$name'];
        if (image != null) {
          c.drawImageRect(
            image,
            Rect.fromLTWH(
              0,
              0,
              image.width.toDouble(),
              image.height.toDouble(),
            ),
            Rect.fromLTWH(p.dx - 14, p.dy - 24, 28, 28),
            Paint(),
          );
        } else {
          c.drawCircle(p - const Offset(0, 8), 5, _paint(amber));
        }
      case PointKind.gate:
        final a = iso(40.9, 24), b = iso(40.9, 27.8);
        if (session.world.gateClosed) {
          for (var i = 0; i <= 7; i++) {
            final q = Offset.lerp(a, b, i / 7)!;
            c.drawLine(
              q,
              q - const Offset(0, 38),
              _paint(const Color(0xff88938b))..strokeWidth = 2,
            );
          }
          c.drawLine(
            a - const Offset(0, 28),
            b - const Offset(0, 28),
            _paint(teal)..strokeWidth = 3,
          );
        }
      case PointKind.ladder:
        final a = iso(place.x, place.y);
        for (final side in [-7.0, 7.0])
          c.drawLine(
            a + Offset(side, 0),
            a + Offset(side, -60),
            _paint(teal)..strokeWidth = 3,
          );
        for (var i = 0; i < 8; i++)
          c.drawLine(
            a + Offset(-7, -i * 8.0),
            a + Offset(7, -i * 8.0),
            _paint(amber)..strokeWidth = 2,
          );
      case PointKind.dog:
      case PointKind.cat:
      case PointKind.pigeon:
        final animal = place.kind == PointKind.dog
            ? session.world.animals.dog
            : place.kind == PointKind.cat
            ? session.world.animals.cat
            : session.world.animals.pigeon;
        _animal(c, animal);
      default:
        break;
    }
  }

  void _animal(Canvas c, AnimalActor animal) {
    final ground = iso(animal.position.dx, animal.position.dy);
    final p = ground - Offset(0, animal.elevation);
    final flight = animal.state == AnimalState.fly;
    c.drawOval(
      Rect.fromCenter(center: ground, width: flight ? 14 : 24, height: 7),
      _paint(const Color(0xff152021).withValues(alpha: flight ? .15 : .25)),
    );
    if (animal.nocturnal) {
      // Original vector silhouette: articulated wings around a fixed body pivot.
      final flap = math.sin(animal.stateTime * 15) * 6;
      c.save();
      c.translate(p.dx, p.dy - (flight ? 8 : 13));
      final wings = Path()
        ..moveTo(-2, -2)
        ..lineTo(-18, -7 - flap)
        ..lineTo(-12, 2)
        ..lineTo(-7, 0)
        ..lineTo(-3, 5)
        ..lineTo(0, 2)
        ..lineTo(3, 5)
        ..lineTo(7, 0)
        ..lineTo(12, 2)
        ..lineTo(18, -7 - flap)
        ..lineTo(2, -2)
        ..close();
      c.drawPath(wings, _paint(const Color(0xff353043)));
      c.drawOval(const Rect.fromLTWH(-3, -5, 6, 10), _paint(ink));
      c.drawPath(
        Path()
          ..moveTo(-3, -3)
          ..lineTo(-3, -8)
          ..lineTo(0, -5)
          ..lineTo(3, -8)
          ..lineTo(3, -3)
          ..close(),
        _paint(ink),
      );
      c.restore();
      return;
    }
    final name = animal.kind == AnimalKind.cat
        ? 'breu'
        : animal.kind == AnimalKind.dog
        ? 'fuba'
        : 'pingo';
    final pose = animal.sleeping
        ? (animal.kind == AnimalKind.cat ? 0 : 2)
        : animal.state == AnimalState.climb
        ? 1
        : animal.state == AnimalState.mark
        ? 3
        : null;
    c.save();
    c.translate(p.dx, p.dy);
    // Existing originals face right. Reflect around the feet, never the texture edge.
    final screenFacing = animal.facing.dx - animal.facing.dy;
    if (screenFacing < 0) c.scale(-1, 1);
    if (pose != null && animal.kind != AnimalKind.pigeon) {
      final image = _sprites['animal_life_poses']!;
      const crops = [
        Rect.fromLTWH(115, 349, 344, 222),
        Rect.fromLTWH(622, 140, 464, 431),
        Rect.fromLTWH(1086, 284, 456, 277),
        Rect.fromLTWH(1653, 140, 468, 476),
      ];
      final source = crops[pose];
      final width = animal.kind == AnimalKind.cat
          ? (pose == 1 ? 20.0 : 24.0)
          : (pose == 2 ? 35.0 : 34.0);
      final height = width * source.height / source.width;
      final breathing = animal.sleeping ? animal.breath * .65 : 0.0;
      c.drawImageRect(
        image,
        source,
        Rect.fromLTWH(
          -width / 2,
          -height - breathing,
          width,
          height + breathing,
        ),
        Paint()..filterQuality = FilterQuality.low,
      );
    } else {
      final frame = animal.moving
          ? animal.walkFrame
          : flight
          ? animal.flightFrame
          : 0;
      final image = _sprites['animal_${name}_$frame']!;
      final sniff = animal.state == AnimalState.sniff
          ? math.sin(animal.stateTime * 5) * .035
          : 0.0;
      c.rotate(sniff);
      c.drawImageRect(
        image,
        const Rect.fromLTWH(0, 0, 96, 96),
        const Rect.fromLTWH(-25, -46, 50, 50),
        Paint()..filterQuality = FilterQuality.low,
      );
    }
    c.restore();
  }

  void _placeLabel(Canvas c, Place place) {
    final nearest = session.world.nearby;
    final selected =
        nearest != null && nearest.kind == place.kind && nearest.id == place.id;
    final near = session.world.distance(place.x, place.y) < 1.85;
    if (!(near && selected) && !session.world.perception) return;
    final p = iso(place.x, place.y);
    c.drawOval(
      Rect.fromCenter(center: p, width: 23, height: 11),
      Paint()
        ..color = amber.withValues(alpha: near && selected ? .7 : .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    if (near && selected)
      _text(
        c,
        place.label.toUpperCase(),
        p - const Offset(0, 55),
        fontSize: 8,
        color: amber,
        backing: true,
      );
  }

  void _prop(Canvas c, int index, Offset p, double extent) {
    final image = _sprites['props']!;
    c.drawImageRect(
      image,
      Rect.fromLTWH(index * 64.0, 0, 64, 64),
      Rect.fromLTWH(p.dx - extent / 2, p.dy - extent + 5, extent, extent),
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  void _drawActorRig(
    Canvas c,
    ui.Image image,
    ActorAnimation motion, {
    ui.Image? torsoImage,
    bool locomotion = true,
    double scale = 1,
  }) {
    final paint = Paint()..filterQuality = FilterQuality.low;
    c.save();
    c.scale(scale);
    if (locomotion) {
      void leg(bool left) {
        final pivot = Offset(left ? -7 : 7, -20);
        final stride = left ? motion.leftStride : motion.rightStride;
        final lift = left ? motion.leftLift : motion.rightLift;
        c.save();
        c.translate(pivot.dx + stride, pivot.dy - lift);
        c.rotate(left ? motion.leftAngle : motion.rightAngle);
        c.drawImageRect(
          image,
          Rect.fromLTWH(left ? 0 : 64, 88, 64, 40),
          Rect.fromLTWH((left ? -40 : 0) - pivot.dx, -20 - pivot.dy, 40, 25),
          paint,
        );
        c.restore();
      }

      leg(true);
      leg(false);
      c.save();
      c.translate(0, -20 + motion.torsoBob);
      c.rotate(motion.torsoLean);
      c.scale(1, motion.chestScale);
      c.drawImageRect(
        torsoImage ?? image,
        const Rect.fromLTWH(0, 0, 128, 90),
        const Rect.fromLTWH(-40, -55, 80, 56.25),
        paint,
      );
      c.restore();
    } else {
      c.drawImageRect(
        image,
        const Rect.fromLTWH(0, 0, 128, 128),
        const Rect.fromLTWH(-40, -75, 80, 80),
        paint,
      );
    }
    c.restore();
  }

  void _actor(
    Canvas c,
    String name,
    double x,
    double y,
    double dx,
    double dy,
    bool moving,
  ) {
    final p =
        (name == 'caio'
            ? iso(
                    session.world.playerDrawPosition.dx,
                    session.world.playerDrawPosition.dy,
                  ) -
                  Offset(0, session.world.playerElevation)
            : iso(x, y)) +
        Offset(
          0,
          name == 'caio' ? (session.buildingTransition?.actorDrop ?? 0) : 0,
        );
    c.drawOval(
      Rect.fromCenter(center: p, width: 25, height: 12),
      _paint(const Color(0x73202c2e)),
    );
    if (name != 'caio' && name != 'dominated') {
      final motion = session.world.npcMotion(name);
      final speaker = const {
        'ines': 'INÊS',
        'orlando': 'ORLANDO',
        'nestor': 'NESTOR',
        'marina': 'MARINA',
        'bia': 'BIA',
        'davi': 'DAVI',
      }[name];
      final conversing =
          session.phase == PlayPhase.dialogue &&
          session.currentLine?.speaker == speaker;
      final facing = conversing
          ? Offset(session.campaign.x - x, session.campaign.y - y)
          : motion.facing;
      final mirror = facing.dx - facing.dy > .1;
      final rig = ActorAnimation.sample(
        travelled: motion.traveled,
        time: session.world.simulationTime,
        moving: motion.moving,
      );
      c.save();
      c.translate(p.dx, p.dy);
      if (mirror) c.scale(-1, 1);
      _drawActorRig(
        c,
        _sprites['phase_$name']!,
        rig,
        scale: name == 'bia' ? .83 : 1,
      );
      c.restore();
      return;
    }
    if (name == 'dominated') {
      final threat = session.world.attackWindup > 0;
      final rig = ActorAnimation.sample(
        travelled: session.world.enemyWalked,
        time: session.world.simulationTime,
        moving: _enemyActuallyMoving && !threat && session.world.enemyStun <= 0,
      );
      c.save();
      c.translate(p.dx, p.dy);
      if (dx - dy > .1) c.scale(-1, 1);
      if (threat) {
        c.rotate(-.09);
      } else if (session.world.enemyStun > 0) {
        c.rotate(.1);
      }
      _drawActorRig(c, _sprites['phase_davi']!, rig);
      c.restore();
      if (threat) {
        c.drawArc(
          Rect.fromCenter(center: p, width: 60, height: 30),
          0,
          math.pi * 2 * (1 - session.world.attackWindup / .65),
          false,
          Paint()
            ..color = const Color(0xffda9b74)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      return;
    }
    moving =
        _playerActuallyMoving &&
        (session.phase == PlayPhase.playing ||
            session.phase == PlayPhase.buildingTransition);
    final rest = session.world.resting;
    if (rest != null && _homeSources.containsKey(rest)) {
      final anchor = session.world.restAnchor;
      final at = anchor == null ? p : iso(anchor.dx, anchor.dy);
      final source = _homeSources[rest]!;
      // Cropped home art has no 128px transparent canvas. Do not scale it as if it did.
      final height = rest == 'lie'
          ? 48.0
          : rest == 'reach'
          ? 61.0
          : 52.0;
      final width = height * source.width / source.height;
      c.drawImageRect(
        _sprites['caio_home_poses']!,
        source,
        Rect.fromLTWH(at.dx - width / 2, at.dy - height + 3, width, height),
        Paint()..filterQuality = FilterQuality.low,
      );
      return;
    }
    final fast =
        session.world.running &&
        !session.world.recoveringBreath &&
        !session.world.severelyHurt &&
        session.campaign.stamina > 5;
    final facing = SpriteFacing.fromWorld(dx, dy, running: moving && fast);
    final action = session.phase == PlayPhase.defeated
        ? 'defeat'
        : session.world.action;
    var state = 'idle';
    if (action == 'push') {
      final progress =
          1 - session.world.actionTime / session.world.actionDuration;
      state = progress < .35
          ? 'push_anticipation'
          : progress < .65
          ? 'push_contact'
          : 'push_recover';
    } else if (action == 'drink') {
      state = 'heal_pose';
    } else if (action == 'climb') {
      state = 'pickup_pose';
    } else if (action == 'heal') {
      state = 'heal_pose';
    } else if (action == 'pickup') {
      state = 'pickup_pose';
    } else if (action == 'hurt') {
      state = 'hurt';
    } else if (action == 'defeat') {
      state = 'defeat_pose';
    }
    final frame = ActorAnimation.frame(session.world.walked, running: fast);
    final key = moving && state == 'idle'
        ? (fast
              ? 'run_${facing.source}_$frame'
              : 'user_caio_${facing.source}_$frame')
        : 'pose_${facing.source}_$state';
    final image = _sprites[key]!;
    final rig = ActorAnimation.sample(
      travelled: session.world.walked,
      time: session.world.simulationTime,
      moving: moving && state == 'idle',
      running: fast,
      injured: session.world.severelyHurt,
      recoveringBreath: session.world.recoveringBreath,
    );
    c.save();
    c.translate(p.dx, p.dy);
    if (facing.mirror) c.scale(-1, 1);
    _drawActorRig(
      c,
      image,
      rig,
      torsoImage: session.world.severelyHurt && state == 'idle'
          ? _sprites['pose_${facing.source}_hurt']
          : null,
      locomotion: state == 'idle',
    );
    c.restore();
    if (session.world.pushCooldown > .4)
      c.drawOval(
        Rect.fromCenter(center: p, width: 105, height: 52),
        Paint()
          ..color = const Color(0x99c2b58c)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  void _enemy(Canvas c) {
    final world = session.world;
    final p = iso(world.enemyX, world.enemyY);
    if (world.distance(world.enemyX, world.enemyY) < 5) {
      c.drawOval(
        Rect.fromCenter(center: p, width: 35, height: 17),
        Paint()
          ..color = const Color(0x99c7806b)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    _actor(
      c,
      'dominated',
      world.enemyX,
      world.enemyY,
      session.campaign.x - world.enemyX,
      session.campaign.y - world.enemyY,
      world.enemyStun <= 0,
    );
    if (world.enemyStun > 0 && world.distance(world.enemyX, world.enemyY) < 2) {
      _text(
        c,
        'DESORIENTADO',
        p - const Offset(0, 77),
        color: const Color(0xffd6a28b),
        fontSize: 8,
        backing: true,
      );
    }
  }

  void _text(
    Canvas c,
    String value,
    Offset p, {
    Color color = teal,
    double fontSize = 10,
    bool backing = false,
  }) {
    final key = '$value:$fontSize:${color.toARGB32()}';
    final text = _labels.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
    final origin = p - Offset(text.width / 2, text.height / 2);
    if (backing) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            origin.dx - 6,
            origin.dy - 4,
            text.width + 12,
            text.height + 8,
          ),
          const Radius.circular(3),
        ),
        _paint(const Color(0xd91a2c32)),
      );
    }
    text.paint(c, origin);
  }

  void _rain(Canvas c) {
    if (session.reducedEffects) return;
    final paint = Paint()
      ..color = const Color(0x294f969b)
      ..strokeWidth = 1;
    for (var i = 0; i < 65; i++) {
      final x = ((i * 137.3 - session.elapsed * 52) % (size.x + 30)) - 15;
      final y = (i * 89.7 + session.elapsed * 235) % (size.y + 30) - 15;
      c.drawLine(Offset(x, y), Offset(x - 5, y + 15), paint);
    }
  }

  @override
  void onDispose() {
    _disposed = true;
    _ready = false;
    unawaited(audio.dispose());
    for (final ground in _grounds.values) {
      ground.dispose();
    }
    _grounds.clear();
    for (final painter in _labels.values) {
      painter.dispose();
    }
    _labels.clear();
    _sprites.clear();
    images.clearCache();
    super.onDispose();
  }
}
