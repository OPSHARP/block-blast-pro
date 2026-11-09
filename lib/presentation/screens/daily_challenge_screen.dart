// Daily Challenge screen according to PRD Section 85 with Pixar 3D Suite

import 'package:flutter/material.dart';
import '../../core/audio/asmr_audio_engine.dart';
import '../../game/game_coordinator.dart';
import '../../domain/models/game_mode.dart';
import '../widgets/pixar_3d_widgets.dart';
import 'game_screen.dart';

class DailyChallengeScreen extends StatelessWidget {
  final GameCoordinator coordinator;

  const DailyChallengeScreen({super.key, required this.coordinator});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: coordinator,
      builder: (context, _) {
        final challenge = coordinator.currentDailyChallenge;
        final theme = coordinator.theme;

        return Scaffold(
          backgroundColor: theme.backgroundEnd,
          appBar: Pixar3DAppBar(
            title: 'DAILY QUEST',
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
              child: challenge == null
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 32,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Date & Seed Header Pill
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: theme.accent.withValues(alpha: 0.4), width: 1.4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('📅', style: TextStyle(fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Column(
                                          children: [
                                            Text(
                                              challenge.dateString.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                color: theme.accent,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'QUEST SEED #${challenge.seed.toRadixString(16).toUpperCase()}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFFCBD5E1),
                                                letterSpacing: 0.8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Challenge Objective Pixar 3D Card
                                Pixar3DCard(
                                  borderRadius: 24,
                                  padding: const EdgeInsets.all(22),
                                  baseColor: challenge.isCompleted
                                      ? const Color(0xFF0D281E)
                                      : const Color(0xFF1E293B),
                                  gradientEnd: challenge.isCompleted
                                      ? const Color(0xFF061A14)
                                      : const Color(0xFF0F172A),
                                  accentColor: challenge.isCompleted
                                      ? const Color(0xFF10B981)
                                      : theme.accent,
                                  borderColor: challenge.isCompleted
                                      ? const Color(0xFF10B981)
                                      : theme.accent.withValues(alpha: 0.6),
                                  extrusionColor: challenge.isCompleted
                                      ? const Color(0xFF064E3B)
                                      : theme.accent.withValues(alpha: 0.3),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: challenge.isCompleted
                                                ? [const Color(0xFF34D399), const Color(0xFF059669)]
                                                : [theme.accent, HSLColor.fromColor(theme.accent).withLightness(0.4).toColor()],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (challenge.isCompleted
                                                      ? const Color(0xFF10B981)
                                                      : theme.accent)
                                                  .withValues(alpha: 0.45),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            challenge.isCompleted
                                                ? Icons.check_circle_rounded
                                                : Icons.emoji_events_rounded,
                                            size: 38,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        challenge.title,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        challenge.description,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFFCBD5E1),
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // 3D Progress Bar
                                      Pixar3DProgressBar(
                                        progress: (challenge.currentProgress / challenge.targetValue).clamp(0.0, 1.0),
                                        fillColor: challenge.isCompleted
                                            ? const Color(0xFF10B981)
                                            : theme.accent,
                                        height: 12,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Progress: ${challenge.currentProgress} / ${challenge.targetValue}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFCBD5E1),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (challenge.isCompleted
                                                      ? const Color(0xFF10B981)
                                                      : theme.accent)
                                                  .withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: challenge.isCompleted
                                                    ? const Color(0xFF10B981)
                                                    : theme.accent,
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Text(
                                              challenge.isCompleted ? 'COMPLETED 🎉' : 'IN PROGRESS ⏳',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: challenge.isCompleted
                                                    ? const Color(0xFF34D399)
                                                    : theme.accent,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Reward Banner Pixar 3D Card
                                Pixar3DCard(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                  borderRadius: 20,
                                  baseColor: const Color(0xFF1E293B),
                                  gradientEnd: const Color(0xFF0F172A),
                                  borderColor: const Color(0xFFFFD700).withValues(alpha: 0.7),
                                  extrusionColor: const Color(0xFFB45309).withValues(alpha: 0.4),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                              blurRadius: 8,
                                            ),
                                          ],
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                        child: const Icon(Icons.card_giftcard, color: Color(0xFF78350F), size: 24),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'QUEST REWARD',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFFFFD700),
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            Text(
                                              challenge.rewardName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (challenge.bestScore > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Best: ${challenge.bestScore}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFFCBD5E1),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const Spacer(),
                                const SizedBox(height: 24),

                                // Chunky 3D Arcade Play Button
                                Pixar3DButton(
                                  primaryColor: challenge.isCompleted
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFFFFD600),
                                  secondaryColor: challenge.isCompleted
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFFF6D00),
                                  height: 62,
                                  borderRadius: 20,
                                  depth: 5.5,
                                  onTap: () {
                                    AsmrAudioEngine.instance.playPixarBoing();
                                    coordinator.startNewGame(
                                      mode: GameMode.dailyChallenge,
                                      customSeed: challenge.seed,
                                    );
                                    Navigator.of(context).pushReplacement(
                                      PixarPageRoute(
                                        page: GameScreen(coordinator: coordinator),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        challenge.isCompleted ? Icons.replay_rounded : Icons.play_arrow_rounded,
                                        size: 28,
                                        color: const Color(0xFF1F1300),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        challenge.isCompleted ? 'PLAY AGAIN' : 'START DAILY QUEST',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                          color: Color(0xFF1F1300),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
