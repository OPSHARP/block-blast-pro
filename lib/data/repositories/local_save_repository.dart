// Abstract Local Save Repository according to PRD Sections 53 & 95

import '../../domain/models/game_state.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/player_skill_profile.dart';
import '../../domain/models/daily_challenge.dart';
import '../../domain/models/streak_info.dart';

abstract class LocalSaveRepository {
  Future<void> saveGameState(GameState state);
  Future<GameState?> loadGameState();
  Future<void> clearGameState();

  Future<int> loadHighScore();
  Future<void> saveHighScore(int score);

  Future<PlayerSkillProfile> loadPlayerProfile();
  Future<void> savePlayerProfile(PlayerSkillProfile profile);

  Future<List<Achievement>> loadAchievements();
  Future<void> saveAchievements(List<Achievement> achievements);

  Future<DailyChallenge?> loadDailyChallenge(String dateString);
  Future<void> saveDailyChallenge(DailyChallenge challenge);

  Future<int> loadStreak();
  Future<void> saveStreak(int streak);

  Future<StreakInfo> loadStreakInfo();
  Future<void> saveStreakInfo(StreakInfo info);

  Future<List<String>> loadUnlockedThemes();
  Future<void> saveUnlockedThemes(List<String> themeIds);

  Future<Map<String, dynamic>> loadSettings();
  Future<void> saveSettings(Map<String, dynamic> settings);

  Future<Map<String, int>> loadLifetimeStats();
  Future<void> recordGameCompletion({
    required int finalScore,
    required int linesCleared,
    required int maxCombo,
    required int movesCount,
  });

  Future<bool> loadAdsRemoved();
  Future<void> saveAdsRemoved(bool removed);
}
