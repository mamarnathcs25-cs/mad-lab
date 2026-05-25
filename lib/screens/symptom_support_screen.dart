import 'package:flutter/material.dart';
import 'package:medapp/app_scope.dart';
import 'package:medapp/models/family_member.dart';
import 'package:medapp/models/symptom_support_result.dart';
import 'package:medapp/services/symptom_support_service.dart';

class SymptomSupportScreen extends StatefulWidget {
  const SymptomSupportScreen({super.key, required this.profile});

  final FamilyMember profile;

  @override
  State<SymptomSupportScreen> createState() => _SymptomSupportScreenState();
}

class _SymptomSupportScreenState extends State<SymptomSupportScreen> {
  static const _symptoms = [
    'Fever',
    'Cough',
    'Cold',
    'Headache',
    'Body pain',
    'Sore throat',
  ];

  final Set<String> _selectedSymptoms = <String>{};
  final SymptomSupportService _service = SymptomSupportService();

  SymptomSupportResult? _result;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final profile = widget.profile;
    final currentMedicines = controller.medicinesForProfile(profile.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Symptom Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C2D12), Color(0xFFEA580C), Color(0xFFFB923C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22EA580C),
                  blurRadius: 24,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Age, weight, and medicine-aware support',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${profile.name}, age ${profile.age}, ${profile.weightKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current medicines tracked: ${currentMedicines.length}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroTag(label: '${profile.age} years'),
                    _HeroTag(label: '${profile.weightKg.toStringAsFixed(1)} kg'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What is the person feeling?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _symptoms.map((symptom) {
                      final isSelected = _selectedSymptoms.contains(symptom);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(symptom),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSymptoms.add(symptom);
                            } else {
                              _selectedSymptoms.remove(symptom);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _selectedSymptoms.isEmpty
                          ? null
                          : () {
                              setState(() {
                                _result = _service.generateSupport(
                                  profile: profile,
                                  symptoms: _selectedSymptoms.toList(),
                                  currentMedicines: currentMedicines,
                                );
                              });
                            },
                      icon: const Icon(Icons.medical_information_outlined),
                      label: const Text('Get Suggestion'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (currentMedicines.isNotEmpty)
            _SupportCard(
              title: 'Current Medicines Considered',
              color: const Color(0xFFF8FAFC),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: currentMedicines
                    .map((medicine) => Chip(label: Text(medicine.name)))
                    .toList(),
              ),
            ),
          if (_result != null) ...[
            const SizedBox(height: 12),
            _SupportCard(
              title: 'Possible Issue',
              color: const Color(0xFFDBEAFE),
              child: Text(_result!.possibleIssue),
            ),
            const SizedBox(height: 12),
            _SupportCard(
              title: 'Medicine Support Suggestion',
              color: const Color(0xFFDCFCE7),
              child: _result!.medicineSuggestions.isEmpty
                  ? const Text('No medicine suggestion available.')
                  : _MedicineSuggestionCard(
                      suggestion: _result!.medicineSuggestions.first,
                    ),
            ),
            if (_result!.currentMedicineWarnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SupportCard(
                title: 'Current Medicine Safety Check',
                color: const Color(0xFFFFEDD5),
                child: Column(
                  children: _result!.currentMedicineWarnings
                      .map((item) => _BulletText(text: item))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _SupportCard(
              title: 'Self-care Advice',
              color: const Color(0xFFE0F2FE),
              child: Column(
                children: _result!.careAdvice
                    .map((item) => _BulletText(text: item))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _SupportCard(
              title: 'When to See a Doctor',
              color: const Color(0xFFFEE2E2),
              child: Column(
                children: _result!.warningAdvice
                    .map((item) => _BulletText(text: item))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _SupportCard(
              title: 'Important Disclaimer',
              color: const Color(0xFFFEF3C7),
              child: Text(_result!.disclaimer),
            ),
          ],
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.title,
    required this.color,
    required this.child,
  });

  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 14,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 8),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _MedicineSuggestionCard extends StatelessWidget {
  const _MedicineSuggestionCard({required this.suggestion});

  final SymptomMedicineSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SuggestionRow(
            label: 'Common medicine',
            value: suggestion.commonMedicine,
            icon: Icons.medication_outlined,
          ),
          const SizedBox(height: 10),
          _SuggestionRow(
            label: 'How it helps',
            value: suggestion.howItHelps,
            icon: Icons.health_and_safety_outlined,
          ),
          const SizedBox(height: 10),
          _SuggestionRow(
            label: 'Important warning',
            value: suggestion.importantWarning,
            icon: Icons.warning_amber_rounded,
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF15803D)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF166534),
                ),
              ),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}
