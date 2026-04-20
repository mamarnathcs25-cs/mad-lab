enum MetricType { bloodPressure, sugarLevel, weight }

class HealthMetric {
  HealthMetric({
    required this.id,
    required this.profileId,
    required this.type,
    required this.value,
    required this.recordedAt,
  });

  final String id;
  final String profileId;
  final MetricType type;
  final double value;
  final DateTime recordedAt;

  String get label {
    switch (type) {
      case MetricType.bloodPressure:
        return 'Blood Pressure';
      case MetricType.sugarLevel:
        return 'Sugar Level';
      case MetricType.weight:
        return 'Weight';
    }
  }

  String get unit {
    switch (type) {
      case MetricType.bloodPressure:
        return 'mmHg';
      case MetricType.sugarLevel:
        return 'mg/dL';
      case MetricType.weight:
        return 'kg';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'type': type.name,
      'value': value,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    return HealthMetric(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      type: MetricType.values.byName(json['type'] as String),
      value: (json['value'] as num).toDouble(),
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
