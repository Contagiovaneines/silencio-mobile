import 'package:shared_preferences/shared_preferences.dart';

import '../models/campaign.dart';

class SaveRepository {
  SaveRepository(this.preferences);
  final SharedPreferences preferences;
  static const key = 'silencio.campaign.v2';
  String? warning;
  Future<void> _pending = Future.value();

  Campaign? load() {
    final value = preferences.get(key);
    final raw = value is String ? value : null;
    if (raw == null) return null;
    try {
      return Campaign.decode(raw);
    } on FormatException {
      warning = 'O progresso anterior não pôde ser lido. A cópia original foi preservada.';
      return null;
    }
  }

  Future<void> save(Campaign campaign) {
    final snapshot = campaign.encode();
    _pending = _pending.catchError((Object _) {}).then((_) async {
      final previous = preferences.getString(key);
      if (previous != null) {
        await preferences.setString('$key.backup', previous);
      }
      if (!await preferences.setString(key, snapshot)) {
        throw StateError('O aparelho não confirmou o salvamento.');
      }
    });
    return _pending;
  }
}
