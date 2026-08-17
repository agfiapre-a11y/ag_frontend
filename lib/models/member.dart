class Member {
  final String id;
  final String churchId;
  final String branchId;
  final String departmentId;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String gender;
  final DateTime? dateOfBirth;
  final String maritalStatus;
  final bool isEmployed;
  final String movement;
  final DateTime membershipDate;
  final bool isActive;

  // Hierarchical fields for multi-tenant support
  final String? organizationId;
  final String? regionId;
  final String? districtId;
  final String? areaId;

  const Member({
    required this.id,
    required this.churchId,
    required this.branchId,
    this.departmentId = '',
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.gender,
    this.dateOfBirth,
    this.maritalStatus = 'single',
    this.isEmployed = false,
    this.movement = '',
    required this.membershipDate,
    required this.isActive,
    this.organizationId,
    this.regionId,
    this.districtId,
    this.areaId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'departmentId': departmentId,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'gender': gender,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'maritalStatus': maritalStatus,
        'isEmployed': isEmployed,
        'movement': movement,
        'membershipDate': membershipDate.toIso8601String(),
        'isActive': isActive,
        'organizationId': organizationId,
        'regionId': regionId,
        'districtId': districtId,
        'areaId': areaId,
      };

  factory Member.fromMap(Map<dynamic, dynamic> map) => Member(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: map['branchId'] as String,
        departmentId: (map['departmentId'] as String?) ?? '',
        name: map['name'] as String,
        email: (map['email'] as String?) ?? '',
        phone: (map['phone'] as String?) ?? '',
        address: (map['address'] as String?) ?? '',
        gender: (map['gender'] as String?) ?? 'male',
        dateOfBirth: map['dateOfBirth'] != null
            ? DateTime.parse(map['dateOfBirth'] as String)
            : null,
        maritalStatus: (map['maritalStatus'] as String?) ?? 'single',
        isEmployed: (map['isEmployed'] as bool?) ?? false,
        movement: (map['movement'] as String?) ?? '',
        membershipDate: DateTime.parse(map['membershipDate'] as String),
        isActive: (map['isActive'] as bool?) ?? true,
        organizationId: map['organizationId'] as String?,
        regionId: map['regionId'] as String?,
        districtId: map['districtId'] as String?,
        areaId: map['areaId'] as String?,
      );

  /// Creates a Member from a NestJS backend API response.
  /// Backend uses snake_case + firstName/lastName; app uses camelCase + name.
  factory Member.fromBackend(Map<dynamic, dynamic> map) {
    final firstName = (map['firstName'] as String?) ?? '';
    final lastName = (map['lastName'] as String?) ?? '';
    return Member(
      id: map['id'] as String,
      churchId: (map['tenantId'] as String?) ?? '',
      branchId: '',
      departmentId: '',
      name: '$firstName $lastName'.trim(),
      email: (map['email'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      gender: (map['gender'] as String?) ?? 'male',
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'].toString())
          : null,
      maritalStatus: (map['maritalStatus'] as String?) ?? 'single',
      isEmployed: (map['isEmployed'] as bool?) ?? false,
      movement: '',
      membershipDate: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isActive: (map['isActive'] as bool?) ?? true,
    );
  }

  Member copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? gender,
    DateTime? dateOfBirth,
    String? maritalStatus,
    bool? isEmployed,
    String? movement,
    DateTime? membershipDate,
    bool? isActive,
    String? branchId,
    String? departmentId,
    String? organizationId,
    String? regionId,
    String? districtId,
    String? areaId,
  }) =>
      Member(
        id: id,
        churchId: churchId,
        branchId: branchId ?? this.branchId,
        departmentId: departmentId ?? this.departmentId,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        isEmployed: isEmployed ?? this.isEmployed,
        movement: movement ?? this.movement,
        membershipDate: membershipDate ?? this.membershipDate,
        isActive: isActive ?? this.isActive,
        organizationId: organizationId ?? this.organizationId,
        regionId: regionId ?? this.regionId,
        districtId: districtId ?? this.districtId,
        areaId: areaId ?? this.areaId,
      );
}
