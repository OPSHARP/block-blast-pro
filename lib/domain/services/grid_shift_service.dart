// Dynamic Grid Shift Service according to PRD Sections 6-10 & 126-147

import 'dart:math';
import '../models/board_state.dart';
import '../models/cell_model.dart';
import '../models/block_weight.dart';
import '../../core/constants/game_constants.dart';

enum ShiftType {
  horizontalRow,
  verticalColumn,
  bandCompression,
}

enum ShiftDirection {
  left,
  right,
  up,
  down,
}

class ShiftResult {
  final BoardState board;
  final bool didShift;
  final ShiftType shiftType;
  final ShiftDirection direction;
  final int affectedIndex;
  final String description;

  const ShiftResult({
    required this.board,
    required this.didShift,
    this.shiftType = ShiftType.horizontalRow,
    this.direction = ShiftDirection.right,
    this.affectedIndex = 0,
    this.description = '',
  });

  static final noShift = ShiftResult(
    board: BoardState(),
    didShift: false,
    description: 'No shift applied',
  );
}

class GridShiftService {
  final Random _random;

  GridShiftService({Random? random}) : _random = random ?? Random();

  // Evaluate whether conditions warrant a grid shift
  bool shouldTriggerShift({
    required int comboCount,
    required BlockWeightClass lastPlacedWeight,
    required double boardDensity,
    required bool allowGridShift,
    required double frequencyMultiplier,
  }) {
    if (!allowGridShift) return false;

    // Trigger on combo threshold
    if (comboCount >= GameConstants.shiftTriggerComboThreshold) {
      return true;
    }

    // Trigger on Heavy or Ultra block placement
    if (lastPlacedWeight == BlockWeightClass.heavy ||
        lastPlacedWeight == BlockWeightClass.ultra) {
      return _random.nextDouble() < (0.6 * frequencyMultiplier);
    }

    // Trigger on high board pressure
    if (boardDensity >= GameConstants.shiftTriggerBoardDensityThreshold) {
      return _random.nextDouble() < (0.4 * frequencyMultiplier);
    }

    return false;
  }

  // Execute safe deterministic shift
  ShiftResult executeSafeShift(BoardState board) {
    // Determine shift candidate (Try horizontal, then vertical)
    final roll = _random.nextBool();

    if (roll) {
      final hResult = _tryHorizontalRowShift(board);
      if (hResult.didShift) return hResult;
      return _tryVerticalColumnShift(board);
    } else {
      final vResult = _tryVerticalColumnShift(board);
      if (vResult.didShift) return vResult;
      return _tryHorizontalRowShift(board);
    }
  }

  // Try shifting a single row left or right without losing any blocks or breaking bounds
  ShiftResult _tryHorizontalRowShift(BoardState board) {
    // Pick candidate rows that have at least 1 occupied cell and at least 1 empty edge
    final candidateRows = <int>[];
    for (int y = 0; y < board.gridSize; y++) {
      int occupied = 0;
      bool hasAnchor = false;
      for (int x = 0; x < board.gridSize; x++) {
        if (board.cells[y][x].isOccupied) {
          occupied++;
          if (board.cells[y][x].isLocked) hasAnchor = true;
        }
      }
      if (occupied > 0 && occupied < board.gridSize && !hasAnchor) {
        candidateRows.add(y);
      }
    }

    if (candidateRows.isEmpty) {
      return ShiftResult(board: board, didShift: false, description: 'No safe rows to shift');
    }

    // Shuffle and test
    candidateRows.shuffle(_random);

    for (final targetY in candidateRows) {
      final row = board.cells[targetY];
      // Check shift right: rightmost cell (x = gridSize - 1) must be empty!
      final canShiftRight = !row[board.gridSize - 1].isOccupied;
      // Check shift left: leftmost cell (x = 0) must be empty!
      final canShiftLeft = !row[0].isOccupied;

      if (canShiftRight && (_random.nextBool() || !canShiftLeft)) {
        // Shift row right
        final newRow = <CellModel>[];
        // Empty cell inserted at index 0
        newRow.add(CellModel(x: 0, y: targetY));
        for (int x = 0; x < board.gridSize - 1; x++) {
          newRow.add(row[x].copyWith(x: x + 1));
        }

        var newBoard = board.copyWith();
        for (int x = 0; x < board.gridSize; x++) {
          newBoard = newBoard.withCellUpdated(newRow[x]);
        }

        return ShiftResult(
          board: newBoard,
          didShift: true,
          shiftType: ShiftType.horizontalRow,
          direction: ShiftDirection.right,
          affectedIndex: targetY,
          description: 'Row ${targetY + 1} shifted right',
        );
      } else if (canShiftLeft) {
        // Shift row left
        final newRow = <CellModel>[];
        for (int x = 1; x < board.gridSize; x++) {
          newRow.add(row[x].copyWith(x: x - 1));
        }
        // Empty cell inserted at rightmost index
        newRow.add(CellModel(x: board.gridSize - 1, y: targetY));

        var newBoard = board.copyWith();
        for (int x = 0; x < board.gridSize; x++) {
          newBoard = newBoard.withCellUpdated(newRow[x]);
        }

        return ShiftResult(
          board: newBoard,
          didShift: true,
          shiftType: ShiftType.horizontalRow,
          direction: ShiftDirection.left,
          affectedIndex: targetY,
          description: 'Row ${targetY + 1} shifted left',
        );
      }
    }

    return ShiftResult(board: board, didShift: false, description: 'Shift aborted for collision safety');
  }

