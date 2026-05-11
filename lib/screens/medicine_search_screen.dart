import 'package:flutter/material.dart';
import 'package:medapp/models/medicine_catalog_item.dart';
import 'package:medapp/services/medicine_service.dart';
import 'package:medapp/widgets/medicine_autocomplete_field.dart';

class MedicineSearchScreen extends StatefulWidget {
  const MedicineSearchScreen({super.key});

  @override
  State<MedicineSearchScreen> createState() => _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends State<MedicineSearchScreen> {
  final MedicineService _medicineService = MedicineService();
  final TextEditingController _controller = TextEditingController();
  MedicineCatalogItem? _selectedSuggestion;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Search')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search medicines offline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Start typing a medicine name like pa or azi to fetch instant local suggestions.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MedicineAutocompleteField(
            controller: _controller,
            service: _medicineService,
            onSuggestionSelected: (suggestion) {
              setState(() => _selectedSuggestion = suggestion);
            },
            onCleared: () => setState(() => _selectedSuggestion = null),
          ),
          const SizedBox(height: 16),
          if (_selectedSuggestion == null)
            const _SearchEmptyState()
          else
            _SearchResultCard(suggestion: _selectedSuggestion!),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.suggestion});

  final MedicineCatalogItem suggestion;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suggestion.displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Text('Dosage: ${suggestion.dosage}'),
            const SizedBox(height: 8),
            Text('Category: ${suggestion.category}'),
            const SizedBox(height: 8),
            Text('Usage: ${suggestion.usage}'),
          ],
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

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
          Icon(Icons.search, size: 40, color: Color(0xFF64748B)),
          SizedBox(height: 12),
          Text(
            'Search to see details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'This screen shows how the reusable local autocomplete widget can be used anywhere in the app without internet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
