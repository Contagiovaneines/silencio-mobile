import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/campaign.dart';
import '../services/save_repository.dart';
import 'world_model.dart';
import 'building_transition.dart';
import 'building_layout.dart';

class GameSession extends ChangeNotifier {
  GameSession(this.repository, this.lines, this.news)
    : world = WorldModel(Campaign()) {
    final saved = repository.load();
    if (saved != null) {
      world.restore(saved);
      hasSave = true;
    }
    soundEnabled = repository.preferences.getBool('silencio.sound') ?? true;
    reducedEffects =
        repository.preferences.getBool('silencio.effects') ?? false;
    largerText = repository.preferences.getBool('silencio.text') ?? false;
    openingAuto =
        repository.preferences.getBool('silencio.openingAuto') ?? false;
    notice = repository.warning ?? '';
  }
  final SaveRepository repository;
  final List<DialogueLine> lines;
  final Map<String, dynamic> news;
  final WorldModel world;
  Campaign get campaign => world.campaign;
  PlayPhase phase = PlayPhase.menu;
  BuildingTransition? buildingTransition;
  String objectTitle = '', objectBody = '';
  PointKind? objectKind;
  final List<({String label, bool enabled, VoidCallback run})> objectActions =
      [];

  bool hasSave = false,
      reducedEffects = false,
      largerText = false,
      soundEnabled = true;
  bool openingAuto = false;
  PlayPhase _journeyReturn = PlayPhase.menu;
  bool get journeyFromMap => _journeyReturn == PlayPhase.map;
  String notice = '';
  double noticeTime = 0, elapsed = 0, _uiElapsed = 0, sceneTime = 0;
  int newsPage = 0, dialogueIndex = 0, openingPage = 0;
  double _autosaveTime = 0;
  List<DialogueLine> activeLines = [];
  VoidCallback? _afterDialogue;
  DialogueLine? get currentLine =>
      dialogueIndex < activeLines.length ? activeLines[dialogueIndex] : null;
  static const opening = [
    (
      'DOZE ANOS ANTES',
      'Uma sala clínica. Uma criança pede uma pausa. A luz vermelha acende antes que a resposta seja registrada.',
    ),
    (
      'O PRIMEIRO EXPERIMENTO',
      'MÉDICA: Ele pediu uma pausa.\nCABINE: Continuem. Precisamos de uma leitura estável.',
    ),
    (
      'RESPOSTA ATÍPICA',
      'SAMUEL: Então por que o padrão está se adaptando?\nA médica desconecta o eletrodo principal.',
    ),
    (
      'SUJEITO 07',
      'Samuel encontra o desenho de uma casa com uma torre riscada. A pasta recebe uma identificação, não uma resposta.',
    ),
    (
      'DOZE ANOS DEPOIS',
      '07:12. Chuva no vidro.\nSanta Aurora ainda parece uma cidade comum.',
    ),
  ];
  static Future<GameSession> load(SaveRepository repository) async {
    final d = jsonDecode(
      await rootBundle.loadString('assets/data/chapter_01.json'),
    ) as Map<String, dynamic>;
    return GameSession(
      repository,
      (d['dialogue'] as List)
          .map((v) => DialogueLine.fromJson(v as Map<String, dynamic>))
          .toList(),
      d['news'] as Map<String, dynamic>,
    );
  }

  void _change(PlayPhase value) {
    phase = value;
    world.stop();
    notifyListeners();
  }

