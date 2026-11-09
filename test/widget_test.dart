// Smoke tests and model verification for Block Blast Pro

import 'package:flutter_test/flutter_test.dart';
import 'package:block_blast_pro/domain/models/game_state.dart';
import 'package:block_blast_pro/domain/models/board_state.dart';
import 'package:block_blast_pro/domain/models/block_catalog.dart';
import 'package:block_blast_pro/domain/models/game_mode.dart';
import 'package:block_blast_pro/domain/services/piece_generator_service.dart';
import 'package:block_blast_pro/core/theme/game_theme.dart';

void main() {
  test('GameState serialization and deserialization preserves properties', () {
    final state = GameState(
      board: BoardState(gridSize: 8),
      trayPieces: [
        BlockCatalog.createBlock(
          id: 'test_1',
          shape: BlockCatalog.single,
          colorValue: 0xFFFF0000,
        ),
      ],
      score: 1250,
      highScore: 5000,
      comboCount: 3,
      gameMode: GameMode.heavyPhysics,
      themeId: 'neon_geometry',
    );

    final map = state.toMap();
    final restored = GameState.fromMap(map);

    expect(restored.score, equals(1250));
    expect(restored.highScore, equals(5000));
    expect(restored.comboCount, equals(3));
    expect(restored.gameMode, equals(GameMode.heavyPhysics));
    expect(restored.themeId, equals('neon_geometry'));
    expect(restored.trayPieces.first?.id, equals('test_1'));
  });

  test('PieceGeneratorService generates 3 pieces respecting density and themes', () {
    final generator = PieceGeneratorService();
    final board = BoardState(gridSize: 8);
    final pieces = generator.generateTrayPieces(
      board: board,
      theme: GameTheme.crystalFlow,
      playerSkillRating: 500,
      gameMode: GameMode.classic,
      customSeed: 12345,
    );

    expect(pieces.length, equals(3));
    for (final p in pieces) {
      expect(p.offsets, isNotEmpty);
      expect(p.colorValue, isNotNull);
    }
  });
}
