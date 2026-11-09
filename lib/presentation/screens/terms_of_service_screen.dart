// Terms of Service Screen for Block Blast Pro
// Compliant with Google Play Developer Policy and Indian IT Regulations

import 'package:flutter/material.dart';
import '../../core/audio/asmr_audio_engine.dart';
import '../../game/game_coordinator.dart';
import '../widgets/pixar_3d_widgets.dart';

class TermsOfServiceScreen extends StatelessWidget {
  final GameCoordinator coordinator;

  const TermsOfServiceScreen({super.key, required this.coordinator});

  @override
  Widget build(BuildContext context) {
    final theme = coordinator.theme;

    return Scaffold(
      backgroundColor: theme.backgroundEnd,
      appBar: Pixar3DAppBar(
        title: 'TERMS OF SERVICE',
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
                            'Effective Date: November 2026 • Version 1.0.2',
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

                      // Card 1: Agreement & Eligibility
                      _buildTermsCard(
                        icon: Icons.gavel_rounded,
                        iconColor: theme.accent,
                        title: '1. Agreement & Eligibility',
                        content:
                            'By downloading, installing, or playing Block Blast Pro, you enter into a legally binding agreement with SHARP OP (Proprietor: Nitesh Kumar).\n\n'
                            '• You must be at least 13 years of age (or 16 in certain jurisdictions) or have the consent of a parent or legal guardian.\n'
                            '• If you do not agree to these terms, please discontinue use and uninstall the application immediately.',
                      ),
                      const SizedBox(height: 14),

                      // Card 2: Operator Details
                      _buildTermsCard(
                        icon: Icons.business_rounded,
                        iconColor: const Color(0xFF38BDF8),
                        title: '2. Operator & Developer',
                        content:
                            'Block Blast Pro is developed and operated by SHARP OP, an enterprise registered in India under MSME Udyam Registration No. UDYAM-UP-18-0090815.\n\n'
                            '• Proprietor: Nitesh Kumar\n'
                            '• Official Telephone Contact: +91 9557754705\n'
                            '• Support Email: drillmovies@gmail.com\n'
                            '• Registered Location: Bulandshahr, Uttar Pradesh 203205, India',
                      ),
                      const SizedBox(height: 14),

                      // Card 3: License & Intellectual Property
                      _buildTermsCard(
                        icon: Icons.verified_user_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: '3. License & Intellectual Property',
                        content:
                            'We grant you a personal, revocable, non-exclusive, and non-transferable license to play the Game for personal entertainment.\n\n'
                            '• All code, artwork, audio tracks, ASMR compositions, skins, and game mechanics are the exclusive property of SHARP OP.\n'
                            '• You may not decompile, reverse-engineer, modify, redistribute, or extract source code from the Game.',
                      ),
                      const SizedBox(height: 14),

                      // Card 4: Fair Play Policy
                      _buildTermsCard(
                        icon: Icons.sports_esports_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: '4. Fair Play & Anti-Cheat',
                        content:
                            'Fair play is essential for our puzzle community. You agree not to:\n\n'
                            '• Use automation tools, bots, speed hacks, memory injectors, or modified APKs.\n'
                            '• Tamper with local save files, challenge salts, or leaderboards.\n'
                            '• Exploit glitches or bugs for artificial score inflation.\n\n'
                            'Violations may lead to immediate restriction or removal from connected leaderboards.',
                      ),
                      const SizedBox(height: 14),

                      // Card 5: In-App Purchases & Billing
                      _buildTermsCard(
                        icon: Icons.credit_card_rounded,
                        iconColor: const Color(0xFFA855F7),
                        title: '5. In-App Subscriptions & Billing',
                        content:
                            'We offer an optional "Remove Ads" monthly auto-renewing subscription (\$4.99 / month or local equivalent):\n\n'
                            '• All billing transactions are processed securely by Google Play In-App Billing.\n'
                            '• Subscriptions auto-renew monthly unless cancelled at least 24 hours before renewal.\n'
                            '• You can cancel anytime via Google Play Store → Payments & Subscriptions.\n'
                            '• Purchases can be restored across devices via the "Restore Purchases" button in Settings.',
                      ),
                      const SizedBox(height: 14),

                      // Card 6: Advertising & Rewarded Content
                      _buildTermsCard(
                        icon: Icons.ads_click_rounded,
                        iconColor: const Color(0xFFEC4899),
                        title: '6. Advertisements & Rewarded Ads',
                        content:
                            'Block Blast Pro is supported by Google Mobile Ads (AdMob) and Unity Ads mediation:\n\n'
                            '• Banners and interstitials appear during standard gameplay breaks.\n'
                            '• Rewarded video ads are entirely optional and can be watched for revives or boosters.\n'
                            '• You can control personalized ad tracking via Android device settings (Google → Ads).',
                      ),
                      const SizedBox(height: 14),

                      // Card 7: Local Storage & Disclaimers
                      _buildTermsCard(
                        icon: Icons.storage_rounded,
                        iconColor: const Color(0xFF06B6D4),
                        title: '7. Local Data & Player Responsibility',
                        content:
                            'Game scores, unlocked skins, and challenge streaks are stored locally on your device storage.\n\n'
                            '• Clearing app storage or uninstalling the app may permanently reset local progress.\n'
                            '• The Game is provided on an "AS IS" basis without warranties of uninterrupted service.\n'
                            '• Virtual items and skins have no real-world monetary value.',
                      ),
                      const SizedBox(height: 14),

                      // Card 8: Governing Law & Grievances
                      _buildTermsCard(
                        icon: Icons.support_agent_rounded,
                        iconColor: const Color(0xFF6366F1),
                        title: '8. Governing Law & Contact',
                        content:
                            'These Terms are governed by the laws of India, with exclusive jurisdiction in the courts of Bulandshahr, Uttar Pradesh.\n\n'
                            'For support, inquiries, or grievance redressal, contact:\n'
                            '• Support Phone: +91 9557754705\n'
                            '• Support Email: drillmovies@gmail.com\n'
                            '• Grievance Officer: Nitesh Kumar, SHARP OP\n'
                            '• Response Time: Within 24–48 business hours',
                      ),
                      const SizedBox(height: 20),

                      // Pixar 3D Close / Accept button
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
                              'I UNDERSTAND & AGREE',
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

  Widget _buildTermsCard({
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

