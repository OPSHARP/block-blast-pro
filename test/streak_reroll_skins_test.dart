import 'package:flutter_test/flutter_test.dart';
import 'package:block_blast_pro/domain/models/streak_info.dart';
import 'package:block_blast_pro/domain/services/streak_service.dart';
import 'package:block_blast_pro/core/theme/game_theme.dart';
import 'package:block_blast_pro/data/repositories/local_save_repository.dart';
import 'package:block_blast_pro/game/game_coordinator.dart';
import 'package:block_blast_pro/domain/models/game_state.dart';
import 'package:block_blast_pro/domain/models/player_skill_profile.dart';
import 'package:block_blast_pro/domain/models/achievement.dart';
import 'package:block_blast_pro/domain/models/daily_challenge.dart';
import 'package:block_blast_pro/core/audio/asmr_audio_engine.dart';

class MockSaveRepository implements LocalSaveRepository {
  GameState? savedState;
  int highScore = 0;
  PlayerSkillProfile profile = const PlayerSkillProfile();
  List<Achievement> achievements = [];
  StreakInfo streakInfo = const StreakInfo(freeRerolls: 3, freeRevives: 1);
  List<String> unlockedThemes = ['crystal_flow', 'neon_geometry'];
  bool adsRemoved = false;

  @override
  Future<void> saveGameState(GameState state) async => savedState = state;
  @override
  Future<GameState?> loadGameState() async => savedState;
  @override
  Future<void> clearGameState() async => savedState = null;

  @override
  Future<int> loadHighScore() async => highScore;
  @override
  Future<void> saveHighScore(int score) async {
    if (score > highScore) highScore = score;
  }

  @override
  Future<PlayerSkillProfile> loadPlayerProfile() async => profile;
  @override
  Future<void> savePlayerProfile(PlayerSkillProfile p) async => profile = p;

  @override
  Future<List<Achievement>> loadAchievements() async => achievements;
  @override
  Future<void> saveAchievements(List<Achievement> a) async => achievements = a;

  @override
  Future<DailyChallenge?> loadDailyChallenge(String d) async => null;
  @override
  Future<void> saveDailyChallenge(DailyChallenge c) async {}

  @override
  Future<int> loadStreak() async => streakInfo.streakCount;
  @override
  Future<void> saveStreak(int s) async => streakInfo = streakInfo.copyWith(streakCount: s);

  @override
  Future<StreakInfo> loadStreakInfo() async => streakInfo;
  @override
  Future<void> saveStreakInfo(StreakInfo info) async => streakInfo = info;

  @override
  Future<List<String>> loadUnlockedThemes() async => unlockedThemes;
  @override
  Future<void> saveUnlockedThemes(List<String> ids) async => unlockedThemes = ids;

  @override
  Future<Map<String, dynamic>> loadSettings() async => {};
  @override
  Future<void> saveSettings(Map<String, dynamic> s) async {}

  @override
  Future<Map<String, int>> loadLifetimeStats() async => {};
  @override
  Future<void> recordGameCompletion({
    required int finalScore,
    required int linesCleared,
    required int maxCombo,
    required int movesCount,
  }) async {}

  @override
  Future<bool> loadAdsRemoved() async => adsRemoved;
  @override
  Future<void> saveAdsRemoved(bool r) async => adsRemoved = r;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StreakService & Day 1-7 Progression Tests', () {
    const service = StreakService();

    test('Streak rewards schedule has valid 7-day progression', () {
      expect(StreakService.schedule.length, 7);
      expect(StreakService.getRewardForDay(1).bonusRerolls, 1);
      expect(StreakService.getRewardForDay(3).bonusRevives, 1);
      expect(StreakService.getRewardForDay(7).bonusRerolls, 5);
      expect(StreakService.getRewardForDay(7).bonusRevives, 2);
    });

    test('claimToday awards rewards and advances streak', () {
      final initial = StreakInfo(
        streakCount: 0,
        freeRerolls: 0,
        freeRevives: 0,
      );

      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final claimed = service.claimToday(initial, now: now);

      expect(claimed.streakCount, 1);
      expect(claimed.freeRerolls, 1);
      expect(claimed.lastClaimDate, todayStr);
      expect(claimed.isClaimableToday, false);
    });

    test('claimToday on same day does not duplicate rewards', () {
      final initial = StreakInfo(
        streakCount: 1,
        lastClaimDate: '2026-09-08',
        freeRerolls: 2,
        freeRevives: 0,
      );

      final claimed = service.claimToday(initial, now: DateTime(2026, 9, 8, 14, 0));
      expect(claimed.streakCount, 1);
      expect(claimed.freeRerolls, 2);
    });

