// Smart Piece Generator with board evaluation and anti-frustration logic according to PRD Sections 19-25

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/board_state.dart';
import '../models/block_model.dart';
import '../models/block_catalog.dart';
import '../models/block_weight.dart';
import '../models/special_block_type.dart';
import '../models/block_skin_style.dart';
import '../models/game_mode.dart';
import '../../core/theme/game_theme.dart';
import 'board_service.dart';

class PieceGeneratorService {
  final Random _random;
  final BoardService _boardService;

  PieceGeneratorService({
    Random? random,
    BoardService? boardService,
  })  : _random = random ?? Random(),
        _boardService = boardService ?? const BoardService();

  // Generate 3 candidate pieces for the player tray with guaranteed distinct skins & colors
  List<BlockModel> generateTrayPieces({
    required BoardState board,
    required GameTheme theme,
    required int playerSkillRating, // 0 - 1000
    required GameMode gameMode,
    int? customSeed,
  }) {
    final rng = customSeed != null ? Random(customSeed) : _random;
    final pieces = <BlockModel>[];
    final density = board.density;

    // Guarantee distinct, contrasting colors for all 3 pieces
    final availableColors = List<Color>.from(theme.blockPalette);
    availableColors.shuffle(rng);

    // Guarantee distinct block skins for all pieces
    final availableSkins = List<BlockSkinStyle>.from(BlockSkinStyle.values);
    availableSkins.shuffle(rng);

    for (int i = 0; i < 3; i++) {
      // Pick shape according to density and skill
      final shape = _selectShape(
        density: density,
        skillRating: playerSkillRating,
        rng: rng,
        isFirstPiece: i == 0,
        board: board,
      );

      // Weight class selection
      final weight = _selectWeightClass(
        gameMode: gameMode,
        skillRating: playerSkillRating,
        rng: rng,
      );

      // Special block selection
      final specialType = _selectSpecialType(
        gameMode: gameMode,
        skillRating: playerSkillRating,
        rng: rng,
      );

      // Pick distinct color from shuffled palette
      final color = availableColors[i % availableColors.length];

      // Pick distinct block skin style
      final skinStyle = availableSkins[i % availableSkins.length];

      final block = BlockCatalog.createBlock(
        id: 'piece_${DateTime.now().microsecondsSinceEpoch}_$i',
        shape: shape,
        colorValue: color.toARGB32(),
        weightClass: weight,
        specialType: specialType,
        skinStyle: skinStyle,
      );

      pieces.add(block);
    }

    // Anti-frustration safeguard: Ensure at least one piece in the set can be legally placed
    if (!_boardService.hasValidMovesRemaining(board, pieces) && board.occupiedCount < (board.gridSize * board.gridSize)) {
      // Replace last piece with a shape guaranteed to fit, e.g. Single or Domino
      final fittingShape = _findFittingShape(board, rng);
      final color = availableColors[2 % availableColors.length];
      final skinStyle = availableSkins[2 % availableSkins.length];
      pieces[2] = BlockCatalog.createBlock(
        id: 'piece_safeguard_${DateTime.now().microsecondsSinceEpoch}',
        shape: fittingShape,
        colorValue: color.toARGB32(),
        weightClass: BlockWeightClass.light,
        specialType: SpecialBlockType.none,
        skinStyle: skinStyle,
      );
    }

    return pieces;
  }

