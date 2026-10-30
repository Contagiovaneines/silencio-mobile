import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

import '../game/game_session.dart';
import '../services/game_preferences.dart';
import '../game/silencio_game.dart';
import '../game/world_model.dart';
import 'phase_presentation.dart';
import 'narrative_backdrop.dart';
import 'campaign_journey.dart';
import 'menu_atmosphere.dart';
import '../models/campaign.dart';

const mist = Color(0xffa2cbb8);
const parchment = Color(0xffe3e4d5);
const ochre = Color(0xffdfb477);

class GameShell extends StatefulWidget {
  const GameShell({super.key, required this.session, this.enableAudio = false});
  final bool enableAudio;
  final GameSession session;
  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final SilencioGame game;
  final focus = FocusNode();
  final keys = <LogicalKeyboardKey>{};
  int _mouseButtons = 0;
  void _pointerInput(PointerEvent event) {
    if (s.phase != PlayPhase.playing) {
      _mouseButtons = 0;
      s.world.endAim();
      return;
    }
    final primaryPressed =
        event.buttons & kPrimaryMouseButton != 0 &&
        _mouseButtons & kPrimaryMouseButton == 0;
    final secondaryHeld = event.buttons & kSecondaryMouseButton != 0;
    if (secondaryHeld) {
      game.aimAtScreen(event.localPosition);
      focus.requestFocus();
      if (primaryPressed) s.attack();
    } else if (_mouseButtons & kSecondaryMouseButton != 0) {
      s.world.endAim();
    }
    _mouseButtons = event.buttons;
  }

  bool _pauseSettings = false;
  GameSession get s => widget.session;
  late final GamePreferences preferences;
  late final AnimationController _menuMotion;
  bool _menuExtrasOpen = false;
  bool _editingControls = false;
  final Map<String, Offset> _controlAnchors = {};
  String tr(String pt, String en) => preferences.language == 'en' ? en : pt;
  void _preference(String key, bool value) {
    unawaited(preferences.setFlag(key, value));
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    preferences = GamePreferences(s.repository.preferences);
    game = SilencioGame(s, enableAudio: widget.enableAudio);
    _menuMotion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    s.addListener(_syncMenuMotion);
    _syncMenuMotion();
    WidgetsBinding.instance.addObserver(this);
  }

  void _syncMenuMotion() {
    if (s.phase == PlayPhase.menu && !s.reducedEffects) {
      if (!_menuMotion.isAnimating) _menuMotion.repeat();
    } else if (_menuMotion.isAnimating) {
      _menuMotion.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      keys.clear();
      s.pause();
      unawaited(s.save());
    }
  }

