import 'package:medapp/models/prescription_result.dart';

class PrescriptionParser {
  static final RegExp _medicinePattern = RegExp(
    r'\b([A-Z][a-zA-Z]+(?:\s[A-Z]?[a-zA-Z]+){0,2})\b',
  );

  static final RegExp _dosagePattern = RegExp(
    r'(\d+\s?(mg|ml|mcg|g|tablet|tab|capsule|cap|drops|puff)s?)',
    caseSensitive: false,
  );

  PrescriptionResult parse(String rawText) {
    final medicineNames = <String>{};
    final dosageLines = <String>{};
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);

    for (final line in lines) {
      if (_dosagePattern.hasMatch(line)) {
        dosageLines.add(line);
      }

      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('tab') ||
          lowerLine.contains('cap') ||
          lowerLine.contains('syrup') ||
          lowerLine.contains('mg') ||
          lowerLine.contains('ml')) {
        final match = _medicinePattern.firstMatch(line);
        if (match != null) {
          medicineNames.add(match.group(1)!.trim());
        }
      }
    }

    return PrescriptionResult(
      rawText: rawText,
      medicineNames: medicineNames.take(5).toList(),
      dosageLines: dosageLines.take(5).toList(),
    );
  }
}
