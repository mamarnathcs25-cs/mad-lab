import 'package:flutter_test/flutter_test.dart';
import 'package:medapp/models/health_metric.dart';
import 'package:medapp/services/prescription_parser.dart';

void main() {
  test('prescription parser extracts medicine and dosage text', () {
    final parser = PrescriptionParser();

    final result = parser.parse('Tab Metformin 500 mg\nCap Vitamin C 250 mg');

    expect(result.rawText, contains('Metformin'));
    expect(result.dosageLines, isNotEmpty);
  });

  test('metric labels stay stable', () {
    final metric = HealthMetric(
      id: '1',
      profileId: 'self',
      type: MetricType.weight,
      value: 72,
      recordedAt: DateTime(2026, 4, 19),
    );

    expect(metric.label, 'Weight');
    expect(metric.unit, 'kg');
  });
}
