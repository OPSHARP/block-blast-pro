// Standard Polyomino catalog for Block Blast Pro according to PRD Sections 16 & 235-251

import 'block_model.dart';
import 'block_weight.dart';
import 'special_block_type.dart';
import 'block_skin_style.dart';

class BlockShapeDefinition {
  final String name;
  final List<BlockOffset> offsets;
  final int width;
  final int height;

  const BlockShapeDefinition({
    required this.name,
    required this.offsets,
    required this.width,
    required this.height,
  });
}

class BlockCatalog {
  // 1x1 Single
  static const single = BlockShapeDefinition(
    name: 'Single',
    offsets: [BlockOffset(0, 0)],
    width: 1,
    height: 1,
  );

  // 2-Line Domino
  static const dominoH = BlockShapeDefinition(
    name: 'Domino H',
    offsets: [BlockOffset(0, 0), BlockOffset(1, 0)],
    width: 2,
    height: 1,
  );
  static const dominoV = BlockShapeDefinition(
    name: 'Domino V',
    offsets: [BlockOffset(0, 0), BlockOffset(0, 1)],
    width: 1,
    height: 2,
  );

  // 3-Line
  static const triH = BlockShapeDefinition(
    name: 'Tromino H',
    offsets: [BlockOffset(0, 0), BlockOffset(1, 0), BlockOffset(2, 0)],
    width: 3,
    height: 1,
  );
  static const triV = BlockShapeDefinition(
    name: 'Tromino V',
    offsets: [BlockOffset(0, 0), BlockOffset(0, 1), BlockOffset(0, 2)],
    width: 1,
    height: 3,
  );

  // 4-Line
  static const quadH = BlockShapeDefinition(
    name: 'Tetramino H',
    offsets: [BlockOffset(0, 0), BlockOffset(1, 0), BlockOffset(2, 0), BlockOffset(3, 0)],
    width: 4,
    height: 1,
  );
  static const quadV = BlockShapeDefinition(
    name: 'Tetramino V',
    offsets: [BlockOffset(0, 0), BlockOffset(0, 1), BlockOffset(0, 2), BlockOffset(0, 3)],
    width: 1,
    height: 4,
  );

  // 5-Line
  static const pentaH = BlockShapeDefinition(
    name: 'Pentamino H',
    offsets: [BlockOffset(0, 0), BlockOffset(1, 0), BlockOffset(2, 0), BlockOffset(3, 0), BlockOffset(4, 0)],
    width: 5,
    height: 1,
  );
  static const pentaV = BlockShapeDefinition(
    name: 'Pentamino V',
    offsets: [BlockOffset(0, 0), BlockOffset(0, 1), BlockOffset(0, 2), BlockOffset(0, 3), BlockOffset(0, 4)],
    width: 1,
    height: 5,
  );

  // Square 2x2
  static const square2x2 = BlockShapeDefinition(
    name: 'Square 2x2',
    offsets: [
      BlockOffset(0, 0), BlockOffset(1, 0),
      BlockOffset(0, 1), BlockOffset(1, 1),
    ],
    width: 2,
    height: 2,
  );

  // Square 3x3
  static const square3x3 = BlockShapeDefinition(
    name: 'Square 3x3',
    offsets: [
      BlockOffset(0, 0), BlockOffset(1, 0), BlockOffset(2, 0),
      BlockOffset(0, 1), BlockOffset(1, 1), BlockOffset(2, 1),
      BlockOffset(0, 2), BlockOffset(1, 2), BlockOffset(2, 2),
    ],
    width: 3,
    height: 3,
  );

  // L-Shapes (3-cell corner)
  static const cornerTopLeft = BlockShapeDefinition(
    name: 'Corner TL',
    offsets: [BlockOffset(0, 0), BlockOffset(1, 0), BlockOffset(0, 1)],
    width: 2,
    height: 2,
  );
  static const cornerTopRight = BlockShapeDefinition(
    name: 'Corner TR',
    offsets: [BlockOffset(0, 0), BlockOffset(1, 0), BlockOffset(1, 1)],
    width: 2,
    height: 2,
  );
  static const cornerBottomLeft = BlockShapeDefinition(
    name: 'Corner BL',
    offsets: [BlockOffset(0, 0), BlockOffset(0, 1), BlockOffset(1, 1)],
    width: 2,
    height: 2,
  );
  static const cornerBottomRight = BlockShapeDefinition(
    name: 'Corner BR',
    offsets: [BlockOffset(1, 0), BlockOffset(0, 1), BlockOffset(1, 1)],
    width: 2,
    height: 2,
  );

