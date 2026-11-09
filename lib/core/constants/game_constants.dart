// Core Game Constants for Block Blast Pro

class GameConstants {
  static const int defaultGridSize = 8;
  static const int maxGridSize = 9;

  // Scoring
  static const int pointsPerPlacedCell = 10;
  static const int pointsPerClearedLine = 100;
  static const int multiLineBonusMultiplier = 150; // e.g. 2 lines = 100*2 + 150
  static const int comboBaseBonus = 50;

  // Combo Timers & Thresholds
  static const Duration comboWindow = Duration(seconds: 8);
  static const int shiftTriggerComboThreshold = 3;
  static const double shiftTriggerBoardDensityThreshold = 0.75; // 75% full

  // Physics Weights
  static const double weightLight = 0.5;
  static const double weightNormal = 1.0;
  static const double weightHeavy = 2.0;
  static const double weightUltra = 4.0;

  // Animation Timings (ms)
  static const int snapDurationMs = 120;
  static const int settleDurationMs = 180;
  static const int clearHighlightDurationMs = 150;
  static const int clearDissolveDurationMs = 280;
  static const int gridShiftDurationMs = 320;
  static const int preShiftWarningDurationMs = 400;

  // Adaptive Difficulty Scale
  static const int minSkillRating = 0;
  static const int maxSkillRating = 1000;
  static const int defaultSkillRating = 500;
  static const int rollingMovesWindow = 20;

  // Offline Challenge Salt
  static const String challengeSalt = 'BlockBlastPro_v1_DailySalt_2026';
}
