import 'package:medapp/models/medicine_model.dart';
import 'package:medapp/models/prescription_result.dart';

class PrescriptionParser {
  static final RegExp _rowPrefixPattern = RegExp(r'^\s*\d+[\).]?\s*');
  static final RegExp _medicineFormPattern = RegExp(
    r'^(?:tab|tablet|cap|capsule|syrup|drops|puff)\.?\s*',
    caseSensitive: false,
  );
  static final RegExp _frequencyPattern = RegExp(r'\b[0-2]-[0-2]-[0-2]\b');
  static final RegExp _timePattern = RegExp(
    r'\b\d{1,2}[:.]\d{2}\s?(?:am|pm)\b|\b\d{1,2}\s?(?:am|pm)\b',
    caseSensitive: false,
  );
  static final RegExp _ingredientLinePattern = RegExp(
    r'^(?:[A-Z0-9/+\-]+\s+){1,6}(?:MG|ML|MCG|G)\b',
  );
  static final RegExp _medicineStrengthSuffixPattern = RegExp(
    r'\b\d+(?:\.\d+)?\s?(?:mg|ml|mcg|g)\b',
    caseSensitive: false,
  );
  static final Set<String> _invalidMedicineNames = {
    'morning',
    'afternoon',
    'night',
    'evening',
    'noon',
    'after food',
    'before food',
    'after meal',
    'before meal',
    'tot',
    'days',
    'day',
    'pm',
    'am',
    'sr',
  };

  static final List<String> _ignoredLineStarts = [
    'rx',
    'diagnosis',
    'advice',
    'doctor',
    'dr.',
    'name',
    'patient',
    'age',
    'date',
    'signature',
    'address',
    'phone',
    'mobile',
    'email',
    'website',
    'hospital',
    'clinic',
    'road',
    'street',
    'area',
    'near',
    'follow up',
    'chief complaints',
    'clinical findings',
    'medicine name',
    'dosage',
    'duration',
    'weight',
    'height',
    'bp:',
    'id:',
    'reg. no',
  ];

  static final List<String> _ignoredLineContains = [
    'hospital',
    'clinic',
    'address',
    'road',
    'street',
    'lane',
    'nagar',
    'colony',
    'sector',
    'floor',
    'building',
    'opposite',
    'phone',
    'mobile',
    'contact',
    'email',
    'www.',
    '.com',
    'timing',
    'closed:',
    'patient',
    'b.m.i',
    'mmhg',
    'sample diagnosis',
    'test findings',
  ];

  PrescriptionResult parse(String rawText) {
    final entries = <PrescriptionEntry>[];
    final seenNames = <String>{};
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);

    for (final line in lines) {
      final normalizedLine = line.trim();
      final lowerLine = normalizedLine.toLowerCase();

      if (_ignoredLineStarts.any(lowerLine.startsWith) ||
          _ignoredLineContains.any(lowerLine.contains)) {
        continue;
      }
      if (lowerLine.startsWith('tot') || lowerLine.contains('(tot:')) {
        continue;
      }
      if (_ingredientLinePattern.hasMatch(normalizedLine) &&
          !_rowPrefixPattern.hasMatch(normalizedLine)) {
        continue;
      }

      final parsed = _parseMedicineRow(normalizedLine);
      if (parsed == null) {
        continue;
      }

      final key = parsed.name.toLowerCase();
      if (seenNames.contains(key)) {
        continue;
      }
      seenNames.add(key);
      entries.add(parsed);
    }

