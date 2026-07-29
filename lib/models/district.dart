class District {
  final String id;
  final String name;
  final String regionId;
  final String adminId;
  final String description;
  final String address;
  final String phone;
  final String email;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const District({
    required this.id,
    required this.name,
    required this.regionId,
    required this.adminId,
    required this.description,
    required this.address,
    required this.phone,
    required this.email,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'regionId': regionId,
        'adminId': adminId,
        'description': description,
        'address': address,
        'phone': phone,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  District copyWith({
    String? name,
    String? description,
    String? address,
    String? phone,
    String? email,
  }) =>
      District(
        id: id,
        name: name ?? this.name,
        regionId: regionId,
        adminId: adminId,
        description: description ?? this.description,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  factory District.fromMap(Map<dynamic, dynamic> map) => District(
        id: map['id'] as String,
        name: map['name'] as String,
        regionId: map['regionId'] as String,
        adminId: map['adminId'] as String,
        description: (map['description'] as String?) ?? '',
        address: (map['address'] as String?) ?? '',
        phone: (map['phone'] as String?) ?? '',
        email: (map['email'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : null,
      );
}
