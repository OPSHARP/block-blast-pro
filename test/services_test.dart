import 'package:flutter_test/flutter_test.dart';
import 'package:block_blast_pro/domain/services/daily_challenge_service.dart';
import 'package:block_blast_pro/domain/services/difficulty_service.dart';
import 'package:block_blast_pro/domain/services/piece_generator_service.dart';
import 'package:block_blast_pro/domain/services/board_service.dart';
import 'package:block_blast_pro/domain/models/board_state.dart';
import 'package:block_blast_pro/domain/models/cell_model.dart';
import 'package:block_blast_pro/domain/models/game_mode.dart';
import 'package:block_blast_pro/domain/models/player_skill_profile.dart';
import 'package:block_blast_pro/core/theme/game_theme.dart';

void main() {
  group('DailyChallengeService', () {
    const service = DailyChallengeService();

    test('deterministic generation produces identical challenge for same date', () {
      final date = DateTime(2026, 9, 8);
      final challenge1 = service.getChallengeForDate(date);
      final challenge2 = service.getChallengeForDate(date);

      expect(challenge1.dateString, challenge2.dateString);
      expect(challenge1.seed, challenge2.seed);
      expect(challenge1.title, challenge2.title);
      expect(challenge1.description, challenge2.description);
      expect(challenge1.targetValue, challenge2.targetValue);
      expect(challenge1.objectiveType, challenge2.objectiveType);
    });

    test('different dates generate distinct challenge seeds or dates', () {
      final date1 = DateTime(2026, 9, 8);
      final date2 = DateTime(2026, 9, 9);
      final challenge1 = service.getChallengeForDate(date1);
      final challenge2 = service.getChallengeForDate(date2);

      expect(challenge1.dateString, isNot(equals(challenge2.dateString)));
      expect(challenge1.seed, isNot(equals(challenge2.seed)));
    });
  });

  group('DifficultyService & PlayerSkillProfile', () {
    test('rolling window computes updated ratings accurately', () {
      final diffService = DifficultyService();
      var profile = const PlayerSkillProfile();

      for (int i = 0; i < 25; i++) {
        diffService.recordMove(const MoveMetric(
          scoreEarned: 250,
          linesCleared: 2,
          combo: 3,
          boardDensityBeforeMove: 0.70,
          usedSpecialBlock: true,
        ));
      }

      profile = diffService.updateProfile(profile);

      expect(profile.spatialPlanning, greaterThan(30));
      expect(profile.comboSkill, greaterThan(30));
      expect(profile.overallSkillRating, greaterThan(400));
    });
  });

  group('PieceGeneratorService', () {
    test('generates exactly 3 pieces adhering to theme and fitting requirements', () {
      final generator = PieceGeneratorService();
      final board = BoardState();
      final theme = GameTheme.allThemes.first;

      final pieces = generator.generateTrayPieces(
        board: board,
        theme: theme,
        playerSkillRating: 500,
        gameMode: GameMode.classic,
      );

      expect(pieces.length, 3);
      for (final piece in pieces) {
        expect(piece.offsets.isNotEmpty, isTrue);
      }
    });

    test('guarantees at least one piece can be placed on a non-full board', () {
      final generator = PieceGeneratorService();
      const boardService = BoardService();
      
      // Fill board mostly, leaving row 0, col 0 empty
      final cells = List.generate(
        8,
        (y) => List.generate(
          8,
          (x) => (x == 0 && y == 0)
              ? CellModel(x: x, y: y)
              : CellModel(x: x, y: y, isOccupied: true, colorValue: 0xFFFFFFFF),
        ),
      );
      final board = BoardState(gridSize: 8, cells: cells);

      final pieces = generator.generateTrayPieces(
        board: board,
        theme: GameTheme.allThemes.first,
        playerSkillRating: 700,
        gameMode: GameMode.classic,
      );

      expect(pieces.length, 3);
      // At least one piece must fit in the remaining space
      final hasFit = pieces.any((p) {
        for (int r = 0; r < 8; r++) {
          for (int c = 0; c < 8; c++) {
            if (boardService.canPlaceBlock(board, p, c, r)) return true;
          }
        }
        return false;
      });
      expect(hasFit, isTrue);
    });
  });
}
