// Dynamic combo badge reflecting ASMR feedback tiers (PRD Section 38 & 72)

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ComboBadge extends StatelessWidget {
  final int comboCount;
  final Color accentColor;

  const ComboBadge({
    super.key,
    required this.comboCount,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (comboCount <= 1) return const SizedBox.shrink();

    String tierName = 'COMBO';
    if (comboCount >= 6) {
      tierName = 'BLOOM OVERDRIVE';
    } else if (comboCount >= 4) {
      tierName = 'RESONANCE';
    } else if (comboCount >= 3) {
      tierName = 'HARMONY';
    }

    return AnimatedScale(
      scale: 1.0 + (comboCount * 0.05).clamp(0.0, 0.25),
      duration: const Duration(milliseconds: 200),
      curve: Curves.elasticOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.9),
              accentColor.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bolt,
              color: AppColors.textPrimary,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              '${comboCount}x $tierName',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
