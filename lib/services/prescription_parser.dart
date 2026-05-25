import 'package:medapp/models/medicine_model.dart';
import 'package:medapp/models/prescription_result.dart';

class PrescriptionParser {
  static final RegExp _rowPrefixPattern = RegExp(r'^\s*\d+[\).]?\s*');
  static final RegExp _medicineFormPattern = RegExp(
    r'^(?:tab|tablet|cap|capsule|syrup|drops|puff)\.?\s*',
    caseSensitive: false,
  );
  static final RegExp _sectionDividerPattern = RegExp(r'^[-_=]{3,}$');
  static final RegExp _frequencyPattern = RegExp(r'\b[0-2]-[0-2]-[0-2]\b');
  static final RegExp _timePattern = RegExp(
    r'\b\d{1,2}[:.]\d{2}\s?(?:am|pm)\b|\b\d{1,2}\s?(?:am|pm)\b',
    caseSensitive: false,
  );
  static final RegExp _strengthPattern = RegExp(
    r'\b\d+(?:\.\d+)?\s?(?:mg|ml|mcg|g)\b',
    caseSensitive: false,
  );
  static final RegExp _formWordPattern = RegExp(
    r'\b(?:tab|tablet|tablets|cap|capsule|capsules|syrup|drops|cream|ointment|gel|injection|suspension|solution|spray)\b',
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

  static final List<String> _sectionStartMarkers = [
    'medicine name',
    'medicines',
    'rx',
    'endorsements',
  ];

  static final List<String> _sectionEndMarkers = [
    'advice',
    'follow up',
    'follow-up',
    'substitute with equivalent',
    'signature',
    'for dispenser',
    'prescriber',
  ];

  PrescriptionResult parse(String rawText) {
    final entries = <PrescriptionEntry>[];
    final seenNames = <String>{};
    final allLines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final lines = _extractMedicineSection(allLines);

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final normalizedLine = line.trim();
      final lowerLine = normalizedLine.toLowerCase();

      if (_ignoredLineStarts.any(lowerLine.startsWith) ||
          _ignoredLineContains.any(lowerLine.contains)) {
        continue;
      }
      if (lowerLine.startsWith('tot') || lowerLine.contains('(tot:')) {
        continue;
      }
      if (_sectionDividerPattern.hasMatch(normalizedLine)) {
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

      final supportingLines = <String>[];
      var lookAhead = index + 1;
      while (lookAhead < lines.length) {
        final nextLine = lines[lookAhead].trim();
        final nextLower = nextLine.toLowerCase();
        if (nextLine.isEmpty ||
            _sectionEndMarkers.any(nextLower.contains) ||
            _looksLikePotentialMedicineStart(nextLine)) {
          break;
        }
        if (_isSupportingInstructionLine(nextLine)) {
          supportingLines.add(nextLine);
        }
        lookAhead++;
      }

      final combinedDosageLine = _combineDosageLine(
        parsed.dosageLine,
        supportingLines,
      );
      final combinedSourceLine = [
        parsed.sourceLine,
        ...supportingLines,
      ].join(' | ');
      final combinedScheduleSource = [
        parsed.dosageLine,
        ...supportingLines,
      ].join(' ');
      final finalSlots = _extractSlots(combinedScheduleSource);
      final finalMealTiming =
          _extractMealTiming([parsed.sourceLine, ...supportingLines].join(' ')) ??
              parsed.suggestedMealTiming;

      final key = parsed.name.toLowerCase();
      if (seenNames.contains(key)) {
        index = lookAhead - 1;
        continue;
      }
      seenNames.add(key);
      entries.add(
        PrescriptionEntry(
          name: parsed.name,
          dosageLine: combinedDosageLine,
          sourceLine: combinedSourceLine,
          suggestedSlots: finalSlots.isEmpty ? parsed.suggestedSlots : finalSlots,
          suggestedMealTiming: finalMealTiming,
        ),
      );
      index = lookAhead - 1;
    }

    return PrescriptionResult(rawText: rawText, entries: entries.take(8).toList());
  }

  List<String> _extractMedicineSection(List<String> lines) {
    var startIndex = -1;
    var fallbackStartIndex = -1;

    for (var index = 0; index < lines.length; index++) {
      final lowerLine = lines[index].toLowerCase();
      if (lowerLine == 'r' || lowerLine == 'rx') {
        fallbackStartIndex = index + 1;
      }
      if (_sectionStartMarkers.any(lowerLine.contains)) {
        startIndex = index + 1;
        break;
      }
    }

    if (startIndex == -1) {
      startIndex = fallbackStartIndex;
    }

    if (startIndex == -1) {
      return lines;
    }

    final section = <String>[];
    for (var index = startIndex; index < lines.length; index++) {
      final line = lines[index].trim();
      final lowerLine = line.toLowerCase();
      if (_sectionEndMarkers.any(lowerLine.contains)) {
        break;
      }
      if (lowerLine == 'dosage' ||
          lowerLine == 'duration' ||
          lowerLine == 'medicine name' ||
          _sectionDividerPattern.hasMatch(line)) {
        continue;
      }
      section.add(line);
    }

    return section.isEmpty ? lines : section;
  }

  PrescriptionEntry? _parseMedicineRow(String line) {
    if (!_looksLikePotentialMedicineStart(line)) {
      return null;
    }

    final isNumberedRow = _rowPrefixPattern.hasMatch(line);
    final startsLikeMedicine = _medicineFormPattern.hasMatch(line);
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
    candidate = candidate.replaceFirst(
      RegExp(
        r'\b\d+\s*(?:morning|afternoon|night|evening|noon)\b.*$',
        caseSensitive: false,
      ),
      '',
    ).trim();
    candidate = candidate.replaceFirst(
      RegExp(
        r'\b(?:od|bd|tds|tid|hs|sos)\b.*$',
        caseSensitive: false,
      ),
      '',
    ).trim();
    candidate = candidate.replaceFirst(
      RegExp(r'\b\d+\s*days?\b.*$', caseSensitive: false),
      '',
    ).trim();
    candidate = candidate.replaceFirst(
      RegExp(
        r'\b(?:before|after)\s+(?:food|meal)\b.*$',
        caseSensitive: false,
      ),
      '',
    ).trim();
    candidate = candidate.replaceAll(RegExp(r'\s*\(.*?\)\s*'), ' ').trim();
    candidate = candidate.replaceAll(RegExp(r'\s{2,}'), ' ');
    candidate = candidate.replaceAll(
      RegExp(r'^[^A-Za-z]+|[^A-Za-z0-9/+.-]+$'),
      '',
    );
    if (candidate.isEmpty) {
      return null;
    }
    if (!_looksLikeMedicineName(candidate)) {
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

  bool _looksLikePotentialMedicineStart(String line) {
    final normalized = line.trim();
    final lower = normalized.toLowerCase();
    if (normalized.isEmpty ||
        _ignoredLineStarts.any(lower.startsWith) ||
        _ignoredLineContains.any(lower.contains) ||
        _sectionEndMarkers.any(lower.contains)) {
      return false;
    }
    if (lower.startsWith('take ') ||
        lower.startsWith('supply') ||
        lower.contains('no more items on this prescription')) {
      return false;
    }

    final isNumberedRow = _rowPrefixPattern.hasMatch(normalized);
    final startsLikeMedicine = _medicineFormPattern.hasMatch(normalized);
    final looksLikeStandaloneMedicine = _looksLikeStandaloneMedicineLine(normalized);

    if (!isNumberedRow && !startsLikeMedicine && !looksLikeStandaloneMedicine) {
      return false;
    }

    final withoutPrefix = normalized.replaceFirst(_rowPrefixPattern, '').trim();
    final firstColumn = withoutPrefix
        .split(RegExp(r'\s{2,}'))
        .map((part) => part.trim())
        .firstWhere((part) => part.isNotEmpty, orElse: () => withoutPrefix);
    final name = _extractMedicineName(firstColumn);
    if (name == null || _looksLikeScheduleOnly(name)) {
      return false;
    }

    if (isNumberedRow && !_hasMedicineClue(normalized) && !startsLikeMedicine) {
      return false;
    }

    return true;
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

  bool _looksLikeStandaloneMedicineLine(String line) {
    if (!_hasMedicineClue(line)) {
      return false;
    }
    if (!RegExp(r'[A-Za-z]{4,}').hasMatch(line)) {
      return false;
    }
    return true;
  }

  bool _hasMedicineClue(String line) {
    final lower = line.toLowerCase();
    return _strengthPattern.hasMatch(lower) ||
        _formWordPattern.hasMatch(lower) ||
        _frequencyPattern.hasMatch(lower) ||
        lower.contains('morning') ||
        lower.contains('afternoon') ||
        lower.contains('night') ||
        lower.contains('before food') ||
        lower.contains('after food') ||
        lower.contains('before meal') ||
        lower.contains('after meal') ||
        RegExp(r'\b(?:od|bd|tds|tid|hs|sos)\b').hasMatch(lower);
  }

  bool _isSupportingInstructionLine(String line) {
    final lower = line.toLowerCase();
    if (lower.startsWith('take ') ||
        lower.startsWith('use ') ||
        lower.startsWith('apply ') ||
        lower.startsWith('instill ') ||
        lower.startsWith('1 ') ||
        lower.startsWith('0 ') ||
        _frequencyPattern.hasMatch(lower) ||
        lower.contains('times daily') ||
        lower.contains('once daily') ||
        lower.contains('twice daily') ||
        lower.contains('thrice daily') ||
        lower.contains('morning') ||
        lower.contains('afternoon') ||
        lower.contains('night') ||
        lower.contains('before food') ||
        lower.contains('after food') ||
        lower.contains('before meal') ||
        lower.contains('after meal')) {
      return true;
    }
    return false;
  }

  String _combineDosageLine(String base, List<String> supportingLines) {
    final usefulLines = supportingLines
        .where(
          (line) => !line.toLowerCase().startsWith('supply'),
        )
        .toList();

    if (base.isNotEmpty &&
        base != base.split('|').first.trim() &&
        usefulLines.isEmpty) {
      return base;
    }

    final pieces = <String>[];
    if (base.isNotEmpty && !_looksLikeMedicineName(base)) {
      pieces.add(base);
    }
    pieces.addAll(usefulLines);
    return pieces.join(' | ');
  }

  bool _looksLikeMedicineName(String candidate) {
    final lower = candidate.toLowerCase();
    if (_ignoredLineStarts.any(lower.startsWith) ||
        _ignoredLineContains.any(lower.contains)) {
      return false;
    }
    if (RegExp(r'[:@]').hasMatch(candidate) || _timePattern.hasMatch(candidate)) {
      return false;
    }

    final words = candidate
        .split(RegExp(r'\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return false;
    }

    final meaningfulWords = words.where((word) {
      final clean = word.toLowerCase().replaceAll(RegExp(r'[^a-z0-9/+.-]'), '');
      if (clean.isEmpty) {
        return false;
      }
      if (_invalidMedicineNames.contains(clean)) {
        return false;
      }
      if ({'mg', 'ml', 'mcg', 'g', 'tab', 'tablet', 'cap', 'capsule'}.contains(clean)) {
        return false;
      }
      return RegExp(r'[a-z]').hasMatch(clean);
    }).toList();

    if (meaningfulWords.isEmpty) {
      return false;
    }

    return meaningfulWords.any((word) {
      final clean = word.toLowerCase().replaceAll(RegExp(r'[^a-z0-9/+.-]'), '');
      return RegExp(r'[a-z]{3,}').hasMatch(clean) || clean.contains('-');
    });
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
