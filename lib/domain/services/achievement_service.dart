// Achievement Registry and Tracking Service according to PRD Sections 50-52

import '../models/achievement.dart';

class AchievementService {
  static List<Achievement> getInitialAchievements() {
    return const [
      // Scoring
      Achievement(
        id: 'score_1k',
        title: 'First Spark',
        description: 'Score your first 1,000 points.',
        category: AchievementCategory.scoring,
        targetValue: 1000,
        reward: 'Crystal Board Border',
      ),
      Achievement(
        id: 'score_10k',
        title: 'Pattern Architect',
        description: 'Reach 10,000 points in a single game.',
        category: AchievementCategory.scoring,
        targetValue: 10000,
        reward: 'Neon Aura',
      ),
      Achievement(
        id: 'score_50k',
        title: 'Block Luminary',
        description: 'Surpass 50,000 points.',
        category: AchievementCategory.scoring,
        targetValue: 50000,
        reward: 'Aurora Palette',
      ),

      // Combos
      Achievement(
        id: 'combo_3',
        title: 'In The Groove',
        description: 'Reach a 3x combo multiplier.',
        category: AchievementCategory.combos,
        targetValue: 3,
        reward: 'Chime Voice Pack',
      ),
      Achievement(
        id: 'combo_6',
        title: 'Resonance Flow',
        description: 'Chain together a 6x combo streak.',
        category: AchievementCategory.combos,
        targetValue: 6,
        reward: 'Ripple Burst FX',
      ),
      Achievement(
        id: 'combo_10',
        title: 'Symphony of Lines',
        description: 'Achieve a legendary 10x combo.',
        category: AchievementCategory.combos,
        targetValue: 10,
        reward: 'Golden Sparkles',
      ),

      // Physics
      Achievement(
        id: 'heavy_first',
        title: 'Gravitational Force',
        description: 'Place 5 Heavy or Ultra weight blocks.',
        category: AchievementCategory.physics,
        targetValue: 5,
        reward: 'Stone Material Pack',
      ),
      Achievement(
        id: 'special_specialists',
        title: 'Specialist',
        description: 'Activate 10 Special Blocks (Anchor, Void, Bloom, Pulse).',
        category: AchievementCategory.physics,
        targetValue: 10,
        reward: 'Void Shockwave',
      ),

      // Grid Shifts
      Achievement(
        id: 'shift_survive_5',
        title: 'Shift Adapter',
        description: 'Survive 5 dynamic grid shifts.',
        category: AchievementCategory.grid,
        targetValue: 5,
        reward: 'Subtle Warning Glow',
      ),
      Achievement(
        id: 'shift_survive_20',
        title: 'Tectonic Sovereign',
        description: 'Successfully navigate through 20 grid shifts.',
        category: AchievementCategory.grid,
        targetValue: 20,
        reward: 'Cybernetic Grid Skin',
      ),

      // Daily
      Achievement(
        id: 'daily_first',
        title: 'Daily Dedication',
        description: 'Complete your first Daily Challenge.',
        category: AchievementCategory.daily,
        targetValue: 1,
        reward: 'Streak Badge',
      ),
      Achievement(
        id: 'daily_streak_7',
        title: 'Weekly Ritual',
        description: 'Maintain a 7-day Daily Challenge streak.',
        category: AchievementCategory.daily,
        targetValue: 7,
        reward: 'Crown Frame',
      ),

      // Exploration
      Achievement(
        id: 'themes_unlocked_3',
        title: 'Chameleon',
        description: 'Unlock 3 distinct visual themes.',
        category: AchievementCategory.exploration,
        targetValue: 3,
        reward: 'Ambient Sound Pack',
      ),
    ];
  }
}
