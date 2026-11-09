// Google Play Games Services Configuration & Resource Identifiers

class PlayGamesConstants {
  static const String channelName = 'com.block.blastpro/play_games';

  // Primary High Score Leaderboard ID from Google Play Console
  // Replace with your leaderboard ID (e.g. CgkIxxxxxxxxxxxx)
  static const String highScoresLeaderboardId = 'CgkI_PLACEHOLDER_LEADERBOARD_ID';

  // In-Game Achievement ID to Google Play Games Achievement ID Mapping
  // Configure each achievement ID created in Google Play Console
  static const Map<String, String> achievementIdMap = {
    // Scoring
    'score_1000': 'CgkI_PLACEHOLDER_ACH_1000',
    'score_5000': 'CgkI_PLACEHOLDER_ACH_5000',
    'score_10000': 'CgkI_PLACEHOLDER_ACH_10000',
    'score_25000': 'CgkI_PLACEHOLDER_ACH_25000',
    'score_50000': 'CgkI_PLACEHOLDER_ACH_50000',

    // Combos & Streaks
    'combo_3': 'CgkI_PLACEHOLDER_ACH_COMBO_3',
    'combo_5': 'CgkI_PLACEHOLDER_ACH_COMBO_5',
    'combo_8': 'CgkI_PLACEHOLDER_ACH_COMBO_8',
    'streak_3': 'CgkI_PLACEHOLDER_ACH_STREAK_3',
    'streak_7': 'CgkI_PLACEHOLDER_ACH_STREAK_7',
    'streak_30': 'CgkI_PLACEHOLDER_ACH_STREAK_30',

    // Grid & Clears
    'perfect_clear': 'CgkI_PLACEHOLDER_ACH_PERFECT_CLEAR',
    'all_clear': 'CgkI_PLACEHOLDER_ACH_ALL_CLEAR',
    'double_clear': 'CgkI_PLACEHOLDER_ACH_DOUBLE_CLEAR',
    'triple_clear': 'CgkI_PLACEHOLDER_ACH_TRIPLE_CLEAR',

    // Daily & Modes
    'daily_challenge_1': 'CgkI_PLACEHOLDER_ACH_DAILY_1',
    'daily_challenge_7': 'CgkI_PLACEHOLDER_ACH_DAILY_7',
    'theme_collector': 'CgkI_PLACEHOLDER_ACH_THEME_COLLECTOR',
  };
}
