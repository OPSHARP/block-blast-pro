// Rating and Review Service for Block Blast Pro
// Handles intelligent, non-intrusive Google Play Store review prompts and redirection.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/play_games_constants.dart';
import '../theme/app_colors.dart';
import '../../presentation/widgets/pixar_3d_widgets.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  static const String _channelName = PlayGamesConstants.channelName;
  final MethodChannel _channel = const MethodChannel(_channelName);

  static const String keyHasRated = 'rating_has_rated';
  static const String keyNeverAsk = 'rating_never_ask_again';
  static const String keyGamesPlayed = 'rating_games_played_count';
  static const String keyLastPromptTimestamp = 'rating_last_prompt_timestamp';
  static const String keyDismissCount = 'rating_dismiss_count';
  static const String keyLastPromptGames = 'rating_last_prompt_games_count';

  /// Redirects the user directly to the Google Play Store app to rate this application.
  Future<bool> openPlayStore({String packageName = 'com.block.blastpro'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyHasRated, true);

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final success = await _channel.invokeMethod<bool>('openPlayStore', {
          'packageName': packageName,
        });
        return success ?? false;
      }
    } catch (e) {
      debugPrint('RatingService openPlayStore error: $e');
    }
    return false;
  }

  /// Increments the total games completed counter.
  Future<int> recordGameFinished() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(keyGamesPlayed) ?? 0;
      final updated = current + 1;
      await prefs.setInt(keyGamesPlayed, updated);
      return updated;
    } catch (e) {
      debugPrint('RatingService recordGameFinished error: $e');
      return 0;
    }
  }

  /// Determines whether the user should be prompted for a Play Store rating right now.
  Future<bool> shouldPromptRating({
    bool isNewHighScore = false,
    int score = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRated = prefs.getBool(keyHasRated) ?? false;
      if (hasRated) return false;

      final neverAsk = prefs.getBool(keyNeverAsk) ?? false;
      if (neverAsk) return false;

      final dismissCount = prefs.getInt(keyDismissCount) ?? 0;
      if (dismissCount >= 3) return false;

      final gamesPlayed = prefs.getInt(keyGamesPlayed) ?? 0;
      // Minimum 3 completed games before the first prompt ever
      if (gamesPlayed < 3) return false;

      final lastPromptTime = prefs.getInt(keyLastPromptTimestamp) ?? 0;
      final lastPromptGames = prefs.getInt(keyLastPromptGames) ?? 0;

      if (lastPromptTime > 0) {
        final daysSinceLastPrompt =
            DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastPromptTime)).inDays;
        final gamesSinceLastPrompt = gamesPlayed - lastPromptGames;

        // Cooldown: at least 4 days AND at least 8 games played since last prompt
        if (daysSinceLastPrompt < 4 || gamesSinceLastPrompt < 8) {
          return false;
        }
      }

      // High-dopamine triggers:
      // Trigger A: New personal high score (score >= 800)
      if (isNewHighScore && score >= 800) {
        return true;
      }

      // Trigger B: Major games played milestones (5, 15, 30 games)
      if (gamesPlayed == 5 || gamesPlayed == 15 || gamesPlayed == 30) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('RatingService shouldPromptRating error: $e');
      return false;
    }
  }

  /// Records that the rating prompt was displayed.
  Future<void> recordPromptShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gamesPlayed = prefs.getInt(keyGamesPlayed) ?? 0;
      await prefs.setInt(keyLastPromptTimestamp, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(keyLastPromptGames, gamesPlayed);
    } catch (e) {
      debugPrint('RatingService recordPromptShown error: $e');
    }
  }

  /// Records that the user dismissed or postponed the prompt.
  Future<void> recordDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(keyDismissCount) ?? 0;
      await prefs.setInt(keyDismissCount, current + 1);
    } catch (e) {
      debugPrint('RatingService recordDismissed error: $e');
    }
  }

  /// Sets never ask again preference.
  Future<void> setNeverAskAgain() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyNeverAsk, true);
    } catch (e) {
      debugPrint('RatingService setNeverAskAgain error: $e');
    }
  }

  /// Shows the Pixar 3D Light Mode Rating Dialog.
  Future<void> showRatingDialog(
    BuildContext context, {
    VoidCallback? onRated,
  }) async {
    await recordPromptShown();

    if (!context.mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _Pixar3DRatingDialog(
          ratingService: this,
          onRated: onRated,
        );
      },
    );
  }
}

class _Pixar3DRatingDialog extends StatefulWidget {
  final RatingService ratingService;
  final VoidCallback? onRated;

  const _Pixar3DRatingDialog({
    required this.ratingService,
    this.onRated,
  });

  @override
  State<_Pixar3DRatingDialog> createState() => _Pixar3DRatingDialogState();
}

class _Pixar3DRatingDialogState extends State<_Pixar3DRatingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Pixar3DCard(
        gradientColors: const [Colors.white, Color(0xFFF8FAFC)],
        borderColor: const Color(0xFFFBBF24),
        extrusion: 8,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pixar Character Block with Star Eyes
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF92400E),
                    offset: Offset(0, 5),
                    blurRadius: 1,
                  ),
                  BoxShadow(
                    color: Color(0x3DFBBF24),
                    offset: Offset(0, 10),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '★_★',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 5 Bouncing Golden Stars Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 400 + index * 120),
                    curve: Curves.elasticOut,
                    builder: (context, val, child) {
                      return Transform.scale(
                        scale: val,
                        child: const Icon(
                          Icons.star_rounded,
                          size: 32,
                          color: Color(0xFFF59E0B),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              'ENJOYING BLOCK BLAST PRO?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Your 5-star rating on Google Play keeps our game 100% free with new themes and smooth 120 FPS updates!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Primary Rate Button (Redirects to Google Play Store)
            Pixar3DButton(
              width: double.infinity,
              text: 'RATE ON GOOGLE PLAY',
              icon: Icons.star_rate_rounded,
              gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
              shadowColor: const Color(0xFF92400E),
              extrusion: 6,
              onPressed: () async {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
                await widget.ratingService.openPlayStore();
                widget.onRated?.call();
              },
            ),
            const SizedBox(height: 12),

            // Maybe Later Button
            Pixar3DButton(
              width: double.infinity,
              text: 'MAYBE LATER',
              gradientColors: const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
              shadowColor: const Color(0xFFCBD5E1),
              textColor: AppColors.textSecondary,
              extrusion: 4,
              onPressed: () async {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
                await widget.ratingService.recordDismissed();
              },
            ),
            const SizedBox(height: 8),

            // Subtle Don't Ask Again Link
            GestureDetector(
              onTap: () async {
                Navigator.of(context).pop();
                await widget.ratingService.setNeverAskAgain();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  "Don't ask again",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
