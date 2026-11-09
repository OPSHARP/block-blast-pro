// Central Game Coordinator managing state transitions, simulation loop, and audio/visuals

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../domain/models/game_state.dart';
import '../domain/models/board_state.dart';
import '../domain/models/block_model.dart';
import '../domain/models/block_weight.dart';
import '../domain/models/block_skin_style.dart';
import '../domain/models/special_block_type.dart';
import '../domain/models/game_mode.dart';
import '../domain/models/achievement.dart';
import '../domain/models/daily_challenge.dart';
import '../domain/models/player_skill_profile.dart';
import '../domain/models/streak_info.dart';
import '../domain/services/board_service.dart';
import '../domain/services/piece_generator_service.dart';
import '../domain/services/grid_shift_service.dart';
import '../domain/services/difficulty_service.dart';
import '../domain/services/daily_challenge_service.dart';
import '../domain/services/streak_service.dart';
import '../data/repositories/local_save_repository.dart';
import '../domain/models/cell_model.dart';
import '../core/theme/game_theme.dart';
import '../core/audio/asmr_audio_engine.dart';
import '../core/billing/billing_service.dart';
import '../core/ads/ad_service.dart';
import '../core/services/play_games_service.dart';
import 'components/particle_engine.dart';

class GameCoordinator extends ChangeNotifier {
  final LocalSaveRepository saveRepository;
  final BoardService boardService;
  final PieceGeneratorService pieceGenerator;
  final GridShiftService gridShiftService;
  final DifficultyService difficultyService;
  final DailyChallengeService dailyChallengeService;
  final AsmrAudioEngine audioEngine;
  final ParticleEngine particleEngine;
  final BillingService billingService;
  final AdService adService;
  final StreakService streakService;
  final PlayGamesService playGamesService;

  GameState _state;
  GameState? _previousState;
  GameTheme _theme;
  List<Achievement> _achievements = [];
  DailyChallenge? _currentDailyChallenge;
  List<String> _unlockedThemeIds = ['crystal_flow', 'neon_geometry'];
  StreakInfo _streakInfo = const StreakInfo();
  bool _hasDoubledScoreThisGame = false;

  Timer? _blitzTimer;
  Timer? _comboCalloutTimer;

  // Drag state
  int? draggingTrayIndex;
  Offset? dragPosition;
  bool isDirectCursor = false;
  Point<int>? hoveredGridCoord;
  bool isPlacementValid = false;

  GameState get state => _state;
  GameTheme get theme => _theme;
  List<Achievement> get achievements => _achievements;
  DailyChallenge? get currentDailyChallenge => _currentDailyChallenge;
  List<String> get unlockedThemeIds => _unlockedThemeIds;
  StreakInfo get streakInfo => _streakInfo;
  int get freeRerolls => _streakInfo.freeRerolls;
  int get freeRevives => _streakInfo.freeRevives;
  int get freeHammers => _streakInfo.freeHammers;
  int get freeTnts => _streakInfo.freeTnts;
  int get freeRotates => _streakInfo.freeRotates;
  int get freeUndos => _streakInfo.freeUndos;
  int get freeMagnets => _streakInfo.freeMagnets;
  int get coins => _streakInfo.coins;
  bool get isHammerModeActive => _state.isHammerModeActive;
  bool get isTntModeActive => _state.isTntModeActive;
  bool get isColorMagnetModeActive => _state.isColorMagnetModeActive;
  bool get canUndo => _previousState != null && !_state.isGameOver;
  BlockModel? get heldPiece => _state.heldPiece;
  bool _canHoldThisTurn = true;
  bool get canHoldThisTurn => _canHoldThisTurn;
  bool get hasDoubledScoreThisGame => _hasDoubledScoreThisGame;

  /// Notifier to request screen shake animations in UI on explosions and high combos
  final ValueNotifier<int> screenShakeNotifier = ValueNotifier(0);
  double screenShakeIntensity = 1.0;
  void triggerScreenShake([double intensity = 1.0]) {
    screenShakeIntensity = intensity;
    screenShakeNotifier.value++;
  }

  /// Recent placement coordinates and notifier for tactile squash & stretch physics
  List<Point<int>>? recentPlacementCoords;
  final ValueNotifier<int> recentPlacementNotifier = ValueNotifier(0);

  /// Notifier for 3D cinematic combo callout overlays ("COOL!", "AWESOME!", "UNSTOPPABLE!", "GODLIKE!")
  final ValueNotifier<String?> comboCalloutNotifier = ValueNotifier(null);
  void triggerComboCallout(String text) {
    _comboCalloutTimer?.cancel();
    comboCalloutNotifier.value = text;
    _comboCalloutTimer = Timer(const Duration(milliseconds: 1400), () {
      comboCalloutNotifier.value = null;
    });
  }

  GameCoordinator({
    required this.saveRepository,
    BoardService? boardService,
    PieceGeneratorService? pieceGenerator,
    GridShiftService? gridShiftService,
    DifficultyService? difficultyService,
    DailyChallengeService? dailyChallengeService,
    StreakService? streakService,
    AsmrAudioEngine? audioEngine,
    ParticleEngine? particleEngine,
    BillingService? billingService,
    AdService? adService,
    PlayGamesService? playGamesService,
  })  : boardService = boardService ?? const BoardService(),
        pieceGenerator = pieceGenerator ?? PieceGeneratorService(),
        gridShiftService = gridShiftService ?? GridShiftService(),
        difficultyService = difficultyService ?? DifficultyService(),
        dailyChallengeService = dailyChallengeService ?? const DailyChallengeService(),
        streakService = streakService ?? const StreakService(),
        audioEngine = audioEngine ?? AsmrAudioEngine(),
        particleEngine = particleEngine ?? ParticleEngine(),
        billingService = billingService ?? BillingService(saveRepository: saveRepository),
        adService = adService ??
            AdService(
              billingService:
                  billingService ?? BillingService(saveRepository: saveRepository),
            ),
        playGamesService = playGamesService ?? PlayGamesService(),
        _state = GameState(
          board: BoardState(),
          trayPieces: const [null, null, null],
        ),
        _theme = GameTheme.crystalFlow;

