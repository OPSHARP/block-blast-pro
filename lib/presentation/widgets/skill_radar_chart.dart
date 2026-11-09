// 6-axis Radar chart visualizing the Player Skill Profile (PRD Section 74)

import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/player_skill_profile.dart';

class SkillRadarChart extends StatelessWidget {
  final PlayerSkillProfile profile;
  final Color accentColor;
  final double size;

  const SkillRadarChart({
    super.key,
    required this.profile,
    required this.accentColor,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarPainter(
          profile: profile,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final PlayerSkillProfile profile;
  final Color accentColor;

  static const List<String> axisLabels = [
    'Spatial Planning',
    'Efficiency',
    'Combo Skill',
    'Risk Taking',
    'Physics',
    'Grid Shift',
  ];

  _RadarPainter({
    required this.profile,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.38;

    final values = [
      profile.spatialPlanning / 100.0,
      profile.efficiency / 100.0,
      profile.comboSkill / 100.0,
      profile.riskManagement / 100.0,
      profile.physicsMastery / 100.0,
      profile.gridAwareness / 100.0,
    ];

    const int numAxes = 6;
    const double angleStep = 2 * pi / numAxes;

    // Draw concentric rings
    final ringPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int step = 1; step <= 5; step++) {
      final r = radius * (step / 5.0);
      final ringPath = Path();
      for (int i = 0; i < numAxes; i++) {
        final angle = i * angleStep - pi / 2;
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (i == 0) {
          ringPath.moveTo(x, y);
        } else {
          ringPath.lineTo(x, y);
        }
      }
      ringPath.close();
      canvas.drawPath(ringPath, ringPaint);
    }

    // Draw axis lines and labels
    final axisPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < numAxes; i++) {
      final angle = i * angleStep - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);

      // Label positioning
      final labelR = radius + 22;
      final lx = center.dx + labelR * cos(angle);
      final ly = center.dy + labelR * sin(angle);

      final textSpan = TextSpan(
        text: axisLabels[i],
        style: const TextStyle(
          color: Color(0xFF334155),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(lx - textPainter.width / 2, ly - textPainter.height / 2),
      );
    }

    // Draw player skill polygon
    final polyPath = Path();
    for (int i = 0; i < numAxes; i++) {
      final angle = i * angleStep - pi / 2;
      final r = radius * values[i].clamp(0.05, 1.0);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);

      if (i == 0) {
        polyPath.moveTo(x, y);
      } else {
        polyPath.lineTo(x, y);
      }
    }
    polyPath.close();

    // Fill with accent gradient
    final fillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(polyPath, fillPaint);

    final strokePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawPath(polyPath, strokePaint);

    // Draw nodes at each vertex
    final dotPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    for (int i = 0; i < numAxes; i++) {
      final angle = i * angleStep - pi / 2;
      final r = radius * values[i].clamp(0.05, 1.0);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      canvas.drawCircle(Offset(x, y), 4.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.profile != profile || oldDelegate.accentColor != accentColor;
}
