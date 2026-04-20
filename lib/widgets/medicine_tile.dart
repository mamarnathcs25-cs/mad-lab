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
  });

  final Medicine medicine;
  final FamilyMember? profile;
  final VoidCallback onDelete;
  final VoidCallback onTaken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                        '${medicine.dosage.isEmpty ? 'Dosage not added' : medicine.dosage} - ${medicine.period.name}',
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
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(label: profile == null ? 'No profile' : profile!.name),
                _InfoChip(label: '${medicine.remainingTablets} tablets left'),
                if (medicine.isLowStock)
                  const _InfoChip(
                    label: 'Refill soon',
                    backgroundColor: Color(0xFFFFE0B2),
                    foregroundColor: Color(0xFF9A4D00),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTaken,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as taken'),
              ),
            ),
          ],
        ),
      ),
    );
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
