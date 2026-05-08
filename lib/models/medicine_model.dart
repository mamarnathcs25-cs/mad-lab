enum MedicineTimeSlot { morning, afternoon, night }

enum MealTiming { beforeMeal, afterMeal }

MedicineTimeSlot medicineTimeSlotForHour(int hour) {
  if (hour < 12) {
    return MedicineTimeSlot.morning;
  }
  if (hour < 17) {
    return MedicineTimeSlot.afternoon;
  }
  return MedicineTimeSlot.night;
}

class Medicine {
  Medicine({
    required this.id,
    required this.profileId,
    required this.name,
    required this.dosage,
    required this.period,
    required this.totalTablets,
    required this.remainingTablets,
    required this.tabletsPerDose,
    required this.lastRefillSync,
    required this.mealTiming,
    required this.reminderHour,
    required this.reminderMinute,
    this.lastTakenOn,
    this.lastMissedOn,
    this.remindersEnabled = true,
  });

  final String id;
  final String profileId;
  final String name;
  final String dosage;
  final MedicineTimeSlot period;
  final int totalTablets;
  final int remainingTablets;
  final int tabletsPerDose;
  final DateTime lastRefillSync;
  final MealTiming mealTiming;
  final int reminderHour;
  final int reminderMinute;
  final DateTime? lastTakenOn;
  final DateTime? lastMissedOn;
  final bool remindersEnabled;

  bool get isLowStock => remainingTablets <= 3;

  Medicine copyWith({
    String? id,
    String? profileId,
    String? name,
    String? dosage,
    MedicineTimeSlot? period,
    int? totalTablets,
    int? remainingTablets,
    int? tabletsPerDose,
    DateTime? lastRefillSync,
    MealTiming? mealTiming,
    int? reminderHour,
    int? reminderMinute,
    DateTime? lastTakenOn,
    DateTime? lastMissedOn,
    bool? remindersEnabled,
  }) {
    return Medicine(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      period: period ?? this.period,
      totalTablets: totalTablets ?? this.totalTablets,
      remainingTablets: remainingTablets ?? this.remainingTablets,
      tabletsPerDose: tabletsPerDose ?? this.tabletsPerDose,
      lastRefillSync: lastRefillSync ?? this.lastRefillSync,
      mealTiming: mealTiming ?? this.mealTiming,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      lastTakenOn: lastTakenOn ?? this.lastTakenOn,
      lastMissedOn: lastMissedOn ?? this.lastMissedOn,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'name': name,
      'dosage': dosage,
      'period': period.name,
      'totalTablets': totalTablets,
      'remainingTablets': remainingTablets,
      'tabletsPerDose': tabletsPerDose,
      'lastRefillSync': lastRefillSync.toIso8601String(),
      'mealTiming': mealTiming.name,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'lastTakenOn': lastTakenOn?.toIso8601String(),
      'lastMissedOn': lastMissedOn?.toIso8601String(),
      'remindersEnabled': remindersEnabled,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String? ?? '',
      period: MedicineTimeSlot.values.byName(json['period'] as String),
      totalTablets: (json['totalTablets'] as num?)?.toInt() ?? 0,
      remainingTablets: (json['remainingTablets'] as num?)?.toInt() ?? 0,
      tabletsPerDose: (json['tabletsPerDose'] as num?)?.toInt() ?? 1,
      lastRefillSync:
          DateTime.tryParse(json['lastRefillSync'] as String? ?? '') ??
              DateTime.now(),
      mealTiming: MealTiming.values.byName(
        json['mealTiming'] as String? ?? MealTiming.afterMeal.name,
      ),
      reminderHour: (json['reminderHour'] as num?)?.toInt() ??
          _defaultReminderFor(
            MedicineTimeSlot.values.byName(
              json['period'] as String? ?? MedicineTimeSlot.morning.name,
            ),
            MealTiming.values.byName(
              json['mealTiming'] as String? ?? MealTiming.afterMeal.name,
            ),
          ).$1,
      reminderMinute: (json['reminderMinute'] as num?)?.toInt() ??
          _defaultReminderFor(
            MedicineTimeSlot.values.byName(
              json['period'] as String? ?? MedicineTimeSlot.morning.name,
            ),
            MealTiming.values.byName(
              json['mealTiming'] as String? ?? MealTiming.afterMeal.name,
            ),
          ).$2,
      lastTakenOn: DateTime.tryParse(json['lastTakenOn'] as String? ?? ''),
      lastMissedOn: DateTime.tryParse(json['lastMissedOn'] as String? ?? ''),
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
    );
  }

  static (int, int) _defaultReminderFor(
    MedicineTimeSlot slot,
    MealTiming mealTiming,
  ) {
    switch (slot) {
      case MedicineTimeSlot.morning:
        return mealTiming == MealTiming.beforeMeal ? (7, 30) : (8, 30);
      case MedicineTimeSlot.afternoon:
        return mealTiming == MealTiming.beforeMeal ? (12, 30) : (13, 30);
      case MedicineTimeSlot.night:
        return mealTiming == MealTiming.beforeMeal ? (19, 30) : (20, 30);
    }
  }
}
