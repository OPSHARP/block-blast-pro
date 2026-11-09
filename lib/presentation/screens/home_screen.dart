// Home Screen launcher with instant resume, game mode cards, and navigation shortcuts

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/audio/asmr_audio_engine.dart';
import '../../game/game_coordinator.dart';
import '../../domain/models/game_mode.dart';
import '../../domain/models/rank_tier.dart';
import '../../domain/services/streak_service.dart';
import '../../core/update/in_app_update_service.dart';
import 'game_screen.dart';
import 'daily_challenge_screen.dart';
import 'theme_gallery_screen.dart';
import 'achievements_screen.dart';
import 'rank_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/pixar_3d_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final GameCoordinator coordinator;
  final InAppUpdateService? updateService;

  const HomeScreen({
    super.key,
    required this.coordinator,
    this.updateService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // 1. Google Play Games auto-login prompt on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final hasPromptedPlayGames = prefs.getBool('play_games_first_launch_prompted') ?? false;
        if (!hasPromptedPlayGames) {
          await prefs.setBool('play_games_first_launch_prompted', true);
          if (mounted && !widget.coordinator.playGamesService.isAuthenticated) {
            // Wait 1200ms so initial entrance animations settle, then prompt Play Games sign-in
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (mounted && !widget.coordinator.playGamesService.isAuthenticated) {
                widget.coordinator.playGamesService.signIn();
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Play Games first open auto login non-fatal: $e');
      }
    });

    // 2. Safely trigger flexible in-app update check after first frame is drawn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          try {
            widget.updateService?.checkForUpdate(
              onUpdateDownloaded: () {
                if (mounted) {
                  widget.updateService?.showUpdateSnackbar(context);
                }
              },
            );
          } catch (_) {}
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = widget.coordinator;
    return ListenableBuilder(
      listenable: coordinator,
      builder: (context, _) {
        final theme = coordinator.theme;
        final state = coordinator.state;
        final currentTier = RankTier.fromScore(state.highScore);

        return Scaffold(
          backgroundColor: theme.backgroundEnd,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.backgroundStart, theme.backgroundEnd],
              ),
            ),
            child: SafeArea(
              top: true,
              bottom: true,
              left: true,
              right: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar with Animated App Name & Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _AnimatedAppNameBadge(accentColor: theme.accent),
                        Row(
                          children: [
                            // No Ads Button / Status Badge
                            ListenableBuilder(
                              listenable: coordinator.billingService,
                              builder: (context, _) {
                                final isRemoved = coordinator.billingService.isAdsRemoved;
                                return InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => SettingsScreen(coordinator: coordinator),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isRemoved
                                            ? const Color(0xFF10B981)
                                            : theme.accent,
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isRemoved ? Icons.verified : Icons.block,
                                          size: 13,
                                          color: isRemoved ? const Color(0xFF10B981) : theme.accent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isRemoved ? 'NO ADS' : 'REMOVE ADS',
                                          style: TextStyle(
                                            color: isRemoved ? const Color(0xFF10B981) : theme.accent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            ListenableBuilder(
                              listenable: coordinator.playGamesService,
                              builder: (context, _) {
                                final isSignedIn = coordinator.playGamesService.isAuthenticated;
                                return GestureDetector(
                                  onTap: () {
                                    AsmrAudioEngine.instance.playPixarPop();
                                    Navigator.of(context).push(
                                      PixarPageRoute(
                                        page: RankScreen(coordinator: coordinator),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: isSignedIn ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isSignedIn ? const Color(0xFF10B981) : Colors.black)
                                              .withValues(alpha: isSignedIn ? 0.25 : 0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.sports_esports_rounded,
                                        size: 19,
                                        color: isSignedIn ? const Color(0xFF10B981) : const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                AsmrAudioEngine.instance.playPixarPop();
                                Navigator.of(context).push(
                                  PixarPageRoute(
                                    page: SettingsScreen(coordinator: coordinator),
                                  ),
                                );
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.settings_rounded,
                                    size: 19,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Pixar 3D Interactive Hero Block Grid with Live Bouncy Characters
                    const Pixar3DHeroGrid(),

                    const SizedBox(height: 14),

                    // Game Title & 3D Logo
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'BLOCK BLAST',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                              color: const Color(0xFF0F172A),
                              shadows: [
                                const Shadow(
                                  offset: Offset(0, 3),
                                  blurRadius: 0,
                                  color: Color(0xFF38BDF8),
                                ),
                                const Shadow(
                                  offset: Offset(0, 5),
                                  blurRadius: 0,
                                  color: Color(0xFF0284C7),
                                ),
                                Shadow(
                                  offset: const Offset(0, 8),
                                  blurRadius: 16,
                                  color: Colors.black.withValues(alpha: 0.12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD600), Color(0xFFFF9100)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9100).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.2),
                            ),
                            child: const Text(
                              '✨ P R O ✨',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF3E2723),
                                letterSpacing: 3.5,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                PixarPageRoute(
                                  page: RankScreen(coordinator: coordinator),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              margin: const EdgeInsets.only(top: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: currentTier.primaryColor.withValues(alpha: 0.6)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(currentTier.emoji, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    currentTier.fullTitle(state.highScore).toUpperCase(),
                                    style: TextStyle(
                                      color: currentTier.primaryColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '•  ${state.highScore} PTS',
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right, size: 15, color: currentTier.primaryColor),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Primary 3D Arcade Play / Resume Button
                    Pixar3DButton(
                      primaryColor: const Color(0xFFFFD600),
                      secondaryColor: const Color(0xFFFF6D00),
                      height: 64,
                      borderRadius: 22,
                      depth: 6,
                      onTap: () {
                        if (state.isGameOver) {
                          coordinator.startNewGame(mode: GameMode.classic);
                        }
                        Navigator.of(context).pushReplacement(
                          PixarPageRoute(
                            page: GameScreen(coordinator: coordinator),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, size: 36, color: Color(0xFF3E2723)),
                          const SizedBox(width: 8),
                          Text(
                            state.isGameOver || state.score == 0 ? 'PLAY CLASSIC' : 'RESUME GAME',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Day 1-7 Retention Streak Progression Card
                    _buildStreakProgressionCard(
                      context: context,
                      coordinator: coordinator,
                      theme: theme,
                    ),

                    const SizedBox(height: 24),

                    // Game Modes Grid
                    Text(
                      'GAME MODES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildModeCard(
                            context: context,
                            title: 'Dynamic Grid',
                            subtitle: 'Shifting board',
                            icon: Icons.sync_alt,
                            accent: const Color(0xFF38BDF8),
                            badge: 'SHIFTING',
                            onTap: () {
                              coordinator.startNewGame(mode: GameMode.dynamicGrid);
                              Navigator.of(context).pushReplacement(
                                PixarPageRoute(
                                  page: GameScreen(coordinator: coordinator),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModeCard(
                            context: context,
                            title: 'Heavy Physics',
                            subtitle: 'Weight & shockwaves',
                            icon: Icons.fitness_center,
                            accent: const Color(0xFFF59E0B),
                            badge: 'PHYSICS',
                            onTap: () {
                              coordinator.startNewGame(mode: GameMode.heavyPhysics);
                              Navigator.of(context).pushReplacement(
                                PixarPageRoute(
                                  page: GameScreen(coordinator: coordinator),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildModeCard(
                            context: context,
                            title: 'Zen Mode',
                            subtitle: 'Infinite relaxation',
                            icon: Icons.spa_outlined,
                            accent: const Color(0xFF10B981),
                            badge: 'RELAX',
                            onTap: () {
                              coordinator.startNewGame(mode: GameMode.zen);
                              Navigator.of(context).pushReplacement(
                                PixarPageRoute(
                                  page: GameScreen(coordinator: coordinator),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModeCard(
                            context: context,
                            title: 'Daily Challenge',
                            subtitle: 'New daily objective',
                            icon: Icons.calendar_today_outlined,
                            accent: const Color(0xFFEC4899),
                            badge: 'QUEST',
                            onTap: () {
                              Navigator.of(context).push(
                                PixarPageRoute(
                                  page: DailyChallengeScreen(coordinator: coordinator),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Pixar3DCard(
                            baseColor: Colors.white,
                            gradientEnd: const Color(0xFFF0FDFA),
                            accentColor: const Color(0xFF06B6D4),
                            borderColor: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                            extrusionColor: const Color(0xFFCBD5E1),
                            borderRadius: 18,
                            depth: 4.5,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            onTap: () {
                              coordinator.startNewGame(mode: GameMode.blitz);
                              Navigator.of(context).pushReplacement(
                                PixarPageRoute(
                                  page: GameScreen(coordinator: coordinator),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF00E5FF), width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.bolt, color: Color(0xFF0284C7), size: 26),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '⚡ BLITZ ATTACK',
                                        style: TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'High-octane time rush • Clear lines for +2.5s bonus',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    '60s RUSH',
                                    style: TextStyle(
                                      color: Color(0xFF002244),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildModeCard(
                            context: context,
                            title: 'Adventure',
                            subtitle: 'Journey milestones',
                            icon: Icons.map_outlined,
                            accent: const Color(0xFFA855F7),
                            badge: 'JOURNEY',
                            onTap: () {
                              coordinator.startNewGame(mode: GameMode.adventure);
                              Navigator.of(context).pushReplacement(
                                PixarPageRoute(
                                  page: GameScreen(coordinator: coordinator),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModeCard(
                            context: context,
                            title: 'Rising Lava',
                            subtitle: 'Survive the surge',
                            icon: Icons.local_fire_department_outlined,
                            accent: const Color(0xFFFF5722),
                            badge: 'SURVIVAL',
                            onTap: () {
                              coordinator.startNewGame(mode: GameMode.lava);
                              Navigator.of(context).pushReplacement(
                                PixarPageRoute(
                                  page: GameScreen(coordinator: coordinator),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Quick Navigation Hub
                    Text(
                      'EXPLORATION & PROGRESS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Pixar3DNavTile(
                            icon: Icons.palette_rounded,
                            label: 'Themes',
                            color: const Color(0xFF8B5CF6),
                            onTap: () {
                              Navigator.of(context).push(
                                PixarPageRoute(
                                  page: ThemeGalleryScreen(coordinator: coordinator),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Pixar3DNavTile(
                            icon: Icons.military_tech_rounded,
                            label: 'Badges',
                            color: const Color(0xFFEC4899),
                            onTap: () {
                              Navigator.of(context).push(
                                PixarPageRoute(
                                  page: AchievementsScreen(coordinator: coordinator),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Pixar3DNavTile(
                            icon: Icons.leaderboard_rounded,
                            label: 'Ranks',
                            color: const Color(0xFFF59E0B),
                            onTap: () {
                              Navigator.of(context).push(
                                PixarPageRoute(
                                  page: RankScreen(coordinator: coordinator),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Pixar3DNavTile(
                            icon: Icons.insights_rounded,
                            label: 'Stats',
                            color: const Color(0xFF10B981),
                            onTap: () {
                              Navigator.of(context).push(
                                PixarPageRoute(
                                  page: StatisticsScreen(coordinator: coordinator),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Bottom AdMob Banner
                    AdBannerWidget(adService: coordinator.adService),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Pixar3DCard(
      baseColor: Colors.white,
      gradientEnd: const Color(0xFFF8FAFC),
      borderColor: accent.withValues(alpha: 0.35),
      extrusionColor: const Color(0xFFCBD5E1),
      accentColor: accent,
      borderRadius: 18,
      depth: 4.5,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accent.withValues(alpha: 0.5), width: 0.8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: accent,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakProgressionCard({
    required BuildContext context,
    required GameCoordinator coordinator,
    required dynamic theme,
  }) {
    final streak = coordinator.streakInfo;
    final currentDay = streak.currentCycleDay;
    final isClaimable = streak.isClaimableToday;
    final reward = StreakService.getRewardForDay(currentDay);

    return Pixar3DCard(
      baseColor: Colors.white,
      gradientEnd: const Color(0xFFF8FAFC),
      borderColor: const Color(0xFFE2E8F0),
      extrusionColor: const Color(0xFFCBD5E1),
      accentColor: isClaimable ? const Color(0xFFF59E0B) : const Color(0xFF0284C7),
      borderRadius: 20,
      depth: 4.5,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${streak.streakCount} DAY STREAK',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Day $currentDay of 7 • Free Power-ups & Boosters',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.casino_outlined, size: 12, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              '${coordinator.freeRerolls}',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEC4899), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite, size: 12, color: Color(0xFFEC4899)),
                            const SizedBox(width: 4),
                            Text(
                              '${coordinator.freeRevives}',
                              style: const TextStyle(
                                color: Color(0xFFEC4899),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.gavel, size: 12, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 4),
                            Text(
                              '${coordinator.freeHammers}',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3D00).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFF3D00), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, size: 12, color: Color(0xFFFF3D00)),
                            const SizedBox(width: 4),
                            Text(
                              '${coordinator.freeTnts}',
                              style: const TextStyle(
                                color: Color(0xFFFF3D00),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.rotate_right, size: 12, color: Color(0xFF00E5FF)),
                            const SizedBox(width: 4),
                            Text(
                              '${coordinator.freeRotates}',
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.undo, size: 12, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(
                              '${coordinator.freeUndos}',
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Day 1-7 Cycle Track
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (idx) {
              final dayNum = idx + 1;
              final isPassed = (!isClaimable && dayNum <= currentDay) || (isClaimable && dayNum < currentDay);
              final isToday = dayNum == currentDay;
              final dayReward = StreakService.getRewardForDay(dayNum);

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: idx == 6 ? 0 : 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isPassed
                        ? const Color(0xFFD1FAE5)
                        : (isToday
                            ? (isClaimable
                                ? const Color(0xFFFEF3C7)
                                : theme.accent.withValues(alpha: 0.15))
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPassed
                          ? const Color(0xFF10B981)
                          : (isToday
                              ? (isClaimable ? const Color(0xFFF59E0B) : theme.accent)
                              : const Color(0xFFCBD5E1)),
                      width: isToday ? 1.8 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'D$dayNum',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isPassed
                              ? const Color(0xFF065F46)
                              : (isToday
                                  ? (isClaimable ? const Color(0xFFB45309) : theme.accent)
                                  : const Color(0xFF475569)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        dayNum == 7
                            ? Icons.stars_rounded
                            : (dayReward.bonusRevives > 0
                                ? Icons.favorite_rounded
                                : (dayReward.bonusHammers > 0 ? Icons.gavel_rounded : Icons.casino_rounded)),
                        size: 15,
                        color: isPassed
                            ? const Color(0xFF059669)
                            : (isToday
                                ? (isClaimable ? const Color(0xFFD97706) : theme.accent)
                                : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Action Button / Status
          if (isClaimable) ...[
            Pixar3DButton(
              primaryColor: const Color(0xFFFFB300),
              secondaryColor: const Color(0xFFFF6F00),
              height: 48,
              borderRadius: 14,
              depth: 3.5,
              onTap: () {
                coordinator.claimDailyStreakReward();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_giftcard, size: 18, color: Color(0xFF1F1300)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'CLAIM DAY $currentDay: ${reward.description.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Color(0xFF1F1300),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF34D399)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Today\'s reward claimed! Day ${currentDay < 7 ? currentDay + 1 : 1} unlocks tomorrow.',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF34D399),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Animated 3D App Name Badge for Top-Left Corner
class _AnimatedAppNameBadge extends StatefulWidget {
  final Color accentColor;

  const _AnimatedAppNameBadge({required this.accentColor});

  @override
  State<_AnimatedAppNameBadge> createState() => _AnimatedAppNameBadgeState();
}

class _AnimatedAppNameBadgeState extends State<_AnimatedAppNameBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Color.lerp(Colors.white, widget.accentColor, 0.12)!,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.accentColor.withValues(alpha: 0.4 + 0.4 * _glowAnimation.value),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: widget.accentColor.withValues(alpha: 0.2 * _glowAnimation.value),
                  blurRadius: 8 * _glowAnimation.value,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 18,
                ),
                const SizedBox(width: 5),
                ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [
                        const Color(0xFF0F172A),
                        Color.lerp(const Color(0xFF0F172A), widget.accentColor, _glowAnimation.value)!,
                        widget.accentColor,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'BLOCK BLAST PRO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
