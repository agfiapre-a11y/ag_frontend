import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/organization.dart';
import '../models/region.dart';
import '../models/district.dart';
import '../models/area.dart';
import '../models/app_user.dart';
import '../core/constants.dart';
import 'local_db.dart';
import 'auth_service.dart';

class SeedHierarchicalData {
  static const _uuid = Uuid();

  /// Seed complete hierarchical structure for testing
  /// Creates: 1 Organization -> 2 Regions -> 4 Districts -> 8 Areas
  static Future<void> seedCompleteHierarchy() async {
    debugPrint('=== SEEDING HIERARCHICAL DATA ===\n');

    // Create Organization
    final orgId = _uuid.v4();
    final org = Organization(
      id: orgId,
      name: 'Paradise Assemblies of God',
      description: 'National church organization',
      adminId: '',
      address: '123 Church Street, Accra, Ghana',
      phone: '+233 20 123 4567',
      email: 'info@paradiseag.com',
      website: 'https://paradiseag.com',
      createdAt: DateTime.now(),
    );
    await LocalDb.saveOrganization(org);
    debugPrint('✓ Created Organization: ${org.name}');

    // Create 2 Regions
    final region1Id = _uuid.v4();
    final region2Id = _uuid.v4();
    
    final region1 = Region(
      id: region1Id,
      name: 'Greater Accra Region',
      organizationId: orgId,
      adminId: '',
      description: 'Greater Accra Regional oversight',
      address: 'Accra, Ghana',
      phone: '+233 30 123 4567',
      email: 'accra@paradiseag.com',
      createdAt: DateTime.now(),
    );
    await LocalDb.saveRegion(region1);
    debugPrint('✓ Created Region: ${region1.name}');

    final region2 = Region(
      id: region2Id,
      name: 'Ashanti Region',
      organizationId: orgId,
      adminId: '',
      description: 'Ashanti Regional oversight',
      address: 'Kumasi, Ghana',
      phone: '+233 32 123 4567',
      email: 'ashanti@paradiseag.com',
      createdAt: DateTime.now(),
    );
    await LocalDb.saveRegion(region2);
    debugPrint('✓ Created Region: ${region2.name}');

    // Create 4 Districts (2 per region)
    final district1Id = _uuid.v4();
    final district2Id = _uuid.v4();
    final district3Id = _uuid.v4();
    final district4Id = _uuid.v4();

    final district1 = District(
      id: district1Id,
      name: 'Accra Central District',
      regionId: region1Id,
      adminId: '',
      description: 'Central Accra district',
      address: 'Accra Central',
      phone: '+233 30 111 2222',
      email: 'accra.central@paradiseag.com',
      createdAt: DateTime.now(),
    );
    await LocalDb.saveDistrict(district1);
    debugPrint('✓ Created District: ${district1.name}');

    final district2 = District(
      id: district2Id,
      name: 'Accra East District',
      regionId: region1Id,
      adminId: '',
      description: 'East Accra district',
      address: 'Accra East',
      phone: '+233 30 222 3333',
      email: 'accra.east@paradiseag.com',
      createdAt: DateTime.now(),
    );
    await LocalDb.saveDistrict(district2);
    debugPrint('✓ Created District: ${district2.name}');

    final district3 = District(
      id: district3Id,
      name: 'Kumasi Central District',
      regionId: region2Id,
      adminId: '',
      description: 'Central Kumasi district',
      address: 'Kumasi Central',
      phone: '+233 32 111 2222',
      email: 'kumasi.central@paradiseag.com',
      createdAt: DateTime.now(),
    );
    await LocalDb.saveDistrict(district3);
    debugPrint('✓ Created District: ${district3.name}');

    final district4 = District(
      id: district4Id,
      name: 'Kumasi North District',
      regionId: region2Id,
      adminId: '',
      description: 'North Kumasi district',
      address: 'Kumasi North',
      phone: '+233 32 222 3333',
      email: 'kumasi.north@paradiseag.com',
      createdAt: DateTime.now(),
    );
    await LocalDb.saveDistrict(district4);
    debugPrint('✓ Created District: ${district4.name}');

    // Create 8 Areas (2 per district)
    final areas = <Map<String, dynamic>>[];
    final districtIds = [district1Id, district2Id, district3Id, district4Id];
    final districtNames = ['Accra Central', 'Accra East', 'Kumasi Central', 'Kumasi North'];
    
    for (int i = 0; i < districtIds.length; i++) {
      for (int j = 1; j <= 2; j++) {
        final areaId = _uuid.v4();
        final area = Area(
          id: areaId,
          name: '${districtNames[i]} Area $j',
          districtId: districtIds[i],
          adminId: '',
          description: 'Area within ${districtNames[i]}',
          address: districtNames[i],
          phone: '+233 30 000 000$i$j',
          email: 'area$i$j@paradiseag.com',
          createdAt: DateTime.now(),
        );
        await LocalDb.saveArea(area);
        areas.add({'id': areaId, 'name': area.name, 'districtId': districtIds[i]});
        debugPrint('✓ Created Area: ${area.name}');
      }
    }

    debugPrint('\n=== HIERARCHY SUMMARY ===');
    debugPrint('Organizations: 1');
    debugPrint('Regions: 2');
    debugPrint('Districts: 4');
    debugPrint('Areas: 8');
    debugPrint('\n=== SEEDING COMPLETE ===');
  }

