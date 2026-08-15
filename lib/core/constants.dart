import 'package:flutter/material.dart';

class AppColors {
  // Improved Cosmic Theme colors - Brighter, more balanced
  static const background = Color(0xFF0F172A);    // Lighter navy (Slate 900)
  static const backgroundLight = Color(0xFF1E293B); // Lighter surface (Slate 800)
  static const primary = Color(0xFF1E40AF);       // Vibrant navy blue (Blue 800)
  static const primaryDark = Color(0xFF1E3A8A);   // Darker navy (Blue 900)
  static const primaryLight = Color(0xFF3B82F6);  // Lighter vibrant blue (Blue 500)
  static const secondary = Color(0xFFD6B25E);     // Stellar Gold
  static const accent = Color(0xFF38BDF8);        // Stellar Cyan
  static const surface = Color(0xFF1E293B);        // Surface (Slate 800)
  static const surfaceLight = Color(0xFF334155);   // Elevated surface (Slate 700)
  static const surfaceLighter = Color(0xFF475569); // Higher elevation (Slate 600)
  static const textPrimary = Color(0xFFF8FAFC);   // Text (Slate 50)
  static const textSecondary = Color(0xFFCBD5E1); // Secondary Text (Slate 300) - brighter
  static const textTertiary = Color(0xFF94A3B8);  // Tertiary Text (Slate 400)
  static const success = Color(0xFF10B981);      // Emerald Green
  static const error = Color(0xFFEF4444);        // Red
  static const warning = Color(0xFFF59E0B);       // Amber
  static const cardBorder = Color(0xFF334155);    // Lighter border (Slate 700)

  // ParadiseTheme colors - Improved palette
  static const midnightBlue = Color(0xFF1E40AF);  // Vibrant navy
  static const royalBlue = Color(0xFF3B82F6);     // Lighter vibrant blue
  static const skyBlue = Color(0xFF38BDF8);      // Stellar Cyan
  static const sunriseGold = Color(0xFFD6B25E);   // Stellar Gold
  static const lightGold = Color(0xFFE5C07B);     // Light Stellar Gold
  static const paradiseBackground = Color(0xFF0F172A); // Lighter navy
  static const paradiseCardColor = Color(0xFF1E293B); // Surface
  static const paradiseTextPrimary = Color(0xFFF8FAFC); // Text
  static const paradiseTextSecondary = Color(0xFFCBD5E1); // Brighter secondary text
  static const paradiseGray = Color(0xFF64748B);  // Slate Gray

  // Dashboard Theme - Charcoal & Champagne Palette
  static const dashboardBackground = Color(0xFF1A1D23);      // Soft charcoal
  static const dashboardBackgroundLight = Color(0xFF252932); // Lighter charcoal
  static const dashboardCard = Color(0xFF2A2E38);             // Rich graphite
  static const dashboardCardLight = Color(0xFF353A45);        // Lighter graphite
  static const dashboardBorder = Color(0xFF3E4450);           // Muted slate
  static const champagneGold = Color(0xFFD4AF37);             // Champagne gold
  static const champagneLight = Color(0xFFE5C158);            // Light champagne
  static const warmWhite = Color(0xFFF5F5F0);                 // Warm white
  static const warmGray = Color(0xFFB8B8B0);                  // Warm gray
  static const warmGrayLight = Color(0xFF8A8A80);              // Lighter warm gray
  static const dashboardBlue = Color(0xFF3B82F6);             // Interactive blue
  static const dashboardBlueLight = Color(0xFF60A5FA);        // Light interactive blue

  // Emerald & Ivory Theme - Enterprise Design
  // Sidebar Colors
  static const emeraldDeep = Color(0xFF0F2E27);              // Deep Emerald
  static const emeraldForest = Color(0xFF182A24);             // Forest Slate
  static const emeraldLight = Color(0xFF1A3D35);              // Light Emerald (active state)
  
  // Main Background
  static const ivorySoft = Color(0xFFF5F3E8);                 // Soft Ivory
  static const ivoryLight = Color(0xFFF7F6F2);                // Light Ivory
  
  // Card Colors
  static const cardWhite = Color(0xFFFFFFFF);                  // White
  static const emeraldCardBorder = Color(0xFFE7E5DF);         // Emerald Card Border
  
  // Accent Colors
  static const goldWarm = Color(0xFFD4AF37);                  // Warm Gold
  static const goldLight = Color(0xFFE5C158);                 // Light Gold
  
  // Status Colors
  static const successGreen = Color(0xFF22C55E);              // Success
  static const warningAmber = Color(0xFFF59E0B);              // Warning
  static const errorRed = Color(0xFFEF4444);                  // Error
  static const infoBlue = Color(0xFF3B82F6);                 // Information
  
  // Text Colors (Emerald Theme)
  static const emeraldTextPrimary = Color(0xFF1E293B);       // Primary Text
  static const emeraldTextSecondary = Color(0xFF64748B);     // Secondary Text
  static const emeraldTextMuted = Color(0xFF94A3B8);         // Muted Text
  
  // Border Colors
  static const borderDefault = Color(0xFFE5E7EB);             // Default Border
  
