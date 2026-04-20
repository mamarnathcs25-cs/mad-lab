import 'package:flutter/material.dart';
import 'package:medapp/app_scope.dart';
import 'package:medapp/models/medicine_model.dart';
import 'package:medapp/services/app_controller.dart';
import 'package:medapp/widgets/medicine_tile.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _totalTabletsController =
      TextEditingController(text: '10');
  final TextEditingController _tabletsPerDoseController =
      TextEditingController(text: '1');

  MedicineTimeSlot _selectedPeriod = MedicineTimeSlot.morning;
  String? _selectedProfileId;

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
      appBar: AppBar(title: const Text('Medicine Reminder System')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummary(controller),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add medicine',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedProfileId,
                    items: profiles
                        .map(
                          (profile) => DropdownMenuItem<String>(
                            value: profile.id,
                            child: Text(
                                '${profile.name} (${profile.relationship})'),
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
                    value: _selectedPeriod,
                    items: MedicineTimeSlot.values
                        .map(
                          (period) => DropdownMenuItem(
                            value: period,
                            child: Text(period.name[0].toUpperCase() +
                                period.name.substring(1)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(
                        () => _selectedPeriod = value ?? MedicineTimeSlot.morning),
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
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: profiles.isEmpty
                          ? null
                          : () => _addMedicine(controller),
                      child: const Text('Save Reminder'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (controller.medicines.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: Text('No medicines added yet.')),
            )
          else
            ...controller.medicines.map(
              (medicine) => MedicineTile(
                medicine: medicine,
                profile: controller.profileById(medicine.profileId),
                onDelete: () => controller.deleteMedicine(medicine.id),
                onTaken: () => controller.decrementMedicine(medicine.id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary(AppController controller) {
    final lowStock =
        controller.medicines.where((medicine) => medicine.isLowStock).length;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Active meds',
            value: controller.medicines.length.toString(),
            icon: Icons.medication_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Low stock',
            value: lowStock.toString(),
            icon: Icons.warning_amber_rounded,
            accent: const Color(0xFFF97316),
          ),
        ),
      ],
    );
  }

  Future<void> _addMedicine(AppController controller) async {
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

    _nameController.clear();
    _dosageController.clear();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medicine reminder saved')),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.accent = const Color(0xFF0F766E),
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(title),
        ],
      ),
    );
  }
}
