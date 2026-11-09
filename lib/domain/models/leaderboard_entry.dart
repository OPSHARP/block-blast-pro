import 'package:flutter/material.dart';
import 'rank_tier.dart';

class LeaderboardEntry {
  final int rank;
  final String playerName;
  final int score;
  final String countryFlag;
  final bool isCurrentUser;
  final RankTier tier;
  final Color avatarColor;

  const LeaderboardEntry({
    required this.rank,
    required this.playerName,
    required this.score,
    required this.countryFlag,
    this.isCurrentUser = false,
    required this.tier,
    required this.avatarColor,
  });

  /// Generates a realistic, dynamic leaderboard integrating the user's high score.
  static List<LeaderboardEntry> getGlobalLeaderboard({
    required int userHighScore,
    String? userDisplayName,
  }) {
    // Curated high-level community players
    final baseCompetitors = <Map<String, dynamic>>[
      {'name': 'ApexBlaster', 'score': 28450, 'flag': '🇺🇸', 'color': const Color(0xFFEF4444)},
      {'name': 'Kenji_99', 'score': 24920, 'flag': '🇯🇵', 'color': const Color(0xFF8B5CF6)},
      {'name': 'Elena_Frost', 'score': 21800, 'flag': '🇩🇪', 'color': const Color(0xFF3B82F6)},
      {'name': 'BlockKing_DK', 'score': 19340, 'flag': '🇩🇰', 'color': const Color(0xFF10B981)},
      {'name': 'ZenMaster_KR', 'score': 17650, 'flag': '🇰🇷', 'color': const Color(0xFFF59E0B)},
      {'name': 'Lucas_Silva', 'score': 15200, 'flag': '🇧🇷', 'color': const Color(0xFF06B6D4)},
      {'name': 'Aarav_Blaster', 'score': 13910, 'flag': '🇮🇳', 'color': const Color(0xFFEC4899)},
      {'name': 'Chloe_Paris', 'score': 12450, 'flag': '🇫🇷', 'color': const Color(0xFF6366F1)},
      {'name': 'Liam_London', 'score': 10890, 'flag': '🇬🇧', 'color': const Color(0xFF14B8A6)},
      {'name': 'Mateo_Madrid', 'score': 9420, 'flag': '🇪🇸', 'color': const Color(0xFFEAB308)},
      {'name': 'Sofia_Roma', 'score': 8150, 'flag': '🇮🇹', 'color': const Color(0xFF84CC16)},
      {'name': 'Noah_Sydney', 'score': 7230, 'flag': '🇦🇺', 'color': const Color(0xFF0EA5E9)},
      {'name': 'Fatima_Dubai', 'score': 6410, 'flag': '🇦🇪', 'color': const Color(0xFFA855F7)},
      {'name': 'Oliver_Toronto', 'score': 5630, 'flag': '🇨🇦', 'color': const Color(0xFFF97316)},
      {'name': 'Marta_Warsaw', 'score': 4890, 'flag': '🇵🇱', 'color': const Color(0xFF10B981)},
      {'name': 'Dmitri_Baltic', 'score': 4120, 'flag': '🇪🇪', 'color': const Color(0xFF06B6D4)},
      {'name': 'Yuki_Tokyo', 'score': 3550, 'flag': '🇯🇵', 'color': const Color(0xFFF43F5E)},
      {'name': 'Carlos_MX', 'score': 2980, 'flag': '🇲🇽', 'color': const Color(0xFF8B5CF6)},
      {'name': 'Ananya_Delhi', 'score': 2450, 'flag': '🇮🇳', 'color': const Color(0xFFEAB308)},
      {'name': 'Jan_Prague', 'score': 1920, 'flag': '🇨🇿', 'color': const Color(0xFF64748B)},
      {'name': 'Lars_Stockholm', 'score': 1480, 'flag': '🇸🇪', 'color': const Color(0xFF38BDF8)},
      {'name': 'Sara_Oslo', 'score': 1050, 'flag': '🇳🇴', 'color': const Color(0xFF708090)},
      {'name': 'Minho_Seoul', 'score': 820, 'flag': '🇰🇷', 'color': const Color(0xFFCD7F32)},
      {'name': 'Mia_Auckland', 'score': 610, 'flag': '🇳🇿', 'color': const Color(0xFFCD7F32)},
      {'name': 'Leo_Vienna', 'score': 390, 'flag': '🇦🇹', 'color': const Color(0xFFCD7F32)},
    ];

    // Combine user with competitors
    final allEntries = <_RawLeaderboardItem>[];
    for (final c in baseCompetitors) {
      allEntries.add(_RawLeaderboardItem(
        name: c['name'] as String,
        score: c['score'] as int,
        flag: c['flag'] as String,
        color: c['color'] as Color,
        isUser: false,
      ));
    }

    // Add user
    final effectiveName = (userDisplayName != null && userDisplayName.trim().isNotEmpty)
        ? userDisplayName.trim()
        : 'You (Champion)';

    allEntries.add(_RawLeaderboardItem(
      name: effectiveName,
      score: userHighScore,
      flag: '⭐',
      color: const Color(0xFF38BDF8),
      isUser: true,
    ));

    // Sort descending by score
    allEntries.sort((a, b) => b.score.compareTo(a.score));

    // Assign dynamic ranks
    final result = <LeaderboardEntry>[];
    for (int i = 0; i < allEntries.length; i++) {
      final item = allEntries[i];
      result.add(LeaderboardEntry(
        rank: i + 1,
        playerName: item.name,
        score: item.score,
        countryFlag: item.flag,
        isCurrentUser: item.isUser,
        tier: RankTier.fromScore(item.score),
        avatarColor: item.color,
      ));
    }

    return result;
  }
}

class _RawLeaderboardItem {
  final String name;
  final int score;
  final String flag;
  final Color color;
  final bool isUser;

  const _RawLeaderboardItem({
    required this.name,
    required this.score,
    required this.flag,
    required this.color,
    required this.isUser,
  });
}