  // Spacing Constants
  static const spacing8 = 8.0;
  static const spacing12 = 12.0;
  static const spacing16 = 16.0;
  static const spacing24 = 24.0;
  static const spacing32 = 32.0;
  static const spacing48 = 48.0;
  static const spacing64 = 64.0;
  
  // Border Radius
  static const radius16 = 16.0;
  
  // Icon Sizes
  static const iconSmall = 20.0;
  static const iconMedium = 24.0;
}

class AppRoles {
  // System Level
  static const superSystemAdmin = 'superSystemAdmin';
  static const nationalAdmin = 'nationalAdmin';
  static const nationalExecutive = 'nationalExecutive';
  
  // Regional Level
  static const regionalAdmin = 'regionalAdmin';
  static const regionalBishop = 'regionalBishop';
  
  // District Level
  static const districtAdmin = 'districtAdmin';
  static const districtPastor = 'districtPastor';
  
  // Area Level (Optional)
  static const areaAdmin = 'areaAdmin';
  
  // Local Church Level
  static const localChurchAdmin = 'localChurchAdmin';
  static const seniorPastor = 'seniorPastor';
  static const associatePastor = 'associatePastor';
  static const churchSecretary = 'churchSecretary';
  static const financeOfficer = 'financeOfficer';
  static const ministryHead = 'ministryHead';
  static const youthMinistryHead = 'youthMinistryHead';
  static const menFellowshipHead = 'menFellowshipHead';
  static const womenFellowshipHead = 'womenFellowshipHead';
  static const childrenMinistryHead = 'childrenMinistryHead';
  static const welfareHead = 'welfareHead';
  static const cellLeader = 'cellLeader';
  static const volunteer = 'volunteer';
  
  // Member Level
  static const member = 'member';
  static const guest = 'guest';

  /// Roles that oversee multiple churches and are NOT tied to a single church.
  /// These roles have cross-church data access based on their hierarchy level.
  /// superSystemAdmin → all churches
  /// nationalAdmin/nationalExecutive → churches in their organization
  /// regionalAdmin/regionalBishop → churches in their region
  /// districtAdmin/districtPastor → churches in their district
  /// areaAdmin → churches in their area
  static const aboveChurchRoles = {
    superSystemAdmin,
    nationalAdmin,
    nationalExecutive,
    regionalAdmin,
    regionalBishop,
    districtAdmin,
    districtPastor,
    areaAdmin,
  };

  /// Roles scoped to a single local church/branch.
  static const churchScopedRoles = {
    localChurchAdmin,
    seniorPastor,
    associatePastor,
    churchSecretary,
    financeOfficer,
    ministryHead,
    youthMinistryHead,
    menFellowshipHead,
    womenFellowshipHead,
    childrenMinistryHead,
    welfareHead,
    cellLeader,
    volunteer,
    member,
    guest,
  };

  /// Returns true if the role is above church level (cross-church access).
  static bool isAboveChurchLevel(String? role) =>
      role != null && aboveChurchRoles.contains(role);

  /// Returns true if the role is scoped to a single church.
  static bool isChurchScoped(String? role) =>
      role != null && churchScopedRoles.contains(role);

  /// Roles that oversee more than a single local church/branch — used to
  /// show the cross-branch filter, branch tags, and branch selector on
  /// finance, attendance, sermons, and events screens.
  static const crossBranchRoles = {
    superSystemAdmin,
    nationalAdmin,
    regionalAdmin,
    districtAdmin,
    areaAdmin,
  };

  /// Roles that can manage welfare cases (create, edit, delete, update status).
  static const welfareManagerRoles = {
    superSystemAdmin,
    nationalAdmin,
    regionalAdmin,
    districtAdmin,
    areaAdmin,
    localChurchAdmin,
    welfareHead,
    churchSecretary,
  };

  /// Roles that can delete welfare cases (narrower than who can create).
  static const welfareDeleteRoles = {
    superSystemAdmin,
    nationalAdmin,
    regionalAdmin,
    districtAdmin,
    areaAdmin,
    localChurchAdmin,
  };

  /// Roles that can add, edit, and delete finance transactions. Pastoral
  /// roles (Senior/Associate Pastor, District Pastor, Regional Bishop,
  /// National Executive) have supervisory view-only access to finance.
  static const financeManagerRoles = {
    superSystemAdmin,
    nationalAdmin,
    regionalAdmin,
    districtAdmin,
    areaAdmin,
    localChurchAdmin,
    financeOfficer,
  };

  /// Roles that can review and approve/reject finance approval requests
  /// submitted by a Finance Officer (i.e. the "top hierarchy" above them).
  static const financeApprovalRoles = {
    superSystemAdmin,
    nationalAdmin,
    regionalAdmin,
    districtAdmin,
    areaAdmin,
    localChurchAdmin,
    seniorPastor,
    associatePastor,
  };

  /// Roles that can create/edit/delete branches and departments.
  static const structureManagerRoles = {
    superSystemAdmin,
    nationalAdmin,
    regionalAdmin,
    districtAdmin,
    areaAdmin,
    localChurchAdmin,
  };