  // Standard L-Shapes (4-cell)
  static const lNormal = BlockShapeDefinition(
    name: 'L Standard',
    offsets: [BlockOffset(0, 0), BlockOffset(0, 1), BlockOffset(0, 2), BlockOffset(1, 2)],
    width: 2,
    height: 3,
  );
  static const lInverted = BlockShapeDefinition(
    name: 'L Inverted',
    offsets: [BlockOffset(1, 0), BlockOffset(1, 1), BlockOffset(1, 2), BlockOffset(0, 2)],
    width: 2,
    height: 3,
  );
  static const lHorizontal = BlockShapeDefinition(
    name: 'L Horizontal',
    offsets: [BlockOffset(0, 0), BlockOffset(1, 0), BlockOffset(2, 0), BlockOffset(0, 1)],
    width: 3,
    height: 2,
  );

  // T-Shapes
  static const tDown = BlockShapeDefinition(
    name: 'T Down',
    offsets: [BlockOffset(0, 0), BlockOffset(1, 0), BlockOffset(2, 0), BlockOffset(1, 1)],
    width: 3,
    height: 2,
  );
  static const tUp = BlockShapeDefinition(
    name: 'T Up',
    offsets: [BlockOffset(1, 0), BlockOffset(0, 1), BlockOffset(1, 1), BlockOffset(2, 1)],
    width: 3,
    height: 2,
  );

  // Plus / Cross
  static const plus = BlockShapeDefinition(
    name: 'Plus',
    offsets: [
      BlockOffset(1, 0),
      BlockOffset(0, 1), BlockOffset(1, 1), BlockOffset(2, 1),
      BlockOffset(1, 2),
    ],
    width: 3,
    height: 3,
  );

  // Zigzag (Z and S)
  static const zShape = BlockShapeDefinition(
    name: 'Z Shape',
    offsets: [BlockOffset(0, 0), BlockOffset(1, 0), BlockOffset(1, 1), BlockOffset(2, 1)],
    width: 3,
    height: 2,
  );
  static const sShape = BlockShapeDefinition(
    name: 'S Shape',
    offsets: [BlockOffset(1, 0), BlockOffset(2, 0), BlockOffset(0, 1), BlockOffset(1, 1)],
    width: 3,
    height: 2,
  );

  // Large L (5-cell)
  static const lLarge = BlockShapeDefinition(
    name: 'L Large',
    offsets: [
      BlockOffset(0, 0), BlockOffset(0, 1), BlockOffset(0, 2),
      BlockOffset(1, 2), BlockOffset(2, 2),
    ],
    width: 3,
    height: 3,
  );

  static const List<BlockShapeDefinition> standardShapes = [
    single,
    dominoH, dominoV,
    triH, triV,
    quadH, quadV,
    square2x2,
    cornerTopLeft, cornerTopRight, cornerBottomLeft, cornerBottomRight,
    lNormal, lInverted, lHorizontal,
    tDown, tUp,
    zShape, sShape,
    plus,
    lLarge,
    pentaH, pentaV,
    square3x3,
  ];

  static BlockModel createBlock({
    required String id,
    required BlockShapeDefinition shape,
    required int colorValue,
    BlockWeightClass weightClass = BlockWeightClass.normal,
    SpecialBlockType specialType = SpecialBlockType.none,
    BlockSkinStyle skinStyle = BlockSkinStyle.gem,
  }) {
    return BlockModel(
      id: id,
      shapeName: shape.name,
      offsets: List.unmodifiable(shape.offsets),
      colorValue: colorValue,
      weightClass: weightClass,
      specialType: specialType,
      skinStyle: skinStyle,
      width: shape.width,
      height: shape.height,
    );
  }
}
