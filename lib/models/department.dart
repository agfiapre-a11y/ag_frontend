class Department {
  final String id;
  final String churchId;
  final String branchId;
  final String name;
  final String description;
  final DateTime createdAt;

  const Department({
    required this.id,
    required this.churchId,
    required this.branchId,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Department.fromMap(Map<dynamic, dynamic> map) => Department(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: map['branchId'] as String,
        name: map['name'] as String,
        description: (map['description'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Department copyWith({
    String? name,
    String? description,
    String? branchId,
  }) =>
      Department(
        id: id,
        churchId: churchId,
        branchId: branchId ?? this.branchId,
        name: name ?? this.name,
        description: description ?? this.description,
        createdAt: createdAt,
      );
}
