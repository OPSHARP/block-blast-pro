import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:block_blast_pro/domain/models/board_state.dart';
import 'package:block_blast_pro/domain/models/cell_model.dart';
import 'package:block_blast_pro/domain/models/block_model.dart';
import 'package:block_blast_pro/domain/models/special_block_type.dart';
import 'package:block_blast_pro/domain/models/block_skin_style.dart';
import 'package:block_blast_pro/domain/models/block_weight.dart';
import 'package:block_blast_pro/domain/models/game_mode.dart';
import 'package:block_blast_pro/domain/models/game_state.dart';
import 'package:block_blast_pro/domain/models/player_skill_profile.dart';
import 'package:block_blast_pro/domain/models/streak_info.dart';
import 'package:block_blast_pro/domain/models/achievement.dart';
import 'package:block_blast_pro/domain/services/board_service.dart';
import 'package:block_blast_pro/domain/services/streak_service.dart';
import 'package:block_blast_pro/core/audio/asmr_audio_engine.dart';
import 'package:block_blast_pro/game/game_coordinator.dart';
import 'package:block_blast_pro/data/repositories/local_save_repository.dart';

class MockSaveRepository implements LocalSaveRepository {
  StreakInfo streakInfo = const StreakInfo();
  dynamic savedState;
  List<String> unlockedThemes = ['crystal_flow'];
  List<Achievement> achievements = [];

  @override
  Future<void> saveStreakInfo(StreakInfo info) async => streakInfo = info;

  @override
  Future<StreakInfo> loadStreakInfo() async => streakInfo;

  @override
  Future<void> saveGameState(dynamic state) async => savedState = state;

  @override
  Future<void> saveUnlockedThemes(List<String> themes) async => unlockedThemes = themes;

  @override
  Future<List<String>> loadUnlockedThemes() async => unlockedThemes;

  @override
  Future<void> saveAchievements(List<Achievement> achs) async => achievements = achs;

  @override
  Future<List<Achievement>> loadAchievements() async => achievements;

  @override
  Future<void> saveHighScore(int score) async {}

  @override
  Future<int> loadHighScore() async => 0;

  @override
  Future<void> savePlayerProfile(PlayerSkillProfile profile) async {}

  @override
  Future<PlayerSkillProfile> loadPlayerProfile() async => const PlayerSkillProfile();

  @override
  Future<Map<String, dynamic>> loadSettings() async => {};

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {}

