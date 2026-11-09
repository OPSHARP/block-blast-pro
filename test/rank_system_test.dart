import 'package:flutter_test/flutter_test.dart';
import 'package:block_blast_pro/domain/models/rank_tier.dart';
import 'package:block_blast_pro/domain/models/leaderboard_entry.dart';

void main() {
  group('RankTier Domain Model Tests', () {
    test('RankTier.fromScore returns correct tiers across all score thresholds', () {
      expect(RankTier.fromScore(0).id, RankTierId.bronze);
      expect(RankTier.fromScore(450).id, RankTierId.bronze);
      expect(RankTier.fromScore(999).id, RankTierId.bronze);

      expect(RankTier.fromScore(1000).id, RankTierId.silver);
      expect(RankTier.fromScore(2499).id, RankTierId.silver);

      expect(RankTier.fromScore(2500).id, RankTierId.gold);
      expect(RankTier.fromScore(4999).id, RankTierId.gold);

      expect(RankTier.fromScore(5000).id, RankTierId.platinum);
      expect(RankTier.fromScore(9999).id, RankTierId.platinum);

      expect(RankTier.fromScore(10000).id, RankTierId.diamond);
      expect(RankTier.fromScore(19999).id, RankTierId.diamond);

      expect(RankTier.fromScore(20000).id, RankTierId.legend);
      expect(RankTier.fromScore(50000).id, RankTierId.legend);
    });

    test('RankTier calculates division progression (III, II, I) correctly', () {
      final bronze = RankTier.bronze;
      expect(bronze.division(100), 'III');
      expect(bronze.division(500), 'II');
      expect(bronze.division(900), 'I');

      final legend = RankTier.legend;
      expect(legend.division(25000), 'Champion');
    });

    test('RankTier progress and pointsToNext calculate correctly', () {
      final bronze = RankTier.bronze;
      expect(bronze.progress(500), closeTo(0.5, 0.01));
      expect(bronze.pointsToNext(500), 500);

      final legend = RankTier.legend;
      expect(legend.progress(25000), 1.0);
      expect(legend.pointsToNext(25000), 0);
    });

    test('All 6 tiers exist, each with non-empty perks and valid colors', () {
      expect(RankTier.allTiers.length, 6);
      for (final tier in RankTier.allTiers) {
        expect(tier.name.isNotEmpty, true);
        expect(tier.title.isNotEmpty, true);
        expect(tier.perks.isNotEmpty, true);
        expect(tier.gradientColors.length, greaterThanOrEqualTo(2));
      }
    });
  });

  group('LeaderboardEntry Tests', () {
    test('getGlobalLeaderboard correctly places user based on score', () {
      // High score beating everyone
      final topBoard = LeaderboardEntry.getGlobalLeaderboard(
        userHighScore: 35000,
        userDisplayName: 'ProPlayer',
      );
      expect(topBoard.first.isCurrentUser, true);
      expect(topBoard.first.rank, 1);
      expect(topBoard.first.score, 35000);

      // Beginner score
      final lowBoard = LeaderboardEntry.getGlobalLeaderboard(
        userHighScore: 500,
        userDisplayName: 'NovicePlayer',
      );
      final userEntry = lowBoard.firstWhere((e) => e.isCurrentUser);
      expect(userEntry.rank, greaterThan(1));
      expect(userEntry.score, 500);
      expect(userEntry.tier.id, RankTierId.bronze);
    });
  });
}
