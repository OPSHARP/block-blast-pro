import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/audio/asmr_audio_engine.dart';
import '../../domain/models/rank_tier.dart';
import '../../game/game_coordinator.dart';
import '../widgets/skill_radar_chart.dart';
import '../widgets/pixar_3d_widgets.dart';

class _LivePlayerEntry {
  final String id;
  final String playerName;
  int score;
  final String countryFlag;
  final bool isCurrentUser;
  final RankTier tier;
  final Color avatarColor;
  int rank;
  int previousRank;
  int? lastScoreDelta;
  DateTime? lastDeltaTime;

  _LivePlayerEntry({
    required this.id,
    required this.playerName,
    required this.score,
    required this.countryFlag,
    this.isCurrentUser = false,
    required this.tier,
    required this.avatarColor,
    required this.rank,
    required this.previousRank,
    this.lastScoreDelta,
    this.lastDeltaTime,
  });
}

class RankScreen extends StatefulWidget {
  final GameCoordinator coordinator;

  const RankScreen({super.key, required this.coordinator});

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _leaderboardFilterIndex = 0; // 0 = Global, 1 = Division Rivals, 2 = Friends
  bool _isSyncing = false;
  List<_LivePlayerEntry> _livePlayers = [];
  Timer? _liveSimulationTimer;
  String _liveTickerMessage = '🟢 LIVE MATCHES • 14,890 Active Players';
  final math.Random _random = math.Random();
  int _lastHighScore = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initLiveLeaderboard();
    _startLiveSimulation();
  }

  @override
  void dispose() {
    _liveSimulationTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _initLiveLeaderboard([int? overrideHighScore, String? overrideDisplayName]) {
    final state = widget.coordinator.state;
    final highScore = overrideHighScore ?? state.highScore;
    final playGames = widget.coordinator.playGamesService;
    final displayName = overrideDisplayName ??
        (playGames.isAuthenticated ? (playGames.displayName ?? 'Player') : 'You (Champion)');
    _lastHighScore = highScore;

    final baseCompetitors = <Map<String, dynamic>>[
      {'name': 'ApexBlaster', 'score': 28450, 'flag': '🇺🇸', 'color': const Color(0xFFEF4444)},
      {'name': 'Kenji_99', 'score': 24920, 'flag': '🇯🇵', 'color': const Color(0xFF8B5CF6)},
      {'name': 'Elena_Frost', 'score': 21800, 'flag': '🇩🇪', 'color': const Color(0xFF3B82F6)},
      {'name': 'BlockKing_DK', 'score': 19340, 'flag': '🇩🇰', 'color': const Color(0xFF10B981)},
      {'name': 'ZenMaster_KR', 'score': 17650, 'flag': '🇰🇷', 'color': const Color(0xFFF59E0B)},
      {'name': 'Lucas_Silva', 'score': 15200, 'flag': '🇧🇷', 'color': const Color(0xFF06B6D4)},
      {'name': 'Aarav_Blaster', 'score': 13910, 'flag': '🇮🇳', 'color': const Color(0xFFEC4899)},
      {'name': 'Chloe_Paris', 'score': 12450, 'flag': '🇫🇷', 'color': const Color(0xFF6366F1)},
      {'name': 'Liam_London', 'score': 10890, 'flag': '🇬🇧', 'color': const Color(0xFF14B8A6)},
      {'name': 'Mateo_Madrid', 'score': 9420, 'flag': '🇪🇸', 'color': const Color(0xFFEAB308)},
      {'name': 'Sofia_Roma', 'score': 8150, 'flag': '🇮🇹', 'color': const Color(0xFF84CC16)},
      {'name': 'Noah_Sydney', 'score': 7230, 'flag': '🇦🇺', 'color': const Color(0xFF0EA5E9)},
      {'name': 'Fatima_Dubai', 'score': 6410, 'flag': '🇦🇪', 'color': const Color(0xFFA855F7)},
      {'name': 'Oliver_Toronto', 'score': 5630, 'flag': '🇨🇦', 'color': const Color(0xFFF97316)},
      {'name': 'Marta_Warsaw', 'score': 4890, 'flag': '🇵🇱', 'color': const Color(0xFF10B981)},
      {'name': 'Dmitri_Baltic', 'score': 4120, 'flag': '🇪🇪', 'color': const Color(0xFF06B6D4)},
      {'name': 'Yuki_Tokyo', 'score': 3550, 'flag': '🇯🇵', 'color': const Color(0xFFF43F5E)},
      {'name': 'Carlos_MX', 'score': 2980, 'flag': '🇲🇽', 'color': const Color(0xFF8B5CF6)},
      {'name': 'Ananya_Delhi', 'score': 2450, 'flag': '🇮🇳', 'color': const Color(0xFFEAB308)},
      {'name': 'Jan_Prague', 'score': 1920, 'flag': '🇨🇿', 'color': const Color(0xFF64748B)},
      {'name': 'Lars_Stockholm', 'score': 1480, 'flag': '🇸🇪', 'color': const Color(0xFF38BDF8)},
      {'name': 'Sara_Oslo', 'score': 1050, 'flag': '🇳🇴', 'color': const Color(0xFF708090)},
      {'name': 'Minho_Seoul', 'score': 820, 'flag': '🇰🇷', 'color': const Color(0xFFCD7F32)},
      {'name': 'Mia_Auckland', 'score': 610, 'flag': '🇳🇿', 'color': const Color(0xFFCD7F32)},
      {'name': 'Leo_Vienna', 'score': 390, 'flag': '🇦🇹', 'color': const Color(0xFFCD7F32)},
    ];

    final players = <_LivePlayerEntry>[];
    for (int i = 0; i < baseCompetitors.length; i++) {
      final c = baseCompetitors[i];
      final baseScore = c['score'] as int;
      final offset = (_random.nextInt(60) - 20);
      final score = math.max(100, baseScore + offset);
      players.add(_LivePlayerEntry(
        id: 'comp_$i',
        playerName: c['name'] as String,
        score: score,
        countryFlag: c['flag'] as String,
        avatarColor: c['color'] as Color,
        tier: RankTier.fromScore(score),
        rank: i + 1,
        previousRank: i + 1,
      ));
    }

    players.add(_LivePlayerEntry(
      id: 'user_self',
      playerName: displayName,
      score: highScore,
      countryFlag: '⭐',
      avatarColor: const Color(0xFF38BDF8),
      isCurrentUser: true,
      tier: RankTier.fromScore(highScore),
      rank: 1,
      previousRank: 1,
    ));

    _reSortAndAssignRanks(players);
    _livePlayers = players;
  }

  void _reSortAndAssignRanks(List<_LivePlayerEntry> list) {
    list.sort((a, b) => b.score.compareTo(a.score));
    for (int i = 0; i < list.length; i++) {
      list[i].rank = i + 1;
    }
  }

  void _startLiveSimulation() {
    _liveSimulationTimer?.cancel();
    _liveSimulationTimer = Timer.periodic(const Duration(milliseconds: 3600), (timer) {
      if (!mounted || _livePlayers.isEmpty) return;

      final candidates = _livePlayers.where((p) => !p.isCurrentUser).toList();
      if (candidates.isEmpty) return;

      final count = _random.nextInt(2) + 1;
      String? activePlayerNote;

      for (int i = 0; i < count; i++) {
        final chosen = candidates[_random.nextInt(candidates.length)];
        final delta = (_random.nextInt(10) + 4) * 10;
        chosen.score += delta;
        chosen.previousRank = chosen.rank;
        chosen.lastScoreDelta = delta;
        chosen.lastDeltaTime = DateTime.now();

        activePlayerNote = '${chosen.playerName} (+$delta pts)';
      }

      // 18% chance to introduce an active new challenger from tournament pool
      if (_random.nextDouble() < 0.18 && _livePlayers.length < 35) {
        final challengers = [
          ('NovaBlast_X', '🇰🇷', const Color(0xFF8B5CF6)),
          ('PixelSamurai', '🇯🇵', const Color(0xFFEF4444)),
          ('CyberDragon', '🇸🇬', const Color(0xFF06B6D4)),
          ('BlazeMaster_IN', '🇮🇳', const Color(0xFFF97316)),
          ('Aurora_V', '🇫🇮', const Color(0xFF10B981)),
          ('TurboBlocker', '🇺🇸', const Color(0xFFEC4899)),
          ('VortexGamer', '🇩🇪', const Color(0xFF38BDF8)),
        ];
        final pick = challengers[_random.nextInt(challengers.length)];
        if (!_livePlayers.any((p) => p.playerName == pick.$1)) {
          final randRef = _livePlayers[_random.nextInt(_livePlayers.length)].score;
          final newScore = math.max(600, randRef + _random.nextInt(160) - 80);
          final newPlayer = _LivePlayerEntry(
            id: 'challenger_${DateTime.now().millisecondsSinceEpoch}',
            playerName: pick.$1,
            score: newScore,
            countryFlag: pick.$2,
            avatarColor: pick.$3,
            tier: RankTier.fromScore(newScore),
            rank: _livePlayers.length + 1,
            previousRank: _livePlayers.length + 1,
            lastScoreDelta: 110,
            lastDeltaTime: DateTime.now(),
          );
          _livePlayers.add(newPlayer);
          activePlayerNote = '${newPlayer.playerName} joined ranking (+110 pts)';
        }
      }

      _reSortAndAssignRanks(_livePlayers);

      setState(() {
        if (activePlayerNote != null) {
          _liveTickerMessage = '⚡ LIVE TOURNAMENT: $activePlayerNote!';
        }
      });
    });
  }

  Future<void> _handlePlayGamesSync() async {
    final pgs = widget.coordinator.playGamesService;
    setState(() => _isSyncing = true);

    try {
      if (!pgs.isAuthenticated) {
        final success = await pgs.signIn();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Connected to Google Play Games as ${pgs.displayName ?? "Player"}!'
                    : 'Google Play Games sign-in cancelled or unavailable.',
              ),
              backgroundColor: success ? AppColors.success : AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Already authenticated, submit high score and try showing native overlay
        final highScore = widget.coordinator.state.highScore;
        await pgs.submitScore(highScore);
        final opened = await pgs.showLeaderboard();
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('High score synced with Google Play Cloud!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync note: Using in-app global leaderboard. ($e)'),
            backgroundColor: AppColors.textSecondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.coordinator,
      builder: (context, _) {
        final theme = widget.coordinator.theme;
        final state = widget.coordinator.state;
        final highScore = state.highScore;
        final currentTier = RankTier.fromScore(highScore);
        final playGames = widget.coordinator.playGamesService;
        final displayName = playGames.displayName ?? 'Player';

        if (_livePlayers.isEmpty || _lastHighScore != highScore) {
          _initLiveLeaderboard(highScore, playGames.isAuthenticated ? displayName : 'You (Champion)');
        }

        final userEntry = _livePlayers.firstWhere(
          (e) => e.isCurrentUser,
          orElse: () => _livePlayers.last,
        );

        return Scaffold(
          backgroundColor: theme.backgroundEnd,
          appBar: Pixar3DAppBar(
            title: 'RANKS & TROPHIES',
            accentColor: theme.accent,
            onBackPressed: () => Navigator.of(context).pop(),
            actions: [
              IconButton(
                icon: _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Icon(
                        playGames.isAuthenticated
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_upload_outlined,
                        color: playGames.isAuthenticated ? const Color(0xFF10B981) : Colors.white,
                        size: 24,
                      ),
                tooltip: playGames.isAuthenticated
                    ? 'Synced with Google Play Games'
                    : 'Sync with Google Play Games',
                onPressed: _isSyncing ? null : _handlePlayGamesSync,
              ),
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
                  // Hero Rank Summary Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildHeroRankCard(currentTier, highScore, userEntry.rank, state),
                  ),

                  // Tactile 3D Tab Bar Header
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      onTap: (_) => AsmrAudioEngine.instance.playPixarPop(),
                      indicator: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.accent,
                            theme.accent.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: theme.accent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: const [
                        Tab(text: '🏆 Top'),
                        Tab(text: '🗺️ Roadmap'),
                        Tab(text: '⭐ Rating'),
                      ],
                    ),
                  ),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLeaderboardTab(_livePlayers, userEntry, theme),
                        _buildTierRoadmapTab(currentTier, highScore, theme),
                        _buildSkillRatingTab(state, theme),
                      ],
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

  Widget _buildHeroRankCard(RankTier tier, int highScore, int globalRank, dynamic state) {
    final progress = tier.progress(highScore);
    final pointsRemaining = tier.pointsToNext(highScore);
    final nextTier = tier.nextTier;
    final rating = state.skillProfile.overallSkillRating;

    return Pixar3DCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(16),
      gradientColors: [
        tier.primaryColor.withValues(alpha: 0.12),
        Colors.white,
      ],
      borderColor: tier.primaryColor.withValues(alpha: 0.4),
      extrusionColor: tier.primaryColor.withValues(alpha: 0.2),
      child: Column(
        children: [
          Row(
            children: [
              // Animated 3D Tier Badge with glossy highlight
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tier.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: tier.primaryColor.withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2.5),
                ),
                child: Center(
                  child: Text(
                    tier.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Tier Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tier.fullTitle(highScore).toUpperCase(),
                            style: TextStyle(
                              color: tier.primaryColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 0.8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tier.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tier.primaryColor.withValues(alpha: 0.6), width: 1.2),
                          ),
                          child: Text(
                            '#$globalRank',
                            style: TextStyle(
                              color: tier.primaryColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'High Score: ${highScore.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} pts',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Skill Rating: $rating • ${state.totalLinesCleared} Lines Cleared',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Pixar 3D Progress Bar to next tier
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nextTier != null
                        ? '${(progress * 100).toInt()}% to ${nextTier.name} ${nextTier.title}'
                        : '🌟 MAX TIER ACHIEVED',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    nextTier != null ? '$pointsRemaining pts needed' : 'Top Tier',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Pixar3DProgressBar(
                progress: progress,
                fillColor: tier.primaryColor,
                height: 10,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(
    List<_LivePlayerEntry> allPlayers,
    _LivePlayerEntry userEntry,
    dynamic theme,
  ) {
    List<_LivePlayerEntry> displayList;

    if (_leaderboardFilterIndex == 1) {
      // Division Rivals: +/- 4 ranks around user
      final userIdx = allPlayers.indexWhere((p) => p.isCurrentUser);
      if (userIdx != -1) {
        final start = math.max(0, userIdx - 4);
        final end = math.min(allPlayers.length, userIdx + 5);
        displayList = allPlayers.sublist(start, end);
      } else {
        displayList = allPlayers.take(10).toList();
      }
    } else if (_leaderboardFilterIndex == 2) {
      // Friends: simulated friends + user
      displayList = allPlayers
          .where((p) =>
              p.isCurrentUser ||
              ['Kenji_99', 'Elena_Frost', 'Aarav_Blaster', 'Sofia_Roma', 'Carlos_MX', 'Liam_London']
                  .contains(p.playerName))
          .toList();
    } else {
      displayList = allPlayers;
    }

    return Column(
      children: [
        // Filter Chips with 3D tactile buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _buildFilterChip('🌐 Global', 0),
              const SizedBox(width: 8),
              _buildFilterChip('⚔️ Rivals', 1),
              const SizedBox(width: 8),
              _buildFilterChip('👥 Friends', 2),
            ],
          ),
        ),

        // Live Tournament Ticker Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.8),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _liveTickerMessage,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ONLINE',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Pinned User Placement Bar in 3D Gold Accent Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Pixar3DCard(
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            gradientColors: [
              theme.accent.withValues(alpha: 0.12),
              Colors.white,
            ],
            borderColor: theme.accent,
            extrusionColor: theme.accent.withValues(alpha: 0.25),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.accent, theme.accent.withValues(alpha: 0.7)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.accent.withValues(alpha: 0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '#${userEntry.rank}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userEntry.playerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('⭐', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Text(
                        userEntry.tier.fullTitle(userEntry.score),
                        style: TextStyle(
                          fontSize: 11,
                          color: userEntry.tier.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      userEntry.score.toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (m) => '${m[1]},',
                          ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'YOUR SCORE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Competitors List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: displayList.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = displayList[index];
              return _buildLeaderboardTile(entry, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _leaderboardFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AsmrAudioEngine.instance.playPixarPop();
          setState(() => _leaderboardFilterIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFF1F5F9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.borderSubtle,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTile(_LivePlayerEntry entry, dynamic theme) {
    Widget rankWidget;

    if (entry.rank == 1) {
      rankWidget = const Text('🥇', style: TextStyle(fontSize: 22));
    } else if (entry.rank == 2) {
      rankWidget = const Text('🥈', style: TextStyle(fontSize: 22));
    } else if (entry.rank == 3) {
      rankWidget = const Text('🥉', style: TextStyle(fontSize: 22));
    } else {
      rankWidget = Text(
        '#${entry.rank}',
        style: TextStyle(
          color: entry.isCurrentUser ? theme.accent : AppColors.textPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      );
    }

    final hasScoreDelta = entry.lastScoreDelta != null &&
        entry.lastDeltaTime != null &&
        DateTime.now().difference(entry.lastDeltaTime!).inSeconds < 4;

    return Pixar3DCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      gradientColors: entry.isCurrentUser
          ? [
              theme.accent.withValues(alpha: 0.12),
              Colors.white,
            ]
          : (entry.rank <= 3
              ? const [
                  Color(0xFFFEF3C7),
                  Colors.white,
                ]
              : null),
      borderColor: entry.isCurrentUser
          ? theme.accent
          : (entry.rank <= 3 ? const Color(0xFFF59E0B) : AppColors.border),
      extrusionColor: entry.isCurrentUser ? theme.accent.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                rankWidget,
                if (entry.rank < entry.previousRank)
                  Text(
                    '▲${entry.previousRank - entry.rank}',
                    style: const TextStyle(fontSize: 9, color: Color(0xFF34D399), fontWeight: FontWeight.w900),
                  )
                else if (entry.rank > entry.previousRank)
                  Text(
                    '▼${entry.rank - entry.previousRank}',
                    style: const TextStyle(fontSize: 9, color: Color(0xFFF59E0B), fontWeight: FontWeight.w900),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Player Avatar Circle with 3D border
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [entry.avatarColor.withValues(alpha: 0.4), entry.avatarColor.withValues(alpha: 0.15)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: entry.avatarColor, width: 2),
            ),
            child: Center(
              child: Text(
                entry.playerName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: entry.avatarColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name and country flag
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.playerName,
                        style: TextStyle(
                          fontWeight: entry.isCurrentUser ? FontWeight.w900 : FontWeight.bold,
                          fontSize: 13,
                          color: entry.isCurrentUser ? theme.accent : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(entry.countryFlag, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                Text(
                  entry.tier.title,
                  style: TextStyle(
                    fontSize: 11,
                    color: entry.tier.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Score & Live Delta
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasScoreDelta)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                  ),
                  child: Text(
                    '+${entry.lastScoreDelta}',
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              Text(
                entry.score.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (m) => '${m[1]},',
                    ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: entry.isCurrentUser ? theme.accent : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierRoadmapTab(RankTier currentTier, int highScore, dynamic theme) {
    final allTiers = RankTier.allTiers;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: allTiers.length,
      itemBuilder: (context, index) {
        final tier = allTiers[index];
        final isAchieved = highScore >= tier.minScore;
        final isCurrent = tier.id == currentTier.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Pixar3DCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            gradientColors: isCurrent
                ? [
                    tier.primaryColor.withValues(alpha: 0.12),
                    Colors.white,
                  ]
                : (isAchieved
                    ? const [
                        Color(0xFFF0FDF4),
                        Colors.white,
                      ]
                    : const [
                        Color(0xFFF8FAFC),
                        Colors.white,
                      ]),
            borderColor: isCurrent
                ? tier.primaryColor
                : (isAchieved ? const Color(0xFF10B981) : AppColors.border),
            extrusionColor: isCurrent ? tier.primaryColor.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: tier.gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: tier.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          tier.emoji,
                          style: const TextStyle(fontSize: 24),
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
                              Text(
                                '${tier.name} ${tier.title}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: tier.primaryColor,
                                ),
                              ),
                              const Spacer(),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: tier.primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: tier.primaryColor.withValues(alpha: 0.4),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                )
                              else if (isAchieved)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22)
                              else
                                const Icon(Icons.lock_outline, color: AppColors.iconSubtle, size: 20),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tier.minScore == 0
                                ? 'Default Tier (0+ pts)'
                                : 'Requires ${tier.minScore.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}+ High Score pts',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.borderSubtle),
                const SizedBox(height: 10),

                // Unlocked perks list
                const Text(
                  'TIER PERKS & BONUSES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                ...tier.perks.map((perk) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            isAchieved ? Icons.verified : Icons.lock_outline,
                            size: 14,
                            color: isAchieved ? const Color(0xFF10B981) : AppColors.iconSubtle,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              perk,
                              style: TextStyle(
                                fontSize: 12,
                                color: isAchieved ? Colors.white : const Color(0xFFCBD5E1),
                                fontWeight: isAchieved ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkillRatingTab(dynamic state, dynamic theme) {
    final profile = state.skillProfile;
    final rating = profile.overallSkillRating;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Elo Card
          Pixar3DCard(
            borderRadius: 22,
            padding: const EdgeInsets.all(22),
            gradientColors: [
              theme.accent.withValues(alpha: 0.12),
              Colors.white,
            ],
            borderColor: theme.accent,
            extrusionColor: theme.accent.withValues(alpha: 0.25),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Text(
                      '$rating',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: theme.accent,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('⚡', style: TextStyle(fontSize: 28)),
                  ],
                ),
                const Text(
                  'COMPOSITE ELO SKILL RATING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dynamic rating adapted from your spatial planning, combo rhythm, and recovery efficiency.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Radar Chart
          Pixar3DCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🎯', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      'SKILL RADAR ATTRIBUTES',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: Center(
                    child: SkillRadarChart(
                      profile: profile,
                      accentColor: theme.accent,
                      size: 240,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Attribute breakdown cards with 3D candy progress bars
          _buildSkillRow('Spatial Planning', profile.spatialPlanning, Icons.grid_4x4),
          _buildSkillRow('Efficiency', profile.efficiency, Icons.speed_outlined),
          _buildSkillRow('Combo Mastery', profile.comboSkill, Icons.flash_on_outlined),
          _buildSkillRow('Risk Management', profile.riskManagement, Icons.shield_outlined),
          _buildSkillRow('Physics Mastery', profile.physicsMastery, Icons.auto_awesome),
          _buildSkillRow('Grid Awareness', profile.gridAwareness, Icons.visibility_outlined),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSkillRow(String label, double value, IconData icon) {
    final color = value > 70
        ? const Color(0xFF10B981)
        : (value > 40 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Pixar3DCard(
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(
              width: 110,
              child: Pixar3DProgressBar(
                progress: (value / 100.0).clamp(0.0, 1.0),
                fillColor: color,
                height: 8,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 34,
              child: Text(
                '${value.toInt()}',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
