import '../../core/theme/app_colors.dart';
// Statistics and 6-axis Player Skill Profile screen with Pixar 3D UI

import 'package:flutter/material.dart';
import '../../core/audio/asmr_audio_engine.dart';
import '../../game/game_coordinator.dart';
import '../../domain/models/rank_tier.dart';
import '../widgets/skill_radar_chart.dart';
import '../widgets/pixar_3d_widgets.dart';

class StatisticsScreen extends StatefulWidget {
  final GameCoordinator coordinator;

  const StatisticsScreen({super.key, required this.coordinator});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, int> _lifetimeStats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await widget.coordinator.saveRepository.loadLifetimeStats();
    if (mounted) {
      setState(() {
        _lifetimeStats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.coordinator,
      builder: (context, _) {
        final profile = widget.coordinator.state.skillProfile;
        final theme = widget.coordinator.theme;

        final highScore = widget.coordinator.state.highScore;
        final tier = RankTier.fromScore(highScore);
        final rankTier = '${tier.emoji} ${tier.fullTitle(highScore).toUpperCase()}';
        final rating = profile.overallSkillRating;

        return Scaffold(
          backgroundColor: theme.backgroundEnd,
          appBar: Pixar3DAppBar(
            title: 'PLAYER STATS & PROFILE',
            accentColor: theme.accent,
            onBack: () => Navigator.of(context).pop(),
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Skill Rating Pixar 3D Card
                    Pixar3DCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(22),
                      baseColor: Colors.white,
                      gradientEnd: const Color(0xFFF8FAFC),
                      accentColor: theme.accent,
                      borderColor: theme.accent.withValues(alpha: 0.6),
                      extrusionColor: theme.accent.withValues(alpha: 0.3),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: tier.gradientColors,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: tier.primaryColor.withValues(alpha: 0.45),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 1.2),
                            ),
                            child: Text(
                              rankTier,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('⭐', style: TextStyle(fontSize: 26)),
                              const SizedBox(width: 8),
                              Text(
                                '$rating',
                                style: const TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -1.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      offset: Offset(0, 4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('⭐', style: TextStyle(fontSize: 26)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'OVERALL SKILL RATING',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Radar Chart Pixar 3D Card
                    Pixar3DCard(
                      borderRadius: 24,
                      baseColor: Colors.white,
                      gradientEnd: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('📊', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 8),
                              Text(
                                '6-AXIS SKILL ATTRIBUTES',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: SkillRadarChart(
                              profile: profile,
                              accentColor: theme.accent,
                              size: 260,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Lifetime Stats Header
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Text('🏅', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            'LIFETIME METRICS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textTertiary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Lifetime Metric Cards (Candy 3D Gradients)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            icon: '🏆',
                            title: 'HIGHEST SCORE',
                            value: '${_lifetimeStats['highestScore'] ?? widget.coordinator.state.highScore}',
                            gradientColors: const [Color(0xFF38BDF8), Color(0xFF0284C7)],
                            accentColor: const Color(0xFF38BDF8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            icon: '⚡',
                            title: 'MAX COMBO',
                            value: '${_lifetimeStats['highestCombo'] ?? 0}x',
                            gradientColors: const [Color(0xFFFBBF24), Color(0xFFD97706)],
                            accentColor: const Color(0xFFFBBF24),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            icon: '🧱',
                            title: 'LINES CLEARED',
                            value: '${_lifetimeStats['totalClears'] ?? 0}',
                            gradientColors: const [Color(0xFF34D399), Color(0xFF059669)],
                            accentColor: const Color(0xFF34D399),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            icon: '🎮',
                            title: 'GAMES PLAYED',
                            value: '${_lifetimeStats['totalGames'] ?? 0}',
                            gradientColors: const [Color(0xFFF472B6), Color(0xFFDB2777)],
                            accentColor: const Color(0xFFF472B6),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String icon,
    required String title,
    required String value,
    required List<Color> gradientColors,
    required Color accentColor,
  }) {
    return Pixar3DCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      baseColor: Colors.white,
      gradientEnd: const Color(0xFFF8FAFC),
      borderColor: accentColor.withValues(alpha: 0.5),
      extrusionColor: accentColor.withValues(alpha: 0.25),
      onTap: () => AsmrAudioEngine.instance.playPixarPop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Text(icon, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: accentColor,
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  color: accentColor.withValues(alpha: 0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