  /// Seed sample users with hierarchical assignments
  static Future<void> seedHierarchicalUsers(String churchId) async {
    debugPrint('\n=== SEEDING HIERARCHICAL USERS ===\n');

    final organizations = LocalDb.getAllOrganizations();
    final regions = LocalDb.getAllRegions();
    final districts = LocalDb.getAllDistricts();
    final areas = LocalDb.getAllAreas();

    if (organizations.isEmpty || regions.isEmpty || districts.isEmpty || areas.isEmpty) {
      debugPrint('Error: Please seed hierarchy first using seedCompleteHierarchy()');
      return;
    }

    final orgId = organizations.first.id;
    final regionId = regions.first.id;
    final districtId = districts.first.id;
    final areaId = areas.first.id;

    // Create Super System Admin
    final superSystemAdmin = AppUser(
      id: _uuid.v4(),
      name: 'System Administrator',
      email: 'sysadmin@paradiseag.com',
      passwordHash: AuthService.hashPassword('password123'),
      role: AppRoles.superSystemAdmin,
      churchId: churchId,
      branchId: '',
      organizationId: orgId,
      phone: '+233 20 000 0001',
      createdAt: DateTime.now(),
    );
    await LocalDb.saveUser(superSystemAdmin);
    debugPrint('✓ Created Super System Admin: ${superSystemAdmin.email}');

    // Create National Admin
    final nationalAdmin = AppUser(
      id: _uuid.v4(),
      name: 'National Administrator',
      email: 'national@paradiseag.com',
      passwordHash: AuthService.hashPassword('password123'),
      role: AppRoles.nationalAdmin,
      churchId: churchId,
      branchId: '',
      organizationId: orgId,
      phone: '+233 20 000 0002',
      createdAt: DateTime.now(),
    );
    await LocalDb.saveUser(nationalAdmin);
    debugPrint('✓ Created National Admin: ${nationalAdmin.email}');

    // Create Regional Admin
    final regionalAdmin = AppUser(
      id: _uuid.v4(),
      name: 'Regional Administrator',
      email: 'regional@paradiseag.com',
      passwordHash: AuthService.hashPassword('password123'),
      role: AppRoles.regionalAdmin,
      churchId: churchId,
      branchId: '',
      organizationId: orgId,
      regionId: regionId,
      phone: '+233 20 000 0003',
      createdAt: DateTime.now(),
    );
    await LocalDb.saveUser(regionalAdmin);
    debugPrint('✓ Created Regional Admin: ${regionalAdmin.email}');

    // Create District Admin
    final districtAdmin = AppUser(
      id: _uuid.v4(),
      name: 'District Administrator',
      email: 'district@paradiseag.com',
      passwordHash: AuthService.hashPassword('password123'),
      role: AppRoles.districtAdmin,
      churchId: churchId,
      branchId: '',
      organizationId: orgId,
      regionId: regionId,
      districtId: districtId,
      phone: '+233 20 000 0004',
      createdAt: DateTime.now(),
    );
    await LocalDb.saveUser(districtAdmin);
    debugPrint('✓ Created District Admin: ${districtAdmin.email}');

    // Create Area Admin
    final areaAdmin = AppUser(
      id: _uuid.v4(),
      name: 'Area Administrator',
      email: 'area@paradiseag.com',
      passwordHash: AuthService.hashPassword('password123'),
      role: AppRoles.areaAdmin,
      churchId: churchId,
      branchId: '',
      organizationId: orgId,
      regionId: regionId,
      districtId: districtId,
      areaId: areaId,
      phone: '+233 20 000 0005',
      createdAt: DateTime.now(),
    );
    await LocalDb.saveUser(areaAdmin);
    debugPrint('✓ Created Area Admin: ${areaAdmin.email}');

    debugPrint('\n=== USER CREDENTIALS ===');
    debugPrint('All users can login with: password123');
    debugPrint('Super System Admin: sysadmin@paradiseag.com');
    debugPrint('National Admin: national@paradiseag.com');
    debugPrint('Regional Admin: regional@paradiseag.com');
    debugPrint('District Admin: district@paradiseag.com');
    debugPrint('Area Admin: area@paradiseag.com');
    debugPrint('\n=== USER SEEDING COMPLETE ===');
  }

  /// Clear all hierarchical data
  static Future<void> clearHierarchicalData() async {
    debugPrint('=== CLEARING HIERARCHICAL DATA ===\n');
    
    await LocalDb.clearAllAreas();
    debugPrint('✓ Cleared Areas');
    
    await LocalDb.clearAllDistricts();
    debugPrint('✓ Cleared Districts');
    
    await LocalDb.clearAllRegions();
    debugPrint('✓ Cleared Regions');
    
    await LocalDb.clearAllOrganizations();
    debugPrint('✓ Cleared Organizations');
    
    debugPrint('\n=== CLEARING COMPLETE ===');
  }
}
