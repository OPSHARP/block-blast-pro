// Unit tests for BoardService: placement, line clears, and scoring

import 'package:flutter_test/flutter_test.dart';
import 'package:block_blast_pro/domain/models/board_state.dart';
import 'package:block_blast_pro/domain/models/block_catalog.dart';
import 'package:block_blast_pro/domain/models/block_weight.dart';
import 'package:block_blast_pro/domain/services/board_service.dart';

void main() {
  group('BoardService Tests', () {
    const boardService = BoardService();

    test('canPlaceBlock returns true for empty board within bounds', () {
      final board = BoardState(gridSize: 8);
      final piece = BlockCatalog.createBlock(
        id: 'test_square',
        shape: BlockCatalog.square2x2,
        colorValue: 0xFFFFFFFF,
      );

      expect(boardService.canPlaceBlock(board, piece, 0, 0), isTrue);
      expect(boardService.canPlaceBlock(board, piece, 6, 6), isTrue);
      // Out of bounds:
      expect(boardService.canPlaceBlock(board, piece, 7, 0), isFalse);
      expect(boardService.canPlaceBlock(board, piece, 0, 7), isFalse);
    });

    test('placeBlock updates board cells correctly', () {
      final board = BoardState(gridSize: 8);
      final piece = BlockCatalog.createBlock(
        id: 'test_single',
        shape: BlockCatalog.single,
        colorValue: 0xFFFF0000,
      );

      final newBoard = boardService.placeBlock(board, piece, 3, 3);
      expect(newBoard.isOccupied(3, 3), isTrue);
      expect(newBoard.occupiedCount, equals(1));
      expect(board.isOccupied(3, 3), isFalse); // Immutable
    });

    test('detectAndClearLines clears full row and calculates score', () {
      var board = BoardState(gridSize: 8);
      final single = BlockCatalog.createBlock(
        id: 's',
        shape: BlockCatalog.single,
        colorValue: 0xFF00FF00,
      );

      // Fill entire row y = 2
      for (int x = 0; x < 8; x++) {
        board = boardService.placeBlock(board, single, x, 2);
      }
      expect(board.occupiedCount, equals(8));

      final result = boardService.detectAndClearLines(board);
      expect(result.clearedLinesCount, equals(1));
      expect(result.clearedRows, contains(2));
      expect(result.newBoard.occupiedCount, equals(0));

      final score = boardService.calculateScore(
        placedCellsCount: 1,
        linesCleared: 1,
        comboCount: 1,
        weightClass: BlockWeightClass.normal,
      );
      expect(score, greaterThan(100));
    });

    test('detectAndClearLines clears simultaneous cross (1 row + 1 col)', () {
      var board = BoardState(gridSize: 8);
      final single = BlockCatalog.createBlock(
        id: 's',
        shape: BlockCatalog.single,
        colorValue: 0xFF00FF00,
      );

      // Fill row 0 and column 0
      for (int i = 0; i < 8; i++) {
        board = boardService.placeBlock(board, single, i, 0);
        board = boardService.placeBlock(board, single, 0, i);
      }

      final result = boardService.detectAndClearLines(board);
      expect(result.clearedLinesCount, equals(2));
      expect(result.clearedRows, contains(0));
      expect(result.clearedColumns, contains(0));
      // Intersecting cell (0,0) is cleared without double-decrement
      expect(result.newBoard.occupiedCount, equals(0));
    });
  });
}
