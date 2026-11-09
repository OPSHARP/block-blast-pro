// Player Skill Profile according to PRD Sections 27 & 74

class PlayerSkillProfile {
  final double spatialPlanning; // 0 - 100
  final double efficiency;      // 0 - 100
  final double comboSkill;      // 0 - 100
  final double riskManagement;  // 0 - 100
  final double physicsMastery;  // 0 - 100
  final double gridAwareness;   // 0 - 100
  final int overallSkillRating; // 0 - 1000

  const PlayerSkillProfile({
    this.spatialPlanning = 50.0,
    this.efficiency = 50.0,
    this.comboSkill = 50.0,
    this.riskManagement = 50.0,
    this.physicsMastery = 50.0,
    this.gridAwareness = 50.0,
    this.overallSkillRating = 500,
  });

  PlayerSkillProfile copyWith({
    double? spatialPlanning,
    double? efficiency,
    double? comboSkill,
    double? riskManagement,
    double? physicsMastery,
    double? gridAwareness,
    int? overallSkillRating,
  }) {
    return PlayerSkillProfile(
      spatialPlanning: spatialPlanning ?? this.spatialPlanning,
      efficiency: efficiency ?? this.efficiency,
      comboSkill: comboSkill ?? this.comboSkill,
      riskManagement: riskManagement ?? this.riskManagement,
      physicsMastery: physicsMastery ?? this.physicsMastery,
      gridAwareness: gridAwareness ?? this.gridAwareness,
      overallSkillRating: overallSkillRating ?? this.overallSkillRating,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'spatialPlanning': spatialPlanning,
      'efficiency': efficiency,
      'comboSkill': comboSkill,
      'riskManagement': riskManagement,
      'physicsMastery': physicsMastery,
      'gridAwareness': gridAwareness,
      'overallSkillRating': overallSkillRating,
    };
  }

  factory PlayerSkillProfile.fromMap(Map<String, dynamic> map) {
    return PlayerSkillProfile(
      spatialPlanning: (map['spatialPlanning'] as num?)?.toDouble() ?? 50.0,
      efficiency: (map['efficiency'] as num?)?.toDouble() ?? 50.0,
      comboSkill: (map['comboSkill'] as num?)?.toDouble() ?? 50.0,
      riskManagement: (map['riskManagement'] as num?)?.toDouble() ?? 50.0,
      physicsMastery: (map['physicsMastery'] as num?)?.toDouble() ?? 50.0,
      gridAwareness: (map['gridAwareness'] as num?)?.toDouble() ?? 50.0,
      overallSkillRating: (map['overallSkillRating'] as int?) ?? 500,
    );
  }
}
