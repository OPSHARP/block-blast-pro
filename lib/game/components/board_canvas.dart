// Custom Board Painter and interactive canvas component for Block Blast Pro

import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/board_state.dart';
import '../../domain/models/block_model.dart';
import '../../domain/models/block_weight.dart';
import '../../domain/models/special_block_type.dart';
import '../../domain/models/block_skin_style.dart';
import '../../core/theme/game_theme.dart';
import 'particle_engine.dart';

class BoardCanvasPainter extends CustomPainter {
  final BoardState board;
  final GameTheme theme;
  final BlockModel? draggingPiece;
  final Point<int>? hoveredCoord;
  final bool isPlacementValid;
  final ParticleEngine particleEngine;
  final String? pendingShiftWarning;
  final double animationValue;

  final bool isHammerModeActive;
  final bool isTntModeActive;
  final bool isColorMagnetModeActive;

  final List<Point<int>>? recentPlacementCoords;
  final double squashProgress;

  BoardCanvasPainter({
    required this.board,
    required this.theme,
    required this.draggingPiece,
    required this.hoveredCoord,
    required this.isPlacementValid,
    required this.particleEngine,
    this.pendingShiftWarning,
    required this.animationValue,
    this.isHammerModeActive = false,
    this.isTntModeActive = false,
    this.isColorMagnetModeActive = false,
    this.recentPlacementCoords,
    this.squashProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridSize = board.gridSize;
    final boardRect = Offset.zero & size;
    final cellSize = size.width / gridSize;
    const cellPadding = 3.0;

    // Check board occupancy for near-full danger warning
    int occupiedCount = 0;
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (board.cells[y][x].isOccupied) occupiedCount++;
      }
    }
    final occupancyRate = occupiedCount / (gridSize * gridSize);
    final isDanger = occupancyRate >= 0.75;

    // 1. Draw Board Base Plate (Glassmorphic)
    final boardRRect = RRect.fromRectAndRadius(boardRect, const Radius.circular(20));
    final basePaint = Paint()
      ..color = theme.boardBackground
      ..style = PaintingStyle.fill;
    canvas.drawRRect(boardRRect, basePaint);

    final borderPulse = 0.6 + 0.4 * sin(animationValue * 4 * pi);
    final Color borderColor;
    if (isColorMagnetModeActive) {
      borderColor = Color.lerp(const Color(0xFFE040FB), const Color(0xFF7C4DFF), borderPulse.clamp(0.0, 1.0))!;
    } else if (isTntModeActive) {
      borderColor = Color.lerp(const Color(0xFFFF3D00), const Color(0xFFFFD600), borderPulse.clamp(0.0, 1.0))!;
    } else if (isHammerModeActive) {
      borderColor = const Color(0xFFFF5722);
    } else if (isDanger) {
      // Urgent pulsing warning glow when board is near full capacity
      final dangerPulse = 0.5 + 0.5 * sin(animationValue * (occupancyRate >= 0.85 ? 8 * pi : 5 * pi));
      borderColor = Color.lerp(const Color(0xFFFF1744), const Color(0xFFFF9100), dangerPulse.clamp(0.0, 1.0))!;
    } else {
      borderColor = theme.boardBorder;
    }