  Future<void> initialize() async {
    try {
      audioEngine.initialize();
    } catch (e) {
      debugPrint('audioEngine init non-fatal: $e');
    }

    try {
      final settings = await saveRepository.loadSettings();
      if (settings.isNotEmpty) {
        audioEngine.masterVolume = (settings['masterVolume'] as num?)?.toDouble() ?? 0.8;
        audioEngine.sfxVolume = (settings['sfxVolume'] as num?)?.toDouble() ?? 1.0;
        audioEngine.isHapticsEnabled = (settings['isHapticsEnabled'] as bool?) ?? true;
        final intensityStr = settings['hapticIntensity'] as String?;
        if (intensityStr != null) {
          try {
            audioEngine.hapticIntensity = HapticIntensity.values.byName(intensityStr);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('settings load non-fatal: $e');
    }

    try {
      await billingService.initialize();
    } catch (e) {
      debugPrint('billingService init non-fatal: $e');
    }

    try {
      await adService.initialize();
    } catch (e) {
      debugPrint('adService init non-fatal: $e');
    }

    try {
      playGamesService.initialize();
      playGamesService.addListener(() {
        if (playGamesService.isAuthenticated && _state.highScore > 0) {
          playGamesService.submitScore(_state.highScore);
        }
      });
    } catch (e) {
      debugPrint('playGamesService init non-fatal: $e');
    }

    int savedHighScore = 0;
    try {
      savedHighScore = await saveRepository.loadHighScore();
      if (savedHighScore > 0 && playGamesService.isAuthenticated) {
        playGamesService.submitScore(savedHighScore);
      }
      _achievements = await saveRepository.loadAchievements();
      _unlockedThemeIds = await saveRepository.loadUnlockedThemes();
      _streakInfo = await saveRepository.loadStreakInfo();
    } catch (e) {
      debugPrint('persistence load non-fatal: $e');
    }

    try {
      final now = DateTime.now();
      _currentDailyChallenge = dailyChallengeService.getChallengeForDate(now);
      final savedDaily = await saveRepository.loadDailyChallenge(_currentDailyChallenge!.dateString);
      if (savedDaily != null) {
        _currentDailyChallenge = savedDaily;
      }
    } catch (e) {
      debugPrint('dailyChallenge load non-fatal: $e');
    }

    try {
      final savedGame = await saveRepository.loadGameState();
      if (savedGame != null && !savedGame.isGameOver) {
        _state = savedGame;
        _theme = GameTheme.getById(savedGame.themeId);
      } else {
        final savedProfile = await saveRepository.loadPlayerProfile();
        await startNewGame(
          highScore: savedHighScore,
          profile: savedProfile,
        );
      }
    } catch (e) {
      debugPrint('gameState restore non-fatal: $e');
    }
    _checkThemeUnlocks();
    notifyListeners();
  }

  Future<void> startNewGame({
    GameMode mode = GameMode.classic,
    int? customSeed,
    int? highScore,
    PlayerSkillProfile? profile,
  }) async {
    _blitzTimer?.cancel();
    _previousState = null;
    difficultyService.resetSession();
    final currentHigh = highScore ?? _state.highScore;
    final currentProf = profile ?? _state.skillProfile;

    final initialBoard = BoardState(gridSize: 8);
    final initialPieces = pieceGenerator.generateTrayPieces(
      board: initialBoard,
      theme: _theme,
      playerSkillRating: currentProf.overallSkillRating,
      gameMode: mode,
      customSeed: customSeed,
    );

    _state = GameState(
      board: initialBoard,
      trayPieces: initialPieces,
      highScore: currentHigh,
      skillProfile: currentProf,
      gameMode: mode,
      themeId: _theme.id,
      score: 0,
      comboCount: 0,
      comboMultiplier: 1.0,
      highestCombo: 0,
      level: 1,
      xp: 0,
      isGameOver: false,
      movesCount: 0,
      totalLinesCleared: 0,
      blitzTimeRemaining: 60.0,
    );

    _hasDoubledScoreThisGame = false;
    _canHoldThisTurn = true;

    if (mode == GameMode.blitz) {
      _startBlitzTimer();
    }

    await saveRepository.saveGameState(_state);
    notifyListeners();
  }

  void _startBlitzTimer() {
    _blitzTimer?.cancel();
    _blitzTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_state.isGameOver || _state.gameMode != GameMode.blitz) {
        timer.cancel();
        return;
      }
      final current = _state.blitzTimeRemaining;
      final next = (current - 0.1).clamp(0.0, 999.0);
      if (next <= 0.0) {
        timer.cancel();
        _state = _state.copyWith(blitzTimeRemaining: 0.0, isGameOver: true);
        audioEngine.playGameOver();
        notifyListeners();
        saveRepository.saveGameState(_state);
      } else {
        _state = _state.copyWith(blitzTimeRemaining: next);
        notifyListeners();
      }
    });
  }

  /// Pause blitz countdown when navigating away or backgrounding
  void pauseBlitzTimer() {
    _blitzTimer?.cancel();
  }

  /// Resume blitz countdown when returning to GameScreen
  void resumeBlitzTimer() {
    if (_state.gameMode == GameMode.blitz && !_state.isGameOver && _state.blitzTimeRemaining > 0) {
      _startBlitzTimer();
    }
  }

  @override
  void dispose() {
    _blitzTimer?.cancel();
    _comboCalloutTimer?.cancel();
    comboCalloutNotifier.dispose();
    screenShakeNotifier.dispose();
    super.dispose();
  }

  void setTheme(GameTheme newTheme) {
    _theme = newTheme;
    _state = _state.copyWith(themeId: newTheme.id);
    saveRepository.saveGameState(_state);
    notifyListeners();
  }

  // --- TOUCH & DRAG PIPELINE ---

  void onDragStart(int trayIndex, Offset startPos, {bool isDirectCursor = false}) {
    if (_state.isGameOver || _state.trayPieces[trayIndex] == null) return;
    if (_state.isTntModeActive || _state.isHammerModeActive) {
      _state = _state.copyWith(
        isTntModeActive: false,
        isHammerModeActive: false,
      );
    }
    draggingTrayIndex = trayIndex;
    dragPosition = startPos;
    this.isDirectCursor = isDirectCursor;
    audioEngine.playPickup();
    notifyListeners();
  }

  void onDragUpdate(Offset currentPos, Rect boardRect, {bool? isDirectCursor}) {
    if (draggingTrayIndex == null) return;
    dragPosition = currentPos;
    if (isDirectCursor != null) {
      this.isDirectCursor = isDirectCursor;
    }

    final piece = _state.trayPieces[draggingTrayIndex!];
    if (piece == null) return;

    final cellSize = boardRect.width > 0 ? (boardRect.width / _state.board.gridSize) : 40.0;

    // Calculate vertical lift offset:
    // - Direct pointer (mouse / trackpad): lift is 0 so the preview and block center directly at the cursor tip.
    // - Touch: ergonomic lift so finger does not obscure the block.
    // - When dragging towards the top of the grid, dynamically taper the lift so the piece stays on the board.
    double liftY = 0.0;
    if (!this.isDirectCursor) {
      const defaultTouchLift = 60.0;
      final distAboveBoardTop = currentPos.dy - boardRect.top;
      if (distAboveBoardTop < defaultTouchLift && boardRect.top > 0) {
        // Taper lift smoothly as finger approaches or passes top of board
        liftY = distAboveBoardTop.clamp(0.0, defaultTouchLift);
      } else {
        liftY = defaultTouchLift;
      }
    }

    final targetCenter = Offset(currentPos.dx, currentPos.dy - liftY);

    // Stardust trail particle emitter behind moving block
    particleEngine.spawnDragStardust(
      x: targetCenter.dx,
      y: targetCenter.dy,
      color: piece.color,
    );

    // Bounding box offset to align targetCenter with piece geometric center
    final localX = targetCenter.dx - boardRect.left - (piece.width * cellSize) / 2.0;
    final localY = targetCenter.dy - boardRect.top - (piece.height * cellSize) / 2.0;

    final rawGx = (localX / cellSize).round();
    final rawGy = (localY / cellSize).round();

    final maxGx = _state.board.gridSize - piece.width;
    final maxGy = _state.board.gridSize - piece.height;

    // Boundary interaction zone around the board
    final horizMargin = cellSize * 1.0;
    final topMargin = cellSize * 1.5;
    final bottomMargin = cellSize * 0.8;

    final isWithinBoardBounds = boardRect.width > 0 &&
        currentPos.dx >= (boardRect.left - horizMargin) &&
        currentPos.dx <= (boardRect.right + horizMargin) &&
        targetCenter.dy >= (boardRect.top - topMargin) &&
        targetCenter.dy <= (boardRect.bottom + bottomMargin);

    if (isWithinBoardBounds) {
      // Clamp coordinates to valid board grid boundary limits (guarantees gy = 0 at the top)
      final gx = rawGx.clamp(0, maxGx);
      final gy = rawGy.clamp(0, maxGy);

      if (boardService.canPlaceBlock(_state.board, piece, gx, gy)) {
        if (!isPlacementValid || hoveredGridCoord?.x != gx || hoveredGridCoord?.y != gy) {
          audioEngine.playSnap();
        }
        isPlacementValid = true;
        hoveredGridCoord = Point<int>(gx, gy);
      } else {
        isPlacementValid = false;
        hoveredGridCoord = Point<int>(gx, gy);
      }
    } else {
      isPlacementValid = false;
      hoveredGridCoord = null;
    }

    notifyListeners();
  }

