class MedicineCatalogItem {
  const MedicineCatalogItem({
    required this.name,
    required this.dosage,
    required this.category,
    required this.usage,
  });

  final String name;
  final String dosage;
  final String category;
  final String usage;

  String get displayName => '$name $dosage';

  factory MedicineCatalogItem.fromJson(Map<String, dynamic> json) {
    return MedicineCatalogItem(
      name: json['name']?.toString().trim() ?? '',
      dosage: json['dosage']?.toString().trim() ?? '',
      category: json['category']?.toString().trim() ?? '',
      usage: json['usage']?.toString().trim() ?? '',
    );
  }
}
