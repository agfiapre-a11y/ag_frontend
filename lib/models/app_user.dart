class AppUser {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String role;
  final String churchId;
  final String branchId;
  final String departmentId;
  final String phone;

  // Classification fields for auto-assignment to movements
  final DateTime? dateOfBirth;
  final String gender;
  final String maritalStatus;
  final bool isEmployed;
  final String movement;

  // Hierarchical fields for multi-tenant support
  final String? organizationId;
  final String? regionId;
  final String? districtId;
  final String? areaId;
  
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.churchId,
    required this.branchId,
    this.departmentId = '',
    required this.phone,
    this.dateOfBirth,
    this.gender = 'male',
    this.maritalStatus = 'single',
    this.isEmployed = false,
    this.movement = '',
    this.organizationId,
    this.regionId,
    this.districtId,
    this.areaId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'role': role,
        'churchId': churchId,
        'branchId': branchId,
        'departmentId': departmentId,
        'phone': phone,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'maritalStatus': maritalStatus,
        'isEmployed': isEmployed,
        'movement': movement,
        'organizationId': organizationId,
        'regionId': regionId,
        'districtId': districtId,
        'areaId': areaId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  /// Sync-safe map that excludes sensitive fields (passwordHash).
  /// Used when enqueuing changes for Supabase sync to prevent
  /// leaking password hashes to the cloud (UK GDPR Art. 5(1)(f)).
  Map<String, dynamic> toSyncMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'churchId': churchId,
        'branchId': branchId,
        'departmentId': departmentId,
        'phone': phone,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'maritalStatus': maritalStatus,
        'isEmployed': isEmployed,
        'movement': movement,
        'organizationId': organizationId,
        'regionId': regionId,
        'districtId': districtId,
        'areaId': areaId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory AppUser.fromMap(Map<dynamic, dynamic> map) => AppUser(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        passwordHash: (map['passwordHash'] as String?) ?? '',
        role: map['role'] as String,
        churchId: (map['churchId'] as String?) ?? '',
        branchId: (map['branchId'] as String?) ?? '',
        departmentId: (map['departmentId'] as String?) ?? '',
        phone: (map['phone'] as String?) ?? '',
        dateOfBirth: map['dateOfBirth'] != null
            ? DateTime.parse(map['dateOfBirth'] as String)
            : null,
        gender: (map['gender'] as String?) ?? 'male',
        maritalStatus: (map['maritalStatus'] as String?) ?? 'single',
        isEmployed: (map['isEmployed'] as bool?) ?? false,
        movement: (map['movement'] as String?) ?? '',
        organizationId: map['organizationId'] as String?,
        regionId: map['regionId'] as String?,
        districtId: map['districtId'] as String?,
        areaId: map['areaId'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : null,
      );

  AppUser copyWith({
    String? name,
    String? email,
    String? passwordHash,
    String? role,
    String? churchId,
    String? branchId,
    String? departmentId,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? maritalStatus,
    bool? isEmployed,
    String? movement,
    String? organizationId,
    String? regionId,
    String? districtId,
    String? areaId,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        role: role ?? this.role,
        churchId: churchId ?? this.churchId,
        branchId: branchId ?? this.branchId,
        departmentId: departmentId ?? this.departmentId,
        phone: phone ?? this.phone,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        isEmployed: isEmployed ?? this.isEmployed,
        movement: movement ?? this.movement,
        organizationId: organizationId ?? this.organizationId,
        regionId: regionId ?? this.regionId,
        districtId: districtId ?? this.districtId,
        areaId: areaId ?? this.areaId,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
