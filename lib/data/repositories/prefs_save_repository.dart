// Local SharedPreferences implementation of LocalSaveRepository

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/player_skill_profile.dart';
import '../../domain/models/daily_challenge.dart';
import '../../domain/models/streak_info.dart';
import '../../domain/services/achievement_service.dart';
import 'local_save_repository.dart';

class PrefsSaveRepository implements LocalSaveRepository {
  static const String _kGameState = 'bbp_game_state';
  static const String _kHighScore = 'bbp_high_score';
  static const String _kPlayerProfile = 'bbp_player_profile';
  static const String _kAchievements = 'bbp_achievements';
  static const String _kDailyPrefix = 'bbp_daily_';
  static const String _kStreak = 'bbp_streak';
  static const String _kStreakInfo = 'bbp_streak_info';
  static const String _kUnlockedThemes = 'bbp_unlocked_themes';
  static const String _kSettings = 'bbp_settings';
  static const String _kStats = 'bbp_stats';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<void> saveGameState(GameState state) async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = jsonEncode(state.toMap());
      await prefs.setString(_kGameState, jsonStr);
    } catch (e) {
      debugPrint('Error saving game state: $e');
    }
  }

  @override
  Future<GameState?> loadGameState() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_kGameState);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return GameState.fromMap(map);
    } catch (e) {
      debugPrint('Corrupt save detected. Recovery initiated: $e');
      return null;
    }
  }

  @override
  Future<void> clearGameState() async {
    final prefs = await _getPrefs();
    await prefs.remove(_kGameState);
  }

  @override
  Future<int> loadHighScore() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_kHighScore) ?? 0;
  }

  @override
  Future<void> saveHighScore(int score) async {
    final prefs = await _getPrefs();
    final current = prefs.getInt(_kHighScore) ?? 0;
    if (score > current) {
      await prefs.setInt(_kHighScore, score);
    }
  }

  @override
  Future<PlayerSkillProfile> loadPlayerProfile() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_kPlayerProfile);
      if (jsonStr == null) return const PlayerSkillProfile();
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return PlayerSkillProfile.fromMap(map);
    } catch (e) {
      return const PlayerSkillProfile();
    }
  }

  @override
  Future<void> savePlayerProfile(PlayerSkillProfile profile) async {
    final prefs = await _getPrefs();
    await prefs.setString(_kPlayerProfile, jsonEncode(profile.toMap()));
  }

  @override
  Future<List<Achievement>> loadAchievements() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_kAchievements);
      if (jsonStr == null) {
        return AchievementService.getInitialAchievements();
      }
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((item) => Achievement.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return AchievementService.getInitialAchievements();
    }
  }

  @override
  Future<void> saveAchievements(List<Achievement> achievements) async {
    final prefs = await _getPrefs();
    final list = achievements.map((a) => a.toMap()).toList();
    await prefs.setString(_kAchievements, jsonEncode(list));
  }

  @override
  Future<DailyChallenge?> loadDailyChallenge(String dateString) async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString('$_kDailyPrefix$dateString');
      if (jsonStr == null) return null;
      return DailyChallenge.fromMap(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveDailyChallenge(DailyChallenge challenge) async {
    final prefs = await _getPrefs();
    await prefs.setString(
      '$_kDailyPrefix${challenge.dateString}',
      jsonEncode(challenge.toMap()),
    );
  }

  @override
  Future<int> loadStreak() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_kStreak) ?? 0;
  }

  @override
  Future<void> saveStreak(int streak) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_kStreak, streak);
  }

  @override
  Future<StreakInfo> loadStreakInfo() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_kStreakInfo);
      if (jsonStr == null || jsonStr.isEmpty) {
        final legacyStreak = prefs.getInt(_kStreak) ?? 0;
        return StreakInfo(streakCount: legacyStreak);
      }
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return StreakInfo.fromMap(map);
    } catch (e) {
      return const StreakInfo();
    }
  }

  @override
  Future<void> saveStreakInfo(StreakInfo info) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_kStreakInfo, jsonEncode(info.toMap()));
      await prefs.setInt(_kStreak, info.streakCount);
    } catch (e) {
      debugPrint('Error saving streak info: $e');
    }
  }

  @override
  Future<List<String>> loadUnlockedThemes() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(_kUnlockedThemes) ?? ['crystal_flow', 'neon_geometry'];
  }

  @override
  Future<void> saveUnlockedThemes(List<String> themeIds) async {
    final prefs = await _getPrefs();
    await prefs.setStringList(_kUnlockedThemes, themeIds);
  }

  static const String _kAdsRemoved = 'bbp_ads_removed';

  @override
  Future<bool> loadAdsRemoved() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(_kAdsRemoved) ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> saveAdsRemoved(bool removed) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(_kAdsRemoved, removed);
    } catch (e) {
      debugPrint('Error saving ads removed state: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> loadSettings() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_kSettings);
      if (jsonStr == null) {
        return {
          'masterVolume': 0.8,
          'sfxVolume': 1.0,
          'asmrIntensity': 'balanced',
          'isMuted': false,
          'isHapticsEnabled': true,
          'gridSize': 8,
          'reducedMotion': false,
          'highContrast': false,
        };
      }
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Corrupt settings recovered to defaults: $e');
      return {
        'masterVolume': 0.8,
        'sfxVolume': 1.0,
        'asmrIntensity': 'balanced',
        'isMuted': false,
        'isHapticsEnabled': true,
        'gridSize': 8,
        'reducedMotion': false,
        'highContrast': false,
      };
    }
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_kSettings, jsonEncode(settings));
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  @override
  Future<Map<String, int>> loadLifetimeStats() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_kStats);
      if (jsonStr == null) {
        return {
          'totalGames': 0,
          'totalScore': 0,
          'totalClears': 0,
          'highestScore': 0,
          'highestCombo': 0,
          'totalMoves': 0,
        };
      }
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as int));
    } catch (e) {
      return {
        'totalGames': 0,
        'totalScore': 0,
        'totalClears': 0,
        'highestScore': 0,
        'highestCombo': 0,
        'totalMoves': 0,
      };
    }
  }

  @override
  Future<void> recordGameCompletion({
    required int finalScore,
    required int linesCleared,
    required int maxCombo,
    required int movesCount,
  }) async {
    try {
      final stats = await loadLifetimeStats();
      stats['totalGames'] = (stats['totalGames'] ?? 0) + 1;
      stats['totalScore'] = (stats['totalScore'] ?? 0) + finalScore;
      stats['totalClears'] = (stats['totalClears'] ?? 0) + linesCleared;
      stats['totalMoves'] = (stats['totalMoves'] ?? 0) + movesCount;
      stats['highestScore'] = (stats['highestScore'] ?? 0) < finalScore ? finalScore : stats['highestScore']!;
      stats['highestCombo'] = (stats['highestCombo'] ?? 0) < maxCombo ? maxCombo : stats['highestCombo']!;

      final prefs = await _getPrefs();
      await prefs.setString(_kStats, jsonEncode(stats));
      await saveHighScore(finalScore);
    } catch (e) {
      debugPrint('Error recording game stats: $e');
    }
  }
}