    return PrescriptionResult(rawText: rawText, entries: entries.take(8).toList());
  }

  PrescriptionEntry? _parseMedicineRow(String line) {
    final isNumberedRow = _rowPrefixPattern.hasMatch(line);
    final startsLikeMedicine = _medicineFormPattern.hasMatch(line);
    if (!isNumberedRow && !startsLikeMedicine) {
      return null;
    }

    if (_timePattern.hasMatch(line) && !startsLikeMedicine) {
      return null;
    }

    final withoutPrefix = line.replaceFirst(_rowPrefixPattern, '').trim();
    final columns = withoutPrefix
        .split(RegExp(r'\s{2,}'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    final firstColumn = columns.isEmpty ? withoutPrefix : columns.first;
    final name = _extractMedicineName(firstColumn);
    if (name == null) {
      return null;
    }

    if (_looksLikeScheduleOnly(name)) {
      return null;
    }

    final scheduleSource = columns.length >= 2 ? columns[1] : withoutPrefix;
    final suggestedSlots = _extractSlots(scheduleSource);
    final suggestedMealTiming = _extractMealTiming(withoutPrefix);

    final dosageLine = columns.length >= 2
        ? columns.skip(1).join(' | ')
        : withoutPrefix;

    return PrescriptionEntry(
      name: name,
      dosageLine: dosageLine,
      sourceLine: line,
      suggestedSlots: suggestedSlots,
      suggestedMealTiming: suggestedMealTiming,
    );
  }

  String? _extractMedicineName(String source) {
    var candidate = source.replaceFirst(_medicineFormPattern, '').trim();
    candidate = candidate.replaceAll(RegExp(r'\s*\(.*?\)\s*'), ' ').trim();
    candidate = candidate.replaceAll(RegExp(r'\s{2,}'), ' ');
    candidate = candidate.replaceAll(
      RegExp(r'^[^A-Za-z]+|[^A-Za-z0-9/+.-]+$'),
      '',
    );
    if (candidate.isEmpty) {
      return null;
    }
    if (candidate.toLowerCase().startsWith('tot')) {
      return null;
    }
    if (_ingredientLinePattern.hasMatch(candidate)) {
      return null;
    }
    return candidate;
  }

  bool _looksLikeScheduleOnly(String candidate) {
    final lower = candidate.toLowerCase().trim();
    if (_invalidMedicineNames.contains(lower)) {
      return true;
    }
    if (_timePattern.hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'^(?:morning|night|afternoon|evening)(?:,\s*\d+\s*(?:morning|night|afternoon|evening))*$')
        .hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'^\d+\s*(?:morning|night|afternoon|evening)$').hasMatch(lower)) {
      return true;
    }
    if (lower == 'sr') {
      return true;
    }
    if (RegExp(r'^[0-9/+.-]+$').hasMatch(lower)) {
      return true;
    }
    if (_medicineStrengthSuffixPattern.hasMatch(lower) &&
        !RegExp(r'[a-z]{3,}').hasMatch(lower.replaceAll(_medicineStrengthSuffixPattern, ''))) {
      return true;
    }
    return false;
  }

  List<MedicineTimeSlot> _extractSlots(String source) {
    final lower = source.toLowerCase();
    final slots = <MedicineTimeSlot>[];

    void add(MedicineTimeSlot slot) {
      if (!slots.contains(slot)) {
        slots.add(slot);
      }
    }

    if (lower.contains('morning')) {
      add(MedicineTimeSlot.morning);
    }
    if (lower.contains('afternoon') || lower.contains('noon')) {
      add(MedicineTimeSlot.afternoon);
    }
    if (lower.contains('night') || lower.contains('evening')) {
      add(MedicineTimeSlot.night);
    }

    final frequencyMatch = _frequencyPattern.firstMatch(lower);
    if (frequencyMatch != null) {
      final parts = frequencyMatch.group(0)!.split('-').map(int.parse).toList();
      if (parts[0] > 0) {
        add(MedicineTimeSlot.morning);
      }
      if (parts[1] > 0) {
        add(MedicineTimeSlot.afternoon);
      }
      if (parts[2] > 0) {
        add(MedicineTimeSlot.night);
      }
    }

    if (slots.isEmpty) {
      if (RegExp(r'\bbd\b').hasMatch(lower)) {
        add(MedicineTimeSlot.morning);
        add(MedicineTimeSlot.night);
      } else if (RegExp(r'\btds\b|\btid\b').hasMatch(lower)) {
        add(MedicineTimeSlot.morning);
        add(MedicineTimeSlot.afternoon);
        add(MedicineTimeSlot.night);
      } else if (RegExp(r'\bod\b').hasMatch(lower)) {
        add(MedicineTimeSlot.morning);
      }
    }

    return slots;
  }

  MealTiming? _extractMealTiming(String source) {
    final lower = source.toLowerCase();
    if (lower.contains('before food') || lower.contains('before meal')) {
      return MealTiming.beforeMeal;
    }
    if (lower.contains('after food') || lower.contains('after meal')) {
      return MealTiming.afterMeal;
    }
    return null;
  }
}
