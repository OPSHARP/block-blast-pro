// Model representing player daily streak progression (Day 1-7 cycle and lifetime)

class StreakInfo {
  final int streakCount;
  final String? lastClaimDate; // YYYY-MM-DD
  final int freeRerolls;
  final int freeRevives;
  final int freeHammers;
  final int freeTnts;
  final int freeRotates;
  final int freeUndos;
  final int freeMagnets;
  final int coins;

  const StreakInfo({
    this.streakCount = 0,
    this.lastClaimDate,
    this.freeRerolls = 3,
    this.freeRevives = 1,
    this.freeHammers = 2,
    this.freeTnts = 1,
    this.freeRotates = 3,
    this.freeUndos = 2,
    this.freeMagnets = 1,
    this.coins = 100,
  });

  int get currentCycleDay {
    if (streakCount == 0) return 1;
    final day = (streakCount % 7);
    return day == 0 ? 7 : day;
  }

  bool isClaimableForDate([DateTime? now]) {
    if (lastClaimDate == null) return true;
    final effective = now ?? DateTime.now();
    final todayStr =
        '${effective.year}-${effective.month.toString().padLeft(2, '0')}-${effective.day.toString().padLeft(2, '0')}';
    return lastClaimDate != todayStr;
  }

  bool get isClaimableToday => isClaimableForDate();

  StreakInfo copyWith({
    int? streakCount,
    String? lastClaimDate,
    int? freeRerolls,
    int? freeRevives,
    int? freeHammers,
    int? freeTnts,
    int? freeRotates,
    int? freeUndos,
    int? freeMagnets,
    int? coins,
  }) {
    return StreakInfo(
      streakCount: streakCount ?? this.streakCount,
      lastClaimDate: lastClaimDate ?? this.lastClaimDate,
      freeRerolls: freeRerolls ?? this.freeRerolls,
      freeRevives: freeRevives ?? this.freeRevives,
      freeHammers: freeHammers ?? this.freeHammers,
      freeTnts: freeTnts ?? this.freeTnts,
      freeRotates: freeRotates ?? this.freeRotates,
      freeUndos: freeUndos ?? this.freeUndos,
      freeMagnets: freeMagnets ?? this.freeMagnets,
      coins: coins ?? this.coins,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'streakCount': streakCount,
      'lastClaimDate': lastClaimDate,
      'freeRerolls': freeRerolls,
      'freeRevives': freeRevives,
      'freeHammers': freeHammers,
      'freeTnts': freeTnts,
      'freeRotates': freeRotates,
      'freeUndos': freeUndos,
      'freeMagnets': freeMagnets,
      'coins': coins,
    };
  }

  factory StreakInfo.fromMap(Map<String, dynamic> map) {
    return StreakInfo(
      streakCount: (map['streakCount'] as num?)?.toInt() ?? 0,
      lastClaimDate: map['lastClaimDate'] as String?,
      freeRerolls: (map['freeRerolls'] as num?)?.toInt() ?? 3,
      freeRevives: (map['freeRevives'] as num?)?.toInt() ?? 1,
      freeHammers: (map['freeHammers'] as num?)?.toInt() ?? 2,
      freeTnts: (map['freeTnts'] as num?)?.toInt() ?? 1,
      freeRotates: (map['freeRotates'] as num?)?.toInt() ?? 3,
      freeUndos: (map['freeUndos'] as num?)?.toInt() ?? 2,
      freeMagnets: (map['freeMagnets'] as num?)?.toInt() ?? 1,
      coins: (map['coins'] as num?)?.toInt() ?? 100,
    );
  }
}
