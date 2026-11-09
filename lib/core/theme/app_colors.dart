// Centralized Light-Mode Semantic Colors for Block Blast Pro
// All UI screens reference these constants for consistent light-mode appearance.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Text ──────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);          // Deep Slate 900 for razor-sharp readability in light mode
  static const Color textSecondary = Color(0xFF334155);        // Slate 700 for subtitles and secondary content
  static const Color textTertiary = Color(0xFF64748B);         // Slate 500 for captions, hints & category headers
  static const Color textOnAccent = Colors.white;              // Crisp white for colored buttons
  static const Color textDark = Color(0xFF0F172A);             // Dark text

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color surface = Colors.white;                  // Crisp glossy white card surface
  static const Color surfaceElevated = Color(0xFFF8FAFC);      // Slightly elevated white/pearl surface
  static const Color scaffoldBackground = Color(0xFFF0F6FF);   // Cheerful light background

  // ── Borders & Dividers ────────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFCBD5E1);

  // ── Icon Colors ───────────────────────────────────────────────────────────
  static const Color iconDefault = Color(0xFF334155);
  static const Color iconSubtle = Color(0xFF64748B);

  // ── Shadows ───────────────────────────────────────────────────────────────
  static const Color shadow = Color(0x14000000);

  // ── Status Colors ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
}
