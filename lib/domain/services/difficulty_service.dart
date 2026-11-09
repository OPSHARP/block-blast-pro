// Adaptive Difficulty and Player Skill Service according to PRD Sections 21-25 & 314-386

import 'dart:math';
import '../models/player_skill_profile.dart';
import '../../core/constants/game_constants.dart';

class MoveMetric {
  final int scoreEarned;
  final int linesCleared;
  final int combo;
  final double boardDensityBeforeMove;
  final bool usedSpecialBlock;

  const MoveMetric({
    required this.scoreEarned,
    required this.linesCleared,
    required this.combo,
    required this.boardDensityBeforeMove,
    this.usedSpecialBlock = false,
  });
}

class DifficultyService {
  final List<MoveMetric> _rollingMoves = [];

  void recordMove(MoveMetric metric) {
    _rollingMoves.add(metric);
    if (_rollingMoves.length > GameConstants.rollingMovesWindow) {
      _rollingMoves.removeAt(0);
    }
  }

  void resetSession() {
    _rollingMoves.clear();
  }

  // Update profile and calculate new internal skill rating
  PlayerSkillProfile updateProfile(PlayerSkillProfile currentProfile) {
    if (_rollingMoves.isEmpty) return currentProfile;

    int totalScore = 0;
    int totalClears = 0;
    int maxCombo = 0;
    int highDensityRecoveries = 0;
    int specialMoves = 0;

    for (final m in _rollingMoves) {
      totalScore += m.scoreEarned;
      totalClears += m.linesCleared;
      maxCombo = max(maxCombo, m.combo);
      if (m.boardDensityBeforeMove > 0.65 && m.linesCleared > 0) {
        highDensityRecoveries++;
      }
      if (m.usedSpecialBlock) {
        specialMoves++;
      }
    }

    final count = _rollingMoves.length;
    final avgScorePerMove = totalScore / count;
    final clearRate = totalClears / count;

    // Calculate axis adjustments (0 - 100)
    final newSpatial = (currentProfile.spatialPlanning * 0.85 + (clearRate * 40.0 + 30.0) * 0.15).clamp(10.0, 100.0);
    final newEfficiency = (currentProfile.efficiency * 0.85 + (min(avgScorePerMove / 2.5, 100.0)) * 0.15).clamp(10.0, 100.0);
    final newCombo = (currentProfile.comboSkill * 0.85 + (min(maxCombo * 16.0 + 20.0, 100.0)) * 0.15).clamp(10.0, 100.0);
    final newRisk = (currentProfile.riskManagement * 0.85 + (min(highDensityRecoveries * 25.0 + 35.0, 100.0)) * 0.15).clamp(10.0, 100.0);
    final newPhysics = (currentProfile.physicsMastery * 0.85 + (min(specialMoves * 20.0 + 40.0, 100.0)) * 0.15).clamp(10.0, 100.0);
    final newGrid = (currentProfile.gridAwareness * 0.85 + (newSpatial * 0.5 + newEfficiency * 0.5) * 0.15).clamp(10.0, 100.0);

    // Compute composite skill rating (0 - 1000)
    final composite = ((newSpatial * 0.25 +
                newEfficiency * 0.20 +
                newCombo * 0.20 +
                newRisk * 0.15 +
                newPhysics * 0.10 +
                newGrid * 0.10) *
            10.0)
        .round()
        .clamp(GameConstants.minSkillRating, GameConstants.maxSkillRating);

    // Smooth transition
    final smoothedRating = (currentProfile.overallSkillRating * 0.9 + composite * 0.1).round();

    return currentProfile.copyWith(
      spatialPlanning: newSpatial,
      efficiency: newEfficiency,
      comboSkill: newCombo,
      riskManagement: newRisk,
      physicsMastery: newPhysics,
      gridAwareness: newGrid,
      overallSkillRating: smoothedRating,
    );
  }
}
