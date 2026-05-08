import 'package:flutter/material.dart';
import 'package:medapp/app_scope.dart';
import 'package:medapp/models/medicine_log.dart';

class MedicineHistoryScreen extends StatefulWidget {
  const MedicineHistoryScreen({super.key});

  @override
  State<MedicineHistoryScreen> createState() => _MedicineHistoryScreenState();
}

class _MedicineHistoryScreenState extends State<MedicineHistoryScreen> {
  bool _showToday = true;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final logs = _showToday
        ? controller.logsForToday()
        : controller.logsForThisWeek();

    final takenCount = logs.where((log) => log.action == 'taken').length;
    final missedCount = logs.where((log) => log.action == 'missed').length;
    final refillCount = logs.where((log) => log.action.startsWith('refilled')).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Medicine History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medicine History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Review taken, missed, and refilled medicines in daily or weekly view.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(value: true, label: Text('Today')),
              ButtonSegment<bool>(value: false, label: Text('This Week')),
            ],
            selected: {_showToday},
            onSelectionChanged: (selection) {
              setState(() => _showToday = selection.first);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Taken',
                  value: takenCount.toString(),
                  color: const Color(0xFF0F766E),
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Missed',
                  value: missedCount.toString(),
                  color: const Color(0xFFDC2626),
                  icon: Icons.cancel_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Refilled',
                  value: refillCount.toString(),
                  color: const Color(0xFF2563EB),
                  icon: Icons.inventory_2_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (logs.isEmpty)
            const _EmptyHistory()
          else
            ...logs.map((log) => _LogTile(log: log)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(title),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final MedicineLog log;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(log.action);
    final icon = _iconFor(log.action);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(log.medicineName),
        subtitle: Text('${_labelFor(log.action)} • ${_formatDateTime(log.loggedAt)}'),
      ),
    );
  }

  Color _colorFor(String action) {
    if (action == 'taken') {
      return const Color(0xFF0F766E);
    }
    if (action == 'missed') {
      return const Color(0xFFDC2626);
    }
    if (action.startsWith('refilled')) {
      return const Color(0xFF2563EB);
    }
    return const Color(0xFF64748B);
  }

  IconData _iconFor(String action) {
    if (action == 'taken') {
      return Icons.check_circle_outline;
    }
    if (action == 'missed') {
      return Icons.cancel_outlined;
    }
    if (action.startsWith('refilled')) {
      return Icons.inventory_2_outlined;
    }
    return Icons.history;
  }

  String _labelFor(String action) {
    if (action == 'taken') {
      return 'Taken';
    }
    if (action == 'missed') {
      return 'Missed';
    }
    if (action.startsWith('refilled')) {
      return action.replaceFirst('refilled', 'Refilled');
    }
    return action[0].toUpperCase() + action.substring(1);
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.history_toggle_off, size: 40, color: Color(0xFF64748B)),
          SizedBox(height: 12),
          Text(
            'No history yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Mark medicines as taken or missed, or refill tablets to build your daily and weekly history.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
