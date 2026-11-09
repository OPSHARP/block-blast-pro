// Board Logic Service for placement validation, clear detection, and scoring

import 'dart:math';
import '../models/board_state.dart';
import '../models/block_model.dart';
import '../models/cell_model.dart';
import '../models/block_weight.dart';
import '../models/special_block_type.dart';
import '../models/block_skin_style.dart';
import '../../core/constants/game_constants.dart';

class ClearResult {
  final BoardState newBoard;
  final int clearedLinesCount;
  final List<int> clearedRows;
  final List<int> clearedColumns;
  final List<Point<int>> clearedCells;
  final bool hasBloomBonus;
  final List<Point<int>> crackedIceCells;
  final List<Point<int>> shatteredIceCells;
  final List<Point<int>> crackedGeodeCells;
  final List<Point<int>> shatteredGeodeCells;
  final List<Point<int>> detonatedTimeBombCells;
  final List<Point<int>> portalTriggerCells;
  final List<Point<int>> portalTargetCells;
  final List<Point<int>> lightningTriggerCells;
  final List<Point<int>> lightningTargetCells;
  final List<Point<int>> rainbowCells;
  final int coinsEarned;

  const ClearResult({
    required this.newBoard,
    required this.clearedLinesCount,
    required this.clearedRows,
    required this.clearedColumns,
    required this.clearedCells,
    this.hasBloomBonus = false,
    this.crackedIceCells = const [],
    this.shatteredIceCells = const [],
    this.crackedGeodeCells = const [],
    this.shatteredGeodeCells = const [],
    this.detonatedTimeBombCells = const [],
    this.portalTriggerCells = const [],
    this.portalTargetCells = const [],
    this.lightningTriggerCells = const [],
    this.lightningTargetCells = const [],
    this.rainbowCells = const [],
    this.coinsEarned = 0,
  });
}

class BoardService {
  const BoardService();

  // Validate if block can be placed at (targetX, targetY)
  bool canPlaceBlock(BoardState board, BlockModel block, int targetX, int targetY) {
    for (final offset in block.offsets) {
      final bx = targetX + offset.dx;
      final by = targetY + offset.dy;

      if (!board.isValidCoord(bx, by)) {
        return false;
      }
      // TNT Bomb can be placed anywhere within board bounds, including on occupied blocks to detonate them
      if (block.specialType == SpecialBlockType.bomb) {
        continue;
      }
      if (board.isOccupied(bx, by)) {
        return false;
      }
    }
    return true;
  }

  // Find valid ghost cells for drag preview
  List<Point<int>>? getGhostPlacement(
      BoardState board, BlockModel block, int targetX, int targetY) {
    if (!canPlaceBlock(board, block, targetX, targetY)) return null;

    return block.offsets
        .map((o) => Point<int>(targetX + o.dx, targetY + o.dy))
        .toList();
  }

  // Commit placement to the board with weight and special rules
  BoardState placeBlock(
      BoardState board, BlockModel block, int targetX, int targetY) {
    var updatedBoard = board.copyWith();

    for (final offset in block.offsets) {
      final bx = targetX + offset.dx;
      final by = targetY + offset.dy;

      final isAnchor = block.specialType == SpecialBlockType.anchor;
      final initialHp = block.specialType == SpecialBlockType.geode
          ? 3
          : (block.specialType == SpecialBlockType.timeBomb
              ? 5
              : (block.specialType == SpecialBlockType.ice ? 2 : 1));

      final newCell = CellModel(
        x: bx,
        y: by,
        isOccupied: true,
        colorValue: block.colorValue,
        weightClass: block.weightClass,
        specialType: block.specialType,
        skinStyle: block.skinStyle,
        isLocked: isAnchor,
        hitPoints: initialHp,
      );
      updatedBoard = updatedBoard.withCellUpdated(newCell);
    }

    // Special behavior: Void Block clears surrounding cells immediately
    if (block.specialType == SpecialBlockType.voidBlock) {
      updatedBoard = _applyVoidEffect(updatedBoard, targetX, targetY);
    } else if (block.specialType == SpecialBlockType.bomb) {
      updatedBoard = _applyBombEffect(updatedBoard, targetX, targetY);
    } else if (block.specialType == SpecialBlockType.laser) {
      updatedBoard = _applyLaserEffect(updatedBoard, targetX, targetY);
    }

    return updatedBoard;
  }

