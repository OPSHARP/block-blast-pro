import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:block_blast_pro/domain/models/board_state.dart';
import 'package:block_blast_pro/domain/models/cell_model.dart';
import 'package:block_blast_pro/domain/models/block_model.dart';
import 'package:block_blast_pro/domain/models/special_block_type.dart';
import 'package:block_blast_pro/domain/models/game_mode.dart';
import 'package:block_blast_pro/domain/services/board_service.dart';
import 'package:block_blast_pro/game/game_coordinator.dart';
import 'package:block_blast_pro/core/audio/asmr_audio_engine.dart';
import 'streak_reroll_skins_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Senior Developer Audit & Quality Tests', () {
    late BoardService boardService;

    setUp(() {
      boardService = const BoardService();
    });

    test('Ice Block 2-hit mechanics: Cracks on 1st clear, Shatters on 2nd clear', () {
      var board = BoardState(gridSize: 8);

      // Fill row 0 with normal occupied blocks except (0, 0) which is an Ice block (2 HP)
      for (int x = 1; x < 8; x++) {
        board = board.withCellUpdated(CellModel(x: x, y: 0, isOccupied: true, colorValue: 0xFF2196F3));
      }
      final iceCell = CellModel(
        x: 0,
        y: 0,
        isOccupied: true,
        colorValue: 0xFF80DEEA,
        specialType: SpecialBlockType.ice,
        hitPoints: 2,
      );
      board = board.withCellUpdated(iceCell);

      // 1st Clear: full row 0
      final result1 = boardService.detectAndClearLines(board);
      expect(result1.clearedLinesCount, 1);
      expect(result1.crackedIceCells, [const Point(0, 0)]);
      expect(result1.shatteredIceCells, isEmpty);

      // The ice cell should still be occupied on the board, but with hitPoints = 1
      final boardAfter1 = result1.newBoard;
      expect(boardAfter1.getCell(0, 0).isOccupied, isTrue);
      expect(boardAfter1.getCell(0, 0).hitPoints, 1);
      expect(boardAfter1.getCell(0, 0).isCracked, isTrue);

      // Fill row 0 again
      var board2 = boardAfter1;
      for (int x = 1; x < 8; x++) {
        board2 = board2.withCellUpdated(CellModel(x: x, y: 0, isOccupied: true, colorValue: 0xFF2196F3));
      }

      // 2nd Clear: full row 0
      final result2 = boardService.detectAndClearLines(board2);
      expect(result2.clearedLinesCount, 1);
      expect(result2.crackedIceCells, isEmpty);
      expect(result2.shatteredIceCells, [const Point(0, 0)]);

      // Now the ice cell should be completely cleared from the board
      final boardAfter2 = result2.newBoard;
      expect(boardAfter2.getCell(0, 0).isOccupied, isFalse);
    });

    test('Color Magnet: dissolveColor removes only cells with matching colorValue', () {
      var board = BoardState(gridSize: 8);
      const targetColor = 0xFFFF5722;
      const otherColor = 0xFF2196F3;

      board = board.withCellUpdated(CellModel(x: 2, y: 3, isOccupied: true, colorValue: targetColor));
      board = board.withCellUpdated(CellModel(x: 4, y: 5, isOccupied: true, colorValue: targetColor));
      board = board.withCellUpdated(CellModel(x: 1, y: 1, isOccupied: true, colorValue: otherColor));

      final res = boardService.dissolveColor(board, targetColor);
      expect(res.destroyedCount, 2);
      expect(res.clearedCells, contains(const Point(2, 3)));
      expect(res.clearedCells, contains(const Point(4, 5)));

      // Target cells cleared
      expect(res.newBoard.getCell(2, 3).isOccupied, isFalse);
      expect(res.newBoard.getCell(4, 5).isOccupied, isFalse);
      // Other color untouched
      expect(res.newBoard.getCell(1, 1).isOccupied, isTrue);
    });

    test('BlockModel rotatedClockwise preserves polyomino integrity and normalizes coordinates', () {
      // Create an L shape (3x2)
      final lPiece = BlockModel(
        id: 'l_test',
        shapeName: 'L',
        offsets: const [
          BlockOffset(0, 0),
          BlockOffset(0, 1),
          BlockOffset(0, 2),
          BlockOffset(1, 2),
        ],
        colorValue: 0xFFFF9800,
        width: 2,
        height: 3,
      );

      final rotated = lPiece.rotatedClockwise();
      expect(rotated.width, 3);
      expect(rotated.height, 2);
      expect(rotated.offsets.length, 4);

      // Min x and min y must be 0
      final minX = rotated.offsets.map((o) => o.dx).reduce(min);
      final minY = rotated.offsets.map((o) => o.dy).reduce(min);
      expect(minX, 0);
      expect(minY, 0);
    });

    test('GameCoordinator rotatePiece rotates specific tray index', () async {
      final repo = MockSaveRepository();
      final coordinator = GameCoordinator(
        saveRepository: repo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.initialize();

      // Ensure freeRotates available
      await repo.saveStreakInfo(coordinator.streakInfo.copyWith(freeRotates: 5));
      await coordinator.initialize();

      final piece0 = coordinator.state.trayPieces[0];
      expect(piece0, isNotNull);

      final success = await coordinator.rotatePiece(0, isFree: true);
      expect(success, isTrue);

      final newPiece0 = coordinator.state.trayPieces[0];
      expect(newPiece0, isNotNull);
      expect(newPiece0!.width, piece0!.height);
      expect(newPiece0.height, piece0.width);
      expect(coordinator.freeRotates, 4);
    });

    test('GameCoordinator undoMove cleanly restores board, tray, and resets targeting modes', () async {
      final repo = MockSaveRepository();
      final coordinator = GameCoordinator(
        saveRepository: repo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.initialize();
      await repo.saveStreakInfo(coordinator.streakInfo.copyWith(freeUndos: 2));
      await coordinator.initialize();

      expect(coordinator.canUndo, isFalse);

      // Simulate a placement
      final piece = coordinator.state.trayPieces[0]!;
      expect(piece, isNotNull);
      coordinator.onDragStart(0, const Offset(100, 100));
      coordinator.onDragUpdate(const Offset(100, 100), const Rect.fromLTRB(0, 0, 320, 320));
      await coordinator.onDragEnd(const Rect.fromLTRB(0, 0, 320, 320));

      expect(coordinator.canUndo, isTrue);
      final scoreAfterMove = coordinator.state.score;
      expect(scoreAfterMove, greaterThan(0));

      // Now execute undo
      final undid = await coordinator.undoMove(isFree: true);
      expect(undid, isTrue);
      expect(coordinator.state.score, 0);
      expect(coordinator.canUndo, isFalse);
      expect(coordinator.freeUndos, 1);
      expect(coordinator.isHammerModeActive, isFalse);
      expect(coordinator.isTntModeActive, isFalse);
      expect(coordinator.isColorMagnetModeActive, isFalse);
      expect(coordinator.hoveredGridCoord, isNull);
      expect(coordinator.draggingTrayIndex, isNull);
    });

    test('GameCoordinator pauseBlitzTimer and resumeBlitzTimer manage timer safely', () async {
      final repo = MockSaveRepository();
      final coordinator = GameCoordinator(
        saveRepository: repo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.startNewGame(mode: GameMode.blitz);
      expect(coordinator.state.gameMode, GameMode.blitz);

      // Pause timer
      coordinator.pauseBlitzTimer();
      final pausedTime = coordinator.state.blitzTimeRemaining;

      // Wait a moment, verify it did not decrement while paused
      await Future.delayed(const Duration(milliseconds: 250));
      expect(coordinator.state.blitzTimeRemaining, pausedTime);

      // Resume timer
      coordinator.resumeBlitzTimer();
      await Future.delayed(const Duration(milliseconds: 250));
      expect(coordinator.state.blitzTimeRemaining, lessThan(pausedTime));

      coordinator.pauseBlitzTimer();
    });

    test('Lightning chain reaction does not throw when eligible targets are empty', () {
      var board = BoardState(gridSize: 8);
      // Fill only row 0, where (0, 0) is a lightning block and (1..7, 0) are normal blocks
      // All other rows are empty
      board = board.withCellUpdated(CellModel(
        x: 0,
        y: 0,
        isOccupied: true,
        colorValue: 0xFF00E5FF,
        specialType: SpecialBlockType.lightning,
      ));
      for (int x = 1; x < 8; x++) {
        board = board.withCellUpdated(CellModel(x: x, y: 0, isOccupied: true, colorValue: 0xFF2196F3));
      }

      final clearRes = boardService.detectAndClearLines(board);
      expect(clearRes.clearedLinesCount, 1);
      expect(clearRes.lightningTriggerCells, [const Point(0, 0)]);
      // Because all occupied cells were in row 0 and got cleared, eligibleTargets is empty
      expect(clearRes.lightningTargetCells, isEmpty);
    });

    test('Holding last remaining tray piece immediately replenishes tray with 3 fresh pieces', () async {
      final repo = MockSaveRepository();
      final coordinator = GameCoordinator(
        saveRepository: repo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.initialize();

      // Put state with only 1 piece in slot 2 (slots 0 and 1 are null)
      final state = coordinator.state.copyWith(
        trayPieces: [null, null, coordinator.state.trayPieces[0]],
        heldPiece: () => null,
      );
      coordinator.setGameStateForTesting(state);

      expect(coordinator.state.trayPieces[0], isNull);
      expect(coordinator.state.trayPieces[1], isNull);
      expect(coordinator.state.trayPieces[2], isNotNull);

      // Now hold the last remaining piece
      await coordinator.holdPiece(2);

      // The held piece should now be set
      expect(coordinator.heldPiece, isNotNull);
      // AND tray must NOT be empty! It must have replenished with 3 fresh pieces!
      expect(coordinator.state.trayPieces.every((p) => p != null), isTrue);
    });

    test('UndoMove preserves highest highScore even if move is reverted', () async {
      final repo = MockSaveRepository();
      final coordinator = GameCoordinator(
        saveRepository: repo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.initialize();
      await repo.saveStreakInfo(coordinator.streakInfo.copyWith(freeUndos: 2));
      await coordinator.initialize();

      // Set initial high score to 100
      final state = coordinator.state.copyWith(score: 95, highScore: 100);
      coordinator.setGameStateForTesting(state);

      // Drag and place piece (earning at least 10 points so score >= 105, setting new highScore)
      coordinator.onDragStart(0, const Offset(100, 100));
      coordinator.onDragUpdate(const Offset(100, 100), const Rect.fromLTRB(0, 0, 320, 320));
      await coordinator.onDragEnd(const Rect.fromLTRB(0, 0, 320, 320));

      expect(coordinator.state.score, greaterThan(100));
      final recordHigh = coordinator.state.highScore;
      expect(recordHigh, greaterThan(100));

      // Revert move
      await coordinator.undoMove(isFree: true);

      // Score goes back to 95
      expect(coordinator.state.score, 95);
      // High score MUST NOT revert to 100! It must stay at the newly achieved record!
      expect(coordinator.state.highScore, recordHigh);
    });

    test('Using Hammer booster invalidates canUndo to prevent state divergence', () async {
      final repo = MockSaveRepository();
      final coordinator = GameCoordinator(
        saveRepository: repo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.initialize();
      await repo.saveStreakInfo(coordinator.streakInfo.copyWith(freeHammers: 2, freeUndos: 2));
      await coordinator.initialize();

      // Place a piece to establish an undo snapshot
      coordinator.onDragStart(0, const Offset(100, 100));
      coordinator.onDragUpdate(const Offset(100, 100), const Rect.fromLTRB(0, 0, 320, 320));
      await coordinator.onDragEnd(const Rect.fromLTRB(0, 0, 320, 320));

      expect(coordinator.canUndo, isTrue);

      // Find an occupied cell to smash
      Point<int>? occupiedPoint;
      for (int y = 0; y < coordinator.state.board.gridSize; y++) {
        for (int x = 0; x < coordinator.state.board.gridSize; x++) {
          if (coordinator.state.board.isOccupied(x, y)) {
            occupiedPoint = Point(x, y);
            break;
          }
        }
        if (occupiedPoint != null) break;
      }
      expect(occupiedPoint, isNotNull);

      // Activate Hammer and smash an occupied cell
      coordinator.toggleHammerMode();
      await coordinator.smashCell(occupiedPoint!.x, occupiedPoint.y, const Rect.fromLTRB(0, 0, 320, 320));

      // After smashing, canUndo should be cleanly invalidated
      expect(coordinator.canUndo, isFalse);
    });
  });
}