  @override
  Future<void> recordGameCompletion({
    required int finalScore,
    required int linesCleared,
    required int maxCombo,
    required int movesCount,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Sledgehammer Tool & Ad Refill Tests', () {
    test('Default StreakInfo includes banked free hammers', () {
      const info = StreakInfo();
      expect(info.freeHammers, 2);
    });

    test('smashCell clears single target cell safely on board', () {
      const service = BoardService();
      var board = BoardState(gridSize: 8);
      board = board.withCellUpdated(
        const CellModel(x: 3, y: 3, isOccupied: true, colorValue: 0xFF00E5FF),
      );
      expect(board.cells[3][3].isOccupied, isTrue);

      final smashedBoard = service.smashCell(board, 3, 3);
      expect(smashedBoard.cells[3][3].isOccupied, isFalse);
    });

    test('GameCoordinator hammer flow and rewarded ad refill', () async {
      final repo = MockSaveRepository();
      final coordinator = GameCoordinator(
        saveRepository: repo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.startNewGame();

      expect(coordinator.freeHammers, 2);
      expect(coordinator.isHammerModeActive, isFalse);

      coordinator.toggleHammerMode();
      expect(coordinator.isHammerModeActive, isTrue);

      // Populate cell (2, 2)
      final occupiedCell = const CellModel(x: 2, y: 2, isOccupied: true, colorValue: 0xFFFF0000);
      coordinator.setGameStateForTesting(
        coordinator.state.copyWith(
          board: coordinator.state.board.withCellUpdated(occupiedCell),
          isHammerModeActive: true,
        ),
      );

      // Smash cell
      await coordinator.smashCell(2, 2, const Rect.fromLTWH(0, 0, 320, 320));
      expect(coordinator.state.board.cells[2][2].isOccupied, isFalse);
      expect(coordinator.freeHammers, 1);
      expect(coordinator.isHammerModeActive, isFalse);

      // Watch ad to grant +1 hammer
      await coordinator.grantHammerViaAd();
      expect(coordinator.freeHammers, 2);
      expect(coordinator.isHammerModeActive, isTrue);
    });
  });

  group('Hold / Pocket Stash Slot Tests', () {
    test('holdPiece stashes piece and swaps correctly', () async {
      final repo = MockSaveRepository();
      final coordinator = GameCoordinator(
        saveRepository: repo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.startNewGame();

      final firstPiece = coordinator.state.trayPieces[0]!;
      expect(coordinator.heldPiece, isNull);
      expect(coordinator.canHoldThisTurn, isTrue);

      // Stash piece 0
      await coordinator.holdPiece(0);
      expect(coordinator.heldPiece?.id, firstPiece.id);
      expect(coordinator.state.trayPieces[0], isNull);
      expect(coordinator.canHoldThisTurn, isFalse);

      // Emergency hold via ad allows immediate swap
      await coordinator.grantEmergencyHoldViaAd(1);
      expect(coordinator.canHoldThisTurn, isFalse);
    });
  });

  group('TNT Bomb & Laser Special Block Tests', () {
    test('TNT Bomb detonates 3x3 blast radius on placement', () {
      const service = BoardService();
      var board = BoardState(gridSize: 8);

      // Fill a 5x5 region around (3, 3)
      for (int y = 1; y <= 5; y++) {
        for (int x = 1; x <= 5; x++) {
          board = board.withCellUpdated(
            CellModel(x: x, y: y, isOccupied: true, colorValue: 0xFF22C55E),
          );
        }
      }

      final bombBlock = const BlockModel(
        id: 'tnt_1',
        shapeName: 'bomb',
        width: 1,
        height: 1,
        offsets: [BlockOffset(0, 0)],
        colorValue: 0xFFFF5722,
        weightClass: BlockWeightClass.heavy,
        specialType: SpecialBlockType.bomb,
        skinStyle: BlockSkinStyle.gem,
      );

      final newBoard = service.placeBlock(board, bombBlock, 3, 3);

      // 3x3 area [2..4, 2..4] should now be completely cleared
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          expect(newBoard.cells[3 + dy][3 + dx].isOccupied, isFalse);
        }
      }
      // Cells outside 3x3 should remain occupied
      expect(newBoard.cells[1][1].isOccupied, isTrue);
    });

    test('Laser block clears full horizontal row and vertical column', () {
      const service = BoardService();
      var board = BoardState(gridSize: 8);

      // Fill entire board
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          board = board.withCellUpdated(
            CellModel(x: x, y: y, isOccupied: true, colorValue: 0xFF22C55E),
          );
        }
      }

      final laserBlock = const BlockModel(
        id: 'laser_1',
        shapeName: 'laser',
        width: 1,
        height: 1,
        offsets: [BlockOffset(0, 0)],
        colorValue: 0xFF00E5FF,
        weightClass: BlockWeightClass.heavy,
        specialType: SpecialBlockType.laser,
        skinStyle: BlockSkinStyle.neon,
      );

      final newBoard = service.placeBlock(board, laserBlock, 4, 4);

      // Row 4 should be cleared
      for (int x = 0; x < 8; x++) {
        expect(newBoard.cells[4][x].isOccupied, isFalse);
      }
      // Column 4 should be cleared
      for (int y = 0; y < 8; y++) {
        expect(newBoard.cells[y][4].isOccupied, isFalse);
      }
    });