  void tick(double dt) {
    elapsed += dt;
    if (noticeTime > 0) {
      noticeTime -= dt;
      if (noticeTime <= 0) notice = '';
    }
    if (phase == PlayPhase.opening) {
      sceneTime += dt;
      if (openingAuto && sceneTime >= 13) {
        nextOpening();
      }
    }
    if (phase == PlayPhase.playing) {
      final resolved = campaign.has('resolved');
      final bandages = campaign.bandages;
      final fridgeWater = campaign.fridgeWater;
      world.update(dt);
      _autosaveTime += dt;
      if (campaign.bandages != bandages ||
          campaign.fridgeWater != fridgeWater ||
          (_autosaveTime >= 20 &&
              !world.encounterActive &&
              world.action == 'idle')) {
        _autosaveTime = 0;
        unawaited(save());
      }
      if (!resolved && campaign.has('resolved')) {
        tell('Davi ficou para trás. Ninguém precisava morrer.');
        unawaited(checkpoint());
      }
      if (campaign.health <= 0) {
        world.beginAction('defeat', 2);
        _change(PlayPhase.defeated);
      }
    }
    if (phase == PlayPhase.buildingTransition) {
      if (buildingTransition!.advance(dt, world)) {
        final wasDoor = buildingTransition!.isDoor;
        buildingTransition = null;
        _change(PlayPhase.playing);
        world.sounds.add(wasDoor ? 'door' : 'step');
        tell(
          wasDoor
              ? campaign.location
              : campaign.floor == 0
              ? 'Térreo. A garagem leva à rua.'
              : campaign.floor == 1
              ? '1º andar. Você pode subir ao 2º ou descer ao térreo.'
              : '2º andar. Sua porta é a 203.',
        );
        unawaited(checkpoint());
      }
    }
    if (phase == PlayPhase.pulse) {
      sceneTime += dt;
      if (sceneTime >= 2) {
        campaign.mark('pulse');
        _openDialogue(
          [
            const DialogueLine(
              'pulse_mother',
              'NARRAÇÃO',
              'observação visual',
              'Ao longe, Marina protege Bia e tenta guiá-la. Caio acompanha os movimentos; não consegue ler seus lábios daqui.',
            ),
            const DialogueLine(
              'pulse_caio',
              'CAIO',
              'escrita',
              'Todo mundo sentiu alguma coisa. Eu só vi as pessoas pararem.',
            ),
            const DialogueLine(
              'pulse_orlando',
              'NARRAÇÃO',
              'observação visual',
              'Orlando olha em volta, inquieto, e faz um gesto para Caio. À distância, a intenção não fica clara.',
            ),
          ],
          after: () {
            tell('O celular vibrou. Leia a mensagem de Helena.');
            unawaited(checkpoint());
          },
        );
      }
    }
    if (phase == PlayPhase.transit) {
      sceneTime += dt;
      if (sceneTime >= 3) {
        campaign.mark('bus');
        campaign.x = 48.5;
        campaign.y = 28;
        _pulse();
      }
    }
    _uiElapsed += dt;
    if (_uiElapsed >= .1) {
      _uiElapsed = 0;
      notifyListeners();
    }
  }

  void tell(String text) {
    notice = text;
    noticeTime = 5;
    notifyListeners();
  }

  void startNew() {
    world.restore(Campaign());
    elapsed = 0;
    openingPage = 0;
    sceneTime = 0;
    _change(PlayPhase.opening);
    unawaited(checkpoint());
  }

  void replayOpening() {
    openingPage = 0;
    sceneTime = 0;
    _change(PlayPhase.opening);
  }

  bool _replaying = false;
  void replay() {
    _replaying = true;
    replayOpening();
  }

  void previousOpening() {
    if (phase != PlayPhase.opening || openingPage == 0) return;
    openingPage--;
    sceneTime = 0;
    notifyListeners();
  }

  void toggleOpeningAuto() {
    openingAuto = !openingAuto;
    sceneTime = 0;
    unawaited(
      repository.preferences.setBool('silencio.openingAuto', openingAuto),
    );
    notifyListeners();
  }

  void menuSettings() {
    if (phase == PlayPhase.menu) _change(PlayPhase.menuSettings);
  }

  void journey() {
    if (![PlayPhase.menu, PlayPhase.map, PlayPhase.complete].contains(phase)) {
      return;
    }
    _journeyReturn = phase;
    _change(PlayPhase.journey);
  }

  void nextOpening() {
    openingPage++;
    sceneTime = 0;
    if (openingPage >= opening.length) {
      finishOpening();
    } else {
      notifyListeners();
    }
  }

  void finishOpening() {
    if (_replaying) {
      _replaying = false;
      _change(PlayPhase.menu);
      return;
    }
    _change(PlayPhase.playing);
    tell('07:12. Confira o celular e pegue a chave e o adaptador.');
  }

  void resume() {
    final saved = repository.load();
    if (saved != null) {
      world.restore(saved);
      _change(saved.finished ? PlayPhase.complete : PlayPhase.playing);
    }
  }

