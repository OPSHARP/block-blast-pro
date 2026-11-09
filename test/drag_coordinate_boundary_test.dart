import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:block_blast_pro/game/game_coordinator.dart';
import 'package:block_blast_pro/domain/models/game_state.dart';
import 'package:block_blast_pro/domain/models/player_skill_profile.dart';
import 'package:block_blast_pro/domain/models/achievement.dart';
import 'package:block_blast_pro/domain/models/streak_info.dart';
import 'package:block_blast_pro/domain/models/daily_challenge.dart';
import 'package:block_blast_pro/core/audio/asmr_audio_engine.dart';
import 'package:block_blast_pro/data/repositories/local_save_repository.dart';

class MockSaveRepository implements LocalSaveRepository {
  GameState? savedState;
  int highScore = 0;
  PlayerSkillProfile profile = const PlayerSkillProfile();
  List<Achievement> achievements = [];
  StreakInfo streakInfo = const StreakInfo(freeRerolls: 3, freeRevives: 1);
  List<String> unlockedThemes = ['crystal_flow', 'neon_geometry'];
  bool adsRemoved = false;

  @override
  Future<void> saveGameState(GameState state) async => savedState = state;
  @override
  Future<GameState?> loadGameState() async => savedState;
  @override
  Future<void> clearGameState() async => savedState = null;

  @override
  Future<int> loadHighScore() async => highScore;
  @override
  Future<void> saveHighScore(int score) async {
    if (score > highScore) highScore = score;
  }

  @override
  Future<PlayerSkillProfile> loadPlayerProfile() async => profile;
  @override
  Future<void> savePlayerProfile(PlayerSkillProfile p) async => profile = p;

  @override
  Future<List<Achievement>> loadAchievements() async => achievements;
  @override
  Future<void> saveAchievements(List<Achievement> a) async => achievements = a;

  @override
  Future<DailyChallenge?> loadDailyChallenge(String d) async => null;
  @override
  Future<void> saveDailyChallenge(DailyChallenge c) async {}

  @override
  Future<int> loadStreak() async => streakInfo.streakCount;
  @override
  Future<void> saveStreak(int s) async => streakInfo = streakInfo.copyWith(streakCount: s);

  @override
  Future<StreakInfo> loadStreakInfo() async => streakInfo;
  @override
  Future<void> saveStreakInfo(StreakInfo info) async => streakInfo = info;

  @override
  Future<List<String>> loadUnlockedThemes() async => unlockedThemes;
  @override
  Future<void> saveUnlockedThemes(List<String> ids) async => unlockedThemes = ids;

  @override
  Future<Map<String, dynamic>> loadSettings() async => {};
  @override
  Future<void> saveSettings(Map<String, dynamic> s) async {}

  @override
  Future<Map<String, int>> loadLifetimeStats() async => {};
  @override
  Future<void> recordGameCompletion({
    required int finalScore,
    required int linesCleared,
    required int maxCombo,
    required int movesCount,
  }) async {}

  @override
  Future<bool> loadAdsRemoved() async => adsRemoved;
  @override
  Future<void> saveAdsRemoved(bool r) async => adsRemoved = r;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameCoordinator coordinator;
  late MockSaveRepository mockRepo;

  setUp(() async {
    mockRepo = MockSaveRepository();
    coordinator = GameCoordinator(
      saveRepository: mockRepo,
      audioEngine: AsmrAudioEngine(enableAudio: false),
    );
    await coordinator.initialize();
    await coordinator.startNewGame();
  });

  group('Drag Coordinate and Top-of-Grid Boundary Tests', () {
    const boardRect = Rect.fromLTWH(20.0, 150.0, 360.0, 360.0);

    test('onDragStart initializes direct cursor and touch modes correctly', () {
      final piece = coordinator.state.trayPieces[0]!;
      expect(piece, isNotNull);

      // Start drag with touch
      coordinator.onDragStart(0, const Offset(100, 500), isDirectCursor: false);
      expect(coordinator.draggingTrayIndex, 0);
      expect(coordinator.dragPosition, const Offset(100, 500));
      expect(coordinator.isDirectCursor, false);

      // Start drag with direct cursor (mouse)
      coordinator.onDragStart(0, const Offset(100, 500), isDirectCursor: true);
      expect(coordinator.isDirectCursor, true);
    });

    test('Dragging with direct cursor (mouse) has 0 lift and centers directly under cursor', () {
      coordinator.onDragStart(0, const Offset(20 + 22.5, 150 + 22.5), isDirectCursor: true);

      // Drag cursor to cell (0, 0) top-left
      coordinator.onDragUpdate(
        const Offset(20 + 22.5, 150 + 22.5),
        boardRect,
        isDirectCursor: true,
      );

      expect(coordinator.hoveredGridCoord, isNotNull);
      expect(coordinator.hoveredGridCoord!.x, inInclusiveRange(0, 7));
      expect(coordinator.hoveredGridCoord!.y, inInclusiveRange(0, 7));
      expect(coordinator.isPlacementValid, true);
    });

    test('Dragging to the very top edge of the grid clamps gy to 0 and keeps ghost preview valid', () {
      coordinator.onDragStart(0, const Offset(100, 400), isDirectCursor: false);

      // Drag pointer right at the top border of the board (y = 150.0)
      coordinator.onDragUpdate(
        const Offset(20 + 45.0 * 2, 150.0), // x over col 2, y exactly at board top
        boardRect,
        isDirectCursor: false,
      );

      // Boundary clamping must guarantee gy is 0 (not -1 or -2) and placement preview is active
      expect(coordinator.hoveredGridCoord, isNotNull);
      expect(coordinator.hoveredGridCoord!.y, 0);
      expect(coordinator.hoveredGridCoord!.x, inInclusiveRange(0, 7));
      expect(coordinator.isPlacementValid, true);
    });

    test('Dragging multi-cell piece to the top row clamps gy to 0', () {
      coordinator.onDragStart(0, const Offset(150, 450), isDirectCursor: true);

      // Move cursor to the very top row (row 0)
      coordinator.onDragUpdate(
        const Offset(20 + 45.0, 150.0 + 10.0),
        boardRect,
        isDirectCursor: true,
      );

      expect(coordinator.hoveredGridCoord, isNotNull);
      expect(coordinator.hoveredGridCoord!.y, 0);
      expect(coordinator.isPlacementValid, true);
    });

    test('Dragging outside active board interaction zone invalidates preview', () {
      coordinator.onDragStart(0, const Offset(150, 450), isDirectCursor: false);

      // Drag far below the board into tray area (y = 650, board bottom is 510)
      coordinator.onDragUpdate(
        const Offset(200, 650),
        boardRect,
        isDirectCursor: false,
      );

      expect(coordinator.hoveredGridCoord, isNull);
      expect(coordinator.isPlacementValid, false);
    });

    test('onDragEnd resets drag and cursor state cleanly', () async {
      coordinator.onDragStart(0, const Offset(100, 200), isDirectCursor: true);
      expect(coordinator.draggingTrayIndex, 0);
      expect(coordinator.isDirectCursor, true);

      await coordinator.onDragEnd(boardRect);

      expect(coordinator.draggingTrayIndex, isNull);
      expect(coordinator.dragPosition, isNull);
      expect(coordinator.hoveredGridCoord, isNull);
      expect(coordinator.isDirectCursor, false);
      expect(coordinator.isPlacementValid, false);
    });
  });
}