  Future<void> onDragEnd(Rect boardRect) async {
    if (draggingTrayIndex == null) return;

    final trayIdx = draggingTrayIndex!;
    if (trayIdx < 0 || trayIdx >= _state.trayPieces.length) {
      draggingTrayIndex = null;
      dragPosition = null;
      hoveredGridCoord = null;
      isDirectCursor = false;
      isPlacementValid = false;
      notifyListeners();
      return;
    }
    final piece = _state.trayPieces[trayIdx];
    final coord = hoveredGridCoord;

    draggingTrayIndex = null;
    dragPosition = null;
    hoveredGridCoord = null;
    isDirectCursor = false;

    if (piece != null && coord != null && isPlacementValid) {
      await _commitPlacement(piece: piece, trayIndex: trayIdx, targetX: coord.x, targetY: coord.y, boardRect: boardRect);
    }

    isPlacementValid = false;
    notifyListeners();
  }

  Future<void> _commitPlacement({
    required BlockModel piece,
    required int trayIndex,
    required int targetX,
    required int targetY,
    required Rect boardRect,
  }) async {
    // 0. Snapshot previous state for 1-step Undo (with targeting flags cleared)
    _previousState = _state.copyWith(
      isHammerModeActive: false,
      isTntModeActive: false,
      isColorMagnetModeActive: false,
    );

    // 1. Authoritative placement
    final preDensity = _state.board.density;
    var newBoard = boardService.placeBlock(_state.board, piece, targetX, targetY);

    // Audio & Haptic
    audioEngine.playPlacement(
      weightClass: piece.weightClass,
      soundProfile: _theme.soundProfile,
    );

    // Record recent placement coordinates for tactile squash & stretch physics
    recentPlacementCoords = piece.offsets
        .map((off) => Point(targetX + off.dx, targetY + off.dy))
        .toList();
    recentPlacementNotifier.value++;
    audioEngine.playSquashImpact();

    // Placement particles
    final cellSize = boardRect.width > 0 ? boardRect.width / _state.board.gridSize : 40.0;
    for (final off in piece.offsets) {
      final cx = boardRect.left + (targetX + off.dx + 0.5) * cellSize;
      final cy = boardRect.top + (targetY + off.dy + 0.5) * cellSize;
      particleEngine.spawnBurst(
        centerX: cx,
        centerY: cy,
        colors: _theme.particlePalette,
        count: 8,
      );
    }

    // Special block placement visual bursts
    if (piece.specialType == SpecialBlockType.rainbow) {
      for (final off in piece.offsets) {
        final cx = boardRect.left + (targetX + off.dx + 0.5) * cellSize;
        final cy = boardRect.top + (targetY + off.dy + 0.5) * cellSize;
        particleEngine.spawnRainbowPrismBurst(centerX: cx, centerY: cy, cellSize: cellSize);
      }
    } else if (piece.specialType == SpecialBlockType.ice) {
      for (final off in piece.offsets) {
        final cx = boardRect.left + (targetX + off.dx + 0.5) * cellSize;
        final cy = boardRect.top + (targetY + off.dy + 0.5) * cellSize;
        particleEngine.spawnIceShatter(centerX: cx, centerY: cy, cellSize: cellSize);
      }
    }

    // Update tray slot
    final updatedTray = List<BlockModel?>.from(_state.trayPieces);
    updatedTray[trayIndex] = null;

    // 2. Line Clear Detection
    final clearResult = boardService.detectAndClearLines(newBoard);

    // Ice block cracking sound
    if (clearResult.crackedIceCells.isNotEmpty) {
      audioEngine.playIceCrack();
    }

    // Ice block shattered on 2nd hit
    if (clearResult.shatteredIceCells.isNotEmpty) {
      audioEngine.playIceShatter();
      triggerScreenShake();
      for (final pt in clearResult.shatteredIceCells) {
        final cx = boardRect.left + (pt.x + 0.5) * cellSize;
        final cy = boardRect.top + (pt.y + 0.5) * cellSize;
        particleEngine.spawnIceShatter(centerX: cx, centerY: cy, cellSize: cellSize);
      }
    }

    // Lightning chain reaction strikes
    if (clearResult.lightningTriggerCells.isNotEmpty && clearResult.lightningTargetCells.isNotEmpty) {
      audioEngine.playLightningZap();
      triggerScreenShake();
      final triggerCount = clearResult.lightningTriggerCells.length;
      for (int i = 0; i < clearResult.lightningTargetCells.length; i++) {
        final fromPt = clearResult.lightningTriggerCells[i % triggerCount];
        final toPt = clearResult.lightningTargetCells[i];
        final fx = boardRect.left + (fromPt.x + 0.5) * cellSize;
        final fy = boardRect.top + (fromPt.y + 0.5) * cellSize;
        final tx = boardRect.left + (toPt.x + 0.5) * cellSize;
        final ty = boardRect.top + (toPt.y + 0.5) * cellSize;
        particleEngine.spawnLightningArc(fromX: fx, fromY: fy, toX: tx, toY: ty);
      }
    }

    // Coin awards
    if (clearResult.coinsEarned > 0) {
      audioEngine.playCoinCollect();
      _streakInfo = _streakInfo.copyWith(coins: _streakInfo.coins + clearResult.coinsEarned);
      unawaited(saveRepository.saveStreakInfo(_streakInfo));
      for (final off in piece.offsets) {
        final cx = boardRect.left + (targetX + off.dx + 0.5) * cellSize;
        final cy = boardRect.top + (targetY + off.dy + 0.5) * cellSize;
        particleEngine.spawnCoinBurst(centerX: cx, centerY: cy);
      }
    }

    // Rainbow prism line clear bursts
    if (clearResult.rainbowCells.isNotEmpty) {
      audioEngine.playAchievement();
      for (final rPt in clearResult.rainbowCells) {
        final rcx = boardRect.left + (rPt.x + 0.5) * cellSize;
        final rcy = boardRect.top + (rPt.y + 0.5) * cellSize;
        particleEngine.spawnRainbowPrismBurst(centerX: rcx, centerY: rcy, cellSize: cellSize);
      }
    }

    // Geode cracking & shattering
    if (clearResult.crackedGeodeCells.isNotEmpty) {
      audioEngine.playIceCrack();
    }
    if (clearResult.shatteredGeodeCells.isNotEmpty) {
      audioEngine.playAchievement();
      triggerScreenShake(1.5);
      triggerComboCallout('CRYSTAL SHATTER! 3x');
      for (final pt in clearResult.shatteredGeodeCells) {
        final cx = boardRect.left + (pt.x + 0.5) * cellSize;
        final cy = boardRect.top + (pt.y + 0.5) * cellSize;
        particleEngine.spawnGeodeShatter(centerX: cx, centerY: cy, cellSize: cellSize);
      }
    }

    // Time-bomb defused and detonated
    if (clearResult.detonatedTimeBombCells.isNotEmpty) {
      audioEngine.playExplosion();
      triggerScreenShake(1.6);
      triggerComboCallout('BOMB DEFUSED! +25 💰');
      for (final pt in clearResult.detonatedTimeBombCells) {
        final cx = boardRect.left + (pt.x + 0.5) * cellSize;
        final cy = boardRect.top + (pt.y + 0.5) * cellSize;
        particleEngine.spawnTimeBombDetonation(centerX: cx, centerY: cy, cellSize: cellSize);
      }
    }

    // Portal vortex resonance
    if (clearResult.portalTriggerCells.isNotEmpty) {
      audioEngine.playAchievement();
      triggerScreenShake(1.4);
      triggerComboCallout('WARP RESONANCE!');
      for (final pt in [...clearResult.portalTriggerCells, ...clearResult.portalTargetCells]) {
        final cx = boardRect.left + (pt.x + 0.5) * cellSize;
        final cy = boardRect.top + (pt.y + 0.5) * cellSize;
        particleEngine.spawnPortalVortex(centerX: cx, centerY: cy);
      }
    }

    int newCombo = _state.comboCount;
    double newMultiplier = 1.0;
    if (clearResult.clearedLinesCount > 0) {
      newCombo += 1;
      newMultiplier = 1.0 + (newCombo * 0.5);

      // Play royalty-free brick break blast sound effect
      audioEngine.playBrickBlast(
        linesCount: clearResult.clearedLinesCount,
        comboCount: newCombo,
      );

      // Tiered screen shake based on blast magnitude
      if (clearResult.clearedLinesCount >= 3 || newCombo >= 5) {
        triggerScreenShake(1.8);
      } else if (clearResult.clearedLinesCount >= 2 || newCombo >= 3) {
        triggerScreenShake(1.2);
      } else {
        triggerScreenShake(0.6);
      }

      // Combo & Multi-Blast 3D Cinematic Callouts
      if (newCombo >= 2) {
        String callout = 'NICE!';
        if (newCombo == 2) callout = 'GREAT!';
        if (newCombo == 3) callout = 'AWESOME!';
        if (newCombo == 4) callout = 'UNSTOPPABLE!';
        if (newCombo >= 5) callout = 'GODLIKE!';
        triggerComboCallout(callout);
      } else if (clearResult.clearedLinesCount >= 2) {
        if (clearResult.clearedLinesCount == 2) {
          triggerComboCallout('DOUBLE BLAST!');
        } else if (clearResult.clearedLinesCount == 3) {
          triggerComboCallout('TRIPLE BLAST!');
        } else {
          triggerComboCallout('MEGA CLEAR!');
        }
      }

      // Explosive brick break blast particles with Domino outward wave distribution
      final shardsPerCell = newCombo >= 5 ? 20 : 10;
      final double centroidX = clearResult.clearedCells.fold(0.0, (sum, pt) => sum + pt.x) / clearResult.clearedCells.length;
      final double centroidY = clearResult.clearedCells.fold(0.0, (sum, pt) => sum + pt.y) / clearResult.clearedCells.length;

      for (final pt in clearResult.clearedCells) {
        final cx = boardRect.left + (pt.x + 0.5) * cellSize;
        final cy = boardRect.top + (pt.y + 0.5) * cellSize;
        final brickColor = newBoard.cells[pt.y][pt.x].color;

        final dist = sqrt(pow(pt.x - centroidX, 2) + pow(pt.y - centroidY, 2));
        final extraShards = (dist * 1.5).round();

        particleEngine.spawnBrickBlast(
          centerX: cx,
          centerY: cy,
          brickColor: brickColor != Colors.transparent ? brickColor : _theme.accent,
          shardCount: shardsPerCell + extraShards,
          cellSize: cellSize,
        );
      }
    } else {
      newCombo = 0;
      newMultiplier = 1.0;

      // Check for Danger Warning heartbeat when grid is near full
      int occupiedCount = 0;
      final totalCells = newBoard.gridSize * newBoard.gridSize;
      for (int y = 0; y < newBoard.gridSize; y++) {
        for (int x = 0; x < newBoard.gridSize; x++) {
          if (newBoard.cells[y][x].isOccupied) occupiedCount++;
        }
      }
      final occupancyRate = occupiedCount / totalCells;
      if (occupancyRate >= 0.75) {
        audioEngine.playDangerHeartbeat(urgency: occupancyRate >= 0.85 ? 1.4 : 1.0);
      }
    }

    // Special Block detonator particles (TNT Bomb 3x3 or Laser Beam)
    if (piece.specialType == SpecialBlockType.bomb) {
      audioEngine.playBrickBlast(linesCount: 3, comboCount: max(2, newCombo));
      particleEngine.spawnTntExplosion(
        centerX: boardRect.left + (targetX + 0.5) * cellSize,
        centerY: boardRect.top + (targetY + 0.5) * cellSize,
        cellSize: cellSize,
      );
      triggerScreenShake();
    } else if (piece.specialType == SpecialBlockType.laser) {
      audioEngine.playBrickBlast(linesCount: 2, comboCount: max(1, newCombo));
      for (int i = 0; i < _state.board.gridSize; i++) {
        particleEngine.spawnBrickBlast(
          centerX: boardRect.left + (i + 0.5) * cellSize,
          centerY: boardRect.top + (targetY + 0.5) * cellSize,
          brickColor: const Color(0xFF00E5FF),
          shardCount: 6,
          cellSize: cellSize,
        );
        particleEngine.spawnBrickBlast(
          centerX: boardRect.left + (targetX + 0.5) * cellSize,
          centerY: boardRect.top + (i + 0.5) * cellSize,
          brickColor: const Color(0xFF00E5FF),
          shardCount: 6,
          cellSize: cellSize,
        );
      }
    }

    newBoard = clearResult.newBoard;
    // Tick move countdowns for Time-Bomb blocks
    newBoard = boardService.tickMoveEnd(newBoard);

    // Rising Lava Mode: every 5 moves without a line clear, magma advances from the bottom!
    if (_state.gameMode == GameMode.lava && clearResult.clearedLinesCount == 0 && (_state.movesCount % 5 == 4)) {
      newBoard = boardService.advanceLava(newBoard);
      audioEngine.playSquashImpact();
      triggerScreenShake(1.2);
      triggerComboCallout('LAVA ADVANCE!');
    }

    // 3. Score Calculation with Fever Overdrive (3x Multiplier at 5+ combo)
    final geodeBonus = clearResult.shatteredGeodeCells.length * 300;
    final rawMoveScore = boardService.calculateScore(
      placedCellsCount: piece.cellCount,
      linesCleared: clearResult.clearedLinesCount,
      comboCount: newCombo,
      weightClass: piece.weightClass,
      hasBloomBonus: clearResult.hasBloomBonus,
    );
    final feverMultiplier = newCombo >= 5 ? 3.0 : 1.0;
    final moveScore = ((rawMoveScore + geodeBonus) * feverMultiplier).round();

    _canHoldThisTurn = true;

    final newScore = _state.score + moveScore;
    final newHighScore = max(newScore, _state.highScore);
    final newHighestCombo = max(newCombo, _state.highestCombo);
    final newMoves = _state.movesCount + 1;
    final newTotalClears = _state.totalLinesCleared + clearResult.clearedLinesCount;

    // Blitz mode bonus time extension: +2.5s per line cleared + 1s * combo
    double updatedBlitzTime = _state.blitzTimeRemaining;
    if (_state.gameMode == GameMode.blitz && clearResult.clearedLinesCount > 0) {
      final bonusSeconds = 2.5 * clearResult.clearedLinesCount + 1.0 * newCombo;
      final currentRemain = _state.blitzTimeRemaining;
      updatedBlitzTime = min(90.0, currentRemain + bonusSeconds);
    }

    // 4. Update Difficulty & Player Profile
    difficultyService.recordMove(
      MoveMetric(
        scoreEarned: moveScore,
        linesCleared: clearResult.clearedLinesCount,
        combo: newCombo,
        boardDensityBeforeMove: preDensity,
        usedSpecialBlock: piece.specialType != SpecialBlockType.none,
      ),
    );
    final updatedProfile = difficultyService.updateProfile(_state.skillProfile);

    // 5. Grid Shift Evaluation
    String? shiftNotice;
    final shouldShift = gridShiftService.shouldTriggerShift(
      comboCount: newCombo,
      lastPlacedWeight: piece.weightClass,
      boardDensity: newBoard.density,
      allowGridShift: _state.gameMode.allowGridShift,
      frequencyMultiplier: _state.gameMode.gridShiftFrequencyMultiplier,
    );

    if (shouldShift) {
      final shiftRes = gridShiftService.executeSafeShift(newBoard);
      if (shiftRes.didShift) {
        newBoard = shiftRes.board;
        shiftNotice = shiftRes.description;
        audioEngine.playGridShift();
      }
    }

    // Morph unplaced morph pieces in tray to next rotational shape
    for (int i = 0; i < updatedTray.length; i++) {
      final p = updatedTray[i];
      if (p != null && p.specialType == SpecialBlockType.morph) {
        updatedTray[i] = p.rotatedClockwise();
      }
    }

    // 6. Tray replenishment if all pieces placed
    var finalTray = updatedTray;
    if (finalTray.every((p) => p == null)) {
      finalTray = pieceGenerator.generateTrayPieces(
        board: newBoard,
        theme: _theme,
        playerSkillRating: updatedProfile.overallSkillRating,
        gameMode: _state.gameMode,
      );
    }

    // 7. Check Game Over (only game over if neither tray pieces nor held piece can be placed)
    bool isOver = false;
    final hasTrayMoves = boardService.hasValidMovesRemaining(newBoard, finalTray);
    final hasHeldMoves = _state.heldPiece != null &&
        boardService.hasValidMovesRemaining(newBoard, [_state.heldPiece]);
    if (_state.gameMode.hasFailState && !hasTrayMoves && !hasHeldMoves) {
      isOver = true;
      audioEngine.playGameOver();
      await saveRepository.recordGameCompletion(
        finalScore: newScore,
        linesCleared: newTotalClears,
        maxCombo: newHighestCombo,
        movesCount: newMoves,
      );
    }

    // Commit state
    _state = _state.copyWith(
      board: newBoard,
      trayPieces: finalTray,
      score: newScore,
      highScore: newHighScore,
      comboCount: newCombo,
      comboMultiplier: newMultiplier,
      highestCombo: newHighestCombo,
      movesCount: newMoves,
      totalLinesCleared: newTotalClears,
      skillProfile: updatedProfile,
      isGameOver: isOver,
      pendingShiftWarning: () => shiftNotice,
      blitzTimeRemaining: updatedBlitzTime,
    );

    // Update Daily Challenge progress
    _updateDailyChallengeProgress(
      newScore: newScore,
      newCombo: newCombo,
      linesCleared: clearResult.clearedLinesCount,
      didShift: shouldShift,
    );

    // Update Achievements
    _checkAchievements();
    _checkThemeUnlocks();

    // Persist
    await saveRepository.saveGameState(_state);
    await saveRepository.saveHighScore(newHighScore);
    await saveRepository.savePlayerProfile(updatedProfile);
    playGamesService.submitScore(newHighScore);

    notifyListeners();
  }

