// Dynamic Visual Themes for Block Blast Pro according to PRD Sections 31 & 458-472

import 'package:flutter/material.dart';

enum ThemeSoundProfile {
  crystal,
  neon,
  ocean,
  paper,
  zen,
  aurora,
  gold,
  magma,
}

class GameTheme {
  final String id;
  final String name;
  final String description;
  final Color backgroundStart;
  final Color backgroundEnd;
  final Color boardBackground;
  final Color boardBorder;
  final Color cellEmpty;
  final Color cellBorder;
  final Color accent;
  final List<Color> blockPalette;
  final List<Color> particlePalette;
  final ThemeSoundProfile soundProfile;
  final IconData icon;
  final int requiredHighScore;
  final int requiredStreak;
  final bool isDefaultUnlocked;

  const GameTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.boardBackground,
    required this.boardBorder,
    required this.cellEmpty,
    required this.cellBorder,
    required this.accent,
    required this.blockPalette,
    required this.particlePalette,
    required this.soundProfile,
    required this.icon,
    this.requiredHighScore = 0,
    this.requiredStreak = 0,
    this.isDefaultUnlocked = true,
  });

  bool isUnlocked({
    required int highScore,
    required int streak,
    required List<String> unlockedIds,
  }) {
    if (isDefaultUnlocked) return true;
    if (unlockedIds.contains(id)) return true;
    if (requiredHighScore > 0 && highScore >= requiredHighScore) return true;
    if (requiredStreak > 0 && streak >= requiredStreak) return true;
    return false;
  }

  String get unlockRequirementText {
    if (isDefaultUnlocked) return 'Unlocked';
    if (requiredHighScore > 0 && requiredStreak > 0) {
      return '$requiredHighScore+ pts OR $requiredStreak-Day Streak';
    }
    if (requiredHighScore > 0) return 'Score $requiredHighScore+ pts';
    if (requiredStreak > 0) return '$requiredStreak-Day Streak';
    return 'Unlocked';
  }

  static const GameTheme crystalFlow = GameTheme(
    id: 'crystal_flow',
    name: 'Crystal Flow',
    description: 'Transparent crystal materials with soft refracted azure glow.',
    backgroundStart: Color(0xFFF0F6FF),
    backgroundEnd: Color(0xFFDCEBFE),
    boardBackground: Color(0x80FFFFFF),
    boardBorder: Color(0xFFBAE6FD),
    cellEmpty: Color(0x1F0284C7),
    cellBorder: Color(0x330284C7),
    accent: Color(0xFF0284C7),
    blockPalette: [
      Color(0xFF06B6D4), // Cyan
      Color(0xFF3B82F6), // Blue
      Color(0xFF6366F1), // Indigo
      Color(0xFF8B5CF6), // Purple
      Color(0xFFEC4899), // Pink
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
    ],
    particlePalette: [
      Color(0xFF38BDF8),
      Color(0xFF818CF8),
      Color(0xFFC084FC),
      Color(0xFFE0F2FE),
    ],
    soundProfile: ThemeSoundProfile.crystal,
    icon: Icons.diamond_outlined,
  );

  static const GameTheme neonGeometry = GameTheme(
    id: 'neon_geometry',
    name: 'Neon Geometry',
    description: 'High energy futuristic presentation with electric neon glows.',
    backgroundStart: Color(0xFFFDF4FF),
    backgroundEnd: Color(0xFFF5D0FE),
    boardBackground: Color(0x80FFFFFF),
    boardBorder: Color(0xFFE879F9),
    cellEmpty: Color(0x1FD946EF),
    cellBorder: Color(0x33D946EF),
    accent: Color(0xFFD946EF),
    blockPalette: [
      Color(0xFFFF007F), // Neon Pink
      Color(0xFF00F0FF), // Electric Cyan
      Color(0xFFFFB800), // Neon Yellow
      Color(0xFF7928CA), // Deep Violet
      Color(0xFF00FF66), // Acid Green
      Color(0xFFFF4500), // Orange Red
      Color(0xFFB026FF), // Neon Purple
    ],
    particlePalette: [
      Color(0xFFFF007F),
      Color(0xFF00F0FF),
      Color(0xFFFFEE00),
      Color(0xFFFFFFFF),
    ],
    soundProfile: ThemeSoundProfile.neon,
    icon: Icons.bolt,
  );

  static const GameTheme oceanDrift = GameTheme(
    id: 'ocean_drift',
    name: 'Ocean Drift',
    description: 'Deep oceanic currents with buoyant bubbles and teal refractions.',
    backgroundStart: Color(0xFFF0FDF4),
    backgroundEnd: Color(0xFFCCFBF1),
    boardBackground: Color(0x80FFFFFF),
    boardBorder: Color(0xFF5EEAD4),
    cellEmpty: Color(0x1F0D9488),
    cellBorder: Color(0x330D9488),
    accent: Color(0xFF0D9488),
    blockPalette: [
      Color(0xFF14B8A6), // Teal
      Color(0xFF0EA5E9), // Sky Blue
      Color(0xFF065F46), // Deep Emerald
      Color(0xFF2DD4BF), // Light Teal
      Color(0xFF38BDF8), // Ice Blue
      Color(0xFFF43F5E), // Coral
      Color(0xFFFBBF24), // Sunlit Amber
    ],
    particlePalette: [
      Color(0xFF2DD4BF),
      Color(0xFF7DD3FC),
      Color(0xFFCCFBF1),
      Color(0xFFFFFFFF),
    ],
    soundProfile: ThemeSoundProfile.ocean,
    icon: Icons.water_drop_outlined,
  );

  static const GameTheme paperAtelier = GameTheme(
    id: 'paper_atelier',
    name: 'Paper Atelier',
    description: 'Tactile paper-fold materials with warm shadows and organic textures.',
    backgroundStart: Color(0xFFFFFBEB),
    backgroundEnd: Color(0xFFFEF3C7),
    boardBackground: Color(0x80FFFFFF),
    boardBorder: Color(0xFFFDE68A),
    cellEmpty: Color(0x22D97706),
    cellBorder: Color(0x38D97706),
    accent: Color(0xFFD97706),
    blockPalette: [
      Color(0xFFD97706), // Kraft Amber
      Color(0xFFB45309), // Terracotta
      Color(0xFF92400E), // Russet
      Color(0xFF059669), // Sage Green
      Color(0xFF2563EB), // Blueprint Blue
      Color(0xFFDC2626), // Carmine
      Color(0xFF7C3AED), // Mulberry
    ],
    particlePalette: [
      Color(0xFFFDE68A),
      Color(0xFFFBBF24),
      Color(0xFFF87171),
      Color(0xFFFEF3C7),
    ],
    soundProfile: ThemeSoundProfile.paper,
    icon: Icons.layers_outlined,
  );

  static const GameTheme zenStone = GameTheme(
    id: 'zen_stone',
    name: 'Zen Stone',
    description: 'Ceramic & polished river stones with serene grounding ripples.',
    backgroundStart: Color(0xFFF8FAFC),
    backgroundEnd: Color(0xFFE2E8F0),
    boardBackground: Color(0x80FFFFFF),
    boardBorder: Color(0xFFCBD5E1),
    cellEmpty: Color(0x2064748B),
    cellBorder: Color(0x3864748B),
    accent: Color(0xFF475569),
    blockPalette: [
      Color(0xFF78716C), // Pebble Slate
      Color(0xFF57534E), // Dark Granite
      Color(0xFFA8A29E), // Polished Stone
      Color(0xFF059669), // Moss Jade
      Color(0xFF0284C7), // River Azure
      Color(0xFFD97706), // Sandstone
      Color(0xFF9333EA), // Amethyst
    ],
    particlePalette: [
      Color(0xFFD6D3D1),
      Color(0xFFA8A29E),
      Color(0xFFE7E5E4),
      Color(0xFF6EE7B7),
    ],
    soundProfile: ThemeSoundProfile.zen,
    icon: Icons.spa_outlined,
  );

  static const GameTheme auroraGarden = GameTheme(
    id: 'aurora_garden',
    name: 'Aurora Garden',
    description: 'Slow atmospheric polar light trails with floating luminous spores.',
    backgroundStart: Color(0xFFF0FDF4),
    backgroundEnd: Color(0xFFD1FAE5),
    boardBackground: Color(0x80FFFFFF),
    boardBorder: Color(0xFF6EE7B7),
    cellEmpty: Color(0x1F059669),
    cellBorder: Color(0x33059669),
    accent: Color(0xFF059669),
    blockPalette: [
      Color(0xFF10B981), // Aurora Green
      Color(0xFF06B6D4), // Cyan
      Color(0xFF8B5CF6), // Polar Violet
      Color(0xFFEC4899), // Solar Flare
      Color(0xFF3B82F6), // Night Sky
      Color(0xFFF59E0B), // Golden Star
      Color(0xFF14B8A6), // Shimmer Teal
    ],
    particlePalette: [
      Color(0xFF34D399),
      Color(0xFF67E8F9),
      Color(0xFFA78BFA),
      Color(0xFFF472B6),
    ],
    soundProfile: ThemeSoundProfile.aurora,
    icon: Icons.wb_twilight_outlined,
  );

  static const GameTheme neonCyberpunk = GameTheme(
    id: 'neon_cyberpunk',
    name: 'Neon Cyberpunk',
    description: 'High-tech synthwave grid with electric magenta and cyber-cyan pulses.',
    backgroundStart: Color(0xFFFDF2F8),
    backgroundEnd: Color(0xFFFCE7F3),
    boardBackground: Color(0x80FFFFFF),
    boardBorder: Color(0xFFF472B6),
    cellEmpty: Color(0x20DB2777),
    cellBorder: Color(0x38DB2777),
    accent: Color(0xFFDB2777),
    blockPalette: [
      Color(0xFFFF2A85),
      Color(0xFF00F0FF),
      Color(0xFFFFD300),
      Color(0xFF7928CA),
      Color(0xFF05FFA1),
      Color(0xFFFF6100),
      Color(0xFFB026FF),
    ],
    particlePalette: [
      Color(0xFFFF2A85),
      Color(0xFF00F0FF),
      Color(0xFFFFD300),
      Color(0xFFFFFFFF),
    ],
    soundProfile: ThemeSoundProfile.neon,
    icon: Icons.sports_esports,
    requiredHighScore: 2500,
    requiredStreak: 3,
    isDefaultUnlocked: false,
  );

  static const GameTheme woodcraft = GameTheme(
    id: 'woodcraft',
    name: 'Woodcraft',
    description: 'Tactile artisanal wooden blocks with warm carved shadows and maple grain.',
    backgroundStart: Color(0xFFFFF7ED),
    backgroundEnd: Color(0xFFFFEDD5),
    boardBackground: Color(0x80FFFFFF),
    boardBorder: Color(0xFFFDBA74),
    cellEmpty: Color(0x20EA580C),
    cellBorder: Color(0x38EA580C),
    accent: Color(0xFFEA580C),
    blockPalette: [
      Color(0xFFD97706),
      Color(0xFFB45309),
      Color(0xFF92400E),
      Color(0xFF78350F),
      Color(0xFFCA8A04),
      Color(0xFFA16207),
      Color(0xFFEA580C),
    ],
    particlePalette: [
      Color(0xFFFDE68A),
      Color(0xFFF59E0B),
      Color(0xFFD97706),
      Color(0xFFFEF3C7),
    ],
    soundProfile: ThemeSoundProfile.paper,
    icon: Icons.forest_outlined,
    requiredHighScore: 5000,
    requiredStreak: 5,
    isDefaultUnlocked: false,
  );

  static const GameTheme jewelPrism = GameTheme(
    id: 'jewel_prism',
    name: 'Jewel Prism',
    description: 'Radiant multifaceted gemstones with brilliant chromatic refractions.',
    backgroundStart: Color(0xFFFAF5FF),
    backgroundEnd: Color(0xFFEDE9FE),
    boardBackground: Color(0x80FFFFFF),
    boardBorder: Color(0xFFC4B5FD),
    cellEmpty: Color(0x207C3AED),
    cellBorder: Color(0x387C3AED),
    accent: Color(0xFF7C3AED),
    blockPalette: [
      Color(0xFFE11D48),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFF6366F1),
    ],
    particlePalette: [
      Color(0xFFFDA4AF),
      Color(0xFFC4B5FD),
      Color(0xFF67E8F9),
      Color(0xFFFFFFFF),
    ],
    soundProfile: ThemeSoundProfile.crystal,
    icon: Icons.auto_awesome,
    requiredHighScore: 10000,
    requiredStreak: 7,
    isDefaultUnlocked: false,
  );

  static const GameTheme obsidianGlow = GameTheme(
    id: 'obsidian_glow',
    name: 'Obsidian Glow',
    description: 'Polished volcanic glass with pulsing molten magma fractures.',
    backgroundStart: Color(0xFFFFF1F2),
    backgroundEnd: Color(0xFFFFE4E6),
    boardBackground: Color(0x80FFFFFF),
    boardBorder: Color(0xFFFDA4AF),
    cellEmpty: Color(0x20E11D48),
    cellBorder: Color(0x38E11D48),
    accent: Color(0xFFE11D48),
    blockPalette: [
      Color(0xFFFF4500),
      Color(0xFFDC2626),
      Color(0xFFF97316),
      Color(0xFFFB923C),
      Color(0xFF7F1D1D),
      Color(0xFF991B1B),
      Color(0xFFFBBF24),
    ],
    particlePalette: [
      Color(0xFFFF4500),
      Color(0xFFF97316),
      Color(0xFFFDE047),
      Color(0xFFFFFFFF),
    ],
    soundProfile: ThemeSoundProfile.zen,
    icon: Icons.local_fire_department,
    requiredHighScore: 20000,
    requiredStreak: 14,
    isDefaultUnlocked: false,
  );

  static const GameTheme royalMidas = GameTheme(
    id: 'royal_midas',
    name: 'Royal Midas',
    description: 'Lustrous 24k polished gold bevels with sweeping specular radiance.',
    backgroundStart: Color(0xFFFFFBEB),
    backgroundEnd: Color(0xFFFEF9C3),
    boardBackground: Color(0x80FFFFFF),
    boardBorder: Color(0xFFFDE047),
    cellEmpty: Color(0x22CA8A04),
    cellBorder: Color(0x38CA8A04),
    accent: Color(0xFFCA8A04),
    blockPalette: [
      Color(0xFFFFD700), // 24k Gold
      Color(0xFFFFC107), // Amber Gold
      Color(0xFFFFE082), // Champagne
      Color(0xFFE91E63), // Royal Ruby
      Color(0xFF9C27B0), // Sovereign Purple
      Color(0xFF00E676), // Imperial Emerald
      Color(0xFF2979FF), // Royal Sapphire
    ],
    particlePalette: [
      Color(0xFFFFD700),
      Color(0xFFFFE57F),
      Color(0xFFFFF9C4),
      Color(0xFFFFFFFF),
    ],
    soundProfile: ThemeSoundProfile.gold,
    icon: Icons.military_tech,
    requiredHighScore: 15000,
    requiredStreak: 10,
    isDefaultUnlocked: false,
  );

  static const GameTheme volcanicMagma = GameTheme(
    id: 'volcanic_magma',
    name: 'Volcanic Magma',
    description: 'Subterranean molten lava fissures with incandescent basalt crust.',
    backgroundStart: Color(0xFFFEF2F2),
    backgroundEnd: Color(0xFFFEE2E2),
    boardBackground: Color(0x80FFFFFF),
    boardBorder: Color(0xFFFCA5A5),
    cellEmpty: Color(0x20DC2626),
    cellBorder: Color(0x38DC2626),
    accent: Color(0xFFDC2626),
    blockPalette: [
      Color(0xFFFF3D00), // Molten Lava
      Color(0xFFFF6D00), // Blazing Flame
      Color(0xFFFFAB00), // Hot Magma
      Color(0xFFD50000), // Deep Crimson
      Color(0xFFBF360C), // Basalt Red
      Color(0xFFFFD600), // Solar Core
      Color(0xFF795548), // Volcanic Rock
    ],
    particlePalette: [
      Color(0xFFFF3D00),
      Color(0xFFFF9100),
      Color(0xFFFFEA00),
      Color(0xFFFFFFFF),
    ],
    soundProfile: ThemeSoundProfile.magma,
    icon: Icons.volcano_outlined,
    requiredHighScore: 8000,
    requiredStreak: 6,
    isDefaultUnlocked: false,
  );

  static const GameTheme bioluminescence = GameTheme(
    id: 'bioluminescence',
    name: 'Bioluminescence',
    description: 'Deep sea abyss glowing with luminous jellyfish azure and coral refractions.',
    backgroundStart: Color(0xFFECFEFF),
    backgroundEnd: Color(0xFFCFFAFE),
    boardBackground: Color(0x80FFFFFF),
    boardBorder: Color(0xFF67E8F9),
    cellEmpty: Color(0x200891B2),
    cellBorder: Color(0x380891B2),
    accent: Color(0xFF0891B2),
    blockPalette: [
      Color(0xFF00E5FF),
      Color(0xFF1DE9B6),
      Color(0xFF00B0FF),
      Color(0xFF76FF03),
      Color(0xFF651FFF),
      Color(0xFFFF4081),
      Color(0xFF00E676),
    ],
    particlePalette: [
      Color(0xFF00E5FF),
      Color(0xFF1DE9B6),
      Color(0xFFE0F7FA),
      Color(0xFFFFFFFF),
    ],
    soundProfile: ThemeSoundProfile.ocean,
    icon: Icons.bubble_chart,
    requiredHighScore: 3500,
    requiredStreak: 4,
    isDefaultUnlocked: false,
  );

  static const GameTheme retroArcade = GameTheme(
    id: 'retro_arcade',
    name: 'Retro 16-Bit',
    description: 'Pixelated arcade nostalgia with dithered bevels and authentic retro hues.',
    backgroundStart: Color(0xFFF1F5F9),
    backgroundEnd: Color(0xFFE2E8F0),
    boardBackground: Color(0x80FFFFFF),
    boardBorder: Color(0xFF94A3B8),
    cellEmpty: Color(0x20475569),
    cellBorder: Color(0x38475569),
    accent: Color(0xFF0284C7),
    blockPalette: [
      Color(0xFFFF5722),
      Color(0xFF29B6F6),
      Color(0xFFFFEE58),
      Color(0xFF66BB6A),
      Color(0xFFAB47BC),
      Color(0xFFFF7043),
      Color(0xFF26A69A),
    ],
    particlePalette: [
      Color(0xFFFF5722),
      Color(0xFF29B6F6),
      Color(0xFFFFEE58),
      Color(0xFFFFFFFF),
    ],
    soundProfile: ThemeSoundProfile.neon,
    icon: Icons.videogame_asset,
    requiredHighScore: 4500,
    requiredStreak: 4,
    isDefaultUnlocked: false,
  );

  static const GameTheme cosmicStarlight = GameTheme(
    id: 'cosmic_starlight',
    name: 'Cosmic Starlight',
    description: 'Infinite midnight nebula illuminated by brilliant celestial constellations.',
    backgroundStart: Color(0xFFF5F3FF),
    backgroundEnd: Color(0xFFDDD6FE),
    boardBackground: Color(0x80FFFFFF),
    boardBorder: Color(0xFFA78BFA),
    cellEmpty: Color(0x206D28D9),
    cellBorder: Color(0x386D28D9),
    accent: Color(0xFF6D28D9),
    blockPalette: [
      Color(0xFF7C4DFF),
      Color(0xFFD500F9),
      Color(0xFF00E5FF),
      Color(0xFFFF4081),
      Color(0xFFFFD700),
      Color(0xFF3D5AFE),
      Color(0xFF00E676),
    ],
    particlePalette: [
      Color(0xFF7C4DFF),
      Color(0xFFE040FB),
      Color(0xFFEDE7F6),
      Color(0xFFFFFFFF),
    ],
    soundProfile: ThemeSoundProfile.crystal,
    icon: Icons.auto_awesome_motion,
    requiredHighScore: 6000,
    requiredStreak: 5,
    isDefaultUnlocked: false,
  );

  static const List<GameTheme> allThemes = [
    crystalFlow,
    neonGeometry,
    oceanDrift,
    paperAtelier,
    zenStone,
    auroraGarden,
    neonCyberpunk,
    bioluminescence,
    retroArcade,
    cosmicStarlight,
    woodcraft,
    jewelPrism,
    obsidianGlow,
    royalMidas,
    volcanicMagma,
  ];

  static GameTheme getById(String id) {
    return allThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => crystalFlow,
    );
  }
}
