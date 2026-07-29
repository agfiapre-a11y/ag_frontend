class Organization {
  final String id;
  final String name;
  final String description;
  final String adminId;
  final String address;
  final String phone;
  final String email;
  final String website;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Organization({
    required this.id,
    required this.name,
    required this.description,
    required this.adminId,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'adminId': adminId,
        'address': address,
        'phone': phone,
        'email': email,
        'website': website,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Organization copyWith({
    String? name,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? website,
  }) =>
      Organization(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        adminId: adminId,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        website: website ?? this.website,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  factory Organization.fromMap(Map<dynamic, dynamic> map) => Organization(
        id: map['id'] as String,
        name: map['name'] as String,
        description: (map['description'] as String?) ?? '',
        adminId: map['adminId'] as String,
        address: (map['address'] as String?) ?? '',
        phone: (map['phone'] as String?) ?? '',
        email: (map['email'] as String?) ?? '',
        website: (map['website'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : null,
      );
}
