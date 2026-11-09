import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/audio/asmr_audio_engine.dart';
import '../../game/game_coordinator.dart';
import '../widgets/pixar_3d_widgets.dart';
import '../../core/services/rating_service.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'rank_screen.dart';

class SettingsScreen extends StatefulWidget {
  final GameCoordinator coordinator;

  const SettingsScreen({super.key, required this.coordinator});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _masterVolume = 0.8;
  double _sfxVolume = 1.0;
  bool _hapticsEnabled = true;
  String _hapticIntensity = 'crisp';
  String _asmrIntensity = 'balanced';
  int _gridSize = 8;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await widget.coordinator.saveRepository.loadSettings();
    setState(() {
      _masterVolume = (settings['masterVolume'] as num?)?.toDouble() ?? 0.8;
      _sfxVolume = (settings['sfxVolume'] as num?)?.toDouble() ?? 1.0;
      _hapticsEnabled = (settings['isHapticsEnabled'] as bool?) ?? true;
      _hapticIntensity = (settings['hapticIntensity'] as String?) ?? 'crisp';
      _asmrIntensity = (settings['asmrIntensity'] as String?) ?? 'balanced';
      _gridSize = (settings['gridSize'] as int?) ?? 8;
      _reducedMotion = (settings['reducedMotion'] as bool?) ?? false;
    });
    try {
      widget.coordinator.audioEngine.masterVolume = _masterVolume;
      widget.coordinator.audioEngine.sfxVolume = _sfxVolume;
      widget.coordinator.audioEngine.hapticIntensity = HapticIntensity.values.byName(_hapticIntensity);
      widget.coordinator.audioEngine.isHapticsEnabled = _hapticsEnabled;
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    final settings = {
      'masterVolume': _masterVolume,
      'sfxVolume': _sfxVolume,
      'isHapticsEnabled': _hapticsEnabled,
      'hapticIntensity': _hapticIntensity,
      'asmrIntensity': _asmrIntensity,
      'gridSize': _gridSize,
      'reducedMotion': _reducedMotion,
    };
    await widget.coordinator.saveRepository.saveSettings(settings);
    try {
      widget.coordinator.audioEngine.masterVolume = _masterVolume;
      widget.coordinator.audioEngine.sfxVolume = _sfxVolume;
      widget.coordinator.audioEngine.hapticIntensity = HapticIntensity.values.byName(_hapticIntensity);
      widget.coordinator.audioEngine.isHapticsEnabled = _hapticsEnabled;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.coordinator,
      builder: (context, _) {
        final theme = widget.coordinator.theme;

        return Scaffold(
          backgroundColor: theme.backgroundEnd,
          appBar: Pixar3DAppBar(
            title: 'SETTINGS & AUDIO',
            accentColor: theme.accent,
            onBackPressed: () => Navigator.of(context).pop(),
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
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Subscription & Ad Removal Card
                  const Row(
                    children: [
                      Text('👑', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text(
                        'PREMIUM MEMBERSHIP',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textTertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListenableBuilder(
                    listenable: widget.coordinator.billingService,
                    builder: (context, _) {
                      final billing = widget.coordinator.billingService;
                      final isRemoved = billing.isAdsRemoved;

                      return Pixar3DCard(
                        borderRadius: 22,
                        padding: const EdgeInsets.all(18),
                        gradientColors: isRemoved
                            ? const [
                                Color(0xFFECFDF5),
                                Color(0xFFD1FAE5),
                              ]
                            : const [
                                Color(0xFFFFFBEB),
                                Color(0xFFFEF3C7),
                              ],
                        borderColor: isRemoved ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        extrusionColor: isRemoved ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isRemoved
                                          ? [const Color(0xFF34D399), const Color(0xFF059669)]
                                          : [const Color(0xFFFBBF24), const Color(0xFFD97706)],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isRemoved ? const Color(0xFF10B981) : const Color(0xFFFFD700))
                                            .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: Icon(
                                    isRemoved ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isRemoved ? 'Ad-Free Pro Active' : 'Remove All Ads',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isRemoved
                                            ? 'Enjoy an uninterrupted gaming flow'
                                            : 'No banners, no interstitial delays',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isRemoved)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                                    ),
                                    child: const Text(
                                      'ACTIVE ✨',
                                      style: TextStyle(
                                        color: Color(0xFF059669),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (!isRemoved) ...[
                              Pixar3DButton(
                                text: billing.isLoading ? 'PROCESSING...' : 'SUBSCRIBE — ${billing.displayPrice}',
                                icon: Icons.star_rounded,
                                height: 48,
                                gradientColors: const [Color(0xFFFBBF24), Color(0xFFD97706)],
                                extrusionColor: const Color(0xFFB45309),
                                onPressed: billing.isLoading
                                    ? null
                                    : () async {
                                        final success = await billing.buyRemoveAds();
                                        if (!context.mounted) return;
                                        if (!success && billing.errorMessage != null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(billing.errorMessage!)),
                                          );
                                        }
                                      },
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: billing.isLoading
                                      ? null
                                      : () async {
                                          AsmrAudioEngine.instance.playPixarPop();
                                          await billing.restorePurchases();
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Purchases restored successfully.'),
                                            ),
                                          );
                                        },
                                  child: const Text(
                                    'Restore Purchases',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Renews monthly • Cancel anytime',
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Google Play Games Services Section
                  const Row(
                    children: [
                      Text('🎮', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text(
                        'GOOGLE PLAY GAMES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textTertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ListenableBuilder(
                    listenable: widget.coordinator.playGamesService,
                    builder: (context, _) {
                      final pgs = widget.coordinator.playGamesService;
                      final isAuth = pgs.isAuthenticated;
                      return Pixar3DCard(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(16),
                        borderColor: isAuth ? const Color(0xFF10B981).withValues(alpha: 0.6) : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isAuth
                                          ? [const Color(0xFF34D399), const Color(0xFF059669)]
                                          : [theme.accent, theme.accent.withValues(alpha: 0.7)],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: const Icon(
                                    Icons.sports_esports_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isAuth
                                            ? (pgs.displayName ?? 'Google Play Games Player')
                                            : 'Google Play Games',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isAuth
                                            ? 'Connected • Cloud High Scores & Badges'
                                            : 'Sign in to sync high scores & leaderboards',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAuth)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                                    ),
                                    child: const Text(
                                      'SYNCED ✨',
                                      style: TextStyle(
                                        color: Color(0xFF059669),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.textPrimary,
                                      side: const BorderSide(color: AppColors.border, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () async {
                                      AsmrAudioEngine.instance.playPixarPop();
                                      if (pgs.isAuthenticated) {
                                        final opened = await pgs.showLeaderboard();
                                        if (opened) return;
                                      }
                                      if (context.mounted) {
                                        Navigator.of(context).push(
                                          PixarPageRoute(
                                            page: RankScreen(coordinator: widget.coordinator),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.leaderboard_outlined, size: 18),
                                    label: const Text('Leaderboard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.textPrimary,
                                      side: const BorderSide(color: AppColors.border, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () {
                                      AsmrAudioEngine.instance.playPixarPop();
                                      pgs.showAchievements();
                                    },
                                    icon: const Icon(Icons.military_tech_outlined, size: 18),
                                    label: const Text('Achievements', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                            if (!isAuth) ...[
                              const SizedBox(height: 12),
                              Pixar3DButton(
                                text: 'CONNECT PLAY GAMES',
                                icon: Icons.login_rounded,
                                height: 44,
                                gradientColors: [
                                  theme.accent,
                                  theme.accent.withValues(alpha: 0.8),
                                ],
                                extrusionColor: theme.accent.withValues(alpha: 0.5),
                                onPressed: () async {
                                  final ok = await pgs.signIn();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok
                                          ? 'Connected to Google Play Games: ${pgs.displayName ?? 'Player'}!'
                                          : 'Google Play Games sign-in: Connects automatically once downloaded from Play Store (for local builds, tester account must be added in Play Console).'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Audio & ASMR section
                  const Row(
                    children: [
                      Text('🎵', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text(
                        'AUDIO & ASMR EXPERIENCE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textTertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Pixar3DCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        // Master Volume Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Master Volume',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${(_masterVolume * 100).round()}%',
                              style: TextStyle(color: theme.accent, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        Slider(
                          value: _masterVolume,
                          activeColor: theme.accent,
                          inactiveColor: AppColors.borderSubtle,
                          onChanged: (v) {
                            setState(() => _masterVolume = v);
                            _saveSettings();
                          },
                        ),
                        const Divider(color: AppColors.borderSubtle),

                        // ASMR Intensity Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ASMR Mode',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            ),
                            DropdownButton<String>(
                              value: _asmrIntensity,
                              dropdownColor: Colors.white,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(value: 'full', child: Text('Full ASMR ✨', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: 'balanced', child: Text('Balanced 🫧', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: 'subtle', child: Text('Subtle 🍃', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  AsmrAudioEngine.instance.playPixarPop();
                                  setState(() => _asmrIntensity = val);
                                  _saveSettings();
                                }
                              },
                            ),
                          ],
                        ),
                        const Divider(color: AppColors.borderSubtle),

                        // Haptics Toggle
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Haptic Feedback',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Vibration on block snap & clears',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                          ),
                          value: _hapticsEnabled,
                          activeTrackColor: theme.accent,
                          onChanged: (v) {
                            AsmrAudioEngine.instance.playPixarPop();
                            setState(() => _hapticsEnabled = v);
                            _saveSettings();
                          },
                        ),
                        if (_hapticsEnabled) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Vibration Force',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  _buildHapticChip('Subtle', 'subtle', theme.accent),
                                  const SizedBox(width: 6),
                                  _buildHapticChip('Crisp', 'crisp', theme.accent),
                                  const SizedBox(width: 6),
                                  _buildHapticChip('Heavy', 'heavy', theme.accent),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Board & Gameplay section
                  const Row(
                    children: [
                      Text('🧩', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text(
                        'BOARD & ACCESSIBILITY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textTertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Pixar3DCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        // Grid Size
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grid Dimensions',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_gridSize}x$_gridSize Grid',
                              style: TextStyle(color: theme.accent, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _gridSize == 8 ? theme.accent : AppColors.borderSubtle,
                                    width: _gridSize == 8 ? 2 : 1,
                                  ),
                                  backgroundColor: _gridSize == 8
                                      ? theme.accent.withValues(alpha: 0.15)
                                      : const Color(0xFFF8FAFC),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () {
                                  AsmrAudioEngine.instance.playPixarPop();
                                  setState(() => _gridSize = 8);
                                  _saveSettings();
                                },
                                child: Text(
                                  '8x8 (Classic)',
                                  style: TextStyle(
                                    color: _gridSize == 8 ? theme.accent : AppColors.textSecondary,
                                    fontWeight: _gridSize == 8 ? FontWeight.w900 : FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _gridSize == 9 ? theme.accent : AppColors.borderSubtle,
                                    width: _gridSize == 9 ? 2 : 1,
                                  ),
                                  backgroundColor: _gridSize == 9
                                      ? theme.accent.withValues(alpha: 0.15)
                                      : const Color(0xFFF8FAFC),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () {
                                  AsmrAudioEngine.instance.playPixarPop();
                                  setState(() => _gridSize = 9);
                                  _saveSettings();
                                },
                                child: Text(
                                  '9x9 (Expanded)',
                                  style: TextStyle(
                                    color: _gridSize == 9 ? theme.accent : AppColors.textSecondary,
                                    fontWeight: _gridSize == 9 ? FontWeight.w900 : FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppColors.borderSubtle),

                        // Reduced Motion
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Reduced Motion',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Minimize particle bursts and pulse animations',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                          ),
                          value: _reducedMotion,
                          activeTrackColor: theme.accent,
                          onChanged: (v) {
                            AsmrAudioEngine.instance.playPixarPop();
                            setState(() => _reducedMotion = v);
                            _saveSettings();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Legal & Privacy section
                  const Row(
                    children: [
                      Text('🛡️', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text(
                        'LEGAL & ABOUT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textTertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Pixar3DCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.accent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.privacy_tip_outlined, color: theme.accent, size: 22),
                          ),
                          title: const Text(
                            'Privacy Policy',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                          subtitle: const Text(
                            'Data safety, consent & ad disclosures',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.iconSubtle, size: 14),
                          onTap: () {
                            AsmrAudioEngine.instance.playPixarPop();
                            Navigator.of(context).push(
                              PixarPageRoute(
                                page: PrivacyPolicyScreen(coordinator: widget.coordinator),
                              ),
                            );
                          },
                        ),
                        const Divider(color: AppColors.borderSubtle),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.description_outlined, color: Color(0xFF38BDF8), size: 22),
                          ),
                          title: const Text(
                            'Terms of Service',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                          subtitle: const Text(
                            'User agreement, fair play & billing',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.iconSubtle, size: 14),
                          onTap: () {
                            AsmrAudioEngine.instance.playPixarPop();
                            Navigator.of(context).push(
                              PixarPageRoute(
                                page: TermsOfServiceScreen(coordinator: widget.coordinator),
                              ),
                            );
                          },
                        ),
                        const Divider(color: AppColors.borderSubtle),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'App Version',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'v1.0.2 (Build 3)',
                                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Rate App on Google Play Option
                  Pixar3DCard(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(14),
                    gradientColors: const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                    borderColor: const Color(0xFFFCD34D),
                    extrusionColor: const Color(0xFFFDE68A),
                    onTap: () async {
                      AsmrAudioEngine.instance.playPixarPop();
                      RatingService().showRatingDialog(context);
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'RATE ON GOOGLE PLAY',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: Color(0xFFB45309),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Reset Game Option
                  Pixar3DCard(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(14),
                    gradientColors: const [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
                    borderColor: const Color(0xFFFCA5A5),
                    extrusionColor: const Color(0xFFFECACA),
                    onTap: () async {
                      AsmrAudioEngine.instance.playPixarPop();
                      await widget.coordinator.startNewGame();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('New game session initialized!')),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restart_alt_rounded, color: Color(0xFFEF4444), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'START FRESH GAME',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: Color(0xFFEF4444),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHapticChip(String label, String value, Color accent) {
    final isSelected = _hapticIntensity == value;
    return GestureDetector(
      onTap: () {
        AsmrAudioEngine.instance.playPixarPop();
        setState(() => _hapticIntensity = value);
        _saveSettings();
        if (value == 'subtle') {
          widget.coordinator.audioEngine.triggerHaptic(HapticType.selection);
        } else if (value == 'heavy') {
          widget.coordinator.audioEngine.triggerHaptic(HapticType.heavy);
        } else {
          widget.coordinator.audioEngine.triggerHaptic(HapticType.medium);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accent : AppColors.borderSubtle,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? accent : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
