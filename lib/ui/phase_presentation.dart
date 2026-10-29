import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/world_model.dart';
import '../game/building_layout.dart';
import '../models/campaign.dart';

class ChapterMap extends CustomPainter {
  ChapterMap(this.campaign, this.world);
  final Campaign campaign;
  final WorldModel world;
  @override
  void paint(Canvas c, Size size) {
    final upstairs = campaign.floor > 0;
    final worldWidth = upstairs ? 26.0 : 56.0,
        worldHeight = upstairs ? 18.0 : 44.0;
    final scale = math.min(size.width / worldWidth, size.height / worldHeight);
    final origin = Offset((size.width - worldWidth * scale) / 2, 0);
    Offset point(double x, double y) => origin + Offset(x * scale, y * scale);
    Rect bounds(Rect b) => Rect.fromLTRB(
      point(b.left, b.top).dx,
      point(b.left, b.top).dy,
      point(b.right, b.bottom).dx,
      point(b.right, b.bottom).dy,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      Paint()..color = const Color(0xff233a40),
    );
    if (upstairs) {
      c.drawRect(
        bounds(ResidentialLayout.footprint),
        Paint()..color = const Color(0xff685e4b),
      );
    } else {
      c.drawRect(
        bounds(const Rect.fromLTRB(2, 16, 53, 40)),
        Paint()..color = const Color(0xff3e5554),
      );
      c.drawRect(
        bounds(const Rect.fromLTRB(12, 10, 23, 16)),
        Paint()..color = const Color(0xff52675e),
      );
    }
    for (final b in world.visibleBlocks) {
      c.drawRect(bounds(b.bounds), Paint()..color = const Color(0xff839789));
    }
    for (final v in world.visibleVehicles) {
      c.drawRect(bounds(v.bounds), Paint()..color = const Color(0xffa49b7a));
    }
    for (final wall in ResidentialLayout.partitions(campaign.floor)) {
      c.drawRect(bounds(wall), Paint()..color = const Color(0xffe1d7ba));
    }
    final route = upstairs
        ? [const Offset(7, 7), const Offset(7, 11), const Offset(10, 14.5)]
        : [
            const Offset(13.2, 15),
            const Offset(28, 25),
            const Offset(39, 29),
            const Offset(48, 28),
          ];
    final path = Path()
      ..moveTo(
        point(route.first.dx, route.first.dy).dx,
        point(route.first.dx, route.first.dy).dy,
      );
    for (final p in route.skip(1)) {
      path.lineTo(point(p.dx, p.dy).dx, point(p.dx, p.dy).dy);
    }
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xffa4cbb5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final entries = upstairs
        ? [
            for (final d in ResidentialLayout.doors.where(
              (d) => d.floor == campaign.floor && d.id != 'banheiro',
            ))
              (d.center.dx, 6.0, 'AP. ${d.id}'),
            (10.0, 14.5, 'Descer'),
            if (campaign.floor == 1) (4.7, 14.5, 'Subir'),
          ]
        : [
            (7.0, 16.0, 'Entrada residencial'),
            (19.0, 13.0, 'Garagem'),
            (28.0, 19.0, 'Mercearia'),
            (20.0, 33.0, 'Praça'),
            (39.0, 23.0, 'Beco'),
            (48.0, 34.0, 'Ônibus'),
          ];
    for (final entry in entries) {
      final text = TextPainter(
        text: TextSpan(
          text: entry.$3,
          style: const TextStyle(
            color: Color(0xfff1e7ce),
            fontSize: 10,
            backgroundColor: Color(0xaa172a32),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(c, point(entry.$1, entry.$2) - Offset(text.width / 2, 0));
    }
    for (final p in world.places) {
      c.drawCircle(
        point(p.x, p.y),
        2,
        Paint()..color = const Color(0xffe3b877),
      );
    }
    final p = point(campaign.x, campaign.y);
    c.drawCircle(p, 7, Paint()..color = const Color(0xff152a32));
    c.drawCircle(p, 4, Paint()..color = const Color(0xffd0f1dc));
  }

  @override
  bool shouldRepaint(covariant ChapterMap old) => true;
}

class OpeningArt extends CustomPainter {
  OpeningArt(this.time, this.page);
  final double time;
  final int page;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xff07151c), Color(0xff263d45)],
        ).createShader(Offset.zero & s),
    );
    final center = Offset(s.width * .58, s.height * .38);
    final shift = math.sin(time * .12) * 7;
    c.save();
    c.translate(shift, 0);
    final room = Path()
      ..moveTo(0, s.height * .65)
      ..lineTo(s.width * .5, s.height * .3)
      ..lineTo(s.width, s.height * .6)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(room, Paint()..color = const Color(0xff34494d));
    for (var i = 0; i < 8; i++) {
      c.drawLine(
        Offset(i * s.width / 7, s.height),
        center,
        Paint()
          ..color = const Color(0xff425859)
          ..strokeWidth = 1,
      );
    }
    final red = page < 4 ? const Color(0xffa76a56) : const Color(0xff799e8f);
    c.drawRect(
      Rect.fromCenter(
        center: center - const Offset(0, 55),
        width: 190,
        height: 90,
      ),
      Paint()..color = const Color(0xff11252b),
    );
    final trace = Path();
    for (var i = 0; i < 190; i++) {
      final x = center.dx - 95 + i,
          y =
              center.dy -
              55 +
              math.sin(i * .16 - time * 2) * 12 +
              math.sin(i * .41 + time) * 5;
      if (i == 0) {
        trace.moveTo(x, y);
      } else {
        trace.lineTo(x, y);
      }
    }
    c.drawPath(
      trace,
      Paint()
        ..color = red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    c.drawCircle(center + const Offset(130, -90), 16, Paint()..color = red);
    c.drawRect(
      Rect.fromCenter(
        center: center + const Offset(-85, 70),
        width: 125,
        height: 20,
      ),
      Paint()..color = const Color(0xff96a79d),
    );
    c.drawLine(
      center + const Offset(-130, 80),
      center + const Offset(-130, 130),
      Paint()
        ..color = const Color(0xff607e7c)
        ..strokeWidth = 7,
    );
    c.drawLine(
      center + const Offset(-40, 80),
      center + const Offset(-40, 130),
      Paint()
        ..color = const Color(0xff607e7c)
        ..strokeWidth = 7,
    );
    c.drawCircle(
      center + const Offset(-130, 15),
      13,
      Paint()..color = const Color(0xff13272e),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + const Offset(-130, 48),
          width: 29,
          height: 50,
        ),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xff13272e),
    );
    c.drawLine(
      Offset(s.width * .3, 0),
      Offset(s.width * .3, s.height * .7),
      Paint()
        ..color = const Color(0x577e9f9b)
        ..strokeWidth = 3,
    );
    c.restore();
  }

  @override
  bool shouldRepaint(covariant OpeningArt old) =>
      old.time != time || old.page != page;
}
