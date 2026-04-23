class MedicineLog {
  MedicineLog({
    required this.id,
    required this.medicineId,
    required this.profileId,
    required this.medicineName,
    required this.action,
    required this.loggedAt,
  });

  final String id;
  final String medicineId;
  final String profileId;
  final String medicineName;
  final String action;
  final DateTime loggedAt;
}
