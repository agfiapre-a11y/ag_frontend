import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/access_control_grant.dart';
import '../services/access_control_service.dart';
import 'auth_provider.dart';

/// State notifier for access control grants and activities.
///
/// Adapted from SIMS's accessControlStore. Provides reactive access to
/// grants and activities for the UI.
class AccessControlNotifier extends StateNotifier<AccessControlState> {
  final Ref _ref;

  AccessControlNotifier(this._ref) : super(AccessControlState.initial()) {
    _refresh();
  }

  void _refresh() {
    final user = _ref.read(appStateProvider).user;
    if (user == null) {
      state = AccessControlState.initial();
      return;
    }

    final grants = AccessControlService.getGrantsForUser(user.id);
    final assignedDashboards = AccessControlService.getAssignedDashboardKeys(user.id);

    state = AccessControlState(
      grants: grants,
      assignedDashboardKeys: assignedDashboards,
    );
  }

  /// Assigns a user to a dashboard with full or page-level access.
  Future<void> assignAccess({
    required String userId,
    required String username,
    required String displayName,
    required String dashboardKey,
    required dynamic allowedPages,
  }) async {
    final currentUser = _ref.read(appStateProvider).user;
    if (currentUser == null) return;

    await AccessControlService.assignAccess(
      userId: userId,
      username: username,
      displayName: displayName,
      dashboardKey: dashboardKey,
      allowedPages: allowedPages,
      grantedBy: currentUser.name,
    );
    _refresh();
  }

  /// Revokes an access grant.
  Future<void> revokeAccess(String grantId) async {
    await AccessControlService.revokeAccess(grantId);
    _refresh();
  }

  /// Revokes all grants for a user.
  Future<void> revokeAllForUser(String userId) async {
    await AccessControlService.revokeAllForUser(userId);
    _refresh();
  }

  /// Refreshes the state from storage.
  void refresh() => _refresh();
}

class AccessControlState {
  final List<AccessControlGrant> grants;
  final List<String> assignedDashboardKeys;

  const AccessControlState({
    required this.grants,
    required this.assignedDashboardKeys,
  });

  factory AccessControlState.initial() =>
      const AccessControlState(grants: [], assignedDashboardKeys: []);

  bool get hasMultipleDashboards => assignedDashboardKeys.length > 1;
}

final accessControlProvider =
    StateNotifierProvider<AccessControlNotifier, AccessControlState>(
  (ref) => AccessControlNotifier(ref),
);