  // Try shifting a single column up or down without losing any blocks
  ShiftResult _tryVerticalColumnShift(BoardState board) {
    final candidateCols = <int>[];
    for (int x = 0; x < board.gridSize; x++) {
      int occupied = 0;
      bool hasAnchor = false;
      for (int y = 0; y < board.gridSize; y++) {
        if (board.cells[y][x].isOccupied) {
          occupied++;
          if (board.cells[y][x].isLocked) hasAnchor = true;
        }
      }
      if (occupied > 0 && occupied < board.gridSize && !hasAnchor) {
        candidateCols.add(x);
      }
    }

    if (candidateCols.isEmpty) {
      return ShiftResult(board: board, didShift: false, description: 'No safe columns to shift');
    }

    candidateCols.shuffle(_random);

    for (final targetX in candidateCols) {
      // Check shift down: bottom cell (y = gridSize - 1) must be empty!
      final canShiftDown = !board.cells[board.gridSize - 1][targetX].isOccupied;
      // Check shift up: top cell (y = 0) must be empty!
      final canShiftUp = !board.cells[0][targetX].isOccupied;

      if (canShiftDown && (_random.nextBool() || !canShiftUp)) {
        // Shift down
        final newCol = <CellModel>[];
        newCol.add(CellModel(x: targetX, y: 0));
        for (int y = 0; y < board.gridSize - 1; y++) {
          newCol.add(board.cells[y][targetX].copyWith(y: y + 1));
        }

        var newBoard = board.copyWith();
        for (int y = 0; y < board.gridSize; y++) {
          newBoard = newBoard.withCellUpdated(newCol[y]);
        }

        return ShiftResult(
          board: newBoard,
          didShift: true,
          shiftType: ShiftType.verticalColumn,
          direction: ShiftDirection.down,
          affectedIndex: targetX,
          description: 'Column ${targetX + 1} shifted down',
        );
      } else if (canShiftUp) {
        // Shift up
        final newCol = <CellModel>[];
        for (int y = 1; y < board.gridSize; y++) {
          newCol.add(board.cells[y][targetX].copyWith(y: y - 1));
        }
        newCol.add(CellModel(x: targetX, y: board.gridSize - 1));

        var newBoard = board.copyWith();
        for (int y = 0; y < board.gridSize; y++) {
          newBoard = newBoard.withCellUpdated(newCol[y]);
        }

        return ShiftResult(
          board: newBoard,
          didShift: true,
          shiftType: ShiftType.verticalColumn,
          direction: ShiftDirection.up,
          affectedIndex: targetX,
          description: 'Column ${targetX + 1} shifted up',
        );
      }
    }

    return ShiftResult(board: board, didShift: false, description: 'Shift aborted for collision safety');
  }
}
