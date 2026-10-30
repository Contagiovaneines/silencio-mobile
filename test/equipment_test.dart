import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silencio/game/game_session.dart';
import 'package:silencio/game/equipment_pose.dart';
import 'package:silencio/models/campaign.dart';
import 'package:silencio/services/save_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('legacy equipment and unequipping preserve possession', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await GameSession.load(
      SaveRepository(await SharedPreferences.getInstance()),
    );
    addTearDown(s.dispose);
    s.startNew();
    s.finishOpening();
    s.campaign.mark('weapon');
    final legacy = s.campaign.toJson()
      ..remove('backpack_equipped')
      ..remove('weapon_equipped');
    final restored = Campaign.decode(jsonEncode(legacy));
    expect(restored.backpackEquipped, isTrue);
    expect(restored.weaponEquipped, isTrue);
    s.toggleWeaponEquipment();
    s.toggleBackpack();
    expect(s.campaign.has('weapon'), isTrue);
    expect(s.campaign.weaponEquipped, isFalse);
    expect(s.campaign.backpackEquipped, isFalse);
    expect(s.world.attackAvailable, isFalse);
    await s.checkpoint();
    expect(s.repository.load()!.backpackEquipped, isFalse);
    expect(s.repository.load()!.weaponEquipped, isFalse);
  });
  test('directional sockets cover movement, guard and hurt', () {
    for (final state in ['idle', 'walk', 'run', 'attack', 'guard', 'hurt']) {
      for (var d = 0; d < 8; d++) {
        final pose = EquipmentPose.sample(
          direction: d,
          state: state,
          progress: .5,
        );
        expect(pose.hand.dx.isFinite, isTrue);
        expect(pose.hand.dy, isNegative);
        expect(pose.angle.isFinite, isTrue);
        expect(pose.behindBody, d >= 5);
      }
    }
    expect(
      EquipmentPose.sample(direction: 2, state: 'hurt').hand,
      isNot(EquipmentPose.sample(direction: 2, state: 'guard').hand),
    );
  });
}
