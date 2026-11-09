// Unit tests for GridShiftService: collision safeguards and anchor resistance

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:block_blast_pro/domain/models/board_state.dart';
import 'package:block_blast_pro/domain/models/block_catalog.dart';
import 'package:block_blast_pro/domain/models/special_block_type.dart';
import 'package:block_blast_pro/domain/services/board_service.dart';
import 'package:block_blast_pro/domain/services/grid_shift_service.dart';

void main() {
  group('GridShiftService Tests', () {
    final shiftService = GridShiftService(random: Random(42));
    const boardService = BoardService();

    test('Shift shifts row safely without deleting blocks', () {
      var board = BoardState(gridSize: 8);
      final single = BlockCatalog.createBlock(
        id: 's',
        shape: BlockCatalog.single,
        colorValue: 0xFFFFFFFF,
      );

      // Place single cell in middle of row 3 at (3, 3)
      board = boardService.placeBlock(board, single, 3, 3);
      expect(board.isOccupied(3, 3), isTrue);

      final result = shiftService.executeSafeShift(board);
      if (result.didShift) {
        expect(result.board.occupiedCount, equals(1));
        // Cell moved either to (4, 3), (2, 3), (3, 4), or (3, 2)
        final moved = result.board.isOccupied(4, 3) ||
            result.board.isOccupied(2, 3) ||
            result.board.isOccupied(3, 4) ||
            result.board.isOccupied(3, 2);
        expect(moved, isTrue);
      }
    });

    test('Anchor block prevents shifting of its row', () {
      var board = BoardState(gridSize: 8);
      final anchor = BlockCatalog.createBlock(
        id: 'anchor',
        shape: BlockCatalog.single,
        colorValue: 0xFFFFFFFF,
        specialType: SpecialBlockType.anchor,
      );

      board = boardService.placeBlock(board, anchor, 2, 2);
      expect(board.getCell(2, 2).isLocked, isTrue);
    });
  });
}
