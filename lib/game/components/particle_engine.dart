// Particle Engine with object pooling for ASMR visual effects (PRD Section 106 & 118)

import 'dart:math';
import 'package:flutter/material.dart';

enum ParticleType {
  circle,
  shard,     // Shattered rectangular/square brick chunk that rotates and tumbles
  ring,      // Expanding blast shockwave ring
  sparkle,   // Diamond glint star
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life; // 1.0 down to 0.0
  double maxLife;
  double size;
  double rotation;
  double rotationSpeed;
  Color color;
  ParticleType type;
  bool isAlive;

  Particle({
    this.x = 0,
    this.y = 0,
    this.vx = 0,
    this.vy = 0,
    this.life = 1.0,
    this.maxLife = 1.0,
    this.size = 4.0,
    this.rotation = 0.0,
    this.rotationSpeed = 0.0,
    this.color = Colors.white,
    this.type = ParticleType.circle,
    this.isAlive = false,
  });
}

class ParticleEngine {
  final int maxParticles;
  late final List<Particle> _pool;
  final Random _random = Random();
  int _activeCount = 0;

  /// High-efficiency thermal saver getter: allows canvas to skip renders when no particles exist
  bool get hasActiveParticles => _activeCount > 0;
  int get activeCount => _activeCount;

  // Reusable Paint & Path objects to eliminate GC allocations during rendering
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _highlightPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0;
  final Path _sparklePath = Path();

  ParticleEngine({this.maxParticles = 500}) {
    _pool = List.generate(maxParticles, (_) => Particle());
  }

