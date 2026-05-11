import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:medapp/models/medicine_catalog_item.dart';

class MedicineService {
  MedicineService();

  static const String _assetPath = 'assets/medicines.json';

  List<MedicineCatalogItem>? _cachedMedicines;
  Future<List<MedicineCatalogItem>>? _loadFuture;

  Future<List<MedicineCatalogItem>> loadMedicines() {
    if (_cachedMedicines != null) {
      return SynchronousFuture<List<MedicineCatalogItem>>(_cachedMedicines!);
    }

    _loadFuture ??= _readMedicinesFromAssets();
    return _loadFuture!;
  }

  Future<List<MedicineCatalogItem>> searchMedicines(String query) async {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.length < 2) {
      return const [];
    }

    final medicines = await loadMedicines();
    final filtered = medicines.where((medicine) {
      final haystacks = [
        medicine.name.toLowerCase(),
        medicine.displayName.toLowerCase(),
        medicine.category.toLowerCase(),
        medicine.usage.toLowerCase(),
      ];
      return haystacks.any((value) => value.contains(trimmedQuery));
    }).toList();

    filtered.sort((a, b) => a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        ));
    return filtered.take(12).toList();
  }

  Future<List<String>> searchMedicineNames(String query) async {
    final results = await searchMedicines(query);
    return results.map((medicine) => medicine.displayName).toList();
  }

  Future<List<MedicineCatalogItem>> _readMedicinesFromAssets() async {
    try {
      final rawJson = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) {
        throw const MedicineLoadException(
          'Local medicines JSON is not a valid list.',
        );
      }

      final medicines = decoded
          .whereType<Map>()
          .map(
            (item) => MedicineCatalogItem.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .where((item) => item.name.isNotEmpty)
          .toList();

      _cachedMedicines = medicines;
      _loadFuture = null;
      return medicines;
    } on FlutterError catch (error, stackTrace) {
      _log('Asset loading error: $error\n$stackTrace');
      _loadFuture = null;
      throw const MedicineLoadException(
        'Could not load local medicines database.',
      );
    } on FormatException catch (error, stackTrace) {
      _log('JSON parsing error: $error\n$stackTrace');
      _loadFuture = null;
      throw const MedicineLoadException(
        'Medicines JSON format is invalid.',
      );
    } catch (error, stackTrace) {
      _log('Unexpected local medicine error: $error\n$stackTrace');
      _loadFuture = null;
      throw MedicineLoadException('Unexpected medicine loading error: $error');
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[MedicineService] $message');
    }
  }
}

class MedicineLoadException implements Exception {
  const MedicineLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}
