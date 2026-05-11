import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:medapp/models/medicine_catalog_item.dart';
import 'package:medapp/services/medicine_service.dart';

class MedicineAutocompleteField extends StatelessWidget {
  const MedicineAutocompleteField({
    super.key,
    required this.controller,
    required this.service,
    required this.onSuggestionSelected,
    this.onCleared,
    this.labelText = 'Medicine name',
    this.hintText = 'Search medicine offline',
  });

  final TextEditingController controller;
  final MedicineService service;
  final ValueChanged<MedicineCatalogItem> onSuggestionSelected;
  final VoidCallback? onCleared;
  final String labelText;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<MedicineCatalogItem>(
      controller: controller,
      debounceDuration: const Duration(milliseconds: 250),
      suggestionsCallback: service.searchMedicines,
      itemBuilder: (context, suggestion) {
        return ListTile(
          dense: true,
          leading: const CircleAvatar(
            radius: 18,
            child: Icon(Icons.medication_outlined, size: 18),
          ),
          title: Text(
            suggestion.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('${suggestion.category} • ${suggestion.usage}'),
        );
      },
      onSelected: (suggestion) {
        controller.text = suggestion.displayName;
        onSuggestionSelected(suggestion);
      },
      loadingBuilder: (context) => const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            SizedBox(width: 12),
            Text('Loading...'),
          ],
        ),
      ),
      emptyBuilder: (context) => const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No medicines found',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ),
      errorBuilder: (context, error) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Could not load local medicines. Please restart the app.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      builder: (context, textController, focusNode) {
        if (textController != controller) {
          textController.text = controller.text;
          textController.selection = controller.selection;
        }

        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      controller.clear();
                      onCleared?.call();
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        );
      },
    );
  }
}
