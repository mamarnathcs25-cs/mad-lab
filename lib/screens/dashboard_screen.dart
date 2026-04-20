import 'package:flutter/material.dart';
import 'package:medapp/app_scope.dart';
import 'package:medapp/models/health_metric.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  MetricType _selectedType = MetricType.bloodPressure;
  String? _selectedProfileId;
  final TextEditingController _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final profiles = controller.profiles;
    _selectedProfileId ??= profiles.isNotEmpty ? profiles.first.id : null;
    final profileId = _selectedProfileId;
    final metrics = profileId == null
        ? <HealthMetric>[]
        : controller.metricsForProfile(profileId, _selectedType);

    return Scaffold(
      appBar: AppBar(title: const Text('Health Tracking Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add metric',
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
                            child: Text(profile.name),
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
                  DropdownButtonFormField<MetricType>(
                    value: _selectedType,
                    items: MetricType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(_metricTitle(type)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() =>
                        _selectedType = value ?? MetricType.bloodPressure),
                    decoration: const InputDecoration(
                      labelText: 'Metric',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _valueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Value',
                      hintText: 'Enter ${_unitForType(_selectedType)}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (_selectedProfileId == null) {
                          return;
                        }
                        final value = double.tryParse(_valueController.text);
                        if (value == null) {
                          return;
                        }
                        await controller.addHealthMetric(
                          profileId: _selectedProfileId!,
                          type: _selectedType,
                          value: value,
                        );
                        _valueController.clear();
                      },
                      child: const Text('Save Metric'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: metrics.isEmpty
                ? const Center(
                    child: Text('Add a few entries to view the graph.'))
                : _SimpleMetricChart(metrics: metrics),
          ),
          const SizedBox(height: 16),
          ...metrics.reversed.map(
            (metric) => Card(
              child: ListTile(
                leading: const Icon(Icons.monitor_heart_outlined),
                title: Text('${metric.value.toStringAsFixed(1)} ${metric.unit}'),
                subtitle: Text(_formatDateTime(metric.recordedAt)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _metricTitle(MetricType type) => switch (type) {
        MetricType.bloodPressure => 'Blood Pressure',
        MetricType.sugarLevel => 'Sugar Level',
        MetricType.weight => 'Weight',
      };

  String _unitForType(MetricType type) => switch (type) {
        MetricType.bloodPressure => 'mmHg',
        MetricType.sugarLevel => 'mg/dL',
        MetricType.weight => 'kg',
      };

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _SimpleMetricChart extends StatelessWidget {
  const _SimpleMetricChart({required this.metrics});

  final List<HealthMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final maxValue = metrics
        .map((metric) => metric.value)
        .fold<double>(0, (previous, current) => current > previous ? current : previous);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final metric in metrics.take(7))
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    metric.value.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 22,
                        height: maxValue == 0 ? 0 : (metric.value / maxValue) * 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${metric.recordedAt.day}/${metric.recordedAt.month}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
