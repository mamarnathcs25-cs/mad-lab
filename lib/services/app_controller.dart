import 'package:flutter/foundation.dart';
import 'package:medapp/models/family_member.dart';
import 'package:medapp/models/health_metric.dart';
import 'package:medapp/models/medicine_log.dart';
import 'package:medapp/models/medicine_model.dart';
import 'package:medapp/services/database_service.dart';

class AppController extends ChangeNotifier {
  AppController();

  final List<FamilyMember> _profiles = [];
  final List<Medicine> _medicines = [];
  final List<HealthMetric> _metrics = [];
  final List<MedicineLog> _medicineLogs = [];
  final DatabaseService _database = DatabaseService.instance;

  bool _isLoaded = false;

  List<FamilyMember> get profiles => List.unmodifiable(_profiles);
  List<Medicine> get medicines => List.unmodifiable(_medicines);
  List<HealthMetric> get metrics => List.unmodifiable(_metrics);
  List<MedicineLog> get medicineLogs => List.unmodifiable(_medicineLogs);
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    if (kIsWeb) {
      _seedDefaultsInMemory();
      _sortAll();
      _isLoaded = true;
      notifyListeners();
      return;
    }

    await _loadFromDatabase();
    if (_profiles.isEmpty) {
      _seedDefaultsInMemory();
      await _database.seedDefaults(
        profiles: _profiles,
        medicines: _medicines,
        metrics: _metrics,
      );
      await _loadFromDatabase();
    }

    await _syncRefillCounts();
    _sortAll();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _loadFromDatabase() async {
    _profiles
      ..clear()
      ..addAll(await _database.getFamilyMembers());
    _medicines
      ..clear()
      ..addAll(await _database.getMedicines());
    _metrics
      ..clear()
      ..addAll(await _database.getHealthMetrics());
    _medicineLogs
      ..clear()
      ..addAll(await _database.getMedicineLogs());
  }

  Future<void> addProfile({
    required String name,
    required String relationship,
  }) async {
    final profile = FamilyMember(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      relationship: relationship,
    );
    _profiles.add(profile);
    if (!kIsWeb) {
      await _database.insertFamilyMember(profile);
      await _loadFromDatabase();
    }
    _sortAll();
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
    final current = _profiles[index];
    final updated = _profiles[index].copyWith(
      name: name,
      relationship: relationship,
    );

    try {
      _profiles[index] = updated;
      if (!kIsWeb) {
        await _database.updateFamilyMember(updated);
        await _loadFromDatabase();
      }
      _sortAll();
      notifyListeners();
    } catch (_) {
      _profiles[index] = current;
      _sortAll();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProfile(String profileId) async {
    _profiles.removeWhere((profile) => profile.id == profileId);
    _medicines.removeWhere((medicine) => medicine.profileId == profileId);
    _metrics.removeWhere((metric) => metric.profileId == profileId);
    if (!kIsWeb) {
      await _database.deleteProfileRelatedData(profileId);
      await _loadFromDatabase();
    }
    _sortAll();
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
    if (!kIsWeb) {
      await _database.insertMedicine(medicine);
      await _database.insertMedicineLog(
        MedicineLog(
          id: '${medicine.id}-created',
          medicineId: medicine.id,
          profileId: medicine.profileId,
          medicineName: medicine.name,
          action: 'created',
          loggedAt: DateTime.now(),
        ),
      );
      await _loadFromDatabase();
    }
    _sortAll();
    notifyListeners();
  }

  Future<void> deleteMedicine(String medicineId) async {
    _medicines.removeWhere((medicine) => medicine.id == medicineId);
    if (!kIsWeb) {
      await _database.deleteMedicine(medicineId);
      await _loadFromDatabase();
    }
    notifyListeners();
  }

  Future<void> addHealthMetric({
    required String profileId,
    required MetricType type,
    required double value,
  }) async {
    final metric = HealthMetric(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      profileId: profileId,
      type: type,
      value: value,
      recordedAt: DateTime.now(),
    );
    _metrics.add(metric);
    if (!kIsWeb) {
      await _database.insertHealthMetric(metric);
    }
    _sortAll();
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
    if (!kIsWeb) {
      await _database.updateMedicine(updated);
      await _database.insertMedicineLog(
        MedicineLog(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          medicineId: updated.id,
          profileId: updated.profileId,
          medicineName: updated.name,
          action: 'taken',
          loggedAt: DateTime.now(),
        ),
      );
      await _loadFromDatabase();
    }
    _sortAll();
    notifyListeners();
  }

  Future<void> addTabletsToMedicine({
    required String medicineId,
    required int tabletCount,
  }) async {
    if (tabletCount <= 0) {
      return;
    }

    final index =
        _medicines.indexWhere((medicine) => medicine.id == medicineId);
    if (index == -1) {
      return;
    }

    final current = _medicines[index];
    final updated = current.copyWith(
      totalTablets: current.totalTablets + tabletCount,
      remainingTablets: current.remainingTablets + tabletCount,
      lastRefillSync: DateTime.now(),
    );

    try {
      _medicines[index] = updated;
      if (!kIsWeb) {
        await _database.updateMedicine(updated);
        await _database.insertMedicineLog(
          MedicineLog(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            medicineId: updated.id,
            profileId: updated.profileId,
            medicineName: updated.name,
            action: 'refilled +$tabletCount',
            loggedAt: DateTime.now(),
          ),
        );
        await _loadFromDatabase();
      }
      _sortAll();
      notifyListeners();
    } catch (_) {
      _medicines[index] = current;
      _sortAll();
      notifyListeners();
      rethrow;
    }
  }

  List<Medicine> medicinesForProfile(String profileId) {
    final filtered = _medicines
        .where((medicine) => medicine.profileId == profileId)
        .toList();
    filtered.sort(_compareMedicines);
    return filtered;
  }

  List<HealthMetric> metricsForProfile(String profileId, MetricType type) {
    final filtered = _metrics
        .where((metric) => metric.profileId == profileId && metric.type == type)
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return filtered;
  }

  List<MedicineLog> recentLogsForProfile(String profileId) {
    return _medicineLogs
        .where((log) => log.profileId == profileId)
        .take(8)
        .toList();
  }

  int medicinesForPeriod(MedicineTimeSlot period) {
    return _medicines.where((medicine) => medicine.period == period).length;
  }

  int lowStockSoonCount() {
    return _medicines.where((medicine) => daysRemaining(medicine) <= 2).length;
  }

  int daysRemaining(Medicine medicine) {
    if (medicine.tabletsPerDose <= 0) {
      return 0;
    }
    return (medicine.remainingTablets / medicine.tabletsPerDose).floor();
  }

  FamilyMember? profileById(String id) {
    try {
      return _profiles.firstWhere((profile) => profile.id == id);
    } catch (_) {
      return null;
    }
  }

  void _seedDefaultsInMemory() {
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

  Future<void> _syncRefillCounts() async {
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
      final updated = medicine.copyWith(
        remainingTablets: (medicine.remainingTablets - reducedBy)
            .clamp(0, medicine.totalTablets),
        lastRefillSync: now,
      );
      _medicines[i] = updated;
      if (!kIsWeb) {
        await _database.updateMedicine(updated);
      }
    }
  }

  void _sortAll() {
    _profiles
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _medicines.sort(_compareMedicines);
    _metrics.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    _medicineLogs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  }

  int _compareMedicines(Medicine a, Medicine b) {
    final periodCompare = a.period.index.compareTo(b.period.index);
    if (periodCompare != 0) {
      return periodCompare;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
