class FamilyMember {
  FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    required this.age,
    required this.weightKg,
  });

  final String id;
  final String name;
  final String relationship;
  final int age;
  final double weightKg;

  FamilyMember copyWith({
    String? id,
    String? name,
    String? relationship,
    int? age,
    double? weightKg,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts
        .take(2)
        .map((part) => part.isEmpty ? '' : part[0])
        .join()
        .toUpperCase();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'age': age,
      'weightKg': weightKg,
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      name: json['name'] as String,
      relationship: json['relationship'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
    );
  }
}
