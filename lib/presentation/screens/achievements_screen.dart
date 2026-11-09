import '../../core/theme/app_colors.dart';
// Achievements and Badges screen according to PRD Section 86

import 'package:flutter/material.dart';
import '../../core/audio/asmr_audio_engine.dart';
import '../../game/game_coordinator.dart';
import '../../domain/models/achievement.dart';
import '../widgets/pixar_3d_widgets.dart';

class AchievementsScreen extends StatefulWidget {
  final GameCoordinator coordinator;

  const AchievementsScreen({super.key, required this.coordinator});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  AchievementCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.coordinator,
      builder: (context, _) {
        final achievements = widget.coordinator.achievements;
        final theme = widget.coordinator.theme;

        final filtered = _selectedCategory == null
            ? achievements
            : achievements.where((a) => a.category == _selectedCategory).toList();

        final unlockedCount = achievements.where((a) => a.isUnlocked).length;
        final totalProgress = achievements.isEmpty ? 0.0 : unlockedCount / achievements.length;

        return Scaffold(
          backgroundColor: theme.backgroundEnd,
          appBar: Pixar3DAppBar(
            title: 'ACHIEVEMENTS',
            accentColor: theme.accent,
            onBack: () => Navigator.of(context).pop(),
            actions: [
              IconButton(
                icon: const Icon(Icons.sports_esports_rounded, color: Colors.white),
                tooltip: 'Play Games Achievements',
                onPressed: () {
                  AsmrAudioEngine.instance.playPixarPop();
                  widget.coordinator.playGamesService.showAchievements();
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.backgroundStart, theme.backgroundEnd],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Pixar 3D Trophy Showcase Header Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Pixar3DCard(
                      baseColor: Colors.white,
                      gradientEnd: const Color(0xFFF8FAFC),
                      accentColor: theme.accent,
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
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.emoji_events_rounded, color: Color(0xFF78350F), size: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'TROPHY ROOM',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Unlock badges & earn boosters',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFCBD5E1),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: theme.accent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.accent, width: 1.2),
                                ),
                                child: Text(
                                  '$unlockedCount / ${achievements.length}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: theme.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Pixar3DProgressBar(
                            progress: totalProgress,
                            fillColor: theme.accent,
                            height: 10,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Category Selector Chips
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildCategoryChip('ALL', null, theme),
                        for (final cat in AchievementCategory.values)
                          _buildCategoryChip(cat.name.toUpperCase(), cat, theme),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Achievements List
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ach = filtered[index];
                        return _buildAchievementCard(ach, theme);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String label, AchievementCategory? category, dynamic theme) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        AsmrAudioEngine.instance.playPixarPop(pitch: 1.2);
        setState(() => _selectedCategory = category);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.accent,
                    HSLColor.fromColor(theme.accent).withLightness(0.4).toColor(),
                  ],
                )
              : null,
          color: isSelected ? null : const Color(0xFFF1F5F9),
          border: Border.all(
            color: isSelected ? Colors.white.withValues(alpha: 0.7) : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: theme.accent.withValues(alpha: 0.45),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement ach, dynamic theme) {
    final progressRatio = (ach.currentProgress / ach.targetValue).clamp(0.0, 1.0);

    return Pixar3DCard(
      baseColor: ach.isUnlocked
          ? const Color(0xFFF0FDF4)
          : Colors.white,
      gradientEnd: ach.isUnlocked
          ? Colors.white
          : const Color(0xFFF8FAFC),
      accentColor: ach.isUnlocked ? const Color(0xFF10B981) : theme.accent,
      borderRadius: 20,
      depth: 4.0,
      padding: const EdgeInsets.all(16),
      borderColor: ach.isUnlocked
          ? const Color(0xFF10B981)
          : AppColors.border,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (ach.isUnlocked ? const Color(0xFF10B981) : const Color(0xFF64748B)).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (ach.isUnlocked ? const Color(0xFF10B981) : const Color(0xFF64748B)).withValues(alpha: 0.7),
                width: 1.5,
              ),
              boxShadow: [
                if (ach.isUnlocked)
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Icon(
              ach.isUnlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
              color: ach.isUnlocked ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ach.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: ach.isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (ach.isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981), width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 12),
                            SizedBox(width: 4),
                            Text(
                              'UNLOCKED',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
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
                  ach.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Pixar3DProgressBar(
                  progress: progressRatio,
                  fillColor: ach.isUnlocked ? const Color(0xFF10B981) : theme.accent,
                  height: 8,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.accent.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Text(
                        '🎁 ${ach.reward}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: theme.accent,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Text(
                      '${ach.currentProgress} / ${ach.targetValue}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
