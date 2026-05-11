import 'package:medapp/models/medicine_model.dart';

class PrescriptionResult {
  PrescriptionResult({
    required this.rawText,
    required this.entries,
  });

  final String rawText;
  final List<PrescriptionEntry> entries;

  List<String> get medicineNames => entries.map((entry) => entry.name).toList();

  List<String> get dosageLines => entries
      .map((entry) => entry.dosageLine)
      .where((line) => line.isNotEmpty)
      .toList();
}

class PrescriptionEntry {
  PrescriptionEntry({
    required this.name,
    required this.dosageLine,
    required this.sourceLine,
    required this.suggestedSlots,
    this.suggestedMealTiming,
  });

  final String name;
  final String dosageLine;
  final String sourceLine;
  final List<MedicineTimeSlot> suggestedSlots;
  final MealTiming? suggestedMealTiming;
}