  void _updateDailyChallengeProgress({
    required int newScore,
    required int newCombo,
    required int linesCleared,
    required bool didShift,
  }) {
    if (_currentDailyChallenge == null || _currentDailyChallenge!.isCompleted) return;

    var challenge = _currentDailyChallenge!;
    int progress = challenge.currentProgress;
    bool completed = false;

    switch (challenge.objectiveType) {
      case ChallengeObjectiveType.scoreTarget:
        progress = newScore;
        if (progress >= challenge.targetValue) completed = true;
        break;
      case ChallengeObjectiveType.comboTarget:
        progress = max(progress, newCombo);
        if (progress >= challenge.targetValue) completed = true;
        break;
      case ChallengeObjectiveType.multiClearCount:
        if (linesCleared > 1) progress += 1;
        if (progress >= challenge.targetValue) completed = true;
        break;
      case ChallengeObjectiveType.gridShiftSurvive:
        if (didShift) progress += 1;
        if (progress >= challenge.targetValue) completed = true;
        break;
      case ChallengeObjectiveType.survivalTurns:
        progress = _state.movesCount;
        if (progress >= challenge.targetValue) completed = true;
        break;
    }

    if (completed && !challenge.isCompleted) {
      audioEngine.playAchievement();
    }

    _currentDailyChallenge = challenge.copyWith(
      currentProgress: progress,
      isCompleted: completed,
      bestScore: max(challenge.bestScore, newScore),
    );

    saveRepository.saveDailyChallenge(_currentDailyChallenge!);
  }

