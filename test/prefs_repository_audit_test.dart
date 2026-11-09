import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:block_blast_pro/data/repositories/prefs_save_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrefsSaveRepository Deep Audit & Resilience Tests', () {
    test('loadGameState handles corrupted JSON string gracefully without throwing', () async {
      SharedPreferences.setMockInitialValues({
        'bbp_game_state': '{corrupted: json [missing quotes',
      });
      final repo = PrefsSaveRepository();
      final state = await repo.loadGameState();
      expect(state, isNull);
    });

    test('loadSettings recovers with default settings if corrupt', () async {
      SharedPreferences.setMockInitialValues({
        'bbp_settings': 'INVALID_JSON',
      });
      final repo = PrefsSaveRepository();
      final settings = await repo.loadSettings();
      expect(settings['masterVolume'], 0.8);
      expect(settings['gridSize'], 8);
    });

    test('loadLifetimeStats returns zeroed metrics on corrupt data', () async {
      SharedPreferences.setMockInitialValues({
        'bbp_stats': 'NOT_A_JSON',
      });
      final repo = PrefsSaveRepository();
      final stats = await repo.loadLifetimeStats();
      expect(stats['totalGames'], 0);
      expect(stats['totalScore'], 0);
    });

    test('persists and loads ads removed status reliably', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = PrefsSaveRepository();

      expect(await repo.loadAdsRemoved(), isFalse);
      await repo.saveAdsRemoved(true);
      expect(await repo.loadAdsRemoved(), isTrue);
    });
  });
}
