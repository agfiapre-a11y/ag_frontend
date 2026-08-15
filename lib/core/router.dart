import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/dashboard_theme_wrapper.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/setup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/super_admin/super_admin_dashboard.dart';
import '../screens/members/members_screen.dart';
import '../screens/members/add_member_screen.dart';
import '../screens/members/edit_member_screen.dart';
import '../screens/users/users_screen.dart';
import '../screens/users/add_user_screen.dart';
import '../screens/users/edit_user_screen.dart';
import '../screens/users/bulk_add_users_screen.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/attendance/take_attendance_screen.dart';
import '../screens/attendance/attendance_detail_screen.dart';
import '../screens/attendance/edit_attendance_screen.dart';
import '../screens/attendance/self_check_in_screen.dart';
import '../screens/finance/finance_screen.dart';
import '../screens/finance/add_transaction_screen.dart';
import '../screens/finance/edit_transaction_screen.dart';
import '../screens/finance/member_finance_screen.dart';
import '../screens/finance/tithe_offering_donation_screen.dart';
import '../screens/finance/budget_spending_screen.dart';
import '../screens/finance/income_entry_screen.dart';
import '../screens/finance/finance_approvals_screen.dart';
import '../screens/finance/finance_reports_screen.dart';
import '../screens/sermons/sermons_screen.dart';
import '../screens/sermons/add_edit_sermon_screen.dart';
import '../screens/sermons/sermon_detail_screen.dart';
import '../screens/events/events_screen.dart';
import '../screens/events/add_edit_event_screen.dart';
import '../screens/events/event_detail_screen.dart';
import '../screens/departments/departments_screen.dart';
import '../screens/departments/add_edit_department_screen.dart';
import '../screens/departments/department_detail_screen.dart';
import '../screens/settings/church_settings_screen.dart';
import '../screens/settings/data_management_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/organizations/organizations_screen.dart';
import '../screens/organizations/add_edit_organization_screen.dart';
import '../screens/regions/regions_screen.dart';
import '../screens/regions/add_edit_region_screen.dart';
import '../screens/districts/districts_screen.dart';
import '../screens/districts/add_edit_district_screen.dart';
import '../screens/areas/areas_screen.dart';
import '../screens/areas/add_edit_area_screen.dart';
import '../screens/welfare/welfare_screen.dart';
import '../screens/welfare/add_welfare_case_screen.dart';
import '../screens/welfare/edit_welfare_case_screen.dart';
import '../screens/welfare/welfare_detail_screen.dart';
import '../screens/welfare/welfare_finance_screen.dart';
import '../screens/welfare/welfare_transactions_screen.dart';
import '../screens/welfare/welfare_contributions_screen.dart';
import '../screens/welfare/welfare_payment_screen.dart';
import '../screens/welfare/department_welfare_screen.dart';
import '../screens/welfare/welfare_reports_screen.dart';
import '../screens/welfare/welfare_statement_screen.dart';
import '../screens/welfare/member_welfare_request_screen.dart';
import '../screens/ministry/ministry_dashboard_screen.dart';
import '../screens/ministry/ministry_finance_screen.dart';
import '../screens/ministry/ministry_reports_screen.dart';
import '../screens/ministry/ministry_announcements_screen.dart';
import '../models/ministry.dart';

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AppState>(appStateProvider, (_, _) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final appState = _ref.read(appStateProvider);
    final loc = state.matchedLocation;

    switch (appState.initState) {
      case AppInitState.loading:
        return loc == '/' ? null : '/';
      case AppInitState.needsSetup:
        if (loc == '/login' || loc == '/setup') return null;
        return '/login';
      case AppInitState.unauthenticated:
        if (loc == '/login') return null;
        return '/login';
      case AppInitState.authenticated:
        if (loc == '/' || loc == '/login' || loc == '/setup') {
          return '/home';
        }
        return null;
    }
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/setup', builder: (_, _) => const SetupScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const DashboardThemeWrapper(child: HomeScreen()),
      ),
      GoRoute(
        path: '/super-admin/churches',
        builder: (_, _) => const DashboardThemeWrapper(child: SuperAdminDashboard()),
      ),
      GoRoute(
        path: '/members',
        builder: (_, _) => const DashboardThemeWrapper(child: MembersScreen()),
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, _) => const DashboardThemeWrapper(child: AddMemberScreen()),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: EditMemberScreen(memberId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: EditMemberScreen(memberId: state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(
        path: '/sermons',
        builder: (_, _) => const DashboardThemeWrapper(child: SermonsScreen()),
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, _) => const DashboardThemeWrapper(child: AddEditSermonScreen()),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: AddEditSermonScreen(sermonId: state.pathParameters['id'])),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: SermonDetailScreen(sermonId: state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(
        path: '/finance',
        builder: (_, _) => const DashboardThemeWrapper(child: FinanceScreen()),
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, _) => const DashboardThemeWrapper(child: AddTransactionScreen()),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: EditTransactionScreen(transactionId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'tithes-offerings-donations',
            builder: (_, _) =>
                const DashboardThemeWrapper(child: TitheOfferingDonationScreen()),
          ),
          GoRoute(
            path: 'budget-spending',
            builder: (_, _) =>
                const DashboardThemeWrapper(child: BudgetSpendingScreen()),
          ),
          GoRoute(
            path: 'income-entry',
            builder: (_, _) =>
                const DashboardThemeWrapper(child: IncomeEntryScreen()),
          ),
          GoRoute(
            path: 'approvals',
            builder: (_, _) =>
                const DashboardThemeWrapper(child: FinanceApprovalsScreen()),
          ),
          GoRoute(
            path: 'reports',
            builder: (_, _) =>
                const DashboardThemeWrapper(child: FinanceReportsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/my-finance',
        builder: (_, _) => const DashboardThemeWrapper(child: MemberFinanceScreen()),
      ),
      GoRoute(
        path: '/ministry',
        builder: (_, _) => const DashboardThemeWrapper(
            child: MinistryDashboardScreen(ministryType: MinistryType.youth)),
        routes: [
          GoRoute(
            path: 'finance',
            builder: (_, _) => const DashboardThemeWrapper(
                child: MinistryFinanceScreen(ministryType: MinistryType.youth)),
          ),
          GoRoute(
            path: 'youth',
            builder: (_, _) => const DashboardThemeWrapper(
                child: MinistryDashboardScreen(ministryType: MinistryType.youth)),
            routes: [
              GoRoute(path: 'finance', builder: (_, _) => const DashboardThemeWrapper(child: MinistryFinanceScreen(ministryType: MinistryType.youth))),
              GoRoute(path: 'reports', builder: (_, _) => const DashboardThemeWrapper(child: MinistryReportsScreen(ministryType: MinistryType.youth))),
              GoRoute(path: 'announcements', builder: (_, _) => const DashboardThemeWrapper(child: MinistryAnnouncementsScreen(ministryType: MinistryType.youth))),
            ],
          ),
          GoRoute(
            path: 'men',
            builder: (_, _) => const DashboardThemeWrapper(
                child: MinistryDashboardScreen(ministryType: MinistryType.menFellowship)),
            routes: [
              GoRoute(path: 'finance', builder: (_, _) => const DashboardThemeWrapper(child: MinistryFinanceScreen(ministryType: MinistryType.menFellowship))),
              GoRoute(path: 'reports', builder: (_, _) => const DashboardThemeWrapper(child: MinistryReportsScreen(ministryType: MinistryType.menFellowship))),
              GoRoute(path: 'announcements', builder: (_, _) => const DashboardThemeWrapper(child: MinistryAnnouncementsScreen(ministryType: MinistryType.menFellowship))),
            ],
          ),
          GoRoute(
            path: 'women',
            builder: (_, _) => const DashboardThemeWrapper(
                child: MinistryDashboardScreen(ministryType: MinistryType.womenFellowship)),
            routes: [
              GoRoute(path: 'finance', builder: (_, _) => const DashboardThemeWrapper(child: MinistryFinanceScreen(ministryType: MinistryType.womenFellowship))),
              GoRoute(path: 'reports', builder: (_, _) => const DashboardThemeWrapper(child: MinistryReportsScreen(ministryType: MinistryType.womenFellowship))),
              GoRoute(path: 'announcements', builder: (_, _) => const DashboardThemeWrapper(child: MinistryAnnouncementsScreen(ministryType: MinistryType.womenFellowship))),
            ],
          ),
          GoRoute(
            path: 'children',
            builder: (_, _) => const DashboardThemeWrapper(
                child: MinistryDashboardScreen(ministryType: MinistryType.children)),
            routes: [
              GoRoute(path: 'finance', builder: (_, _) => const DashboardThemeWrapper(child: MinistryFinanceScreen(ministryType: MinistryType.children))),
              GoRoute(path: 'reports', builder: (_, _) => const DashboardThemeWrapper(child: MinistryReportsScreen(ministryType: MinistryType.children))),
              GoRoute(path: 'announcements', builder: (_, _) => const DashboardThemeWrapper(child: MinistryAnnouncementsScreen(ministryType: MinistryType.children))),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/attendance',
        builder: (_, _) => const DashboardThemeWrapper(child: AttendanceScreen()),
        routes: [
          GoRoute(
            path: 'take',
            builder: (_, _) => const DashboardThemeWrapper(child: TakeAttendanceScreen()),
          ),
          GoRoute(
            path: 'self-checkin',
            builder: (_, _) => const DashboardThemeWrapper(child: SelfCheckInScreen()),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: EditAttendanceScreen(recordId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: AttendanceDetailScreen(recordId: state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(
        path: '/users',
        builder: (_, _) => const DashboardThemeWrapper(child: UsersScreen()),
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, _) => const DashboardThemeWrapper(child: AddUserScreen()),
          ),
          GoRoute(
            path: 'bulk-add',
            builder: (_, _) => const DashboardThemeWrapper(child: BulkAddUsersScreen()),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: EditUserScreen(userId: state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(
        path: '/settings/church',
        builder: (_, _) => const DashboardThemeWrapper(child: ChurchSettingsScreen()),
      ),
      GoRoute(
        path: '/settings/data-management',
        builder: (_, _) => const DashboardThemeWrapper(child: DataManagementScreen()),
      ),
      GoRoute(
        path: '/departments',
        builder: (_, _) => const DashboardThemeWrapper(child: DepartmentsScreen()),
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, _) => const DashboardThemeWrapper(child: AddEditDepartmentScreen()),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: AddEditDepartmentScreen(deptId: state.pathParameters['id'])),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: DepartmentDetailScreen(deptId: state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(
        path: '/events',
        builder: (_, _) => const DashboardThemeWrapper(child: EventsScreen()),
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, _) => const DashboardThemeWrapper(child: AddEditEventScreen()),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: AddEditEventScreen(eventId: state.pathParameters['id'])),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: EventDetailScreen(eventId: state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const DashboardThemeWrapper(child: ProfileScreen()),
      ),
      // Hierarchical routes
      GoRoute(
        path: '/organizations',
        builder: (_, _) => const DashboardThemeWrapper(child: OrganizationsScreen()),
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, _) => const DashboardThemeWrapper(child: AddEditOrganizationScreen()),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: AddEditOrganizationScreen(organizationId: state.pathParameters['id'])),
          ),
        ],
      ),
      GoRoute(
        path: '/regions',
        builder: (_, _) => const DashboardThemeWrapper(child: RegionsScreen()),
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, _) => const DashboardThemeWrapper(child: AddEditRegionScreen()),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: AddEditRegionScreen(regionId: state.pathParameters['id'])),
          ),
        ],
      ),
      GoRoute(
        path: '/districts',
        builder: (_, _) => const DashboardThemeWrapper(child: DistrictsScreen()),
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, _) => const DashboardThemeWrapper(child: AddEditDistrictScreen()),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: AddEditDistrictScreen(districtId: state.pathParameters['id'])),
          ),
        ],
      ),
      GoRoute(
        path: '/areas',
        builder: (_, _) => const DashboardThemeWrapper(child: AreasScreen()),
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, _) => const DashboardThemeWrapper(child: AddEditAreaScreen()),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: AddEditAreaScreen(areaId: state.pathParameters['id'])),
          ),
        ],
      ),
      GoRoute(
        path: '/welfare',
        builder: (_, _) => const DashboardThemeWrapper(child: WelfareScreen()),
        routes: [
          GoRoute(
            path: 'add',
            builder: (_, _) => const DashboardThemeWrapper(child: AddWelfareCaseScreen()),
          ),
          GoRoute(
            path: 'request',
            builder: (_, _) => const DashboardThemeWrapper(child: MemberWelfareRequestScreen()),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: EditWelfareCaseScreen(welfareCaseId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'detail/:id',
            builder: (_, state) =>
                DashboardThemeWrapper(child: WelfareDetailScreen(welfareCaseId: state.pathParameters['id']!)),
          ),
          GoRoute(
            path: 'finance',
            builder: (_, _) => const DashboardThemeWrapper(child: WelfareFinanceScreen()),
            routes: [
              GoRoute(
                path: 'transactions',
                builder: (_, _) => const DashboardThemeWrapper(child: WelfareTransactionsScreen()),
              ),
              GoRoute(
                path: 'contributions',
                builder: (_, _) => const DashboardThemeWrapper(child: WelfareContributionsScreen()),
              ),
              GoRoute(
                path: 'payment',
                builder: (_, _) => const DashboardThemeWrapper(child: WelfarePaymentScreen()),
              ),
              GoRoute(
                path: 'departments',
                builder: (_, _) => const DashboardThemeWrapper(child: DepartmentWelfareScreen()),
              ),
              GoRoute(
                path: 'reports',
                builder: (_, _) => const DashboardThemeWrapper(child: WelfareReportsScreen()),
              ),
              GoRoute(
                path: 'statements',
                builder: (_, _) => const DashboardThemeWrapper(child: WelfareStatementScreen()),
              ),
            ],
          ),
          // Ministry routes
          GoRoute(
            path: 'ministry/youth',
            builder: (_, _) => const DashboardThemeWrapper(
                child: MinistryDashboardScreen(ministryType: MinistryType.youth)),
            routes: [
              GoRoute(
                path: 'finance',
                builder: (_, _) => const DashboardThemeWrapper(
                    child: MinistryFinanceScreen(ministryType: MinistryType.youth)),
              ),
              GoRoute(
                path: 'reports',
                builder: (_, _) => const DashboardThemeWrapper(
                    child: MinistryReportsScreen(ministryType: MinistryType.youth)),
              ),
              GoRoute(
                path: 'announcements',
                builder: (_, _) => const DashboardThemeWrapper(
                    child: MinistryAnnouncementsScreen(ministryType: MinistryType.youth)),
              ),
            ],
          ),
          GoRoute(
            path: 'ministry/men',
            builder: (_, _) => const DashboardThemeWrapper(
                child: MinistryDashboardScreen(ministryType: MinistryType.menFellowship)),
            routes: [
              GoRoute(
                path: 'finance',
                builder: (_, _) => const DashboardThemeWrapper(
                    child: MinistryFinanceScreen(ministryType: MinistryType.menFellowship)),
              ),
              GoRoute(
                path: 'reports',
                builder: (_, _) => const DashboardThemeWrapper(
                    child: MinistryReportsScreen(ministryType: MinistryType.menFellowship)),
              ),
              GoRoute(
                path: 'announcements',
                builder: (_, _) => const DashboardThemeWrapper(
                    child: MinistryAnnouncementsScreen(ministryType: MinistryType.menFellowship)),
              ),
            ],
          ),
          GoRoute(
            path: 'ministry/women',
            builder: (_, _) => const DashboardThemeWrapper(
                child: MinistryDashboardScreen(ministryType: MinistryType.womenFellowship)),
            routes: [
              GoRoute(
                path: 'finance',
                builder: (_, _) => const DashboardThemeWrapper(
                    child: MinistryFinanceScreen(ministryType: MinistryType.womenFellowship)),
              ),
              GoRoute(
                path: 'reports',
                builder: (_, _) => const DashboardThemeWrapper(
                    child: MinistryReportsScreen(ministryType: MinistryType.womenFellowship)),
              ),
              GoRoute(
                path: 'announcements',
                builder: (_, _) => const DashboardThemeWrapper(
                    child: MinistryAnnouncementsScreen(ministryType: MinistryType.womenFellowship)),
              ),
            ],
          ),
          GoRoute(
            path: 'ministry/children',
            builder: (_, _) => const DashboardThemeWrapper(
                child: MinistryDashboardScreen(ministryType: MinistryType.children)),
            routes: [
              GoRoute(
                path: 'finance',
                builder: (_, _) => const DashboardThemeWrapper(
                    child: MinistryFinanceScreen(ministryType: MinistryType.children)),
              ),
              GoRoute(
                path: 'reports',
                builder: (_, _) => const DashboardThemeWrapper(
                    child: MinistryReportsScreen(ministryType: MinistryType.children)),
              ),
              GoRoute(
                path: 'announcements',
                builder: (_, _) => const DashboardThemeWrapper(
                    child: MinistryAnnouncementsScreen(ministryType: MinistryType.children)),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
