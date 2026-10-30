import 'dart:convert';
import 'dart:ui' show Offset;

enum PlayPhase {
  menu,
  menuSettings,
  journey,
  opening,
  map,
  pulse,
  transit,
  buildingTransition,
  objectPanel,
  playing,
  dialogue,
  news,
  journal,
  paused,
  complete,
  defeated,
}

class JournalEntry {
  const JournalEntry(this.id, this.title, this.text, this.kind);
  final String id;
  final String title;
  final String text;
  final String kind;
}

class DialogueLine {
  const DialogueLine(this.id, this.speaker, this.mode, this.text);
  final String id;
  final String speaker;
  final String mode;
  final String text;
  Map<String, String> toJson() => {
    'id': id,
    'speaker': speaker,
    'mode': mode,
    'text': text,
  };

  factory DialogueLine.fromJson(Map<String, dynamic> value) {
    final fields = ['id', 'speaker', 'mode', 'text'];
    if (fields.any((key) => value[key] is! String)) {
      throw const FormatException('Fala sem identificação ou texto.');
    }
    final line = DialogueLine(
      value['id'],
      value['speaker'],
      value['mode'],
      value['text'],
    );
    if (line.speaker == 'CAIO' &&
        !['celular', 'escrita', 'gesto', 'Libras'].contains(line.mode)) {
      throw const FormatException('Caio se comunica sem fala vocal.');
    }
    return line;
  }
}

class Campaign {
  double x = 6, y = 6, health = 100, stamina = 100;
  double enemyHealth = 100;
  double nightEnemyHealth = 100;
  double? downedEnemyX, downedEnemyY;
  int floor = 2;
  final Set<String> openDoors = {};
  final Set<String> openWindows = {};
  final Set<String> brokenWindows = {};
  final Set<String> closedCurtains = {};
  final Set<String> removedCurtains = {};
  int storedBandages = 0;
  bool fridgeWater = true;
  bool backpackEquipped = true, weaponEquipped = true;
  int bandages = 0;
  bool injured = false;
  final Set<String> events = {};
  final List<DialogueLine> history = [];
  static const eventIds = {
    'phone',
    'key',
    'adapter',
    'weapon',
    'enemy_defeated',
    'help_ines',
    'delivered',
    'news',
    'socket',
    'alley',
    'resolved',
    'loot',
    'water',
    'bus_arrived',
    'bus',
    'pulse',
    'night',
    'answered_bia',
    'finish',
    'dog',
    'cat',
    'pigeon',
    'chapter2_started',
    'chapter2_torch',
    'chapter2_supply',
    'chapter2_panel',
    'chapter2_rescue',
    'chapter2_garage',
    'chapter2_alarm_off',
    'chapter2_lured',
    'chapter2_message',
    'chapter2_shortcut',
    'chapter2_enemy_down',
    'chapter2_complete',
    'home_tv_on',
    'home_lights_off',
  };
  bool has(String id) => events.contains(id);
  bool mark(String id) {
    if (!eventIds.contains(id)) throw ArgumentError.value(id);
    return events.add(id);
  }

  bool get inChapterTwo => has('chapter2_started');
  Offset? get downedEnemyPosition =>
      downedEnemyX == null ? null : Offset(downedEnemyX!, downedEnemyY!);

  void rememberDownedEnemy(Offset position) {
    downedEnemyX = position.dx;
    downedEnemyY = position.dy;
  }

