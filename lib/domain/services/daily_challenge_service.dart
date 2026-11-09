// Deterministic Daily Challenge Generator according to PRD Sections 44-49 & 613-673

import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/daily_challenge.dart';
import '../../core/constants/game_constants.dart';

class DailyChallengeService {
  const DailyChallengeService();

  // Generate deterministic challenge for a given calendar date
  DailyChallenge getChallengeForDate(DateTime date) {
    final dateString = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final hashInput = '$dateString:v1.0:${GameConstants.challengeSalt}';
    final bytes = utf8.encode(hashInput);
    final digest = sha256.convert(bytes);

    // Extract 32-bit positive seed
    final seed = digest.bytes[0] |
        (digest.bytes[1] << 8) |
        (digest.bytes[2] << 16) |
        (digest.bytes[3] << 24);

    final objectiveTypes = [
      ChallengeObjectiveType.scoreTarget,
      ChallengeObjectiveType.comboTarget,
      ChallengeObjectiveType.multiClearCount,
      ChallengeObjectiveType.gridShiftSurvive,
    ];
    final selectedType = objectiveTypes[seed.abs() % objectiveTypes.length];

    String title;
    String description;
    int targetValue;
    String rewardName;

    switch (selectedType) {
      case ChallengeObjectiveType.scoreTarget:
        final multiplier = (seed.abs() % 4) + 2; // 2 to 5
        targetValue = multiplier * 2500; // 5000 to 12500
        title = 'Daily Mastermind';
        description = 'Accumulate $targetValue points in a single session.';
        rewardName = 'Crystal Shard';
        break;

      case ChallengeObjectiveType.comboTarget:
        targetValue = (seed.abs() % 4) + 4; // 4 to 7
        title = 'Combo Weaver';
        description = 'Reach an unbroken combo streak of $targetValue.';
        rewardName = 'Aurora Glow';
        break;

      case ChallengeObjectiveType.multiClearCount:
        targetValue = (seed.abs() % 3) + 3; // 3 to 5
        title = 'Double Impact';
        description = 'Execute $targetValue multi-line simultaneous clears.';
        rewardName = 'Zen Pebble';
        break;

      case ChallengeObjectiveType.gridShiftSurvive:
        targetValue = (seed.abs() % 3) + 3; // 3 to 5
        title = 'Tectonic Navigator';
        description = 'Survive $targetValue dynamic grid shifts without game over.';
        rewardName = 'Neon Pulse';
        break;

      case ChallengeObjectiveType.survivalTurns:
        targetValue = 25;
        title = 'Endurance';
        description = 'Survive 25 block placements.';
        rewardName = 'Paper Fold';
        break;
    }

    return DailyChallenge(
      dateString: dateString,
      seed: seed.abs(),
      objectiveType: selectedType,
      title: title,
      description: description,
      targetValue: targetValue,
      rewardName: rewardName,
    );
  }
}
