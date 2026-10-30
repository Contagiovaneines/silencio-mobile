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
  test('weapon and nonlethal takedown survive save and reload', () {
    final campaign = Campaign();
    campaign.events.addAll(['alley', 'weapon', 'enemy_defeated', 'resolved']);
    campaign.enemyHealth = 0;
    final loaded = Campaign.decode(campaign.encode());
    expect(loaded.has('weapon'), isTrue);
    expect(loaded.has('enemy_defeated'), isTrue);
    expect(loaded.has('resolved'), isTrue);
    expect(loaded.canLeave, isFalse);
  });
  test(
    'partial enemy health survives save and old v2 saves default to full',
    () {
      final campaign = Campaign()..enemyHealth = 63;
      expect(Campaign.decode(campaign.encode()).enemyHealth, 63);

      final oldV2 = Campaign().toJson()..remove('enemy_health');
      expect(Campaign.decode(jsonEncode(oldV2)).enemyHealth, 100);
    },
  );
  test('window states survive save and old v2 saves keep windows closed', () {
    final campaign = Campaign()..openWindows.add('203');
    expect(Campaign.decode(campaign.encode()).openWindows, contains('203'));

    final oldV2 = Campaign().toJson()..remove('open_windows');
    expect(Campaign.decode(jsonEncode(oldV2)).openWindows, isEmpty);
  });
  test('enemy health values and defeated state must agree', () {
    for (final value in [-1, 101]) {
      final data = Campaign().toJson()..['enemy_health'] = value;
      expect(() => Campaign.decode(jsonEncode(data)), throwsFormatException);
    }
    final inconsistent = Campaign()
      ..events.addAll(['alley', 'weapon', 'enemy_defeated', 'resolved']);
    expect(() => Campaign.decode(inconsistent.encode()), throwsFormatException);
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