  /// Roles that can record and edit attendance.
  static const attendanceManagerRoles = {
    superSystemAdmin,
    nationalAdmin,
    regionalAdmin,
    districtAdmin,
    areaAdmin,
    localChurchAdmin,
    seniorPastor,
    associatePastor,
    churchSecretary,
    ministryHead,
    youthMinistryHead,
    menFellowshipHead,
    womenFellowshipHead,
    childrenMinistryHead,
    cellLeader,
  };

  /// Roles that can delete attendance records (narrower than who can record).
  static const attendanceDeleteRoles = {
    superSystemAdmin,
    nationalAdmin,
    regionalAdmin,
    districtAdmin,
    areaAdmin,
    localChurchAdmin,
    churchSecretary,
  };

  /// Roles that can add/edit/delete sermons.
  static const sermonManagerRoles = {
    superSystemAdmin,
    nationalAdmin,
    regionalAdmin,
    districtAdmin,
    areaAdmin,
    localChurchAdmin,
    seniorPastor,
    associatePastor,
    districtPastor,
    regionalBishop,
    ministryHead,
  };

  /// Roles that can add/edit/delete events.
  static const eventManagerRoles = {
    superSystemAdmin,
    nationalAdmin,
    regionalAdmin,
    districtAdmin,
    areaAdmin,
    localChurchAdmin,
    seniorPastor,
    associatePastor,
    districtPastor,
    regionalBishop,
    churchSecretary,
    ministryHead,
    cellLeader,
  };

  /// Roles that can edit organization/church settings.
  static const churchSettingsManagerRoles = {
    superSystemAdmin,
  };

  /// Roles eligible to be assigned as a branch's lead pastor/administrator.
  static const branchLeaderRoles = {
    localChurchAdmin,
    seniorPastor,
    associatePastor,
  };

  /// Roles scoped to a single local church/branch, requiring a branch
  /// assignment when creating/editing a user account.
  static const branchScopedRoles = {
    localChurchAdmin,
    seniorPastor,
    associatePastor,
    churchSecretary,
    financeOfficer,
    ministryHead,
    youthMinistryHead,
    menFellowshipHead,
    womenFellowshipHead,
    childrenMinistryHead,
    welfareHead,
    cellLeader,
    volunteer,
    member,
    guest,
  };

  /// Roles scoped to a specific department, requiring a department
  /// assignment when creating/editing a user account.
  static const departmentScopedRoles = {
    ministryHead,
    youthMinistryHead,
    menFellowshipHead,
    womenFellowshipHead,
    childrenMinistryHead,
  };

  static String label(String role) {
    switch (role) {
      case superSystemAdmin:
        return 'Super System Administrator';
      case nationalAdmin:
        return 'National Administrator';
      case nationalExecutive:
        return 'National Executive';
      case regionalAdmin:
        return 'Regional Administrator';
      case regionalBishop:
        return 'Regional Bishop';
      case districtAdmin:
        return 'District Administrator';
      case districtPastor:
        return 'District Pastor';
      case areaAdmin:
        return 'Area Administrator';
      case localChurchAdmin:
        return 'Local Church Administrator';
      case seniorPastor:
        return 'Senior Pastor';
      case associatePastor:
        return 'Associate Pastor';
      case churchSecretary:
        return 'Church Secretary';
      case financeOfficer:
        return 'Finance Officer';
      case ministryHead:
        return 'Ministry Head';
      case youthMinistryHead:
        return 'Youth Ministry Head';
      case menFellowshipHead:
        return "Men's Fellowship Head";
      case womenFellowshipHead:
        return "Women's Fellowship Head";
      case childrenMinistryHead:
        return 'Children\'s Ministry Head';
      case welfareHead:
        return 'Welfare Head';
      case cellLeader:
        return 'Cell Leader';
      case volunteer:
        return 'Volunteer';
      case member:
        return 'Member';
      case guest:
        return 'Guest';
      default:
        return role;
    }
  }
}

class HiveBoxes {
  // Hierarchical boxes
  static const organization = 'organization_box';
  static const region = 'region_box';
  static const district = 'district_box';
  static const area = 'area_box';
  
  // Existing boxes
  static const church = 'church_box';
  static const users = 'users_box';
  static const branches = 'branches_box';
  static const departments = 'departments_box';
  static const members = 'members_box';
  static const session = 'session_box';
  static const attendance = 'attendance_box';
  static const finance = 'finance_box';
  static const sermons = 'sermons_box';
  static const events = 'events_box';
  static const welfare = 'welfare_box';
  static const welfareFinance = 'welfare_finance_box';
  static const departmentWelfare = 'department_welfare_box';
  static const welfareStatements = 'welfare_statements_box';
  static const sharedReports = 'shared_reports_box';
  static const ministries = 'ministries_box';
  static const ministryFinance = 'ministry_finance_box';
  static const ministryAnnouncements = 'ministry_announcements_box';
  static const contributions = 'contributions_box';
  static const benefitRequests = 'benefit_requests_box';
  static const budgets = 'budgets_box';
  static const financeApprovals = 'finance_approvals_box';
}

class HiveKeys {
  static const church = 'church';
  static const session = 'session';
}
