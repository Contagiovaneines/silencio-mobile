import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

import '../game/game_session.dart';
import 'game_preferences.dart';
import '../models/campaign.dart';

class GameAudio {
  bool _started = false, _enabled = false, _failed = false, _disposed = false;
  Future<void> _pending = Future.value();
  final Map<String, Future<AudioPool>> _pools = {};
  final Set<Future<void>> _effects = {};
  void update(GameSession session) {
    final preferences = GamePreferences(session.repository.preferences);
    final active =
        session.soundEnabled &&
        ![
          PlayPhase.menu,
          PlayPhase.menuSettings,
          PlayPhase.journey,
          PlayPhase.paused,
          PlayPhase.defeated,
        ].contains(session.phase);
    final wanted = active && preferences.musicEnabled;
    if (wanted != _enabled) {
      _enabled = wanted;
      _pending = _pending.then((_) async {
        if (_disposed) return;
        try {
          if (!_started && wanted) {
            await FlameAudio.bgm.initialize();
            await FlameAudio.bgm.play('rain.wav', volume: .18);
            _started = true;
          } else if (_started) {
            if (wanted) {
              await FlameAudio.bgm.resume();
            } else {
              await FlameAudio.bgm.pause();
            }
          }
        } catch (_) {
          if (!_failed) {
            _failed = true;
            session.tell(
              'O áudio não iniciou. Você pode continuar com as pistas visuais.',
            );
          }
        }
      });
    }
    final sounds = List<String>.of(session.world.sounds);
    session.world.sounds.clear();
    if (!active || !preferences.effectsEnabled || _disposed) return;
    for (final cue in sounds) {
      final effect = _play(cue);
      _effects.add(effect);
      unawaited(effect.whenComplete(() => _effects.remove(effect)));
    }
  }

  Future<void> _play(String cue) async {
    try {
      final pool = await _pools.putIfAbsent(
        cue,
        () => FlameAudio.createPool('$cue.wav', maxPlayers: 2),
      );
      if (!_disposed) await pool.start(volume: cue == 'step' ? .18 : .38);
    } catch (_) {
      /* Optional effect failure never blocks the simulation. */
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _pending;
    await Future.wait(List<Future<void>>.of(_effects));
    for (final future in _pools.values) {
      try {
        final pool = await future;
        await pool.dispose();
      } catch (_) {
        /* A pool that failed to initialize owns no active cue. */
      }
    }
    _pools.clear();
    if (_started) await FlameAudio.bgm.dispose();
  }
}
