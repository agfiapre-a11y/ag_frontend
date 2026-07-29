import 'package:uuid/uuid.dart';
import '../models/app_user.dart';
import '../models/attendance_record.dart';
import '../models/branch.dart';
import '../models/department.dart';
import '../models/event.dart';
import '../models/member.dart';
import '../models/sermon.dart';
import '../models/transaction.dart';
import '../core/constants.dart';
import 'local_db.dart';
import 'auth_service.dart';
import 'tenant_context.dart';

const _uuid = Uuid();

class SeedDataService {
  static Future<void> seedTrainingData(String churchId) async {
    final church = LocalDb.getChurch();
    if (church == null) return;
    if (!TenantContext.isActive) {
      TenantContext.setActiveChurch(church.id);
    }

    // Seed branches
    final branch1Id = _uuid.v4();
    final branch2Id = _uuid.v4();
    final branch3Id = _uuid.v4();

    await _seedBranches(churchId, [branch1Id, branch2Id, branch3Id]);

    // Seed users (pastors for each branch)
    final pastor1Id = _uuid.v4();
    final pastor2Id = _uuid.v4();
    final pastor3Id = _uuid.v4();
    final accountantId = _uuid.v4();
    final deptLeaderId = _uuid.v4();

    await _seedUsers(
      churchId,
      [
        (pastor1Id, branch1Id, AppRoles.pastor, 'Rev. John Mensah'),
        (pastor2Id, branch2Id, AppRoles.pastor, 'Rev. Sarah Osei'),
        (pastor3Id, branch3Id, AppRoles.pastor, 'Rev. Emmanuel Kofi'),
        (accountantId, '', AppRoles.accountant, 'Grace Amoah'),
        (deptLeaderId, branch1Id, AppRoles.deptLeader, 'Daniel Addo'),
      ],
    );

    // Seed departments
    final dept1Id = _uuid.v4();
    final dept2Id = _uuid.v4();
    final dept3Id = _uuid.v4();

    await _seedDepartments(
      churchId,
      [
        (dept1Id, branch1Id, 'Choir', 'Music ministry'),
        (dept2Id, branch1Id, 'Ushers', 'Hospitality team'),
        (dept3Id, branch2Id, 'Youth Ministry', 'Young adults fellowship'),
      ],
    );

    // Seed members
    final memberIds = await _seedMembers(
      churchId,
      branch1Id,
      branch2Id,
      branch3Id,
      dept1Id,
      dept2Id,
      dept3Id,
    );

    // Seed attendance records
    await _seedAttendance(churchId, branch1Id, branch2Id, branch3Id, memberIds);

    // Seed finance transactions
    await _seedFinance(churchId, branch1Id, branch2Id, branch3Id, pastor1Id, accountantId);

    // Seed sermons
    await _seedSermons(churchId, branch1Id, branch2Id, branch3Id, pastor1Id, pastor2Id, pastor3Id);

    // Seed events
    await _seedEvents(churchId, branch1Id, branch2Id, branch3Id);
  }

  static Future<void> deleteTrainingData(String churchId) async {
    // Delete all data except the church itself and super admin
    await LocalDb.clearAllAttendanceRecords();
    await LocalDb.clearAllTransactions();
    await LocalDb.clearAllSermons();
    await LocalDb.clearAllEvents();
    await LocalDb.clearAllMembers();
    await LocalDb.clearAllDepartments();
    await LocalDb.clearAllBranches();
    
    // Keep only super admin user
    final allUsers = LocalDb.getAllUsers();
    for (final user in allUsers) {
      if (user.role != AppRoles.superAdmin) {
        await LocalDb.deleteUser(user.id);
      }
    }
  }