  Future<void> retry() async {
    final raw = repository.preferences.getString(
      '${SaveRepository.key}.checkpoint',
    );
    Campaign? c;
    if (raw != null) {
      try {
        c = Campaign.decode(raw);
      } on FormatException {
        c = null;
      }
    }
    world.restore(c ?? Campaign());
    _change(PlayPhase.playing);
    await save();
  }

  Future<void> save() async {
    if (campaign.health <= 0 || phase == PlayPhase.buildingTransition) return;
    try {
      await repository.save(campaign);
      hasSave = true;
    } catch (_) {
      tell('O aparelho não confirmou o salvamento. A partida continua.');
    }
  }

  Future<void> checkpoint() async {
    if (campaign.health <= 0 || phase == PlayPhase.buildingTransition) return;
    final safe = !world.encounterActive;
    final snapshot = campaign.encode();
    await save();
    if (safe) {
      await repository.preferences.setString(
        '${SaveRepository.key}.checkpoint',
        snapshot,
      );
    }
  }

  Future<void> toMenu() async {
    _change(PlayPhase.paused);
    await save();
    _change(PlayPhase.menu);
  }

  void pause() {
    if (phase == PlayPhase.playing) _change(PlayPhase.paused);
  }

  void closePanel() {
    if (phase == PlayPhase.menuSettings) {
      _change(PlayPhase.menu);
      return;
    }
    if (phase == PlayPhase.journey) {
      _change(_journeyReturn);
      return;
    }
    world.resting = null;
    world.restAnchor = null;
    objectKind = null;
    _change(PlayPhase.playing);
  }

  void journal() => _change(PlayPhase.journal);
  void map() => _change(PlayPhase.map);
  void navigateFromMap(String key) {
    if (phase != PlayPhase.map) return;
    final targets = world.places.where(
      (p) => '${p.kind.name}:${p.id ?? p.label}' == key,
    );
    if (targets.isEmpty) return;
    final point = targets.first;
    closePanel();
    world.moveTo(point.x, point.y);
  }

  void toggleEffects() {
    reducedEffects = !reducedEffects;
    unawaited(
      repository.preferences.setBool('silencio.effects', reducedEffects),
    );
    notifyListeners();
  }

  void toggleText() {
    largerText = !largerText;
    unawaited(repository.preferences.setBool('silencio.text', largerText));
    notifyListeners();
  }

  void toggleSound() {
    soundEnabled = !soundEnabled;
    unawaited(repository.preferences.setBool('silencio.sound', soundEnabled));
    notifyListeners();
  }

  void toggleRun() {
    world.running = !world.running;
    notifyListeners();
  }

  void togglePerception() {
    if (phase != PlayPhase.playing) return;
    world.perception = !world.perception;
    notifyListeners();
  }

  void push() {
    if (phase != PlayPhase.playing) return;
    if (!world.push()) tell('Recupere o fôlego antes de empurrar.');
    notifyListeners();
  }

  void heal() {
    if (phase != PlayPhase.playing) return;
    if (!world.heal()) {
      tell(
        world.encounterActive
            ? 'Afaste-se da ameaça para tratar o braço.'
            : 'Você precisa de ferimento e atadura para tratar.',
      );
    }
    notifyListeners();
  }

  void phone() {
    if (campaign.has('pulse')) {
      _openDialogue(
        [
          const DialogueLine(
            'night_helena',
            'HELENA',
            'mensagem',
            'Mudaram o horário. Hoje, às duas. Se a torre acender, fica longe da avenida.',
          ),
          const DialogueLine(
            'night_caio',
            'CAIO',
            'celular',
            'Você está onde?',
          ),
          const DialogueLine(
            'night_helena2',
            'HELENA',
            'mensagem',
            'Ainda não posso dizer.',
          ),
        ],
        after: () {
          campaign.mark('night');
          unawaited(checkpoint());
        },
      );
    } else {
      _openDialogue(
        lines,
        after: () {
          campaign.mark('phone');
          unawaited(checkpoint());
        },
      );
    }
    world.sounds.add('phone');
  }

  void _pulse() {
    if (campaign.has('pulse')) {
      tell('A mensagem de Helena está no celular.');
      return;
    }
    sceneTime = 0;
    world.sounds.add('pulse');
    _change(PlayPhase.pulse);
  }

