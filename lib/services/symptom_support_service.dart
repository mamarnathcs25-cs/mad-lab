import 'package:medapp/models/family_member.dart';
import 'package:medapp/models/medicine_model.dart';
import 'package:medapp/models/symptom_support_result.dart';

class SymptomSupportService {
  SymptomSupportResult generateSupport({
    required FamilyMember profile,
    required List<String> symptoms,
    required List<Medicine> currentMedicines,
  }) {
    final lowerSymptoms =
        symptoms.map((symptom) => symptom.toLowerCase()).toSet();
    final medicineSuggestions = <SymptomMedicineSuggestion>[];
    final careAdvice = <String>[];
    final warningAdvice = <String>[];
    final currentMedicineWarnings = <String>[];

    String possibleIssue = 'General symptom support';

    final hasFever = lowerSymptoms.contains('fever');
    final hasCough = lowerSymptoms.contains('cough');
    final hasCold = lowerSymptoms.contains('cold');
    final hasHeadache = lowerSymptoms.contains('headache');
    final hasBodyPain = lowerSymptoms.contains('body pain');
    final hasSoreThroat = lowerSymptoms.contains('sore throat');

    final lowerMedicineNames = currentMedicines
        .map((medicine) => medicine.name.toLowerCase())
        .toList();

    if (hasFever && (hasBodyPain || hasHeadache)) {
      possibleIssue = 'Possible viral fever or seasonal infection';
    } else if (hasCold || hasCough || hasSoreThroat) {
      possibleIssue = 'Possible cold or upper respiratory irritation';
    } else if (hasHeadache) {
      possibleIssue = 'Possible headache, stress, or dehydration';
    }

    if (hasFever) {
      if (profile.age < 1) {
        medicineSuggestions.add(
          SymptomMedicineSuggestion(
            commonMedicine: 'No self-medication for infants',
            howItHelps:
                'Fever in infants needs direct pediatric evaluation instead of home medicine guessing.',
            importantWarning:
                'Any fever in a baby under 3 months needs urgent medical attention.',
          ),
        );
        warningAdvice.add(
          'Any fever in a baby under 3 months needs urgent medical attention.',
        );
      } else if (profile.age < 12 || profile.weightKg < 40) {
        medicineSuggestions.add(
          SymptomMedicineSuggestion(
            commonMedicine: 'Pediatric paracetamol syrup/suspension',
            howItHelps: 'Commonly used to reduce fever in children.',
            importantWarning:
                'Use only child-safe label directions or doctor advice. Avoid adult-strength fever medicines for children.',
          ),
        );
        warningAdvice.add(
          'Avoid adult-strength fever medicines for children unless a doctor specifically advises it.',
        );
      } else {
        medicineSuggestions.add(
          SymptomMedicineSuggestion(
            commonMedicine: 'Paracetamol / Acetaminophen',
            howItHelps:
                'Common first-choice medicine for fever and mild body discomfort in adults.',
            importantWarning:
                'Avoid taking extra if the person is already using a similar pain or fever medicine.',
          ),
        );
      }
      careAdvice.add(
          'Drink fluids regularly and monitor temperature every few hours.');
      careAdvice.add('Rest and avoid heavy activity until the fever settles.');
      warningAdvice.add(
          'See a doctor if fever lasts more than 2 days or becomes very high.');
    }

    if (hasCough || hasCold || hasSoreThroat) {
      if (hasCough) {
        medicineSuggestions.add(
          SymptomMedicineSuggestion(
            commonMedicine: 'Cough syrup / Ambroxol-based relief',
            howItHelps:
                'Used depending on whether the cough is dry or with mucus.',
            importantWarning:
                'Choose according to cough type and avoid duplicate cold syrups.',
          ),
        );
      } else if (hasSoreThroat) {
        medicineSuggestions.add(
          SymptomMedicineSuggestion(
            commonMedicine: 'Throat lozenges + Paracetamol',
            howItHelps:
                'Commonly used for sore throat discomfort and mild pain relief.',
            importantWarning:
                'Seek medical help if swallowing becomes very painful or difficult.',
          ),
        );
      } else if (hasCold) {
        medicineSuggestions.add(
          SymptomMedicineSuggestion(
            commonMedicine: 'Cetirizine / Levocetirizine',
            howItHelps:
                'Commonly used for sneezing, runny nose, or allergy-type cold symptoms.',
            importantWarning:
                'May cause sleepiness in some people.',
          ),
        );
      } else {
        medicineSuggestions.add(
          SymptomMedicineSuggestion(
            commonMedicine: 'Saline nasal spray / steam inhalation',
            howItHelps:
                'Helps with blocked nose, mild congestion, and cold discomfort.',
            importantWarning:
                'Use steam carefully to avoid burns, especially for children.',
          ),
        );
      }
      careAdvice.add(
          'Warm fluids, steam carefully, and saline gargles may help soothe symptoms.');
      warningAdvice.add(
        'Get medical help if breathing becomes difficult, wheezing starts, or symptoms worsen quickly.',
      );
    }

    if (hasHeadache) {
      medicineSuggestions.add(
        SymptomMedicineSuggestion(
          commonMedicine: 'Paracetamol / Acetaminophen',
          howItHelps: 'Commonly used for headache relief.',
          importantWarning:
              'Do not combine with another pain or fever medicine already being taken.',
        ),
      );
      careAdvice.add(
          'Hydration, sleep, and reducing screen strain can help headache symptoms.');
      warningAdvice.add(
        'Seek medical help for severe headache, confusion, fainting, or repeated vomiting.',
      );
    }

    if (hasBodyPain) {
      medicineSuggestions.add(
        SymptomMedicineSuggestion(
          commonMedicine: 'Paracetamol / Ibuprofen',
          howItHelps:
              'Commonly used for body pain and fever-related discomfort in adults.',
          importantWarning:
              'Avoid duplicate pain-relief medicines and follow prior doctor restrictions.',
        ),
      );
      careAdvice.add(
          'Gentle rest and fluids can help body pain during viral illness.');
    }

    if (lowerMedicineNames.any(
      (name) =>
          name.contains('paracetamol') ||
          name.contains('acetaminophen') ||
          name.contains('ibuprofen'),
    )) {
      currentMedicineWarnings.add(
        'This profile is already taking a pain/fever medicine. Avoid doubling similar medicines without doctor or pharmacist advice.',
      );
    }

    if (currentMedicines.length >= 3) {
      currentMedicineWarnings.add(
        'This profile already has multiple medicines. Please review any new symptom-relief medicine with a doctor or pharmacist.',
      );
    }

    if (medicineSuggestions.isEmpty) {
      medicineSuggestions.add(
        SymptomMedicineSuggestion(
          commonMedicine: 'Doctor-approved medicine only',
          howItHelps:
              'Use symptom relief only after doctor or pharmacist guidance for unclear symptoms.',
          importantWarning:
              'Avoid guessing medicine when the symptom pattern is unclear.',
        ),
      );
    }

    if (warningAdvice.isEmpty) {
      warningAdvice.add(
        'See a doctor if symptoms keep worsening, last longer than expected, or the person looks very unwell.',
      );
    }

    return SymptomSupportResult(
      possibleIssue: possibleIssue,
      medicineSuggestions: _prioritizeSuggestions(
        _dedupeSuggestions(medicineSuggestions),
      ),
      careAdvice: careAdvice.toSet().toList(),
      warningAdvice: warningAdvice.toSet().toList(),
      currentMedicineWarnings: currentMedicineWarnings.toSet().toList(),
      disclaimer:
          'I am not a doctor. These are general support suggestions only. Please consult a doctor if symptoms continue, worsen, or feel serious.',
    );
  }