  void _keyboard(KeyEvent event) {
    final key = event.logicalKey;
    if (event is KeyUpEvent) {
      keys.remove(key);
    } else {
      keys.add(key);
    }
    if (event is KeyDownEvent) {
      if (key == LogicalKeyboardKey.escape && _pauseSettings) {
        setState(() => _pauseSettings = false);
        return;
      }
      if (key == LogicalKeyboardKey.escape) {
        if (s.phase == PlayPhase.opening) {
          s.finishOpening();
        } else if (s.phase == PlayPhase.playing) {
          s.pause();
        } else if ([
          PlayPhase.paused,
          PlayPhase.journal,
          PlayPhase.map,
          PlayPhase.objectPanel,
          PlayPhase.menuSettings,
          PlayPhase.journey,
        ].contains(s.phase)) {
          s.closePanel();
        }
      }
      if (s.phase == PlayPhase.playing) {
        if (key == LogicalKeyboardKey.keyE) s.interact();
        if (key == LogicalKeyboardKey.space) s.push();
        if (key == LogicalKeyboardKey.keyF) s.attack();
        if (key == LogicalKeyboardKey.keyV) s.toggleGuard();
        if (key == LogicalKeyboardKey.keyB) s.vault();
        if (key == LogicalKeyboardKey.keyQ) s.togglePerception();
        if (key == LogicalKeyboardKey.keyJ) s.journal();
        if (key == LogicalKeyboardKey.keyM) s.map();
        if (key == LogicalKeyboardKey.keyP) s.phone();
        if (key == LogicalKeyboardKey.keyR) s.toggleRun();
      } else if (s.phase == PlayPhase.opening &&
          key == LogicalKeyboardKey.enter) {
        s.nextOpening();
      } else if (s.phase == PlayPhase.opening &&
          key == LogicalKeyboardKey.arrowLeft) {
        s.previousOpening();
      } else if (s.phase == PlayPhase.dialogue &&
          key == LogicalKeyboardKey.enter) {
        s.nextLine();
      }
    }
    if (s.phase != PlayPhase.playing) return;
    s.world.sprintHeld =
        keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight);
    double axis(LogicalKeyboardKey a, LogicalKeyboardKey b) =>
        keys.contains(a) || keys.contains(b) ? 1 : 0;
    final dx =
        axis(LogicalKeyboardKey.keyD, LogicalKeyboardKey.arrowRight) -
        axis(LogicalKeyboardKey.keyA, LogicalKeyboardKey.arrowLeft);
    final dy =
        axis(LogicalKeyboardKey.keyS, LogicalKeyboardKey.arrowDown) -
        axis(LogicalKeyboardKey.keyW, LogicalKeyboardKey.arrowUp);
    s.world.setInput(dx + dy * 2, -dx + dy * 2);
  }

  void _resume() {
    s.resume();
    focus.requestFocus();
  }

  Future<void> _start() async {
    if (s.hasSave) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr('Começar de novo?', 'Start again?')),
          content: Text(
            tr(
              'O progresso atual será substituído.',
              'Current progress will be replaced.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('Voltar', 'Back')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('Nova exploração', 'New game')),
            ),
          ],
        ),
      );
      if (accepted != true) return;
    }
    s.startNew();
    focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: KeyboardListener(
      focusNode: focus,
      autofocus: true,
      onKeyEvent: _keyboard,
      child: AnimatedBuilder(
        animation: s,
        builder: (context, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.textScalerOf(context).scale(1) *
                  (s.largerText ? 1.18 : 1),
            ),
            disableAnimations: s.reducedEffects,
            highContrast: preferences.highContrast,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                ignoring: s.phase != PlayPhase.playing,
                child: Listener(
                  onPointerDown: _pointerInput,
                  onPointerMove: _pointerInput,
                  onPointerUp: _pointerInput,
                  onPointerCancel: (_) {
                    _mouseButtons = 0;
                    s.world.endAim();
                  },
                  child: GestureDetector(
                    onTapDown: (d) {
                      game.tapGround(d.localPosition);
                      focus.requestFocus();
                    },
                    child: GameWidget(game: game, autofocus: false),
                  ),
                ),
              ),
              if (s.phase == PlayPhase.menu) _menu(),
              if (s.phase == PlayPhase.menuSettings) _settings(),
              if (s.phase == PlayPhase.journey) _journey(),
              if (s.phase == PlayPhase.opening) _opening(),
              if (s.phase == PlayPhase.map) _map(),
              if (s.phase == PlayPhase.pulse) _pulse(),
              if (s.phase == PlayPhase.transit) _transit(),
              if (s.phase == PlayPhase.buildingTransition)
                _buildingTransition(),
              if (s.phase == PlayPhase.playing) ...[_hud(), _controls()],
              if (s.phase == PlayPhase.objectPanel) _objectPanel(),
              if (s.phase == PlayPhase.dialogue) _dialogue(),
              if (s.phase == PlayPhase.news) _news(),
              if (s.phase == PlayPhase.journal) _journal(),
              if (s.phase == PlayPhase.paused)
                _pauseSettings ? _settings(fromPause: true) : _pause(),
              if (s.phase == PlayPhase.complete) _complete(),
              if (s.phase == PlayPhase.defeated) _defeated(),
              if (s.notice.isNotEmpty && s.phase == PlayPhase.playing)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.sizeOf(context).width < 600 ? 300 : 96,
                  child: IgnorePointer(
                    child: Center(
                      child: ConstrainedBox(
                        key: const Key('game-notice'),
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _glass(
                            Padding(
                              padding: const EdgeInsets.all(9),
                              child: Text(
                                s.notice,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: parchment,
                                  fontSize: 11,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _menu() => LayoutBuilder(
    builder: (context, viewport) {
      final wide =
          viewport.maxWidth >= 700 &&
          viewport.maxHeight >= 360 &&
          viewport.maxWidth >= viewport.maxHeight * 1.35;
      final portrait = viewport.maxWidth < 600;
      final motion = s.reducedEffects ? 0.0 : _menuMotion.value;
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/menu_santa_aurora_v2.png',
            fit: BoxFit.cover,
            alignment: portrait ? Alignment.centerRight : Alignment.topCenter,
            filterQuality: FilterQuality.medium,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xf20a121b),
                  Color(0xd50a121b),
                  Color(0x740a121b),
                  Color(0x160a121b),
                ],
                stops: [0, .34, .66, 1],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xe9081119), Color(0x00081119)],
                stops: [0, .58],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _menuMotion,
            builder: (context, _) => CustomPaint(
              painter: MenuAtmospherePainter(
                progress: s.reducedEffects ? 0 : _menuMotion.value,
                reducedMotion: s.reducedEffects,
              ),
            ),
          ),
          Positioned(
            right: portrait ? -32 : viewport.maxWidth * .025,
            bottom: portrait ? 94 : 0,
            width: portrait ? viewport.maxWidth * .66 : viewport.maxWidth * .43,
            height: portrait
                ? viewport.maxHeight * .40
                : viewport.maxHeight * .82,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _menuMotion,
                builder: (context, child) => Opacity(
                  opacity: portrait ? .42 : .92,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      s.reducedEffects
                          ? 0
                          : math.sin(motion * math.pi * 2) * 2.2,
                    ),
                    child: child,
                  ),
                ),
                child: Image.asset(
                  'assets/images/menu_caio_foreground_v1.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                portrait ? 18 : 36,
                portrait ? 14 : 24,
                portrait ? 18 : 30,
                portrait ? 14 : 20,
              ),
              child: wide
                  ? Row(
                      key: const Key('menu-wide-layout'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: math.min(410, viewport.maxWidth * .38),
                          child: SingleChildScrollView(
                            child: _menuMainColumn(
                              compact: viewport.maxWidth < 1100,
                              wide: true,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: _weatherCard(
                                  compact: viewport.maxWidth < 1100,
                                ),
                              ),
                              if (viewport.maxWidth >= 1100)
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 960,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Row(
                                        children: [
                                          Expanded(child: _cityCard()),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _featureCard(
                                              Icons.back_hand_outlined,
                                              tr(
                                                'COMUNICAÇÃO',
                                                'COMMUNICATION',
                                              ),
                                              tr(
                                                'Libras e celular',
                                                'Signs and phone',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _featureCard(
                                              Icons.inventory_2_outlined,
                                              tr('SOBREVIVÊNCIA', 'SURVIVAL'),
                                              tr(
                                                'Recursos e inventário',
                                                'Resources and inventory',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _featureCard(
                                              Icons.search_rounded,
                                              tr(
                                                'INVESTIGAÇÃO',
                                                'INVESTIGATION',
                                              ),
                                              tr(
                                                'Descubra a verdade',
                                                'Find the truth',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (portrait) _weatherCard(compact: true),
                          _menuMainColumn(compact: portrait, wide: false),
                          const SizedBox(height: 18),
                          _cityCard(),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _smallFeature(
                                Icons.back_hand_outlined,
                                tr('COMUNICAÇÃO', 'COMMUNICATION'),
                                tr('Libras e celular', 'Signs and phone'),
                              ),
                              _smallFeature(
                                Icons.inventory_2_outlined,
                                tr('SOBREVIVÊNCIA', 'SURVIVAL'),
                                tr(
                                  'Recursos e inventário',
                                  'Resources and inventory',
                                ),
                              ),
                              _smallFeature(
                                Icons.search_rounded,
                                tr('INVESTIGAÇÃO', 'INVESTIGATION'),
                                tr('Descubra a verdade', 'Find the truth'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (_menuExtrasOpen)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xb900060c),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: _glass(
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              tr('Extras', 'Extras'),
                              style: const TextStyle(
                                color: parchment,
                                fontSize: 25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tr(
                                'Acompanhe sua jornada e reveja a abertura.',
                                'Review your journey and watch the opening again.',
                              ),
                              style: const TextStyle(color: mist, height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _menuExtrasOpen = false);
                                s.journey();
                              },
                              icon: const Icon(Icons.route_outlined),
                              label: Text(tr('Jornada', 'Journey')),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _menuExtrasOpen = false);
                                s.replay();
                              },
                              icon: const Icon(Icons.movie_outlined),
                              label: Text(
                                tr(
                                  'Reassistir à abertura',
                                  'Watch opening again',
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _menuExtrasOpen = false),
                              child: Text(tr('Voltar', 'Back')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _menuMainColumn({required bool compact, required bool wide}) {
    final dense = compact && wide;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          tr(
            'UM JOGO SOBRE O QUE AINDA É HUMANO',
            'A GAME ABOUT WHAT REMAINS HUMAN',
          ),
          style: const TextStyle(color: mist, fontSize: 9, letterSpacing: 2),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'SILÊNCIO',
            style: TextStyle(
              fontSize: dense ? 38 : (compact ? 50 : (wide ? 66 : 58)),
              height: 1.04,
              letterSpacing: compact ? 4 : 7,
              fontWeight: FontWeight.w800,
              color: parchment,
              shadows: const [Shadow(color: Color(0xaa000000), blurRadius: 22)],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          tr(
            'SANTA AURORA  /  UM DIA NORMAL',
            'SANTA AURORA  /  AN ORDINARY DAY',
          ),
          style: const TextStyle(
            fontSize: 10,
            color: ochre,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: dense ? 6 : 14),
        if (!compact && !wide) _weatherCard(compact: true),
        if (!compact && !wide) const SizedBox(height: 12),
        _menuButton(
          key: const Key('menu-continue'),
          title: tr('Continuar', 'Continue'),
          subtitle: s.hasSave
              ? '${s.campaign.location} · ${s.campaign.evidenceCount}/${Campaign.markerTotal} ${tr('marcos', 'milestones')}'
              : tr('Nenhum salvamento encontrado', 'No saved progress found'),
          icon: Icons.description_outlined,
          onPressed: s.hasSave ? _resume : null,
          highlighted: s.hasSave,
          continueButton: true,
          dense: dense,
        ),
        SizedBox(height: dense ? 4 : 8),
        _menuButton(
          key: const Key('menu-new-game'),
          title: tr('Novo jogo', 'New game'),
          subtitle: tr('Começar do início', 'Start from the beginning'),
          icon: Icons.note_add_outlined,
          onPressed: _start,
          dense: dense,
        ),
        SizedBox(height: dense ? 4 : 8),
        _menuButton(
          key: const Key('menu-options'),
          title: tr('Configurações', 'Settings'),
          subtitle: tr(
            'Som, controles e acessibilidade',
            'Sound, controls and accessibility',
          ),
          icon: Icons.settings_outlined,
          onPressed: s.menuSettings,
          dense: dense,
        ),
        SizedBox(height: dense ? 4 : 8),
        _menuButton(
          key: const Key('menu-extras'),
          title: tr('Extras', 'Extras'),
          subtitle: tr('Jornada e abertura', 'Journey and opening'),
          icon: Icons.folder_open_outlined,
          onPressed: () => setState(() => _menuExtrasOpen = true),
          dense: dense,
        ),
        SizedBox(height: dense ? 5 : 10),
        Text(
          tr('FASE 01  ·  BETA 0.5', 'CHAPTER 01  ·  BETA 0.5'),
          style: const TextStyle(
            color: Color(0xffb1b6b7),
            fontSize: 9,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _menuButton({
    required Key key,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onPressed,
    bool highlighted = false,
    bool continueButton = false,
    bool dense = false,
  }) {
    final content = Row(
      children: [
        Icon(icon, size: dense ? 20 : 25),
        SizedBox(width: dense ? 10 : 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: dense ? 12 : 14,
                  letterSpacing: dense ? 1.2 : 1.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: dense ? 9 : 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded, size: 22),
      ],
    );
    final style = ButtonStyle(
      alignment: Alignment.centerLeft,
      minimumSize: WidgetStatePropertyAll(Size.fromHeight(dense ? 50 : 66)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: dense ? 12 : 16,
          vertical: dense ? 4 : 8,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: highlighted
                ? const Color(0xfff1ca7c)
                : const Color(0x998fa5b0),
          ),
        ),
      ),
      foregroundColor: WidgetStatePropertyAll(
        highlighted ? const Color(0xff1b1b18) : parchment,
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xa719252f);
        }
        return highlighted ? const Color(0xfff0c879) : const Color(0x8d0b151f);
      }),
      overlayColor: const WidgetStatePropertyAll(Color(0x22ffffff)),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w500),
      ),
    );
    return SizedBox(
      width: double.infinity,
      height: dense ? 52 : 68,
      child: continueButton
          ? FilledButton(
              key: key,
              onPressed: onPressed,
              style: style,
              child: content,
            )
          : OutlinedButton(
              key: key,
              onPressed: onPressed,
              style: style,
              child: content,
            ),
    );
  }

  Widget _weatherCard({required bool compact}) => _glass(
    Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: compact ? 9 : 12,
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(
            Icons.cloudy_snowing,
            color: const Color(0xffd4e2ed),
            size: compact ? 25 : 32,
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '07:12',
                style: TextStyle(
                  color: parchment,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              Text(
                tr('CHUVA DE NOVO', 'RAIN AGAIN'),
                style: const TextStyle(
                  color: mist,
                  fontSize: 9,
                  letterSpacing: 1.2,
                ),
              ),
              if (!compact)
                Text(
                  tr(
                    'Hoje parecia ser só mais um dia.',
                    'Today seemed like any other day.',
                  ),
                  style: const TextStyle(
                    color: Color(0xffbfc7ce),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _cityCard() => _glass(
    Padding(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          const Icon(Icons.location_city_outlined, color: ochre, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('SANTA AURORA', 'SANTA AURORA'),
                  style: const TextStyle(
                    color: parchment,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(
                    'Uma cidade que já foi normal. Agora, cada rua esconde histórias e perigos.',
                    'A city that used to be ordinary. Now every street hides stories and danger.',
                  ),
                  style: const TextStyle(
                    color: mist,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _featureCard(IconData icon, String title, String subtitle) => _glass(
    Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ochre, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: parchment,
              fontSize: 9,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: mist, fontSize: 9),
          ),
        ],
      ),
    ),
  );

  Widget _smallFeature(IconData icon, String title, String subtitle) =>
      SizedBox(width: 165, child: _featureCard(icon, title, subtitle));

  Widget _settings({bool fromPause = false}) => _panel(
    maxWidth: 620,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('Configurações', 'Settings'),
          style: const TextStyle(color: parchment, fontSize: 26),
        ),
        const SizedBox(height: 12),
        _eyebrow(tr('ÁUDIO', 'AUDIO')),
        _setting(
          tr('Sons e ambiente', 'Enable audio'),
          s.soundEnabled,
          (_) => s.toggleSound(),
        ),
        _setting(
          tr('Ambiente sonoro', 'Ambient audio'),
          preferences.musicEnabled,
          (v) => _preference('music', v),
          enabled: s.soundEnabled,
        ),
        _setting(
          tr('Efeitos sonoros', 'Sound effects'),
          preferences.effectsEnabled,
          (v) => _preference('audioEffects', v),
          enabled: s.soundEnabled,
        ),
        const SizedBox(height: 12),
        _eyebrow(tr('IMAGEM E ACESSIBILIDADE', 'DISPLAY AND ACCESSIBILITY')),
        _setting(
          tr(
            'Reduzir chuva, pulsos e movimento',
            'Reduce rain, pulses and motion',
          ),
          s.reducedEffects,
          (_) => s.toggleEffects(),
        ),
        _setting(
          tr('Qualidade visual econômica', 'Low visual quality'),
          preferences.lowQuality,
          (v) => _preference('lowQuality', v),
          subtitle: tr(
            'Reduz efeitos e detalhes decorativos do cenário.',
            'Reduces visual effects and decorative scenery details.',
          ),
        ),
        _setting(
          tr('Texto maior', 'Larger text'),
          s.largerText,
          (_) => s.toggleText(),
        ),
        _setting(
          tr('Painéis com alto contraste', 'High contrast panels'),
          preferences.highContrast,
          (v) => _preference('highContrast', v),
        ),
        const SizedBox(height: 12),
        _eyebrow(tr('CONTROLES DE TOQUE', 'TOUCH CONTROLS')),
        _setting(
          tr('Controle de movimento à direita', 'Movement control on right'),
          preferences.rightStick,
          (v) => _preference('rightStick', v),
          subtitle: tr(
            'Os botões de ação mudam para o lado oposto.',
            'Action buttons move to the opposite side.',
          ),
        ),
        _setting(
          tr('Controle de movimento maior', 'Larger movement control'),
          preferences.largeStick,
          (v) => _preference('largeStick', v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: preferences.language,
          decoration: InputDecoration(
            labelText: tr('Idioma da interface', 'Interface language'),
          ),
          items: const [
            DropdownMenuItem(value: 'pt-BR', child: Text('Português (Brasil)')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (value) async {
            if (value == null) return;
            await preferences.setLanguage(value);
            if (mounted) setState(() {});
          },
        ),
        const SizedBox(height: 12),
        Text(
          tr(
            'Beta: narrativa, objetivos e locais permanecem em português.',
            'Beta: narrative, objectives and locations remain in Portuguese.',
          ),
          style: const TextStyle(color: mist, fontSize: 12),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: fromPause
              ? () => setState(() => _pauseSettings = false)
              : s.closePanel,
          child: Text(
            fromPause
                ? tr('Voltar à pausa', 'Back to pause')
                : tr('Voltar ao menu', 'Back to menu'),
          ),
        ),
      ],
    ),
  );

  Widget _setting(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
    String? subtitle,
  }) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
    value: value,
    onChanged: enabled ? onChanged : null,
  );

  Widget _journey() => _panel(
    maxWidth: 920,
    child: CampaignJourney(
      completed: s.campaign.has('finish'),
      onPlayChapterTwo: s.campaign.has('finish') ? s.startChapterTwo : null,
      hasSave: s.hasSave,
      localMap: s.journeyFromMap,
      onPlay: () {
        if (s.journeyFromMap) {
          s.closePanel();
        } else if (s.hasSave && !s.campaign.finished) {
          _resume();
        } else {
          _start();
        }
      },
      onBack: s.closePanel,
    ),
  );

  Widget _hud() => Positioned(
    top: 8,
    left: 12,
    right: 12,
    child: SafeArea(
      bottom: false,
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          SizedBox(
            width: math.min(
              MediaQuery.sizeOf(context).width - 24,
              MediaQuery.sizeOf(context).width < 600 ? 360 : 390,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: _glass(
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: ConstrainedBox(
                    key: const Key('game-hud-card'),
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.radio_button_checked,
                              size: 10,
                              color: ochre,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                '${s.world.atmosphere.clock}  ·  ${s.campaign.location}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: mist,
                                  fontSize: 9,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${s.campaign.evidenceCount}/${Campaign.markerTotal} ${tr('MARCOS', 'MILESTONES')}',
                              style: const TextStyle(color: ochre, fontSize: 9),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.campaign.objective,
                          key: const Key('hud-objective'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.15,
                            color: parchment,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _meter(
                              s.campaign.injured
                                  ? tr('BRAÇO FERIDO', 'INJURED ARM')
                                  : tr('SAÚDE', 'HEALTH'),
                              s.campaign.health,
                              const Color(0xffdf6167),
                            ),
                            const SizedBox(width: 12),
                            _meter(
                              tr('FÔLEGO', 'STAMINA'),
                              s.campaign.stamina,
                              const Color(0xff79c995),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (s.world.encounterActive &&
              !s.world.enemyDefeated &&
              s.world.distance(s.world.enemyX, s.world.enemyY) < 5)
            SizedBox(
              width: MediaQuery.sizeOf(context).width < 600
                  ? MediaQuery.sizeOf(context).width - 36
                  : MediaQuery.sizeOf(context).width - 300,
              child: Align(
                alignment: Alignment.topLeft,
                child: _glass(
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xffdf6167),
                          size: 15,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'DAVI · ${s.world.enemyHealth.round()}%',
                          style: const TextStyle(
                            color: parchment,
                            fontSize: 10,
                            letterSpacing: .7,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              key: const ValueKey('enemy-health'),
                              value:
                                  s.world.enemyHealth /
                                  WorldModel.enemyMaxHealth,
                              minHeight: 5,
                              color: const Color(0xffdf6167),
                              backgroundColor: const Color(0xff493638),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          _glass(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: tr('Usar atadura', 'Use bandage'),
                  onPressed: s.heal,
                  icon: Badge(
                    label: Text('${s.campaign.bandages}'),
                    backgroundColor: const Color(0xff526c60),
                    child: const Icon(
                      Icons.healing_rounded,
                      size: 20,
                      color: parchment,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: tr(
                    'Diário e conversas',
                    'Journal and conversations',
                  ),
                  onPressed: s.journal,
                  icon: const Icon(
                    Icons.menu_book_rounded,
                    size: 20,
                    color: parchment,
                  ),
                ),
                IconButton(
                  tooltip: tr('Celular', 'Phone'),
                  onPressed: s.phone,
                  icon: const Icon(Icons.smartphone_rounded),
                ),
                IconButton(
                  tooltip: tr('Mapa', 'Map'),
                  onPressed: s.map,
                  icon: const Icon(Icons.map_outlined),
                ),
                IconButton(
                  tooltip: tr('Pausar', 'Pause'),
                  onPressed: s.pause,
                  icon: const Icon(
                    Icons.pause_rounded,
                    size: 22,
                    color: parchment,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _meter(String label, double value, Color color) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                color: Color(0xff90a8a0),
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              '${value.round()}',
              style: TextStyle(fontSize: 9, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: value / 100,
            color: color,
            backgroundColor: const Color(0xff32494a),
            minHeight: 3,
          ),
        ),
      ],
    ),
  );

  Widget _controls() {
    final place = s.world.nearby;
    return Positioned.fill(
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final portrait = width < 600;
            final movementSize = preferences.largeStick ? 132.0 : 106.0;
            final actionWidth = math.min(width - 20, portrait ? 340.0 : 360.0);
            final actionHeight = portrait ? 148.0 : 86.0;
            final side = preferences.rightStick ? .84 : .16;
            final opposite = 1 - side;
            final movementDefault = Offset(side, portrait ? .89 : .82);
            final actionsDefault = Offset(
              portrait ? .50 : opposite,
              portrait ? .70 : .82,
            );
            final sprintDefault = Offset(side, portrait ? .73 : .64);
            Offset anchor(String id, Offset fallback) =>
                _controlAnchors[id] ??
                preferences.controlPosition(id) ??
                fallback;

            Widget placed(String id, Offset fallback, Size size, Widget child) {
              final position = anchor(id, fallback);
              final left = (position.dx * width - size.width / 2)
                  .clamp(0.0, math.max(0, width - size.width))
                  .toDouble();
              final top = (position.dy * height - size.height / 2)
                  .clamp(0.0, math.max(0, height - size.height))
                  .toDouble();
              return Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: _editingControls
                      ? (details) => _moveControl(
                          id,
                          details.delta,
                          Size(width, height),
                          fallback,
                        )
                      : null,
                  onPanEnd: _editingControls
                      ? (_) => unawaited(
                          preferences.setControlPosition(
                            id,
                            anchor(id, fallback),
                          ),
                        )
                      : null,
                  child: DecoratedBox(
                    decoration: _editingControls
                        ? BoxDecoration(
                            border: Border.all(
                              color: const Color(0xff45d6ba),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            color: const Color(0x3327b69e),
                          )
                        : const BoxDecoration(),
                    child: SizedBox.fromSize(
                      key: Key('control-$id'),
                      size: size,
                      child: IgnorePointer(
                        ignoring: _editingControls,
                        child: Center(child: child),
                      ),
                    ),
                  ),
                ),
              );
            }

            final actions = <Widget>[
              _action(
                Icons.blur_on_rounded,
                tr('Percepção', 'Perception'),
                s.togglePerception,
                selected: s.world.perception,
                small: true,
              ),
              _action(
                Icons.back_hand_outlined,
                tr('Empurrar', 'Push'),
                s.push,
                small: true,
              ),
              if (s.world.encounterActive)
                _action(
                  Icons.shield_outlined,
                  tr('Defender', 'Guard'),
                  s.toggleGuard,
                  selected: s.world.guarding,
                  small: true,
                ),
              if (s.world.canVault)
                _action(
                  Icons.arrow_upward_rounded,
                  'Transpor muro',
                  s.vault,
                  small: true,
                ),
              if (s.world.encounterActive &&
                  !s.world.enemyDefeated &&
                  s.campaign.has('weapon'))
                _action(
                  Icons.gavel_rounded,
                  tr('Atacar', 'Attack'),
                  s.attack,
                  small: true,
                  showLabel: true,
                ),
              _action(
                place == null
                    ? Icons.touch_app_outlined
                    : Icons.pan_tool_alt_outlined,
                s.world.resting == 'sit' || s.world.resting == 'typing'
                    ? tr('Levantar', 'Stand up')
                    : place == null
                    ? tr('Interagir', 'Interact')
                    : s.world.actionFor(place),
                s.interact,
                selected: place != null,
                small: true,
                showLabel: place != null,
              ),
            ];
            final actionContent = portrait
                ? Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: actions,
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          actions[i],
                        ],
                      ],
                    ),
                  );

            return Stack(
              children: [
                placed(
                  'movement',
                  movementDefault,
                  Size(movementSize, movementSize),
                  VirtualStick(
                    onChanged: (o) =>
                        s.world.setInput(o.dx + o.dy * 2, -o.dx + o.dy * 2),
                  ),
                ),
                placed(
                  'actions',
                  actionsDefault,
                  Size(actionWidth, actionHeight),
                  actionContent,
                ),
                placed(
                  'sprint',
                  sprintDefault,
                  const Size(48, 48),
                  Tooltip(
                    message: s.world.recoveringBreath
                        ? tr('Recuperando fôlego', 'Catching breath')
                        : s.world.severelyHurt
                        ? tr('Ferido · caminhar', 'Injured · walk')
                        : s.world.effectiveRunning
                        ? tr('Correndo', 'Running')
                        : tr('Correr', 'Run'),
                    child: Material(
                      color: const Color(0xdb172b33),
                      shape: const CircleBorder(
                        side: BorderSide(color: Color(0xff506c69), width: 1.2),
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: s.toggleRun,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            s.world.effectiveRunning
                                ? Icons.directions_run
                                : Icons.directions_walk,
                            size: 22,
                            color: parchment,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_editingControls)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: const Color(0xf5182a32),
                        borderRadius: BorderRadius.circular(22),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tr('Arraste para organizar', 'Drag to arrange'),
                                style: const TextStyle(
                                  color: parchment,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _editingControls = false),
                                child: Text(tr('Concluir', 'Done')),
                              ),
                              IconButton(
                                tooltip: tr('Restaurar layout', 'Reset layout'),
                                onPressed: () async {
                                  await preferences.resetControlPositions();
                                  if (mounted) {
                                    setState(_controlAnchors.clear);
                                  }
                                },
                                icon: const Icon(Icons.restart_alt, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _moveControl(String id, Offset delta, Size size, Offset fallback) {
    final current =
        _controlAnchors[id] ?? preferences.controlPosition(id) ?? fallback;
    setState(() {
      _controlAnchors[id] = Offset(
        (current.dx + delta.dx / size.width).clamp(.04, .96),
        (current.dy + delta.dy / size.height).clamp(.04, .96),
      );
    });
  }

  Widget _action(
    IconData icon,
    String label,
    VoidCallback action, {
    bool selected = false,
    bool small = false,
    bool showLabel = false,
  }) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        button: true,
        label: label,
        child: Material(
          color: selected ? const Color(0xe0587a6f) : const Color(0xdb172b33),
          shape: CircleBorder(
            side: BorderSide(
              color: selected ? mist : const Color(0xff506c69),
              width: 1.2,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: action,
            child: SizedBox(
              width: small ? 52 : 70,
              height: small ? 52 : 70,
              child: Icon(
                icon,
                color: selected ? parchment : const Color(0xffa5beb1),
                size: small ? 22 : 28,
              ),
            ),
          ),
        ),
      ),
      if (showLabel) ...[
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: small ? 9 : 10, color: parchment),
        ),
      ],
    ],
  );

  Widget _dialogue() {
    final line = s.currentLine;
    final portrait = const {
      'CAIO': 'caio',
      'HELENA': 'helena',
      'INÊS': 'ines',
      'CELINA': 'ines',
      'ORLANDO': 'orlando',
      'NANDO': 'nestor',
      'MARINA': 'marina',
      'BIA': null,
    }[line?.speaker];
    return _scrim(
      Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 18, 36, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 280),
            child: _glass(
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (portrait != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/portrait_$portrait.png',
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          line?.mode == 'leitura labial'
                              ? Icons.face_outlined
                              : line?.mode == 'gesto' || line?.mode == 'Libras'
                              ? Icons.front_hand_outlined
                              : Icons.smartphone_rounded,
                          size: 17,
                          color: ochre,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _eyebrow(
                            '${line?.speaker ?? ''}  ·  ${line?.mode.toUpperCase() ?? ''}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${s.dialogueIndex + 1}/${s.activeLines.length}',
                          style: const TextStyle(
                            color: Color(0xff819c93),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (line?.speaker == 'HELENA' &&
                        s.campaign.has('pulse')) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.asset(
                          'assets/images/video_placeholder_03_mensagem_v01.png',
                          width: double.infinity,
                          height: 145,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      line?.text ?? '',
                      style: TextStyle(
                        fontSize: s.largerText ? 20 : 17,
                        height: 1.5,
                        color: parchment,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: s.nextLine,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                        label: Text(tr('Continuar', 'Continue')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      opacity: .2,
    );
  }

  Widget _news() {
    final pages = (s.news['pages'] as List).cast<String>();
    final ticker = (s.news['ticker'] as List).cast<String>();
    return _panel(
      maxWidth: 760,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fiber_manual_record, color: ochre, size: 9),
              const SizedBox(width: 8),
              _eyebrow(s.news['source'] as String),
              const Spacer(),
              const Text(
                'LEGENDA DO BOLETIM',
                style: TextStyle(
                  color: Color(0xff8eaaa1),
                  fontSize: 9,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 126,
                decoration: BoxDecoration(
                  color: const Color(0xff294b4c),
                  border: Border.all(color: const Color(0xff58756d)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cell_tower_rounded, color: mist, size: 43),
                    SizedBox(height: 10),
                    Text(
                      'SANTA\nAURORA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: parchment,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.news['title'] as String,
                      style: const TextStyle(
                        color: parchment,
                        fontSize: 25,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pages[s.newsPage],
                      style: TextStyle(
                        fontSize: s.largerText ? 18 : 15,
                        color: const Color(0xffc3d0c5),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xff3a5555)),
          Text(
            ticker[s.newsPage % ticker.length],
            style: const TextStyle(color: ochre, fontSize: 11),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Text(
                'BOLETIM ${s.newsPage + 1} / ${pages.length}',
                style: const TextStyle(
                  color: mist,
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: s.advanceNews,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  s.newsPage < pages.length - 1
                      ? 'Próxima página'
                      : 'Registrar e voltar',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _journal() => _panel(
    maxWidth: 800,
    child: SizedBox(
      height: math.min(MediaQuery.sizeOf(context).height - 100, 440),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Row(
              children: [
                _eyebrow('CADERNO DE CAIO'),
                const Spacer(),
                IconButton(
                  tooltip: 'Voltar ao jogo',
                  onPressed: s.closePanel,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Pistas e hipóteses'),
                Tab(text: 'Conversas'),
                Tab(text: 'Equipamentos'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView.separated(
                    padding: const EdgeInsets.only(top: 12),
                    itemCount: s.campaign.entries.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: Color(0xff304c4b)),
                    itemBuilder: (context, index) {
                      final e = s.campaign.entries[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.kind,
                              style: TextStyle(
                                color: e.kind == 'HIPÓTESE' ? ochre : mist,
                                fontSize: 9,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              e.title,
                              style: const TextStyle(
                                color: parchment,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              e.text,
                              style: TextStyle(
                                color: const Color(0xffb0c4ba),
                                height: 1.5,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  s.campaign.history.isEmpty
                      ? const Center(
                          child: Text('As conversas aparecerão aqui.'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 12),
                          itemCount: s.campaign.history.length,
                          itemBuilder: (context, index) {
                            final line = s.campaign.history[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${line.speaker} · ${line.mode.toUpperCase()}',
                                    style: const TextStyle(
                                      color: mist,
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    line.text,
                                    style: TextStyle(
                                      color: parchment,
                                      height: 1.5,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  ListView(
                    children: [
                      SwitchListTile(
                        title: const Text('Mochila equipada'),
                        subtitle: const Text(
                          'Muda a aparência. Os itens guardados são preservados.',
                        ),
                        value: s.campaign.backpackEquipped,
                        onChanged: (_) => s.toggleBackpack(),
                      ),
                      SwitchListTile(
                        title: const Text('Arma na mão'),
                        subtitle: Text(
                          s.campaign.has('weapon')
                              ? 'Arma improvisada. Guardar não descarta o item.'
                              : 'Nenhuma arma recolhida.',
                        ),
                        value:
                            s.campaign.has('weapon') &&
                            s.campaign.weaponEquipped,
                        onChanged: s.campaign.has('weapon')
                            ? (_) => s.toggleWeaponEquipment()
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _pause() => Positioned.fill(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/menu_santa_aurora_v2.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xe90a121b),
                Color(0xd90a121b),
                Color(0x9b0a121b),
                Color(0x790a121b),
              ],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xd9081119), Color(0x28081119)],
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ConstrainedBox(
                key: const Key('pause-card'),
                constraints: BoxConstraints(
                  maxWidth: 440,
                  maxHeight: MediaQuery.sizeOf(context).height - 32,
                ),
                child: _glass(
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _eyebrow(
                                tr(
                                  'UM INSTANTE DE SILÊNCIO',
                                  'A MOMENT OF SILENCE',
                                ),
                              ),
                            ),
                            Text(
                              '${s.world.atmosphere.clock}  ·  ${s.campaign.location}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ochre,
                                fontSize: 9,
                                letterSpacing: .7,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr('A cidade pode esperar.', 'The city can wait.'),
                          style: const TextStyle(
                            color: parchment,
                            fontSize: 25,
                            height: 1.1,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(height: 1, color: const Color(0x665e746d)),
                        const SizedBox(height: 6),
                        _pauseSwitch(
                          tr('Sons e ambiente', 'Ambient audio'),
                          s.soundEnabled,
                          s.toggleSound,
                        ),
                        _pauseSwitch(
                          tr(
                            'Reduzir chuva e pulsos',
                            'Reduce rain and pulses',
                          ),
                          s.reducedEffects,
                          s.toggleEffects,
                        ),
                        _pauseSwitch(
                          tr('Texto maior', 'Larger text'),
                          s.largerText,
                          s.toggleText,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tr(
                            'WASD mover · E interagir · F atacar · V defender · Shift correr · Esc voltar\nQ percepção · M mapa · P celular · J diário · mouse direito mirar',
                            'WASD move · E interact · F attack · V guard · Shift run · Esc back\nQ perception · M map · P phone · J journal · right mouse aim',
                          ),
                          style: const TextStyle(
                            color: Color(0xffa2b5ac),
                            fontSize: 9,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: FilledButton.icon(
                            onPressed: s.closePanel,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xfff0c879),
                              foregroundColor: const Color(0xff1b1b18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .8,
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(tr('CONTINUAR', 'CONTINUE')),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    setState(() => _pauseSettings = true),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: parchment,
                                  side: const BorderSide(
                                    color: Color(0xff789087),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: const Size(0, 40),
                                  textStyle: const TextStyle(fontSize: 11),
                                ),
                                icon: const Icon(
                                  Icons.settings_outlined,
                                  size: 17,
                                ),
                                label: Text(tr('Configurações', 'Settings')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() => _editingControls = true);
                                  s.closePanel();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: parchment,
                                  side: const BorderSide(
                                    color: Color(0xff789087),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: const Size(0, 40),
                                  textStyle: const TextStyle(fontSize: 11),
                                ),
                                icon: const Icon(
                                  Icons.open_with_rounded,
                                  size: 17,
                                ),
                                label: Text(
                                  tr('Editar controles', 'Edit controls'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => unawaited(s.toMenu()),
                            style: TextButton.styleFrom(
                              foregroundColor: mist,
                              visualDensity: VisualDensity.compact,
                              textStyle: const TextStyle(fontSize: 10),
                            ),
                            icon: const Icon(Icons.save_outlined, size: 15),
                            label: Text(
                              tr(
                                'Salvar e voltar ao menu',
                                'Save and return to menu',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _pauseSwitch(String label, bool value, VoidCallback toggle) =>
      SizedBox(
        height: 34,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: parchment),
              ),
            ),
            Transform.scale(
              scale: .72,
              child: Switch.adaptive(
                value: value,
                onChanged: (_) => toggle(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );

  Widget _complete() => _panel(
    maxWidth: 620,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/video_placeholder_01_abertura_v01.png',
            width: double.infinity,
            height: 190,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        _eyebrow(
          s.campaign.inChapterTwo ? 'FASE 02 CONCLUÍDA' : 'FASE 01 CONCLUÍDA',
        ),
        const SizedBox(height: 15),
        Text(
          s.campaign.inChapterTwo ? '02:00.' : 'Um Dia Normal.',
          style: const TextStyle(
            color: parchment,
            fontSize: 34,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          s.campaign.inChapterTwo
              ? 'Mapa recolhido no posto de serviço. Helena espera na entrada dos fundos da oficina.\n“Estou indo.” A mensagem ainda não foi enviada. A Queda é o próximo capítulo, ainda em produção.'
              : 'O ônibus da linha 203 parte sob a chuva. A mensagem de Helena continua no celular.\nHoje, às duas. O próximo capítulo começa nesse horário.',
          style: const TextStyle(
            color: Color(0xffb6c9bd),
            fontSize: 15,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          s.campaign.inChapterTwo
              ? (s.campaign.has('chapter2_rescue')
                    ? 'A vizinha ficou protegida. A chave abriu a passagem de serviço.'
                    : 'Você seguiu pela rota externa. A escolha ficou registrada.')
              : [
                  if (s.campaign.has('help_ines'))
                    'Dona Celina se lembra da sua ajuda no hall.',
                  if (s.campaign.has('answered_bia'))
                    'Bia recebeu sua resposta escrita no abrigo.',
                  if (!s.campaign.has('help_ines') &&
                      !s.campaign.has('answered_bia'))
                    'O encontro terminou sem matar Davi.',
                ].join('\n'),
          style: const TextStyle(color: ochre, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 20),
        if (!s.campaign.inChapterTwo)
          FilledButton(
            onPressed: s.startChapterTwo,
            child: const Text('Jogar fase 02 · 02:00'),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text(
              s.campaign.inChapterTwo
                  ? 'PROGRESSO SALVO · FASE 02'
                  : 'PROGRESSO SALVO · 02:00 DESBLOQUEADO',
              style: const TextStyle(
                color: mist,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            FilledButton(
              onPressed: () => unawaited(s.toMenu()),
              child: const Text('Voltar ao menu'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _defeated() => _panel(
    maxWidth: 500,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('VOCÊ PRECISA DE OUTRA SAÍDA'),
        const SizedBox(height: 16),
        const Text(
          'Ainda não acabou.',
          style: TextStyle(
            fontSize: 30,
            color: parchment,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Recuar e empurrar criam espaço. A passagem não exige derrotar o morador.',
          style: TextStyle(color: Color(0xffb4c6ba), height: 1.6),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => unawaited(s.retry()),
          child: const Text('Retomar o último registro'),
        ),
      ],
    ),
  );

  Widget _opening() => s.openingPrelude
      ? _openingPrelude()
      : ColoredBox(
          color: const Color(0xff07151c),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: s.toggleOpeningAuto,
                            icon: Icon(
                              s.openingAuto
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                              size: 18,
                            ),
                            label: Text(
                              s.openingAuto
                                  ? tr('Automático: ligado', 'Auto: on')
                                  : tr('Leitura manual', 'Manual reading'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${s.openingPage + 1} / ${GameSession.opening.length}',
                        style: const TextStyle(color: mist),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: NarrativeBackdrop(
                    asset: s.openingPage == 3
                        ? 'assets/images/opening_subject07_v1.png'
                        : 'assets/images/opening_storyboard_v1.png',
                    atlasIndex: s.openingPage == 3
                        ? null
                        : s.openingPage == 4
                        ? 3
                        : s.openingPage,
                    atlasColumns: 2,
                    atlasRows: 2,
                    progress: s.sceneTime / 13,
                    reducedMotion: s.reducedEffects,
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                  child: _glass(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _eyebrow(
                            tr(
                              GameSession.opening[s.openingPage].$1,
                              GameSession.openingEn[s.openingPage].$1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.sizeOf(context).height * .26,
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                tr(
                                  GameSession.opening[s.openingPage].$2,
                                  GameSession.openingEn[s.openingPage].$2,
                                ),
                                style: TextStyle(
                                  color: parchment,
                                  fontSize: 14.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 4,
                            children: [
                              TextButton(
                                onPressed: s.openingPage > 0
                                    ? s.previousOpening
                                    : null,
                                child: Text(tr('Anterior', 'Previous')),
                              ),
                              TextButton(
                                onPressed: s.finishOpening,
                                child: Text(
                                  tr('Pular abertura', 'Skip opening'),
                                ),
                              ),
                              FilledButton(
                                onPressed: s.nextOpening,
                                child: Text(tr('Avançar', 'Next')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

  Widget _openingPrelude() => ColoredBox(
    color: const Color(0xff07151c),
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: s.toggleOpeningAuto,
                      icon: Icon(
                        s.openingAuto
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        size: 18,
                      ),
                      label: Text(
                        s.openingAuto
                            ? tr('Automático: ligado', 'Auto: on')
                            : tr('Leitura manual', 'Manual reading'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  tr('CIDADE · 8 s', 'CITY · 8 s'),
                  style: const TextStyle(color: mist),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/video_placeholder_01_abertura_v01.png',
                  key: const ValueKey('opening-city-placeholder'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x12000000), Color(0x7f07151c)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: _glass(
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _eyebrow(
                      tr('SANTA AURORA · 07:12', 'SANTA AURORA · 07:12'),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      tr(
                        'A cidade ainda parece normal. A chuva continua. Em algum lugar, o dia já começou diferente.',
                        'The city still looks ordinary. Rain keeps falling. Somewhere, the day has already changed.',
                      ),
                      style: const TextStyle(
                        color: parchment,
                        fontSize: 14.5,
                        height: 1.4,
                      ),
                    ),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 4,
                      children: [
                        TextButton(
                          onPressed: s.finishOpening,
                          child: Text(tr('Pular abertura', 'Skip opening')),
                        ),
                        FilledButton(
                          onPressed: s.nextOpening,
                          child: Text(tr('Avançar', 'Next')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _map() {
    return _panel(
      maxWidth: 960,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _eyebrow(
                  s.campaign.floor == 2
                      ? '2º ANDAR · APARTAMENTO 203'
                      : s.campaign.floor == 1
                      ? '1º ANDAR · RESIDENCIAL'
                      : 'TÉRREO · SANTA AURORA',
                ),
              ),
              TextButton.icon(
                onPressed: s.journey,
                icon: const Icon(Icons.route_outlined, size: 16),
                label: const Text('Jornada'),
              ),
              IconButton(
                onPressed: s.closePanel,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            s.campaign.objective,
            style: const TextStyle(color: parchment, fontSize: 14),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: math.min(360, MediaQuery.sizeOf(context).height * .48),
            width: 850,
            child: CustomPaint(painter: ChapterMap(s.campaign, s.world)),
          ),
          const Text(
            'Ponto claro: você · Dourado: interação · Blocos: edifícios e veículos.',
            style: TextStyle(color: mist, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _pulse() => IgnorePointer(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/video_placeholder_02_pulso_v01.png',
          fit: BoxFit.cover,
        ),
        ColoredBox(
          color: Color.fromRGBO(
            177,
            204,
            183,
            s.reducedEffects
                ? .12
                : .16 + math.sin(s.sceneTime * math.pi) * .15,
          ),
          child: Center(
            child: _glass(
              const Padding(
                padding: EdgeInsets.all(22),
                child: Text(
                  'A cidade parou. Você continua consciente.',
                  style: TextStyle(color: parchment, fontSize: 20),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  Widget _objectPanel() => Align(
    alignment: Alignment.bottomRight,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 350,
        height: math.min(MediaQuery.sizeOf(context).height * .6, 370),
        child: _glass(
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.objectTitle,
                    style: const TextStyle(color: parchment, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.objectBody,
                    style: const TextStyle(color: mist, height: 1.5),
                  ),
                  for (final action in s.objectActions)
                    TextButton(
                      onPressed: action.enabled ? action.run : null,
                      child: Text(action.label),
                    ),
                  FilledButton(
                    onPressed: () {
                      s.closePanel();
                      focus.requestFocus();
                    },
                    child: Text(
                      s.world.resting == 'sit' ||
                              s.world.resting == 'lie' ||
                              s.world.resting == 'typing'
                          ? 'Levantar'
                          : 'Fechar',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildingTransition() {
    final transition = s.buildingTransition!;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: Color.fromRGBO(5, 12, 17, transition.fade),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _glass(
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      transition.isDoor
                          ? Icons.meeting_room_outlined
                          : Icons.stairs_outlined,
                      color: ochre,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        transition.caption,
                        style: const TextStyle(color: parchment, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _transit() => Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: _glass(
        const Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'No ônibus de Nando · próxima esquina',
            style: TextStyle(color: parchment, fontSize: 17),
          ),
        ),
      ),
    ),
  );

  Widget _panel({
    required Widget child,
    double maxWidth = 700,
    double outerInset = 24,
    double contentInset = 24,
    Key? key,
  }) => _scrim(
    Center(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(outerInset),
          child: ConstrainedBox(
            key: key,
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: MediaQuery.sizeOf(context).height - outerInset * 2,
            ),
            child: _glass(
              SingleChildScrollView(
                padding: EdgeInsets.all(contentInset),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget _scrim(Widget child, {double opacity = .65}) => Listener(
    behavior: HitTestBehavior.opaque,
    child: ColoredBox(
      color: const Color(0xff08171e).withValues(alpha: opacity),
      child: child,
    ),
  );
  Widget _glass(Widget child) => Material(
    color: preferences.highContrast
        ? const Color(0xff061017)
        : const Color(0xf5182a32),
    elevation: 8,
    shadowColor: const Color(0x40101d23),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: Color(0xff415c57)),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
  Widget _eyebrow(String text) => Text(
    text,
    style: const TextStyle(
      color: mist,
      fontSize: 10,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w600,
    ),
  );
  @override
  void dispose() {
    s.removeListener(_syncMenuMotion);
    _menuMotion.dispose();
    WidgetsBinding.instance.removeObserver(this);
    focus.dispose();
    super.dispose();
  }
}

class VirtualStick extends StatefulWidget {
  const VirtualStick({super.key, required this.onChanged});
  final ValueChanged<Offset> onChanged;
  @override
  State<VirtualStick> createState() => _VirtualStickState();
}

class _VirtualStickState extends State<VirtualStick> {
  Offset offset = Offset.zero;
  void _move(Offset position) {
    var next = position - const Offset(53, 53);
    if (next.distance > 37) next = next / next.distance * 37;
    setState(() => offset = next);
    widget.onChanged(next / 37);
  }

  void _release() {
    setState(() => offset = Offset.zero);
    widget.onChanged(Offset.zero);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Controle de movimento',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => _move(d.localPosition),
      onPanUpdate: (d) => _move(d.localPosition),
      onPanEnd: (_) => _release(),
      onPanCancel: _release,
      child: Container(
        width: 106,
        height: 106,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x9a192f35),
          border: Border.all(color: const Color(0xff536f68)),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.add, color: Color(0x506f9586), size: 42),
            ),
            Positioned(
              left: 34 + offset.dx,
              top: 34 + offset.dy,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xc1799b89),
                  border: Border.all(color: mist.withValues(alpha: .75)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x400e2227), blurRadius: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
