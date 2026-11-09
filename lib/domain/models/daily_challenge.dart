// Daily Challenge Model according to PRD Sections 44-49

enum ChallengeObjectiveType {
  scoreTarget,
  comboTarget,
  survivalTurns,
  multiClearCount,
  gridShiftSurvive,
}

class DailyChallenge {
  final String dateString; // YYYY-MM-DD
  final int seed;
  final ChallengeObjectiveType objectiveType;
  final String title;
  final String description;
  final int targetValue;
  final int currentProgress;
  final bool isCompleted;
  final int bestScore;
  final String rewardName;

  const DailyChallenge({
    required this.dateString,
    required this.seed,
    required this.objectiveType,
    required this.title,
    required this.description,
    required this.targetValue,
    this.currentProgress = 0,
    this.isCompleted = false,
    this.bestScore = 0,
    required this.rewardName,
  });

  DailyChallenge copyWith({
    String? dateString,
    int? seed,
    ChallengeObjectiveType? objectiveType,
    String? title,
    String? description,
    int? targetValue,
    int? currentProgress,
    bool? isCompleted,
    int? bestScore,
    String? rewardName,
  }) {
    return DailyChallenge(
      dateString: dateString ?? this.dateString,
      seed: seed ?? this.seed,
      objectiveType: objectiveType ?? this.objectiveType,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      bestScore: bestScore ?? this.bestScore,
      rewardName: rewardName ?? this.rewardName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateString': dateString,
      'seed': seed,
      'objectiveType': objectiveType.index,
      'title': title,
      'description': description,
      'targetValue': targetValue,
      'currentProgress': currentProgress,
      'isCompleted': isCompleted,
      'bestScore': bestScore,
      'rewardName': rewardName,
    };
  }

  factory DailyChallenge.fromMap(Map<String, dynamic> map) {
    return DailyChallenge(
      dateString: map['dateString'] as String,
      seed: map['seed'] as int,
      objectiveType: ChallengeObjectiveType.values[
          (map['objectiveType'] as int?)?.clamp(0, ChallengeObjectiveType.values.length - 1) ?? 0],
      title: map['title'] as String,
      description: map['description'] as String,
      targetValue: map['targetValue'] as int,
      currentProgress: map['currentProgress'] as int? ?? 0,
      isCompleted: map['isCompleted'] as bool? ?? false,
      bestScore: map['bestScore'] as int? ?? 0,
      rewardName: map['rewardName'] as String,
    );
  }
}