  List<SymptomMedicineSuggestion> _dedupeSuggestions(
    List<SymptomMedicineSuggestion> suggestions,
  ) {
    final seen = <String>{};
    final result = <SymptomMedicineSuggestion>[];
    for (final suggestion in suggestions) {
      final key =
          '${suggestion.commonMedicine}|${suggestion.howItHelps}|${suggestion.importantWarning}';
      if (seen.add(key)) {
        result.add(suggestion);
      }
    }
    return result;
  }

  List<SymptomMedicineSuggestion> _prioritizeSuggestions(
    List<SymptomMedicineSuggestion> suggestions,
  ) {
    if (suggestions.isEmpty) {
      return suggestions;
    }

    final priority = <String, int>{
      'no self-medication for infants': 0,
      'pediatric paracetamol syrup/suspension': 1,
      'paracetamol / acetaminophen': 2,
      'cetirizine / levocetirizine': 3,
      'cough syrup / ambroxol-based relief': 4,
      'throat lozenges + paracetamol': 5,
      'saline nasal spray / steam inhalation': 6,
      'paracetamol / ibuprofen': 7,
      'doctor-approved medicine only': 8,
    };

    final sorted = [...suggestions]
      ..sort((a, b) {
        final aRank = priority[a.commonMedicine.toLowerCase()] ?? 99;
        final bRank = priority[b.commonMedicine.toLowerCase()] ?? 99;
        return aRank.compareTo(bRank);
      });

    return [sorted.first];
  }
}
