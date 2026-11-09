// Local Achievement Model according to PRD Sections 50-52

enum AchievementCategory {
  scoring,
  combos,
  physics,
  grid,
  daily,
  exploration,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final int targetValue;
  final int currentProgress;
  final bool isUnlocked;
  final String reward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetValue,
    this.currentProgress = 0,
    this.isUnlocked = false,
    required this.reward,
  });

  double get progressPercentage =>
      targetValue == 0 ? 1.0 : (currentProgress / targetValue).clamp(0.0, 1.0);

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    AchievementCategory? category,
    int? targetValue,
    int? currentProgress,
    bool? isUnlocked,
    String? reward,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      reward: reward ?? this.reward,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.index,
      'targetValue': targetValue,
      'currentProgress': currentProgress,
      'isUnlocked': isUnlocked,
      'reward': reward,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: AchievementCategory.values[
          (map['category'] as int?)?.clamp(0, AchievementCategory.values.length - 1) ?? 0],
      targetValue: map['targetValue'] as int,
      currentProgress: map['currentProgress'] as int? ?? 0,
      isUnlocked: map['isUnlocked'] as bool? ?? false,
      reward: map['reward'] as String,
    );
  }
}
