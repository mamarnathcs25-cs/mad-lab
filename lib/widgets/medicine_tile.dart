import 'package:flutter/material.dart';
import 'package:medapp/models/family_member.dart';
import 'package:medapp/models/medicine_model.dart';

class MedicineTile extends StatelessWidget {
  const MedicineTile({
    super.key,
    required this.medicine,
    required this.profile,
    required this.onDelete,
    required this.onTaken,
    required this.onMissed,
    required this.onAddTablets,
  });

  final Medicine medicine;
  final FamilyMember? profile;
  final VoidCallback onDelete;
  final VoidCallback onTaken;
  final VoidCallback onMissed;
  final VoidCallback onAddTablets;

  int _daysRemaining() {
    if (medicine.tabletsPerDose <= 0) {
      return 0;
    }
    return (medicine.remainingTablets / medicine.tabletsPerDose).floor();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysRemaining = _daysRemaining();
    final formattedTime = _formatReminderTime();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: medicine.isLowStock
                      ? Colors.orange.shade100
                      : theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.medication_outlined,
                    color: medicine.isLowStock
                        ? Colors.orange.shade800
                        : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${medicine.dosage.isEmpty ? 'Dosage not added' : medicine.dosage} - $formattedTime - ${medicine.mealTiming == MealTiming.beforeMeal ? 'before meal' : 'after meal'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                    label: profile == null ? 'No profile' : profile!.name),
                _InfoChip(label: medicine.period.name),
                _InfoChip(label: '${medicine.remainingTablets} tablets left'),
                _InfoChip(label: '$daysRemaining day supply'),
                if (medicine.isLowStock)
                  const _InfoChip(
                    label: 'Refill soon',
                    backgroundColor: Color(0xFFFFE0B2),
                    foregroundColor: Color(0xFF9A4D00),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: onTaken,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark as taken'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onMissed,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Mark missed'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onAddTablets,
                    icon: const Icon(Icons.add),
                    label: const Text('Add tablets'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReminderTime() {
    final hour = medicine.reminderHour;
    final minute = medicine.reminderMinute.toString().padLeft(2, '0');
    final normalizedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final suffix = hour >= 12 ? 'PM' : 'AM';
    return '$normalizedHour:$minute $suffix';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor ?? const Color(0xFF334155),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
