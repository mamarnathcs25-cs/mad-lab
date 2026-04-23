import 'package:medapp/models/family_member.dart';
import 'package:medapp/models/health_metric.dart';
import 'package:medapp/models/medicine_log.dart';
import 'package:medapp/models/medicine_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const _databaseName = 'medapp.db';
  static const _databaseVersion = 2;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databasePath = await getDatabasesPath();
    final path = p.join(databasePath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );

    return _database!;
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE family_members (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        relationship TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE medicines (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        period TEXT NOT NULL,
        total_tablets INTEGER NOT NULL,
        remaining_tablets INTEGER NOT NULL,
        tablets_per_dose INTEGER NOT NULL,
        last_refill_sync TEXT NOT NULL,
        reminders_enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (profile_id) REFERENCES family_members (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE health_metrics (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        recorded_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES family_members (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE medicine_logs (
        id TEXT PRIMARY KEY,
        medicine_id TEXT NOT NULL,
        profile_id TEXT NOT NULL,
        medicine_name TEXT NOT NULL,
        action TEXT NOT NULL,
        logged_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES family_members (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS medicine_logs (
          id TEXT PRIMARY KEY,
          medicine_id TEXT NOT NULL,
          profile_id TEXT NOT NULL,
          medicine_name TEXT NOT NULL,
          action TEXT NOT NULL,
          logged_at TEXT NOT NULL,
          FOREIGN KEY (profile_id) REFERENCES family_members (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<List<FamilyMember>> getFamilyMembers() async {
    final db = await database;
    final rows = await db.query(
      'family_members',
      orderBy: 'LOWER(name) ASC',
    );
    return rows.map(_familyMemberFromRow).toList();
  }

  Future<void> insertFamilyMember(FamilyMember member) async {
    final db = await database;
    await db.insert(
      'family_members',
      _familyMemberToRow(member),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateFamilyMember(FamilyMember member) async {
    await insertFamilyMember(member);
  }

  Future<void> deleteFamilyMember(String id) async {
    final db = await database;
    await db.delete('family_members', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Medicine>> getMedicines() async {
    final db = await database;
    final rows = await db.query(
      'medicines',
      orderBy: '''
        CASE period
          WHEN 'morning' THEN 0
          WHEN 'afternoon' THEN 1
          WHEN 'night' THEN 2
          ELSE 3
        END ASC,
        LOWER(name) ASC
      ''',
    );
    return rows.map(_medicineFromRow).toList();
  }

  Future<void> insertMedicine(Medicine medicine) async {
    final db = await database;
    await db.insert(
      'medicines',
      _medicineToRow(medicine),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMedicine(Medicine medicine) async {
    final db = await database;
    final updatedRows = await db.update(
      'medicines',
      _medicineToRow(medicine),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
    if (updatedRows == 0) {
      await insertMedicine(medicine);
    }
  }

  Future<void> deleteMedicine(String id) async {
    final db = await database;
    await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<HealthMetric>> getHealthMetrics() async {
    final db = await database;
    final rows = await db.query(
      'health_metrics',
      orderBy: 'recorded_at DESC',
    );
    return rows.map(_healthMetricFromRow).toList();
  }

  Future<List<MedicineLog>> getMedicineLogs() async {
    final db = await database;
    final rows = await db.query(
      'medicine_logs',
      orderBy: 'logged_at DESC',
    );
    return rows.map(_medicineLogFromRow).toList();
  }

  Future<void> insertHealthMetric(HealthMetric metric) async {
    final db = await database;
    await db.insert(
      'health_metrics',
      _healthMetricToRow(metric),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMedicineLog(MedicineLog log) async {
    final db = await database;
    await db.insert(
      'medicine_logs',
      _medicineLogToRow(log),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteProfileRelatedData(String profileId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'medicine_logs',
        where: 'profile_id = ?',
        whereArgs: [profileId],
      );
      await txn.delete(
        'health_metrics',
        where: 'profile_id = ?',
        whereArgs: [profileId],
      );
      await txn.delete(
        'medicines',
        where: 'profile_id = ?',
        whereArgs: [profileId],
      );
      await txn.delete(
        'family_members',
        where: 'id = ?',
        whereArgs: [profileId],
      );
    });
  }

  Future<void> seedDefaults({
    required List<FamilyMember> profiles,
    required List<Medicine> medicines,
    required List<HealthMetric> metrics,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final profile in profiles) {
        await txn.insert(
          'family_members',
          _familyMemberToRow(profile),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      for (final medicine in medicines) {
        await txn.insert(
          'medicines',
          _medicineToRow(medicine),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      for (final metric in metrics) {
        await txn.insert(
          'health_metrics',
          _healthMetricToRow(metric),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  Map<String, Object?> _familyMemberToRow(FamilyMember member) {
    return {
      'id': member.id,
      'name': member.name,
      'relationship': member.relationship,
    };
  }

  FamilyMember _familyMemberFromRow(Map<String, Object?> row) {
    return FamilyMember(
      id: row['id'] as String,
      name: row['name'] as String,
      relationship: row['relationship'] as String,
    );
  }

  Map<String, Object?> _medicineToRow(Medicine medicine) {
    return {
      'id': medicine.id,
      'profile_id': medicine.profileId,
      'name': medicine.name,
      'dosage': medicine.dosage,
      'period': medicine.period.name,
      'total_tablets': medicine.totalTablets,
      'remaining_tablets': medicine.remainingTablets,
      'tablets_per_dose': medicine.tabletsPerDose,
      'last_refill_sync': medicine.lastRefillSync.toIso8601String(),
      'reminders_enabled': medicine.remindersEnabled ? 1 : 0,
    };
  }

  Medicine _medicineFromRow(Map<String, Object?> row) {
    return Medicine(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      name: row['name'] as String,
      dosage: row['dosage'] as String,
      period: MedicineTimeSlot.values.byName(row['period'] as String),
      totalTablets: row['total_tablets'] as int,
      remainingTablets: row['remaining_tablets'] as int,
      tabletsPerDose: row['tablets_per_dose'] as int,
      lastRefillSync: DateTime.tryParse(row['last_refill_sync'] as String) ??
          DateTime.now(),
      remindersEnabled: row['reminders_enabled'] == 1,
    );
  }

  Map<String, Object?> _healthMetricToRow(HealthMetric metric) {
    return {
      'id': metric.id,
      'profile_id': metric.profileId,
      'type': metric.type.name,
      'value': metric.value,
      'recorded_at': metric.recordedAt.toIso8601String(),
    };
  }

  HealthMetric _healthMetricFromRow(Map<String, Object?> row) {
    return HealthMetric(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      type: MetricType.values.byName(row['type'] as String),
      value: (row['value'] as num).toDouble(),
      recordedAt:
          DateTime.tryParse(row['recorded_at'] as String) ?? DateTime.now(),
    );
  }

  Map<String, Object?> _medicineLogToRow(MedicineLog log) {
    return {
      'id': log.id,
      'medicine_id': log.medicineId,
      'profile_id': log.profileId,
      'medicine_name': log.medicineName,
      'action': log.action,
      'logged_at': log.loggedAt.toIso8601String(),
    };
  }

  MedicineLog _medicineLogFromRow(Map<String, Object?> row) {
    return MedicineLog(
      id: row['id'] as String,
      medicineId: row['medicine_id'] as String,
      profileId: row['profile_id'] as String,
      medicineName: row['medicine_name'] as String,
      action: row['action'] as String,
      loggedAt: DateTime.tryParse(row['logged_at'] as String) ?? DateTime.now(),
    );
  }
}
