import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sync_queue_entry.dart';
import '../services/sync_service.dart';
import 'auth_provider.dart';
import 'data_provider.dart';

/// State notifier for sync status and operations.
///
/// Auto-sync is ALWAYS ON when Supabase is configured — no opt-in needed.
/// Runs every 30 seconds when online, plus immediately on connectivity
/// restore and app resume. After each successful sync that pulls new data,
/// all data providers are invalidated so the UI refreshes automatically.
class SyncNotifier extends StateNotifier<SyncState> {
  final Ref _ref;
  final String churchId;
  StreamSubscription<bool>? _connectivitySub;
  Timer? _autoSyncTimer;
  bool _disposed = false;

  SyncNotifier(this._ref, this.churchId) : super(SyncState(
    status: SyncService.isConfigured ? SyncStatus.idle : SyncStatus.notConfigured,
    lastSyncedAt: SyncService.getLastSyncTime(),
    pendingCount: SyncService.getPendingCount(),
  )) {
    _init();
  }

  void _init() {
    // Update pending count
    state = state.copyWith(pendingCount: SyncService.getPendingCount());

    // Listen to connectivity changes — sync immediately when back online
    _connectivitySub = SyncService.connectivityStream().listen((online) {
      if (online && state.status != SyncStatus.syncing && !_disposed) {
        sync();
      }
    });

    // Always-on auto-sync: every 15 seconds when configured.
    // ONLINE-FIRST: Frequent sync ensures data stays fresh and local
    // changes are pushed to Supabase quickly.
    if (SyncService.isConfigured && churchId.isNotEmpty) {
      _autoSyncTimer?.cancel();
      _autoSyncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (!_disposed && state.status != SyncStatus.syncing) {
          sync();
        }
      });
      // ONLINE-FIRST: Sync immediately on startup (1 second delay to allow
      // providers to initialize)
      Timer(const Duration(seconds: 1), () {
        if (!_disposed && state.status != SyncStatus.syncing) {
          sync();
        }
      });
    }
  }

  /// Run a full sync (push + pull). Returns the sync result.
  /// After a successful sync that pulled new records, all data providers
  /// are invalidated so the UI refreshes automatically.
  Future<SyncResult> sync() async {
    if (!SyncService.isConfigured) {
      state = state.copyWith(status: SyncStatus.notConfigured);
      return const SyncResult(
        success: false,
        pushed: 0,
        pulled: 0,
        failed: 0,
        message: 'Supabase not configured',
      );
    }

    if (churchId.isEmpty) {
      return const SyncResult(
        success: false,
        pushed: 0,
        pulled: 0,
        failed: 0,
        message: 'No church selected',
      );
    }

    if (state.status == SyncStatus.syncing) {
      // Already syncing — skip
      return const SyncResult(
        success: true,
        pushed: 0,
        pulled: 0,
        failed: 0,
        message: 'Already syncing',
      );
    }

    state = state.copyWith(status: SyncStatus.syncing);

    final result = await SyncService.fullSync(churchId: churchId);

    if (_disposed) return result;

    state = state.copyWith(
      status: result.success ? SyncStatus.success : SyncStatus.error,
      lastSyncedAt: DateTime.now(),
      pendingCount: SyncService.getPendingCount(),
      errorMessage: result.success ? null : result.message,
    );

    // If we pulled new data, refresh all data providers so the UI updates
    if (result.success && result.pulled > 0) {
      _refreshAllProviders();
    }

    // Reset to idle after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (!_disposed &&
          (state.status == SyncStatus.success ||
              state.status == SyncStatus.error)) {
        state = state.copyWith(status: SyncStatus.idle);
      }
    });

    return result;
  }

  /// Invalidate all data providers so they reload from LocalDb.
  /// This ensures the UI reflects the latest synced data.
  void _refreshAllProviders() {
    // Invalidate all data providers — they will reload from LocalDb
    // on the next watch/read, picking up the freshly synced data.
    _ref.invalidate(userProvider);
    _ref.invalidate(departmentProvider);
    _ref.invalidate(memberProvider);
    _ref.invalidate(attendanceProvider);
    _ref.invalidate(financeProvider);
    _ref.invalidate(sermonProvider);
    _ref.invalidate(libraryBookProvider);
    _ref.invalidate(devotionGuideProvider);
    _ref.invalidate(bibleStudyResourceProvider);
    _ref.invalidate(sundaySchoolBookProvider);
    _ref.invalidate(sundaySchoolChapterProvider);
    _ref.invalidate(communityPostProvider);
    _ref.invalidate(commentProvider);
    _ref.invalidate(conversationProvider);
    _ref.invalidate(eventProvider);
    _ref.invalidate(organizationProvider);
    _ref.invalidate(regionProvider);
    _ref.invalidate(districtProvider);
    _ref.invalidate(areaProvider);
    _ref.invalidate(welfareProvider);
    _ref.invalidate(welfareFinanceProvider);
    _ref.invalidate(departmentWelfareProvider);
    _ref.invalidate(ministryProvider);
    _ref.invalidate(ministryFinanceProvider);
    _ref.invalidate(ministryAnnouncementProvider);
    _ref.invalidate(contributionProvider);
    _ref.invalidate(myContributionProvider);
    _ref.invalidate(benefitRequestProvider);
    _ref.invalidate(myBenefitRequestProvider);
    _ref.invalidate(budgetProvider);
    _ref.invalidate(financeApprovalProvider);
    _ref.invalidate(notificationProvider);
  }

  /// Enable auto-sync manually (kept for compatibility — auto-sync is
  /// always on now, so this is a no-op).
  void enableAutoSync() {
    // Auto-sync is always on — no-op
  }

  /// Disable auto-sync manually (kept for compatibility).
  void disableAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Refresh pending count.
  void refresh() {
    if (_disposed) return;
    state = state.copyWith(
      pendingCount: SyncService.getPendingCount(),
      lastSyncedAt: SyncService.getLastSyncTime(),
      status: SyncService.isConfigured ? state.status : SyncStatus.notConfigured,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySub?.cancel();
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final appState = ref.watch(appStateProvider);
  return SyncNotifier(ref, appState.church?.id ?? '');
});
