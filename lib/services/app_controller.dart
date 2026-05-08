import 'package:flutter/foundation.dart';
import 'package:medapp/models/family_member.dart';
import 'package:medapp/models/health_metric.dart';
import 'package:medapp/models/medicine_log.dart';
import 'package:medapp/models/medicine_model.dart';
import 'package:medapp/services/database_service.dart';
import 'package:medapp/services/notification_service.dart';

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
  List<Medicine> get pendingMedicines => List.unmodifiable(
        _medicines.where((medicine) => !isMedicineHandledToday(medicine)),
      );
  List<HealthMetric> get metrics => List.unmodifiable(_metrics);
  List<MedicineLog> get medicineLogs => List.unmodifiable(_medicineLogs);
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    if (kIsWeb) {
      _sortAll();
      _isLoaded = true;
      notifyListeners();
      return;
    }

    await _loadFromDatabase();
    await _removeLegacySeedData();
    await _loadFromDatabase();
    await refreshMedicineStatuses();
    await _refreshMedicineSchedules();
    _sortAll();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> refreshMedicineStatuses() async {
    if (kIsWeb) {
      notifyListeners();
      return;
    }

    await _syncRefillCounts();
    await _autoMarkNightMisses();
    await _loadFromDatabase();
    _sortAll();
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
    required int age,
    required double weightKg,
  }) async {
    final profile = FamilyMember(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      relationship: relationship,
      age: age,
      weightKg: weightKg,
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
    required int age,
    required double weightKg,
  }) async {
    final index = _profiles.indexWhere((profile) => profile.id == profileId);
    if (index == -1) {
      return;
    }
    final current = _profiles[index];
    final updated = _profiles[index].copyWith(
      name: name,
      relationship: relationship,
      age: age,
      weightKg: weightKg,
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
    required MealTiming mealTiming,
    required int reminderHour,
    required int reminderMinute,
    required int totalTablets,
    required int tabletsPerDose,
  }) async {
    final period = medicineTimeSlotForHour(reminderHour);
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
      mealTiming: mealTiming,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
    );
    _medicines.add(medicine);
    if (!kIsWeb) {
      await _database.insertMedicine(medicine);
      await NotificationService.instance.scheduleMedicineReminder(medicine);
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
      await NotificationService.instance.cancelMedicineReminder(medicineId);
      await _loadFromDatabase();
    }
    notifyListeners();
  }

  Future<void> addHealthMetric({
    required String profileId,
    required MetricType type,
    required double value,
    DateTime? recordedAt,
  }) async {
    final entryDate = recordedAt ?? DateTime.now();
    final metric = HealthMetric(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      profileId: profileId,
      type: type,
      value: value,
      recordedAt: entryDate,
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
    if (isMedicineHandledToday(current)) {
      return;
    }
    final updated = current.copyWith(
      remainingTablets: (current.remainingTablets - current.tabletsPerDose)
          .clamp(0, current.totalTablets),
      lastRefillSync: DateTime.now(),
      lastTakenOn: DateTime.now(),
      lastMissedOn: null,
    );
    _medicines[index] = updated;
    if (!kIsWeb) {
      await _database.updateMedicine(updated);
      await NotificationService.instance.dismissActiveMedicineNotification(
        updated.id,
      );
      await NotificationService.instance.scheduleMedicineReminder(updated);
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

  Future<void> markMedicineMissed(String medicineId) async {
    final index =
        _medicines.indexWhere((medicine) => medicine.id == medicineId);
    if (index == -1) {
      return;
    }

    final current = _medicines[index];
    if (isMedicineHandledToday(current)) {
      return;
    }

    final updated = current.copyWith(lastMissedOn: DateTime.now());
    _medicines[index] = updated;

    if (!kIsWeb) {
      await _database.updateMedicine(updated);
      await NotificationService.instance.dismissActiveMedicineNotification(
        updated.id,
      );
      await NotificationService.instance.scheduleMedicineReminder(updated);
      await _database.insertMedicineLog(
        MedicineLog(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          medicineId: updated.id,
          profileId: updated.profileId,
          medicineName: updated.name,
          action: 'missed',
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
        .where(
          (medicine) =>
              medicine.profileId == profileId &&
              !isMedicineHandledToday(medicine),
        )
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

  List<MedicineLog> logsForToday() {
    final now = DateTime.now();
    return _medicineLogs.where((log) {
      return log.loggedAt.year == now.year &&
          log.loggedAt.month == now.month &&
          log.loggedAt.day == now.day;
    }).toList();
  }

  List<MedicineLog> logsForThisWeek() {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return _medicineLogs.where((log) {
      return !log.loggedAt.isBefore(startOfWeek) &&
          log.loggedAt.isBefore(endOfWeek);
    }).toList();
  }

  int medicinesForPeriod(MedicineTimeSlot period) {
    return _medicines
        .where(
          (medicine) =>
              medicine.period == period && !isMedicineHandledToday(medicine),
        )
        .length;
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

  Future<void> _refreshMedicineSchedules() async {
    if (kIsWeb) {
      return;
    }
    for (final medicine in _medicines) {
      await NotificationService.instance.scheduleMedicineReminder(medicine);
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
    final hourCompare = a.reminderHour.compareTo(b.reminderHour);
    if (hourCompare != 0) {
      return hourCompare;
    }
    final minuteCompare = a.reminderMinute.compareTo(b.reminderMinute);
    if (minuteCompare != 0) {
      return minuteCompare;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  bool isMedicineTakenToday(Medicine medicine) {
    return _isSameDay(medicine.lastTakenOn, DateTime.now());
  }

  bool isMedicineMissedToday(Medicine medicine) {
    return _isSameDay(medicine.lastMissedOn, DateTime.now());
  }

  bool isMedicineHandledToday(Medicine medicine) {
    return isMedicineTakenToday(medicine) || isMedicineMissedToday(medicine);
  }

  Future<void> markMedicineTakenFromNotification(String medicineId) async {
    await decrementMedicine(medicineId);
  }

  Future<void> _removeLegacySeedData() async {
    final demoProfileIds = {'self', 'mother'};
    final hasLegacyProfiles = _profiles.any(
      (profile) => demoProfileIds.contains(profile.id),
    );
    final hasLegacyMedicine = _medicines.any(
      (medicine) => medicine.id == 'starter-med-1',
    );
    if (!hasLegacyProfiles && !hasLegacyMedicine) {
      return;
    }

    for (final profileId in demoProfileIds) {
      if (_profiles.any((profile) => profile.id == profileId)) {
        await _database.deleteProfileRelatedData(profileId);
      }
    }
  }

  Future<void> _autoMarkNightMisses() async {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day, 22);
    if (now.isBefore(cutoff)) {
      return;
    }

    for (var i = 0; i < _medicines.length; i++) {
      final medicine = _medicines[i];
      if (isMedicineHandledToday(medicine)) {
        continue;
      }

      final reminderTime = DateTime(
        now.year,
        now.month,
        now.day,
        medicine.reminderHour,
        medicine.reminderMinute,
      );
      if (now.isBefore(reminderTime)) {
        continue;
      }

      final updated = medicine.copyWith(lastMissedOn: now);
      _medicines[i] = updated;
      await _database.updateMedicine(updated);
      await NotificationService.instance.cancelMedicineReminder(updated.id);
      await _database.insertMedicineLog(
        MedicineLog(
          id: 'missed-${updated.id}-${now.millisecondsSinceEpoch}',
          medicineId: updated.id,
          profileId: updated.profileId,
          medicineName: updated.name,
          action: 'missed',
          loggedAt: now,
        ),
      );
    }
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) {
      return false;
    }
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
