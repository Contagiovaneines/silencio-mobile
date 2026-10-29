import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:silencio/models/campaign.dart';

void main() {
  test('save preserves inventory, events, injury and actual dialogue', () {
    final c = Campaign()
      ..bandages = 2
      ..injured = true;
    c.events.addAll(['key', 'adapter', 'delivered', 'news', 'resolved']);
    c.history.add(
      const DialogueLine('read', 'CAIO', 'escrita', 'Uma marca na tomada.'),
    );
    final d = Campaign.decode(c.encode());
    expect(d.toJson(), c.toJson());
    expect(d.canLeave, isTrue);
  });
  test(
    'unknown version, invalid numbers and impossible progression are rejected',
    () {
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (d) => d['schema_version'] = 99,
        (d) => d['health'] = -2,
        (d) => d['events'] = ['finish'],
        (d) => d['events'] = ['loot'],
        (d) => d['events'] = ['unknown'],
      ]) {
        final d = Campaign().toJson();
        mutate(d);
        expect(() => Campaign.decode(jsonEncode(d)), throwsFormatException);
      }
    },
  );
  test('Caio has no vocal dialogue', () {
    expect(
      () => DialogueLine.fromJson({
        'id': 'bad',
        'speaker': 'CAIO',
        'mode': 'fala',
        'text': 'Oi',
      }),
      throwsFormatException,
    );
  });
}