  void _pickup(String id, String text) {
    if (!campaign.mark(id)) return;
    world.beginAction('pickup', .7);
    world.sounds.add('pickup');
    tell(text);
    unawaited(checkpoint());
  }

  void _buildingJourney(BuildingJourney kind, {String doorId = '203'}) {
    buildingTransition = BuildingTransition(
      kind,
      Offset(campaign.x, campaign.y),
      sourceFloor: campaign.floor,
      doorId: doorId,
    );
    _change(PlayPhase.buildingTransition);
    world.sounds.add('door');
  }

  void _useDoor(String id) {
    final door = ResidentialLayout.door(id);
    if (door.locked) {
      tell(
        'Porta $id fechada. O acesso a esta residência não está disponível nesta fase.',
      );
      return;
    }
    if (id == '203' && !campaign.has('key')) {
      tell('A chave de casa está na cozinha. Pegue antes de sair.');
      return;
    }
    final position = Offset(campaign.x, campaign.y);
    final inside =
        (position - door.inside).distance < (position - door.outside).distance;
    final approach = inside ? door.inside : door.outside;
    if (!world.canTravel(position, approach)) {
      tell('Aproxime-se do lado livre da porta.');
      return;
    }
    _buildingJourney(
      inside ? BuildingJourney.leaveApartment : BuildingJourney.enterApartment,
      doorId: id,
    );
  }

  void openObject(PointKind kind) {
    objectKind = kind;
    objectActions.clear();
    void action(String label, bool enabled, VoidCallback run) =>
        objectActions.add((label: label, enabled: enabled, run: run));
    switch (kind) {
      case PointKind.bed:
        objectTitle = 'Cama · apartamento 203';
        objectBody = 'Você pode descansar e salvar. A fase termina aqui somente depois dos acontecimentos do dia. Descansar não adianta o relógio nem cura ferimentos.';
        world.resting = 'lie';
        world.restAnchor = const Offset(4.2, 4.3);
        action('Salvar progresso', true, () {
          unawaited(checkpoint());
          tell('Progresso salvo.');
        });
      case PointKind.sofa:
      case PointKind.chair:
        objectTitle = kind == PointKind.sofa
            ? 'Sofá'
            : 'Cadeira da escrivaninha';
        objectBody = 'Um instante de descanso. Levantar devolve o controle sem alterar seus objetivos.';
        world.resting = 'sit';
        world.restAnchor = kind == PointKind.sofa
            ? const Offset(3.8, 8.2)
            : const Offset(6.4, 4.8);
      case PointKind.wardrobe:
        objectTitle = 'Guarda-roupa · armazenamento';
        objectBody =
            'Ataduras com Caio: ${campaign.bandages}\nGuardadas: ${campaign.storedBandages}\nItens de missão permanecem com Caio.';
        world.resting = 'reach';
        action(
          'Guardar uma atadura',
          campaign.bandages > 0 && campaign.storedBandages < 999,
          () {
            campaign.bandages--;
            campaign.storedBandages++;
            unawaited(checkpoint());
            openObject(kind);
          },
        );
        action('Retirar uma atadura', campaign.storedBandages > 0, () {
          campaign.storedBandages--;
          campaign.bandages++;
          unawaited(checkpoint());
          openObject(kind);
        });
      case PointKind.refrigerator:
        objectTitle = 'Geladeira';
        objectBody = campaign.fridgeWater
            ? 'Uma porção de água disponível. Beber recupera o fôlego, sem tratar ferimentos.'
            : 'Você já bebeu a água disponível.';
        world.resting = 'reach';
        action('Beber água', campaign.fridgeWater, () {
          closePanel();
          world.beginAction('drink', 1.8);
        });
      case PointKind.notebook:
        objectTitle = 'Notebook · arquivos locais';
        objectBody =
            'Caderno do dia\n${campaign.objective}\n\n${campaign.entries.map((e) => '${e.title}\n${e.text}').join('\n\n')}';
        world.resting = 'typing';
        world.restAnchor = const Offset(6.4, 4.8);
      default:
        return;
    }
    _change(PlayPhase.objectPanel);
  }