  BoardState _applyVoidEffect(BoardState board, int cx, int cy) {
    var current = board.copyWith();
    final deltas = [
      const Point(0, 0),
      const Point(1, 0),
      const Point(-1, 0),
      const Point(0, 1),
      const Point(0, -1),
    ];
    for (final d in deltas) {
      final nx = cx + d.x;
      final ny = cy + d.y;
      if (current.isValidCoord(nx, ny)) {
        final cell = current.getCell(nx, ny);
        if (!cell.isLocked) {
          current = current.withCellUpdated(cell.cleared());
        }
      }
    }
    return current;
  }

  BoardState _applyBombEffect(BoardState board, int cx, int cy) {
    var current = board.copyWith();
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        final nx = cx + dx;
        final ny = cy + dy;
        if (current.isValidCoord(nx, ny)) {
          final cell = current.getCell(nx, ny);
          if (!cell.isLocked) {
            current = current.withCellUpdated(cell.cleared());
          }
        }
      }
    }
    return current;
  }

  BoardState _applyLaserEffect(BoardState board, int cx, int cy) {
    var current = board.copyWith();
    // Clear entire row
    for (int x = 0; x < current.gridSize; x++) {
      final cell = current.getCell(x, cy);
      if (!cell.isLocked) {
        current = current.withCellUpdated(cell.cleared());
      }
    }
    // Clear entire column
    for (int y = 0; y < current.gridSize; y++) {
      final cell = current.getCell(cx, y);
      if (!cell.isLocked) {
        current = current.withCellUpdated(cell.cleared());
      }
    }
    return current;
  }

  /// Sledgehammer power tool: smashes and clears any single cell on the board
  BoardState smashCell(BoardState board, int x, int y) {
    if (!board.isValidCoord(x, y)) return board;
    final cell = board.getCell(x, y);
    if (!cell.isOccupied) return board;
    return board.withCellUpdated(cell.cleared());
  }

  /// TNT Bomb detonation: clears all occupied cells in a 3x3 radius centered at (cx, cy)
  ({BoardState newBoard, List<Point<int>> clearedCells, int destroyedCount}) detonateArea(
      BoardState board, int cx, int cy, {int radius = 1}) {
    var updated = board.copyWith();
    final cleared = <Point<int>>[];
    int count = 0;

    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        final nx = cx + dx;
        final ny = cy + dy;
        if (updated.isValidCoord(nx, ny)) {
          final cell = updated.getCell(nx, ny);
          if (cell.isOccupied && !cell.isLocked) {
            updated = updated.withCellUpdated(cell.cleared());
            cleared.add(Point<int>(nx, ny));
            count++;
          }
        }
      }
    }

    return (newBoard: updated, clearedCells: cleared, destroyedCount: count);
  }

  // Detect and clear full rows and columns simultaneously
  ClearResult detectAndClearLines(BoardState board) {
    final clearedRows = <int>[];
    final clearedColumns = <int>[];
    bool hasBloom = false;

    // Check rows
    for (int y = 0; y < board.gridSize; y++) {
      bool rowFull = true;
      for (int x = 0; x < board.gridSize; x++) {
        if (!board.cells[y][x].isOccupied) {
          rowFull = false;
          break;
        }
      }
      if (rowFull) {
        clearedRows.add(y);
      }
    }

    // Check columns
    for (int x = 0; x < board.gridSize; x++) {
      bool colFull = true;
      for (int y = 0; y < board.gridSize; y++) {
        if (!board.cells[y][x].isOccupied) {
          colFull = false;
          break;
        }
      }
      if (colFull) {
        clearedColumns.add(x);
      }
    }

    final candidateCells = <Point<int>>{};
    for (final r in clearedRows) {
      for (int x = 0; x < board.gridSize; x++) {
        candidateCells.add(Point<int>(x, r));
      }
    }
    for (final c in clearedColumns) {
      for (int y = 0; y < board.gridSize; y++) {
        candidateCells.add(Point<int>(c, y));
      }
    }

    // If no lines cleared, return original board
    if (clearedRows.isEmpty && clearedColumns.isEmpty) {
      return ClearResult(
        newBoard: board,
        clearedLinesCount: 0,
        clearedRows: const [],
        clearedColumns: const [],
        clearedCells: const [],
      );
    }

    final actuallyClearedCells = <Point<int>>[];
    final crackedIceCells = <Point<int>>[];
    final shatteredIceCells = <Point<int>>[];
    final crackedGeodeCells = <Point<int>>[];
    final shatteredGeodeCells = <Point<int>>[];
    final detonatedTimeBombCells = <Point<int>>[];
    final portalTriggers = <Point<int>>[];
    final portalTargets = <Point<int>>[];
    final lightningTriggers = <Point<int>>[];
    final lightningTargets = <Point<int>>[];
    final rainbowCells = <Point<int>>[];
    int coins = 0;

    var newBoard = board.copyWith();

    for (final pt in candidateCells) {
      final cell = board.getCell(pt.x, pt.y);
      if (cell.specialType == SpecialBlockType.bloom) {
        hasBloom = true;
      }
      if (cell.specialType == SpecialBlockType.coin) {
        coins += 10;
      }
      if (cell.specialType == SpecialBlockType.lightning) {
        lightningTriggers.add(pt);
      }
      if (cell.specialType == SpecialBlockType.rainbow) {
        rainbowCells.add(pt);
      }

      // Time-Bomb block: defused in line clear!
      if (cell.specialType == SpecialBlockType.timeBomb) {
        detonatedTimeBombCells.add(pt);
        coins += 25;
        newBoard = newBoard.withCellUpdated(cell.cleared());
        actuallyClearedCells.add(pt);
      } else if (cell.specialType == SpecialBlockType.portal) {
        portalTriggers.add(pt);
        newBoard = newBoard.withCellUpdated(cell.cleared());
        actuallyClearedCells.add(pt);
      } else if (cell.specialType == SpecialBlockType.geode && cell.hitPoints > 1) {
        // Multi-layer Geode crystal: cracks layer, remains on board
        newBoard = newBoard.withCellUpdated(cell.copyWith(hitPoints: cell.hitPoints - 1));
        crackedGeodeCells.add(pt);
      } else if (cell.specialType == SpecialBlockType.geode && cell.hitPoints <= 1) {
        // Final geode crystal layer shattered!
        shatteredGeodeCells.add(pt);
        newBoard = newBoard.withCellUpdated(cell.cleared());
        actuallyClearedCells.add(pt);
      } else if (cell.specialType == SpecialBlockType.ice && cell.hitPoints > 1) {
        // Ice block: cracks on first clear
        newBoard = newBoard.withCellUpdated(cell.copyWith(hitPoints: 1));
        crackedIceCells.add(pt);
      } else {
        if (cell.specialType == SpecialBlockType.ice && cell.hitPoints == 1) {
          shatteredIceCells.add(pt);
        }
        newBoard = newBoard.withCellUpdated(cell.cleared());
        actuallyClearedCells.add(pt);
      }
    }

    // Portal Cross-Resonance: channels clearing energy to linked portals on the board
    if (portalTriggers.isNotEmpty) {
      for (int y = 0; y < newBoard.gridSize; y++) {
        for (int x = 0; x < newBoard.gridSize; x++) {
          final c = newBoard.getCell(x, y);
          if (c.isOccupied && c.specialType == SpecialBlockType.portal && !portalTriggers.contains(Point(x, y))) {
            portalTargets.add(Point(x, y));
            // Blast the portal and immediate orthogonal neighbors
            final deltas = [const Point(0, 0), const Point(1, 0), const Point(-1, 0), const Point(0, 1), const Point(0, -1)];
            for (final d in deltas) {
              final nx = x + d.x;
              final ny = y + d.y;
              if (newBoard.isValidCoord(nx, ny) && newBoard.isOccupied(nx, ny) && !newBoard.getCell(nx, ny).isLocked) {
                newBoard = newBoard.withCellUpdated(newBoard.getCell(nx, ny).cleared());
                actuallyClearedCells.add(Point(nx, ny));
              }
            }
          }
        }
      }
    }

    // Lightning Chain Reaction: strikes up to 3 random other occupied cells per trigger
    if (lightningTriggers.isNotEmpty) {
      final eligibleTargets = <Point<int>>[];
      for (int y = 0; y < newBoard.gridSize; y++) {
        for (int x = 0; x < newBoard.gridSize; x++) {
          final c = newBoard.getCell(x, y);
          if (c.isOccupied && !c.isLocked) {
            eligibleTargets.add(Point<int>(x, y));
          }
        }
      }
      eligibleTargets.shuffle();
      final maxArcs = min(eligibleTargets.length, lightningTriggers.length * 3);
      for (int i = 0; i < maxArcs; i++) {
        final targetPt = eligibleTargets[i];
        final targetCell = newBoard.getCell(targetPt.x, targetPt.y);
        newBoard = newBoard.withCellUpdated(targetCell.cleared());
        lightningTargets.add(targetPt);
        actuallyClearedCells.add(targetPt);
      }
    }

    return ClearResult(
      newBoard: newBoard,
      clearedLinesCount: clearedRows.length + clearedColumns.length,
      clearedRows: clearedRows,
      clearedColumns: clearedColumns,
      clearedCells: actuallyClearedCells,
      hasBloomBonus: hasBloom,
      crackedIceCells: crackedIceCells,
      shatteredIceCells: shatteredIceCells,
      crackedGeodeCells: crackedGeodeCells,
      shatteredGeodeCells: shatteredGeodeCells,
      detonatedTimeBombCells: detonatedTimeBombCells,
      portalTriggerCells: portalTriggers,
      portalTargetCells: portalTargets,
      lightningTriggerCells: lightningTriggers,
      lightningTargetCells: lightningTargets,
      rainbowCells: rainbowCells,
      coinsEarned: coins,
    );
  }

  /// Ticks move countdowns at turn completion (Time-Bomb countdown)
  BoardState tickMoveEnd(BoardState board) {
    var updated = board.copyWith();
    for (int y = 0; y < updated.gridSize; y++) {
      for (int x = 0; x < updated.gridSize; x++) {
        final cell = updated.getCell(x, y);
        if (cell.isOccupied && cell.specialType == SpecialBlockType.timeBomb) {
          final newCount = cell.hitPoints - 1;
          if (newCount <= 0) {
            // Countdown expired: turns into solid obsidian rock obstacle
            updated = updated.withCellUpdated(cell.copyWith(
              specialType: SpecialBlockType.none,
              hitPoints: 1,
              colorValue: 0xFF37474F,
            ));
          } else {
            updated = updated.withCellUpdated(cell.copyWith(hitPoints: newCount));
          }
        }
      }
    }
    return updated;
  }

  /// Lava Mode: pushes a row of molten lava rock from bottom if no lines cleared
  BoardState advanceLava(BoardState board) {
    var updated = board.copyWith();
    final bottomY = updated.gridSize - 1;

    // Shift entire board upward by 1 row to simulate rising molten magma
    for (int y = 0; y < bottomY; y++) {
      for (int x = 0; x < updated.gridSize; x++) {
        final below = updated.getCell(x, y + 1);
        updated = updated.withCellUpdated(CellModel(
          x: x,
          y: y,
          isOccupied: below.isOccupied,
          colorValue: below.colorValue,
          weightClass: below.weightClass,
          specialType: below.specialType,
          skinStyle: below.skinStyle,
          isLocked: below.isLocked,
          hitPoints: below.hitPoints,
        ));
      }
    }

    // Fill bottom row with fresh bubbling volcanic magma rock
    for (int x = 0; x < updated.gridSize; x++) {
      updated = updated.withCellUpdated(CellModel(
        x: x,
        y: bottomY,
        isOccupied: true,
        colorValue: 0xFFFF3D00,
        specialType: SpecialBlockType.none,
        skinStyle: BlockSkinStyle.volcanicMagma,
      ));
    }
    return updated;
  }

  /// Dissolve and clear all occupied cells of a specific color (Color Magnet Booster)
  ({BoardState newBoard, List<Point<int>> clearedCells, int destroyedCount}) dissolveColor(
      BoardState board, int targetColor) {
    var updated = board.copyWith();
    final cleared = <Point<int>>[];
    int count = 0;

    for (int y = 0; y < board.gridSize; y++) {
      for (int x = 0; x < board.gridSize; x++) {
        final cell = board.getCell(x, y);
        if (cell.isOccupied && cell.colorValue == targetColor && !cell.isLocked) {
          updated = updated.withCellUpdated(cell.cleared());
          cleared.add(Point<int>(x, y));
          count++;
        }
      }
    }
    return (newBoard: updated, clearedCells: cleared, destroyedCount: count);
  }

  // Calculate score for placement and clear events
  int calculateScore({
    required int placedCellsCount,
    required int linesCleared,
    required int comboCount,
    required BlockWeightClass weightClass,
    bool hasBloomBonus = false,
  }) {
    // Placement points
    int score = placedCellsCount * GameConstants.pointsPerPlacedCell;

    // Weight bonus
    score = (score * weightClass.weight).round();

    // Clear points
    if (linesCleared > 0) {
      int clearPoints = linesCleared * GameConstants.pointsPerClearedLine;

      // Multi-line bonus
      if (linesCleared > 1) {
        clearPoints += (linesCleared - 1) * GameConstants.multiLineBonusMultiplier;
      }

      // Combo scaling
      final comboMultiplier = 1.0 + (comboCount * 0.5);
      clearPoints = (clearPoints * comboMultiplier).round();

      if (hasBloomBonus) {
        clearPoints *= 2;
      }

      score += clearPoints;
    }

    return score;
  }

  // Check if any remaining piece in tray can be legally placed
  bool hasValidMovesRemaining(BoardState board, List<BlockModel?> trayPieces) {
    for (final piece in trayPieces) {
      if (piece == null) continue;

      for (int y = 0; y <= board.gridSize - piece.height; y++) {
        for (int x = 0; x <= board.gridSize - piece.width; x++) {
          if (canPlaceBlock(board, piece, x, y)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
