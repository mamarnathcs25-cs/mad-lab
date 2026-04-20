class FamilyMember {
  FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
  });

  final String id;
  final String name;
  final String relationship;

  FamilyMember copyWith({
    String? id,
    String? name,
    String? relationship,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
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
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      name: json['name'] as String,
      relationship: json['relationship'] as String? ?? '',
    );
  }
}