    if (isDanger && !isColorMagnetModeActive && !isTntModeActive && !isHammerModeActive) {
      final dangerGlowPaint = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.30 * (0.6 + 0.4 * sin(animationValue * 6 * pi)))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(boardRRect, dangerGlowPaint);
    }

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isColorMagnetModeActive || isTntModeActive || isHammerModeActive || isDanger) ? 3.5 : 2.0;
    canvas.drawRRect(boardRRect, borderPaint);

    // 2. Draw Grid Cells
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final cell = board.cells[y][x];
        final rect = Rect.fromLTWH(
          x * cellSize + cellPadding,
          y * cellSize + cellPadding,
          cellSize - cellPadding * 2,
          cellSize - cellPadding * 2,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

        if (!cell.isOccupied) {
          // Empty Cell
          final emptyPaint = Paint()
            ..color = theme.cellEmpty
            ..style = PaintingStyle.fill;
          canvas.drawRRect(rrect, emptyPaint);

          final emptyBorderPaint = Paint()
            ..color = isTntModeActive
                ? const Color(0xFFFF3D00).withValues(alpha: 0.35 + 0.25 * sin(animationValue * 5 * pi))
                : (isColorMagnetModeActive
                    ? const Color(0xFFE040FB).withValues(alpha: 0.35 + 0.25 * sin(animationValue * 5 * pi))
                    : theme.cellBorder)
            ..style = PaintingStyle.stroke
            ..strokeWidth = (isTntModeActive || isColorMagnetModeActive) ? 1.4 : 1.0;
          canvas.drawRRect(rrect, emptyBorderPaint);

          if (isTntModeActive) {
            final tntPulse = 0.35 + 0.25 * sin(animationValue * 5 * pi);
            final tntEmptyPaint = Paint()
              ..color = const Color(0xFFFF9100).withValues(alpha: tntPulse.clamp(0.0, 1.0))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2;
            final c = rrect.center;
            canvas.drawLine(c + const Offset(-3, 0), c + const Offset(3, 0), tntEmptyPaint);
            canvas.drawLine(c + const Offset(0, -3), c + const Offset(0, 3), tntEmptyPaint);
          }
        } else {
          // Occupied Cell with 3D Bevel & Lighting
          // Apply Squash & Stretch physics if recently placed
          final isSquashTarget = recentPlacementCoords != null &&
              recentPlacementCoords!.any((pt) => pt.x == x && pt.y == y) &&
              squashProgress < 1.0;

          RRect cellRRect = rrect;
          if (isSquashTarget) {
            final factor = sin(squashProgress * pi) * (1.0 - squashProgress);
            final scaleX = 1.0 + factor * 0.14;
            final scaleY = 1.0 - factor * 0.14;
            final center = rrect.center;
            final scaledRect = Rect.fromCenter(
              center: center,
              width: rect.width * scaleX,
              height: rect.height * scaleY,
            );
            cellRRect = RRect.fromRectAndRadius(scaledRect, const Radius.circular(8));
          }

          _drawOccupiedCell(
            canvas,
            cellRRect,
            cell.color,
            cell.weightClass,
            cell.specialType,
            cell.skinStyle,
            cell.isCracked,
            hitPoints: cell.hitPoints,
          );

          // If Hammer mode active, draw targeting pulse over occupied cells
          if (isHammerModeActive) {
            final hammerPulse = 0.35 + 0.25 * sin(animationValue * 4 * pi);
            final reticlePaint = Paint()
              ..color = const Color(0xFFFF5722).withValues(alpha: hammerPulse)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0;
            canvas.drawRRect(rrect, reticlePaint);
            // Center reticle cross
            final c = rrect.center;
            canvas.drawLine(c + const Offset(-4, 0), c + const Offset(4, 0), reticlePaint);
            canvas.drawLine(c + const Offset(0, -4), c + const Offset(0, 4), reticlePaint);
          } else if (isTntModeActive) {
            final tntPulse = 0.45 + 0.35 * sin(animationValue * 5 * pi);
            final tntReticlePaint = Paint()
              ..color = const Color(0xFFFF3D00).withValues(alpha: tntPulse.clamp(0.0, 1.0))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2;
            canvas.drawRRect(rrect, tntReticlePaint);
            // Fiery explosive crosshairs
            final c = rrect.center;
            canvas.drawLine(c + const Offset(-6, 0), c + const Offset(6, 0), tntReticlePaint);
            canvas.drawLine(c + const Offset(0, -6), c + const Offset(0, 6), tntReticlePaint);
          } else if (isColorMagnetModeActive) {
            final magPulse = 0.45 + 0.35 * sin(animationValue * 5 * pi);
            final magReticlePaint = Paint()
              ..color = const Color(0xFFE040FB).withValues(alpha: magPulse.clamp(0.0, 1.0))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2;
            canvas.drawRRect(rrect, magReticlePaint);
            final c = rrect.center;
            canvas.drawCircle(c, 4, magReticlePaint);
          }
        }
      }
    }

    // 3. Smart Ghost Flash: Pre-visualize completing lines before placement
    if (draggingPiece != null && hoveredCoord != null && isPlacementValid) {
      final hx = hoveredCoord!.x;
      final hy = hoveredCoord!.y;

      final prospectiveOccupied = List.generate(
        gridSize,
        (y) => List.generate(gridSize, (x) => board.cells[y][x].isOccupied),
      );
      for (final off in draggingPiece!.offsets) {
        final gx = hx + off.dx;
        final gy = hy + off.dy;
        if (board.isValidCoord(gx, gy)) {
          prospectiveOccupied[gy][gx] = true;
        }
      }

      final prospectiveRows = <int>[];
      for (int y = 0; y < gridSize; y++) {
        if (prospectiveOccupied[y].every((occ) => occ)) prospectiveRows.add(y);
      }
      final prospectiveCols = <int>[];
      for (int x = 0; x < gridSize; x++) {
        bool colFull = true;
        for (int y = 0; y < gridSize; y++) {
          if (!prospectiveOccupied[y][x]) {
            colFull = false;
            break;
          }
        }
        if (colFull) prospectiveCols.add(x);
      }

      // Draw Glowing Shimmer over prospective lines
      final totalLines = prospectiveRows.length + prospectiveCols.length;
      if (totalLines > 0) {
        final shimmerPulse = 0.45 + 0.35 * sin(animationValue * 6 * pi);
        final shimmerColor = totalLines >= 2
            ? const Color(0xFFFFD700) // Golden Multi-Blast radiance
            : const Color(0xFF00E5FF); // Electric Cyan single blast

        final lineShimmerPaint = Paint()
          ..color = shimmerColor.withValues(alpha: shimmerPulse * 0.4)
          ..style = PaintingStyle.fill;
        final lineBorderPaint = Paint()
          ..color = shimmerColor.withValues(alpha: shimmerPulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        for (final r in prospectiveRows) {
          final rowRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(cellPadding, r * cellSize + cellPadding, size.width - cellPadding * 2, cellSize - cellPadding * 2),
            const Radius.circular(8),
          );
          canvas.drawRRect(rowRect, lineShimmerPaint);
          canvas.drawRRect(rowRect, lineBorderPaint);
        }
        for (final c in prospectiveCols) {
          final colRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(c * cellSize + cellPadding, cellPadding, cellSize - cellPadding * 2, size.height - cellPadding * 2),
            const Radius.circular(8),
          );
          canvas.drawRRect(colRect, lineShimmerPaint);
          canvas.drawRRect(colRect, lineBorderPaint);
        }
      }

      // Draw Piece Ghost Preview
      final ghostPulse = 0.65 + 0.25 * sin(animationValue * 2 * pi);
      for (final off in draggingPiece!.offsets) {
        final gx = hx + off.dx;
        final gy = hy + off.dy;

        if (board.isValidCoord(gx, gy)) {
          final rect = Rect.fromLTWH(
            gx * cellSize + cellPadding,
            gy * cellSize + cellPadding,
            cellSize - cellPadding * 2,
            cellSize - cellPadding * 2,
          );
          final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

          // Translucent ghost glow
          final ghostPaint = Paint()
            ..color = draggingPiece!.color.withValues(alpha: ghostPulse * 0.75)
            ..style = PaintingStyle.fill;
          canvas.drawRRect(rrect, ghostPaint);

          final ghostBorder = Paint()
            ..color = Colors.white.withValues(alpha: ghostPulse)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;
          canvas.drawRRect(rrect, ghostBorder);
        }
      }
    }

    // 4. Draw Particles (Burst and Sparks)
    particleEngine.render(canvas);

    // 5. Subtle Shift Warning Indicator
    if (pendingShiftWarning != null && pendingShiftWarning!.isNotEmpty) {
      final warningPaint = Paint()
        ..color = theme.accent.withValues(alpha: 0.15 + 0.1 * sin(animationValue * 4 * pi))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(boardRRect, warningPaint);
    }
  }

  void _drawOccupiedCell(
    Canvas canvas,
    RRect rrect,
    Color baseColor,
    BlockWeightClass weightClass,
    SpecialBlockType specialType,
    BlockSkinStyle skinStyle,
    bool isCracked, {
    int hitPoints = 1,
  }) {
    // 3D Depth Shadow
    final shadowOffset = weightClass == BlockWeightClass.heavy || weightClass == BlockWeightClass.ultra
        ? 3.0
        : 1.8;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect.shift(Offset(0, shadowOffset)), shadowPaint);

    LinearGradient gradient;
    final bevelPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2;

    if (specialType == SpecialBlockType.rainbow) {
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
      bevelPaint.color = Colors.white.withValues(alpha: 0.85);
      bevelPaint.strokeWidth = 1.6;
    } else if (specialType == SpecialBlockType.ice) {
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFE0F7FA).withValues(alpha: 0.95),
          const Color(0xFF80DEEA).withValues(alpha: 0.85),
          const Color(0xFF26C6DA).withValues(alpha: 0.9),
        ],
      );
      bevelPaint.color = Colors.white;
      bevelPaint.strokeWidth = 1.4;
    } else if (specialType == SpecialBlockType.lightning) {
      gradient = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFF8D),
          Color(0xFFFFD600),
          Color(0xFF00E5FF),
        ],
      );
      bevelPaint.color = Colors.white;
      bevelPaint.strokeWidth = 1.8;
    } else if (specialType == SpecialBlockType.coin) {
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF9C4),
          Color(0xFFFFD700),
          Color(0xFFFF8F00),
        ],
      );
      bevelPaint.color = const Color(0xFFFFFDE7);
      bevelPaint.strokeWidth = 1.6;
    } else if (specialType == SpecialBlockType.geode) {
      if (hitPoints >= 3) {
        gradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE1BEE7),
            Color(0xFF8E24AA),
            Color(0xFF4A148C),
          ],
        );
        bevelPaint.color = const Color(0xFFF3E5F5);
        bevelPaint.strokeWidth = 1.6;
      } else if (hitPoints == 2) {
        gradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF80DEEA),
            Color(0xFF00ACC1),
            Color(0xFF006064),
          ],
        );
        bevelPaint.color = const Color(0xFFE0F7FA);
        bevelPaint.strokeWidth = 1.8;
      } else {
        gradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFB2EBF2),
            Color(0xFF00E5FF),
          ],
        );
        bevelPaint.color = Colors.white;
        bevelPaint.strokeWidth = 2.0;
      }
    } else if (specialType == SpecialBlockType.timeBomb) {
      final bombPulse = 0.5 + 0.5 * sin(animationValue * 8 * pi);
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(const Color(0xFFFF5252), Colors.white, bombPulse * 0.4)!,
          const Color(0xFFFF1744),
          const Color(0xFF880E4F),
        ],
      );
      bevelPaint.color = const Color(0xFFFFD54F);
      bevelPaint.strokeWidth = 1.8;
    } else if (specialType == SpecialBlockType.portal) {
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF00E5FF),
          Color(0xFF651FFF),
          Color(0xFFD500F9),
        ],
      );
      bevelPaint.color = const Color(0xFF80D8FF);
      bevelPaint.strokeWidth = 1.8;
    } else if (specialType == SpecialBlockType.morph) {
      final morphPulse = 0.5 + 0.5 * sin(animationValue * 4 * pi);
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(baseColor, const Color(0xFF00E676), morphPulse)!,
          baseColor,
          Color.lerp(baseColor, const Color(0xFF651FFF), morphPulse)!,
        ],
      );
      bevelPaint.color = Colors.white.withValues(alpha: 0.75);
      bevelPaint.strokeWidth = 1.6;
    } else {
      switch (skinStyle) {
        case BlockSkinStyle.gem:
          gradient = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(baseColor, Colors.white, 0.55)!,
              baseColor,
              Color.lerp(baseColor, Colors.black, 0.35)!,
            ],
            stops: const [0.0, 0.45, 1.0],
          );
          bevelPaint.color = Colors.white.withValues(alpha: 0.55);
          break;

        case BlockSkinStyle.neon:
          gradient = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(baseColor, Colors.white, 0.35)!,
              baseColor,
              Color.lerp(baseColor, Colors.black, 0.2)!,
            ],
          );
          bevelPaint.color = Color.lerp(baseColor, Colors.white, 0.7)!;
          bevelPaint.strokeWidth = 1.8;
          break;

        case BlockSkinStyle.candy:
          gradient = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(baseColor, Colors.white, 0.7)!,
              baseColor,
              Color.lerp(baseColor, Colors.black, 0.25)!,
            ],
            stops: const [0.0, 0.4, 1.0],
          );
          bevelPaint.color = Colors.white.withValues(alpha: 0.45);
          break;

        case BlockSkinStyle.woodcraft:
          gradient = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(baseColor, const Color(0xFFFDE68A), 0.35)!,
              baseColor,
              Color.lerp(baseColor, const Color(0xFF451A03), 0.45)!,
            ],
          );
          bevelPaint.color = const Color(0xFFFDE68A).withValues(alpha: 0.5);
          break;

        case BlockSkinStyle.obsidian:
          gradient = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(baseColor, Colors.white, 0.35)!,
              Color.lerp(baseColor, Colors.black, 0.6)!,
              const Color(0xFF0F172A),
            ],
          );
          bevelPaint.color = baseColor.withValues(alpha: 0.85);
          bevelPaint.strokeWidth = 1.5;
          break;

        case BlockSkinStyle.midasGold:
          gradient = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF9C4), // Champagne shine
              Color(0xFFFFD700), // 24k Gold
              Color(0xFFFFB300), // Deep amber
              Color(0xFF8D6E63), // Antique gold base
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          );
          bevelPaint.color = const Color(0xFFFFFDE7);
          bevelPaint.strokeWidth = 1.8;
          break;

        case BlockSkinStyle.volcanicMagma:
          gradient = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFD600), // Solar core
              const Color(0xFFFF3D00), // Molten lava
              Color.lerp(baseColor, const Color(0xFF260D05), 0.7)!, // Basalt crust
            ],
            stops: const [0.0, 0.45, 1.0],
          );
          bevelPaint.color = const Color(0xFFFF9100);
          bevelPaint.strokeWidth = 1.6;
          break;

        case BlockSkinStyle.cyberpunk:
          gradient = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00F0FF),
              const Color(0xFF1E0836),
              const Color(0xFFFF007F),
            ],
            stops: const [0.0, 0.5, 1.0],
          );
          bevelPaint.color = const Color(0xFF00F0FF);
          bevelPaint.strokeWidth = 1.8;
          break;

        case BlockSkinStyle.bioluminescence:
          gradient = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(baseColor, const Color(0xFFE0F7FA), 0.6)!,
              baseColor.withValues(alpha: 0.88),
              Color.lerp(baseColor, const Color(0xFF004D40), 0.5)!,
            ],
          );
          bevelPaint.color = const Color(0xFF80DEEA);
          bevelPaint.strokeWidth = 1.5;
          break;

        case BlockSkinStyle.retroArcade:
          gradient = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(baseColor, Colors.white, 0.45)!,
              baseColor,
              Color.lerp(baseColor, Colors.black, 0.4)!,
            ],
          );
          bevelPaint.color = Colors.white.withValues(alpha: 0.8);
          bevelPaint.strokeWidth = 2.0;
          break;

        case BlockSkinStyle.cosmicStarlight:
          gradient = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE040FB),
              Color(0xFF311B92),
              Color(0xFF0A0017),
            ],
          );
          bevelPaint.color = const Color(0xFFE040FB);
          bevelPaint.strokeWidth = 1.6;
          break;
      }
    }

    final fillPaint = Paint()
      ..shader = gradient.createShader(rrect.outerRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, bevelPaint);

    // Dynamic Skin Particle Accents
    if (skinStyle == BlockSkinStyle.midasGold) {
      // Golden specular diagonal sweep
      final gleamPhase = (animationValue * 2.0) % 1.0;
      final gleamX = rrect.left + (rrect.width * 2.5) * gleamPhase - (rrect.width * 0.75);
      final gleamPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..strokeWidth = 1.8;
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawLine(
        Offset(gleamX, rrect.top - 4),
        Offset(gleamX - rrect.height * 0.7, rrect.bottom + 4),
        gleamPaint,
      );
      canvas.restore();
    } else if (skinStyle == BlockSkinStyle.volcanicMagma) {
      // Molten pulsating vein glow
      final veinGlow = 0.4 + 0.35 * sin(animationValue * 5 * pi);
      final veinPaint = Paint()
        ..color = const Color(0xFFFFD600).withValues(alpha: veinGlow.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      final c = rrect.center;
      canvas.save();
      canvas.clipRRect(rrect);
      final veinPath = Path()
        ..moveTo(c.dx - 6, c.dy + 6)
        ..lineTo(c.dx - 1, c.dy)
        ..lineTo(c.dx + 4, c.dy - 5);
      canvas.drawPath(veinPath, veinPaint);
      canvas.restore();
    } else if (skinStyle == BlockSkinStyle.cosmicStarlight) {
      // Celestial diamond sparkle in center
      final starGleam = 0.3 + 0.3 * sin(animationValue * 4 * pi);
      final starPaint = Paint()..color = Colors.white.withValues(alpha: starGleam)..style = PaintingStyle.fill;
      canvas.drawCircle(rrect.center, 2.0, starPaint);
    }

    // Render Fracture Cracks for Ice and damaged Geodes
    if (isCracked || (specialType == SpecialBlockType.geode && hitPoints <= 2)) {
      final crackPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      final c = rrect.center;
      final crackPath = Path()
        ..moveTo(c.dx - 8, c.dy - 8)
        ..lineTo(c.dx - 2, c.dy - 1)
        ..lineTo(c.dx + 2, c.dy - 6)
        ..lineTo(c.dx + 8, c.dy - 3)
        ..moveTo(c.dx - 2, c.dy - 1)
        ..lineTo(c.dx - 1, c.dy + 7)
        ..lineTo(c.dx + 6, c.dy + 8)
        ..moveTo(c.dx - 1, c.dy + 3)
        ..lineTo(c.dx - 7, c.dy + 5);
      canvas.drawPath(crackPath, crackPaint);
    }

    // Special Block Glyphs
    if (specialType != SpecialBlockType.none) {
      _drawSpecialGlyph(canvas, rrect.center, specialType, hitPoints: hitPoints);
    }
  }

  void _drawSpecialGlyph(Canvas canvas, Offset center, SpecialBlockType type, {int hitPoints = 1}) {
    final glyphPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    switch (type) {
      case SpecialBlockType.rainbow:
        final arcPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawArc(
          Rect.fromCircle(center: center + const Offset(0, 3), radius: 6),
          pi,
          pi,
          false,
          arcPaint,
        );
        canvas.drawArc(
          Rect.fromCircle(center: center + const Offset(0, 3), radius: 3),
          pi,
          pi,
          false,
          arcPaint,
        );
        break;
      case SpecialBlockType.lightning:
        final boltPaint = Paint()
          ..color = const Color(0xFFFFF176)
          ..style = PaintingStyle.fill;
        final boltPath = Path()
          ..moveTo(center.dx + 2, center.dy - 8)
          ..lineTo(center.dx - 4, center.dy)
          ..lineTo(center.dx - 1, center.dy)
          ..lineTo(center.dx - 2, center.dy + 8)
          ..lineTo(center.dx + 4, center.dy)
          ..lineTo(center.dx + 1, center.dy)
          ..close();
        canvas.drawPath(boltPath, boltPaint);
        break;
      case SpecialBlockType.ice:
        final icePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        canvas.drawLine(center + const Offset(-6, 0), center + const Offset(6, 0), icePaint);
        canvas.drawLine(center + const Offset(0, -6), center + const Offset(0, 6), icePaint);
        canvas.drawLine(center + const Offset(-4, -4), center + const Offset(4, 4), icePaint);
        canvas.drawLine(center + const Offset(-4, 4), center + const Offset(4, -4), icePaint);
        break;
      case SpecialBlockType.coin:
        final coinRim = Paint()
          ..color = const Color(0xFFFFF9C4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        final starFill = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 6, coinRim);
        canvas.drawCircle(center, 2.5, starFill);
        break;
      case SpecialBlockType.timeBomb:
        final bombFill = Paint()
          ..color = const Color(0xFFFF1744)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 7, bombFill);
        canvas.drawCircle(center, 7, glyphPaint);
        // Fuse spark
        canvas.drawLine(center + const Offset(4, -5), center + const Offset(7, -8), glyphPaint);
        // Countdown text
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$hitPoints',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
        break;
      case SpecialBlockType.geode:
        final gemFill = Paint()
          ..color = (hitPoints >= 3
              ? const Color(0xFFBA68C8)
              : (hitPoints == 2 ? const Color(0xFF00E5FF) : Colors.white))
          ..style = PaintingStyle.fill;
        final path = Path()
          ..moveTo(center.dx, center.dy - 7)
          ..lineTo(center.dx + 6, center.dy - 1)
          ..lineTo(center.dx + 4, center.dy + 6)
          ..lineTo(center.dx - 4, center.dy + 6)
          ..lineTo(center.dx - 6, center.dy - 1)
          ..close();
        canvas.drawPath(path, gemFill);
        canvas.drawPath(path, glyphPaint);
        break;
      case SpecialBlockType.portal:
        final portalPaint = Paint()
          ..color = const Color(0xFF00E5FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
        canvas.drawOval(Rect.fromCenter(center: center, width: 13, height: 7), portalPaint);
        final innerPortal = Paint()
          ..color = const Color(0xFFD500F9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
        canvas.drawOval(Rect.fromCenter(center: center, width: 8, height: 4), innerPortal);
        break;
      case SpecialBlockType.morph:
        canvas.drawArc(Rect.fromCircle(center: center, radius: 5.5), 0, 1.5 * pi, false, glyphPaint);
        canvas.drawLine(center + const Offset(5.5, -2), center + const Offset(5.5, 2), glyphPaint);
        canvas.drawLine(center + const Offset(3.5, 0), center + const Offset(5.5, 2), glyphPaint);
        break;
      case SpecialBlockType.magnet:
        final magPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawArc(
          Rect.fromCircle(center: center + const Offset(0, -1), radius: 5),
          0,
          pi,
          false,
          magPaint,
        );
        canvas.drawLine(center + const Offset(-5, -1), center + const Offset(-5, -6), magPaint);
        canvas.drawLine(center + const Offset(5, -1), center + const Offset(5, -6), magPaint);
        break;
      case SpecialBlockType.anchor:
        canvas.drawLine(center + const Offset(0, -6), center + const Offset(0, 6), glyphPaint);
        canvas.drawLine(center + const Offset(-5, -2), center + const Offset(5, -2), glyphPaint);
        break;
      case SpecialBlockType.gravity:
        canvas.drawLine(center + const Offset(0, -6), center + const Offset(0, 5), glyphPaint);
        canvas.drawLine(center + const Offset(-4, 1), center + const Offset(0, 5), glyphPaint);
        canvas.drawLine(center + const Offset(4, 1), center + const Offset(0, 5), glyphPaint);
        break;
      case SpecialBlockType.voidBlock:
        final fillVoid = Paint()
          ..color = Colors.black.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 5, fillVoid);
        canvas.drawCircle(center, 5, glyphPaint);
        break;
      case SpecialBlockType.bloom:
        canvas.drawCircle(center, 4, glyphPaint);
        break;
      case SpecialBlockType.pulse:
        canvas.drawCircle(center, 6, glyphPaint);
        canvas.drawCircle(center, 2, glyphPaint);
        break;
      case SpecialBlockType.bomb:
        final bombFill = Paint()
          ..color = const Color(0xFFFF5722)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 5, bombFill);
        canvas.drawCircle(center, 5, glyphPaint);
        canvas.drawLine(center + const Offset(3, -3), center + const Offset(6, -6), glyphPaint);
        break;
      case SpecialBlockType.laser:
        canvas.drawLine(center + const Offset(-6, 0), center + const Offset(6, 0), glyphPaint);
        canvas.drawLine(center + const Offset(0, -6), center + const Offset(0, 6), glyphPaint);
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant BoardCanvasPainter oldDelegate) {
    if (board != oldDelegate.board) return true;
    if (draggingPiece != oldDelegate.draggingPiece) return true;
    if (hoveredCoord != oldDelegate.hoveredCoord) return true;
    if (isPlacementValid != oldDelegate.isPlacementValid) return true;
    if (particleEngine.hasActiveParticles) return true;
    if (squashProgress < 1.0) return true;
    if (isHammerModeActive != oldDelegate.isHammerModeActive) return true;
    if (isTntModeActive != oldDelegate.isTntModeActive) return true;
    if (isColorMagnetModeActive != oldDelegate.isColorMagnetModeActive) return true;
    if (isHammerModeActive || isTntModeActive || isColorMagnetModeActive) return true;

    // Check danger occupancy state:
    final int occ = board.occupiedCount;
    final bool isDanger = occ / (board.gridSize * board.gridSize) >= 0.75;
    if (isDanger) return true;

    // Special animated cells check (time bomb countdown pulse, gold sweep, magma fissures)
    for (int y = 0; y < board.gridSize; y++) {
      for (int x = 0; x < board.gridSize; x++) {
        final c = board.cells[y][x];
        if (c.isOccupied) {
          if (c.specialType == SpecialBlockType.timeBomb ||
              c.specialType == SpecialBlockType.rainbow ||
              c.skinStyle == BlockSkinStyle.midasGold ||
              c.skinStyle == BlockSkinStyle.volcanicMagma ||
              c.skinStyle == BlockSkinStyle.cosmicStarlight) {
            return true;
          }
        }
      }
    }
    // Thermal saver: completely idle board skips repaint!
    return false;
  }
}