  void interact() {
    if (phase != PlayPhase.playing || world.action != 'idle') return;
    final p = world.nearby;
    if (p == null) {
      tell('Aproxime-se de uma pessoa ou de um objeto marcado.');
      return;
    }
    switch (p.kind) {
      case PointKind.ladder:
        if (world.climbLadder())
          tell(
            world.onRoof ? 'Caio desce pelos apoios.' : 'Caio sobe pela escada até o patamar. Use a mesma escada para descer.',
          );
      case PointKind.apartmentDoor:
        _useDoor('203');
      case PointKind.buildingDoor:
        _useDoor(p.id!);
      case PointKind.chair:
      case PointKind.sofa:
      case PointKind.wardrobe:
      case PointKind.refrigerator:
      case PointKind.notebook:
        openObject(p.kind);
      case PointKind.bathroom:
        tell(
          'Banheiro do apartamento 203. Pia, chuveiro e vaso; passagem pela porta própria.',
        );
      case PointKind.noticeboard:
        tell(
          'Entrada residencial no térreo. Elevador em manutenção: utilize a escada.',
        );
      case PointKind.stairsDown:
        _buildingJourney(BuildingJourney.downstairs);
      case PointKind.stairsUp:
        _buildingJourney(BuildingJourney.upstairs);
      case PointKind.elevator:
        tell(
          'Em manutenção. A placa orienta usar a escada no fim do corredor.',
        );

      case PointKind.phone:
        phone();
      case PointKind.key:
        _pickup(
          'key',
          'Chave guardada. Aproxime-se da porta 203 para abrir e sair.',
        );
      case PointKind.adapter:
        _pickup('adapter', 'Adaptador recolhido. Orlando espera na mercearia.');
      case PointKind.bed:
        if (campaign.has('night') &&
            campaign.has('pulse') &&
            campaign.canLeave) {
          world.resting = 'lie';
          world.restAnchor = const Offset(4.2, 4.3);
          campaign.mark('finish');
          _change(PlayPhase.complete);
          unawaited(checkpoint());
        } else {
          openObject(PointKind.bed);
          unawaited(checkpoint());
        }
      case PointKind.neighbor:
        _openDialogue(
          [
            DialogueLine(
              'ines_bag',
              'INÊS',
              'fala',
              campaign.has('help_ines')
                  ? 'Obrigada de novo, Caio. Orlando abriu cedo.'
                  : 'Minha sacola rasgou... Você me ajuda com as compras?',
            ),
            const DialogueLine(
              'ines_caio',
              'CAIO',
              'gesto',
              'Caio recolhe as compras e oferece a sacola.',
            ),
          ],
          after: () {
            campaign.mark('help_ines');
            unawaited(checkpoint());
          },
        );
      case PointKind.merchant:
        if (!campaign.has('adapter')) {
          tell('O adaptador ficou no apartamento.');
          return;
        }
        if (!campaign.has('delivered')) {
          _openDialogue(
            [
              const DialogueLine(
                'orlando_delivery',
                'ORLANDO',
                'fala',
                'O adaptador! Obrigado, Caio. A tomada queimou de novo. Pode olhar a televisão enquanto eu testo.',
              ),
              const DialogueLine(
                'caio_delivery',
                'CAIO',
                'celular',
                'A marca nos contatos está igual à de ontem.',
              ),
              const DialogueLine(
                'orlando_permission',
                'ORLANDO',
                'fala',
                'Tem uma atadura no porta-malas do meu sedã, na garagem. Pode pegar se precisar. E a água está ali.',
              ),
              const DialogueLine(
                'helena_cancel',
                'HELENA',
                'mensagem',
                'Não posso aparecer em público. Espere minhas instruções. Confira o número antes de responder.',
              ),
            ],
            after: () {
              campaign.mark('delivered');
              world.sounds.add('phone');
              unawaited(checkpoint());
            },
          );
        } else {
          _openDialogue([
            const DialogueLine(
              'orlando_again',
              'ORLANDO',
              'fala',
              'A manutenção da rede é só de madrugada. Vá pela praça, o beco encurta o caminho até o ônibus.',
            ),
          ]);
        }
      case PointKind.television:
        newsPage = 0;
        _change(PlayPhase.news);
      case PointKind.panel:
        _openDialogue(
          [
            const DialogueLine(
              'socket_read',
              'CAIO',
              'escrita',
              'O calor marcou os mesmos contatos. Um padrão... mas ainda não sei o que significa.',
            ),
          ],
          after: () {
            campaign.mark('socket');
            unawaited(save());
          },
        );
      case PointKind.sedan:
        if (!campaign.has('delivered')) {
          tell('O carro é de Orlando. Preciso pedir autorização.');
          return;
        }
        if (campaign.has('loot')) {
          tell('O porta-malas já foi revistado.');
          return;
        }
        campaign.bandages = (campaign.bandages + 1).clamp(0, 10);
        _pickup('loot', 'Porta-malas aberto: uma atadura.');
        world.sounds.add('door');
      case PointKind.water:
        campaign.stamina = 100;
        _pickup(
          'water',
          'Água recolhida. Fôlego recuperado; ferimentos precisam de atadura.',
        );
      case PointKind.gate:
        if (!campaign.has('alley')) {
          tell('Alavanca manual do zelador. Pode separar o beco da passagem.');
          return;
        }
        campaign.mark('resolved');
        world.gateClosed = true;
        world.sounds.add('door');
        world.enemyStun = 5;
        tell('A divisória separou Davi. A passagem está livre.');
        unawaited(checkpoint());
      case PointKind.bus:
        if (!campaign.canLeave) {
          tell(campaign.objective);
          return;
        }
        if (campaign.has('bus') || campaign.has('pulse')) {
          tell('A viagem já terminou. Volte a pé para casa.');
          return;
        }
        _openDialogue(
          [
            const DialogueLine(
              'nestor_board',
              'NESTOR',
              'fala',
              'Eu levo você até a próxima esquina. Pode ir a pé também. Sente perto da porta.',
            ),
          ],
          after: () {
            sceneTime = 0;
            world.sounds.add('engine');
            _change(PlayPhase.transit);
          },
        );
      case PointKind.crossing:
        if (!campaign.canLeave) {
          tell(campaign.objective);
          return;
        }
        _pulse();
      case PointKind.dog:
        campaign.mark('dog');
        world.sounds.add('dog');
        tell(world.animals.interact('fuba', canOccupy: world.animalCanOccupy));
      case PointKind.cat:
        campaign.mark('cat');
        world.sounds.add('cat');
        tell(world.animals.interact('breu', canOccupy: world.animalCanOccupy));
      case PointKind.pigeon:
        campaign.mark('pigeon');

        world.sounds.add('bird');
        tell(
          world.isNight
              ? 'Um morcego cruza a luz e procura um pouso protegido.'
              : world.animals.interact(
                  'pingo',
                  canOccupy: world.animalCanOccupy,
                ),
        );
    }
  }

