import '../../core/theme/app_colors.dart';
// Theme Gallery screen with live previews and material cards (PRD Section 88)

import 'package:flutter/material.dart';
import '../../core/audio/asmr_audio_engine.dart';
import '../../game/game_coordinator.dart';
import '../../core/theme/game_theme.dart';
import '../widgets/pixar_3d_widgets.dart';

class ThemeGalleryScreen extends StatelessWidget {
  final GameCoordinator coordinator;

  const ThemeGalleryScreen({super.key, required this.coordinator});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: coordinator,
      builder: (context, _) {
        final currentTheme = coordinator.theme;
        final highScore = coordinator.state.highScore;
        final streak = coordinator.streakInfo.streakCount;
        final unlockedThemes = GameTheme.allThemes.where((t) {
          return t.isUnlocked(
            highScore: highScore,
            streak: streak,
            unlockedIds: coordinator.unlockedThemeIds,
          );
        }).toList();

        return Scaffold(
          backgroundColor: currentTheme.backgroundEnd,
          appBar: Pixar3DAppBar(
            title: 'THEME GALLERY',
            accentColor: currentTheme.accent,
            onBack: () => Navigator.of(context).pop(),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [currentTheme.backgroundStart, currentTheme.backgroundEnd],
              ),
            ),
            child: SafeArea(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // Top Pixar 3D Theme Progress Showcase Card
                  Pixar3DCard(
                    baseColor: Colors.white,
                    gradientEnd: const Color(0xFFF8FAFC),
                    accentColor: currentTheme.accent,
                    borderRadius: 22,
                    depth: 4.5,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: currentTheme.accent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: currentTheme.accent.withValues(alpha: 0.6),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.palette_rounded,
                                    color: currentTheme.accent,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'SKIN COLLECTION',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Active: ${currentTheme.name}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: currentTheme.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                              ),
                              child: Text(
                                '${unlockedThemes.length} / ${GameTheme.allThemes.length} UNLOCKED',
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Pixar3DProgressBar(
                          progress: unlockedThemes.length / GameTheme.allThemes.length,
                          fillColor: currentTheme.accent,
                          height: 10,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Section Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'AVAILABLE PALETTES & SOUNDSCAPES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFCBD5E1),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Themes List
                  for (final theme in GameTheme.allThemes) ...[
                    Builder(builder: (context) {
                      final isSelected = theme.id == currentTheme.id;
                      final isUnlocked = theme.isUnlocked(
                        highScore: highScore,
                        streak: streak,
                        unlockedIds: coordinator.unlockedThemeIds,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Pixar3DCard(
                          baseColor: isSelected
                              ? Colors.white
                              : (isUnlocked ? Colors.white : const Color(0xFFF8FAFC)),
                          gradientEnd: isSelected
                              ? Color.lerp(Colors.white, theme.accent, 0.08)!
                              : const Color(0xFFF1F5F9),
                          accentColor: isSelected
                              ? theme.accent
                              : (isUnlocked ? theme.accent.withValues(alpha: 0.5) : const Color(0xFF94A3B8)),
                          depth: isSelected ? 5.5 : 4.0,
                          borderRadius: 22,
                          padding: const EdgeInsets.all(18),
                          borderColor: isSelected
                              ? theme.accent
                              : (isUnlocked ? AppColors.border : AppColors.borderSubtle),
                          extrusionColor: isSelected
                              ? Color.lerp(const Color(0xFFCBD5E1), theme.accent, 0.3)!
                              : null,
                          onTap: () {
                            if (!isUnlocked) {
                              AsmrAudioEngine.instance.playPixarPop(pitch: 0.7);
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Locked! Requirement: ${theme.unlockRequirementText}'),
                                  backgroundColor: const Color(0xFF1E293B),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            AsmrAudioEngine.instance.playPixarSparkle();
                            coordinator.setTheme(theme);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Theme Icon Emblem
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: (isUnlocked ? theme.accent : const Color(0xFF64748B)).withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: (isUnlocked ? theme.accent : const Color(0xFF64748B)).withValues(alpha: 0.7),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        if (isUnlocked)
                                          BoxShadow(
                                            color: theme.accent.withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isUnlocked ? theme.icon : Icons.lock_rounded,
                                        color: isUnlocked ? theme.accent : const Color(0xFF94A3B8),
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                theme.name,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      theme.accent,
                                                      HSLColor.fromColor(theme.accent).withLightness(0.45).toColor(),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: theme.accent.withValues(alpha: 0.5),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF0F172A)),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'ACTIVE',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w900,
                                                        color: Color(0xFF0F172A),
                                                        letterSpacing: 0.8,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else if (!isUnlocked)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0F172A),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: const Color(0xFF334155)),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.lock, size: 11, color: Color(0xFF94A3B8)),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'LOCKED',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w900,
                                                        color: Color(0xFF94A3B8),
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isUnlocked
                                              ? '🎵 Sound Profile: ${theme.soundProfile.name.toUpperCase()} ASMR'
                                              : '🔒 Unlock: ${theme.unlockRequirementText}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isUnlocked
                                                ? const Color(0xFFCBD5E1)
                                                : const Color(0xFFFBBF24),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                theme.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUnlocked ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Pixar 3D Toy Block Palette Swatches
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      for (final color in theme.blockPalette.take(6))
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            color: HSLColor.fromColor(color).withLightness(0.22).toColor(),
                                            boxShadow: [
                                              if (isUnlocked)
                                                BoxShadow(
                                                  color: color.withValues(alpha: 0.45),
                                                  offset: const Offset(0, 3),
                                                  blurRadius: 4,
                                                ),
                                            ],
                                          ),
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 2.5),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  isUnlocked ? color : color.withValues(alpha: 0.35),
                                                  isUnlocked
                                                      ? HSLColor.fromColor(color).withLightness(0.35).toColor()
                                                      : color.withValues(alpha: 0.15),
                                                ],
                                              ),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: isUnlocked ? 0.65 : 0.2),
                                                width: 1.0,
                                              ),
                                            ),
                                            child: isUnlocked
                                                ? Align(
                                                    alignment: Alignment.topLeft,
                                                    child: Container(
                                                      margin: const EdgeInsets.all(2.0),
                                                      width: 5,
                                                      height: 3,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withValues(alpha: 0.8),
                                                        borderRadius: BorderRadius.circular(2),
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (isUnlocked && !isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: theme.accent.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: theme.accent.withValues(alpha: 0.5), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.touch_app_rounded, size: 12, color: theme.accent),
                                          const SizedBox(width: 4),
                                          Text(
                                            'TAP TO USE',
                                            style: TextStyle(
                                              color: theme.accent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
