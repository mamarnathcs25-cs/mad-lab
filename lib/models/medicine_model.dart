enum MedicineTimeSlot { morning, afternoon, night }

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
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
    );
  }
}
