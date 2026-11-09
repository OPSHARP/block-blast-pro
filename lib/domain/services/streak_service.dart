// Service for calculating and awarding Day 1-7 login streak rewards to drive 30-day retention

import '../models/streak_info.dart';

class StreakReward {
  final int day;
  final int bonusRerolls;
  final int bonusRevives;
  final int bonusHammers;
  final int bonusTnts;
  final int bonusRotates;
  final int bonusUndos;
  final int bonusMagnets;
  final int bonusCoins;
  final String title;
  final String description;

  const StreakReward({
    required this.day,
    required this.bonusRerolls,
    required this.bonusRevives,
    this.bonusHammers = 0,
    this.bonusTnts = 0,
    this.bonusRotates = 0,
    this.bonusUndos = 0,
    this.bonusMagnets = 0,
    this.bonusCoins = 0,
    required this.title,
    required this.description,
  });
}

class StreakService {
  const StreakService();

  static const List<StreakReward> schedule = [
    StreakReward(
      day: 1,
      bonusRerolls: 1,
      bonusRevives: 0,
      bonusHammers: 0,
      bonusRotates: 1,
      bonusCoins: 25,
      title: 'Day 1 Starter',
      description: '+1 Reroll, +1 Rotate & 25 Coins',
    ),
    StreakReward(
      day: 2,
      bonusRerolls: 2,
      bonusRevives: 0,
      bonusHammers: 0,
      bonusUndos: 1,
      bonusCoins: 50,
      title: 'Day 2 Momentum',
      description: '+2 Rerolls, +1 Undo & 50 Coins',
    ),
    StreakReward(
      day: 3,
      bonusRerolls: 1,
      bonusRevives: 1,
      bonusHammers: 0,
      bonusRotates: 1,
      bonusCoins: 50,
      title: 'Day 3 Revival',
      description: '+1 Revive, +1 Reroll, +1 Rotate & 50 Coins',
    ),
    StreakReward(
      day: 4,
      bonusRerolls: 2,
      bonusRevives: 0,
      bonusHammers: 1,
      bonusUndos: 1,
      bonusCoins: 75,
      title: 'Day 4 Power Tool',
      description: '+2 Rerolls, +1 Hammer, +1 Undo & 75 Coins',
    ),
    StreakReward(
      day: 5,
      bonusRerolls: 3,
      bonusRevives: 0,
      bonusHammers: 0,
      bonusTnts: 1,
      bonusMagnets: 1,
      bonusCoins: 100,
      title: 'Day 5 Explosive',
      description: '+3 Rerolls, +1 TNT, +1 Magnet & 100 Coins',
    ),
    StreakReward(
      day: 6,
      bonusRerolls: 2,
      bonusRevives: 1,
      bonusHammers: 0,
      bonusRotates: 1,
      bonusUndos: 1,
      bonusCoins: 100,
      title: 'Day 6 Champion',
      description: '+1 Revive, +2 Rerolls, +1 Rotate, +1 Undo & 100 Coins',
    ),
    StreakReward(
      day: 7,
      bonusRerolls: 5,
      bonusRevives: 2,
      bonusHammers: 2,
      bonusTnts: 2,
      bonusRotates: 2,
      bonusUndos: 2,
      bonusMagnets: 2,
      bonusCoins: 250,
      title: 'Day 7 Mega Vault',
      description: '🌟 +5 Rerolls, +2 Revives, +2 Hammers, +2 TNTs, +2 Rotates, +2 Undos, +2 Magnets & 250 Coins',
    ),
  ];

  static StreakReward getRewardForDay(int day) {
    final index = (day - 1) % 7;
    return schedule[index];
  }

  /// Claims today's reward and advances streak
  StreakInfo claimToday(StreakInfo current, {DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();
    final todayStr =
        '${effectiveNow.year}-${effectiveNow.month.toString().padLeft(2, '0')}-${effectiveNow.day.toString().padLeft(2, '0')}';

    if (current.lastClaimDate == todayStr) {
      return current; // Already claimed today
    }

    int newStreak = current.streakCount + 1;
    if (current.lastClaimDate != null) {
      try {
        final last = DateTime.parse(current.lastClaimDate!);
        final differenceInHours = effectiveNow.difference(last).inHours;
        // If missed more than 48 hours, reset streak to 1
        if (differenceInHours > 48) {
          newStreak = 1;
        }
      } catch (_) {
        newStreak = 1;
      }
    }

    final cycleDay = ((newStreak - 1) % 7) + 1;
    final reward = getRewardForDay(cycleDay);

    return current.copyWith(
      streakCount: newStreak,
      lastClaimDate: todayStr,
      freeRerolls: current.freeRerolls + reward.bonusRerolls,
      freeRevives: current.freeRevives + reward.bonusRevives,
      freeHammers: current.freeHammers + reward.bonusHammers,
      freeTnts: current.freeTnts + reward.bonusTnts,
      freeRotates: current.freeRotates + reward.bonusRotates,
      freeUndos: current.freeUndos + reward.bonusUndos,
      freeMagnets: current.freeMagnets + reward.bonusMagnets,
      coins: current.coins + reward.bonusCoins,
    );
  }
}
