import 'dart:math';
import 'package:flutter/material.dart';
import 'block_weight.dart';
import 'special_block_type.dart';
import 'block_skin_style.dart';

class BlockOffset {
  final int dx;
  final int dy;

  const BlockOffset(this.dx, this.dy);

  Map<String, int> toMap() => {'dx': dx, 'dy': dy};

  factory BlockOffset.fromMap(Map<String, dynamic> map) =>
      BlockOffset(map['dx'] as int, map['dy'] as int);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockOffset &&
          runtimeType == other.runtimeType &&
          dx == other.dx &&
          dy == other.dy;

  @override
  int get hashCode => dx.hashCode ^ dy.hashCode;
}

class BlockModel {
  final String id;
  final String shapeName;
  final List<BlockOffset> offsets; // Relative to top-left (0,0)
  final int colorValue;
  final BlockWeightClass weightClass;
  final SpecialBlockType specialType;
  final BlockSkinStyle skinStyle;
  final int width;
  final int height;

  const BlockModel({
    required this.id,
    required this.shapeName,
    required this.offsets,
    required this.colorValue,
    this.weightClass = BlockWeightClass.normal,
    this.specialType = SpecialBlockType.none,
    this.skinStyle = BlockSkinStyle.gem,
    required this.width,
    required this.height,
  });

  Color get color => Color(colorValue);
  int get cellCount => offsets.length;

  /// Rotates polyomino block 90 degrees clockwise and normalizes coordinates
  BlockModel rotatedClockwise() {
    if (offsets.isEmpty) return this;
    final rotated = offsets.map((o) => BlockOffset(-o.dy, o.dx)).toList();
    final minX = rotated.map((o) => o.dx).reduce(min);
    final minY = rotated.map((o) => o.dy).reduce(min);
    final normalized = rotated.map((o) => BlockOffset(o.dx - minX, o.dy - minY)).toList();
    final newW = normalized.map((o) => o.dx).reduce(max) + 1;
    final newH = normalized.map((o) => o.dy).reduce(max) + 1;
    return copyWith(
      offsets: normalized,
      width: newW,
      height: newH,
    );
  }

  BlockModel copyWith({
    String? id,
    String? shapeName,
    List<BlockOffset>? offsets,
    int? colorValue,
    BlockWeightClass? weightClass,
    SpecialBlockType? specialType,
    BlockSkinStyle? skinStyle,
    int? width,
    int? height,
  }) {
    return BlockModel(
      id: id ?? this.id,
      shapeName: shapeName ?? this.shapeName,
      offsets: offsets ?? this.offsets,
      colorValue: colorValue ?? this.colorValue,
      weightClass: weightClass ?? this.weightClass,
      specialType: specialType ?? this.specialType,
      skinStyle: skinStyle ?? this.skinStyle,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shapeName': shapeName,
      'offsets': offsets.map((o) => o.toMap()).toList(),
      'colorValue': colorValue,
      'weightClass': weightClass.index,
      'specialType': specialType.index,
      'skinStyle': skinStyle.index,
      'width': width,
      'height': height,
    };
  }

  factory BlockModel.fromMap(Map<String, dynamic> map) {
    return BlockModel(
      id: map['id'] as String,
      shapeName: map['shapeName'] as String,
      offsets: (map['offsets'] as List<dynamic>)
          .map((o) => BlockOffset.fromMap(o as Map<String, dynamic>))
          .toList(),
      colorValue: map['colorValue'] as int,
      weightClass: BlockWeightClass.values[
          (map['weightClass'] as int?)?.clamp(0, BlockWeightClass.values.length - 1) ?? 1],
      specialType: SpecialBlockType.values[
          (map['specialType'] as int?)?.clamp(0, SpecialBlockType.values.length - 1) ?? 0],
      skinStyle: BlockSkinStyle.values[
          (map['skinStyle'] as int?)?.clamp(0, BlockSkinStyle.values.length - 1) ?? 0],
      width: map['width'] as int,
      height: map['height'] as int,
    );
  }
}