  void spawnBurst({
    required double centerX,
    required double centerY,
    required List<Color> colors,
    int count = 16,
    double speedMultiplier = 1.0,
    double initialSize = 5.0,
  }) {
    int spawned = 0;
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.type = ParticleType.circle;
        p.x = centerX;
        p.y = centerY;

        final angle = _random.nextDouble() * 2 * pi;
        final speed = (_random.nextDouble() * 120 + 40) * speedMultiplier;
        p.vx = cos(angle) * speed;
        p.vy = sin(angle) * speed;

        p.life = 1.0;
        p.maxLife = 0.4 + _random.nextDouble() * 0.4; // 400 - 800 ms
        p.size = initialSize + _random.nextDouble() * 3.0;
        p.rotation = 0.0;
        p.rotationSpeed = 0.0;
        p.color = colors[_random.nextInt(colors.length)];

        spawned++;
        if (spawned >= count) break;
      }
    }
  }

  /// Spawn an explosive brick break blast effect
  /// Features shattering brick chunks/shards with tumble physics, expanding shockwave ring, and sparkles
  void spawnBrickBlast({
    required double centerX,
    required double centerY,
    required Color brickColor,
    int shardCount = 12,
    double cellSize = 32.0,
  }) {
    final shardColors = [
      brickColor,
      Color.lerp(brickColor, Colors.white, 0.45)!,
      Color.lerp(brickColor, Colors.black, 0.25)!,
      Colors.white,
    ];

    int shardsSpawned = 0;
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.x = centerX + (_random.nextDouble() * 12.0 - 6.0);
        p.y = centerY + (_random.nextDouble() * 12.0 - 6.0);

        final angle = _random.nextDouble() * 2 * pi;
        final speed = _random.nextDouble() * 180 + 70; // Explosive impulse
        p.vx = cos(angle) * speed;
        p.vy = sin(angle) * speed - 50.0; // Upward initial launch

        p.life = 1.0;
        p.maxLife = 0.45 + _random.nextDouble() * 0.35; // 450 - 800 ms
        p.size = 5.0 + _random.nextDouble() * 4.0;
        p.rotation = _random.nextDouble() * 2 * pi;
        p.rotationSpeed = (_random.nextDouble() * 16.0 - 8.0); // Fast tumbling
        p.color = shardColors[_random.nextInt(shardColors.length)];
        p.type = ParticleType.shard;

        shardsSpawned++;
        if (shardsSpawned >= shardCount) break;
      }
    }

    // Spawn expanding shockwave ring
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.x = centerX;
        p.y = centerY;
        p.vx = 0;
        p.vy = 0;
        p.life = 1.0;
        p.maxLife = 0.35; // 350ms quick ring
        p.size = cellSize * 1.6;
        p.rotation = 0;
        p.rotationSpeed = 0;
        p.color = Color.lerp(brickColor, Colors.white, 0.7)!;
        p.type = ParticleType.ring;
        break;
      }
    }

    // Spawn 6 high-speed glittering sparks
    int sparksSpawned = 0;
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.x = centerX;
        p.y = centerY;

        final angle = _random.nextDouble() * 2 * pi;
        final speed = _random.nextDouble() * 220 + 90;
        p.vx = cos(angle) * speed;
        p.vy = sin(angle) * speed;

        p.life = 1.0;
        p.maxLife = 0.3 + _random.nextDouble() * 0.25;
        p.size = 3.0 + _random.nextDouble() * 2.5;
        p.rotation = 0;
        p.rotationSpeed = 0;
        p.color = Colors.white;
        p.type = ParticleType.sparkle;

        sparksSpawned++;
        if (sparksSpawned >= 6) break;
      }
    }
  }

  void spawnShockwave({
    required double centerX,
    required double centerY,
    required Color color,
    int count = 24,
  }) {
    spawnBurst(
      centerX: centerX,
      centerY: centerY,
      colors: [color, Colors.white],
      count: count,
      speedMultiplier: 1.6,
      initialSize: 6.0,
    );
  }

  /// Massive cinematic TNT Bomb explosion with multi-layered shockwaves,
  /// tumbling incandescent shards, blazing embers, and diamond starbursts.
  void spawnTntExplosion({
    required double centerX,
    required double centerY,
    required double cellSize,
  }) {
    // 1. Dual Concentric Expanding Shockwave Rings
    // Outer fiery shockwave
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.x = centerX;
        p.y = centerY;
        p.vx = 0;
        p.vy = 0;
        p.life = 1.0;
        p.maxLife = 0.55;
        p.size = cellSize * 3.8;
        p.rotation = 0;
        p.rotationSpeed = 0;
        p.color = const Color(0xFFFF3D00); // Fiery blazing orange-red
        p.type = ParticleType.ring;
        break;
      }
    }
    // Inner high-heat flash shockwave
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.x = centerX;
        p.y = centerY;
        p.vx = 0;
        p.vy = 0;
        p.life = 1.0;
        p.maxLife = 0.38;
        p.size = cellSize * 2.4;
        p.rotation = 0;
        p.rotationSpeed = 0;
        p.color = const Color(0xFFFFEA00); // Intense electric gold/white flash
        p.type = ParticleType.ring;
        break;
      }
    }

    // 2. High-Density Tumbling Incandescent Shards & Shrapnel (36 particles)
    final shardColors = [
      const Color(0xFFFF1744), // Crimson blast
      const Color(0xFFFF5722), // Fiery neon orange
      const Color(0xFFFF9100), // Amber flame
      const Color(0xFFFFD600), // Yellow fire
      const Color(0xFF263238), // Carbon soot/ash
      Colors.white,
    ];

    int shardsSpawned = 0;
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.x = centerX + (_random.nextDouble() * 24.0 - 12.0);
        p.y = centerY + (_random.nextDouble() * 24.0 - 12.0);

        final angle = _random.nextDouble() * 2 * pi;
        final speed = _random.nextDouble() * 260 + 100;
        p.vx = cos(angle) * speed;
        p.vy = sin(angle) * speed - 80.0; // Upward explosive lift

        p.life = 1.0;
        p.maxLife = 0.5 + _random.nextDouble() * 0.45; // 500 - 950 ms
        p.size = 6.0 + _random.nextDouble() * 6.0;
        p.rotation = _random.nextDouble() * 2 * pi;
        p.rotationSpeed = (_random.nextDouble() * 24.0 - 12.0);
        p.color = shardColors[_random.nextInt(shardColors.length)];
        p.type = ParticleType.shard;

        shardsSpawned++;
        if (shardsSpawned >= 36) break;
      }
    }

    // 3. Radial Blazing Embers (28 fire spheres)
    final emberColors = [
      const Color(0xFFFF5722),
      const Color(0xFFFF9100),
      const Color(0xFFFFD600),
      Colors.white,
    ];
    int embersSpawned = 0;
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.x = centerX;
        p.y = centerY;

        final angle = _random.nextDouble() * 2 * pi;
        final speed = _random.nextDouble() * 200 + 60;
        p.vx = cos(angle) * speed;
        p.vy = sin(angle) * speed;

        p.life = 1.0;
        p.maxLife = 0.4 + _random.nextDouble() * 0.4;
        p.size = 5.0 + _random.nextDouble() * 4.0;
        p.rotation = 0;
        p.rotationSpeed = 0;
        p.color = emberColors[_random.nextInt(emberColors.length)];
        p.type = ParticleType.circle;

        embersSpawned++;
        if (embersSpawned >= 28) break;
      }
    }

    // 4. Diamond Glint Stars (16 high-speed glittering sparks)
    int sparksSpawned = 0;
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.x = centerX;
        p.y = centerY;

        final angle = _random.nextDouble() * 2 * pi;
        final speed = _random.nextDouble() * 320 + 120;
        p.vx = cos(angle) * speed;
        p.vy = sin(angle) * speed;

        p.life = 1.0;
        p.maxLife = 0.35 + _random.nextDouble() * 0.3;
        p.size = 4.0 + _random.nextDouble() * 3.5;
        p.rotation = 0;
        p.rotationSpeed = 0;
        p.color = Colors.white;
        p.type = ParticleType.sparkle;

        sparksSpawned++;
        if (sparksSpawned >= 16) break;
      }
    }
  }

  /// Spawns a high-energy electric lightning arc between two cell coordinates
  void spawnLightningArc({
    required double fromX,
    required double fromY,
    required double toX,
    required double toY,
  }) {
    final dx = toX - fromX;
    final dy = toY - fromY;
    final distance = sqrt(dx * dx + dy * dy);
    final steps = (distance / 8.0).clamp(4, 20).toInt();

    final electricColors = [
      const Color(0xFF00E5FF), // Cyan spark
      const Color(0xFF76FF03), // Electric lime
      const Color(0xFFFFFF00), // Yellow bolt
      Colors.white,
    ];

    // Shockwave ring at target
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.x = toX;
        p.y = toY;
        p.vx = 0;
        p.vy = 0;
        p.life = 1.0;
        p.maxLife = 0.28;
        p.size = 28.0;
        p.rotation = 0;
        p.rotationSpeed = 0;
        p.color = const Color(0xFF00E5FF);
        p.type = ParticleType.ring;
        break;
      }
    }

    // Zig-zag electric line particles
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final baseX = fromX + dx * t;
      final baseY = fromY + dy * t;
      final jitter = (_random.nextDouble() * 16.0 - 8.0);

      for (final p in _pool) {
        if (!p.isAlive) {
          p.isAlive = true;
          p.x = baseX + jitter;
          p.y = baseY + jitter;
          p.vx = (_random.nextDouble() * 60.0 - 30.0);
          p.vy = (_random.nextDouble() * 60.0 - 30.0);
          p.life = 1.0;
          p.maxLife = 0.2 + _random.nextDouble() * 0.18;
          p.size = 3.0 + _random.nextDouble() * 2.5;
          p.rotation = _random.nextDouble() * 2 * pi;
          p.rotationSpeed = _random.nextDouble() * 10.0;
          p.color = electricColors[_random.nextInt(electricColors.length)];
          p.type = (_random.nextBool() ? ParticleType.sparkle : ParticleType.circle);
          break;
        }
      }
    }
  }

  /// Spawns chromatic spectrum burst when Rainbow block clears
  void spawnRainbowPrismBurst({
    required double centerX,
    required double centerY,
    double cellSize = 32.0,
  }) {
    final rainbowColors = [
      const Color(0xFFFF1744), // Red
      const Color(0xFFFF9100), // Orange
      const Color(0xFFFFEA00), // Yellow
      const Color(0xFF00E676), // Green
      const Color(0xFF00E5FF), // Cyan
      const Color(0xFF2979FF), // Blue
      const Color(0xFFD500F9), // Purple
      Colors.white,
    ];

    // Rainbow shockwave ring
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.x = centerX;
        p.y = centerY;
        p.vx = 0;
        p.vy = 0;
        p.life = 1.0;
        p.maxLife = 0.4;
        p.size = cellSize * 2.2;
        p.rotation = 0;
        p.rotationSpeed = 0;
        p.color = const Color(0xFFE040FB);
        p.type = ParticleType.ring;
        break;
      }
    }

    int count = 0;
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.x = centerX;
        p.y = centerY;

        final angle = (count / 24.0) * 2 * pi;
        final speed = _random.nextDouble() * 160 + 80;
        p.vx = cos(angle) * speed;
        p.vy = sin(angle) * speed;

        p.life = 1.0;
        p.maxLife = 0.5 + _random.nextDouble() * 0.3;
        p.size = 5.0 + _random.nextDouble() * 3.0;
        p.rotation = _random.nextDouble() * 2 * pi;
        p.rotationSpeed = (_random.nextDouble() * 10.0 - 5.0);
        p.color = rainbowColors[count % rainbowColors.length];
        p.type = count % 2 == 0 ? ParticleType.sparkle : ParticleType.shard;

        count++;
        if (count >= 24) break;
      }
    }
  }

  /// Spawns crystalline glass and frost shatter when Ice block breaks
  void spawnIceShatter({
    required double centerX,
    required double centerY,
    double cellSize = 32.0,
  }) {
    final iceColors = [
      const Color(0xFFE0F7FA), // Soft frost white
      const Color(0xFF80DEEA), // Glacial cyan
      const Color(0xFF4DD0E1), // Cyan crystal
      const Color(0xFF00E5FF), // Electric cyan
      Colors.white,
    ];

    // Frost shockwave ring
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.x = centerX;
        p.y = centerY;
        p.vx = 0;
        p.vy = 0;
        p.life = 1.0;
        p.maxLife = 0.35;
        p.size = cellSize * 1.8;
        p.rotation = 0;
        p.rotationSpeed = 0;
        p.color = const Color(0xFFB2EBF2);
        p.type = ParticleType.ring;
        break;
      }
    }

    int shards = 0;
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.x = centerX + (_random.nextDouble() * 10.0 - 5.0);
        p.y = centerY + (_random.nextDouble() * 10.0 - 5.0);

        final angle = _random.nextDouble() * 2 * pi;
        final speed = _random.nextDouble() * 150 + 60;
        p.vx = cos(angle) * speed;
        p.vy = sin(angle) * speed - 40.0;

        p.life = 1.0;
        p.maxLife = 0.45 + _random.nextDouble() * 0.3;
        p.size = 4.0 + _random.nextDouble() * 4.0;
        p.rotation = _random.nextDouble() * 2 * pi;
        p.rotationSpeed = (_random.nextDouble() * 18.0 - 9.0);
        p.color = iceColors[_random.nextInt(iceColors.length)];
        p.type = ParticleType.shard;

        shards++;
        if (shards >= 18) break;
      }
    }
  }

  /// Spawns shimmering coin gold shower
  void spawnCoinBurst({
    required double centerX,
    required double centerY,
  }) {
    final goldColors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFFFC107), // Amber
      const Color(0xFFFFE082), // Light gold
      Colors.white,
    ];

    int spawned = 0;
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.x = centerX + (_random.nextDouble() * 12.0 - 6.0);
        p.y = centerY + (_random.nextDouble() * 12.0 - 6.0);

        final angle = -pi / 2 + (_random.nextDouble() * 1.2 - 0.6); // Upward cone
        final speed = _random.nextDouble() * 180 + 100;
        p.vx = cos(angle) * speed;
        p.vy = sin(angle) * speed;

        p.life = 1.0;
        p.maxLife = 0.55 + _random.nextDouble() * 0.35;
        p.size = 5.0 + _random.nextDouble() * 3.5;
        p.rotation = 0;
        p.rotationSpeed = 0;
        p.color = goldColors[_random.nextInt(goldColors.length)];
        p.type = ParticleType.sparkle;

        spawned++;
        if (spawned >= 16) break;
      }
    }
  }

  /// Emits subtle stardust sparkles while user drags a block
  void spawnDragStardust({
    required double x,
    required double y,
    required Color color,
  }) {
    int count = 0;
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        p.x = x + (_random.nextDouble() * 16.0 - 8.0);
        p.y = y + (_random.nextDouble() * 16.0 - 8.0);
        p.vx = (_random.nextDouble() * 30.0 - 15.0);
        p.vy = (_random.nextDouble() * 20.0 + 10.0); // Gentle downward drift
        p.life = 1.0;
        p.maxLife = 0.25 + _random.nextDouble() * 0.15;
        p.size = 2.5 + _random.nextDouble() * 2.0;
        p.rotation = 0;
        p.rotationSpeed = 0;
        p.color = Color.lerp(color, Colors.white, 0.55)!;
        p.type = ParticleType.sparkle;

        count++;
        _activeCount++;
        if (count >= 2) break;
      }
    }
  }

  /// Spawns dazzling multi-layer geode crystalline shatter explosion
  void spawnGeodeShatter({
    required double centerX,
    required double centerY,
    double cellSize = 36.0,
  }) {
    final geodeColors = [
      const Color(0xFFBA68C8), // Amethyst lavender
      const Color(0xFF9C27B0), // Royal purple
      const Color(0xFF00E5FF), // Diamond cyan
      const Color(0xFFE0F7FA), // Ice diamond
      Colors.white,
    ];

    int shards = 0;
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        _activeCount++;
        p.x = centerX + (_random.nextDouble() * 10.0 - 5.0);
        p.y = centerY + (_random.nextDouble() * 10.0 - 5.0);

        final angle = _random.nextDouble() * 2 * pi;
        final speed = _random.nextDouble() * 200 + 80;
        p.vx = cos(angle) * speed;
        p.vy = sin(angle) * speed - 50.0;

        p.life = 1.0;
        p.maxLife = 0.5 + _random.nextDouble() * 0.35;
        p.size = 5.0 + _random.nextDouble() * 4.0;
        p.rotation = _random.nextDouble() * 2 * pi;
        p.rotationSpeed = (_random.nextDouble() * 20.0 - 10.0);
        p.color = geodeColors[_random.nextInt(geodeColors.length)];
        p.type = ParticleType.shard;

        shards++;
        if (shards >= 20) break;
      }
    }

    // Sparkle glints
    int sparkles = 0;
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        _activeCount++;
        p.x = centerX + (_random.nextDouble() * 16.0 - 8.0);
        p.y = centerY + (_random.nextDouble() * 16.0 - 8.0);

        final angle = _random.nextDouble() * 2 * pi;
        final speed = _random.nextDouble() * 140 + 60;
        p.vx = cos(angle) * speed;
        p.vy = sin(angle) * speed;

        p.life = 1.0;
        p.maxLife = 0.6 + _random.nextDouble() * 0.3;
        p.size = 6.0 + _random.nextDouble() * 4.0;
        p.rotation = 0;
        p.rotationSpeed = 0;
        p.color = Colors.white;
        p.type = ParticleType.sparkle;

        sparkles++;
        if (sparkles >= 12) break;
      }
    }

    // Shockwave ring
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        _activeCount++;
        p.x = centerX;
        p.y = centerY;
        p.vx = 0;
        p.vy = 0;
        p.life = 1.0;
        p.maxLife = 0.45;
        p.size = cellSize * 2.2;
        p.color = const Color(0xFF00E5FF);
        p.type = ParticleType.ring;
        break;
      }
    }
  }

  /// Spawns fiery detonation blast for Countdown Time-Bomb Block
  void spawnTimeBombDetonation({
    required double centerX,
    required double centerY,
    double cellSize = 36.0,
  }) {
    final bombColors = [
      const Color(0xFFFF3D00), // Blazing red-orange
      const Color(0xFFFF9100), // Amber flame
      const Color(0xFFFFD600), // Solar core yellow
      const Color(0xFFFF5252), // Incandescent coral
      Colors.white,
    ];

    int count = 0;
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        _activeCount++;
        p.x = centerX + (_random.nextDouble() * 14.0 - 7.0);
        p.y = centerY + (_random.nextDouble() * 14.0 - 7.0);

        final angle = _random.nextDouble() * 2 * pi;
        final speed = _random.nextDouble() * 240 + 90;
        p.vx = cos(angle) * speed;
        p.vy = sin(angle) * speed - 60.0;

        p.life = 1.0;
        p.maxLife = 0.55 + _random.nextDouble() * 0.35;
        p.size = 6.0 + _random.nextDouble() * 4.5;
        p.rotation = _random.nextDouble() * 2 * pi;
        p.rotationSpeed = (_random.nextDouble() * 24.0 - 12.0);
        p.color = bombColors[_random.nextInt(bombColors.length)];
        p.type = ParticleType.shard;

        count++;
        if (count >= 24) break;
      }
    }

    // Fiery shockwave ring
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        _activeCount++;
        p.x = centerX;
        p.y = centerY;
        p.vx = 0;
        p.vy = 0;
        p.life = 1.0;
        p.maxLife = 0.42;
        p.size = cellSize * 2.8;
        p.color = const Color(0xFFFF3D00);
        p.type = ParticleType.ring;
        break;
      }
    }
  }

  /// Spawns ethereal swirling portal vortex particles
  void spawnPortalVortex({
    required double centerX,
    required double centerY,
  }) {
    final portalColors = [
      const Color(0xFF00E5FF), // Cyan portal
      const Color(0xFFD500F9), // Purple portal
      const Color(0xFF7C4DFF), // Indigo
      Colors.white,
    ];

    int spawned = 0;
    for (final p in _pool) {
      if (!p.isAlive) {
        p.isAlive = true;
        _activeCount++;
        final angle = _random.nextDouble() * 2 * pi;
        final dist = _random.nextDouble() * 20.0 + 8.0;
        p.x = centerX + cos(angle) * dist;
        p.y = centerY + sin(angle) * dist;

        // Tangential velocity creates spiral orbit
        final speed = _random.nextDouble() * 90 + 50;
        p.vx = -sin(angle) * speed;
        p.vy = cos(angle) * speed;

        p.life = 1.0;
        p.maxLife = 0.4 + _random.nextDouble() * 0.25;
        p.size = 3.5 + _random.nextDouble() * 2.5;
        p.rotation = 0;
        p.rotationSpeed = 0;
        p.color = portalColors[_random.nextInt(portalColors.length)];
        p.type = ParticleType.sparkle;

        spawned++;
        if (spawned >= 14) break;
      }
    }
  }

  void update(double dt) {
    if (_activeCount == 0) return; // Thermal saver: 0 CPU iterations when idle!
    final safeDt = dt.clamp(0.0, 0.05);
    int alive = 0;
    for (final p in _pool) {
      if (p.isAlive) {
        p.x += p.vx * safeDt;
        p.y += p.vy * safeDt;

        // Physical gravity and drag
        if (p.type == ParticleType.shard) {
          p.vy += 320 * safeDt; // Heavy realistic brick gravity
          p.vx *= (1.0 - 0.8 * safeDt).clamp(0.0, 1.0); // Air drag
          p.rotation += p.rotationSpeed * safeDt;
        } else if (p.type == ParticleType.circle) {
          p.vy += 90 * safeDt;
          p.vx *= (1.0 - 0.5 * safeDt).clamp(0.0, 1.0);
        }

        p.life -= safeDt / p.maxLife;
        if (p.life <= 0) {
          p.isAlive = false;
        } else {
          alive++;
        }
      }
    }
    _activeCount = alive;
  }

  void render(Canvas canvas) {
    if (_activeCount == 0) return; // Thermal saver: 0 GPU draw calls when idle!
    for (final p in _pool) {
      if (p.isAlive) {
        final currentAlpha = (p.life.clamp(0.0, 1.0) * 255).round();

        switch (p.type) {
          case ParticleType.shard:
            // Shattered beveled rectangular brick shard
            _fillPaint.color = p.color.withAlpha(currentAlpha);
            final scale = (0.35 + 0.65 * p.life);
            final halfW = (p.size * scale) * 0.9;
            final halfH = halfW * 0.75;

            canvas.save();
            canvas.translate(p.x, p.y);
            canvas.rotate(p.rotation);
            final rect = Rect.fromCenter(center: Offset.zero, width: halfW * 2, height: halfH * 2);
            canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1.5)), _fillPaint);

            // Specular edge highlight on shard
            _highlightPaint.color = Colors.white.withAlpha((currentAlpha * 0.7).round());
            canvas.drawLine(rect.topLeft, rect.topRight, _highlightPaint);
            canvas.restore();
            break;

          case ParticleType.ring:
            // Expanding shockwave ring
            final ringRadius = p.size * (1.8 - 1.2 * p.life);
            _strokePaint.color = p.color.withAlpha((currentAlpha * 0.8).round());
            _strokePaint.strokeWidth = 2.5 * p.life;
            canvas.drawCircle(Offset(p.x, p.y), ringRadius, _strokePaint);
            break;

          case ParticleType.sparkle:
            // Diamond glint star (zero-allocation reuse of _sparklePath)
            _fillPaint.color = p.color.withAlpha(currentAlpha);
            final s = p.size * (0.4 + 0.6 * p.life);
            final thin = s * 0.35;
            _sparklePath.reset();
            _sparklePath.moveTo(p.x, p.y - s);
            _sparklePath.lineTo(p.x + thin, p.y);
            _sparklePath.lineTo(p.x, p.y + s);
            _sparklePath.lineTo(p.x - thin, p.y);
            _sparklePath.close();
            _sparklePath.moveTo(p.x - s, p.y);
            _sparklePath.lineTo(p.x, p.y + thin);
            _sparklePath.lineTo(p.x + s, p.y);
            _sparklePath.lineTo(p.x, p.y - thin);
            _sparklePath.close();
            canvas.drawPath(_sparklePath, _fillPaint);
            break;

          case ParticleType.circle:
            _fillPaint.color = p.color.withAlpha(currentAlpha);
            final currentRadius = p.size * (0.3 + 0.7 * p.life);
            canvas.drawCircle(Offset(p.x, p.y), currentRadius, _fillPaint);
            break;
        }
      }
    }
  }

  void clear() {
    for (final p in _pool) {
      p.isAlive = false;
    }
    _activeCount = 0;
  }
}