    test('grantTntBlockViaAd armors tray with explosive TNT piece', () async {
      final repo = MockSaveRepository();
      final coordinator = GameCoordinator(
        saveRepository: repo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.startNewGame();

      await coordinator.grantTntBlockViaAd();
      expect(coordinator.state.trayPieces[0]?.specialType, SpecialBlockType.bomb);
      expect(coordinator.state.trayPieces[0]?.colorValue, 0xFFFF5722);
    });

    test('TNT Bomb can be placed on occupied cells without rejection', () {
      const service = BoardService();
      var board = BoardState(gridSize: 8);
      board = board.withCellUpdated(
        const CellModel(x: 3, y: 3, isOccupied: true, colorValue: 0xFF00E5FF),
      );

      final tntBlock = BlockModel(
        id: 'tnt_test',
        shapeName: 'tnt_bomb',
        width: 1,
        height: 1,
        offsets: const [BlockOffset(0, 0)],
        colorValue: 0xFFFF5722,
        weightClass: BlockWeightClass.heavy,
        specialType: SpecialBlockType.bomb,
        skinStyle: BlockSkinStyle.gem,
      );

      // Normal block cannot be placed on occupied cell
      final normalBlock = BlockModel(
        id: 'normal_test',
        shapeName: 'dot',
        width: 1,
        height: 1,
        offsets: const [BlockOffset(0, 0)],
        colorValue: 0xFFFFFFFF,
        weightClass: BlockWeightClass.normal,
        specialType: SpecialBlockType.none,
        skinStyle: BlockSkinStyle.gem,
      );
      expect(service.canPlaceBlock(board, normalBlock, 3, 3), isFalse);

      // TNT Bomb CAN be placed on occupied cell
      expect(service.canPlaceBlock(board, tntBlock, 3, 3), isTrue);
    });

    test('BoardService detonateArea clears 3x3 surrounding cells', () {
      const service = BoardService();
      var board = BoardState(gridSize: 8);
      // Fill 3x3 cells from (1,1) to (3,3)
      for (int y = 1; y <= 3; y++) {
        for (int x = 1; x <= 3; x++) {
          board = board.withCellUpdated(
            CellModel(x: x, y: y, isOccupied: true, colorValue: 0xFF38BDF8),
          );
        }
      }

      final result = service.detonateArea(board, 2, 2, radius: 1);
      expect(result.destroyedCount, 9);
      expect(result.clearedCells.length, 9);
      for (int y = 1; y <= 3; y++) {
        for (int x = 1; x <= 3; x++) {
          expect(result.newBoard.cells[y][x].isOccupied, isFalse);
        }
      }
    });

    test('GameCoordinator TNT detonator tool flow and ad refill', () async {
      final repo = MockSaveRepository();
      final coordinator = GameCoordinator(
        saveRepository: repo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.startNewGame();

      expect(coordinator.freeTnts, 1);
      expect(coordinator.isTntModeActive, isFalse);

      coordinator.toggleTntMode();
      expect(coordinator.isTntModeActive, isTrue);
      expect(coordinator.isHammerModeActive, isFalse);

      // Fill a 3x3 cluster on the board
      var board = coordinator.state.board;
      for (int y = 2; y <= 4; y++) {
        for (int x = 2; x <= 4; x++) {
          board = board.withCellUpdated(
            CellModel(x: x, y: y, isOccupied: true, colorValue: 0xFFEC4899),
          );
        }
      }
      coordinator.setGameStateForTesting(
        coordinator.state.copyWith(board: board, isTntModeActive: true),
      );

      final prevScore = coordinator.state.score;
      // Detonate at center (3, 3)
      await coordinator.detonateTnt(3, 3, const Rect.fromLTWH(0, 0, 320, 320));
      expect(coordinator.isTntModeActive, isFalse);
      expect(coordinator.freeTnts, 0);
      expect(coordinator.state.score, greaterThan(prevScore));
      for (int y = 2; y <= 4; y++) {
        for (int x = 2; x <= 4; x++) {
          expect(coordinator.state.board.cells[y][x].isOccupied, isFalse);
        }
      }

      // Watch ad to grant +1 TNT
      await coordinator.grantTntViaAd();
      expect(coordinator.freeTnts, 1);
      expect(coordinator.isTntModeActive, isTrue);
    });
  });

