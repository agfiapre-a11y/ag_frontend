class Church {
  final String id;
  final String name;
  final String adminId;
  final String address;
  final String phone;
  final String email;
  final String currency;
  final DateTime createdAt;

  const Church({
    required this.id,
    required this.name,
    required this.adminId,
    required this.address,
    required this.phone,
    required this.email,
    this.currency = 'GH₵',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'adminId': adminId,
        'address': address,
        'phone': phone,
        'email': email,
        'currency': currency,
        'createdAt': createdAt.toIso8601String(),
      };

  Church copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? currency,
  }) =>
      Church(
        id: id,
        adminId: adminId,
        name: name ?? this.name,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        currency: currency ?? this.currency,
        createdAt: createdAt,
      );

  factory Church.fromMap(Map<dynamic, dynamic> map) => Church(
        id: map['id'] as String,
        name: map['name'] as String,
        adminId: map['adminId'] as String,
        address: (map['address'] as String?) ?? '',
        phone: (map['phone'] as String?) ?? '',
        email: (map['email'] as String?) ?? '',
        currency: (map['currency'] as String?) ?? 'GH₵',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
