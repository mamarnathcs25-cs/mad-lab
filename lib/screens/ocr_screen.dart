import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:medapp/app_scope.dart';
import 'package:medapp/models/medicine_model.dart';
import 'package:medapp/models/prescription_result.dart';
import 'package:medapp/screens/add_medicine_screen.dart';
import 'package:medapp/services/prescription_parser.dart';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key, required this.image});

  final File image;

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  final PrescriptionParser _parser = PrescriptionParser();

  bool _isLoading = true;
  PrescriptionResult? _result;
  List<PrescriptionEntry> _remainingEntries = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      final inputImage = InputImage.fromFile(widget.image);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      setState(() {
        _result = _parser.parse(recognizedText.text);
        _remainingEntries = List<PrescriptionEntry>.from(_result!.entries);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Failed to scan prescription. Please try a clearer photo.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final dosageLines = _remainingEntries
        .map((entry) => entry.dosageLine)
        .where((line) => line.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Prescription Results')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : result == null
                  ? const Center(child: Text('No scan result available'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (result.entries.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFF59E0B)),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Color(0xFFB45309),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No clear medicine line was detected from this scan. Try a straighter image, crop around the prescription item, or use a clearer photo.',
                                    style: TextStyle(
                                      color: Color(0xFF92400E),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _SectionCard(
                          title: 'Suggested Medicines',
                          icon: Icons.medication_outlined,
                          child: _remainingEntries.isEmpty
                              ? const Text(
                                  'All scanned medicines have been added or no clear medicines were detected.')
                              : Column(
                                  children: _remainingEntries.map((entry) {
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(12),
                                        leading: const CircleAvatar(
                                          child: Icon(
                                            Icons.local_hospital_outlined,
                                          ),
                                        ),
                                        title: Text(
                                          entry.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          entry.dosageLine.isEmpty
                                              ? entry.sourceLine
                                              : entry.dosageLine,
                                        ),
                                        trailing: FilledButton(
                                          onPressed: () => _openSingleAdd(
                                            context: context,
                                            entry: entry,
                                          ),
                                          child: const Text('Add'),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Dosage Lines',
                          icon: Icons.notes_outlined,
                          child: dosageLines.isEmpty
                              ? const Text('No dosage text detected.')
                              : Column(
                                  children: dosageLines
                                      .map(
                                        (line) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: const Icon(
                                              Icons.check_circle_outline),
                                          title: Text(line),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                        const SizedBox(height: 12),
                        if (_remainingEntries.isNotEmpty)
                          FilledButton.icon(
                            onPressed: () => _openBulkAdd(context),
                            icon: const Icon(Icons.auto_fix_high_outlined),
                            label: Text(
                              'Add All ${_remainingEntries.length} Medicines',
                            ),
                          ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Raw Extracted Text',
                          icon: Icons.text_snippet_outlined,
                          child: SelectableText(result.rawText.isEmpty
                              ? 'No text found.'
                              : result.rawText),
                        ),
                      ],
                    ),
    );
  }

  Future<void> _openSingleAdd({
    required BuildContext context,
    required PrescriptionEntry entry,
  }) async {
    final initialTime = _defaultTimeForSlot(
      entry.suggestedSlots.isEmpty ? null : entry.suggestedSlots.first,
    );
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddMedicineScreen(
          initialMedicineName: entry.name,
          initialDosage: entry.dosageLine,
          initialMealTiming: entry.suggestedMealTiming,
          initialReminderHour: initialTime.$1,
          initialReminderMinute: initialTime.$2,
        ),
      ),
    );

    if (!context.mounted || saved != true) {
      return;
    }

    setState(() {
      _remainingEntries.removeWhere(
        (item) => item.name == entry.name && item.sourceLine == entry.sourceLine,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.name} added to reminders')),
    );
  }

  Future<void> _openBulkAdd(BuildContext context) async {
    final savedNames = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => _BulkPrescriptionAddScreen(entries: _remainingEntries),
      ),
    );

    if (!context.mounted || savedNames == null || savedNames.isEmpty) {
      return;
    }

    setState(() {
      _remainingEntries.removeWhere(
        (entry) => savedNames.contains(entry.name),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${savedNames.length} medicines added to reminders')),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _BulkPrescriptionAddScreen extends StatefulWidget {
  const _BulkPrescriptionAddScreen({required this.entries});

  final List<PrescriptionEntry> entries;

  @override
  State<_BulkPrescriptionAddScreen> createState() =>
      _BulkPrescriptionAddScreenState();
}

class _BulkPrescriptionAddScreenState extends State<_BulkPrescriptionAddScreen> {
  final TextEditingController _totalTabletsController =
      TextEditingController(text: '10');
  final TextEditingController _tabletsPerDoseController =
      TextEditingController(text: '1');
  MealTiming _selectedMealTiming = MealTiming.afterMeal;
  TimeOfDay _fallbackReminderTime = const TimeOfDay(hour: 8, minute: 30);
  String? _selectedProfileId;
  final Set<int> _selectedIndexes = <int>{};

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.entries.length; i++) {
      _selectedIndexes.add(i);
    }
  }

  @override
  void dispose() {
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
      appBar: AppBar(title: const Text('Add Scanned Medicines')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                            child: Text('${profile.name} (${profile.relationship})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedProfileId = value),
                    decoration: const InputDecoration(labelText: 'Profile'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _pickReminderTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fallback reminder time',
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_fallbackReminderTime.format(context)),
                          ),
                          const Text('Change'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Detected morning/afternoon/night instructions will be used automatically. This time is only used when OCR cannot detect a schedule.',
                      style: TextStyle(color: Color(0xFF64748B)),
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
                    decoration: const InputDecoration(labelText: 'Meal timing'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _totalTabletsController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Total tablets'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _tabletsPerDoseController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Tablets per day'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.entries.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return CheckboxListTile(
              value: _selectedIndexes.contains(index),
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedIndexes.add(index);
                  } else {
                    _selectedIndexes.remove(index);
                  }
                });
              },
              title: Text(item.name),
              subtitle: Text(
                [
                  item.dosageLine.isEmpty ? item.sourceLine : item.dosageLine,
                  if (item.suggestedSlots.isNotEmpty)
                    'Detected: ${item.suggestedSlots.map(_slotLabel).join(', ')}',
                  if (item.suggestedMealTiming != null)
                    item.suggestedMealTiming == MealTiming.beforeMeal
                        ? 'Before meal'
                        : 'After meal',
                ].join('\n'),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              isThreeLine: true,
            );
          }),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: profiles.isEmpty || _selectedIndexes.isEmpty ? null : _saveAll,
            child: Text('Save ${_selectedIndexes.length} reminders'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _fallbackReminderTime,
    );
    if (picked != null) {
      setState(() => _fallbackReminderTime = picked);
    }
  }

  Future<void> _saveAll() async {
    final controller = AppScope.of(context);
    final profileId = _selectedProfileId;
    if (profileId == null) {
      return;
    }

    final totalTablets = int.tryParse(_totalTabletsController.text) ?? 10;
    final tabletsPerDose = int.tryParse(_tabletsPerDoseController.text) ?? 1;
    final savedNames = <String>[];

    for (final index in _selectedIndexes.toList()..sort()) {
      final entry = widget.entries[index];
      final slots = entry.suggestedSlots.isEmpty
          ? <MedicineTimeSlot>[
              medicineTimeSlotForHour(_fallbackReminderTime.hour),
            ]
          : entry.suggestedSlots;
      for (final slot in slots) {
        final reminderTime = entry.suggestedSlots.isEmpty
            ? (_fallbackReminderTime.hour, _fallbackReminderTime.minute)
            : _defaultTimeForSlot(slot);
        await controller.addMedicine(
          profileId: profileId,
          name: entry.name,
          dosage: entry.dosageLine,
          mealTiming: entry.suggestedMealTiming ?? _selectedMealTiming,
          reminderHour: reminderTime.$1,
          reminderMinute: reminderTime.$2,
          totalTablets: totalTablets,
          tabletsPerDose: tabletsPerDose,
        );
      }
      savedNames.add(entry.name);
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(savedNames);
  }

  String _slotLabel(MedicineTimeSlot slot) {
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

(int, int) _defaultTimeForSlot(MedicineTimeSlot? slot) {
  switch (slot) {
    case MedicineTimeSlot.morning:
      return (8, 0);
    case MedicineTimeSlot.afternoon:
      return (14, 0);
    case MedicineTimeSlot.night:
      return (20, 0);
    case null:
      return (8, 30);
  }
}
