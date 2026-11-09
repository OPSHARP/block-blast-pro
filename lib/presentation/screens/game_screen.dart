// Main Gameplay Screen with HUD, Board Canvas, Piece Tray, and Dragging Overlay

import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import '../../domain/models/game_mode.dart';
import '../../game/game_coordinator.dart';
import '../../game/components/board_canvas.dart';
import '../../game/components/piece_tray_widget.dart';
import '../../game/components/piece_widget.dart';
import '../widgets/glass_container.dart';
import '../widgets/combo_badge.dart';
import '../widgets/ad_banner_widget.dart';
import '../../core/audio/asmr_audio_engine.dart';
import '../../core/services/rating_service.dart';
import '../widgets/pixar_3d_widgets.dart';
import 'home_screen.dart';

class GameScreen extends StatefulWidget {
  final GameCoordinator coordinator;

  const GameScreen({super.key, required this.coordinator});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animController;
  late final AnimationController _shakeController;
  late final AnimationController _squashController;
  final GlobalKey _boardKey = GlobalKey();
  DateTime _lastFrameTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _animController.addListener(_onTick);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _squashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    widget.coordinator.screenShakeNotifier.addListener(_onScreenShake);
    widget.coordinator.recentPlacementNotifier.addListener(_onRecentPlacement);
    widget.coordinator.addListener(_onCoordinatorStateChanged);

