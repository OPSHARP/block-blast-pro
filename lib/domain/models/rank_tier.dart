import 'package:flutter/material.dart';

enum RankTierId {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  legend,
}

class RankTier {
  final RankTierId id;
  final String name;
  final String title;
  final int minScore;
  final int maxScore;
  final Color primaryColor;
  final List<Color> gradientColors;
  final IconData icon;
  final String emoji;
  final List<String> perks;

  const RankTier({
    required this.id,
    required this.name,
    required this.title,
    required this.minScore,
    required this.maxScore,
    required this.primaryColor,
    required this.gradientColors,
    required this.icon,
    required this.emoji,
    required this.perks,
  });

  /// Returns the matching RankTier for a given high score.
  static RankTier fromScore(int score) {
    if (score >= legend.minScore) return legend;
    if (score >= diamond.minScore) return diamond;
    if (score >= platinum.minScore) return platinum;
    if (score >= gold.minScore) return gold;
    if (score >= silver.minScore) return silver;
    return bronze;
  }

  /// Calculates the division within the tier (III, II, I).
  String division(int score) {
    if (id == RankTierId.legend) return 'Champion';
    final span = maxScore - minScore;
    if (span <= 0) return 'I';
    final progressInTier = (score - minScore).clamp(0, span);
    final third = span / 3.0;
    if (progressInTier < third) return 'III';
    if (progressInTier < third * 2) return 'II';
    return 'I';
  }

  /// Full formatted rank title, e.g. "Gold Strategist II" or "Legend Champion"
  String fullTitle(int score) {
    final div = division(score);
    if (id == RankTierId.legend) return '$name $title';
    return '$name $title $div';
  }

  /// Progress from 0.0 to 1.0 towards the next tier.
  double progress(int score) {
    if (id == RankTierId.legend) return 1.0;
    final span = maxScore - minScore;
    if (span <= 0) return 1.0;
    final current = (score - minScore).clamp(0, span);
    return (current / span).clamp(0.0, 1.0);
  }

  /// Points needed to reach the next tier.
  int pointsToNext(int score) {
    if (id == RankTierId.legend) return 0;
    final remaining = maxScore - score;
    return remaining > 0 ? remaining : 0;
  }

  /// Next tier object, or null if already at max tier.
  RankTier? get nextTier {
    switch (id) {
      case RankTierId.bronze:
        return silver;
      case RankTierId.silver:
        return gold;
      case RankTierId.gold:
        return platinum;
      case RankTierId.platinum:
        return diamond;
      case RankTierId.diamond:
        return legend;
      case RankTierId.legend:
        return null;
    }
  }

  // Pre-defined tier constants
  static const RankTier bronze = RankTier(
    id: RankTierId.bronze,
    name: 'Bronze',
    title: 'Novice',
    minScore: 0,
    maxScore: 1000,
    primaryColor: Color(0xFFF59E0B),
    gradientColors: [Color(0xFFF59E0B), Color(0xFFB45309)],
    icon: Icons.shield_outlined,
    emoji: '🥉',
    perks: [
      'Standard Tray Replenish',
      'Daily Challenge Access',
      'Default Pastel Themes',
    ],
  );

  static const RankTier silver = RankTier(
    id: RankTierId.silver,
    name: 'Silver',
    title: 'Apprentice',
    minScore: 1000,
    maxScore: 2500,
    primaryColor: Color(0xFF708090),
    gradientColors: [Color(0xFF94A3B8), Color(0xFF64748B)],
    icon: Icons.verified_outlined,
    emoji: '🥈',
    perks: [
      '+1 Free Undo per Game',
      '5% Score Multiplier Boost',
      'Silver Profile Badge',
    ],
  );

  static const RankTier gold = RankTier(
    id: RankTierId.gold,
    name: 'Gold',
    title: 'Strategist',
    minScore: 2500,
    maxScore: 5000,
    primaryColor: Color(0xFFEAB308),
    gradientColors: [Color(0xFFFBBF24), Color(0xFFD97706)],
    icon: Icons.workspace_premium_outlined,
    emoji: '🥇',
    perks: [
      'Golden Horizon Theme Unlock',
      '+1 Daily Free Reroll',
      '10% Score Multiplier Boost',
    ],
  );

  static const RankTier platinum = RankTier(
    id: RankTierId.platinum,
    name: 'Platinum',
    title: 'Master',
    minScore: 5000,
    maxScore: 10000,
    primaryColor: Color(0xFF06B6D4),
    gradientColors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
    icon: Icons.diamond_outlined,
    emoji: '💎',
    perks: [
      'Platinum Frame in Leaderboards',
      '+1 Weekly Hammer Booster',
      '15% Score Multiplier Boost',
    ],
  );

  static const RankTier diamond = RankTier(
    id: RankTierId.diamond,
    name: 'Diamond',
    title: 'Grandmaster',
    minScore: 10000,
    maxScore: 20000,
    primaryColor: Color(0xFF8B5CF6),
    gradientColors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
    icon: Icons.auto_awesome,
    emoji: '👑',
    perks: [
      'Grandmaster Crown Aura',
      'Magma Surge Theme Unlock',
      '20% Score Multiplier Boost',
    ],
  );

  static const RankTier legend = RankTier(
    id: RankTierId.legend,
    name: 'Legend',
    title: 'Champion',
    minScore: 20000,
    maxScore: 50000,
    primaryColor: Color(0xFFEF4444),
    gradientColors: [Color(0xFFF43F5E), Color(0xFFDC2626)],
    icon: Icons.local_fire_department,
    emoji: '🌟',
    perks: [
      'Royal Gold Theme Unlock',
      'Top 1% Global Champion Badge',
      'Animated Particle Trail',
      'Eternal Leaderboard Hall of Fame',
    ],
  );

  static const List<RankTier> allTiers = [
    bronze,
    silver,
    gold,
    platinum,
    diamond,
    legend,
  ];
}
