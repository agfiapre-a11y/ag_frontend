/// A grant that gives a user access to a specific dashboard (role) and
/// either all its pages or a subset of pages.
///
/// Adapted from SIMS's PageAccessGrant model. This allows an admin to
/// assign a user to another role's dashboard with page-level granularity.
///
/// Example: A financeOfficer can be granted access to the WelfareHead
/// dashboard's "overview" and "reports" pages only, without getting
/// full welfare management capabilities.
class AccessControlGrant {
  final String id;
  final String userId;
  final String username;
  final String displayName;

  /// The dashboard key (from RoleDashboardCatalog) this grant gives access to.
  /// e.g. 'WelfareHead', 'ChurchAdmin', etc.
  final String dashboardKey;
  final String dashboardLabel;

  /// Either 'all' for full dashboard access, or a list of specific page keys.
  final dynamic allowedPages; // String 'all' or List<String>

  /// Who assigned this grant (admin user's name/email).
  final String grantedBy;

  /// When the grant was created (ISO 8601 string).
  final String grantedAt;

  /// Church scope (tenant isolation).
  final String churchId;

  const AccessControlGrant({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.dashboardKey,
    required this.dashboardLabel,
    required this.allowedPages,
    required this.grantedBy,
    required this.grantedAt,
    required this.churchId,
  });

  /// Returns true if the grant allows access to all pages.
  bool get isFullAccess => allowedPages == 'all';

  /// Returns the list of allowed page keys (empty if full access).
  List<String> get pageList {
    if (allowedPages == 'all') return [];
    if (allowedPages is List) {
      return (allowedPages as List).map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Returns true if the grant allows access to a specific page.
  bool allowsPage(String pageKey) {
    if (isFullAccess) return true;
    return pageList.contains(pageKey);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'username': username,
        'displayName': displayName,
        'dashboardKey': dashboardKey,
        'dashboardLabel': dashboardLabel,
        'allowedPages': allowedPages,
        'grantedBy': grantedBy,
        'grantedAt': grantedAt,
        'churchId': churchId,
      };

  factory AccessControlGrant.fromMap(Map<dynamic, dynamic> map) =>
      AccessControlGrant(
        id: map['id'] as String,
        userId: map['userId'] as String,
        username: (map['username'] as String?) ?? '',
        displayName: (map['displayName'] as String?) ?? '',
        dashboardKey: map['dashboardKey'] as String,
        dashboardLabel: (map['dashboardLabel'] as String?) ?? '',
        allowedPages: map['allowedPages'],
        grantedBy: (map['grantedBy'] as String?) ?? '',
        grantedAt: (map['grantedAt'] as String?) ?? '',
        churchId: (map['churchId'] as String?) ?? '',
      );
}

/// Activity log entry for access-controlled dashboard navigation.
/// Tracks when an assigned user views a page on a dashboard they were
/// granted access to (not their own primary dashboard).
class AccessActivity {
  final String id;
  final String userId;
  final String username;
  final String displayName;
  final String dashboardKey;
  final String dashboardLabel;
  final String pageKey;
  final String pageLabel;
  final String action;
  final String timestamp;

  const AccessActivity({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.dashboardKey,
    required this.dashboardLabel,
    required this.pageKey,
    required this.pageLabel,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'username': username,
        'displayName': displayName,
        'dashboardKey': dashboardKey,
        'dashboardLabel': dashboardLabel,
        'pageKey': pageKey,
        'pageLabel': pageLabel,
        'action': action,
        'timestamp': timestamp,
      };

  factory AccessActivity.fromMap(Map<dynamic, dynamic> map) =>
      AccessActivity(
        id: map['id'] as String,
        userId: map['userId'] as String,
        username: (map['username'] as String?) ?? '',
        displayName: (map['displayName'] as String?) ?? '',
        dashboardKey: map['dashboardKey'] as String,
        dashboardLabel: (map['dashboardLabel'] as String?) ?? '',
        pageKey: map['pageKey'] as String,
        pageLabel: (map['pageLabel'] as String?) ?? '',
        action: (map['action'] as String?) ?? '',
        timestamp: (map['timestamp'] as String?) ?? '',
      );
}