    // Resume blitz timer if active
    if (widget.coordinator.state.gameMode == GameMode.blitz &&
        !widget.coordinator.state.isGameOver) {
      widget.coordinator.resumeBlitzTimer();
    }
  }

  bool _hasCheckedRatingThisGameOver = false;

  void _onCoordinatorStateChanged() async {
    final state = widget.coordinator.state;
    if (state.isGameOver && !_hasCheckedRatingThisGameOver) {
      _hasCheckedRatingThisGameOver = true;
      await RatingService().recordGameFinished();
      final isNewHighScore = state.score >= state.highScore && state.score > 0;
      final shouldPrompt = await RatingService().shouldPromptRating(
        isNewHighScore: isNewHighScore,
        score: state.score,
      );
      if (shouldPrompt && mounted) {
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted && widget.coordinator.state.isGameOver) {
            RatingService().showRatingDialog(context);
          }
        });
      }
    } else if (!state.isGameOver) {
      _hasCheckedRatingThisGameOver = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // Thermal & battery saver: Halt tickers completely while app is in background
      _animController.stop();
      widget.coordinator.pauseBlitzTimer();
    } else if (state == AppLifecycleState.resumed) {
      _animController.repeat();
      if (widget.coordinator.state.gameMode == GameMode.blitz &&
          !widget.coordinator.state.isGameOver) {
        widget.coordinator.resumeBlitzTimer();
      }
    }
  }

  void _onScreenShake() {
    if (mounted) {
      _shakeController.forward(from: 0.0);
    }
  }

  void _onRecentPlacement() {
    if (mounted) {
      _squashController.forward(from: 0.0);
    }
  }

  void _onTick() {
    final now = DateTime.now();
    final dt = (now.difference(_lastFrameTime).inMicroseconds / 1000000.0).clamp(0.0, 0.05);
    _lastFrameTime = now;
    // Thermal saver: Only update simulation if active particles exist
    if (widget.coordinator.particleEngine.hasActiveParticles) {
      widget.coordinator.particleEngine.update(dt);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.coordinator.removeListener(_onCoordinatorStateChanged);
    widget.coordinator.pauseBlitzTimer();
    widget.coordinator.screenShakeNotifier.removeListener(_onScreenShake);
    widget.coordinator.recentPlacementNotifier.removeListener(_onRecentPlacement);
    _shakeController.dispose();
    _squashController.dispose();
    _animController.removeListener(_onTick);
    _animController.dispose();
    super.dispose();
  }

  Rect _getBoardRect() {
    final renderBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Rect.zero;
    final pos = renderBox.localToGlobal(Offset.zero);
    return pos & renderBox.size;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.coordinator,
      builder: (context, _) {
        final state = widget.coordinator.state;
        final theme = widget.coordinator.theme;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            widget.coordinator.pauseBlitzTimer();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => HomeScreen(coordinator: widget.coordinator),
              ),
            );
          },
          child: Scaffold(
            backgroundColor: theme.backgroundEnd,
            body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.backgroundStart, theme.backgroundEnd],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Core Gameplay SafeArea (strictly prevents hiding in notification bar or navigation keys)
                SafeArea(
                  top: true,
                  bottom: true,
                  left: true,
                  right: true,
                  child: Column(
                    children: [
                      // Top HUD
                      _buildTopHud(context, state, theme),

                      // Center Board Area (dynamically expands and flexes without overflowing)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _shakeController,
                              builder: (context, child) {
                                final shakeVal = _shakeController.value;
                                final intensity = widget.coordinator.screenShakeIntensity;
                                final shakeOffset = (shakeVal > 0 && shakeVal < 1.0)
                                    ? sin(shakeVal * 8 * pi) * (1.0 - shakeVal) * 8.0 * intensity
                                    : 0.0;
                                final rotOffset = (shakeVal > 0 && shakeVal < 1.0)
                                    ? sin(shakeVal * 6 * pi) * (1.0 - shakeVal) * 0.012 * intensity
                                    : 0.0;
                                return Transform.rotate(
                                  angle: rotOffset,
                                  child: Transform.translate(
                                    offset: Offset(shakeOffset, shakeOffset * 0.5),
                                    child: child,
                                  ),
                                );
                              },
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: Container(
                                  key: _boardKey,
                                  child: GestureDetector(
                                    onTapUp: (details) {
                                      final boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
                                      if (boardBox != null && boardBox.size.width > 0) {
                                        final cellSize = boardBox.size.width / state.board.gridSize;
                                        final x = (details.localPosition.dx / cellSize).floor().clamp(0, state.board.gridSize - 1);
                                        final y = (details.localPosition.dy / cellSize).floor().clamp(0, state.board.gridSize - 1);

                                        if (widget.coordinator.isTntModeActive) {
                                          widget.coordinator.detonateTnt(x, y, _getBoardRect());
                                        } else if (widget.coordinator.isHammerModeActive) {
                                          widget.coordinator.smashCell(x, y, _getBoardRect());
                                        } else if (widget.coordinator.isColorMagnetModeActive) {
                                          widget.coordinator.executeColorMagnet(x, y, _getBoardRect());
                                        }
                                      }
                                    },
                                    child: AnimatedBuilder(
                                      animation: Listenable.merge([_animController, _squashController]),
                                      builder: (context, _) {
                                        final dragPiece = widget.coordinator.draggingTrayIndex != null
                                            ? state.trayPieces[widget.coordinator.draggingTrayIndex!]
                                            : null;

                                        return RepaintBoundary(
                                          child: CustomPaint(
                                            painter: BoardCanvasPainter(
                                              board: state.board,
                                              theme: theme,
                                              draggingPiece: dragPiece,
                                              hoveredCoord: widget.coordinator.hoveredGridCoord,
                                              isPlacementValid: widget.coordinator.isPlacementValid,
                                              particleEngine: widget.coordinator.particleEngine,
                                              pendingShiftWarning: state.pendingShiftWarning,
                                              animationValue: _animController.value,
                                              isHammerModeActive: widget.coordinator.isHammerModeActive,
                                              isTntModeActive: widget.coordinator.isTntModeActive,
                                              isColorMagnetModeActive: widget.coordinator.isColorMagnetModeActive,
                                              recentPlacementCoords: widget.coordinator.recentPlacementCoords,
                                              squashProgress: _squashController.value,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // TNT Detonator Mode Active Banner
                      if (widget.coordinator.isTntModeActive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3D00).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFF3D00)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department, size: 14, color: Color(0xFFFF3D00)),
                              const SizedBox(width: 6),
                              const Text(
                                '💥 TNT ACTIVE: TAP ANY CELL TO BLOW UP 3x3!',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFF3D00),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => widget.coordinator.cancelTntMode(),
                                child: const Icon(Icons.close, size: 14, color: AppColors.iconDefault),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Hammer Mode Active Banner
                      if (widget.coordinator.isHammerModeActive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFF5722)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.build_circle, size: 14, color: Color(0xFFFF5722)),
                              const SizedBox(width: 6),
                              const Text(
                                'HAMMER ACTIVE: TAP ANY BLOCK TO SMASH',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFF5722),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => widget.coordinator.cancelHammerMode(),
                                child: const Icon(Icons.close, size: 14, color: AppColors.iconDefault),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],

                      // Color Magnet Mode Active Banner
                      if (widget.coordinator.isColorMagnetModeActive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE040FB).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE040FB)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.explore, size: 14, color: Color(0xFFE040FB)),
                              const SizedBox(width: 6),
                              const Text(
                                '🧲 MAGNET ACTIVE: TAP BLOCK TO DISSOLVE COLOR!',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFE040FB),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => widget.coordinator.cancelColorMagnetMode(),
                                child: const Icon(Icons.close, size: 14, color: AppColors.iconDefault),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],

                      // Grid Shift Warning Pill
                      if (state.pendingShiftWarning != null) ...[
                        const SizedBox(height: 4),
                        _buildShiftBanner(state.pendingShiftWarning!, theme),
                      ],

                      // Advanced Booster Bar (Hold, Rotate, Undo, Hammer, TNT, Magnet, Reroll)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildHoldSlot(context, state, theme),
                              const SizedBox(width: 6),
                              _buildRotateButton(context, theme),
                              const SizedBox(width: 6),
                              _buildUndoButton(context, theme),
                              const SizedBox(width: 6),
                              _buildHammerButton(context, theme),
                              const SizedBox(width: 6),
                              _buildTntBoosterButton(context, theme),
                              const SizedBox(width: 6),
                              _buildColorMagnetButton(context, theme),
                              const SizedBox(width: 6),
                              _buildRerollButton(context, theme),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Piece Tray
                      PieceTrayWidget(
                        pieces: state.trayPieces,
                        theme: theme,
                        draggingIndex: widget.coordinator.draggingTrayIndex,
                        onDragStart: (idx, pos, isDirect) {
                          widget.coordinator.onDragStart(idx, pos, isDirectCursor: isDirect);
                        },
                        onDragUpdate: (pos, isDirect) {
                          final boardRect = _getBoardRect();
                          widget.coordinator.onDragUpdate(pos, boardRect, isDirectCursor: isDirect);
                        },
                        onDragEnd: () {
                          final boardRect = _getBoardRect();
                          widget.coordinator.onDragEnd(boardRect);
                        },
                        onRotatePiece: (idx) => _handleRotateSlot(context, idx),
                      ),
                      const SizedBox(height: 4),
                      // Bottom AdMob Banner
                      AdBannerWidget(adService: widget.coordinator.adService),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),

                // Floating Dragged Piece (lifted above finger or directly on cursor)
                if (widget.coordinator.draggingTrayIndex != null &&
                    widget.coordinator.dragPosition != null)
                  _buildFloatingPiece(state),

                // 3D Cinematic Combo Callout Overlay
                _buildComboCalloutOverlay(),

                // Fever Overdrive Electric Neon Screen Edge Glow (5+ combo)
                if (state.isFeverMode)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, _) {
                          final pulse = 0.5 + 0.5 * sin(_animController.value * 8 * pi);
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Color.lerp(
                                  const Color(0xFF00E5FF),
                                  const Color(0xFFFFD700),
                                  pulse,
                                )!.withValues(alpha: 0.55 + 0.35 * pulse),
                                width: 4.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.4 * pulse),
                                  blurRadius: 18.0,
                                  spreadRadius: 2.0,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Game Over Modal Overlay
                if (state.isGameOver) _buildGameOverOverlay(context, state, theme),
              ],
            ),
          ),
        ),
      );
    },
  );
  }

  Widget _buildTopHud(BuildContext context, dynamic state, dynamic theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 3D Pixar Home / Exit & Banked Coins Pill
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  AsmrAudioEngine.instance.playPixarPop();
                  widget.coordinator.pauseBlitzTimer();
                  Navigator.of(context).pushReplacement(
                    PixarPageRoute(
                      builder: (_) => HomeScreen(coordinator: widget.coordinator),
                    ),
                  );
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFF1F5F9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.1),
                        offset: const Offset(0, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 2,
                        child: Container(
                          width: 22,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const Icon(Icons.home_rounded, color: AppColors.textPrimary, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 3D Golden Toy Coin Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFDF00), Color(0xFFF59E0B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFFBEB), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB45309).withValues(alpha: 0.8),
                      offset: const Offset(0, 3),
                      blurRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFFBEB),
                      ),
                      child: const Center(
                        child: Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.coordinator.coins}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF78350F),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Pixar 3D Score & Best Badge
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${state.score}',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -1.0,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFF1F5F9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_rounded, size: 14, color: theme.accent),
                    const SizedBox(width: 4),
                    Text(
                      'BEST: ${state.highScore}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              // Blitz mode timer indicator
              if (state.gameMode == GameMode.blitz) ...[
                Builder(builder: (context) {
                  final remainSec = state.blitzTimeRemaining.ceil();
                  final isUrgent = remainSec <= 10;
                  return Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isUrgent
                            ? const [Color(0xFFFF1744), Color(0xFFD50000)]
                            : const [Color(0xFF00E5FF), Color(0xFF0091EA)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isUrgent
                                  ? const Color(0xFFB71C1C)
                                  : const Color(0xFF01579B)),
                          offset: const Offset(0, 2),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${remainSec}s BLITZ',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              if (state.gameMode == GameMode.lava) ...[
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFE64A19)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFBF360C),
                        offset: Offset(0, 2),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_rounded, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'RISING LAVA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (state.gameMode == GameMode.adventure) ...[
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA855F7), Color(0xFF7E22CE)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF581C87),
                        offset: Offset(0, 2),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_rounded, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'JOURNEY MODE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (state.isFeverMode)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFFF9100)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFE65100),
                        offset: Offset(0, 2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_rounded, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'FEVER 3X',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Combo indicator
          ComboBadge(
            comboCount: state.comboCount,
            accentColor: theme.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildShiftBanner(String text, dynamic theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.accent.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz, size: 16, color: theme.accent),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: theme.accent,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingPiece(dynamic state) {
    final piece = state.trayPieces[widget.coordinator.draggingTrayIndex!];
    if (piece == null) return const SizedBox.shrink();

    final pos = widget.coordinator.dragPosition!;
    final boardRect = _getBoardRect();
    final cellSize = boardRect.width > 0
        ? (boardRect.width / state.board.gridSize)
        : 36.0;
    final width = piece.width * cellSize;
    final height = piece.height * cellSize;

    // Calculate vertical lift offset matching coordinator exactly
    double liftY = 0.0;
    if (!widget.coordinator.isDirectCursor) {
      const defaultTouchLift = 60.0;
      final distAboveBoardTop = pos.dy - boardRect.top;
      if (distAboveBoardTop < defaultTouchLift && boardRect.top > 0) {
        liftY = distAboveBoardTop.clamp(0.0, defaultTouchLift);
      } else {
        liftY = defaultTouchLift;
      }
    }

    final left = pos.dx - (width / 2.0);
    final top = pos.dy - liftY - (height / 2.0);

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: PieceWidget(
          block: piece,
          cellSize: cellSize,
          isGhost: false,
          tiltAngle: widget.coordinator.isDirectCursor ? 0.0 : 0.04,
          isDragging: true,
        ),
      ),
    );
  }

  Widget _buildComboCalloutOverlay() {
    return ValueListenableBuilder<String?>(
      valueListenable: widget.coordinator.comboCalloutNotifier,
      builder: (context, text, _) {
        if (text == null) return const SizedBox.shrink();

        final List<Color> gradientColors;
        final Color glowColor;
        if (text.contains('GODLIKE') || text.contains('MEGA')) {
          gradientColors = const [Color(0xFFFF007F), Color(0xFFFF1744), Color(0xFFFFD600)];
          glowColor = const Color(0xFFFF1744);
        } else if (text.contains('UNSTOPPABLE') || text.contains('TRIPLE')) {
          gradientColors = const [Color(0xFFFF3D00), Color(0xFFFFD700)];
          glowColor = const Color(0xFFFF9100);
        } else if (text.contains('AWESOME') || text.contains('DOUBLE')) {
          gradientColors = const [Color(0xFF7C4DFF), Color(0xFF00E5FF)];
          glowColor = const Color(0xFF00E5FF);
        } else {
          gradientColors = const [Color(0xFF00E5FF), Color(0xFF1DE9B6)];
          glowColor = const Color(0xFF00E5FF);
        }

        return Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.2, end: 1.0),
                duration: const Duration(milliseconds: 320),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.textSecondary,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.65),
                        blurRadius: 28,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.textPrimary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(0, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.auto_awesome, color: AppColors.textPrimary, size: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameOverOverlay(BuildContext context, dynamic state, dynamic theme) {
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Pixar3DCard(
              gradientColors: const [Colors.white, Color(0xFFF8FAFC)],
              borderColor: theme.accent,
              extrusion: 8,
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pixar 3D Playful Block Character Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF4B4B), Color(0xFFD32F2F)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF9A0007),
                              offset: Offset(0, 4),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'X_X',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'GAME OVER',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'FINAL SCORE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.score}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: theme.accent,
                      shadows: [
                        Shadow(
                          color: theme.accent.withValues(alpha: 0.5),
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 3D Stat Badges Row
                  Row(
                    children: [
                      Expanded(child: _build3DStatPill('BEST', '${state.highScore}', const Color(0xFFFFD54F))),
                      const SizedBox(width: 8),
                      Expanded(child: _build3DStatPill('MAX COMBO', '${state.highestCombo}x', const Color(0xFF00E5FF))),
                      const SizedBox(width: 8),
                      Expanded(child: _build3DStatPill('LINES', '${state.totalLinesCleared}', const Color(0xFF34D399))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Second chance banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFEF4444).withValues(alpha: 0.25),
                          const Color(0xFFDC2626).withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEF4444), width: 1.2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_rounded, size: 16, color: Color(0xFFEF4444)),
                        SizedBox(width: 6),
                        Text(
                          'SECOND CHANCE: KEEP YOUR STREAK!',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Double Score Button
                  if (!widget.coordinator.hasDoubledScoreThisGame && state.score > 0) ...[
                    Pixar3DButton(
                      text: 'DOUBLE SCORE (2X)',
                      icon: Icons.bolt_rounded,
                      gradientColors: const [Color(0xFFFBBF24), Color(0xFFD97706)],
                      shadowColor: const Color(0xFF92400E),
                      extrusion: 6,
                      onPressed: () {
                        widget.coordinator.adService.showRewardedAd(
                          context: context,
                          onUserEarnedReward: (amount, type) {
                            widget.coordinator.doubleEndgameScore();
                            AsmrAudioEngine.instance.playPixarSparkle();
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ] else if (widget.coordinator.hasDoubledScoreThisGame) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFFF59E0B)),
                          SizedBox(width: 6),
                          Text(
                            '2X SCORE & XP APPLIED!',
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Revive Button
                  Pixar3DButton(
                    text: 'REVIVE (+CLEAR 3 ROWS)',
                    icon: Icons.ondemand_video_rounded,
                    gradientColors: const [Color(0xFF34D399), Color(0xFF059669)],
                    shadowColor: const Color(0xFF065F46),
                    extrusion: 6,
                    onPressed: () {
                      widget.coordinator.adService.showRewardedAd(
                        context: context,
                        onUserEarnedReward: (amount, type) {
                          widget.coordinator.reviveGame();
                          AsmrAudioEngine.instance.playPixarBoing();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Play Again Button
                  Pixar3DButton(
                    text: 'PLAY AGAIN',
                    icon: Icons.replay_rounded,
                    gradientColors: [theme.accent, theme.accent.withValues(alpha: 0.8)],
                    shadowColor: const Color(0xFF0F172A),
                    extrusion: 6,
                    onPressed: () {
                      widget.coordinator.adService.showInterstitialAd(
                        onDismissed: () {
                          widget.coordinator.startNewGame(mode: state.gameMode);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Share Score Card
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD700),
                      side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _showShareScoreModal(context, state, theme),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text(
                      'SHARE SCORE CARD',
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Return to menu
                  TextButton(
                    onPressed: () {
                      widget.coordinator.adService.showInterstitialAd(
                        onDismissed: () {
                          Navigator.of(context).pushReplacement(
                            PixarPageRoute(
                              builder: (_) => HomeScreen(coordinator: widget.coordinator),
                            ),
                          );
                        },
                      );
                    },
                    child: Text(
                      'RETURN TO MENU',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showShareScoreModal(BuildContext context, dynamic state, dynamic theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'YOUR SCORE CARD',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // Card graphic
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.military_tech, color: Color(0xFFFFD700), size: 28),
                        SizedBox(width: 8),
                        Text(
                          'BLOCK BLAST PRO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFFD700),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${state.score}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const Text(
                      'POINTS SCORED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('BEST', '${state.highScore}'),
                        _buildStatItem('COMBO', '${state.highestCombo}x'),
                        _buildStatItem('LINES', '${state.totalLinesCleared}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: AppColors.textTertiary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: '🎮 I scored ${state.score} in Block Blast Pro! '
                          'High Score: ${state.highScore} | Max Combo: ${state.highestCombo}x | Lines: ${state.totalLinesCleared}. '
                          'Can you beat my record?',
                    ),
                  );
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Score Card copied to clipboard! Share with your friends!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 20),
                label: const Text('COPY & SHARE TO FRIENDS', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _handleRotateSlot(BuildContext context, int slotIndex) {
    if (widget.coordinator.freeRotates > 0) {
      widget.coordinator.rotatePiece(slotIndex, isFree: true);
    } else {
      widget.coordinator.adService.showRewardedAd(
        context: context,
        onUserEarnedReward: (amount, type) {
          widget.coordinator.grantRotateViaAd();
          widget.coordinator.rotatePiece(slotIndex, isFree: true);
        },
      );
    }
  }

  Widget _buildRotateButton(BuildContext context, dynamic theme) {
    final rotates = widget.coordinator.freeRotates;
    final hasFree = rotates > 0;

    return InkWell(
      onTap: () {
        final firstIdx = widget.coordinator.state.trayPieces.indexWhere((p) => p != null);
        if (firstIdx == -1) return;
        _handleRotateSlot(context, firstIdx);
      },
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        borderRadius: 20,
        backgroundColor: theme.boardBackground,
        borderColor: hasFree ? const Color(0xFF00E5FF) : theme.accent.withValues(alpha: 0.6),
        borderWidth: 1.2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rotate_right,
              size: 15,
              color: hasFree ? const Color(0xFF00E5FF) : theme.accent,
            ),
            const SizedBox(width: 4),
            Text(
              hasFree ? 'ROTATE ($rotates)' : 'ROTATE (AD)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: hasFree ? const Color(0xFF00E5FF) : AppColors.textTertiary,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUndoButton(BuildContext context, dynamic theme) {
    final undos = widget.coordinator.freeUndos;
    final canUndo = widget.coordinator.canUndo;
    final hasFree = undos > 0;

    return Opacity(
      opacity: canUndo ? 1.0 : 0.45,
      child: InkWell(
        onTap: canUndo
            ? () {
                if (hasFree) {
                  widget.coordinator.undoMove(isFree: true);
                } else {
                  widget.coordinator.adService.showRewardedAd(
                    context: context,
                    onUserEarnedReward: (amount, type) {
                      widget.coordinator.grantUndoViaAd();
                      widget.coordinator.undoMove(isFree: true);
                    },
                  );
                }
              }
            : null,
        borderRadius: BorderRadius.circular(20),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          borderRadius: 20,
          backgroundColor: theme.boardBackground,
          borderColor: canUndo ? (hasFree ? const Color(0xFFF59E0B) : theme.accent) : AppColors.borderSubtle,
          borderWidth: 1.2,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.undo,
                size: 15,
                color: canUndo ? (hasFree ? const Color(0xFFF59E0B) : theme.accent) : AppColors.iconSubtle,
              ),
              const SizedBox(width: 4),
              Text(
                hasFree ? 'UNDO ($undos)' : 'UNDO (AD)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: canUndo ? (hasFree ? const Color(0xFFF59E0B) : AppColors.textTertiary) : AppColors.iconSubtle,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorMagnetButton(BuildContext context, dynamic theme) {
    final magnets = widget.coordinator.freeMagnets;
    final isActive = widget.coordinator.isColorMagnetModeActive;

    return InkWell(
      onTap: () {
        if (isActive) {
          widget.coordinator.cancelColorMagnetMode();
        } else if (magnets > 0) {
          widget.coordinator.toggleColorMagnetMode();
        } else {
          widget.coordinator.adService.showRewardedAd(
            context: context,
            onUserEarnedReward: (amount, type) {
              widget.coordinator.grantColorMagnetViaAd();
            },
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        borderRadius: 20,
        backgroundColor: isActive
            ? const Color(0xFFE040FB).withValues(alpha: 0.35)
            : theme.boardBackground,
        borderColor: isActive
            ? const Color(0xFFE040FB)
            : (magnets > 0 ? const Color(0xFFE040FB) : const Color(0xFFAB47BC)),
        borderWidth: 1.2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore,
              size: 15,
              color: isActive
                  ? const Color(0xFFE040FB)
                  : (magnets > 0 ? const Color(0xFFE040FB) : AppColors.textTertiary),
            ),
            const SizedBox(width: 4),
            Text(
              isActive
                  ? 'CANCEL'
                  : (magnets > 0 ? 'MAGNET ($magnets)' : 'MAGNET (AD)'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isActive
                    ? const Color(0xFFE040FB)
                    : (magnets > 0 ? const Color(0xFFE040FB) : AppColors.textTertiary),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRerollButton(BuildContext context, dynamic theme) {
    final freeCount = widget.coordinator.freeRerolls;
    final hasFree = freeCount > 0;

    return InkWell(
      onTap: () {
        if (hasFree) {
          widget.coordinator.rerollPieces(isFree: true);
        } else {
          widget.coordinator.adService.showRewardedAd(
            context: context,
            onUserEarnedReward: (amount, type) {
              widget.coordinator.grantRerollViaAd();
              widget.coordinator.rerollPieces(isFree: true);
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.casino, color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Tray Rerolled Successfully!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                    ),
                  ),
                );
              }
            },
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        borderRadius: 20,
        backgroundColor: theme.boardBackground,
        borderColor: hasFree ? const Color(0xFF10B981) : theme.accent.withValues(alpha: 0.6),
        borderWidth: 1.2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.casino_outlined,
              size: 16,
              color: hasFree ? const Color(0xFF10B981) : theme.accent,
            ),
            const SizedBox(width: 6),
            Text(
              hasFree ? 'REROLL ($freeCount)' : 'REROLL (AD)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: hasFree ? const Color(0xFF10B981) : AppColors.textTertiary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldSlot(BuildContext context, dynamic state, dynamic theme) {
    final held = state.heldPiece;
    final canHold = widget.coordinator.canHoldThisTurn;
    final emptyIdx = state.trayPieces.indexOf(null);
    final hasEmptySlot = emptyIdx != -1;

    String label;
    if (held != null) {
      final action = hasEmptySlot ? 'DEPLOY' : 'SWAP';
      label = canHold ? action : '$action (AD)';
    } else {
      label = 'HOLD';
    }

    return InkWell(
      onTap: () {
        final trayIdx = (held != null && hasEmptySlot)
            ? emptyIdx
            : state.trayPieces.indexWhere((p) => p != null);
        if (trayIdx == -1) return;

        if (canHold) {
          widget.coordinator.holdPiece(trayIdx);
        } else {
          // Emergency hold via rewarded ad
          widget.coordinator.adService.showRewardedAd(
            context: context,
            onUserEarnedReward: (amount, type) {
              widget.coordinator.grantEmergencyHoldViaAd(trayIdx);
            },
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        borderRadius: 16,
        backgroundColor: theme.boardBackground,
        borderColor: held != null ? theme.accent : AppColors.borderSubtle,
        borderWidth: 1.2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (held != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(held.colorValue),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Color(held.colorValue).withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              held != null ? Icons.all_inbox : Icons.move_to_inbox,
              size: 15,
              color: held != null ? theme.accent : AppColors.iconDefault,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: held != null ? theme.accent : AppColors.iconDefault,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHammerButton(BuildContext context, dynamic theme) {
    final hammers = widget.coordinator.freeHammers;
    final isActive = widget.coordinator.isHammerModeActive;

    return InkWell(
      onTap: () {
        if (isActive) {
          widget.coordinator.cancelHammerMode();
        } else if (hammers > 0) {
          widget.coordinator.toggleHammerMode();
        } else {
          widget.coordinator.adService.showRewardedAd(
            context: context,
            onUserEarnedReward: (amount, type) {
              widget.coordinator.grantHammerViaAd();
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.build, color: Color(0xFFFF5722), size: 18),
                        SizedBox(width: 8),
                        Text(
                          '+1 Sledgehammer Added & Armed!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFFF5722), width: 1.2),
                    ),
                  ),
                );
              }
            },
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        borderRadius: 20,
        backgroundColor: isActive ? const Color(0xFFFF5722).withValues(alpha: 0.35) : theme.boardBackground,
        borderColor: isActive
            ? const Color(0xFFFF5722)
            : (hammers > 0 ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B)),
        borderWidth: 1.2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.gavel,
              size: 15,
              color: isActive
                  ? const Color(0xFFFF5722)
                  : (hammers > 0 ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 4),
            Text(
              isActive
                  ? 'CANCEL'
                  : (hammers > 0 ? 'HAMMER ($hammers)' : 'HAMMER (AD)'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isActive
                    ? const Color(0xFFFF5722)
                    : (hammers > 0 ? const Color(0xFF38BDF8) : AppColors.textTertiary),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTntBoosterButton(BuildContext context, dynamic theme) {
    final tnts = widget.coordinator.freeTnts;
    final isActive = widget.coordinator.isTntModeActive;

    return InkWell(
      onTap: () {
        if (isActive) {
          widget.coordinator.cancelTntMode();
        } else if (tnts > 0) {
          widget.coordinator.toggleTntMode();
        } else {
          widget.coordinator.adService.showRewardedAd(
            context: context,
            onUserEarnedReward: (amount, type) {
              widget.coordinator.grantTntViaAd();
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Color(0xFFFF3D00), size: 18),
                        SizedBox(width: 8),
                        Text(
                          '💥 TNT Detonator Armed! Tap anywhere to blow up 3x3!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFFF3D00), width: 1.2),
                    ),
                  ),
                );
              }
            },
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        borderRadius: 20,
        backgroundColor: isActive
            ? const Color(0xFFFF3D00).withValues(alpha: 0.35)
            : theme.boardBackground,
        borderColor: isActive
            ? const Color(0xFFFF3D00)
            : (tnts > 0 ? const Color(0xFFFF9100) : const Color(0xFFFF5722)),
        borderWidth: 1.2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: 15,
              color: isActive
                  ? const Color(0xFFFF3D00)
                  : (tnts > 0 ? const Color(0xFFFF9100) : const Color(0xFFFF5722)),
            ),
            const SizedBox(width: 4),
            Text(
              isActive
                  ? 'CANCEL'
                  : (tnts > 0 ? 'TNT ($tnts)' : 'TNT (AD)'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isActive
                    ? const Color(0xFFFF3D00)
                    : (tnts > 0 ? const Color(0xFFFF9100) : AppColors.textTertiary),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String val) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _build3DStatPill(String label, String val, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 2),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
