import 'dart:convert';

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
  int floor = 2;
  final Set<String> openDoors = {};
  int storedBandages = 0;
  bool fridgeWater = true;
  int bandages = 0;
  bool injured = false;
  final Set<String> events = {};
  final List<DialogueLine> history = [];
  static const eventIds = {
    'phone',
    'key',
    'adapter',
    'help_ines',
    'delivered',
    'news',
    'socket',
    'alley',
    'resolved',
    'loot',
    'water',
    'bus',
    'pulse',
    'night',
    'finish',
    'dog',
    'cat',
    'pigeon',
  };
  bool has(String id) => events.contains(id);
  bool mark(String id) {
    if (!eventIds.contains(id)) throw ArgumentError.value(id);
    return events.add(id);
  }

  bool get finished => has('finish');
  bool get canLeave => has('delivered') && has('news') && has('resolved');
  int get evidenceCount =>
      ['delivered', 'news', 'resolved', 'pulse', 'night'].where(has).length;
  String get objective {
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
    if (!has('pulse')) return 'Vá à parada. Você pode embarcar ou seguir a pé.';
    if (!has('night')) return 'Leia a mensagem de Helena no celular.';
    return 'Volte ao apartamento 203, no 2º andar, e use a cama.';
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
        'A sacola de Dona Inês',
        'Ajudei a recolher as compras no hall.',
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
    if (has('resolved'))
      const JournalEntry(
        'davi',
        'Uma saída sem matar',
        'Davi estava em crise. Consegui separar os dois.',
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
    'stored_bandages': storedBandages,
    'fridge_water': fridgeWater,
    'x': x,
    'y': y,
    'health': health,
    'stamina': stamina,
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
      ..bandages = bs
      ..injured = d['injured'];
    // Version 0.2 saves had one continuous map. Preserve inventory and infer its floor.
    final savedFloor = d.containsKey('floor')
        ? d['floor']
        : (c.x < 12 && c.y < 16 ? 2 : 0);
    if (savedFloor != 0 && savedFloor != 1 && savedFloor != 2) {
      throw const FormatException('Andar inválido.');
    }
    c.floor = savedFloor as int;
    final doors = d['open_doors'] ?? <dynamic>[];
    final stored = d['stored_bandages'] ?? 0;
    final water = d['fridge_water'] ?? true;
    if (doors is! List ||
        doors.any(
          (v) => v is! String || !['entrada', 'banheiro'].contains(v),
        ) ||
        stored is! int ||
        stored < 0 ||
        stored > 999 ||
        water is! bool) {
      throw const FormatException('Estado doméstico inválido.');
    }
    c.openDoors.addAll(doors.cast<String>());
    c.storedBandages = stored;
    c.fridgeWater = water;
    c.events.addAll(es.cast<String>());
    c.history.addAll(
      hs.map((v) => DialogueLine.fromJson(v as Map<String, dynamic>)),
    );
    if (c.history.map((v) => v.id).toSet().length != c.history.length ||
        (c.finished && (!c.has('night') || !c.has('pulse') || !c.canLeave)) ||
        (c.has('loot') && !c.has('delivered')) ||
        (c.has('delivered') && !c.has('adapter'))) {
      throw const FormatException('Eventos incompatíveis.');
    }
    return c;
  }
}
