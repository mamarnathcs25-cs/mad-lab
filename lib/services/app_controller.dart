import 'package:flutter/foundation.dart';
import 'package:medapp/models/family_member.dart';
import 'package:medapp/models/health_metric.dart';
import 'package:medapp/models/medicine_model.dart';

class AppController extends ChangeNotifier {
  AppController() {
    _seedDefaults();
  }

  final List<FamilyMember> _profiles = [];
  final List<Medicine> _medicines = [];
  final List<HealthMetric> _metrics = [];

  bool _isLoaded = false;

  List<FamilyMember> get profiles => List.unmodifiable(_profiles);
  List<Medicine> get medicines => List.unmodifiable(_medicines);
  List<HealthMetric> get metrics => List.unmodifiable(_metrics);
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _syncRefillCounts();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> addProfile({
    required String name,
    required String relationship,
  }) async {
    _profiles.add(
      FamilyMember(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        relationship: relationship,
      ),
    );
    notifyListeners();
  }

  Future<void> updateProfile({
    required String profileId,
    required String name,
    required String relationship,
  }) async {
    final index = _profiles.indexWhere((profile) => profile.id == profileId);
    if (index == -1) {
      return;
    }

    _profiles[index] = _profiles[index].copyWith(
      name: name,
      relationship: relationship,
    );
    notifyListeners();
  }

  Future<void> deleteProfile(String profileId) async {
    _profiles.removeWhere((profile) => profile.id == profileId);
    _medicines.removeWhere((medicine) => medicine.profileId == profileId);
    _metrics.removeWhere((metric) => metric.profileId == profileId);
    notifyListeners();
  }

  Future<void> addMedicine({
    required String profileId,
    required String name,
    required String dosage,
    required MedicineTimeSlot period,
    required int totalTablets,
    required int tabletsPerDose,
  }) async {
    final medicine = Medicine(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      profileId: profileId,
      name: name,
      dosage: dosage,
      period: period,
      totalTablets: totalTablets,
      remainingTablets: totalTablets,
      tabletsPerDose: tabletsPerDose,
      lastRefillSync: DateTime.now(),
    );
    _medicines.add(medicine);
    notifyListeners();
  }

  Future<void> deleteMedicine(String medicineId) async {
    _medicines.removeWhere((medicine) => medicine.id == medicineId);
    notifyListeners();
  }

  Future<void> addHealthMetric({
    required String profileId,
    required MetricType type,
    required double value,
  }) async {
    _metrics.add(
      HealthMetric(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        profileId: profileId,
        type: type,
        value: value,
        recordedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> decrementMedicine(String medicineId) async {
    final index =
        _medicines.indexWhere((medicine) => medicine.id == medicineId);
    if (index == -1) {
      return;
    }

    final current = _medicines[index];
    final updated = current.copyWith(
      remainingTablets: (current.remainingTablets - current.tabletsPerDose)
          .clamp(0, current.totalTablets),
      lastRefillSync: DateTime.now(),
    );
    _medicines[index] = updated;
    notifyListeners();
  }

  List<Medicine> medicinesForProfile(String profileId) {
    return _medicines
        .where((medicine) => medicine.profileId == profileId)
        .toList();
  }

  List<HealthMetric> metricsForProfile(String profileId, MetricType type) {
    final filtered = _metrics
        .where((metric) => metric.profileId == profileId && metric.type == type)
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return filtered;
  }

  FamilyMember? profileById(String id) {
    try {
      return _profiles.firstWhere((profile) => profile.id == id);
    } catch (_) {
      return null;
    }
  }

  void _seedDefaults() {
    if (_profiles.isNotEmpty || _metrics.isNotEmpty || _medicines.isNotEmpty) {
      return;
    }

    final primaryProfile = FamilyMember(
      id: 'self',
      name: 'You',
      relationship: 'Self',
    );
    final mother = FamilyMember(
      id: 'mother',
      name: 'Anita',
      relationship: 'Mother',
    );

    _profiles
      ..clear()
      ..addAll([primaryProfile, mother]);

    _medicines
      ..clear()
      ..add(
        Medicine(
          id: 'starter-med-1',
          profileId: primaryProfile.id,
          name: 'Metformin',
          dosage: '500 mg',
          period: MedicineTimeSlot.morning,
          totalTablets: 15,
          remainingTablets: 9,
          tabletsPerDose: 1,
          lastRefillSync: DateTime.now(),
        ),
      );

    _metrics
      ..clear()
      ..addAll([
        HealthMetric(
          id: 'bp-1',
          profileId: primaryProfile.id,
          type: MetricType.bloodPressure,
          value: 124,
          recordedAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        HealthMetric(
          id: 'bp-2',
          profileId: primaryProfile.id,
          type: MetricType.bloodPressure,
          value: 122,
          recordedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        HealthMetric(
          id: 'bp-3',
          profileId: primaryProfile.id,
          type: MetricType.bloodPressure,
          value: 118,
          recordedAt: DateTime.now(),
        ),
      ]);
  }

  void _syncRefillCounts() {
    final now = DateTime.now();
    for (var i = 0; i < _medicines.length; i++) {
      final medicine = _medicines[i];
      final days = DateTime(now.year, now.month, now.day)
          .difference(DateTime(
            medicine.lastRefillSync.year,
            medicine.lastRefillSync.month,
            medicine.lastRefillSync.day,
          ))
          .inDays;

      if (days <= 0) {
        continue;
      }

      final reducedBy = days * medicine.tabletsPerDose;
      _medicines[i] = medicine.copyWith(
        remainingTablets: (medicine.remainingTablets - reducedBy)
            .clamp(0, medicine.totalTablets),
        lastRefillSync: now,
      );
    }
  }
}