  bool get finished => inChapterTwo ? has('chapter2_complete') : has('finish');
  bool get canLeave => has('delivered') && has('news') && has('resolved');
  bool get busReady => canLeave && has('pulse') && has('night');
  int get evidenceCount => [
    'delivered',
    'news',
    'resolved',
    'pulse',
    'night',
    'bus',
  ].where(has).length;
  static const markerTotal = 6;
  String get objective {
    if (inChapterTwo) {
      if (finished) {
        return '02:00 concluída. O mapa indica o caminho para A Queda.';
      }
      if (!has('chapter2_torch')) {
        return 'Pegue a lanterna no apartamento. O celular marca 01:58.';
      }
      if (floor == 2 && y < 10) {
        return 'Saia pela porta 203. O elevador está sem energia.';
      }
      if (!has('chapter2_panel')) {
        return 'Examine o quadro de manutenção no corredor.';
      }
      if (floor > 0) {
        return 'Desça pela escada. A vizinha da 202 precisa de ajuda opcional.';
      }
      if (!has('chapter2_garage')) {
        return 'Atravesse a garagem. Desligue o alarme ou use a lata como distração.';
      }
      if (!has('chapter2_message')) {
        return 'Confira a mensagem de Helena no celular.';
      }
      return 'Recolha o mapa no posto de serviço, atrás da oficina. A avenida também dá acesso.';
    }
    if (finished) {
      return 'Fase 01 concluída. 02:00 está disponível para a próxima fase.';
    }
    if (!has('phone')) return 'Confira a mensagem no celular, sobre a mesa.';
    if (!has('key') || !has('adapter')) {
      return 'Pegue a chave e o adaptador no apartamento.';
    }
    if (!has('delivered')) {
      if (floor == 1) return 'Desça ao térreo e leve o adaptador a Orlando.';
      if (floor == 2) {
        return y < 10
            ? 'Abra a porta 203 e leve o adaptador a Orlando.'
            : 'Desça pela escada até o térreo e siga para a mercearia.';
      }
      return 'Leve o adaptador a Orlando, na mercearia.';
    }
    if (!has('news')) return 'Leia a notícia na televisão da mercearia.';
    if (!has('resolved')) {
      return 'Atravesse o beco: crie distância ou feche o portão.';
    }
    if (!has('pulse')) return 'Siga até o cruzamento. A cidade está mudando.';
    if (!has('night')) return 'Confira a nova mensagem de Helena no celular.';
    if (!has('bus')) {
      if (has('bus_arrived')) {
        return 'O ônibus da linha 203 chegou. Embarque no ponto.';
      }
      if (floor == 0 &&
          (Offset(x, y) - const Offset(43.5, 29.5)).distance < 2) {
        return 'Aguarde no ponto. O ônibus da linha 203 está chegando.';
      }
      return 'Siga até o ponto da Rua das Flores e aguarde a linha 203.';
    }
    return 'Aguarde a partida do ônibus.';
  }

