// Piece visual widget rendering polyomino shapes with bevel, shadows, and weight badges

import 'package:flutter/material.dart';
import '../../domain/models/block_model.dart';
import '../../domain/models/block_weight.dart';
import '../../domain/models/special_block_type.dart';
import '../../domain/models/block_skin_style.dart';

class PieceWidget extends StatelessWidget {
  final BlockModel block;
  final double cellSize;
  final bool isGhost;
  final double tiltAngle; // Directional tilt in radians
  final bool isDragging;

  const PieceWidget({
    super.key,
    required this.block,
    this.cellSize = 26.0,
    this.isGhost = false,
    this.tiltAngle = 0.0,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = block.width * cellSize;
    final height = block.height * cellSize;

    // Organic squash & stretch physics during drag
    final scaleX = isDragging ? 1.05 : 1.0;
    final scaleY = isDragging ? 0.95 : 1.0;

    return Transform.scale(
      scaleX: scaleX,
      scaleY: scaleY,
      child: Transform.rotate(
        angle: tiltAngle,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              for (final off in block.offsets)
                Positioned(
                  left: off.dx * cellSize,
                  top: off.dy * cellSize,
                  child: _buildCell(context, off),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, BlockOffset off) {
    const padding = 1.5;
    final size = cellSize - (padding * 2);

    BorderRadius borderRadius;
    Gradient gradient;
    Border border;
    List<BoxShadow> shadows;

    if (block.specialType == SpecialBlockType.rainbow) {
      borderRadius = BorderRadius.circular(size * 0.25);
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF1744),
          Color(0xFFFF9100),
          Color(0xFFFFEA00),
          Color(0xFF00E676),
          Color(0xFF00E5FF),
          Color(0xFF2979FF),
          Color(0xFFD500F9),
        ],
      );
      border = Border.all(color: Colors.white, width: 1.5);
      shadows = isGhost
          ? []
          : [
              const BoxShadow(
                color: Color(0xFFE040FB),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ];
    } else if (block.specialType == SpecialBlockType.ice) {
      borderRadius = BorderRadius.circular(size * 0.2);
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFE0F7FA).withValues(alpha: 0.95),
          const Color(0xFF80DEEA).withValues(alpha: 0.85),
          const Color(0xFF26C6DA).withValues(alpha: 0.9),
        ],
      );
      border = Border.all(color: Colors.white, width: 1.4);
      shadows = isGhost
          ? []
          : [
              const BoxShadow(
                color: Color(0xFF80DEEA),
                blurRadius: 5,
                spreadRadius: 0.5,
              ),
            ];
    } else if (block.specialType == SpecialBlockType.lightning) {
      borderRadius = BorderRadius.circular(size * 0.18);
      gradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFF8D),
          Color(0xFFFFD600),
          Color(0xFF00E5FF),
        ],
      );
      border = Border.all(color: Colors.white, width: 1.6);
      shadows = isGhost
          ? []
          : [
              const BoxShadow(
                color: Color(0xFFFFD600),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ];
    } else if (block.specialType == SpecialBlockType.coin) {
      borderRadius = BorderRadius.circular(size * 0.3);
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF9C4),
          Color(0xFFFFD700),
          Color(0xFFFF8F00),
        ],
      );
      border = Border.all(color: const Color(0xFFFFFDE7), width: 1.5);
      shadows = isGhost
          ? []
          : [
              const BoxShadow(
                color: Color(0xFFFFD700),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ];
    } else {
      switch (block.skinStyle) {
        case BlockSkinStyle.gem:
          borderRadius = BorderRadius.circular(size * 0.22);
          gradient = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(block.color, Colors.white, 0.55)!,
              block.color,
              Color.lerp(block.color, Colors.black, 0.35)!,
            ],
            stops: const [0.0, 0.45, 1.0],
          );
          border = Border.all(
            color: Colors.white.withValues(alpha: 0.65),
            width: 1.2,
          );
          shadows = isGhost
              ? []
              : [
                  BoxShadow(
                    color: block.color.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ];
          break;

      case BlockSkinStyle.neon:
        borderRadius = BorderRadius.circular(size * 0.18);
        gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(block.color, Colors.white, 0.35)!,
            block.color,
            Color.lerp(block.color, Colors.black, 0.2)!,
          ],
        );
        border = Border.all(
          color: Color.lerp(block.color, Colors.white, 0.7)!,
          width: 1.8,
        );
        shadows = isGhost
            ? []
            : [
                BoxShadow(
                  color: block.color.withValues(alpha: 0.65),
                  blurRadius: 6,
                  spreadRadius: 0.8,
                ),
              ];
        break;

      case BlockSkinStyle.candy:
        borderRadius = BorderRadius.circular(size * 0.35);
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(block.color, Colors.white, 0.7)!,
            block.color,
            Color.lerp(block.color, Colors.black, 0.25)!,
          ],
          stops: const [0.0, 0.4, 1.0],
        );
        border = Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.0,
        );
        shadows = isGhost
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ];
        break;

      case BlockSkinStyle.woodcraft:
        borderRadius = BorderRadius.circular(size * 0.15);
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(block.color, const Color(0xFFFDE68A), 0.35)!,
            block.color,
            Color.lerp(block.color, const Color(0xFF451A03), 0.45)!,
          ],
        );
        border = Border.all(
          color: const Color(0xFFFDE68A).withValues(alpha: 0.55),
          width: 1.3,
        );
        shadows = isGhost
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ];
        break;

      case BlockSkinStyle.obsidian:
        borderRadius = BorderRadius.circular(size * 0.20);
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(block.color, Colors.white, 0.35)!,
            Color.lerp(block.color, Colors.black, 0.6)!,
            const Color(0xFF0F172A),
          ],
        );
        border = Border.all(
          color: block.color.withValues(alpha: 0.85),
          width: 1.5,
        );
        shadows = isGhost
            ? []
            : [
                BoxShadow(
                  color: block.color.withValues(alpha: 0.5),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ];
        break;

      case BlockSkinStyle.midasGold:
        borderRadius = BorderRadius.circular(size * 0.22);
        gradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF9C4), // Bright champagne highlight
            Color(0xFFFFD700), // 24k Gold
            Color(0xFFFFB300), // Rich amber
            Color(0xFF8D6E63), // Antique gold base
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        );
        border = Border.all(
          color: const Color(0xFFFFFDE7),
          width: 1.8,
        );
        shadows = isGhost
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.55),
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ];
        break;

      case BlockSkinStyle.volcanicMagma:
        borderRadius = BorderRadius.circular(size * 0.18);
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD600), // Solar core
            const Color(0xFFFF3D00), // Molten lava
            Color.lerp(block.color, const Color(0xFF260D05), 0.7)!, // Basalt crust
          ],
          stops: const [0.0, 0.45, 1.0],
        );
        border = Border.all(
          color: const Color(0xFFFF9100),
          width: 1.6,
        );
        shadows = isGhost
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFFFF3D00).withValues(alpha: 0.6),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ];
        break;

      case BlockSkinStyle.cyberpunk:
        borderRadius = BorderRadius.circular(size * 0.14);
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00F5FF), // Cyber cyan
            Color.lerp(block.color, const Color(0xFFFF007F), 0.5)!, // Neon magenta
            const Color(0xFF1A0033), // Deep synth
          ],
          stops: const [0.0, 0.55, 1.0],
        );
        border = Border.all(
          color: const Color(0xFF00F5FF),
          width: 1.6,
        );
        shadows = isGhost
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFFFF007F).withValues(alpha: 0.6),
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ];
        break;

      case BlockSkinStyle.bioluminescence:
        borderRadius = BorderRadius.circular(size * 0.26);
        gradient = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            const Color(0xFF64FFDA), // Bioluminescent pulse
            Color.lerp(block.color, const Color(0xFF004D40), 0.4)!,
            const Color(0xFF021B1A), // Deep abyss
          ],
        );
        border = Border.all(
          color: const Color(0xFF64FFDA).withValues(alpha: 0.8),
          width: 1.5,
        );
        shadows = isGhost
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF64FFDA).withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ];
        break;

      case BlockSkinStyle.retroArcade:
        borderRadius = BorderRadius.circular(size * 0.08); // Pixel block feel
        gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(block.color, Colors.white, 0.5)!,
            block.color,
            Color.lerp(block.color, Colors.black, 0.4)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        );
        border = Border.all(
          color: Colors.white,
          width: 2.0,
        );
        shadows = isGhost
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 0,
                  offset: const Offset(2, 2), // 8-bit hard drop shadow
                ),
              ];
        break;

      case BlockSkinStyle.cosmicStarlight:
        borderRadius = BorderRadius.circular(size * 0.22);
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE0C3FC), // Nebula mist
            Color.lerp(block.color, const Color(0xFF8EC5FC), 0.6)!,
            const Color(0xFF1E085A), // Deep cosmos
          ],
          stops: const [0.0, 0.45, 1.0],
        );
        border = Border.all(
          color: const Color(0xFFE0C3FC),
          width: 1.6,
        );
        shadows = isGhost
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF8EC5FC).withValues(alpha: 0.65),
                  blurRadius: 9,
                  spreadRadius: 1,
                ),
              ];
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.all(padding),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: gradient,
        boxShadow: shadows,
        border: border,
      ),
      child: _buildSpecialIcon(size),
    );
  }

  Widget? _buildSpecialIcon(double size) {
    if (block.specialType == SpecialBlockType.none &&
        block.weightClass == BlockWeightClass.normal) {
      return null;
    }

    IconData? icon;
    if (block.specialType == SpecialBlockType.rainbow) {
      icon = Icons.auto_awesome;
    } else if (block.specialType == SpecialBlockType.ice) {
      icon = Icons.ac_unit;
    } else if (block.specialType == SpecialBlockType.lightning) {
      icon = Icons.bolt;
    } else if (block.specialType == SpecialBlockType.coin) {
      icon = Icons.monetization_on;
    } else if (block.specialType == SpecialBlockType.magnet) {
      icon = Icons.explore;
    } else if (block.specialType == SpecialBlockType.anchor) {
      icon = Icons.anchor;
    } else if (block.specialType == SpecialBlockType.voidBlock) {
      icon = Icons.blur_circular;
    } else if (block.specialType == SpecialBlockType.bloom) {
      icon = Icons.spa;
    } else if (block.specialType == SpecialBlockType.gravity) {
      icon = Icons.arrow_downward;
    } else if (block.specialType == SpecialBlockType.timeBomb) {
      icon = Icons.timer;
    } else if (block.specialType == SpecialBlockType.geode) {
      icon = Icons.diamond;
    } else if (block.specialType == SpecialBlockType.portal) {
      icon = Icons.all_inclusive;
    } else if (block.specialType == SpecialBlockType.morph) {
      icon = Icons.change_circle;
    } else if (block.weightClass == BlockWeightClass.heavy ||
        block.weightClass == BlockWeightClass.ultra) {
      icon = Icons.fitness_center;
    }

    if (icon == null) return null;

    return Center(
      child: Icon(
        icon,
        size: size * 0.55,
        color: Colors.white.withValues(alpha: 0.85),
      ),
    );
  }
}
