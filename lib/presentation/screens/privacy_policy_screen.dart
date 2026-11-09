// Privacy Policy Screen for Block Blast Pro
// Compliant with Google Play Developer Policy, Data Safety, and COPPA Guidelines

import 'package:flutter/material.dart';
import '../../core/audio/asmr_audio_engine.dart';
import '../../game/game_coordinator.dart';
import '../widgets/pixar_3d_widgets.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final GameCoordinator coordinator;

  const PrivacyPolicyScreen({super.key, required this.coordinator});

  @override
  Widget build(BuildContext context) {
    final theme = coordinator.theme;

    return Scaffold(
      backgroundColor: theme.backgroundEnd,
      appBar: Pixar3DAppBar(
        title: 'PRIVACY POLICY',
        accentColor: theme.accent,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.backgroundStart,
              theme.backgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: theme.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.accent.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            'Effective Date: October 2026 • Version 1.0.2',
                            style: TextStyle(
                              color: theme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Introduction card
                      _buildPolicyCard(
                        icon: Icons.shield_rounded,
                        iconColor: theme.accent,
                        title: '1. Commitment to Your Privacy',
                        content:
                            'Block Blast Pro ("we", "our", or "the Game") respects and protects your privacy. '
                            'This Privacy Policy explains how your information is handled when you download, install, and play Block Blast Pro. '
                            'We do NOT collect, sell, or trade any personal identifying information (such as your real name, address, or phone number).',
                      ),
                      const SizedBox(height: 14),

                      // Local Data & Game Progress card
                      _buildPolicyCard(
                        icon: Icons.storage_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: '2. Local Game Storage',
                        content:
                            'All gameplay data—including your high scores, best combos, current board state, theme preferences, audio settings, '
                            'and power-up inventory—is stored locally on your device via encrypted local preferences.\n\n'
                            '• Your game progress never leaves your device unless you explicitly opt in to Google Play Games cloud synchronization.\n'
                            '• You can reset all local progress at any time through the "Start Fresh Game" button in Settings or by clearing app storage in device settings.',
                      ),
                      const SizedBox(height: 14),

                      // Advertising & AdMob card
                      _buildPolicyCard(
                        icon: Icons.ads_click_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: '3. Advertising (Google AdMob)',
                        content:
                            'Block Blast Pro is supported by advertisements provided by Google Mobile Ads (AdMob). '
                            'AdMob may collect and process pseudonymous identifiers to serve relevant ads:\n\n'
                            '• Google Advertising ID (AD_ID) for frequency capping, ad delivery, and fraud detection\n'
                            '• Coarse diagnostic and ad interaction metrics\n'
                            '• Users can reset or opt out of personalized ads at any time via Android Settings → Google → Ads.\n'
                            '• Ads can be completely removed from the game via the "Remove Ads" monthly subscription (\$4.99 / month, cancel anytime).',
                      ),
                      const SizedBox(height: 14),

                      // Google Play Services & Leaderboards card
                      _buildPolicyCard(
                        icon: Icons.sports_esports_rounded,
                        iconColor: const Color(0xFF38BDF8),
                        title: '4. Google Play Games Services',
                        content:
                            'The Game offers optional integration with Google Play Games Services for global leaderboards and achievements:\n\n'
                            '• Connection is purely voluntary. The game does NOT require a login or account to play.\n'
                            '• If connected, your Google Play gamer tag and avatar may be displayed on global high score leaderboards.\n'
                            '• Authentication and profile data are managed directly by Google under the Google Privacy Policy (policies.google.com/privacy).',
                      ),
                      const SizedBox(height: 14),

                      // In-App Purchases card
                      _buildPolicyCard(
                        icon: Icons.shopping_bag_rounded,
                        iconColor: const Color(0xFFA855F7),
                        title: '5. In-App Purchases & Billing',
                        content:
                            'All in-app purchases (such as the \$4.99 / month "Remove Ads" subscription) are processed securely through the Google Play In-App Billing system.\n\n'
                            '• We do NOT collect, process, or store credit card numbers, banking details, or billing addresses.\n'
                            '• Google Play securely manages transaction authorization, order fulfillment, and purchase restoration across your devices.\n'
                            '• Subscriptions auto-renew monthly and can be cancelled at any time through Google Play Store → Subscriptions.',
                      ),
                      const SizedBox(height: 14),

                      // Children's Privacy card
                      _buildPolicyCard(
                        icon: Icons.family_restroom_rounded,
                        iconColor: const Color(0xFFEC4899),
                        title: '6. Children\'s Privacy (COPPA & Play Families)',
                        content:
                            'Block Blast Pro complies with the Children\'s Online Privacy Protection Act (COPPA), GDPR-K, and the Google Play Families Policy.\n\n'
                            '• We do not knowingly collect personal information from children under 13.\n'
                            '• Ad requests in the app are configured to adhere to Google Mobile Ads child-directed and consent standards.',
                      ),
                      const SizedBox(height: 14),

                      // Security & Retention card
                      _buildPolicyCard(
                        icon: Icons.lock_rounded,
                        iconColor: const Color(0xFF06B6D4),
                        title: '7. Data Security & Retention',
                        content:
                            'We implement strict sandboxing and security measures to protect your game data. '
                            'Because we do not operate remote user account servers, we do not retain or store any user credentials or personal profiles.',
                      ),
                      const SizedBox(height: 14),

                      // Developer Contact card
                      _buildPolicyCard(
                        icon: Icons.contact_support_rounded,
                        iconColor: const Color(0xFF6366F1),
                        title: '8. Contact Information',
                        content:
                            'If you have any questions, concerns, or requests regarding this Privacy Policy or your data, please contact our support team:\n\n'
                            '• Enterprise: SHARP OP (Nitesh Kumar)\n'
                            '• Support Email: drillmovies@gmail.com\n'
                            '• Support Phone: +91 9557754705\n'
                            '• Address: Bilsuri, Sikandrabad, Bulandshahr, UP 203205, India\n'
                            '• Response Time: Within 24–48 business hours',
                      ),
                      const SizedBox(height: 20),

                      // Pixar 3D Close / Back button
                      Pixar3DButton(
                        primaryColor: const Color(0xFF34D399),
                        secondaryColor: const Color(0xFF059669),
                        height: 56,
                        borderRadius: 18,
                        depth: 4.5,
                        onTap: () {
                          AsmrAudioEngine.instance.playPixarPop();
                          Navigator.of(context).pop();
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF064E3B), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'I UNDERSTAND & ACCEPT',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: Color(0xFF064E3B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Pixar3DCard(
      baseColor: const Color(0xFF1E293B),
      gradientEnd: const Color(0xFF0F172A),
      borderColor: iconColor.withValues(alpha: 0.4),
      depth: 4.0,
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor.withValues(alpha: 0.5), width: 1.2),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
