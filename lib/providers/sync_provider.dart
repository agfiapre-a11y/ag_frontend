import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sync_queue_entry.dart';
import '../services/sync_service.dart';
import 'auth_provider.dart';

/// State notifier for sync status and operations.
class SyncNotifier extends StateNotifier<SyncState> {
  final String churchId;
  StreamSubscription<bool>? _connectivitySub;
  Timer? _autoSyncTimer;

  SyncNotifier(this.churchId) : super(SyncState(
    status: SyncService.isConfigured ? SyncStatus.idle : SyncStatus.notConfigured,
    lastSyncedAt: SyncService.getLastSyncTime(),
    pendingCount: SyncService.getPendingCount(),
  )) {
    _init();
  }

  void _init() {
    // Update pending count
    state = state.copyWith(pendingCount: SyncService.getPendingCount());

    // Listen to connectivity changes for auto-sync
    _connectivitySub = SyncService.connectivityStream().listen((online) {
      if (online && state.status != SyncStatus.syncing) {
        sync();
      }
    });
  }

  /// Run a full sync (push + pull).
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

    state = state.copyWith(status: SyncStatus.syncing);

    final result = await SyncService.fullSync(churchId: churchId);

    state = state.copyWith(
      status: result.success ? SyncStatus.success : SyncStatus.error,
      lastSyncedAt: DateTime.now(),
      pendingCount: SyncService.getPendingCount(),
      errorMessage: result.success ? null : result.message,
    );

    // Reset to idle after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (state.status == SyncStatus.success || state.status == SyncStatus.error) {
        state = state.copyWith(status: SyncStatus.idle);
      }
    });

    return result;
  }

  /// Enable auto-sync (syncs every 5 minutes when online).
  void enableAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (SyncService.isConfigured) {
        sync();
      }
    });
  }

  /// Disable auto-sync.
  void disableAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Refresh pending count.
  void refresh() {
    state = state.copyWith(
      pendingCount: SyncService.getPendingCount(),
      lastSyncedAt: SyncService.getLastSyncTime(),
      status: SyncService.isConfigured ? state.status : SyncStatus.notConfigured,
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final appState = ref.watch(appStateProvider);
  return SyncNotifier(appState.church?.id ?? '');
});