  static Future<void> _seedBranches(String churchId, List<String> branchIds) async {
    final branches = [
      Branch(
        id: branchIds[0],
        churchId: churchId,
        name: 'Main Branch - Accra',
        location: 'Osu, Accra',
        pastorId: '',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
      ),
      Branch(
        id: branchIds[1],
        churchId: churchId,
        name: 'Kumasi Branch',
        location: 'Kumasi, Ashanti Region',
        pastorId: '',
        createdAt: DateTime.now().subtract(const Duration(days: 300)),
      ),
      Branch(
        id: branchIds[2],
        churchId: churchId,
        name: 'Tamale Branch',
        location: 'Tamale, Northern Region',
        pastorId: '',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
    ];

    for (final branch in branches) {
      await LocalDb.saveBranch(branch);
    }
  }

  static Future<void> _seedUsers(
    String churchId,
    List<(String id, String branchId, String role, String name)> users,
  ) async {
    for (final (id, branchId, role, name) in users) {
      final user = AppUser(
        id: id,
        churchId: churchId,
        branchId: branchId,
        departmentId: role == AppRoles.deptLeader ? '' : '',
        name: name,
        email: '${name.toLowerCase().replaceAll(' ', '.')}@paradiseag.com',
        passwordHash: AuthService.hashPassword('Password123'),
        phone: '+233${_randomPhoneNumber()}',
        role: role,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      );
      await LocalDb.saveUser(user);
    }
  }

  static Future<void> _seedDepartments(
    String churchId,
    List<(String id, String branchId, String name, String description)> departments,
  ) async {
    for (final (id, branchId, name, description) in departments) {
      final dept = Department(
        id: id,
        churchId: churchId,
        branchId: branchId,
        name: name,
        description: description,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
      );
      await LocalDb.saveDepartment(dept);
    }
  }

  static Future<List<String>> _seedMembers(
    String churchId,
    String branch1Id,
    String branch2Id,
    String branch3Id,
    String dept1Id,
    String dept2Id,
    String dept3Id,
  ) async {
    final members = [
      // Branch 1 members
      _createMember(churchId, branch1Id, dept1Id, 'Kwame Asante', '+233240123456', 'Male'),
      _createMember(churchId, branch1Id, dept1Id, 'Abena Mensah', '+233241234567', 'Female'),
      _createMember(churchId, branch1Id, dept2Id, 'Kojo Ofori', '+233242345678', 'Male'),
      _createMember(churchId, branch1Id, dept2Id, 'Akua Frempong', '+233243456789', 'Female'),
      _createMember(churchId, branch1Id, '', 'Kofi Annan', '+233244567890', 'Male'),
      _createMember(churchId, branch1Id, '', 'Ama Boateng', '+233245678901', 'Female'),
      _createMember(churchId, branch1Id, dept1Id, 'Emmanuel Agyeman', '+233246789012', 'Male'),
      _createMember(churchId, branch1Id, dept1Id, 'Grace Osei', '+233247890123', 'Female'),
      // Branch 2 members
      _createMember(churchId, branch2Id, dept3Id, 'Yaw Adjei', '+233250123456', 'Male'),
      _createMember(churchId, branch2Id, dept3Id, 'Efua Kwarteng', '+233251234567', 'Female'),
      _createMember(churchId, branch2Id, '', 'Kwabena Darko', '+233252345678', 'Male'),
      _createMember(churchId, branch2Id, '', 'Yaa Owusu', '+233253456789', 'Female'),
      // Branch 3 members
      _createMember(churchId, branch3Id, '', 'Ibrahim Mohammed', '+233260123456', 'Male'),
      _createMember(churchId, branch3Id, '', 'Fatima Alhassan', '+233261234567', 'Female'),
    ];

    final memberIds = <String>[];
    for (final member in members) {
      await LocalDb.saveMember(member);
      memberIds.add(member.id);
    }
    return memberIds;
  }

  static Member _createMember(
    String churchId,
    String branchId,
    String departmentId,
    String name,
    String phone,
    String gender,
  ) {
    return Member(
      id: _uuid.v4(),
      churchId: churchId,
      branchId: branchId,
      departmentId: departmentId,
      name: name,
      email: '${name.toLowerCase().replaceAll(' ', '.')}@gmail.com',
      phone: phone,
      address: 'P.O. Box ${_randomNumber(1000, 9999)}, Ghana',
      gender: gender,
      dateOfBirth: DateTime(1980 + _randomNumber(18, 45), _randomNumber(1, 12), _randomNumber(1, 28)),
      membershipDate: DateTime.now().subtract(Duration(days: _randomNumber(30, 365))),
      isActive: true,
    );
  }

  static Future<void> _seedAttendance(
    String churchId,
    String branch1Id,
    String branch2Id,
    String branch3Id,
    List<String> memberIds,
  ) async {
    final now = DateTime.now();
    
    // Create attendance for the last 4 Sundays
    for (int i = 0; i < 4; i++) {
      final date = now.subtract(Duration(days: (i * 7) + (now.weekday - DateTime.sunday)));
      
      // Branch 1 attendance
      await LocalDb.saveAttendanceRecord(AttendanceRecord(
        id: _uuid.v4(),
        churchId: churchId,
        branchId: branch1Id,
        serviceType: ServiceTypes.sundayService,
        date: date,
        presentMemberIds: memberIds.take(_randomNumber(5, 8)).toList(),
        recordedById: '',
        createdAt: date,
      ));

      // Branch 2 attendance
      await LocalDb.saveAttendanceRecord(AttendanceRecord(
        id: _uuid.v4(),
        churchId: churchId,
        branchId: branch2Id,
        serviceType: ServiceTypes.sundayService,
        date: date,
        presentMemberIds: memberIds.skip(8).take(_randomNumber(3, 4)).toList(),
        recordedById: '',
        createdAt: date,
      ));

      // Branch 3 attendance
      await LocalDb.saveAttendanceRecord(AttendanceRecord(
        id: _uuid.v4(),
        churchId: churchId,
        branchId: branch3Id,
        serviceType: ServiceTypes.sundayService,
        date: date,
        presentMemberIds: memberIds.skip(12).take(_randomNumber(1, 2)).toList(),
        recordedById: '',
        createdAt: date,
      ));
    }

    // Mid-week service attendance
    final midweekDate = now.subtract(Duration(days: now.weekday - DateTime.wednesday));
    await LocalDb.saveAttendanceRecord(AttendanceRecord(
      id: _uuid.v4(),
      churchId: churchId,
      branchId: branch1Id,
      serviceType: ServiceTypes.bibleStudy,
      date: midweekDate,
      presentMemberIds: memberIds.take(_randomNumber(4, 6)).toList(),
      recordedById: '',
      createdAt: midweekDate,
    ));
  }

  static Future<void> _seedFinance(
    String churchId,
    String branch1Id,
    String branch2Id,
    String branch3Id,
    String pastor1Id,
    String accountantId,
  ) async {
    final now = DateTime.now();
    final branches = [branch1Id, branch2Id, branch3Id];

    // Create transactions for the last 3 months
    for (int month = 0; month < 3; month++) {
      final monthDate = DateTime(now.year, now.month - month, 1);
      
      for (final branchId in branches) {
        // Income transactions
        await LocalDb.saveTransaction(FinanceTransaction(
          id: _uuid.v4(),
          churchId: churchId,
          branchId: branchId,
          type: TransactionType.income,
          category: IncomeCategories.tithe,
          amount: _randomAmount(500, 2000),
          description: 'Sunday tithe collection',
          date: monthDate.add(Duration(days: _randomNumber(1, 28))),
          recordedById: accountantId,
          createdAt: monthDate,
        ));

        await LocalDb.saveTransaction(FinanceTransaction(
          id: _uuid.v4(),
          churchId: churchId,
          branchId: branchId,
          type: TransactionType.income,
          category: IncomeCategories.offering,
          amount: _randomAmount(300, 1500),
          description: 'Special offering',
          date: monthDate.add(Duration(days: _randomNumber(1, 28))),
          recordedById: accountantId,
          createdAt: monthDate,
        ));

        await LocalDb.saveTransaction(FinanceTransaction(
          id: _uuid.v4(),
          churchId: churchId,
          branchId: branchId,
          type: TransactionType.income,
          category: IncomeCategories.donation,
          amount: _randomAmount(100, 500),
          description: 'Special donation',
          date: monthDate.add(Duration(days: _randomNumber(1, 28))),
          recordedById: accountantId,
          createdAt: monthDate,
        ));

        // Expense transactions
        await LocalDb.saveTransaction(FinanceTransaction(
          id: _uuid.v4(),
          churchId: churchId,
          branchId: branchId,
          type: TransactionType.expense,
          category: ExpenseCategories.utilities,
          amount: _randomAmount(200, 500),
          description: 'Electricity and water bills',
          date: monthDate.add(Duration(days: _randomNumber(1, 28))),
          recordedById: accountantId,
          createdAt: monthDate,
        ));

        await LocalDb.saveTransaction(FinanceTransaction(
          id: _uuid.v4(),
          churchId: churchId,
          branchId: branchId,
          type: TransactionType.expense,
          category: ExpenseCategories.maintenance,
          amount: _randomAmount(100, 400),
          description: 'Church maintenance',
          date: monthDate.add(Duration(days: _randomNumber(1, 28))),
          recordedById: accountantId,
          createdAt: monthDate,
        ));
      }
    }
  }

  static Future<void> _seedSermons(
    String churchId,
    String branch1Id,
    String branch2Id,
    String branch3Id,
    String pastor1Id,
    String pastor2Id,
    String pastor3Id,
  ) async {
    final sermons = [
      (branch1Id, pastor1Id, 'Walking in Faith', 'Learning to trust God in every season of life'),
      (branch1Id, pastor1Id, 'The Power of Prayer', 'Understanding the importance of prayer in Christian life'),
      (branch2Id, pastor2Id, 'Love Your Neighbor', 'Practical ways to show love to others'),
      (branch2Id, pastor2Id, 'Building Strong Families', 'Biblical principles for family life'),
      (branch3Id, pastor3Id, 'Hope in Difficult Times', 'Finding hope when life is hard'),
      (branch3Id, pastor3Id, 'The Great Commission', 'Our mandate to spread the gospel'),
    ];

    final now = DateTime.now();
    for (int i = 0; i < sermons.length; i++) {
      final (branchId, pastorId, title, summary) = sermons[i];
      final sermon = Sermon(
        id: _uuid.v4(),
        churchId: churchId,
        branchId: branchId,
        title: title,
        speaker: 'Pastor',
        series: '',
        scriptureReference: _randomScripture(),
        notes: 'Key points from the sermon on $title. $summary',
        audioUrl: '',
        videoUrl: '',
        serviceType: ServiceTypes.sundayService,
        date: now.subtract(Duration(days: i * 14)),
        recordedById: pastorId,
        createdAt: now.subtract(Duration(days: i * 14)),
      );
      await LocalDb.saveSermon(sermon);
    }
  }

  static Future<void> _seedEvents(
    String churchId,
    String branch1Id,
    String branch2Id,
    String branch3Id,
  ) async {
    final now = DateTime.now();
    final events = [
      ChurchEvent(
        id: _uuid.v4(),
        churchId: churchId,
        branchId: branch1Id,
        departmentId: '',
        title: 'Easter Convention',
        description: 'Annual Easter celebration with special speakers and worship',
        category: EventCategory.conference,
        location: 'Main Auditorium',
        organizer: 'Church Council',
        startDate: now.add(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 33)),
        isAllDay: true,
        recordedById: '',
        createdAt: now,
      ),
      ChurchEvent(
        id: _uuid.v4(),
        churchId: churchId,
        branchId: branch2Id,
        departmentId: '',
        title: 'Youth Retreat',
        description: 'Youth fellowship retreat at the mountains',
        category: EventCategory.youthEvent,
        location: 'Kumasi Retreat Center',
        organizer: 'Youth Ministry',
        startDate: now.add(const Duration(days: 45)),
        endDate: now.add(const Duration(days: 47)),
        isAllDay: true,
        recordedById: '',
        createdAt: now,
      ),
      ChurchEvent(
        id: _uuid.v4(),
        churchId: churchId,
        branchId: branch1Id,
        departmentId: '',
        title: 'Christmas Carol Service',
        description: 'Special Christmas service with carols and drama',
        category: EventCategory.specialService,
        location: 'Main Sanctuary',
        organizer: 'Music Ministry',
        startDate: now.subtract(const Duration(days: 180)),
        endDate: now.subtract(const Duration(days: 180)),
        isAllDay: false,
        recordedById: '',
        createdAt: now.subtract(const Duration(days: 200)),
      ),
      ChurchEvent(
        id: _uuid.v4(),
        churchId: churchId,
        branchId: branch3Id,
        departmentId: '',
        title: 'Community Outreach',
        description: 'Feeding program for the homeless',
        category: EventCategory.outreach,
        location: 'Tamale City Center',
        organizer: 'Social Services',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.subtract(const Duration(days: 30)),
        isAllDay: false,
        recordedById: '',
        createdAt: now.subtract(const Duration(days: 45)),
      ),
    ];

    for (final event in events) {
      await LocalDb.saveEvent(event);
    }
  }

  static String _randomPhoneNumber() {
    return '20${_randomNumber(10000000, 99999999)}';
  }

  static int _randomNumber(int min, int max) {
    return min + (DateTime.now().millisecondsSinceEpoch % (max - min + 1));
  }

  static double _randomAmount(double min, double max) {
    return min + (DateTime.now().millisecondsSinceEpoch % (max - min + 1)).toDouble();
  }

  static String _randomScripture() {
    final scriptures = [
      'John 3:16',
      'Romans 8:28',
      'Philippians 4:13',
      'Jeremiah 29:11',
      'Psalm 23:1',
      'Matthew 6:33',
      'Proverbs 3:5-6',
      'Isaiah 40:31',
    ];
    return scriptures[DateTime.now().millisecondsSinceEpoch % scriptures.length];
  }
}