  group('Fever Overdrive & Second Chance Revive Tests', () {
    test('Fever mode activates at 5+ combo count', () {
      final board = BoardState(gridSize: 8);
      final normalState = GameState(
        board: board,
        trayPieces: const [null, null, null],
        comboCount: 4,
      );
      expect(normalState.isFeverMode, isFalse);

      final feverState = normalState.copyWith(comboCount: 5);
      expect(feverState.isFeverMode, isTrue);
    });

    test('Revive game clears rows, refills tray, clears game over, and resets hammer/hold', () async {
      final repo = MockSaveRepository();
      final coordinator = GameCoordinator(
        saveRepository: repo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.startNewGame();

      // Trigger game over with hammer mode active
      coordinator.setGameStateForTesting(
        coordinator.state.copyWith(
          isGameOver: true,
          isHammerModeActive: true,
        ),
      );
      expect(coordinator.state.isGameOver, isTrue);
      expect(coordinator.isHammerModeActive, isTrue);

      await coordinator.reviveGame();
      expect(coordinator.state.isGameOver, isFalse);
      expect(coordinator.isHammerModeActive, isFalse);
      expect(coordinator.canHoldThisTurn, isTrue);
      expect(coordinator.state.trayPieces.any((p) => p != null), isTrue);
    });

    test('StreakService Day 4 schedule includes bonus hammer', () {
      final day4Reward = StreakService.getRewardForDay(4);
      expect(day4Reward.bonusHammers, 1);
      expect(day4Reward.bonusRerolls, 2);

      final day7Reward = StreakService.getRewardForDay(7);
      expect(day7Reward.bonusHammers, 2);
    });
  });

  group('Rotate Booster & 90-degree Geometry Tests', () {
    test('BlockModel rotatedClockwise transforms line-3 from vertical to horizontal', () {
      final verticalLine = BlockModel(
        id: 'v_line',
        shapeName: 'line_3',
        width: 1,
        height: 3,
        offsets: const [BlockOffset(0, 0), BlockOffset(0, 1), BlockOffset(0, 2)],
        colorValue: 0xFF00E5FF,
      );

      final rotated = verticalLine.rotatedClockwise();
      expect(rotated.width, 3);
      expect(rotated.height, 1);
      expect(rotated.offsets.contains(const BlockOffset(0, 0)), isTrue);
      expect(rotated.offsets.contains(const BlockOffset(1, 0)), isTrue);
      expect(rotated.offsets.contains(const BlockOffset(2, 0)), isTrue);
    });

    test('rotatePiece in tray decrements freeRotates and updates tray', () async {
      final repo = MockSaveRepository();
      final coordinator = GameCoordinator(
        saveRepository: repo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.startNewGame();

      final initialRotates = coordinator.freeRotates;
      final targetPiece = coordinator.state.trayPieces.firstWhere((p) => p != null)!;
      final targetIdx = coordinator.state.trayPieces.indexOf(targetPiece);

      final success = await coordinator.rotatePiece(targetIdx, isFree: true);
      expect(success, isTrue);
      expect(coordinator.freeRotates, initialRotates - 1);
      expect(coordinator.state.trayPieces[targetIdx]!.width, targetPiece.height);
      expect(coordinator.state.trayPieces[targetIdx]!.height, targetPiece.width);
    });
  });

  group('1-Step Undo Move Tests', () {
    test('Placing a piece enables canUndo and undoMove restores board & tray', () async {
      final repo = MockSaveRepository();
      final coordinator = GameCoordinator(
        saveRepository: repo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.startNewGame();
      expect(coordinator.canUndo, isFalse);

      final singleBlock = BlockModel(
        id: 'dot_1',
        shapeName: 'dot',
        width: 1,
        height: 1,
        offsets: const [BlockOffset(0, 0)],
        colorValue: 0xFFFF5722,
      );

      // Force slot 0 to single block
      coordinator.setGameStateForTesting(
        coordinator.state.copyWith(
          trayPieces: [singleBlock, null, null],
        ),
      );

      final initialFreeUndos = coordinator.freeUndos;

      // Drag and place dot at (0, 0)
      coordinator.onDragStart(0, const Offset(100, 500));
      coordinator.onDragUpdate(const Offset(20, 20), const Rect.fromLTWH(0, 0, 320, 320));
      await coordinator.onDragEnd(const Rect.fromLTWH(0, 0, 320, 320));

      expect(coordinator.state.board.cells[0][0].isOccupied, isTrue);
      expect(coordinator.canUndo, isTrue);

      // Undo move
      final undone = await coordinator.undoMove(isFree: true);
      expect(undone, isTrue);
      expect(coordinator.state.board.cells[0][0].isOccupied, isFalse);
      expect(coordinator.state.trayPieces[0], isNotNull);
      expect(coordinator.freeUndos, initialFreeUndos - 1);
      expect(coordinator.canUndo, isFalse);
    });
  });

  group('Special Block: 2-Hit Ice Mechanics & Color Magnet Tests', () {
    test('Ice block cracks on first clear (HP 2 -> 1) and destroys on second clear', () {
      const service = BoardService();
      var board = BoardState(gridSize: 8);

      // Fill row 0 with normal blocks except (0, 0) which is an Ice block (HP: 2)
      board = board.withCellUpdated(
        const CellModel(
          x: 0,
          y: 0,
          isOccupied: true,
          colorValue: 0xFF80D8FF,
          specialType: SpecialBlockType.ice,
          hitPoints: 2,
        ),
      );
      for (int x = 1; x < 8; x++) {
        board = board.withCellUpdated(
          CellModel(x: x, y: 0, isOccupied: true, colorValue: 0xFF00E5FF),
        );
      }

      // First clear
      final firstClear = service.detectAndClearLines(board);
      expect(firstClear.clearedLinesCount, 1);
      // Ice block is cracked, not cleared
      expect(firstClear.crackedIceCells, contains(const Point(0, 0)));
      expect(firstClear.newBoard.cells[0][0].isOccupied, isTrue);
      expect(firstClear.newBoard.cells[0][0].hitPoints, 1);
      expect(firstClear.newBoard.cells[0][0].isCracked, isTrue);

      // Fill remaining cells of row 0 again to trigger second clear
      var board2 = firstClear.newBoard;
      for (int x = 1; x < 8; x++) {
        board2 = board2.withCellUpdated(
          CellModel(x: x, y: 0, isOccupied: true, colorValue: 0xFF00E5FF),
        );
      }

      // Second clear destroys the cracked Ice block
      final secondClear = service.detectAndClearLines(board2);
      expect(secondClear.clearedLinesCount, 1);
      expect(secondClear.newBoard.cells[0][0].isOccupied, isFalse);
    });

    test('dissolveColor clears all cells of target color across board', () {
      const service = BoardService();
      var board = BoardState(gridSize: 8);

      // Place 4 cells of color 0xFFE040FB (purple) and 2 of color 0xFF00E5FF (cyan)
      board = board.withCellUpdated(const CellModel(x: 1, y: 1, isOccupied: true, colorValue: 0xFFE040FB));
      board = board.withCellUpdated(const CellModel(x: 2, y: 1, isOccupied: true, colorValue: 0xFFE040FB));
      board = board.withCellUpdated(const CellModel(x: 4, y: 3, isOccupied: true, colorValue: 0xFFE040FB));
      board = board.withCellUpdated(const CellModel(x: 5, y: 5, isOccupied: true, colorValue: 0xFF00E5FF));

      final res = service.dissolveColor(board, 0xFFE040FB);
      expect(res.destroyedCount, 3);
      expect(res.newBoard.cells[1][1].isOccupied, isFalse);
      expect(res.newBoard.cells[2][1].isOccupied, isFalse);
      expect(res.newBoard.cells[4][3].isOccupied, isFalse);
      // Cyan block remains
      expect(res.newBoard.cells[5][5].isOccupied, isTrue);
    });
  });

  group('Blitz Mode 60s Time Attack Tests', () {
    test('Blitz mode starts with 60 seconds time attack', () async {
      final repo = MockSaveRepository();
      final coordinator = GameCoordinator(
        saveRepository: repo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.startNewGame(mode: GameMode.blitz);

      expect(coordinator.state.gameMode, GameMode.blitz);
      expect(coordinator.state.blitzTimeRemaining, 60.0);
      coordinator.dispose();
    });
  });
}
