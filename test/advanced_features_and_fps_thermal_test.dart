import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:block_blast_pro/domain/models/board_state.dart';
import 'package:block_blast_pro/domain/models/block_catalog.dart';
import 'package:block_blast_pro/domain/models/special_block_type.dart';
import 'package:block_blast_pro/domain/models/block_skin_style.dart';
import 'package:block_blast_pro/domain/models/game_mode.dart';
import 'package:block_blast_pro/core/theme/game_theme.dart';
import 'package:block_blast_pro/domain/services/board_service.dart';
import 'package:block_blast_pro/game/components/particle_engine.dart';

void main() {
  group('New Game Modes, Themes, and Skin Styles', () {
    test('GameMode enum contains adventure and lava modes with proper properties', () {
      expect(GameMode.adventure.displayName, contains('Journey'));
      expect(GameMode.adventure.hasFailState, isTrue);

      expect(GameMode.lava.displayName, contains('Lava'));
      expect(GameMode.lava.hasFailState, isTrue);
    });

    test('All new block skins exist and are registered in BlockSkinStyle', () {
      expect(BlockSkinStyle.values, contains(BlockSkinStyle.cyberpunk));
      expect(BlockSkinStyle.values, contains(BlockSkinStyle.bioluminescence));
      expect(BlockSkinStyle.values, contains(BlockSkinStyle.retroArcade));
      expect(BlockSkinStyle.values, contains(BlockSkinStyle.cosmicStarlight));
    });

    test('All new themes exist and are in GameTheme.allThemes', () {
      final themeIds = GameTheme.allThemes.map((t) => t.id).toList();
      expect(themeIds, contains('bioluminescence'));
      expect(themeIds, contains('retro_arcade'));
      expect(themeIds, contains('cosmic_starlight'));
    });
  });

  group('Geode, Time-Bomb, Portal, and Lava Board Logic', () {
    late BoardService boardService;

    setUp(() {
      boardService = const BoardService();
    });

    test('Placing a geode block assigns initial hit points of 3', () {
      final board = BoardState(gridSize: 8);
      final geodeBlock = BlockCatalog.createBlock(
        id: 'geode_1',
        shape: BlockCatalog.single,
        colorValue: 0xFF9C27B0,
        specialType: SpecialBlockType.geode,
      );

      final newBoard = boardService.placeBlock(board, geodeBlock, 2, 2);
      final cell = newBoard.getCell(2, 2);
      expect(cell.isOccupied, isTrue);
      expect(cell.specialType, equals(SpecialBlockType.geode));
      expect(cell.hitPoints, equals(3));
      expect(cell.geodeStage, equals(3));
    });

    test('Clearing a row containing a geode cracks it from HP 3 to 2, does not vacate cell', () {
      var board = BoardState(gridSize: 8);
      final geodeBlock = BlockCatalog.createBlock(
        id: 'geode_test',
        shape: BlockCatalog.single,
        colorValue: 0xFF9C27B0,
        specialType: SpecialBlockType.geode,
      );
      board = boardService.placeBlock(board, geodeBlock, 0, 0);

      // Fill rest of row y = 0
      for (int x = 1; x < 8; x++) {
        final filler = BlockCatalog.createBlock(
          id: 'fill_$x',
          shape: BlockCatalog.single,
          colorValue: 0xFF2196F3,
        );
        board = boardService.placeBlock(board, filler, x, 0);
      }

      final clearResult = boardService.detectAndClearLines(board);
      expect(clearResult.clearedRows, contains(0));
      expect(clearResult.crackedGeodeCells, contains(const Point(0, 0)));
      expect(clearResult.shatteredGeodeCells, isEmpty);

      // The geode is still on the board at (0, 0) with HP 2
      final afterCell = clearResult.newBoard.getCell(0, 0);
      expect(afterCell.isOccupied, isTrue);
      expect(afterCell.hitPoints, equals(2));
    });

    test('Placing a timeBomb assigns initial hit points of 5 and tickMoveEnd decrements countdown', () {
      var board = BoardState(gridSize: 8);
      final bombBlock = BlockCatalog.createBlock(
        id: 'bomb_1',
        shape: BlockCatalog.single,
        colorValue: 0xFFFF5722,
        specialType: SpecialBlockType.timeBomb,
      );

      board = boardService.placeBlock(board, bombBlock, 4, 4);
      expect(board.getCell(4, 4).bombCountdown, equals(5));

      // Tick move end decrements
      final tickedBoard = boardService.tickMoveEnd(board);
      expect(tickedBoard.getCell(4, 4).bombCountdown, equals(4));
    });

    test('Lava advance pushes board upward and fills bottom row with basalt lava', () {
      var board = BoardState(gridSize: 8);
      // Place a piece at row 7
      final piece = BlockCatalog.createBlock(
        id: 'test_p',
        shape: BlockCatalog.single,
        colorValue: 0xFF00E5FF,
      );
      board = boardService.placeBlock(board, piece, 3, 7);

      final lavaBoard = boardService.advanceLava(board);

      // Previous row 7 piece should have been shifted up to row 6
      expect(lavaBoard.getCell(3, 6).isOccupied, isTrue);

      // Bottom row (row 7) should now be completely occupied by lava cells
      for (int x = 0; x < 8; x++) {
        expect(lavaBoard.getCell(x, 7).isOccupied, isTrue);
        expect(lavaBoard.getCell(x, 7).skinStyle, equals(BlockSkinStyle.volcanicMagma));
      }
    });
  });

  group('Highest FPS & Thermal Efficiency Optimizations', () {
    test('ParticleEngine reports hasActiveParticles correctly and skips updates when idle', () {
      final engine = ParticleEngine();

      // Initially zero active particles
      expect(engine.hasActiveParticles, isFalse);

      // Updating empty engine returns in 0ms without iteration
      engine.update(0.016);
      expect(engine.hasActiveParticles, isFalse);

      // Spawning particles sets active count
      engine.spawnGeodeShatter(centerX: 100, centerY: 100, cellSize: 40);
      expect(engine.hasActiveParticles, isTrue);

      // Clearing all particles resets hasActiveParticles to false immediately
      engine.clear();
      expect(engine.hasActiveParticles, isFalse);
    });
  });
}