  void _checkAchievements() {
    final updated = <Achievement>[];
    bool unlockedAny = false;

    for (final ach in _achievements) {
      if (ach.isUnlocked) {
        updated.add(ach);
        continue;
      }

      int progress = ach.currentProgress;
      bool unlock = false;

      switch (ach.id) {
        case 'score_1k':
        case 'score_10k':
        case 'score_50k':
          progress = max(progress, _state.score);
          if (progress >= ach.targetValue) unlock = true;
          break;
        case 'combo_3':
        case 'combo_6':
        case 'combo_10':
          progress = max(progress, _state.highestCombo);
          if (progress >= ach.targetValue) unlock = true;
          break;
        case 'daily_first':
          if (_currentDailyChallenge?.isCompleted ?? false) {
            progress = 1;
            unlock = true;
          }
          break;
        default:
          break;
      }

      if (unlock) {
        unlockedAny = true;
        updated.add(ach.copyWith(currentProgress: ach.targetValue, isUnlocked: true));
        playGamesService.unlockAchievement(ach.id);
      } else {
        updated.add(ach.copyWith(currentProgress: progress));
      }
    }

    if (unlockedAny) {
      audioEngine.playAchievement();
    }
    _achievements = updated;
    saveRepository.saveAchievements(_achievements);
  }