  BlockShapeDefinition _selectShape({
    required double density,
    required int skillRating,
    required Random rng,
    required bool isFirstPiece,
    required BoardState board,
  }) {
    // High board density (> 60% full): heavily favor small and recovery shapes
    if (density > 0.60) {
      final recoveryShapes = [
        BlockCatalog.single,
        BlockCatalog.dominoH,
        BlockCatalog.dominoV,
        BlockCatalog.triH,
        BlockCatalog.triV,
        BlockCatalog.cornerTopLeft,
        BlockCatalog.cornerBottomRight,
      ];
      return recoveryShapes[rng.nextInt(recoveryShapes.length)];
    }

    // Beginner skill rating (< 350)
    if (skillRating < 350) {
      final beginnerShapes = [
        BlockCatalog.single,
        BlockCatalog.dominoH,
        BlockCatalog.dominoV,
        BlockCatalog.triH,
        BlockCatalog.triV,
        BlockCatalog.square2x2,
        BlockCatalog.cornerTopLeft,
        BlockCatalog.cornerTopRight,
        BlockCatalog.lNormal,
      ];
      return beginnerShapes[rng.nextInt(beginnerShapes.length)];
    }

    // Advanced / Expert (>= 700)
    if (skillRating >= 700) {
      // Full catalog including large shapes
      return BlockCatalog.standardShapes[rng.nextInt(BlockCatalog.standardShapes.length)];
    }

    // Standard Casual catalog
    final standardPool = [
      BlockCatalog.single,
      BlockCatalog.dominoH,
      BlockCatalog.dominoV,
      BlockCatalog.triH,
      BlockCatalog.triV,
      BlockCatalog.quadH,
      BlockCatalog.quadV,
      BlockCatalog.square2x2,
      BlockCatalog.cornerTopLeft,
      BlockCatalog.cornerTopRight,
      BlockCatalog.cornerBottomLeft,
      BlockCatalog.cornerBottomRight,
      BlockCatalog.lNormal,
      BlockCatalog.lInverted,
      BlockCatalog.lHorizontal,
      BlockCatalog.tDown,
      BlockCatalog.tUp,
      BlockCatalog.zShape,
      BlockCatalog.sShape,
      BlockCatalog.plus,
    ];
    return standardPool[rng.nextInt(standardPool.length)];
  }

  BlockWeightClass _selectWeightClass({
    required GameMode gameMode,
    required int skillRating,
    required Random rng,
  }) {
    if (gameMode == GameMode.blitz) {
      return rng.nextDouble() < 0.5 ? BlockWeightClass.light : BlockWeightClass.normal;
    }

    if (gameMode == GameMode.heavyPhysics) {
      final roll = rng.nextDouble();
      if (roll < 0.35) return BlockWeightClass.heavy;
      if (roll < 0.50) return BlockWeightClass.ultra;
      if (roll < 0.75) return BlockWeightClass.normal;
      return BlockWeightClass.light;
    }

    // Standard mode: mostly Normal, occasional Light and Heavy
    final roll = rng.nextDouble();
    if (skillRating > 600 && roll < 0.15) {
      return BlockWeightClass.heavy;
    }
    if (roll < 0.20) {
      return BlockWeightClass.light;
    }
    return BlockWeightClass.normal;
  }

  SpecialBlockType _selectSpecialType({
    required GameMode gameMode,
    required int skillRating,
    required Random rng,
  }) {
    // Special blocks appear ~14% of the time, 25% in heavy physics, 20% in blitz
    final threshold = gameMode == GameMode.heavyPhysics
        ? 0.25
        : (gameMode == GameMode.blitz ? 0.20 : 0.14);
    if (rng.nextDouble() > threshold) {
      return SpecialBlockType.none;
    }

    final pool = [
      SpecialBlockType.anchor,
      SpecialBlockType.voidBlock,
      SpecialBlockType.bloom,
      SpecialBlockType.pulse,
      SpecialBlockType.gravity,
      SpecialBlockType.magnet,
      SpecialBlockType.rainbow,
      SpecialBlockType.lightning,
      SpecialBlockType.ice,
      SpecialBlockType.coin,
      SpecialBlockType.timeBomb,
      SpecialBlockType.geode,
      SpecialBlockType.portal,
      SpecialBlockType.morph,
    ];
    return pool[rng.nextInt(pool.length)];
  }

  BlockShapeDefinition _findFittingShape(BoardState board, Random rng) {
    final simpleCandidates = [
      BlockCatalog.single,
      BlockCatalog.dominoH,
      BlockCatalog.dominoV,
      BlockCatalog.cornerTopLeft,
    ];

    for (final shape in simpleCandidates) {
      final dummy = BlockCatalog.createBlock(
        id: 'test',
        shape: shape,
        colorValue: 0xFFFFFFFF,
      );
      for (int y = 0; y <= board.gridSize - shape.height; y++) {
        for (int x = 0; x <= board.gridSize - shape.width; x++) {
          if (_boardService.canPlaceBlock(board, dummy, x, y)) {
            return shape;
          }
        }
      }
    }
    return BlockCatalog.single;
  }
}
