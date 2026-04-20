class PrescriptionResult {
  PrescriptionResult({
    required this.rawText,
    required this.medicineNames,
    required this.dosageLines,
  });

  final String rawText;
  final List<String> medicineNames;
  final List<String> dosageLines;
}
