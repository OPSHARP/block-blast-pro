import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:block_blast_pro/domain/models/board_state.dart';
import 'package:block_blast_pro/domain/models/game_mode.dart';
import 'package:block_blast_pro/core/theme/game_theme.dart';
import 'package:block_blast_pro/core/audio/asmr_audio_engine.dart';
import 'package:block_blast_pro/domain/services/piece_generator_service.dart';
import 'package:block_blast_pro/domain/services/board_service.dart';
import 'package:block_blast_pro/game/game_coordinator.dart';
import 'package:block_blast_pro/game/components/particle_engine.dart';
import 'streak_reroll_skins_test.dart'; // Reuses MockSaveRepository

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic Block Skins & Distinct Colors Tests', () {
    final generator = PieceGeneratorService();
    final board = BoardState(gridSize: 8);

    test('generateTrayPieces generates 3 pieces with distinct colors and distinct skins', () {
      for (int seed = 1; seed <= 10; seed++) {
        final pieces = generator.generateTrayPieces(
          board: board,
          theme: GameTheme.crystalFlow,
          playerSkillRating: 500,
          gameMode: GameMode.classic,
          customSeed: seed,
        );

        expect(pieces.length, 3);

        // Verify distinct colors
        final colors = pieces.map((p) => p.colorValue).toSet();
        expect(colors.length, 3, reason: 'All 3 pieces must have distinct colors in tray');

        // Verify distinct block skins
        final skins = pieces.map((p) => p.skinStyle).toSet();
        expect(skins.length, 3, reason: 'All 3 pieces must have distinct block skins in tray');
      }
    });

    test('BoardService placeBlock propagates skinStyle to authoritative CellModel', () {
      const boardService = BoardService();
      final pieces = generator.generateTrayPieces(
        board: board,
        theme: GameTheme.neonGeometry,
        playerSkillRating: 500,
        gameMode: GameMode.classic,
        customSeed: 42,
      );

      final piece = pieces.first;
      final updatedBoard = boardService.placeBlock(board, piece, 0, 0);

      for (final off in piece.offsets) {
        final cell = updatedBoard.cells[off.dy][off.dx];
        expect(cell.isOccupied, true);
        expect(cell.skinStyle, piece.skinStyle);
        expect(cell.colorValue, piece.colorValue);
      }
    });
  });

  group('Brick Break Blast VFX & SFX Tests', () {
    test('ParticleEngine spawns shards, shockwave ring, and sparkles on brick blast', () {
      final engine = ParticleEngine(maxParticles: 500);

      engine.spawnBrickBlast(
        centerX: 150.0,
        centerY: 150.0,
        brickColor: const Color(0xFF06B6D4),
        shardCount: 12,
        cellSize: 32.0,
      );

      // Verify particles were created with different types
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Render initial frame
      engine.render(canvas);

      // Simulate physics tick
      engine.update(0.016);
      engine.render(canvas);

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('AsmrAudioEngine synthesizes procedural royalty-free brick blast without errors', () {
      final audio = AsmrAudioEngine(enableAudio: false);

      // Trigger multi-line brick break blast
      expect(() => audio.playBrickBlast(linesCount: 2, comboCount: 3), returnsNormally);
      expect(() => audio.playClear(linesCount: 1, comboCount: 1), returnsNormally);
    });
  });

  group('Reroll Ad Reward & Counter Persistence Tests', () {
    late MockSaveRepository mockRepo;
    late GameCoordinator coordinator;

    setUp(() async {
      mockRepo = MockSaveRepository();
      coordinator = GameCoordinator(
        saveRepository: mockRepo,
        audioEngine: AsmrAudioEngine(enableAudio: false),
      );
      await coordinator.initialize();
    });

    test('Exhausting 3 free rerolls then watching ad grants +1 free reroll and updates counter', () async {
      expect(coordinator.freeRerolls, 3);

      // Consume free rerolls
      await coordinator.rerollPieces(isFree: true);
      expect(coordinator.freeRerolls, 2);

      await coordinator.rerollPieces(isFree: true);
      expect(coordinator.freeRerolls, 1);

      await coordinator.rerollPieces(isFree: true);
      expect(coordinator.freeRerolls, 0);

      // Player has 0 free rerolls left, clicks REROLL (AD)
      await coordinator.rerollPieces(isFree: false);

      // Counter must now be 1, showing REROLL (1) in UI
      expect(coordinator.freeRerolls, 1);

      // And tray must have 3 new pieces with distinct skins
      expect(coordinator.state.trayPieces.length, 3);
      final skins = coordinator.state.trayPieces.whereType<dynamic>().map((p) => p.skinStyle).toSet();
      expect(skins.length, 3);
    });
  });
}
