class Branch {
  final String id;
  final String churchId;
  final String name;
  final String location;
  final String pastorId;
  
  // Hierarchical fields for multi-tenant support
  final String? organizationId;
  final String? regionId;
  final String? districtId;
  final String? areaId;
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Branch({
    required this.id,
    required this.churchId,
    required this.name,
    required this.location,
    required this.pastorId,
    this.organizationId,
    this.regionId,
    this.districtId,
    this.areaId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'name': name,
        'location': location,
        'pastorId': pastorId,
        'organizationId': organizationId,
        'regionId': regionId,
        'districtId': districtId,
        'areaId': areaId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Branch.fromMap(Map<dynamic, dynamic> map) => Branch(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        name: map['name'] as String,
        location: (map['location'] as String?) ?? '',
        pastorId: (map['pastorId'] as String?) ?? '',
        organizationId: map['organizationId'] as String?,
        regionId: map['regionId'] as String?,
        districtId: map['districtId'] as String?,
        areaId: map['areaId'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : null,
      );

  Branch copyWith({
    String? name,
    String? location,
    String? pastorId,
    String? organizationId,
    String? regionId,
    String? districtId,
    String? areaId,
  }) =>
      Branch(
        id: id,
        churchId: churchId,
        name: name ?? this.name,
        location: location ?? this.location,
        pastorId: pastorId ?? this.pastorId,
        organizationId: organizationId ?? this.organizationId,
        regionId: regionId ?? this.regionId,
        districtId: districtId ?? this.districtId,
        areaId: areaId ?? this.areaId,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
