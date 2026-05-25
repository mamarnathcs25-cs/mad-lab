import 'package:flutter/material.dart';
import 'package:medapp/app_scope.dart';
import 'package:medapp/models/medicine_log.dart';
import 'package:medapp/models/medicine_model.dart';
import 'package:medapp/screens/add_medicine_screen.dart';
import 'package:medapp/screens/medicine_history_screen.dart';
import 'package:medapp/services/app_controller.dart';
import 'package:medapp/widgets/medicine_tile.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final pendingMedicines = controller.pendingMedicines;
    final primaryProfile =
        controller.profiles.isEmpty ? null : controller.profiles.first;
    final recentLogs = primaryProfile == null
        ? <MedicineLog>[]
        : controller.recentLogsForProfile(primaryProfile.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Reminder System')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
          );

          if (saved == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Medicine reminder saved')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroBanner(controller: controller),
          const SizedBox(height: 16),
          _InsightRow(controller: controller),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Today\'s Medicines',
            subtitle: 'Track reminders, refill counts, and medicine actions.',
          ),
          const SizedBox(height: 12),
          if (pendingMedicines.isEmpty)
            const _EmptyPanel(
              title: 'No pending medicines',
              subtitle:
                  'Add a reminder or mark medicines tomorrow when the next day starts.',
              icon: Icons.medication_liquid_outlined,
            )
          else
            ...pendingMedicines.map(
              (medicine) => MedicineTile(
                medicine: medicine,
                profile: controller.profileById(medicine.profileId),
                onDelete: () => controller.deleteMedicine(medicine.id),
                onTaken: () => controller.decrementMedicine(medicine.id),
                onMissed: () => controller.markMedicineMissed(medicine.id),
                onAddTablets: () => _openAddTabletsScreen(
                  context: context,
                  medicineId: medicine.id,
                  medicineName: medicine.name,
                ),
              ),
            ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Recent Activity',
            subtitle: 'Taken doses and refill actions appear here.',
            actionLabel: 'View History',
            onAction: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MedicineHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (recentLogs.isEmpty)
            const _EmptyPanel(
              title: 'No activity yet',
              subtitle:
                  'Mark a medicine as taken or refill tablets to build your history log.',
              icon: Icons.history_toggle_off,
            )
          else
            ...recentLogs.map(
              (log) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFCCFBF1),
                    child: Icon(
                      log.action.startsWith('taken')
                          ? Icons.check_circle_outline
                          : log.action == 'missed'
                              ? Icons.cancel_outlined
                              : Icons.inventory_2_outlined,
                      color: log.action == 'missed'
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0F766E),
                    ),
                  ),
                  title: Text(log.medicineName),
                  subtitle: Text(
                    '${log.action} • ${_formatDateTime(log.loggedAt)}',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openAddTabletsScreen({
    required BuildContext context,
    required String medicineId,
    required String medicineName,
  }) async {
    final tabletCount = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => _AddTabletsScreen(medicineName: medicineName),
      ),
    );

    if (tabletCount == null || !context.mounted) {
      return;
    }

    final controller = AppScope.of(context);

    try {
      await controller.addTabletsToMedicine(
        medicineId: medicineId,
        tabletCount: tabletCount,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$tabletCount tablets added')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not add tablets. Please restart and try again.'),
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tonightCount = controller.medicinesForPeriod(MedicineTimeSlot.night);
    final lowStockSoon = controller.lowStockSoonCount();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3B39), Color(0xFF0F766E), Color(0xFF2DD4BF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F766E),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.favorite_outline,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'MediMate',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Stay on top of medicines without the stress.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You have $tonightCount medicines tonight and $lowStockSoon low-stock reminders to review.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(
                icon: Icons.nightlight_round,
                label: '$tonightCount tonight',
              ),
              _HeroPill(
                icon: Icons.inventory_2_outlined,
                label: '$lowStockSoon low stock',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InsightCard(
            title: 'Active meds',
            value: controller.medicines.length.toString(),
            icon: Icons.medication_outlined,
            accent: const Color(0xFF0F766E),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InsightCard(
            title: 'Low in 2 days',
            value: controller.lowStockSoonCount().toString(),
            icon: Icons.warning_amber_rounded,
            accent: const Color(0xFFF97316),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InsightCard(
            title: 'Tonight',
            value: controller
                .medicinesForPeriod(MedicineTimeSlot.night)
                .toString(),
            icon: Icons.nightlight_round,
            accent: const Color(0xFF1D4ED8),
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
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
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(title),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.arrow_outward, size: 18),
            label: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFF64748B)),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTabletsScreen extends StatefulWidget {
  const _AddTabletsScreen({required this.medicineName});

  final String medicineName;

  @override
  State<_AddTabletsScreen> createState() => _AddTabletsScreenState();
}

class _AddTabletsScreenState extends State<_AddTabletsScreen> {
  final TextEditingController _tabletController =
      TextEditingController(text: '10');

  @override
  void dispose() {
    _tabletController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Tablets')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Add tablets to ${widget.medicineName}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tabletController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Number of tablets',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(_tabletController.text.trim());
              if (value == null || value <= 0) {
                return;
              }
              Navigator.of(context).pop(value);
            },
            child: const Text('Add Tablets'),
          ),
        ],
      ),
    );
  }
}