    test('consecutive daily claim advances to Day 2 and Day 7', () {
      var state = const StreakInfo(streakCount: 0, freeRerolls: 0, freeRevives: 0);

      // Day 1
      state = service.claimToday(state, now: DateTime(2026, 9, 1));
      expect(state.streakCount, 1);
      expect(state.currentCycleDay, 1);

      // Day 2
      state = service.claimToday(state, now: DateTime(2026, 9, 2));
      expect(state.streakCount, 2);
      expect(state.currentCycleDay, 2);

      // Fast forward to Day 7
      for (int day = 3; day <= 7; day++) {
        state = service.claimToday(state, now: DateTime(2026, 9, day));
      }
      expect(state.streakCount, 7);
      expect(state.currentCycleDay, 7);
      expect(state.freeRerolls, 16); // 1 + 2 + 1 + 2 + 3 + 2 + 5 = 16
      expect(state.freeRevives, 4); // 0 + 0 + 1 + 0 + 0 + 1 + 2 = 4
    });
  });

  group('Unlockable Skins Tests', () {
    test('Starter themes are unlocked by default', () {
      expect(GameTheme.crystalFlow.isDefaultUnlocked, true);
      expect(GameTheme.neonGeometry.isDefaultUnlocked, true);
      expect(
        GameTheme.crystalFlow.isUnlocked(highScore: 0, streak: 0, unlockedIds: []),
        true,
      );
    });

    test('Neon Cyberpunk unlocks at 2,500 score or 3-day streak', () {
      final theme = GameTheme.neonCyberpunk;
      expect(theme.isDefaultUnlocked, false);

      // Below requirements
      expect(theme.isUnlocked(highScore: 1000, streak: 1, unlockedIds: []), false);

      // Unlocked by high score
      expect(theme.isUnlocked(highScore: 2500, streak: 1, unlockedIds: []), true);

      // Unlocked by streak
      expect(theme.isUnlocked(highScore: 0, streak: 3, unlockedIds: []), true);
    });

    test('Woodcraft unlocks at 5,000 score or 5-day streak', () {
      final theme = GameTheme.woodcraft;
      expect(theme.isUnlocked(highScore: 4999, streak: 4, unlockedIds: []), false);
      expect(theme.isUnlocked(highScore: 5000, streak: 0, unlockedIds: []), true);
      expect(theme.isUnlocked(highScore: 0, streak: 5, unlockedIds: []), true);
    });

    test('Jewel Prism unlocks at 10,000 score or 7-day streak', () {
      final theme = GameTheme.jewelPrism;
      expect(theme.isUnlocked(highScore: 9999, streak: 6, unlockedIds: []), false);
      expect(theme.isUnlocked(highScore: 10000, streak: 0, unlockedIds: []), true);
      expect(theme.isUnlocked(highScore: 0, streak: 7, unlockedIds: []), true);
    });

    test('Obsidian Glow unlocks at 20,000 score or 14-day streak', () {
      final theme = GameTheme.obsidianGlow;
      expect(theme.isUnlocked(highScore: 19999, streak: 13, unlockedIds: []), false);
      expect(theme.isUnlocked(highScore: 20000, streak: 0, unlockedIds: []), true);
      expect(theme.isUnlocked(highScore: 0, streak: 14, unlockedIds: []), true);
    });
  });

  group('GameCoordinator Reroll & Double Endgame Score Tests', () {
    late MockSaveRepository mockRepo;
    late GameCoordinator coordinator;

    setUp(() async {
      mockRepo = MockSaveRepository();
      coordinator = GameCoordinator(
        saveRepository: mockRepo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.initialize();
    });

    test('Reroll pieces replaces tray pieces and uses free reroll', () async {
      expect(coordinator.freeRerolls, 3);

      await coordinator.rerollPieces(isFree: true);

      expect(coordinator.freeRerolls, 2);
      expect(coordinator.state.trayPieces.length, 3);
      expect(coordinator.state.trayPieces.every((p) => p != null), true);
    });

    test('Rewarded ad reroll grants +1 free reroll count', () async {
      expect(coordinator.freeRerolls, 3);

      await coordinator.rerollPieces(isFree: false);

      expect(coordinator.freeRerolls, 4); // Free count incremented by 1!
    });

    test('Double endgame score doubles score and XP on game over', () async {
      await coordinator.startNewGame();
      final overState = coordinator.state.copyWith(
        score: 500,
        xp: 100,
        highScore: 500,
        isGameOver: true,
      );
      coordinator.setGameStateForTesting(overState);

      expect(coordinator.state.score, 500);
      expect(coordinator.hasDoubledScoreThisGame, false);

      // Trigger double endgame score
      await coordinator.doubleEndgameScore();

      expect(coordinator.state.score, 1000);
      expect(coordinator.state.highScore, 1000);
      expect(coordinator.hasDoubledScoreThisGame, true);

      // Attempting to double again should be blocked
      await coordinator.doubleEndgameScore();
      expect(coordinator.state.score, 1000);
    });

    test('High score updates trigger theme auto-unlock', () async {
      await coordinator.startNewGame();
      final highState = coordinator.state.copyWith(
        score: 2600,
        highScore: 2600,
        isGameOver: true,
      );
      coordinator.setGameStateForTesting(highState);

      expect(coordinator.unlockedThemeIds.contains('neon_cyberpunk'), true);
    });
  });
}
