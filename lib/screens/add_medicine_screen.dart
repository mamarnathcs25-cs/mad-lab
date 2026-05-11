import 'package:flutter/material.dart';
import 'package:medapp/app_scope.dart';
import 'package:medapp/models/medicine_catalog_item.dart';
import 'package:medapp/models/medicine_model.dart';
import 'package:medapp/services/medicine_service.dart';
import 'package:medapp/widgets/medicine_autocomplete_field.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({
    super.key,
    this.initialMedicineName = '',
    this.initialDosage = '',
    this.initialMealTiming,
    this.initialReminderHour = 8,
    this.initialReminderMinute = 30,
  });

  final String initialMedicineName;
  final String initialDosage;
  final MealTiming? initialMealTiming;
  final int initialReminderHour;
  final int initialReminderMinute;

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final MedicineService _medicineService = MedicineService();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  final TextEditingController _totalTabletsController =
      TextEditingController(text: '10');
  final TextEditingController _tabletsPerDoseController =
      TextEditingController(text: '1');

  late MealTiming _selectedMealTiming;
  String? _selectedProfileId;
  late TimeOfDay _selectedReminderTime;
  MedicineCatalogItem? _selectedSuggestion;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialMedicineName);
    _dosageController = TextEditingController(text: widget.initialDosage);
    _selectedMealTiming = widget.initialMealTiming ?? MealTiming.afterMeal;
    _selectedReminderTime = TimeOfDay(
      hour: widget.initialReminderHour,
      minute: widget.initialReminderMinute,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _totalTabletsController.dispose();
    _tabletsPerDoseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final profiles = controller.profiles;
    _selectedProfileId ??= profiles.isNotEmpty ? profiles.first.id : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Medicine')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Turn a scan or doctor note into a trackable reminder.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Set profile, dosage, schedule, and stock in one place.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProfileId,
                    items: profiles
                        .map(
                          (profile) => DropdownMenuItem<String>(
                            value: profile.id,
                            child: Text(
                              '${profile.name} (${profile.relationship})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedProfileId = value),
                    decoration: const InputDecoration(
                      labelText: 'Profile',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  MedicineAutocompleteField(
                    controller: _nameController,
                    service: _medicineService,
                    onSuggestionSelected: _handleSuggestionSelected,
                    onCleared: () => setState(() => _selectedSuggestion = null),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage text',
                      hintText: 'Example: 500 mg',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_selectedSuggestion != null) ...[
                    const SizedBox(height: 12),
                    _MedicineDetailsCard(suggestion: _selectedSuggestion!),
                  ],
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _pickReminderTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Reminder clock time',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedReminderTime.format(context),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const Text('Change'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MealTiming>(
                    initialValue: _selectedMealTiming,
                    items: MealTiming.values
                        .map(
                          (timing) => DropdownMenuItem(
                            value: timing,
                            child: Text(
                              timing == MealTiming.beforeMeal
                                  ? 'Before meal'
                                  : 'After meal',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(
                      () => _selectedMealTiming = value ?? MealTiming.afterMeal,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Meal timing',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'This will be grouped as ${_periodLabel(_periodFromTime(_selectedReminderTime))} medicine in the dashboard.',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _totalTabletsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total tablets',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _tabletsPerDoseController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tablets per day',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: profiles.isEmpty ? null : _save,
                      child: const Text('Save Reminder'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final controller = AppScope.of(context);
    if (_selectedProfileId == null || _nameController.text.trim().isEmpty) {
      return;
    }

    await controller.addMedicine(
      profileId: _selectedProfileId!,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      mealTiming: _selectedMealTiming,
      reminderHour: _selectedReminderTime.hour,
      reminderMinute: _selectedReminderTime.minute,
      totalTablets: int.tryParse(_totalTabletsController.text) ?? 10,
      tabletsPerDose: int.tryParse(_tabletsPerDoseController.text) ?? 1,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _handleSuggestionSelected(MedicineCatalogItem suggestion) {
    setState(() {
      _selectedSuggestion = suggestion;
      _dosageController.text = suggestion.dosage;
    });
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedReminderTime,
    );
    if (picked == null) {
      return;
    }
    setState(() => _selectedReminderTime = picked);
  }

  MedicineTimeSlot _periodFromTime(TimeOfDay time) {
    return medicineTimeSlotForHour(time.hour);
  }

  String _periodLabel(MedicineTimeSlot slot) {
    switch (slot) {
      case MedicineTimeSlot.morning:
        return 'morning';
      case MedicineTimeSlot.afternoon:
        return 'afternoon';
      case MedicineTimeSlot.night:
        return 'night';
    }
  }
}

class _MedicineDetailsCard extends StatelessWidget {
  const _MedicineDetailsCard({required this.suggestion});

  final MedicineCatalogItem suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: Color(0xFF0F766E)),
              const SizedBox(width: 8),
              Text(
                'Selected Medicine',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Name', value: suggestion.name),
          _DetailRow(label: 'Dosage', value: suggestion.dosage),
          _DetailRow(label: 'Category', value: suggestion.category),
          _DetailRow(label: 'Usage', value: suggestion.usage),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Color(0xFF0F766E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