  // Revive game by clearing the 3 densest rows and generating fresh fitting pieces
  Future<void> reviveGame() async {
    if (!_state.isGameOver) return;

    final rowOccupancy = <int, int>{};
    for (int y = 0; y < _state.board.gridSize; y++) {
      int count = 0;
      for (int x = 0; x < _state.board.gridSize; x++) {
        if (_state.board.isOccupied(x, y)) count++;
      }
      rowOccupancy[y] = count;
    }

    final sorted = rowOccupancy.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final rowsToClear = sorted.take(3).map((e) => e.key).toSet();

    final currentCells = _state.board.cells;
    final newCells = List.generate(
      _state.board.gridSize,
      (y) => List.generate(
        _state.board.gridSize,
        (x) => rowsToClear.contains(y)
            ? CellModel(x: x, y: y)
            : currentCells[y][x],
      ),
    );

    final clearedBoard = BoardState(
      gridSize: _state.board.gridSize,
      cells: newCells,
    );

    audioEngine.playClear(linesCount: 3, comboCount: 1);

    // Guaranteed fit tray pieces
    final newTray = pieceGenerator.generateTrayPieces(
      board: clearedBoard,
      theme: _theme,
      playerSkillRating: _state.skillProfile.overallSkillRating,
      gameMode: _state.gameMode,
    );

    _state = _state.copyWith(
      board: clearedBoard,
      trayPieces: newTray,
      isGameOver: false,
      isHammerModeActive: false,
    );

    _canHoldThisTurn = true;

    await saveRepository.saveGameState(_state);
    notifyListeners();
  }

  // --- BOOSTER & POWER-UP METHODS ---

  /// Reroll the current tray pieces (either with banked free reroll or after rewarded video ad)
  Future<void> rerollPieces({bool isFree = false}) async {
    if (_state.isGameOver) return;

    if (isFree) {
      if (_streakInfo.freeRerolls <= 0) return;
      _streakInfo = _streakInfo.copyWith(
        freeRerolls: _streakInfo.freeRerolls - 1,
      );
      await saveRepository.saveStreakInfo(_streakInfo);
    } else {
      // Watching a rewarded ad grants +1 free reroll to player's bank
      _streakInfo = _streakInfo.copyWith(
        freeRerolls: _streakInfo.freeRerolls + 1,
      );
      await saveRepository.saveStreakInfo(_streakInfo);
      audioEngine.playAchievement();
    }

    final newTray = pieceGenerator.generateTrayPieces(
      board: _state.board,
      theme: _theme,
      playerSkillRating: _state.skillProfile.overallSkillRating,
      gameMode: _state.gameMode,
    );

    audioEngine.playGridShift();

    _previousState = null;
    _state = _state.copyWith(trayPieces: newTray);
    await saveRepository.saveGameState(_state);
    notifyListeners();
  }

  Future<void> grantRerollViaAd() async {
    _streakInfo = _streakInfo.copyWith(freeRerolls: _streakInfo.freeRerolls + 1);
    await saveRepository.saveStreakInfo(_streakInfo);
    audioEngine.playAchievement();
    notifyListeners();
  }

  /// Restores held piece back to first available tray slot
  void releaseHeldPiece() {
    if (_state.isGameOver || _state.heldPiece == null) return;
    final emptySlot = _state.trayPieces.indexWhere((p) => p == null);
    if (emptySlot != -1) {
      final updatedTray = List<BlockModel?>.from(_state.trayPieces);
      updatedTray[emptySlot] = _state.heldPiece;
      _state = _state.copyWith(
        trayPieces: updatedTray,
        heldPiece: () => null,
      );
      audioEngine.playPickup();
      notifyListeners();
    }
  }

  /// Toggle Sledgehammer tool mode
  void toggleHammerMode() {
    if (_state.isGameOver) return;
    final next = !_state.isHammerModeActive;
    _state = _state.copyWith(
      isHammerModeActive: next,
      isTntModeActive: false,
    );
    notifyListeners();
  }

  /// Cancel Sledgehammer tool mode
  void cancelHammerMode() {
    if (_state.isHammerModeActive) {
      _state = _state.copyWith(isHammerModeActive: false);
      notifyListeners();
    }
  }

  /// Toggle TNT Bomb detonator tool mode
  void toggleTntMode() {
    if (_state.isGameOver) return;
    final next = !_state.isTntModeActive;
    _state = _state.copyWith(
      isTntModeActive: next,
      isHammerModeActive: false,
    );
    notifyListeners();
  }

  /// Cancel TNT Bomb detonator tool mode
  void cancelTntMode() {
    if (_state.isTntModeActive) {
      _state = _state.copyWith(isTntModeActive: false);
      notifyListeners();
    }
  }

  /// Detonate a 3x3 explosive blast centered at (cx, cy) on the board
  Future<void> detonateTnt(int cx, int cy, Rect boardRect) async {
    if (!_state.isTntModeActive || _state.isGameOver) return;
    if (!_state.board.isValidCoord(cx, cy)) return;

    if (_streakInfo.freeTnts > 0) {
      _streakInfo = _streakInfo.copyWith(freeTnts: _streakInfo.freeTnts - 1);
      await saveRepository.saveStreakInfo(_streakInfo);
    }
    _previousState = null;

    final detonateResult = boardService.detonateArea(_state.board, cx, cy, radius: 1);
    final cellSize = boardRect.width > 0 ? boardRect.width / _state.board.gridSize : 40.0;
    final pixelCx = boardRect.left + (cx + 0.5) * cellSize;
    final pixelCy = boardRect.top + (cy + 0.5) * cellSize;

    // Trigger high-impact cinematic explosion effects
    particleEngine.spawnTntExplosion(
      centerX: pixelCx,
      centerY: pixelCy,
      cellSize: cellSize,
    );

    // Audio & Haptics
    audioEngine.playBrickBlast(linesCount: 3, comboCount: 3);
    triggerScreenShake();

    // Score calculation: 150 points for blast + 35 pts per destroyed cell
    final blastScore = 150 + (detonateResult.destroyedCount * 35);
    int totalScoreBonus = blastScore;

    // Check if line clears formed after detonation
    final clearResult = boardService.detectAndClearLines(detonateResult.newBoard);
    final finalBoard = clearResult.clearedLinesCount > 0 ? clearResult.newBoard : detonateResult.newBoard;

    if (clearResult.clearedLinesCount > 0) {
      final lineScore = boardService.calculateScore(
        placedCellsCount: 0,
        linesCleared: clearResult.clearedLinesCount,
        comboCount: 1,
        weightClass: BlockWeightClass.normal,
        hasBloomBonus: clearResult.hasBloomBonus,
      );
      totalScoreBonus += lineScore;

      for (final pt in clearResult.clearedCells) {
        final cx = boardRect.left + (pt.x + 0.5) * cellSize;
        final cy = boardRect.top + (pt.y + 0.5) * cellSize;
        particleEngine.spawnBrickBlast(
          centerX: cx,
          centerY: cy,
          brickColor: const Color(0xFFFF5722),
          shardCount: 8,
          cellSize: cellSize,
        );
      }
    }

    final newScore = _state.score + totalScoreBonus;
    final previousHigh = _state.highScore;
    final newHigh = max(newScore, previousHigh);

    _state = _state.copyWith(
      board: finalBoard,
      score: newScore,
      highScore: newHigh,
      isTntModeActive: false,
    );

    _checkAchievements();
    _checkThemeUnlocks();

    await saveRepository.saveGameState(_state);
    if (newHigh > previousHigh) {
      await saveRepository.saveHighScore(newHigh);
      playGamesService.submitScore(newHigh);
    }
    notifyListeners();
  }

  /// Watch a rewarded ad to gain +1 TNT Bomb and immediately activate detonation targeting
  Future<void> grantTntViaAd() async {
    _streakInfo = _streakInfo.copyWith(
      freeTnts: _streakInfo.freeTnts + 1,
    );
    await saveRepository.saveStreakInfo(_streakInfo);
    audioEngine.playAchievement();

    _state = _state.copyWith(
      isTntModeActive: true,
      isHammerModeActive: false,
      isColorMagnetModeActive: false,
    );
    notifyListeners();
  }

