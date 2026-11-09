// Pixar-Style 3D Animated UI Components for Block Blast Pro
// Provides glossy, tactile 3D cards, physical arcade buttons, and animated Pixar block hero grid

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/audio/asmr_audio_engine.dart';

/// Tactile, glossy 3D card with embossed bevels, physical bottom extrusion, and spring press physics
class Pixar3DCard extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final List<Color>? gradientColors;
  final Color? gradientEnd;
  final Color? accentColor;
  final Color? borderColor;
  final Color? extrusionColor;
  final VoidCallback? onTap;
  final double depth;
  final double? extrusion;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Widget? badge;

  const Pixar3DCard({
    super.key,
    required this.child,
    this.baseColor,
    this.gradientColors,
    this.gradientEnd,
    this.accentColor,
    this.borderColor,
    this.extrusionColor,
    this.onTap,
    this.depth = 4.5,
    this.extrusion,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(16.0),
    this.badge,
  });

  @override
  State<Pixar3DCard> createState() => _Pixar3DCardState();
}

class _Pixar3DCardState extends State<Pixar3DCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  Color _darken(Color color, [double factor = 0.5]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * factor).clamp(0.0, 1.0)).toColor();
  }

  Color _lighten(Color color, [double factor = 1.35]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * factor).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final isBaseWhite = widget.baseColor == Colors.white ||
        (widget.baseColor == null && widget.gradientColors == null);
    final effectiveBase = widget.baseColor ??
        (widget.gradientColors != null && widget.gradientColors!.isNotEmpty
            ? widget.gradientColors!.first
            : Colors.white);
    final gradEnd = widget.gradientEnd ??
        (widget.gradientColors != null && widget.gradientColors!.length > 1
            ? widget.gradientColors![1]
            : (isBaseWhite ? const Color(0xFFF8FAFC) : _darken(effectiveBase, 0.75)));
    final bottomShadow = widget.extrusionColor ?? (isBaseWhite ? const Color(0xFFCBD5E1) : _darken(effectiveBase, 0.45));
    final topHighlight = widget.borderColor ?? (isBaseWhite ? const Color(0xFFE2E8F0) : _lighten(effectiveBase, 1.3).withValues(alpha: 0.35));
    final cardDepth = widget.extrusion ?? widget.depth;
    final effectiveDepth = _isPressed ? cardDepth * 0.3 : cardDepth;
    final translateY = _isPressed ? cardDepth * 0.7 : 0.0;

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = true);
          AsmrAudioEngine().playPixarPop(pitch: 0.95);
        }
      },
      onTapUp: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        }
      },
      onTapCancel: () {
        if (widget.onTap != null) {
          setState(() => _isPressed = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, translateY, 0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: bottomShadow,
            boxShadow: [
              // 3D Extrusion Bottom Shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: isBaseWhite ? 0.07 : 0.25),
                offset: Offset(0, effectiveDepth + 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
              // Radiant Outer Accent Glow / Soft ambient shadow
              BoxShadow(
                color: (widget.accentColor ?? (isBaseWhite ? const Color(0xFF0F172A) : effectiveBase)).withValues(alpha: widget.accentColor != null ? 0.15 : (isBaseWhite ? 0.04 : 0.2)),
                offset: const Offset(0, 3),
                blurRadius: 12,
                spreadRadius: -1,
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: effectiveDepth),
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  effectiveBase,
                  gradEnd,
                ],
              ),
              border: Border.all(
                color: topHighlight,
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                // Top Gloss Specular Highlight Line
                Positioned(
                  top: 0,
                  left: 12,
                  right: 12,
                  child: Container(
                    height: 1.8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                widget.child,
                if (widget.badge != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: widget.badge!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chunky 3D Physical Pixar Arcade Button with spring translation and glossy lens reflection
class Pixar3DButton extends StatefulWidget {
  final Widget? child;
  final String? text;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onPressed;
  final Color primaryColor;
  final Color? secondaryColor;
  final List<Color>? gradientColors;
  final Color? shadowColor;
  final Color? extrusionColor;
  final double height;
  final double borderRadius;
  final double depth;
  final double? extrusion;

  const Pixar3DButton({
    super.key,
    this.child,
    this.text,
    this.icon,
    this.onTap,
    this.onPressed,
    this.primaryColor = const Color(0xFFFFD600),
    this.secondaryColor = const Color(0xFFFF6D00),
    this.gradientColors,
    this.shadowColor,
    this.extrusionColor,
    this.textColor,
    this.width,
    this.height = 60.0,
    this.borderRadius = 22.0,
    this.depth = 6.0,
    this.extrusion,
  });

  final Color? textColor;
  final double? width;

  @override
  State<Pixar3DButton> createState() => _Pixar3DButtonState();
}

class _Pixar3DButtonState extends State<Pixar3DButton> {
  bool _isPressed = false;

  Color _darken(Color color, [double factor = 0.5]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * factor).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final effectivePrimary = widget.gradientColors != null && widget.gradientColors!.isNotEmpty
        ? widget.gradientColors!.first
        : widget.primaryColor;
    final effectiveSecondary = widget.gradientColors != null && widget.gradientColors!.length > 1
        ? widget.gradientColors![1]
        : widget.secondaryColor;
    final bottomShadow = widget.shadowColor ??
        widget.extrusionColor ??
        _darken(effectiveSecondary ?? effectivePrimary, 0.42);
    final buttonDepth = widget.extrusion ?? widget.depth;
    final effectiveDepth = _isPressed ? buttonDepth * 0.25 : buttonDepth;
    final translateY = _isPressed ? buttonDepth * 0.75 : 0.0;
    final action = widget.onPressed ?? widget.onTap ?? () {};

    Widget content;
    if (widget.child != null) {
      content = widget.child!;
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
          ],
          if (widget.text != null)
            Text(
              widget.text!,
              style: TextStyle(
                color: widget.textColor ?? Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            ),
        ],
      );
    }

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        AsmrAudioEngine().playPixarPop(pitch: 1.15);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        action();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutQuad,
        transform: Matrix4.translationValues(0, translateY, 0),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: bottomShadow,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                offset: Offset(0, effectiveDepth + 4),
                blurRadius: 10,
              ),
              BoxShadow(
                color: effectivePrimary.withValues(alpha: 0.4),
                offset: const Offset(0, 2),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: effectiveDepth),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  effectivePrimary,
                  effectiveSecondary ?? _darken(effectivePrimary, 0.7),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.8,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top Gloss Pill Reflection
                Positioned(
                  top: 2,
                  left: 20,
                  right: 20,
                  height: widget.height * 0.38,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(widget.borderRadius - 2),
                        bottom: const Radius.circular(10),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.55),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Interactive 3D Animated Hero Grid displaying 4 smiling/bouncy Pixar toy blocks
class Pixar3DHeroGrid extends StatefulWidget {
  final VoidCallback? onBlockTap;

  const Pixar3DHeroGrid({super.key, this.onBlockTap});

  @override
  State<Pixar3DHeroGrid> createState() => _Pixar3DHeroGridState();
}

class _Pixar3DHeroGridState extends State<Pixar3DHeroGrid> with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  int _bouncingIndex = -1;

  static const List<_PixarBlockModel> _blocks = [
    _PixarBlockModel(
      color: Color(0xFF00E5FF),
      gradientEnd: Color(0xFF0288D1),
      shadowColor: Color(0xFF01579B),
      eyeType: _EyeType.happy,
      label: '⚡',
    ),
    _PixarBlockModel(
      color: Color(0xFFFF2A6D),
      gradientEnd: Color(0xFFC2185B),
      shadowColor: Color(0xFF880E4F),
      eyeType: _EyeType.wink,
      label: '💖',
    ),
    _PixarBlockModel(
      color: Color(0xFFFFD600),
      gradientEnd: Color(0xFFFF8F00),
      shadowColor: Color(0xFFE65100),
      eyeType: _EyeType.star,
      label: '⭐',
    ),
    _PixarBlockModel(
      color: Color(0xFF00E676),
      gradientEnd: Color(0xFF2E7D32),
      shadowColor: Color(0xFF1B5E20),
      eyeType: _EyeType.curious,
      label: '🍀',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _triggerBounce(int index) {
    setState(() => _bouncingIndex = index);
    AsmrAudioEngine().playPixarBoing();
    widget.onBlockTap?.call();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _bouncingIndex = -1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        final t = _floatController.value * math.pi;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_blocks.length, (i) {
            final block = _blocks[i];
            final offsetSine = math.sin(t + (i * 0.78)) * 4.5;
            final isBouncing = _bouncingIndex == i;

            return GestureDetector(
              onTap: () => _triggerBounce(i),
              child: AnimatedScale(
                scale: isBouncing ? 1.25 : 1.0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.elasticOut,
                child: Transform.translate(
                  offset: Offset(0, offsetSine),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: block.shadowColor,
                      boxShadow: [
                        BoxShadow(
                          color: block.color.withValues(alpha: 0.45),
                          offset: const Offset(0, 5),
                          blurRadius: 10,
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [block.color, block.gradientEnd],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.65),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Specular Highlight Glare
                          Positioned(
                            top: 2,
                            left: 4,
                            child: Container(
                              width: 10,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          // Pixar Eyes
                          _buildEyes(block.eyeType),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildEyes(_EyeType eyeType) {
    switch (eyeType) {
      case _EyeType.happy:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _EyeDot(),
            SizedBox(width: 8),
            _EyeDot(),
          ],
        );
      case _EyeType.wink:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _EyeDot(),
            SizedBox(width: 8),
            Text('^', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 13)),
          ],
        );
      case _EyeType.star:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('★', style: TextStyle(color: Colors.black87, fontSize: 11)),
            SizedBox(width: 6),
            Text('★', style: TextStyle(color: Colors.black87, fontSize: 11)),
          ],
        );
      case _EyeType.curious:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _EyeDot(pupilOffset: Offset(1, -1)),
            SizedBox(width: 8),
            _EyeDot(pupilOffset: Offset(1, -1)),
          ],
        );
    }
  }
}

enum _EyeType { happy, wink, star, curious }

class _PixarBlockModel {
  final Color color;
  final Color gradientEnd;
  final Color shadowColor;
  final _EyeType eyeType;
  final String label;

  const _PixarBlockModel({
    required this.color,
    required this.gradientEnd,
    required this.shadowColor,
    required this.eyeType,
    required this.label,
  });
}

class _EyeDot extends StatelessWidget {
  final Offset pupilOffset;
  const _EyeDot({this.pupilOffset = Offset.zero});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Container(
          width: 4,
          height: 5,
          transform: Matrix4.translationValues(pupilOffset.dx, pupilOffset.dy, 0),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2E),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Pixar 3D Squircle Navigation Tile for Exploration Hub (Themes, Badges, Ranks, Stats)
class Pixar3DNavTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const Pixar3DNavTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<Pixar3DNavTile> createState() => _Pixar3DNavTileState();
}

class _Pixar3DNavTileState extends State<Pixar3DNavTile> {
  bool _isPressed = false;

  Color _darken(Color color, [double factor = 0.5]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * factor).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final darkShadow = _darken(widget.color, 0.45);
    const depth = 4.0;
    final effectiveDepth = _isPressed ? depth * 0.25 : depth;
    final translateY = _isPressed ? depth * 0.75 : 0.0;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        AsmrAudioEngine().playPixarPop(pitch: 1.3);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, translateY, 0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: darkShadow,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.35),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: effectiveDepth),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color,
                  _darken(widget.color, 0.75),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1.4,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: Colors.white, size: 24),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pixar Playful 3D Spring Page Route Transition
/// Smooth, hardware-accelerated elastic spring pop transition (120 FPS, zero heating)
class PixarPageRoute<T> extends PageRouteBuilder<T> {
  final Widget? page;
  final WidgetBuilder? builder;

  PixarPageRoute({this.page, this.builder, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              page ?? (builder != null ? builder(context) : const SizedBox.shrink()),
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeInCubic,
            );
            return ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
        );
}

/// Pixar 3D AppBar with glossy floating back button and embossed title
class Pixar3DAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onBackPressed;
  final Color? accentColor;
  final List<Widget>? actions;

  const Pixar3DAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.onBackPressed,
    this.accentColor,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final backCallback = onBack ?? onBackPressed;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: backCallback != null
          ? Padding(
              padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
              child: Pixar3DCard(
                baseColor: Colors.white,
                gradientEnd: const Color(0xFFF8FAFC),
                borderColor: const Color(0xFFCBD5E1),
                extrusionColor: const Color(0xFFCBD5E1),
                depth: 3.0,
                borderRadius: 12,
                padding: EdgeInsets.zero,
                onTap: backCallback,
                child: const Center(
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 16),
                ),
              ),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: accentColor ?? const Color(0xFF0F172A),
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: 1.5,
        ),
      ),
      actions: actions,
    );
  }
}

/// Pixar 3D Glossy Candy Progress Bar with embossed track
class Pixar3DProgressBar extends StatelessWidget {
  final double progress;
  final Color fillColor;
  final Color? trackColor;
  final double height;

  const Pixar3DProgressBar({
    super.key,
    required this.progress,
    required this.fillColor,
    this.trackColor,
    this.height = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final bg = trackColor ?? const Color(0xFF0F172A);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 2),
            blurRadius: 3,
            spreadRadius: -1,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth * clamped;
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: barWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  gradient: LinearGradient(
                    colors: [
                      fillColor,
                      HSLColor.fromColor(fillColor).withLightness(0.4).toColor(),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: fillColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              // Top Gloss Reflection
              Positioned(
                top: 1,
                left: 2,
                right: 2,
                height: height * 0.35,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 4),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.6),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
