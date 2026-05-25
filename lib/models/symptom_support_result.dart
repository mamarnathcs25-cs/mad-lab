class SymptomSupportResult {
  SymptomSupportResult({
    required this.possibleIssue,
    required this.medicineSuggestions,
    required this.careAdvice,
    required this.warningAdvice,
    required this.disclaimer,
    required this.currentMedicineWarnings,
  });

  final String possibleIssue;
  final List<SymptomMedicineSuggestion> medicineSuggestions;
  final List<String> careAdvice;
  final List<String> warningAdvice;
  final String disclaimer;
  final List<String> currentMedicineWarnings;
}

class SymptomMedicineSuggestion {
  SymptomMedicineSuggestion({
    required this.commonMedicine,
    required this.howItHelps,
    required this.importantWarning,
  });

  final String commonMedicine;
  final String howItHelps;
  final String importantWarning;
}