  /// Rotate a piece in the tray clockwise by 90 degrees
  Future<bool> rotatePiece(int trayIndex, {bool isFree = false}) async {
    if (_state.isGameOver) return false;
    if (trayIndex < 0 || trayIndex >= _state.trayPieces.length) return false;
    final piece = _state.trayPieces[trayIndex];
    if (piece == null) return false;

    if (isFree) {
      if (_streakInfo.freeRotates <= 0) return false;
      _streakInfo = _streakInfo.copyWith(freeRotates: _streakInfo.freeRotates - 1);
      await saveRepository.saveStreakInfo(_streakInfo);
    }

    final rotated = piece.rotatedClockwise();
    final updatedTray = List<BlockModel?>.from(_state.trayPieces);
    updatedTray[trayIndex] = rotated;

    audioEngine.playRotate();
    _state = _state.copyWith(trayPieces: updatedTray);
    await saveRepository.saveGameState(_state);
    notifyListeners();
    return true;
  }

  Future<void> grantRotateViaAd() async {
    _streakInfo = _streakInfo.copyWith(freeRotates: _streakInfo.freeRotates + 1);
    await saveRepository.saveStreakInfo(_streakInfo);
    audioEngine.playAchievement();
    notifyListeners();
  }

  /// Undo the last placed piece and restore previous board and tray state
  Future<bool> undoMove({bool isFree = false}) async {
    if (!canUndo) return false;

    if (isFree) {
      if (_streakInfo.freeUndos <= 0) return false;
      _streakInfo = _streakInfo.copyWith(freeUndos: _streakInfo.freeUndos - 1);
      await saveRepository.saveStreakInfo(_streakInfo);
    }

    final currentHigh = max(_state.highScore, _previousState!.highScore);
    _state = _previousState!.copyWith(highScore: currentHigh);
    _previousState = null;
    draggingTrayIndex = null;
    dragPosition = null;
    hoveredGridCoord = null;
    isPlacementValid = false;
    _canHoldThisTurn = true;
    audioEngine.playUndo();
    await saveRepository.saveGameState(_state);
    notifyListeners();
    return true;
  }

  Future<void> grantUndoViaAd() async {
    _streakInfo = _streakInfo.copyWith(freeUndos: _streakInfo.freeUndos + 1);
    await saveRepository.saveStreakInfo(_streakInfo);
    audioEngine.playAchievement();
    notifyListeners();
  }

  /// Toggle Color Magnet tool mode
  void toggleColorMagnetMode() {
    if (_state.isGameOver) return;
    final next = !_state.isColorMagnetModeActive;
    _state = _state.copyWith(
      isColorMagnetModeActive: next,
      isHammerModeActive: false,
      isTntModeActive: false,
    );
    notifyListeners();
  }

  /// Cancel Color Magnet tool mode
  void cancelColorMagnetMode() {
    if (_state.isColorMagnetModeActive) {
      _state = _state.copyWith(isColorMagnetModeActive: false);
      notifyListeners();
    }
  }

  /// Execute Color Magnet dissolving all blocks of the selected color
  Future<void> executeColorMagnet(int cx, int cy, Rect boardRect) async {
    if (!_state.isColorMagnetModeActive || _state.isGameOver) return;
    if (!_state.board.isValidCoord(cx, cy)) return;
    final targetCell = _state.board.getCell(cx, cy);
    if (!targetCell.isOccupied) return;

    if (_streakInfo.freeMagnets > 0) {
      _streakInfo = _streakInfo.copyWith(freeMagnets: _streakInfo.freeMagnets - 1);
      await saveRepository.saveStreakInfo(_streakInfo);
    }
    _previousState = null;

    final targetColorValue = targetCell.colorValue;
    final dissolveResult = boardService.dissolveColor(_state.board, targetColorValue);
    final cellSize = boardRect.width > 0 ? boardRect.width / _state.board.gridSize : 40.0;

    // Audio & Haptic & Particles
    audioEngine.playColorMagnet();
    audioEngine.playBrickBlast(linesCount: 2, comboCount: 2);
    triggerScreenShake();

    for (final pt in dissolveResult.clearedCells) {
      final px = boardRect.left + (pt.x + 0.5) * cellSize;
      final py = boardRect.top + (pt.y + 0.5) * cellSize;
      particleEngine.spawnBrickBlast(
        centerX: px,
        centerY: py,
        brickColor: targetCell.color,
        shardCount: 12,
        cellSize: cellSize,
      );
    }

    final blastScore = 120 + (dissolveResult.destroyedCount * 30);
    int totalScoreBonus = blastScore;

    final clearResult = boardService.detectAndClearLines(dissolveResult.newBoard);
    final finalBoard = clearResult.clearedLinesCount > 0 ? clearResult.newBoard : dissolveResult.newBoard;

    if (clearResult.clearedLinesCount > 0) {
      final lineScore = boardService.calculateScore(
        placedCellsCount: 0,
        linesCleared: clearResult.clearedLinesCount,
        comboCount: 1,
        weightClass: BlockWeightClass.normal,
        hasBloomBonus: clearResult.hasBloomBonus,
      );
      totalScoreBonus += lineScore;
    }

    final newScore = _state.score + totalScoreBonus;
    final previousHigh = _state.highScore;
    final newHigh = max(newScore, previousHigh);

    _state = _state.copyWith(
      board: finalBoard,
      score: newScore,
      highScore: newHigh,
      isColorMagnetModeActive: false,
    );

    _checkAchievements();
    _checkThemeUnlocks();

    await saveRepository.saveGameState(_state);
    if (newHigh > previousHigh) {
      await saveRepository.saveHighScore(newHigh);
      playGamesService.submitScore(newHigh);
    }
    notifyListeners();
  }

  Future<void> grantColorMagnetViaAd() async {
    _streakInfo = _streakInfo.copyWith(freeMagnets: _streakInfo.freeMagnets + 1);
    await saveRepository.saveStreakInfo(_streakInfo);
    audioEngine.playAchievement();
    _state = _state.copyWith(
      isColorMagnetModeActive: true,
      isHammerModeActive: false,
      isTntModeActive: false,
    );
    notifyListeners();
  }