  String get location => floor == 2
      ? (y < 10 ? 'AP. 203 · 2º ANDAR' : 'CORREDOR · 2º ANDAR')
      : floor == 1
      ? 'CORREDOR · 1º ANDAR'
      : (y < 16 && x < 16
            ? 'TÉRREO · HALL RESIDENCIAL'
            : y < 17
            ? 'TÉRREO · GARAGEM'
            : 'SANTA AURORA');
  List<JournalEntry> get entries => [
    if (inChapterTwo)
      const JournalEntry(
        'chapter2_started',
        '01:58 · 02:00',
        'A energia caiu. O celular vibrou. Vou encontrar Helena sem depender do elevador.',
        'OBJETIVO',
      ),
    if (has('chapter2_panel'))
      const JournalEntry(
        'chapter2_panel',
        'Desligamento remoto',
        'O registro do painel indica um comando remoto às 02:00. Não foi uma pane local.',
        'EVIDÊNCIA',
      ),
    if (has('chapter2_rescue'))
      const JournalEntry(
        'chapter2_rescue',
        'A vizinha da 202',
        'Usei uma atadura e libertei a porta emperrada. Ela me deu a chave da passagem de serviço.',
        'CONSEQUÊNCIA',
      ),
    if (has('chapter2_message'))
      const JournalEntry(
        'chapter2_message',
        'Oficina da Rua do Mercado',
        'Helena pediu que eu fosse à entrada dos fundos. O mapa fica no posto de serviço.',
        'MENSAGEM',
      ),
    if (has('chapter2_complete'))
      const JournalEntry(
        'chapter2_complete',
        'Estou indo',
        'Mapa recolhido. A mensagem não foi enviada. Preciso alcançar a oficina.',
        'OBJETIVO',
      ),
    const JournalEntry(
      'start',
      '07:12 · Um Dia Normal',
      'Celular e caderno comigo. Preciso levar o adaptador para Orlando.',
      'OBJETIVO',
    ),
    if (has('phone'))
      const JournalEntry(
        'phone',
        'Mensagem de Helena',
        'Helena pediu que eu fosse ao centro. Pediu também que eu conferisse as mensagens do número dela.',
        'DEPOIMENTO',
      ),
    if (has('help_ines'))
      const JournalEntry(
        'ines',
        'A sacola de Dona Celina',
        'Ajudei a recolher as compras no hall.',
        'CONSEQUÊNCIA',
      ),
    if (has('answered_bia'))
      const JournalEntry(
        'answered_bia',
        'Bia no ponto da linha 203',
        'Respondi por mensagem. Bia espera a linha e procura notícias da mãe, que trabalha perto do hospital.',
        'CONSEQUÊNCIA',
      ),
    if (has('delivered'))
      const JournalEntry(
        'delivery',
        'Entrega feita',
        'Orlando recebeu o adaptador e autorizou pegar uma atadura no sedã.',
        'OBSERVAÇÃO',
      ),
    if (has('socket'))
      const JournalEntry(
        'socket',
        'Tomada queimada',
        'A marca de calor se repete ao redor dos contatos. Pode haver um padrão nas oscilações.',
        'HIPÓTESE',
      ),
    if (has('news'))
      const JournalEntry(
        'news',
        'Manutenção noturna',
        'A televisão anuncia manutenção da rede às 02:00.',
        'OBSERVAÇÃO',
      ),
    if (has('resolved') && !has('enemy_defeated'))
      const JournalEntry(
        'davi',
        'Uma saída sem matar',
        'Davi estava em crise. Consegui separar os dois.',
        'CONSEQUÊNCIA',
      ),
    if (has('enemy_defeated'))
      const JournalEntry(
        'enemy_defeated',
        'Davi ficou inconsciente',
        'O cano improvisado interrompeu o ataque. Davi ainda respirava; Caio se afastou sem continuar a agressão.',
        'CONSEQUÊNCIA',
      ),
    if (has('pulse'))
      const JournalEntry(
        'pulse',
        'A cidade parou',
        'Todos interromperam o movimento. Eu permaneci consciente.',
        'OBSERVAÇÃO',
      ),
    if (has('night'))
      const JournalEntry(
        'night',
        'Hoje, às duas',
        'Helena avisou: se a torre acender, ficar longe da avenida.',
        'MENSAGEM',
      ),
  ];
  Map<String, dynamic> toJson() => {
    'schema_version': 2,
    'floor': floor,
    'open_doors': openDoors.toList()..sort(),
    'open_windows': openWindows.toList()..sort(),
    'broken_windows': brokenWindows.toList()..sort(),
    'closed_curtains': closedCurtains.toList()..sort(),
    'removed_curtains': removedCurtains.toList()..sort(),
    'stored_bandages': storedBandages,
    'fridge_water': fridgeWater,
    'backpack_equipped': backpackEquipped,
    'weapon_equipped': weaponEquipped,
    'x': x,
    'y': y,
    'health': health,
    'stamina': stamina,
    'enemy_health': enemyHealth,
    'night_enemy_health': nightEnemyHealth,
    if (downedEnemyX != null && downedEnemyY != null) ...{
      'downed_enemy_x': downedEnemyX,
      'downed_enemy_y': downedEnemyY,
    },
    'bandages': bandages,
    'injured': injured,
    'events': events.toList()..sort(),
    'history': history.map((v) => v.toJson()).toList(),
  };
  String encode() => jsonEncode(toJson());
  static Campaign decode(String source) {
    final d = jsonDecode(source);
    if (d is! Map<String, dynamic> || d['schema_version'] != 2) {
      throw const FormatException('Versão de progresso incompatível.');
    }
    double number(String k, double max) {
      final v = d[k];
      if (v is! num || !v.isFinite || v < 0 || v > max) {
        throw FormatException('Progresso inválido: $k');
      }
      return v.toDouble();
    }

    double optionalNumber(String k, double max, double fallback) {
      if (!d.containsKey(k)) return fallback;
      final v = d[k];
      if (v is! num || !v.isFinite || v < 0 || v > max) {
        throw FormatException('Progresso inválido: $k');
      }
      return v.toDouble();
    }

    final es = d['events'], hs = d['history'], bs = d['bandages'];
    if (es is! List ||
        es.any((v) => v is! String || !eventIds.contains(v)) ||
        hs is! List ||
        hs.any((v) => v is! Map<String, dynamic>) ||
        bs is! int ||
        bs < 0 ||
        bs > 10 ||
        d['injured'] is! bool) {
      throw const FormatException('Inventário ou eventos inválidos.');
    }
    final c = Campaign()
      ..x = number('x', 55)
      ..y = number('y', 43)
      ..health = number('health', 100)
      ..stamina = number('stamina', 100)
      ..enemyHealth = optionalNumber('enemy_health', 100, 100)
      ..nightEnemyHealth = optionalNumber('night_enemy_health', 100, 100)
      ..bandages = bs
      ..injured = d['injured'];
    final downedX = d['downed_enemy_x'];
    final downedY = d['downed_enemy_y'];
    if (downedX != null || downedY != null) {
      if (downedX is! num ||
          downedY is! num ||
          !downedX.isFinite ||
          !downedY.isFinite ||
          downedX < 0 ||
          downedX > 55 ||
          downedY < 0 ||
          downedY > 43) {
        throw const FormatException('Posição do inimigo inválida.');
      }
      c
        ..downedEnemyX = downedX.toDouble()
        ..downedEnemyY = downedY.toDouble();
    }
    // Version 0.2 saves had one continuous map. Preserve inventory and infer its floor.
    final savedFloor = d.containsKey('floor')
        ? d['floor']
        : (c.x < 12 && c.y < 16 ? 2 : 0);
    if (savedFloor != 0 && savedFloor != 1 && savedFloor != 2) {
      throw const FormatException('Andar inválido.');
    }
    c.floor = savedFloor as int;
    final doors = d['open_doors'] ?? <dynamic>[];
    final windows = d['open_windows'] ?? <dynamic>[];
    final stored = d['stored_bandages'] ?? 0;
    final water = d['fridge_water'] ?? true;
    final backpack = d['backpack_equipped'] ?? true;
    final weapon = d['weapon_equipped'] ?? true;
    if (doors is! List ||
        doors.any(
          (v) => v is! String || !['entrada', 'banheiro'].contains(v),
        ) ||
        windows is! List ||
        windows.any(
          (v) =>
              v is! String ||
              !['103', '102', '101', '203', '202', '201'].contains(v),
        ) ||
        stored is! int ||
        stored < 0 ||
        stored > 999 ||
        water is! bool ||
        backpack is! bool ||
        weapon is! bool) {
      throw const FormatException('Estado doméstico inválido.');
    }
    c.openDoors.addAll(doors.cast<String>());
    c.openWindows.addAll(windows.cast<String>());
    for (final entry in {
      'broken_windows': c.brokenWindows,
      'closed_curtains': c.closedCurtains,
      'removed_curtains': c.removedCurtains,
    }.entries) {
      final values = d[entry.key] ?? <dynamic>[];
      if (values is! List ||
          values.any(
            (v) =>
                v is! String ||
                !['103', '102', '101', '203', '202', '201'].contains(v),
          )) {
        throw const FormatException('Estado de janela inválido.');
      }
      entry.value.addAll(values.cast<String>());
    }
    c.closedCurtains.removeAll(c.removedCurtains);

    c.storedBandages = stored;
    c.fridgeWater = water;
    c.backpackEquipped = backpack;
    c.weaponEquipped = weapon;
    c.events.addAll(es.cast<String>());
    c.history.addAll(
      hs.map((v) => DialogueLine.fromJson(v as Map<String, dynamic>)),
    );
    if (c.history.map((v) => v.id).toSet().length != c.history.length ||
        (c.has('finish') &&
            (!c.has('night') ||
                !c.has('pulse') ||
                !c.has('bus_arrived') ||
                !c.has('bus') ||
                !c.canLeave)) ||
        (c.has('loot') && !c.has('delivered')) ||
        (c.has('delivered') && !c.has('adapter')) ||
        (c.has('enemy_defeated') &&
            (!c.has('weapon') ||
                !c.has('alley') ||
                !c.has('resolved') ||
                c.enemyHealth != 0)) ||
        (!c.has('enemy_defeated') && c.enemyHealth == 0) ||
        (c.inChapterTwo && !c.has('finish')) ||
        (!c.inChapterTwo && c.events.any((id) => id.startsWith('chapter2_'))) ||
        (c.has('chapter2_complete') &&
            (!c.inChapterTwo ||
                !c.has('chapter2_message') ||
                !c.has('chapter2_garage'))) ||
        (c.has('chapter2_enemy_down') != (c.nightEnemyHealth == 0))) {
      throw const FormatException('Eventos incompatíveis.');
    }
    return c;
  }
}
