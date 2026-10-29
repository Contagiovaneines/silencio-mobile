import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/game_session.dart';
import '../services/game_preferences.dart';
import '../game/silencio_game.dart';
import '../game/world_model.dart';
import 'phase_presentation.dart';
import 'narrative_backdrop.dart';
import 'campaign_journey.dart';
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

class _GameShellState extends State<GameShell> with WidgetsBindingObserver {
  late final SilencioGame game;
  final focus = FocusNode();
  final keys = <LogicalKeyboardKey>{};
  String? _mapTarget;
  GameSession get s => widget.session;
  late final GamePreferences preferences;
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
    WidgetsBinding.instance.addObserver(this);
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
              GestureDetector(
                onTapDown: (d) {
                  game.tapGround(d.localPosition);
                  focus.requestFocus();
                },
                child: GameWidget(game: game, autofocus: false),
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
              if (s.phase == PlayPhase.paused) _pause(),
              if (s.phase == PlayPhase.complete) _complete(),
              if (s.phase == PlayPhase.defeated) _defeated(),
              if (s.notice.isNotEmpty && s.phase == PlayPhase.playing)
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: MediaQuery.sizeOf(context).width < 600 ? 300 : 18,
                  child: IgnorePointer(
                    child: _glass(
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          s.notice,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: parchment,
                            fontSize: 11,
                            height: 1.4,
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

  Widget _menu() => Stack(
    fit: StackFit.expand,
    children: [
      NarrativeBackdrop(
        asset: 'assets/images/menu_santa_aurora_v1.png',
        reducedMotion: s.reducedEffects,
      ),
      DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xf5102029), Color(0xd5102029), Color(0x35102029)],
            stops: [0, .42, 1],
          ),
        ),
      ),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 20, 28, 18),
          child: LayoutBuilder(
            builder: (context, bounds) => Row(
              children: [
                SizedBox(
                  width: math.min(
                    440,
                    bounds.maxWidth <= 650
                        ? bounds.maxWidth
                        : bounds.maxWidth * .64,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(
                            'UM JOGO SOBRE O QUE AINDA É HUMANO',
                            'A GAME ABOUT WHAT REMAINS HUMAN',
                          ),
                          style: const TextStyle(
                            color: mist,
                            fontSize: 9,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'SILÊNCIO',
                            style: TextStyle(
                              fontSize: bounds.maxHeight < 400 ? 52 : 68,
                              height: 1.1,
                              letterSpacing: 7,
                              fontWeight: FontWeight.w300,
                              color: parchment,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tr(
                            'SANTA AURORA / UM DIA NORMAL',
                            'SANTA AURORA / AN ORDINARY DAY',
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            color: ochre,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(
                            '07:12. Chuva de novo.\nHoje parecia ser só mais um dia.',
                            '07:12. Rain again.\nToday seemed like any other day.',
                          ),
                          style: const TextStyle(
                            color: mist,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            FilledButton.icon(
                              onPressed: _start,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(tr('Novo jogo', 'New game')),
                            ),
                            if (s.hasSave)
                              FilledButton.tonalIcon(
                                onPressed: _resume,
                                icon: const Icon(Icons.restore_rounded),
                                label: Text(tr('Continuar', 'Continue')),
                              ),
                            OutlinedButton.icon(
                              onPressed: s.menuSettings,
                              icon: const Icon(Icons.settings_outlined),
                              label: Text(tr('Configurações', 'Settings')),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: s.journey,
                          icon: const Icon(Icons.route_outlined, size: 18),
                          label: Text(tr('Jornada', 'Journey')),
                        ),
                        TextButton(
                          onPressed: s.replay,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: Text(
                            tr(
                              'Reassistir à abertura  ↗',
                              'Watch opening again  ↗',
                            ),
                            style: const TextStyle(fontSize: 11, color: mist),
                          ),
                        ),
                        Text(
                          tr('FASE 01 · BETA 0.5', 'CHAPTER 01 · BETA 0.5'),
                          style: const TextStyle(
                            color: Color(0xff718d88),
                            fontSize: 9,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (bounds.maxWidth > 650)
                  Flexible(
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: _glass(
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.radio_button_checked,
                                color: ochre,
                                size: 16,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tr(
                                  '01 / UM DIA NORMAL',
                                  '01 / AN ORDINARY DAY',
                                ),
                                style: const TextStyle(
                                  color: parchment,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.hasSave
                                    ? '${s.campaign.location}\n${s.campaign.evidenceCount}/5 ${tr('marcos registrados', 'milestones recorded')}'
                                    : tr(
                                        'Apartamento 203 · 2º andar\nUma manhã que parecia comum.',
                                        'Apartment 203 · 2nd floor\nA morning that seemed ordinary.',
                                      ),
                                style: const TextStyle(
                                  color: mist,
                                  fontSize: 11,
                                  height: 1.5,
                                ),
                              ),
                            ],
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
    ],
  );

  Widget _settings() => _panel(
    maxWidth: 620,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('Configurações', 'Settings'),
          style: const TextStyle(color: parchment, fontSize: 26),
        ),
        _setting(
          tr('Sons e ambiente', 'Enable audio'),
          s.soundEnabled,
          (_) => s.toggleSound(),
        ),
        _setting(
          tr('Ambiente sonoro', 'Ambient audio'),
          preferences.musicEnabled,
          (v) => _preference('music', v),
        ),
        _setting(
          tr('Efeitos sonoros', 'Sound effects'),
          preferences.effectsEnabled,
          (v) => _preference('audioEffects', v),
        ),
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
        _setting(
          tr('Controle de movimento à direita', 'Movement control on right'),
          preferences.rightStick,
          (v) => _preference('rightStick', v),
        ),
        _setting(
          tr('Controle de movimento maior', 'Larger movement control'),
          preferences.largeStick,
          (v) => _preference('largeStick', v),
        ),
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
          onPressed: s.closePanel,
          child: Text(tr('Voltar ao menu', 'Back to menu')),
        ),
      ],
    ),
  );

  Widget _setting(String title, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        value: value,
        onChanged: onChanged,
      );

  Widget _journey() => _panel(
    maxWidth: 920,
    child: CampaignJourney(
      completed: s.campaign.finished,
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
    top: 12,
    left: 18,
    right: 18,
    child: SafeArea(
      bottom: false,
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          SizedBox(
            width: MediaQuery.sizeOf(context).width < 600
                ? MediaQuery.sizeOf(context).width - 36
                : MediaQuery.sizeOf(context).width - 300,
            child: Align(
              alignment: Alignment.topLeft,
              child: _glass(
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: ConstrainedBox(
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
                              '${s.campaign.evidenceCount}/5 ${tr('MARCOS', 'MILESTONES')}',
                              style: const TextStyle(color: ochre, fontSize: 9),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          s.campaign.objective,
                          style: const TextStyle(
                            fontSize: 12,
                            color: parchment,
                          ),
                        ),
                        const SizedBox(height: 10),
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
        child: Stack(
          children: [
            Positioned(
              left: preferences.rightStick ? null : 24,
              right: preferences.rightStick ? 24 : null,
              bottom: preferences.largeStick ? 160 : 138,
              child: OutlinedButton.icon(
                onPressed: s.toggleRun,
                icon: Icon(
                  s.world.running
                      ? Icons.directions_run
                      : Icons.directions_walk,
                ),
                label: Text(
                  s.world.recoveringBreath
                      ? tr('Recuperando fôlego', 'Catching breath')
                      : s.world.severelyHurt
                      ? tr('Ferido · caminhar', 'Injured · walk')
                      : s.world.running
                      ? tr('Correndo', 'Running')
                      : tr('Caminhando', 'Walking'),
                ),
              ),
            ),
            Positioned(
              left: preferences.rightStick ? null : 24,
              right: preferences.rightStick ? 24 : null,
              bottom: 20,
              child: SizedBox(
                width: preferences.largeStick ? 132 : 106,
                height: preferences.largeStick ? 132 : 106,
                child: FittedBox(
                  child: VirtualStick(
                    onChanged: (o) =>
                        s.world.setInput(o.dx + o.dy * 2, -o.dx + o.dy * 2),
                  ),
                ),
              ),
            ),
            Positioned(
              right: preferences.rightStick ? null : 22,
              left: preferences.rightStick ? 22 : null,
              bottom: MediaQuery.sizeOf(context).width < 600 ? 210 : 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _action(
                    Icons.blur_on_rounded,
                    tr('Percepção', 'Perception'),
                    s.togglePerception,
                    selected: s.world.perception,
                    small: true,
                  ),
                  const SizedBox(width: 10),
                  _action(
                    Icons.back_hand_outlined,
                    tr('Empurrar', 'Push'),
                    s.push,
                    small: true,
                  ),
                  const SizedBox(width: 12),
                  _action(
                    place == null
                        ? Icons.touch_app_outlined
                        : Icons.pan_tool_alt_outlined,
                    place?.action ?? tr('Interagir', 'Interact'),
                    s.interact,
                    selected: place != null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(
    IconData icon,
    String label,
    VoidCallback action, {
    bool selected = false,
    bool small = false,
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
      const SizedBox(height: 7),
      Text(
        label,
        style: TextStyle(fontSize: small ? 9 : 10, color: parchment),
      ),
    ],
  );

  Widget _dialogue() {
    final line = s.currentLine;
    final portrait = const {
      'CAIO': 'caio',
      'HELENA': 'helena',
      'INÊS': 'ines',
      'ORLANDO': 'orlando',
      'NESTOR': 'nestor',
      'MARINA': 'marina',
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
        length: 2,
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
              tabs: [
                Tab(text: 'Pistas e hipóteses'),
                Tab(text: 'Conversas'),
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
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _pause() => _panel(
    maxWidth: 560,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(tr('UM INSTANTE DE SILÊNCIO', 'A MOMENT OF SILENCE')),
        const SizedBox(height: 12),
        Text(
          tr('A cidade pode esperar.', 'The city can wait.'),
          style: TextStyle(
            color: parchment,
            fontSize: 27,
            fontWeight: FontWeight.w300,
          ),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(tr('Sons e ambiente', 'Enable audio')),
          value: s.soundEnabled,
          onChanged: (_) => s.toggleSound(),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            tr('Reduzir chuva e pulsos', 'Reduce rain and pulses'),
            style: TextStyle(fontSize: 14),
          ),
          value: s.reducedEffects,
          onChanged: (_) => s.toggleEffects(),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            tr('Texto maior', 'Larger text'),
            style: const TextStyle(fontSize: 14),
          ),
          value: s.largerText,
          onChanged: (_) => s.toggleText(),
        ),
        Text(
          tr(
            'WASD/setas: mover · E: interagir · Espaço: empurrar · R: correr · Q: Percepção · M: mapa · P: celular · J: diário · Esc: voltar.',
            'WASD/arrows: move · E: interact · Space: push · R: run · Q: perception · M: map · P: phone · J: journal · Esc: back.',
          ),
          style: const TextStyle(
            color: Color(0xff91aca2),
            fontSize: 11,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: s.closePanel,
              child: Text(tr('Continuar', 'Continue')),
            ),
            OutlinedButton(
              onPressed: () => unawaited(s.toMenu()),
              child: Text(
                tr('Salvar e voltar ao menu', 'Save and return to menu'),
              ),
            ),
          ],
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
        _eyebrow('FASE 01 CONCLUÍDA'),
        const SizedBox(height: 15),
        const Text(
          'Um Dia Normal.',
          style: TextStyle(
            color: parchment,
            fontSize: 34,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'De volta ao apartamento. O pulso passou, mas o aviso de Helena ficou.\nHoje, às duas. O próximo capítulo começa nesse horário.',
          style: TextStyle(color: Color(0xffb6c9bd), fontSize: 15, height: 1.7),
        ),
        const SizedBox(height: 16),
        Text(
          s.campaign.has('help_ines')
              ? 'Dona Inês se lembra da sua ajuda no hall.'
              : 'O encontro terminou sem matar Davi.',
          style: const TextStyle(color: ochre, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text(
              'PROGRESSO SALVO · 02:00 DESBLOQUEADO',
              style: TextStyle(color: mist, fontSize: 10, letterSpacing: 1.5),
            ),
            const Spacer(),
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

  Widget _opening() => ColoredBox(
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
                  '${s.openingPage + 1} / ${GameSession.opening.length}',
                  style: const TextStyle(color: mist),
                ),
              ],
            ),
          ),
          Expanded(
            child: NarrativeBackdrop(
              asset: s.openingPage == 4
                  ? 'assets/images/menu_santa_aurora_v1.png'
                  : s.openingPage.isEven
                  ? 'assets/images/legacy_subject07_lab.png'
                  : 'assets/images/legacy_laboratory.jpg',
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
                    _eyebrow(GameSession.opening[s.openingPage].$1),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .26,
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          GameSession.opening[s.openingPage].$2,
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
    final points = s.world.places;
    String id(Place p) => '${p.kind.name}:${p.id ?? p.label}';
    final selected = points.any((p) => id(p) == _mapTarget)
        ? _mapTarget
        : points.isEmpty
        ? null
        : id(points.first);
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
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: selected,
                  isExpanded: true,
                  items: [
                    for (final p in points)
                      DropdownMenuItem(
                        value: id(p),
                        child: Text(
                          p.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _mapTarget = value),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: selected == null
                    ? null
                    : () => s.navigateFromMap(selected),
                child: const Text('Caminhar até'),
              ),
            ],
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
    child: ColoredBox(
      color: Color.fromRGBO(
        177,
        204,
        183,
        s.reducedEffects ? .12 : .16 + math.sin(s.sceneTime * math.pi) * .15,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.objectTitle,
                  style: const TextStyle(color: parchment, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      s.objectBody,
                      style: const TextStyle(color: mist, height: 1.5),
                    ),
                  ),
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
            'No ônibus de Nestor · próxima esquina',
            style: TextStyle(color: parchment, fontSize: 17),
          ),
        ),
      ),
    ),
  );

  Widget _panel({required Widget child, double maxWidth = 700}) => _scrim(
    Center(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: MediaQuery.sizeOf(context).height - 48,
            ),
            child: _glass(
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget _scrim(Widget child, {double opacity = .65}) => ColoredBox(
    color: const Color(0xff08171e).withValues(alpha: opacity),
    child: child,
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
