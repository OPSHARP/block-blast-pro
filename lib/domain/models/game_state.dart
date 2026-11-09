// Authoritative Game Session State for Block Blast Pro

import 'board_state.dart';
import 'block_model.dart';
import 'game_mode.dart';
import 'player_skill_profile.dart';

class GameState {
  final BoardState board;
  final List<BlockModel?> trayPieces; // 3 pieces slot
  final int score;
  final int highScore;
  final int comboCount;
  final double comboMultiplier;
  final int highestCombo;
  final int level;
  final int xp;
  final GameMode gameMode;
  final bool isGameOver;
  final int movesCount;
  final int totalLinesCleared;
  final PlayerSkillProfile skillProfile;
  final String themeId;
  final String? pendingShiftWarning;
  final bool isShifting;
  final BlockModel? heldPiece;
  final bool isHammerModeActive;
  final bool isTntModeActive;
  final bool isColorMagnetModeActive;
  final double blitzTimeRemaining;

  const GameState({
    required this.board,
    required this.trayPieces,
    this.score = 0,
    this.highScore = 0,
    this.comboCount = 0,
    this.comboMultiplier = 1.0,
    this.highestCombo = 0,
    this.level = 1,
    this.xp = 0,
    this.gameMode = GameMode.classic,
    this.isGameOver = false,
    this.movesCount = 0,
    this.totalLinesCleared = 0,
    this.skillProfile = const PlayerSkillProfile(),
    this.themeId = 'crystal_flow',
    this.pendingShiftWarning,
    this.isShifting = false,
    this.heldPiece,
    this.isHammerModeActive = false,
    this.isTntModeActive = false,
    this.isColorMagnetModeActive = false,
    this.blitzTimeRemaining = 60.0,
  });

  bool get isTrayEmpty => trayPieces.every((p) => p == null);
  bool get isFeverMode => comboCount >= 5;

  GameState copyWith({
    BoardState? board,
    List<BlockModel?>? trayPieces,
    int? score,
    int? highScore,
    int? comboCount,
    double? comboMultiplier,
    int? highestCombo,
    int? level,
    int? xp,
    GameMode? gameMode,
    bool? isGameOver,
    int? movesCount,
    int? totalLinesCleared,
    PlayerSkillProfile? skillProfile,
    String? themeId,
    String? Function()? pendingShiftWarning,
    bool? isShifting,
    BlockModel? Function()? heldPiece,
    bool? isHammerModeActive,
    bool? isTntModeActive,
    bool? isColorMagnetModeActive,
    double? blitzTimeRemaining,
  }) {
    return GameState(
      board: board ?? this.board,
      trayPieces: trayPieces ?? this.trayPieces,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      comboCount: comboCount ?? this.comboCount,
      comboMultiplier: comboMultiplier ?? this.comboMultiplier,
      highestCombo: highestCombo ?? this.highestCombo,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      gameMode: gameMode ?? this.gameMode,
      isGameOver: isGameOver ?? this.isGameOver,
      movesCount: movesCount ?? this.movesCount,
      totalLinesCleared: totalLinesCleared ?? this.totalLinesCleared,
      skillProfile: skillProfile ?? this.skillProfile,
      themeId: themeId ?? this.themeId,
      pendingShiftWarning: pendingShiftWarning != null
          ? pendingShiftWarning()
          : this.pendingShiftWarning,
      isShifting: isShifting ?? this.isShifting,
      heldPiece: heldPiece != null ? heldPiece() : this.heldPiece,
      isHammerModeActive: isHammerModeActive ?? this.isHammerModeActive,
      isTntModeActive: isTntModeActive ?? this.isTntModeActive,
      isColorMagnetModeActive: isColorMagnetModeActive ?? this.isColorMagnetModeActive,
      blitzTimeRemaining: blitzTimeRemaining ?? this.blitzTimeRemaining,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'board': board.toMap(),
      'trayPieces': trayPieces.map((p) => p?.toMap()).toList(),
      'score': score,
      'highScore': highScore,
      'comboCount': comboCount,
      'comboMultiplier': comboMultiplier,
      'highestCombo': highestCombo,
      'level': level,
      'xp': xp,
      'gameMode': gameMode.index,
      'isGameOver': isGameOver,
      'movesCount': movesCount,
      'totalLinesCleared': totalLinesCleared,
      'skillProfile': skillProfile.toMap(),
      'themeId': themeId,
      'heldPiece': heldPiece?.toMap(),
    };
  }

  factory GameState.fromMap(Map<String, dynamic> map) {
    final boardMap = map['board'] as Map<String, dynamic>? ?? {};
    final rawTray = map['trayPieces'] as List<dynamic>? ?? [];
    final parsedTray = rawTray.map((item) {
      if (item == null) return null;
      return BlockModel.fromMap(item as Map<String, dynamic>);
    }).toList();

    final safeTray = parsedTray.length == 3
        ? parsedTray
        : (parsedTray.isNotEmpty && parsedTray.length < 3
            ? [...parsedTray, ...List<BlockModel?>.filled(3 - parsedTray.length, null)]
            : List<BlockModel?>.filled(3, null));

    BlockModel? parsedHeld;
    if (map['heldPiece'] != null) {
      parsedHeld = BlockModel.fromMap(map['heldPiece'] as Map<String, dynamic>);
    }

    return GameState(
      board: BoardState.fromMap(boardMap),
      trayPieces: safeTray,
      score: (map['score'] as int?) ?? 0,
      highScore: (map['highScore'] as int?) ?? 0,
      comboCount: (map['comboCount'] as int?) ?? 0,
      comboMultiplier: (map['comboMultiplier'] as num?)?.toDouble() ?? 1.0,
      highestCombo: (map['highestCombo'] as int?) ?? 0,
      level: (map['level'] as int?) ?? 1,
      xp: (map['xp'] as int?) ?? 0,
      gameMode: GameMode.values[
          (map['gameMode'] as int?)?.clamp(0, GameMode.values.length - 1) ?? 0],
      isGameOver: (map['isGameOver'] as bool?) ?? false,
      movesCount: (map['movesCount'] as int?) ?? 0,
      totalLinesCleared: (map['totalLinesCleared'] as int?) ?? 0,
      skillProfile: PlayerSkillProfile.fromMap(
          map['skillProfile'] as Map<String, dynamic>? ?? {}),
      themeId: (map['themeId'] as String?) ?? 'crystal_flow',
      heldPiece: parsedHeld,
    );
  }
}
