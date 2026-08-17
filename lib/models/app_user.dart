class AppUser {
  final String id;
  final String name;
  final String email;
  final String passwordHash;

  /// All roles assigned to this user. A user can have multiple roles
  /// (e.g. financeOfficer + churchSecretary) and switch between them
  /// at runtime via [activeRole].
  final List<String> roles;

  /// The currently active role — must be one of [roles].
  /// Used for routing, nav filtering, and access control.
  final String activeRole;

  /// Backward-compatible getter: returns the activeRole.
  /// Code that hasn't been migrated to multi-role can still use `user.role`.
  String get role => activeRole;

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
    required this.roles,
    required this.activeRole,
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
        'roles': roles,
        'activeRole': activeRole,
        // Keep 'role' for backward compatibility with older clients
        'role': activeRole,
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
        'roles': roles,
        'activeRole': activeRole,
        // Keep 'role' for backward compatibility with older clients
        'role': activeRole,
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

  factory AppUser.fromMap(Map<dynamic, dynamic> map) {
    // Parse roles: support both new 'roles' array and legacy 'role' string
    List<String> parsedRoles;
    if (map['roles'] != null) {
      parsedRoles = (map['roles'] as List).map((e) => e.toString()).toList();
    } else if (map['role'] != null) {
      // Legacy: single role string → migrate to array
      parsedRoles = [map['role'] as String];
    } else {
      parsedRoles = [];
    }

    // activeRole: use explicit field, or fall back to first role, or legacy 'role'
    String parsedActiveRole;
    if (map['activeRole'] != null) {
      parsedActiveRole = map['activeRole'] as String;
    } else if (parsedRoles.isNotEmpty) {
      parsedActiveRole = parsedRoles.first;
    } else if (map['role'] != null) {
      parsedActiveRole = map['role'] as String;
    } else {
      parsedActiveRole = '';
    }

    // Ensure activeRole is in roles (data integrity)
    if (parsedRoles.isNotEmpty && !parsedRoles.contains(parsedActiveRole)) {
      parsedActiveRole = parsedRoles.first;
    }

    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      passwordHash: (map['passwordHash'] as String?) ?? '',
      roles: parsedRoles,
      activeRole: parsedActiveRole,
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
  }

  /// Creates an AppUser from a NestJS backend API response.
  /// Backend uses snake_case; app uses camelCase.
  factory AppUser.fromBackend(Map<dynamic, dynamic> map) {
    // Parse roles: backend 'roles' is a text array, 'role' is the legacy single role
    List<String> parsedRoles;
    if (map['roles'] is List) {
      parsedRoles = List<String>.from(map['roles'] as List);
    } else if (map['role'] != null) {
      parsedRoles = [map['role'] as String];
    } else {
      parsedRoles = [];
    }

    String parsedActiveRole;
    if (map['activeRole'] != null) {
      parsedActiveRole = map['activeRole'] as String;
    } else if (parsedRoles.isNotEmpty) {
      parsedActiveRole = parsedRoles.first;
    } else if (map['role'] != null) {
      parsedActiveRole = map['role'] as String;
    } else {
      parsedActiveRole = '';
    }

    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      passwordHash: '',
      roles: parsedRoles,
      activeRole: parsedActiveRole,
      churchId: (map['tenantId'] as String?) ?? '',
      branchId: '',
      phone: '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? passwordHash,
    List<String>? roles,
    String? activeRole,
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
        roles: roles ?? this.roles,
        activeRole: activeRole ?? this.activeRole,
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

  /// Returns true if the user has the given role in their roles array.
  bool hasRole(String role) => roles.contains(role);

  /// Returns true if the user has any of the given roles.
  bool hasAnyRole(List<String> rolesToCheck) =>
      rolesToCheck.any((r) => roles.contains(r));
}
