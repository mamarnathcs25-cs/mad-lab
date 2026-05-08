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
    final medicineSuggestions = <String>[];
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
          'For infants, do not self-medicate. Immediate pediatric advice is the safest option.',
        );
        warningAdvice.add(
          'Any fever in a baby under 3 months needs urgent medical attention.',
        );
      } else if (profile.age < 12 || profile.weightKg < 40) {
        medicineSuggestions.add(
          'Basic suggestion: pediatric paracetamol syrup/suspension may be commonly used, but only with child-safe label directions or doctor advice.',
        );
        warningAdvice.add(
          'Avoid adult-strength fever medicines for children unless a doctor specifically advises it.',
        );
      } else {
        medicineSuggestions.add(
          'Basic suggestion: paracetamol/acetaminophen is commonly used for fever if it is already safe for this person.',
        );
        medicineSuggestions.add(
          'Basic suggestion: ibuprofen is another common option for some adults, but avoid it with ulcer, kidney disease, or doctor restriction.',
        );
      }
      careAdvice.add(
          'Drink fluids regularly and monitor temperature every few hours.');
      careAdvice.add('Rest and avoid heavy activity until the fever settles.');
      warningAdvice.add(
          'See a doctor if fever lasts more than 2 days or becomes very high.');
    }

    if (hasCough || hasCold || hasSoreThroat) {
      medicineSuggestions.add(
        'Basic suggestion: saline spray, warm fluids, and age-appropriate cough/cold relief are commonly used depending on symptoms.',
      );
      careAdvice.add(
          'Warm fluids, steam carefully, and saline gargles may help soothe symptoms.');
      warningAdvice.add(
        'Get medical help if breathing becomes difficult, wheezing starts, or symptoms worsen quickly.',
      );
    }

    if (hasHeadache) {
      medicineSuggestions.add(
        'Basic suggestion: paracetamol/acetaminophen is commonly used for headache if it is safe for the person and not duplicating current medicines.',
      );
      careAdvice.add(
          'Hydration, sleep, and reducing screen strain can help headache symptoms.');
      warningAdvice.add(
        'Seek medical help for severe headache, confusion, fainting, or repeated vomiting.',
      );
    }

    if (hasBodyPain) {
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
        'Use only doctor-approved medicines or pharmacist guidance for these symptoms.',
      );
    }

    if (warningAdvice.isEmpty) {
      warningAdvice.add(
        'See a doctor if symptoms keep worsening, last longer than expected, or the person looks very unwell.',
      );
    }

    return SymptomSupportResult(
      possibleIssue: possibleIssue,
      medicineSuggestions: medicineSuggestions.toSet().toList(),
      careAdvice: careAdvice.toSet().toList(),
      warningAdvice: warningAdvice.toSet().toList(),
      currentMedicineWarnings: currentMedicineWarnings.toSet().toList(),
      disclaimer:
          'I am not a doctor. These are general support suggestions only. Please consult a doctor if symptoms continue, worsen, or feel serious.',
    );
  }
}
