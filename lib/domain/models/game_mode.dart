// Game Mode definitions according to PRD Sections 75-77

enum GameMode {
  classic(
    displayName: 'Classic Mode',
    description: 'The pure block-placement puzzle experience. Build combos and survive.',
    iconName: 'grid_view',
    allowGridShift: true,
    gridShiftFrequencyMultiplier: 1.0,
    hasFailState: true,
  ),
  dynamicGrid(
    displayName: 'Dynamic Grid',
    description: 'The grid shifts dynamically in response to combos and board density.',
    iconName: 'sync_alt',
    allowGridShift: true,
    gridShiftFrequencyMultiplier: 2.0,
    hasFailState: true,
  ),
  heavyPhysics(
    displayName: 'Heavy Physics',
    description: 'Experience weight classes with impact shockwaves and board pressure.',
    iconName: 'fitness_center',
    allowGridShift: true,
    gridShiftFrequencyMultiplier: 1.2,
    hasFailState: true,
  ),
  zen(
    displayName: 'Zen Mode',
    description: 'No game over, gentle ASMR audio, peaceful atmospheric visuals.',
    iconName: 'spa',
    allowGridShift: false,
    gridShiftFrequencyMultiplier: 0.0,
    hasFailState: false,
  ),
  dailyChallenge(
    displayName: 'Daily Challenge',
    description: 'A unique deterministic puzzle scenario generated each calendar day.',
    iconName: 'calendar_today',
    allowGridShift: true,
    gridShiftFrequencyMultiplier: 1.5,
    hasFailState: true,
  ),
  blitz(
    displayName: 'Blitz Mode',
    description: 'Race against a 60-second timer! Every line clear adds bonus time.',
    iconName: 'timer',
    allowGridShift: false,
    gridShiftFrequencyMultiplier: 0.0,
    hasFailState: true,
  ),
  custom(
    displayName: 'Custom Mode',
    description: 'Player-tuned board rules, custom physics weights, and grid settings.',
    iconName: 'tune',
    allowGridShift: true,
    gridShiftFrequencyMultiplier: 1.0,
    hasFailState: true,
  ),
  adventure(
    displayName: 'Journey Mode',
    description: 'Stage-based campaign! Conquer unique board puzzles, achieve objectives, and earn 3-star ratings.',
    iconName: 'explore',
    allowGridShift: true,
    gridShiftFrequencyMultiplier: 1.0,
    hasFailState: true,
  ),
  lava(
    displayName: 'Rising Lava',
    description: 'Survival mode! Lava rises from the bottom every 6 moves unless you clear lines to push it back down.',
    iconName: 'whatshot',
    allowGridShift: false,
    gridShiftFrequencyMultiplier: 0.0,
    hasFailState: true,
  );

  final String displayName;
  final String description;
  final String iconName;
  final bool allowGridShift;
  final double gridShiftFrequencyMultiplier;
  final bool hasFailState;

  const GameMode({
    required this.displayName,
    required this.description,
    required this.iconName,
    required this.allowGridShift,
    required this.gridShiftFrequencyMultiplier,
    required this.hasFailState,
  });
}
