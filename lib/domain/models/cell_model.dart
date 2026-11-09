// Grid Cell Model representing an authoritative board slot

import 'package:flutter/material.dart';
import 'block_weight.dart';
import 'special_block_type.dart';
import 'block_skin_style.dart';

class CellModel {
  final int x;
  final int y;
  final bool isOccupied;
  final int colorValue;
  final BlockWeightClass weightClass;
  final SpecialBlockType specialType;
  final BlockSkinStyle skinStyle;
  final bool isLocked;
  final int hitPoints;

  const CellModel({
    required this.x,
    required this.y,
    this.isOccupied = false,
    this.colorValue = 0x00000000,
    this.weightClass = BlockWeightClass.normal,
    this.specialType = SpecialBlockType.none,
    this.skinStyle = BlockSkinStyle.gem,
    this.isLocked = false,
    this.hitPoints = 1,
  });

  Color get color => Color(colorValue);
  bool get isCracked => specialType == SpecialBlockType.ice && hitPoints == 1;
  bool get isGeodeStage1 => specialType == SpecialBlockType.geode && hitPoints == 2;
  bool get isGeodeStage2 => specialType == SpecialBlockType.geode && hitPoints == 1;
  int get geodeStage => specialType == SpecialBlockType.geode ? hitPoints : 0;
  bool get isTimeBomb => specialType == SpecialBlockType.timeBomb;
  int get bombCountdown => isTimeBomb ? hitPoints : 0;

  CellModel copyWith({
    int? x,
    int? y,
    bool? isOccupied,
    int? colorValue,
    BlockWeightClass? weightClass,
    SpecialBlockType? specialType,
    BlockSkinStyle? skinStyle,
    bool? isLocked,
    int? hitPoints,
  }) {
    return CellModel(
      x: x ?? this.x,
      y: y ?? this.y,
      isOccupied: isOccupied ?? this.isOccupied,
      colorValue: colorValue ?? this.colorValue,
      weightClass: weightClass ?? this.weightClass,
      specialType: specialType ?? this.specialType,
      skinStyle: skinStyle ?? this.skinStyle,
      isLocked: isLocked ?? this.isLocked,
      hitPoints: hitPoints ?? this.hitPoints,
    );
  }

  CellModel cleared() {
    return CellModel(
      x: x,
      y: y,
      isOccupied: false,
      colorValue: 0x00000000,
      weightClass: BlockWeightClass.normal,
      specialType: SpecialBlockType.none,
      skinStyle: BlockSkinStyle.gem,
      isLocked: false,
      hitPoints: 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'isOccupied': isOccupied,
      'colorValue': colorValue,
      'weightClass': weightClass.index,
      'specialType': specialType.index,
      'skinStyle': skinStyle.index,
      'isLocked': isLocked,
      'hitPoints': hitPoints,
    };
  }

  factory CellModel.fromMap(Map<String, dynamic> map) {
    return CellModel(
      x: map['x'] as int,
      y: map['y'] as int,
      isOccupied: map['isOccupied'] as bool? ?? false,
      colorValue: map['colorValue'] as int? ?? 0x00000000,
      weightClass: BlockWeightClass.values[
          (map['weightClass'] as int?)?.clamp(0, BlockWeightClass.values.length - 1) ?? 1],
      specialType: SpecialBlockType.values[
          (map['specialType'] as int?)?.clamp(0, SpecialBlockType.values.length - 1) ?? 0],
      skinStyle: BlockSkinStyle.values[
          (map['skinStyle'] as int?)?.clamp(0, BlockSkinStyle.values.length - 1) ?? 0],
      isLocked: map['isLocked'] as bool? ?? false,
      hitPoints: (map['hitPoints'] as int?) ?? 1,
    );
  }
}