  /// Smash an occupied cell on the board using the Sledgehammer
  Future<void> smashCell(int x, int y, Rect boardRect) async {
    if (!_state.isHammerModeActive || _state.isGameOver) return;
    if (!_state.board.isValidCoord(x, y)) return;
    final cell = _state.board.getCell(x, y);
    if (!cell.isOccupied) return;

    if (_streakInfo.freeHammers > 0) {
      _streakInfo = _streakInfo.copyWith(freeHammers: _streakInfo.freeHammers - 1);
      await saveRepository.saveStreakInfo(_streakInfo);
    }
    _previousState = null;

    final updatedBoard = boardService.smashCell(_state.board, x, y);
    final cellSize = boardRect.width > 0 ? boardRect.width / _state.board.gridSize : 40.0;
    final cx = boardRect.left + (x + 0.5) * cellSize;
    final cy = boardRect.top + (y + 0.5) * cellSize;

    particleEngine.spawnBrickBlast(
      centerX: cx,
      centerY: cy,
      brickColor: cell.color,
      shardCount: 16,
      cellSize: cellSize,
    );

    audioEngine.playBrickBlast(linesCount: 1, comboCount: 1);
    triggerScreenShake();

    // Check if line clears formed after smash
    final clearResult = boardService.detectAndClearLines(updatedBoard);
    final finalBoard = clearResult.clearedLinesCount > 0 ? clearResult.newBoard : updatedBoard;

    int extraScore = 50;
    if (clearResult.clearedLinesCount > 0) {
      final lineScore = boardService.calculateScore(
        placedCellsCount: 0,
        linesCleared: clearResult.clearedLinesCount,
        comboCount: 1,
        weightClass: BlockWeightClass.normal,
        hasBloomBonus: clearResult.hasBloomBonus,
      );
      extraScore += lineScore;
      for (final pt in clearResult.clearedCells) {
        final pcx = boardRect.left + (pt.x + 0.5) * cellSize;
        final pcy = boardRect.top + (pt.y + 0.5) * cellSize;
        particleEngine.spawnBrickBlast(
          centerX: pcx,
          centerY: pcy,
          brickColor: const Color(0xFF38BDF8),
          shardCount: 8,
          cellSize: cellSize,
        );
      }
    }

    final newScore = _state.score + extraScore;
    final previousHigh = _state.highScore;
    final newHigh = max(newScore, previousHigh);

    _state = _state.copyWith(
      board: finalBoard,
      score: newScore,
      highScore: newHigh,
      isHammerModeActive: false,
    );

    _checkAchievements();
    _checkThemeUnlocks();

    await saveRepository.saveGameState(_state);
    if (newHigh > previousHigh) {
      await saveRepository.saveHighScore(newHigh);
      playGamesService.submitScore(newHigh);
    }
    notifyListeners();
  }

  /// Watch a rewarded ad to gain +1 Sledgehammer and immediately activate it
  Future<void> grantHammerViaAd() async {
    _streakInfo = _streakInfo.copyWith(
      freeHammers: _streakInfo.freeHammers + 1,
    );
    await saveRepository.saveStreakInfo(_streakInfo);
    audioEngine.playAchievement();

    _state = _state.copyWith(isHammerModeActive: true);
    notifyListeners();
  }

  /// Stash a piece from the tray into the Hold slot (or swap with held piece)
  Future<void> holdPiece(int trayIndex) async {
    if (_state.isGameOver) return;
    if (trayIndex < 0 || trayIndex >= _state.trayPieces.length) return;
    final pieceToHold = _state.trayPieces[trayIndex];
    final prevHeld = _state.heldPiece;
    if (pieceToHold == null && prevHeld == null) return;

    var updatedTray = List<BlockModel?>.from(_state.trayPieces);
    updatedTray[trayIndex] = prevHeld;

    // If holding the last remaining piece left the tray completely empty,
    // immediately replenish the tray with 3 fresh pieces so the game can continue!
    if (updatedTray.every((p) => p == null)) {
      updatedTray = pieceGenerator.generateTrayPieces(
        board: _state.board,
        theme: _theme,
        playerSkillRating: _state.skillProfile.overallSkillRating,
        gameMode: _state.gameMode,
      );
    }

    // Check game over if neither tray nor held piece has valid moves
    bool isOver = false;
    final hasTrayMoves = boardService.hasValidMovesRemaining(_state.board, updatedTray);
    final hasHeldMoves = pieceToHold != null &&
        boardService.hasValidMovesRemaining(_state.board, [pieceToHold]);
    if (_state.gameMode.hasFailState && !hasTrayMoves && !hasHeldMoves) {
      isOver = true;
      audioEngine.playGameOver();
    }

    _state = _state.copyWith(
      trayPieces: updatedTray,
      heldPiece: () => pieceToHold,
      isGameOver: isOver,
    );

    _canHoldThisTurn = false;
    audioEngine.playGridShift();

    await saveRepository.saveGameState(_state);
    notifyListeners();
  }

  /// Unlock emergency hold stash via Rewarded Ad
  Future<void> grantEmergencyHoldViaAd(int trayIndex) async {
    _canHoldThisTurn = true;
    audioEngine.playAchievement();
    await holdPiece(trayIndex);
  }

  /// Transform the first tray piece into an explosive TNT Bomb block via Rewarded Ad
  Future<void> grantTntBlockViaAd() async {
    if (_state.isGameOver) return;

    final tntBlock = BlockModel(
      id: 'tnt_${DateTime.now().millisecondsSinceEpoch}',
      shapeName: 'tnt_bomb',
      width: 1,
      height: 1,
      offsets: const [BlockOffset(0, 0)],
      colorValue: 0xFFFF5722, // Fiery neon orange
      weightClass: BlockWeightClass.heavy,
      specialType: SpecialBlockType.bomb,
      skinStyle: BlockSkinStyle.gem,
    );

    final updatedTray = List<BlockModel?>.from(_state.trayPieces);
    int targetSlot = updatedTray.indexWhere((p) => p == null);
    if (targetSlot == -1) targetSlot = 0;
    updatedTray[targetSlot] = tntBlock;

    audioEngine.playAchievement();

    _state = _state.copyWith(trayPieces: updatedTray);
    await saveRepository.saveGameState(_state);
    notifyListeners();
  }

  /// Double endgame score and XP after player watches rewarded ad
  Future<void> doubleEndgameScore() async {
    if (!_state.isGameOver || _hasDoubledScoreThisGame) return;

    _hasDoubledScoreThisGame = true;
    final doubledScore = _state.score * 2;
    final doubledXp = _state.xp + _state.score;
    final newHigh = max(doubledScore, _state.highScore);

    audioEngine.playAchievement();

    _state = _state.copyWith(
      score: doubledScore,
      xp: doubledXp,
      highScore: newHigh,
    );

    _checkThemeUnlocks();

    await saveRepository.saveGameState(_state);
    await saveRepository.saveHighScore(newHigh);
    playGamesService.submitScore(newHigh);
    await saveRepository.recordGameCompletion(
      finalScore: doubledScore,
      linesCleared: _state.totalLinesCleared,
      maxCombo: _state.highestCombo,
      movesCount: _state.movesCount,
    );

    notifyListeners();
  }

  /// Claim today's Day 1-7 streak reward (free rerolls, revives, etc.)
  Future<void> claimDailyStreakReward() async {
    final updated = streakService.claimToday(_streakInfo);
    _streakInfo = updated;
    audioEngine.playAchievement();

    await saveRepository.saveStreakInfo(_streakInfo);
    await saveRepository.saveStreak(_streakInfo.streakCount);

    _checkThemeUnlocks();
    notifyListeners();
  }

  /// Check and auto-unlock themes when high score or streak meets requirements
  void _checkThemeUnlocks() {
    final currentHigh = _state.highScore;
    final currentStreak = _streakInfo.streakCount;
    final updatedUnlocked = List<String>.from(_unlockedThemeIds);
    bool anyNew = false;

    for (final theme in GameTheme.allThemes) {
      if (!updatedUnlocked.contains(theme.id) &&
          theme.isUnlocked(
            highScore: currentHigh,
            streak: currentStreak,
            unlockedIds: updatedUnlocked,
          )) {
        updatedUnlocked.add(theme.id);
        anyNew = true;
      }
    }

    if (anyNew) {
      _unlockedThemeIds = updatedUnlocked;
      saveRepository.saveUnlockedThemes(_unlockedThemeIds);
    }
  }

  @visibleForTesting
  void setGameStateForTesting(GameState state) {
    _state = state;
    _checkThemeUnlocks();
    notifyListeners();
  }
}
