import 'package:flutter/material.dart';
import 'package:medapp/app_scope.dart';
import 'package:medapp/models/medicine_model.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({
    super.key,
    this.initialMedicineName = '',
    this.initialDosage = '',
  });

  final String initialMedicineName;
  final String initialDosage;

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  final TextEditingController _totalTabletsController =
      TextEditingController(text: '10');
  final TextEditingController _tabletsPerDoseController =
      TextEditingController(text: '1');

  MedicineTimeSlot _selectedPeriod = MedicineTimeSlot.morning;
  String? _selectedProfileId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialMedicineName);
    _dosageController = TextEditingController(text: widget.initialDosage);
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
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medicine name',
                      border: OutlineInputBorder(),
                    ),
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<MedicineTimeSlot>(
                    initialValue: _selectedPeriod,
                    items: MedicineTimeSlot.values
                        .map(
                          (period) => DropdownMenuItem(
                            value: period,
                            child: Text(
                              period.name[0].toUpperCase() +
                                  period.name.substring(1),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(
                      () => _selectedPeriod = value ?? MedicineTimeSlot.morning,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Reminder time',
                      border: OutlineInputBorder(),
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
      period: _selectedPeriod,
      totalTablets: int.tryParse(_totalTabletsController.text) ?? 10,
      tabletsPerDose: int.tryParse(_tabletsPerDoseController.text) ?? 1,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }
}