  void _openDialogue(List<DialogueLine> values, {VoidCallback? after}) {
    activeLines = values.map((line) {
      if (line.mode != 'fala' || line.speaker == 'CAIO') return line;
      final id = line.speaker.toLowerCase().replaceAll('ê', 'e');
      final matches = world.people.where((p) => p.id == id);
      final visible = matches.any(
        (p) =>
            world.distance(p.x, p.y) <= 2.4 &&
            world.lineClear(Offset(campaign.x, campaign.y), Offset(p.x, p.y)),
      );
      return visible
          ? DialogueLine(line.id, line.speaker, 'leitura labial', line.text)
          : DialogueLine(
              line.id,
              line.speaker,
              'observação visual',
              'O rosto está distante ou encoberto. Caio precisa se aproximar para compreender.',
            );
    }).toList();
    dialogueIndex = 0;
    _afterDialogue = after;
    _change(PlayPhase.dialogue);
    _remember();
  }

  void _remember() {
    final line = currentLine;
    if (line != null && !campaign.history.any((v) => v.id == line.id)) {
      campaign.history.add(line);
    }
  }

  void nextLine() {
    if (phase != PlayPhase.dialogue) return;
    dialogueIndex++;
    if (dialogueIndex >= activeLines.length) {
      final cb = _afterDialogue;
      _afterDialogue = null;
      _change(PlayPhase.playing);
      cb?.call();
      unawaited(save());
    } else {
      _remember();
      notifyListeners();
    }
  }

  void advanceNews() {
    if (phase != PlayPhase.news) return;
    if (newsPage < (news['pages'] as List).length - 1) {
      newsPage++;
      notifyListeners();
    } else {
      campaign.mark('news');
      _change(PlayPhase.playing);
      tell('Notícia registrada no caderno.');
      unawaited(checkpoint());
    }
  }
}
