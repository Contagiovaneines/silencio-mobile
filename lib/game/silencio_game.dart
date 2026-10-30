import 'dart:math' as math;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../services/game_audio.dart';
import '../services/game_preferences.dart';
import 'sprite_facing.dart';
import 'actor_animation.dart';
import 'actor_frames.dart';
import 'equipment_pose.dart';
import 'animal_behaviour.dart';

import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flame/cache.dart';
import 'package:flutter/painting.dart';

import '../models/campaign.dart';
import 'game_session.dart';
import 'world_model.dart';
import 'building_layout.dart';
import 'ground_tile_variation.dart';
import 'wall_cutaway.dart';

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
  final Map<String, Rect> _refinedSources = {};
  final Map<int, ui.Picture> _grounds = {};
  final Map<Rect, WallCutaway> _wallCutaways = {};
  final Map<String, Rect> _kitBounds = {};
  int _cameraFloor = 2;
  bool _ready = false, _disposed = false;
  double _cameraX = 0, _cameraY = 0;
  Offset? _aimScreen;
  bool _playerActuallyMoving = false, _enemyActuallyMoving = false;
  double get zoom => (size.y / 720).clamp(.65, 1.1);
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
    final refinedPack = jsonDecode(
      await rootBundle.loadString('assets/data/apartment_refined_v1.json'),
    ) as Map<String, dynamic>;
    for (final entry
        in (refinedPack['sprites'] as Map<String, dynamic>).entries) {
      final values = (entry.value as List).cast<num>();
      _refinedSources[entry.key] = Rect.fromLTWH(
        values[0].toDouble(),
        values[1].toDouble(),
        values[2].toDouble(),
        values[3].toDouble(),
      );
    }
    final kit = jsonDecode(
      await rootBundle.loadString('assets/data/asset_pack_v1.json'),
    ) as Map<String, dynamic>;
    for (final entry in (kit['building'] as Map<String, dynamic>).entries) {
      final bounds = (entry.value['bounds'] as List).cast<num>();
      _kitBounds[entry.key] = Rect.fromLTRB(
        bounds[0].toDouble(),
        bounds[1].toDouble(),
        bounds[2].toDouble(),
        bounds[3].toDouble(),
      );
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
    _updateWallCutaways(0, snap: true);
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
    if (_cameraFloor != session.campaign.floor) _wallCutaways.clear();
    _updateWallCutaways(dt);
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
    if (session.world.aiming && _aimScreen != null) {
      aimAtScreen(_aimScreen!);
    } else {
      _aimScreen = null;
    }
  }

  Offset screenToWorld(Offset screen) {
    final local =
        (screen - Offset(size.x * .5, size.y * .53)) / zoom +
        Offset(_cameraX, _cameraY);
    final x = (local.dx / 32 + local.dy / 16) / 2;
    final y = (local.dy / 16 - local.dx / 32) / 2;
    return Offset(x, y);
  }

  void aimAtScreen(Offset screen) {
    if (session.phase != PlayPhase.playing) return;
    _aimScreen = screen;
    final target = screenToWorld(screen);
    session.cancelApproach();
    session.world.aimAt(target.dx, target.dy);
  }

  void tapGround(Offset screen) {
    if (session.phase != PlayPhase.playing) return;
    if (session.world.aiming) {
      session.attack();
      return;
    }
    final target = screenToWorld(screen);
    Place? selected;
    var nearest = double.infinity;
    final local = iso(target.dx, target.dy);
    for (final place in session.world.places) {
      if (place.floor == 0 &&
          WorldModel.shopBounds.contains(Offset(place.x, place.y)) &&
          !session.world.inShop) {
        continue;
      }
      final delta = local - iso(place.x, place.y);
      final distance = math.sqrt(
        delta.dx * delta.dx + (delta.dy + 18) * (delta.dy + 18) * .35,
      );
      if (delta.dx.abs() <= 26 &&
          delta.dy >= -56 &&
          delta.dy <= 10 &&
          distance < nearest) {
        nearest = distance;
        selected = place;
      }
    }
    if (selected != null) {
      session.approachAndInteract(selected);
    } else {
      session.cancelApproach();
      session.world.moveTo(target.dx, target.dy);
    }
  }

  Paint _paint(Color color) => Paint()..color = color;
  Path _poly(List<Offset> points) => Path()..addPolygon(points, true);

  void _drawGround(Canvas c, {required int floor}) {
    if (floor == 0) {
      c.drawRect(
        const Rect.fromLTRB(-5000, -2000, 5000, 5000),
        _paint(const Color(0xff586848)),
      );
    }
    // The non-walkable terrain apron keeps the building in its neighborhood
    // when an upper floor is cut away. Navigation still uses WorldModel bounds.
    final apron = floor == 0 ? 32 : 0;
    for (var y = -apron; y < WorldModel.height + apron; y++) {
      for (var x = -apron; x < WorldModel.width + apron; x++) {
        if (floor > 0 &&
            !ResidentialLayout.footprint.contains(
              Offset(x.toDouble(), y.toDouble()),
            )) {
          continue;
        }
        final apartment = floor > 0 && x >= 2 && x < 24 && y >= 2 && y < 10;
        final hall = x >= 2 && x < 24 && y >= 10 && y < 16;
        final garage = x >= 12 && x < 23 && y >= 10 && y < 16;
        final shop = x >= 24 && x < 32 && y >= 17 && y < 24;
        final road = y >= 26 && y <= 30 || x >= 43 && x < 50 && y >= 16;
        final plaza = x >= 15 && x < 26 && y >= 27 && y < 36;
        final pavement =
            y >= 24 && y <= 32 ||
            x >= 41 && x <= 51 && y >= 16 ||
            x >= 2 && x < 33 && y >= 16 && y < 20;
        final bath = floor == 2 && x >= 8 && x < 12 && y >= 7 && y < 10;
        final tile = bath
            ? 'concrete'
            : apartment
            ? 'wood'
            : hall || garage || shop || plaza
            ? 'concrete'
            : road
            ? 'asphalt'
            : pavement
            ? 'sidewalk'
            : 'grass';
        final p = iso(x.toDouble(), y.toDouble());
        final tileSprite = tile == 'concrete'
            ? 'tile_concrete_${ConcreteTileVariation.at(x, y)}'
            : tile == 'grass'
            ? 'tile_grass_${ConcreteTileVariation.at(x, y)}'
            : 'tile_$tile';
        final interiorTile = floor > 0 && (hall || bath);
        if (interiorTile) {
          final corners = [
            p,
            p + const Offset(32, 16),
            p + const Offset(0, 32),
            p + const Offset(-32, 16),
          ];
          c.drawPath(
            _poly(corners),
            _paint(
              bath
                  ? ((x + y).isEven
                        ? const Color(0xffc4c5b7)
                        : const Color(0xffadb7ae))
                  : ((x + y).isEven
                        ? const Color(0xffa59c87)
                        : const Color(0xffa09883)),
            ),
          );
          c.drawPath(
            _poly(corners),
            _paint(const Color(0x40807665))
              ..style = PaintingStyle.stroke
              ..strokeWidth = .7,
          );
        } else {
          c.drawImageRect(
            _sprites[tileSprite]!,
            const Rect.fromLTWH(0, 0, 64, 32),
            Rect.fromLTWH(p.dx - 32, p.dy, 64, 32),
            Paint()..color = const Color(0xffa5b1aa),
          );
        }
        c.drawPath(
          _poly([
            p,
            p + const Offset(32, 16),
            p + const Offset(0, 32),
            p + const Offset(-32, 16),
          ]),
          Paint()
            ..color = Color.fromRGBO(
              7,
              25,
              32,
              apartment
                  ? .10
                  : interiorTile
                  ? .04
                  : .18,
            ),
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
    if (floor == 0) _drawCrosswalk(c);
  }

  void _drawCrosswalk(Canvas c) {
    // Six short, evenly spaced bars cross the road at the shop corner.
    // They sit on the asphalt plane and stay separate from the sidewalk grid.
    for (var x = 39.0; x <= 41.75; x += .55) {
      c.drawPath(
        _poly([
          iso(x - .13, 26),
          iso(x + .13, 26),
          iso(x + .13, 30.75),
          iso(x - .13, 30.75),
        ]),
        _paint(const Color(0xffd6d0b7)),
      );
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
    final occupiedUnit = ResidentialLayout.unitAt(
      session.campaign.floor,
      Offset(session.campaign.x, session.campaign.y),
    );
    final focusedInterior = occupiedUnit != null;
    if (occupiedUnit != null) {
      // The cutaway shows one lived-in apartment, but its exterior support
      // belongs to the complete building footprint. Using only the unit's
      // rectangle makes the second-floor room read as a detached box.
      _focusedApartmentFoundation(c, ResidentialLayout.footprint);
    }
    if (session.campaign.floor > 0 && !focusedInterior) {
      c.save();
      c.translate(0, session.campaign.floor * 62.0);
      c.drawPicture(_grounds[0]!);
      for (final block in WorldModel.blocks.where(
        (b) => b.floor == 0 && b.style != 5,
      )) {
        _building(c, block);
      }
      c.restore();
      _floorSlab(c);
    }
    if (focusedInterior) {
      c.save();
      c.clipPath(
        _poly([
          iso(occupiedUnit.left, occupiedUnit.top),
          iso(occupiedUnit.right, occupiedUnit.top),
          iso(occupiedUnit.right, occupiedUnit.bottom),
          iso(occupiedUnit.left, occupiedUnit.bottom),
        ]),
      );
      c.drawPicture(_grounds[session.campaign.floor]!);
      c.restore();
      _focusedHallwayContext(c, occupiedUnit);
    } else if (session.campaign.floor > 0 &&
        ResidentialLayout.unitAt(
              session.campaign.floor,
              Offset(session.campaign.x, session.campaign.y),
            ) ==
            null) {
      // In the shared hallway, draw only its tiles. Drawing the whole floor
      // map exposed the bedrooms through the neighboring apartment walls.
      c.save();
      c.clipPath(
        _poly([
          iso(ResidentialLayout.corridor.left, ResidentialLayout.corridor.top),
          iso(ResidentialLayout.corridor.right, ResidentialLayout.corridor.top),
          iso(
            ResidentialLayout.corridor.right,
            ResidentialLayout.corridor.bottom,
          ),
          iso(
            ResidentialLayout.corridor.left,
            ResidentialLayout.corridor.bottom,
          ),
        ]),
      );
      c.drawPicture(_grounds[session.campaign.floor]!);
      c.restore();
    } else {
      c.drawPicture(_grounds[session.campaign.floor]!);
    }
    if (session.campaign.floor == 0) {
      _drawTower(c);
    }
    if (!focusedInterior) _upperLanding(c);

    _flashlight(c);
    _drawPath(c);
    final aim = session.world.aimTarget;
    if (session.world.aiming && aim != null) {
      final player = iso(session.campaign.x, session.campaign.y);
      final target = iso(aim.dx, aim.dy);
      final clear = session.world.lineClear(
        Offset(session.campaign.x, session.campaign.y),
        aim,
      );
      final paint = _paint(clear ? amber : const Color(0xffbc8274))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      c.drawLine(player, target, paint);
      c.drawOval(Rect.fromCenter(center: target, width: 18, height: 9), paint);
      c.drawLine(
        target - const Offset(12, 0),
        target + const Offset(12, 0),
        paint,
      );
    }
    final draws =
        <
          ({
            double depth,
            void Function() draw,
            Rect? footprint,
            Offset? position,
          })
        >[];
    final farWalls = <Rect>[];
    final nearWalls = <Rect>[];
    for (final block in WorldModel.blocks.where(
      (b) => b.floor == session.campaign.floor && _onScreen(b.bounds),
    )) {
      if (focusedInterior &&
          block.interior &&
          block.floor > 0 &&
          block.bounds != occupiedUnit) {
        continue;
      }
      final closedUnit =
          block.interior && block.floor > 0 && block.bounds != occupiedUnit;
      final closedShop = block.style == 1 && !session.world.inShop;
      draws.add((
        depth: block.interior && !closedUnit && !closedShop
            ? block.bounds.left + block.bounds.top
            : block.bounds.right + block.bounds.bottom,
        footprint: block.interior && !closedUnit && !closedShop
            ? null
            : block.bounds,
        position: null,
        draw: () => closedUnit
            ? _closedUnit(
                c,
                block,
                corridorView: session.world.inResidence && occupiedUnit == null,
              )
            : _building(c, block),
      ));
      if (block.style == 1 && session.world.inShop) {
        draws.add((
          depth: block.bounds.right + block.bounds.bottom,
          footprint: null,
          position: null,
          draw: () => _shopFront(c, block, cut: true),
        ));
      }
    }
    for (final p
        in session.campaign.floor == 0
            ? [
                const Offset(7, 18),
                const Offset(21, 18.5),
                const Offset(26, 12),
                const Offset(15.5, 24.4),
                const Offset(35.5, 31.5),
                const Offset(49.2, 24.1),
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
      if (place.floor == 0 &&
          WorldModel.shopBounds.contains(Offset(place.x, place.y)) &&
          !session.world.inShop) {
        continue;
      }
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
    for (final wall in ResidentialLayout.partitions(
      session.campaign.floor,
    ).where((wall) => occupiedUnit == null || wall.overlaps(occupiedUnit))) {
      final center = wall.center;
      final farBoundary =
          occupiedUnit != null &&
          (wall.width > wall.height
              ? wall.center.dy <= occupiedUnit.top + .25
              : wall.center.dx <= occupiedUnit.left + .25);
      final nearBoundary =
          occupiedUnit != null &&
          (wall.width > wall.height
              ? wall.center.dy >= occupiedUnit.bottom - .25
              : wall.center.dx >= occupiedUnit.right - .25);
      if (occupiedUnit != null && farBoundary) {
        farWalls.add(wall);
        continue;
      }
      if (occupiedUnit != null && nearBoundary) {
        nearWalls.add(wall);
        continue;
      }
      draws.add((
        depth: center.dx + center.dy,
        footprint: wall,
        position: null,
        draw: () => _structuralWall(c, wall),
      ));
    }
    // Isometric sorting by ground footprints can cycle when a tall back wall
    // overlaps a bed sprite. Keep the apartment's far perimeter behind all
    // furniture; render the near perimeter last so it still frames the cutaway.
    for (final wall in farWalls) {
      _structuralWall(c, wall);
    }
    for (final person in session.world.visiblePeople.where(
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
      final anchor = session.world.restAnchor;
      final resting = session.world.resting;
      final isRestingOnThis = resting == 'lie' && furniture.kind == 'bed' ||
          resting == 'sit' &&
              anchor != null &&
              ((anchor.dx < 5 && furniture.kind == 'sofa') ||
                  (anchor.dx >= 5 && furniture.kind == 'chair'));
      if (isRestingOnThis) continue;
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
    if (session.world.encounterActive || session.world.enemyDefeated) {
      draws.add((
        depth: session.world.enemyX + session.world.enemyY,
        footprint: null,
        position: Offset(session.world.enemyX, session.world.enemyY),
        draw: () => session.world.enemyDefeated ? _downedEnemy(c) : _enemy(c),
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
    for (final wall in nearWalls) {
      _structuralWall(c, wall);
    }
    if (session.phase != PlayPhase.buildingTransition) {
      final nearby = session.world.nearby;
      final placeLabels = session.world.perception
          ? session.world.places
          : [
              if (nearby != null && session.world.shouldShowPlaceLabel(nearby))
                nearby,
            ];
      for (final place in placeLabels) {
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
        !session.world.inResidence) {
      _rain(c);
    }
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

  void _flashlight(Canvas c) {
    if (!session.campaign.inChapterTwo ||
        !session.campaign.has('chapter2_torch')) {
      return;
    }
    final world = session.world;
    final origin = Offset(session.campaign.x, session.campaign.y);
    final angle = math.atan2(world.facingY, world.facingX);
    final edge = <Offset>[iso(origin.dx, origin.dy)];
    // The light follows the feet plane and stops at solid geometry.
    // A fixed small ray count keeps the mobile cost bounded.
    for (var ray = 0; ray <= 10; ray++) {
      final a = angle - .48 + ray * .096;
      var end = origin;
      for (var step = 1; step <= 11; step++) {
        final candidate =
            origin + Offset(math.cos(a), math.sin(a)) * (step * .35);
        if (!world.isOpen(candidate.dx, candidate.dy)) break;
        end = candidate;
      }
      edge.add(iso(end.dx, end.dy));
    }
    final center = iso(origin.dx, origin.dy);
    c.drawPath(
      _poly(edge),
      Paint()
        ..shader = ui.Gradient.radial(center, 145, [
          const Color(0x65eadca2),
          const Color(0x00eadca2),
        ]),
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
    if (block.style == 1 && block.interior) {
      _shop(c, block);
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
      _paint(
        fade(
          block.style == 0 ? const Color(0xffa29e87) : const Color(0xff7e8a80),
        ),
      ),
    );
    c.drawPath(
      _poly([base[1], base[2], roof[2], roof[1]]),
      _paint(
        fade(
          block.style == 0 ? const Color(0xff818a78) : const Color(0xff5e7470),
        ),
      ),
    );
    c.drawPath(
      _poly(roof),
      _paint(
        fade(
          block.style == 1 ? const Color(0xff49615d) : const Color(0xff344e51),
        ),
      ),
    );
    for (var rise = 8.0; rise < block.height; rise += 9) {
      c.drawLine(
        base[3] - Offset(0, rise),
        base[2] - Offset(0, rise),
        _paint(fade(const Color(0x2880715f)))..strokeWidth = 1,
      );
      c.drawLine(
        base[1] - Offset(0, rise),
        base[2] - Offset(0, rise),
        _paint(fade(const Color(0x28516358)))..strokeWidth = 1,
      );
    }
    c.drawLine(
      base[3] - const Offset(0, 4),
      base[2] - const Offset(0, 4),
      _paint(fade(const Color(0xff6b705f)))..strokeWidth = 8,
    );
    if (block.style == 0) {
      final ridgeA = Offset.lerp(roof[0], roof[3], .5)! - const Offset(0, 22);
      final ridgeB = Offset.lerp(roof[1], roof[2], .5)! - const Offset(0, 22);
      c.drawPath(
        _poly([roof[0], roof[1], ridgeB, ridgeA]),
        _paint(fade(const Color(0xff687064))),
      );
      c.drawPath(
        _poly([roof[3], roof[2], ridgeB, ridgeA]),
        _paint(fade(const Color(0xff48584e))),
      );
      for (var row = 0.0; row < 1; row += .125) {
        final a = Offset.lerp(roof[3], ridgeA, row)!;
        final z = Offset.lerp(roof[2], ridgeB, row)!;
        c.drawLine(
          a,
          z,
          _paint(fade(const Color(0xff7c8270)))..strokeWidth = 1,
        );
        for (var joint = .04; joint < 1; joint += .08) {
          final p = Offset.lerp(a, z, joint)!;
          final q = Offset.lerp(
            Offset.lerp(roof[3], ridgeA, row + .125)!,
            Offset.lerp(roof[2], ridgeB, row + .125)!,
            joint,
          )!;
          c.drawLine(
            p,
            q,
            _paint(fade(const Color(0xff3f4d43)))..strokeWidth = .8,
          );
        }
      }
      c.drawLine(
        ridgeA,
        ridgeB,
        _paint(fade(const Color(0xffa1a08a)))..strokeWidth = 3,
      );
    }
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

  void _shopWall(Canvas c, Offset a, Offset b, double height, Color color) {
    c.drawPath(
      _poly([a, b, b - Offset(0, height), a - Offset(0, height)]),
      _paint(color),
    );
    c.drawLine(
      a - Offset(0, height),
      b - Offset(0, height),
      _paint(const Color(0xffd4c6a4))..strokeWidth = 3,
    );
    c.drawLine(
      a - const Offset(0, 3),
      b - const Offset(0, 3),
      _paint(const Color(0xff655f4e))..strokeWidth = 4,
    );
  }

  void _shopFront(Canvas c, Block block, {required bool cut}) {
    final b = block.bounds;
    final middle = b.center.dx;
    final height = cut ? 12.0 : block.height;
    for (final span in [(b.left, middle - .9), (middle + .9, b.right)]) {
      _shopWall(
        c,
        iso(span.$1, b.bottom),
        iso(span.$2, b.bottom),
        height,
        const Color(0xffb0a38a),
      );
    }
    if (cut) return;
    final a = iso(middle - .9, b.bottom), z = iso(middle + .9, b.bottom);
    // The visible opening matches the existing traversable doorway exactly.
    _shopWall(
      c,
      a - const Offset(0, 52),
      z - const Offset(0, 52),
      block.height - 52,
      const Color(0xff69796b),
    );
    for (final foot in [a, z]) {
      c.drawLine(
        foot,
        foot - const Offset(0, 52),
        _paint(const Color(0xffe0c697))..strokeWidth = 4,
      );
    }
    c.drawPath(
      _poly([a, z, z - const Offset(0, 51), a - const Offset(0, 51)]),
      _paint(const Color(0xff293c38)),
    );
    for (final x in [25.5, 30.5]) {
      final left = iso(x - .65, b.bottom) - const Offset(0, 20);
      final right = iso(x + .65, b.bottom) - const Offset(0, 20);
      _shopWall(c, left, right, 26, const Color(0xff456568));
      c.drawLine(
        Offset.lerp(left, right, .5)!,
        Offset.lerp(left, right, .5)! - const Offset(0, 26),
        _paint(const Color(0xffc7ba97))..strokeWidth = 2,
      );
    }
    _text(
      c,
      'MERCEARIA · ORLANDO',
      iso(middle, b.bottom) - const Offset(0, 61),
      fontSize: 8,
      color: amber,
      backing: true,
    );
  }

  void _shop(Canvas c, Block block) {
    final b = block.bounds;
    final inside =
        session.campaign.floor == block.floor && session.world.inShop;
    if (inside) {
      _shopWall(
        c,
        iso(b.left, b.top),
        iso(b.right, b.top),
        block.height,
        const Color(0xffc2b99f),
      );
      _shopWall(
        c,
        iso(b.left, b.top),
        iso(b.left, b.bottom),
        block.height,
        const Color(0xffa7ad95),
      );
      _shopWall(
        c,
        iso(b.right, b.top),
        iso(b.right, b.bottom),
        12,
        const Color(0xffa0aa91),
      );
      _text(
        c,
        'MERCEARIA',
        iso(28, 17) - const Offset(0, 42),
        fontSize: 10,
        color: const Color(0xff4e6254),
      );
      return;
    }
    final storefront = _sprites['pack_market_exterior'];
    if (storefront != null) {
      final width = (b.width + b.height) * 32;
      final height = width * storefront.height / storefront.width;
      final left = iso(b.left, b.bottom).dx;
      final baseline = iso(b.right, b.bottom).dy;
      c.drawImageRect(
        storefront,
        Rect.fromLTWH(
          0,
          0,
          storefront.width.toDouble(),
          storefront.height.toDouble(),
        ),
        Rect.fromLTWH(left, baseline - height, width, height),
        Paint()..filterQuality = FilterQuality.medium,
      );
      return;
    }
    _shopWall(
      c,
      iso(b.right, b.top),
      iso(b.right, b.bottom),
      block.height,
      const Color(0xff84927b),
    );
    _shopFront(c, block, cut: false);
    final roof = [
      iso(b.left, b.top),
      iso(b.right, b.top),
      iso(b.right, b.bottom),
      iso(b.left, b.bottom),
    ].map((p) => p - Offset(0, block.height)).toList();
    c.drawPath(_poly(roof), _paint(const Color(0xff50695d)));
    c.drawPath(
      _poly(roof),
      _paint(const Color(0xffa3ad90))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    for (var y = b.top + .5; y < b.bottom; y += .6) {
      c.drawLine(
        iso(b.left, y) - Offset(0, block.height),
        iso(b.right, y) - Offset(0, block.height),
        _paint(const Color(0xff758476))..strokeWidth = 1,
      );
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
    if (night > .03 && !_lowQuality) {
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
    }
    final lamp = _sprites['street_lamp'];
    if (lamp != null) {
      const width = 54.0;
      final height = width * 248 / 157;
      c.drawImageRect(
        lamp,
        Rect.fromLTWH(0, 0, lamp.width.toDouble(), lamp.height.toDouble()),
        Rect.fromLTWH(p.dx - width / 2, p.dy - height, width, height),
        Paint()..filterQuality = FilterQuality.medium,
      );
      return;
    }
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

  void _floorSlab(Canvas c) {
    final b = ResidentialLayout.footprint;
    for (final edge in [
      (iso(b.left, b.bottom), iso(b.right, b.bottom)),
      (iso(b.right, b.top), iso(b.right, b.bottom)),
    ]) {
      final (a, z) = edge;
      final drop = Offset(0, session.campaign.floor * 62.0);
      c.drawPath(
        _poly([a, z, z + drop, a + drop]),
        _paint(const Color(0xff69736b)),
      );
      for (var level = 0; level < session.campaign.floor; level++) {
        final off = Offset(0, level * 62.0 + 7);
        c.drawLine(
          a + off,
          z + off,
          _paint(const Color(0xffb7b19d))..strokeWidth = 5,
        );
        for (var t = .06; t < 1; t += .10) {
          final p = Offset.lerp(a, z, t)! + off + const Offset(0, 22);
          final q = Offset.lerp(a, z, t + .045)! + off + const Offset(0, 22);
          c.drawPath(
            _poly([p, q, q + const Offset(0, 23), p + const Offset(0, 23)]),
            _paint(const Color(0xff304950)),
          );
        }
      }
      c.drawLine(a, z, _paint(const Color(0xffc7bd9f))..strokeWidth = 4);
    }
  }

  void _focusedApartmentFoundation(Canvas c, Rect unit) {
    // Project the actual street and lower-storey shells beneath the cutaway.
    // This gives the upper apartment a visible architectural base without
    // drawing a roof/floor slab across the whole building footprint.
    final storeys = math.max(1, session.campaign.floor);
    final drop = Offset(0, storeys * 62.0);
    c.save();
    c.translate(0, drop.dy);
    c.drawPicture(_grounds[0]!);
    for (final block in WorldModel.blocks.where(
      (b) => b.floor == 0 && b.style != 5 && !b.interior,
    )) {
      _building(c, block);
    }
    c.restore();

    final topRight = iso(unit.right, unit.top),
        frontRight = iso(unit.right, unit.bottom),
        frontLeft = iso(unit.left, unit.bottom);
    c.drawPath(
      _poly([frontLeft, frontRight, frontRight + drop, frontLeft + drop]),
      _paint(const Color(0xff59615a)),
    );
    c.drawPath(
      _poly([topRight, frontRight, frontRight + drop, topRight + drop]),
      _paint(const Color(0xff3e4b4c)),
    );
    c.drawLine(
      frontLeft + drop,
      frontRight + drop,
      _paint(const Color(0xffa39b84))..strokeWidth = 3,
    );
    c.drawLine(
      topRight + drop,
      frontRight + drop,
      _paint(const Color(0xff8c9182))..strokeWidth = 2,
    );
    for (var storey = 0; storey < storeys; storey++) {
      final rowOffset = Offset(0, (storey + .5) * 62.0);
      for (var index = 1; index <= 3; index++) {
        final p = Offset.lerp(frontLeft, frontRight, index / 4)! + rowOffset;
        final window = [
          p + const Offset(-12, -10),
          p + const Offset(12, 2),
          p + const Offset(12, 25),
          p + const Offset(-12, 13),
        ];
        final pane = [
          Offset.lerp(window[0], window[1], .12)!,
          Offset.lerp(window[1], window[2], .12)!,
          Offset.lerp(window[2], window[3], .12)!,
          Offset.lerp(window[3], window[0], .12)!,
        ];
        c.drawPath(_poly(window), _paint(const Color(0xffb1a58d)));
        c.drawPath(_poly(pane), _paint(const Color(0xff354e54)));
        c.drawPath(
          _poly([
            pane[0],
            pane[1],
            Offset.lerp(pane[1], pane[2], .45)!,
            Offset.lerp(pane[0], pane[3], .45)!,
          ]),
          _paint(const Color(0xff687b79)),
        );
        c.drawPath(
          _poly(window),
          _paint(const Color(0xff978e78))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        c.drawLine(
          Offset.lerp(pane[0], pane[1], .5)!,
          Offset.lerp(pane[3], pane[2], .5)!,
          _paint(const Color(0xff7e887d))..strokeWidth = 1,
        );
        c.drawLine(
          Offset.lerp(pane[0], pane[3], .55)!,
          Offset.lerp(pane[1], pane[2], .55)!,
          _paint(const Color(0xff7e887d))..strokeWidth = 1,
        );
      }
    }
    c.drawLine(
      frontLeft + drop,
      frontRight + drop,
      _paint(const Color(0xff323e3f))..strokeWidth = 4,
    );
  }

  void _focusedHallwayContext(Canvas c, Rect unit) {
    const doorCenterX = 7.0;
    final landingLeft = math.max(unit.left, doorCenterX - 2.0);
    final landingRight = math.min(unit.right, doorCenterX + 2.0);
    final endY = math.min(
      unit.bottom + 2.5,
      ResidentialLayout.corridor.bottom,
    );
    final landing = _poly([
      iso(landingLeft, unit.bottom),
      iso(landingRight, unit.bottom),
      iso(landingRight, endY),
      iso(landingLeft, endY),
    ]);
    c.save();
    c.clipPath(landing);
    c.drawPicture(_grounds[session.campaign.floor]!);
    c.restore();

    final left = iso(landingLeft, endY), right = iso(landingRight, endY);
    c.drawLine(left, right, _paint(const Color(0xff62756e))..strokeWidth = 3);
    for (var x = landingLeft; x <= landingRight; x += .5) {
      final post = iso(x, endY);
      c.drawLine(
        post,
        post - const Offset(0, 17),
        _paint(const Color(0xff87958a))..strokeWidth = 1.5,
      );
    }
    c.drawLine(
      left - const Offset(0, 17),
      right - const Offset(0, 17),
      _paint(const Color(0xffb1ac92))..strokeWidth = 2.5,
    );
  }

  void _closedUnit(Canvas c, Block block, {bool corridorView = false}) {
    final b = block.bounds;
    const height = 58.0;
    final a = iso(b.left, b.top), z = iso(b.right, b.top);
    final d = iso(b.right, b.bottom), e = iso(b.left, b.bottom);
    const up = Offset(0, height);
    c.drawPath(_poly([e, d, d - up, e - up]), _paint(const Color(0xff8b8877)));
    c.drawPath(_poly([z, d, d - up, z - up]), _paint(const Color(0xff6b7268)));
    if (!corridorView) {
      c.drawPath(
        _poly([a - up, z - up, d - up, e - up]),
        _paint(const Color(0xff485955)),
      );
      c.drawPath(
        _poly([a - up, z - up, d - up, e - up]),
        _paint(const Color(0xffa6a48e))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      for (var y = b.top + 1; y < b.bottom; y += 1) {
        c.drawLine(
          iso(b.left, y) - up,
          iso(b.right, y) - up,
          _paint(const Color(0xff5c6b61))..strokeWidth = 1,
        );
      }
    } else {
      // Simple opaque caps hide unoccupied apartments from the hall without
      // drawing their furniture or a detailed roof texture.
      c.drawLine(
        e - up,
        d - up,
        _paint(const Color(0xffa6a48e))..strokeWidth = 3,
      );
      c.drawLine(
        z - up,
        d - up,
        _paint(const Color(0xff929380))..strokeWidth = 3,
      );
      final cap = [a - up, z - up, d - up, e - up];
      c.drawPath(_poly(cap), _paint(const Color(0xff59625a)));
      c.drawPath(
        _poly(cap),
        _paint(const Color(0xff858777))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _upperLanding(Canvas c) {
    if (ResidentialLayout.unitAt(
          session.campaign.floor,
          Offset(session.campaign.x, session.campaign.y),
        ) !=
        null) {
      return;
    }
    final floor = session.campaign.floor;
    final a = iso(2, 16), b = iso(24, 16);
    c.drawPath(
      _poly([a, b, b + const Offset(0, 28), a + const Offset(0, 28)]),
      _paint(const Color(0xff263b40)),
    );
    if (floor > 0) {
      bool stairOpening(double x) =>
          (x >= 3.75 && x <= 5.65) || (x >= 9.05 && x <= 10.95);
      for (var x = 2.0; x <= 24; x += .65) {
        if (stairOpening(x)) continue;
        final p = iso(x, 15.95);
        c.drawLine(
          p,
          p - const Offset(0, 30),
          _paint(const Color(0xff758985))..strokeWidth = 2,
        );
      }
      for (final range in [(2.0, 3.75), (5.65, 9.05), (10.95, 24.0)]) {
        c.drawLine(
          iso(range.$1, 15.95) - const Offset(0, 30),
          iso(range.$2, 15.95) - const Offset(0, 30),
          _paint(teal)..strokeWidth = 3,
        );
      }
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
    final board = iso(18.5, 10.25);
    c.drawLine(
      board - const Offset(0, 11),
      board - const Offset(0, 42),
      _paint(const Color(0xff746448))..strokeWidth = 3,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: board - const Offset(0, 45),
          width: 30,
          height: 34,
        ),
        const Radius.circular(2),
      ),
      _paint(const Color(0xff816e53)),
    );
    c.drawRect(
      Rect.fromCenter(
        center: board - const Offset(0, 45),
        width: 22,
        height: 26,
      ),
      _paint(const Color(0xffd0c5a4)),
    );
  }

  void _updateWallCutaways(double dt, {bool snap = false}) {
    final player = Offset(session.campaign.x, session.campaign.y);
    final indoors = session.campaign.floor > 0
        ? ResidentialLayout.footprint.contains(player)
        : session.world.inResidence;
    for (final wall in ResidentialLayout.partitions(session.campaign.floor)) {
      final horizontal = wall.width > wall.height;
      _wallCutaways
          .putIfAbsent(wall, WallCutaway.new)
          .update(
            signedDistance: horizontal
                ? player.dy - wall.center.dy
                : player.dx - wall.center.dx,
            indoors: indoors,
            dt: dt,
            snap: snap,
          );
    }
  }

  void _structuralWall(Canvas c, Rect wall) {
    if (!_onScreen(wall)) return;
    final horizontal = wall.width > wall.height;
    final a = horizontal
            ? iso(wall.left, wall.center.dy)
            : iso(wall.center.dx, wall.top),
        b = horizontal
            ? iso(wall.right, wall.center.dy)
            : iso(wall.center.dx, wall.bottom);
    final player = Offset(session.campaign.x, session.campaign.y);
    final inside =
        (session.campaign.floor > 0 &&
            ResidentialLayout.unitAt(session.campaign.floor, player) != null) ||
        (session.campaign.floor == 0 && session.world.inResidence);
    final bathroom = ResidentialLayout.bathroom.contains(player);
    final cut = (inside || bathroom)
        ? (_wallCutaways[wall]?.fraction ?? 0)
        : 0.0;
    final occludes = cut > .01;
    // Keep the cutaway wall at the same architectural height as a door and
    // fade the face instead. Shortening the wall left full-height doors
    // visually detached and made rooms look as if the door floated above them.
    final height =
        session.campaign.floor > 0 && horizontal && wall.center.dy > 15
        ? 12.0
        : ResidentialLayout.wallHeight;
    final wallOpacity = 1 - .78 * cut;
    c.drawPath(
      _poly([a, b, b - Offset(0, height), a - Offset(0, height)]),
      _paint(
        (horizontal ? const Color(0xffb7ae96) : const Color(0xff9d9b86))
            .withValues(alpha: wallOpacity),
      ),
    );
    final texture =
        _sprites[horizontal
            ? 'kit_wall_plaster_east'
            : 'kit_wall_plaster_west'];
    if (texture != null) {
      c.save();
      c.clipPath(_poly([a, b, b - Offset(0, height), a - Offset(0, height)]));
      final span = horizontal ? wall.width : wall.height;
      for (var n = 0.0; n < span; n += 2) {
        final start = horizontal
            ? iso(wall.left + n, wall.center.dy)
            : iso(wall.center.dx, wall.top + n);
        c.drawImageRect(
          texture,
          const Rect.fromLTWH(0, 0, 80, 112),
          Rect.fromLTWH(
            start.dx - (horizontal ? 8 : 72),
            start.dy - 72,
            80,
            112,
          ),
          Paint()
            ..color = Color.fromRGBO(255, 255, 255, wallOpacity)
            ..filterQuality = FilterQuality.none,
        );
      }
      c.restore();
    }
    c.drawLine(
      a - const Offset(0, 3),
      b - const Offset(0, 3),
      _paint(const Color(0xff675d4d))..strokeWidth = 4,
    );
    if (!occludes) {
      c.drawLine(
        a - Offset(0, height * .42),
        b - Offset(0, height * .42),
        _paint(const Color(0x208c8067))..strokeWidth = 1,
      );
    }
    c.drawLine(
      a - Offset(0, height),
      b - Offset(0, height),
      _paint(const Color(0xffb1a38b))..strokeWidth = 3,
    );
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

  void _frontWindow(Canvas c, Offset p, {required bool open, String? id}) {
    _windowBase(c, p, open: open);
    if (id == null) return;
    final state = session.campaign;
    if (state.brokenWindows.contains(id)) {
      c.drawPath(
        _poly([
          p + const Offset(-8, -23),
          p + const Offset(-4, -14),
          p + const Offset(0, -20),
        ]),
        _paint(const Color(0xffa6c6cc)),
      );
    }
    if (state.removedCurtains.contains(id)) return;
    final closed = state.closedCurtains.contains(id);
    for (final span in closed ? [(-8.0, 8.0)] : [(-8.0, -5.0), (5.0, 8.0)]) {
      final a = p + Offset(span.$1, span.$1 * .5 - 20);
      final b = p + Offset(span.$2, span.$2 * .5 - 20);
      c.drawPath(
        _poly([a, b, b + const Offset(0, 19), a + const Offset(0, 19)]),
        _paint(const Color(0xffad9472)),
      );
      c.drawLine(a, b, _paint(const Color(0xff665542))..strokeWidth = 2);
    }
  }

  void _windowBase(Canvas c, Offset p, {required bool open}) {
    final texture =
        _sprites[open ? 'kit_window_open_east' : 'kit_window_closed_east'];
    if (texture != null) {
      c.drawImageRect(
        texture,
        const Rect.fromLTWH(0, 0, 64, 80),
        Rect.fromLTWH(p.dx - 16, p.dy - 30, 32, 40),
        Paint()..filterQuality = FilterQuality.none,
      );
      return;
    }
    final frame = [
      p + const Offset(-10, -5),
      p + const Offset(10, 5),
      p + const Offset(10, -18),
      p + const Offset(-10, -28),
    ];
    c.drawPath(_poly(frame), _paint(const Color(0xffb6a078)));
    if (open) {
      c.drawPath(
        _poly([
          p + const Offset(-7, -7),
          p + const Offset(7, 0),
          p + const Offset(7, -17),
          p + const Offset(-7, -24),
        ]),
        _paint(const Color(0xff101b20)),
      );
      c.drawPath(
        _poly([
          p + const Offset(-8, -6),
          p + const Offset(-1, -3),
          p + const Offset(-7, -20),
          p + const Offset(-14, -25),
        ]),
        _paint(const Color(0xffdec390)),
      );
    } else {
      final glass = [
        p + const Offset(-7, -24),
        p + const Offset(7, -17),
        p + const Offset(7, 1),
        p + const Offset(-7, -6),
      ];
      c.drawPath(
        _poly(glass),
        _paint(const Color(0xff314b53).withValues(alpha: .8)),
      );
      _glassSheen(c, glass);
      c.drawLine(
        p + const Offset(-7, -17),
        p + const Offset(7, -10),
        _paint(const Color(0xffe0bd79))..strokeWidth = 3,
      );
    }
    c.drawPath(
      _poly(frame),
      _paint(const Color(0xffb6a078))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _glassSheen(Canvas c, List<Offset> pane, {double opacity = .82}) {
    // Pane order: upper-left, upper-right, lower-right, lower-left.
    final band = [
      Offset.lerp(pane[0], pane[3], .1)!,
      Offset.lerp(pane[1], pane[2], .1)!,
      Offset.lerp(pane[1], pane[2], .34)!,
      Offset.lerp(pane[0], pane[3], .34)!,
    ];
    c.drawPath(
      _poly(band),
      _paint(const Color(0xffc9f0ed).withValues(alpha: .66 * opacity)),
    );
    final glintStart = Offset.lerp(pane[0], pane[3], .43)!;
    final glintEnd = Offset.lerp(pane[1], pane[2], .43)!;
    c.drawLine(
      glintStart,
      glintEnd,
      _paint(const Color(0xfff4ffed).withValues(alpha: .52 * opacity))
        ..strokeWidth = 1.25,
    );
  }

  void _residentialExterior(Canvas c) {
    if (ResidentialLayout.unitAt(
          session.campaign.floor,
          Offset(session.campaign.x, session.campaign.y),
        ) !=
        null) {
      return;
    }
    final inside = ResidentialLayout.corridor.contains(
      Offset(session.campaign.x, session.campaign.y),
    );
    if (inside) {
      // The corridor is already the current floor. Drawing a whole building
      // here adds a roof over the hall and makes the floor look disconnected.
      return;
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
    // Exterior panels share the same floor anchors as the interior walls.
    // Clipping keeps facade texture behind openings and balcony details.
    for (final east in [true, false]) {
      final texture =
          _sprites[east ? 'kit_wall_exterior_east' : 'kit_wall_exterior_west'];
      if (texture == null) continue;
      final a = east ? left : right, z = east ? right : back;
      c.save();
      c.clipPath(_poly([a, z, z - const Offset(0, h), a - const Offset(0, h)]));
      for (var level = 0; level < 4; level++) {
        for (var segment = 0; segment < (east ? 11 : 4); segment++) {
          final anchor =
              (east ? iso(2 + segment * 2, 10) : iso(24, 10 - segment * 2)) -
              Offset(0, level * 62.0);
          c.drawImageRect(
            texture,
            const Rect.fromLTWH(0, 0, 80, 112),
            Rect.fromLTWH(
              anchor.dx - 8,
              anchor.dy - (east ? 72 : 104),
              80,
              112,
            ),
            Paint()..filterQuality = FilterQuality.none,
          );
        }
      }
      c.restore();
    }
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
      for (final window in ResidentialLayout.windows.where(
        (window) => window.floor == floor,
      )) {
        _frontWindow(
          c,
          iso(window.center.dx, window.center.dy) - Offset(0, rise + 20),
          open: session.world.windowIsOpen(window.id),
          id: window.id,
        );
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
    const width = 1.8;
    // The leaf and frame share the same opening geometry on both sides of a
    // doorway; cutting the wall must never shrink the actual door panel.
    final height = door.leafHeight;
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
      a - Offset(0, height + 5),
      _paint(const Color(0xffba9b70))..strokeWidth = 5,
    );
    c.drawLine(
      b,
      b - Offset(0, height + 5),
      _paint(const Color(0xffba9b70))..strokeWidth = 5,
    );
    c.drawLine(
      a - Offset(0, height + 5),
      b - Offset(0, height + 5),
      _paint(const Color(0xffba9b70))..strokeWidth = 5,
    );
    final q = iso(x + math.cos(angle) * width, y - math.sin(angle) * width);
    c.drawPath(
      _poly([a, q, q - Offset(0, height), a - Offset(0, height)]),
      _paint(const Color(0xff715037)),
    );
    for (var i = 1; i < 5; i++) {
      final p = Offset.lerp(a, q, i / 5)!;
      c.drawLine(
        p - const Offset(0, 3),
        p - Offset(0, height - 3),
        _paint(const Color(0xff8d6543))..strokeWidth = 1,
      );
    }
    final handle = Offset.lerp(a, q, .82)! - Offset(0, height * .5);
    c.drawCircle(handle, 2.2, _paint(const Color(0xffe4bf77)));
    final plaqueCenter =
        Offset.lerp(a, q, .5)! - Offset(0, math.max(5, height * .72));
    final plaque = Rect.fromCenter(
      center: plaqueCenter,
      width: id == 'entrada'
          ? 38
          : id == 'banheiro'
          ? 18
          : 22,
      height: 10,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(plaque, const Radius.circular(1)),
      _paint(const Color(0xff392d24)),
    );
    _text(
      c,
      id == 'entrada'
          ? 'ENTRADA'
          : id == 'banheiro'
          ? 'WC'
          : id,
      plaqueCenter,
      fontSize: id == 'entrada' ? 5 : 6,
      color: amber,
    );
  }

  void _staircase(Canvas c, Offset position, bool ascending) {
    final shaft = _poly([
      iso(position.dx - .7, position.dy),
      iso(position.dx + .7, position.dy),
      iso(position.dx + .7, position.dy + 1.8),
      iso(position.dx - .7, position.dy + 1.8),
    ]);
    c.drawPath(shaft, _paint(const Color(0xff283735)));
    c.save();
    if (!ascending) c.clipPath(shaft);
    if (ascending) {
      for (final x in [position.dx - .7, position.dx + .7]) {
        final back = iso(x, position.dy), front = iso(x, position.dy + 1.8);
        c.drawPath(
          _poly([back, front, back - const Offset(0, 35)]),
          _paint(const Color(0xff7d8276)),
        );
      }
    }
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
      c.drawPath(
        _poly([e, d, d + const Offset(0, 5), e + const Offset(0, 5)]),
        _paint(const Color(0xff56635b)),
      );
      c.drawLine(e, d, _paint(const Color(0xffadb1a0))..strokeWidth = 1);
    }
    c.restore();
    for (final side in [-.8, .8]) {
      final a = iso(position.dx + side, position.dy) - const Offset(0, 35),
          b =
              iso(position.dx + side, position.dy + 1.8) +
              Offset(0, ascending ? -35 : 0);
      c.drawLine(a, b, _paint(const Color(0xffb3aa91))..strokeWidth = 3);
      c.drawLine(
        a,
        a + const Offset(0, 5),
        _paint(const Color(0xffb3aa91))..strokeWidth = 2,
      );
      c.drawLine(
        b,
        b + const Offset(0, 5),
        _paint(const Color(0xffb3aa91))..strokeWidth = 2,
      );
    }
  }

  void _elevator(Canvas c, Offset position) {
    final texture = _sprites['kit_elevator'];
    if (texture != null) {
      final p = iso(position.dx, position.dy);
      c.drawImageRect(
        texture,
        const Rect.fromLTWH(0, 0, 128, 144),
        Rect.fromLTWH(p.dx - 38, p.dy - 78, 80, 90),
        Paint()..filterQuality = FilterQuality.none,
      );
      _text(
        c,
        'MANUTENÇÃO',
        p - const Offset(0, 48),
        fontSize: 7,
        color: amber,
        backing: true,
      );
      return;
    }
    final p = iso(position.dx, position.dy);
    c.drawOval(
      Rect.fromCenter(center: p + const Offset(0, 2), width: 48, height: 16),
      _paint(const Color(0x3b152021)),
    );
    final frame = Rect.fromLTWH(p.dx - 23, p.dy - 61, 46, 61);
    c.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(3)),
      _paint(const Color(0xff4e544e)),
    );
    final doors = frame.deflate(4);
    c.drawRect(doors, _paint(const Color(0xff33464a)));
    c.drawRect(
      Rect.fromLTRB(doors.left + 1, doors.top + 1, p.dx - 1, doors.bottom - 1),
      _paint(const Color(0xff66716d)),
    );
    c.drawRect(
      Rect.fromLTRB(p.dx + 1, doors.top + 1, doors.right - 1, doors.bottom - 1),
      _paint(const Color(0xff596661)),
    );
    c.drawLine(
      Offset(p.dx, doors.top + 2),
      Offset(p.dx, doors.bottom - 2),
      _paint(const Color(0xff29383a))..strokeWidth = 2,
    );
    c.drawCircle(Offset(p.dx + 14, p.dy - 31), 1.5, _paint(amber));
    final indicator = Rect.fromLTWH(p.dx - 12, p.dy - 76, 24, 12);
    c.drawRRect(
      RRect.fromRectAndRadius(indicator, const Radius.circular(2)),
      _paint(const Color(0xff273538)),
    );
    _text(c, '2', p - const Offset(0, 72), fontSize: 8, color: amber);
    final servicePlate = Rect.fromCenter(
      center: p - const Offset(0, 38),
      width: 31,
      height: 10,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(servicePlate, const Radius.circular(1)),
      _paint(const Color(0xff283638)),
    );
    _text(c, 'MANUT.', p - const Offset(0, 36), fontSize: 5, color: amber);
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
      _glassSheen(c, [
        window[3],
        window[2],
        window[1],
        window[0],
      ], opacity: .88);
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
      final motif = iso(5.85, 6.85);
      final medallion = [
        motif + const Offset(0, -12),
        motif + const Offset(23, 0),
        motif + const Offset(0, 12),
        motif + const Offset(-23, 0),
      ];
      c.drawPath(
        _poly(medallion),
        Paint()
          ..color = const Color(0xffc2ab78)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      c.drawCircle(motif, 3, _paint(const Color(0xffc2ab78)));
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
    final refinedSource = furniture.sprite == null
        ? null
        : _refinedSources[furniture.sprite];
    final refinedAtlas = _sprites['apartment_refined'];
    if (session.campaign.floor == 2 &&
        refinedSource != null &&
        refinedAtlas != null) {
      final width = (b.width + b.height) * 32;
      final height = width * refinedSource.height / refinedSource.width;
      final center = iso(b.center.dx, b.center.dy);
      final bottom = iso(b.right, b.bottom).dy;
      c.drawOval(
        Rect.fromCenter(
          center: center + const Offset(0, 4),
          width: width * .72,
          height: 14,
        ),
        _paint(const Color(0x38201913)),
      );
      final actor = iso(session.campaign.x, session.campaign.y) -
          const Offset(0, 35);
      final destination = Rect.fromLTWH(
        center.dx - width / 2,
        bottom - height,
        width,
        height,
      );
      c.drawImageRect(
        refinedAtlas,
        refinedSource,
        destination,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Color.fromRGBO(
            255,
            255,
            255,
            destination.contains(actor) &&
                    session.campaign.x + session.campaign.y <
                        b.right + b.bottom
                ? .45
                : 1,
          ),
      );
      return;
    }
    final packSpriteKey = switch (kind) {
      'bus_shelter' => 'pack_bus_shelter',
      'bus_stop_sign' => 'pack_bus_stop_sign',
      'bench' => 'street_bench',
      'street_tree' => 'street_tree',
      'street_tree_autumn' => 'street_tree_autumn',
      _ => null,
    };
    final packSprite = packSpriteKey == null ? null : _sprites[packSpriteKey];
    if (packSprite != null) {
      final visualScale = switch (kind) {
        'bus_stop_sign' => 1.7,
        'bench' => 1.15,
        'street_tree' || 'street_tree_autumn' => 1.28,
        _ => 1.0,
      };
      final width = kind == 'bus_stop_sign'
          ? 56.0
          : (b.width + b.height) * 32 * visualScale;
      final height = width * packSprite.height / packSprite.width;
      final center = iso(b.center.dx, b.center.dy);
      final baseline = iso(b.right, b.bottom).dy;
      c.drawOval(
        Rect.fromCenter(
          center: center + const Offset(0, 3),
          width: width * .7,
          height: 8,
        ),
        _paint(const Color(0x38201913)),
      );
      c.drawImageRect(
        packSprite,
        Rect.fromLTWH(
          0,
          0,
          packSprite.width.toDouble(),
          packSprite.height.toDouble(),
        ),
        Rect.fromLTWH(center.dx - width / 2, baseline - height, width, height),
        Paint()..filterQuality = FilterQuality.medium,
      );
      return;
    }
    final modular = switch (kind) {
      'fridge' => 'kit_fridge',
      'shelf' => 'kit_shop_shelf',
      'counter' => 'kit_counter',
      'bench' => 'kit_bench',
      _ => null,
    };
    if (modular != null && _kitBounds[modular] != null) {
      final source = _kitBounds[modular]!;
      final width = (b.width + b.height) * 32;
      final height = h + (b.width + b.height) * 16;
      final center = iso(b.center.dx, b.center.dy),
          bottom = iso(b.right, b.bottom).dy;
      c.drawOval(
        Rect.fromCenter(center: center, width: width * .7, height: 10),
        _paint(const Color(0x40202c27)),
      );
      c.drawImageRect(
        _sprites[modular]!,
        source,
        Rect.fromLTWH(center.dx - width / 2, bottom - height, width, height),
        Paint()..filterQuality = FilterQuality.none,
      );
      return;
    }
    final fixtureName = switch (kind) {
      'toilet' => 'bathroom_toilet',
      'basin' => 'bathroom_vanity',
      'shower' => 'bathroom_shower',
      _ => null,
    };
    if (session.campaign.floor == 2 && fixtureName != null) {
      final image = _sprites[fixtureName]!;
      final width = (b.width + b.height) * 32 * .62;
      final height = width * image.height / image.width;
      final center = iso(b.center.dx, b.center.dy);
      final bottom = iso(b.right, b.bottom).dy;
      c.drawOval(
        Rect.fromCenter(
          center: center + const Offset(0, 3),
          width: width * .7,
          height: 9,
        ),
        _paint(const Color(0x38201913)),
      );
      c.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(center.dx - width / 2, bottom - height, width, height),
        Paint()..filterQuality = FilterQuality.medium,
      );
      return;
    }
    final source = _furnitureSources[kind];
    if (session.campaign.floor == 2 && source != null) {
      final image = _sprites['apartment_furniture']!;
      // The footprint already represents the object's isometric ground size;
      // avoid inflating the sprite into nearby walls and furniture.
      final width = (b.width + b.height) * 32;
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
    const views = ['front_left', 'front_right', 'side', 'rear_three_quarter'];
    final view = views[vehicle.view.clamp(0, 3).toInt()];
    final image = open
        ? _sprites['vehicle_${vehicle.id}_open']!
        : _sprites['vehicle_${vehicle.id}_$view'] ??
              _sprites['vehicle_${vehicle.id}_closed']!;
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
      case PointKind.broadcast:
        final base = iso(place.x, place.y - .7);
        final image = _sprites['kit_broadcast'];
        if (image != null) {
          c.drawImageRect(
            image,
            const Rect.fromLTWH(0, 0, 256, 240),
            Rect.fromLTWH(base.dx - 102.4, base.dy - 179.2, 204.8, 192),
            Paint()..filterQuality = FilterQuality.none,
          );
          c.save();
          c.translate(base.dx - 102.4 + 121 * .8, base.dy - 179.2 + 86 * .8);
          c.transform(
            Float64List.fromList([
              1,
              .5,
              0,
              0,
              0,
              1,
              0,
              0,
              0,
              0,
              1,
              0,
              0,
              0,
              0,
              1,
            ]),
          );
          _text(
            c,
            session.campaign.inChapterTwo
                ? 'SITUAÇÃO SOB\nCONTROLE'
                : 'MANUTENÇÃO\nHOJE · 02:00',
            Offset.zero,
            fontSize: 10,
            color: const Color(0xffc4e0cc),
          );
          c.restore();
        }
      case PointKind.nightTorch:
      case PointKind.nightSupply:
      case PointKind.nightPanel:
      case PointKind.nightNeighbor:
      case PointKind.nightBreaker:
      case PointKind.nightCan:
      case PointKind.nightMap:
        final key = switch (place.kind) {
          PointKind.nightTorch => 'kit_flashlight',
          PointKind.nightSupply || PointKind.nightNeighbor => 'kit_bandage',
          PointKind.nightPanel || PointKind.nightBreaker => 'kit_breaker',
          PointKind.nightCan => 'kit_can',
          _ => 'kit_map',
        };
        final sprite = _sprites[key];
        if (sprite != null) {
          final height = 28.0 * sprite.height / sprite.width;
          c.drawImageRect(
            sprite,
            Rect.fromLTWH(
              0,
              0,
              sprite.width.toDouble(),
              sprite.height.toDouble(),
            ),
            Rect.fromLTWH(p.dx - 14, p.dy - height, 28, height),
            Paint()..filterQuality = FilterQuality.none,
          );
        }
        if (place.kind == PointKind.nightCan &&
            !session.campaign.has('chapter2_alarm_off')) {
          final center = iso(19, 13);
          final radius = 20 + (session.elapsed % 1.5) * 35;
          c.drawOval(
            Rect.fromCenter(center: center, width: radius * 2, height: radius),
            Paint()
              ..color = amber.withValues(alpha: .45)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
          _text(
            c,
            session.campaign.has('chapter2_lured') ? 'DISTRAÇÃO' : 'ALARME',
            center - const Offset(0, 65),
            fontSize: 8,
            color: amber,
            backing: true,
          );
        }
      case PointKind.apartmentDoor:
        _apartmentDoor(c);
      case PointKind.buildingDoor:
        _apartmentDoor(c, place.id!);
      case PointKind.window:
        _frontWindow(
          c,
          // Coordinates in this pass already belong to the active floor.
          p - const Offset(0, 20),
          open: session.world.windowIsOpen(place.id!),
          id: place.id,
        );
      case PointKind.stairsDown:
        _staircase(c, Offset(place.x, place.y - .5), false);
      case PointKind.stairsUp:
        _staircase(c, Offset(place.x, place.y - .5), true);
      case PointKind.elevator:
        _elevator(c, Offset(place.x, place.y));
      case PointKind.bus:
        // The physical, collision-backed bus stop sign is drawn as street
        // furniture beside this objective marker.
        break;

      case PointKind.television:
        _prop(c, 3, p, 48);
      case PointKind.panel:
        _prop(c, 2, p, 32);
      case PointKind.adapter:
      case PointKind.key:
      case PointKind.water:
      case PointKind.weapon:
        final name = place.kind == PointKind.adapter
            ? 'adapter'
            : place.kind == PointKind.key
            ? 'key'
            : place.kind == PointKind.weapon
            ? 'weapon'
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
        for (final side in [-7.0, 7.0]) {
          c.drawLine(
            a + Offset(side, 0),
            a + Offset(side, -60),
            _paint(teal)..strokeWidth = 3,
          );
        }
        for (var i = 0; i < 8; i++) {
          c.drawLine(
            a + Offset(-7, -i * 8.0),
            a + Offset(7, -i * 8.0),
            _paint(amber)..strokeWidth = 2,
          );
        }
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
    if (place.floor == 0 &&
        WorldModel.shopBounds.contains(Offset(place.x, place.y)) &&
        !session.world.inShop) {
      return;
    }
    final nearest = session.world.nearby;
    final selected =
        nearest != null && nearest.kind == place.kind && nearest.id == place.id;
    final label = place.floatingLabel;
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
    if (near && selected && label != null && session.world.resting == null) {
      _text(
        c,
        label.toUpperCase(),
        p - const Offset(0, 55),
        fontSize: 8,
        color: amber,
        backing: true,
      );
    }
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
    Offset strideAxis = const Offset(1, 0),
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
        c.translate(
          pivot.dx + strideAxis.dx * stride,
          pivot.dy + strideAxis.dy * stride - lift,
        );
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
        // The supplied frames have their sole at source y=119.
        const Rect.fromLTWH(-40, -74.375, 80, 80),
        paint,
      );
    }
    c.restore();
  }

  bool _actorAtlas(
    Canvas c,
    String name,
    String state,
    Offset position,
    double dx,
    double dy, {
    double travelled = 0,
    double progress = 0,
    double scale = 1,
    bool reverse = false,
  }) {
    final image = _sprites['actor_${name}_$state'];
    if (image == null) return false;
    var frame = ActorFrames.frame(
      state,
      actor: name,
      travelled: travelled,
      time: session.world.simulationTime,
      progress: progress,
    );
    if (reverse) frame = ActorFrames.count(state, actor: name) - 1 - frame;
    c.drawImageRect(
      image,
      ActorFrames.source(frame, ActorFrames.direction(dx, dy)),
      Rect.fromLTWH(
        position.dx - 40 * scale,
        position.dy - 74.375 * scale,
        80 * scale,
        90 * scale,
      ),
      Paint()..filterQuality = FilterQuality.none,
    );
    return true;
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
      if (_actorAtlas(
        c,
        name,
        motion.moving ? 'walk' : 'idle',
        p,
        facing.dx,
        facing.dy,
        travelled: motion.traveled,
        scale: name == 'bia' ? .83 : 1.0,
      )) {
        return;
      }
      final mirror = facing.dx - facing.dy > .1;
      final projected = Offset(
        facing.dx - facing.dy,
        (facing.dx + facing.dy) * .5,
      );
      final strideAxis = projected.distance < .001
          ? const Offset(1, 0)
          : Offset(projected.dx * (mirror ? -1 : 1), projected.dy) /
                projected.distance;
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
        strideAxis: strideAxis,
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
      if (threat) {
        c.rotate(-.09);
      } else if (session.world.enemyStun > 0) {
        c.rotate(.1);
      }
      final state = threat
          ? 'attack'
          : session.world.enemyStun > 0
          ? 'hurt'
          : _enemyActuallyMoving
          ? 'walk'
          : 'idle';
      final progress = threat
          ? 1 - session.world.attackWindup / .65
          : session.world.enemyStun > 0
          ? 1 - session.world.enemyStun / 1.2
          : 0.0;
      final gear = EquipmentPose.sample(
        direction: ActorFrames.direction(dx, dy),
        state: state,
        progress: progress,
      );
      final armed = session.campaign.inChapterTwo;
      if (armed && gear.behindBody) {
        _heldWeapon(
          c,
          Offset.zero,
          gear,
          spriteKey: 'gear_pipe',
          gripColor: const Color(0xff76503b),
        );
      }
      if (!_actorAtlas(
        c,
        session.world.enemyIdentity,
        state,
        Offset.zero,
        dx,
        dy,
        travelled: session.world.enemyWalked,
        progress: progress,
      )) {
        if (dx - dy > .1) c.scale(-1, 1);
        _drawActorRig(c, _sprites['phase_davi']!, rig);
      }
      if (armed && !gear.behindBody) {
        _heldWeapon(
          c,
          Offset.zero,
          gear,
          spriteKey: 'gear_pipe',
          gripColor: const Color(0xff76503b),
        );
      }
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
    if ((rest == 'sit' || rest == 'lie') &&
        session.world.restAnchor != null) {
      final anchor = session.world.restAnchor!;
      final asset = rest == 'lie'
          ? 'caio_deitado_cama'
          : anchor.dx < 5
          ? 'caio_sentado_sofa'
          : 'caio_sentado_cadeira';
      final source = _refinedSources[asset];
      final atlas = _sprites['apartment_refined'];
      if (source != null && atlas != null) {
        final height = 112.0;
        final width = height * source.width / source.height;
        final at = iso(anchor.dx, anchor.dy);
        c.drawImageRect(
          atlas,
          source,
          Rect.fromLTWH(at.dx - width / 2, at.dy - height, width, height),
          Paint()..filterQuality = FilterQuality.medium,
        );
        return;
      }
    }
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
    final fast = session.world.effectiveRunning;
    final facing = SpriteFacing.fromWorld(dx, dy, running: moving && fast);
    final action = session.phase == PlayPhase.defeated
        ? 'defeat'
        : session.world.action;
    var state = 'idle';
    if (action == 'push' || action == 'attack') {
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
    final atlasState = action == 'attack' || action == 'push'
        ? 'attack'
        : action == 'hurt'
        ? 'hurt'
        : action == 'block'
        ? 'guard'
        : state == 'idle'
        ? (moving
              ? (session.world.guarding || session.world.aiming
                    ? 'guard_walk'
                    : fast
                    ? 'run'
                    : 'walk')
              : session.world.aiming || session.world.guarding
              ? 'guard'
              : 'idle')
        : null;
    final progress = session.world.actionDuration > 0
        ? 1 - session.world.actionTime / session.world.actionDuration
        : 0.0;
    final gearState = atlasState ?? 'idle';
    final gear = EquipmentPose.sample(
      direction: ActorFrames.direction(dx, dy),
      state: gearState,
      progress: progress,
    );
    final hasHeldWeapon =
        session.campaign.has('weapon') &&
        session.campaign.weaponEquipped &&
        !['pickup', 'heal', 'drink', 'climb', 'defeat'].contains(action);
    if (hasHeldWeapon && gear.behindBody) _heldWeapon(c, p, gear);
    if (atlasState == null ||
        !_actorAtlas(
          c,
          session.campaign.backpackEquipped ? 'caio' : 'caio_nobag',
          atlasState,
          p,
          dx,
          dy,
          travelled: session.world.walked,
          progress: progress,
          reverse:
              (session.world.aiming || session.world.guarding) &&
              session.world.inputX * dx + session.world.inputY * dy < 0,
        )) {
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
        // These are complete authored frames, not a skin for the NPC rig.
        // Slicing and rotating them again deforms the legs and doubles the gait.
        locomotion: false,
      );
      c.restore();
    }
    if (hasHeldWeapon && !gear.behindBody) _heldWeapon(c, p, gear);
    if (session.world.pushCooldown > .4) {
      c.drawOval(
        Rect.fromCenter(center: p, width: 105, height: 52),
        Paint()
          ..color = const Color(0x99c2b58c)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _heldWeapon(
    Canvas c,
    Offset sole,
    EquipmentPose pose, {
    String spriteKey = 'item_weapon',
    Color gripColor = const Color(0xffb4855b),
  }) {
    final sprite = _sprites[spriteKey];
    if (sprite == null) return;
    c.save();
    c.translate(sole.dx + pose.hand.dx, sole.dy + pose.hand.dy);
    c.rotate(pose.angle + math.pi / 4);
    final legacy = spriteKey == 'item_weapon';
    final side = legacy ? 32.0 : 64.0;
    final target = legacy
        ? const Rect.fromLTWH(-5.25, -18.75, 24, 24)
        : const Rect.fromLTWH(-9.6, -30, 38.4, 38.4);
    c.drawImageRect(
      sprite,
      Rect.fromLTWH(0, 0, side, side),
      target,
      Paint()..filterQuality = FilterQuality.none,
    );
    // A small closed grip covers the attachment, including in hurt poses.
    c.drawOval(const Rect.fromLTWH(-2, -2, 4, 4), _paint(gripColor));
    c.restore();
  }

  void _downedEnemy(Canvas c) {
    final world = session.world;
    final p = iso(world.enemyX, world.enemyY);
    c.drawOval(
      Rect.fromCenter(center: p, width: 45, height: 16),
      _paint(const Color(0xff11191b).withValues(alpha: .48)),
    );
    final dx = session.campaign.x - world.enemyX;
    final dy = session.campaign.y - world.enemyY;
    c.save();
    c.translate(p.dx, p.dy - 19);
    c.rotate(math.pi / 2);
    _actorAtlas(
      c,
      world.enemyIdentity,
      'hurt',
      const Offset(0, 25),
      dx,
      dy,
      progress: 1,
      scale: .72,
    );
    c.restore();
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
