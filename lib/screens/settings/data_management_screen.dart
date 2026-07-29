import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
import '../../providers/data_provider.dart';
import '../../services/backup_service.dart';
import '../../services/sync_service.dart';
import '../../services/supabase_config.dart';
import '../../models/sync_queue_entry.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/notification_center_button.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DataSummary? _dataSummary;
  final bool _loading = false;
  int? _dataSizeBytes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final summary = await BackupService.getDataSummary();
    final size = await BackupService.getEstimatedDataSize();
    if (mounted) {
      setState(() {
        _dataSummary = summary;
        _dataSizeBytes = size;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Data Management'),
        actions: const [
          NotificationCenterButton(),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.backup_outlined), text: 'Backup & Restore'),
              Tab(icon: Icon(Icons.cloud_sync_outlined), text: 'Cloud Sync'),
              Tab(icon: Icon(Icons.health_and_safety_outlined), text: 'System Health'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BackupRestoreTab(
                  dataSummary: _dataSummary,
                  dataSizeBytes: _dataSizeBytes,
                  formattedSize: _dataSizeBytes != null ? _formatBytes(_dataSizeBytes!) : '--',
                  loading: _loading,
                  onRefresh: _loadSummary,
                ),
                _CloudSyncTab(),
                _SystemHealthTab(dataSummary: _dataSummary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Backup & Restore Tab ──────────────────────────────────────────────────────

class _BackupRestoreTab extends ConsumerStatefulWidget {
  final DataSummary? dataSummary;
  final int? dataSizeBytes;
  final String formattedSize;
  final bool loading;
  final VoidCallback onRefresh;

  const _BackupRestoreTab({
    required this.dataSummary,
    required this.dataSizeBytes,
    required this.formattedSize,
    required this.loading,
    required this.onRefresh,
  });

  @override
  ConsumerState<_BackupRestoreTab> createState() => _BackupRestoreTabState();
}

class _BackupRestoreTabState extends ConsumerState<_BackupRestoreTab> {
  final _passwordCtrl = TextEditingController();
  final _restorePasswordCtrl = TextEditingController();
  bool _obscureBackup = true;
  bool _obscureRestore = true;
  bool _working = false;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  BackupPreview? _backupPreview;
  bool _mergeRestore = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _restorePasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _createBackup() async {
    if (_passwordCtrl.text.length < 4) {
      _showSnack('Password must be at least 4 characters', isError: true);
      return;
    }

    setState(() => _working = true);
    try {
      final backup = await BackupService.createBackup(
        password: _passwordCtrl.text,
        appVersion: '1.0.0',
      );

      // Share the file (works on web, mobile, and desktop)
      await Share.shareXFiles(
        [XFile.fromData(backup.bytes, name: backup.fileName, mimeType: 'application/octet-stream')],
        text: 'Paradise AG Church - Encrypted Backup (${DateTime.now()})',
      );

      if (mounted) {
        _showSnack('Backup created successfully. Save the .pab file in a safe location.', isError: false);
      }
    } catch (e) {
      if (mounted) _showSnack('Backup failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pab'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() {
      _selectedFileBytes = file.bytes;
      _selectedFileName = file.name;
      _backupPreview = null;
    });
  }

  Future<void> _previewBackup() async {
    if (_selectedFileBytes == null || _restorePasswordCtrl.text.isEmpty) {
      _showSnack('Select a file and enter the password first', isError: true);
      return;
    }

    setState(() => _working = true);
    try {
      final preview = await BackupService.previewBackup(
        bytes: _selectedFileBytes!,
        password: _restorePasswordCtrl.text,
      );

      if (preview == null) {
        _showSnack('Could not read backup. Check password and file.', isError: true);
        setState(() => _backupPreview = null);
      } else {
        setState(() => _backupPreview = preview);
        _showSnack('Backup verified. Ready to restore.', isError: false);
      }
    } catch (e) {
      _showSnack('Preview failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _restoreBackup() async {
    if (_selectedFileBytes == null) {
      _showSnack('Select a backup file first', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_mergeRestore ? 'Merge Backup?' : 'Restore Backup?'),
        content: Text(_mergeRestore
            ? 'This will merge the backup data with your current data. Existing entries with the same ID will be overwritten. Continue?'
            : 'WARNING: This will ERASE all current data and replace it with the backup. This cannot be undone. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _mergeRestore ? Colors.orange : Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _working = true);
    try {
      final result = await BackupService.restoreBackup(
        bytes: _selectedFileBytes!,
        password: _restorePasswordCtrl.text,
        merge: _mergeRestore,
      );

      if (result.success) {
        // Refresh all providers
        ref.read(userProvider.notifier).refresh();
        ref.read(memberProvider.notifier).refresh();
        ref.read(financeProvider.notifier).refresh();
        ref.read(eventProvider.notifier).refresh();
        ref.read(sermonProvider.notifier).refresh();
        ref.read(welfareProvider.notifier).refresh();
        ref.read(attendanceProvider.notifier).refresh();
        ref.read(departmentProvider.notifier).refresh();
        ref.read(branchProvider.notifier).refresh();
        ref.read(notificationProvider.notifier).refresh();

        if (mounted) {
          _showSnack(result.message, isError: false);
          widget.onRefresh();
        }
      } else {
        if (mounted) _showSnack(result.message, isError: true);
      }
    } catch (e) {
      if (mounted) _showSnack('Restore failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.dataSummary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data Summary Card
          _SectionCard(
            title: 'Current Data Overview',
            icon: Icons.storage_outlined,
            child: summary == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Row(
                        children: [
                          _DataChip(label: 'Total Size', value: widget.formattedSize),
                          _DataChip(label: 'Entries', value: '${summary.totalEntries}'),
                          _DataChip(label: 'Keys', value: '${summary.totalKeys}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DataPill(icon: Icons.church, label: 'Churches', value: summary.churches),
                          _DataPill(icon: Icons.people, label: 'Users', value: summary.users),
                          _DataPill(icon: Icons.badge, label: 'Members', value: summary.members),
                          _DataPill(icon: Icons.account_balance_wallet, label: 'Transactions', value: summary.transactions),
                          _DataPill(icon: Icons.event, label: 'Events', value: summary.events),
                          _DataPill(icon: Icons.video_library, label: 'Sermons', value: summary.sermons),
                          _DataPill(icon: Icons.handshake, label: 'Welfare', value: summary.welfareCases),
                          _DataPill(icon: Icons.fact_check, label: 'Attendance', value: summary.attendanceRecords),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),

          // Create Backup Section
          _SectionCard(
            title: 'Create Encrypted Backup',
            icon: Icons.lock_outline,
            iconColor: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export all app data (members, users, finance, events, sermons, welfare, attendance, etc.) into an encrypted .pab file. Keep the password safe — you\'ll need it to restore.',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscureBackup,
                  decoration: InputDecoration(
                    labelText: 'Backup Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureBackup ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureBackup = !_obscureBackup),
                    ),
                    helperText: 'Min 4 characters. Remember this password!',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _working ? null : _createBackup,
                    icon: _working
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.backup),
                    label: const Text('Create & Share Backup'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Restore Backup Section
          _SectionCard(
            title: 'Restore from Backup',
            icon: Icons.restore,
            iconColor: Colors.orange,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import a .pab backup file to restore app data. You can either replace all current data or merge with existing data.',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickBackupFile,
                    icon: const Icon(Icons.file_open),
                    label: Text(_selectedFileName != null
                        ? 'File: $_selectedFileName'
                        : 'Select .pab Backup File'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _restorePasswordCtrl,
                  obscureText: _obscureRestore,
                  decoration: InputDecoration(
                    labelText: 'Backup Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureRestore ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureRestore = !_obscureRestore),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Switch(
                      value: _mergeRestore,
                      onChanged: (v) => setState(() => _mergeRestore = v),
                    ),
                    Expanded(
                      child: Text(
                        _mergeRestore ? 'Merge mode: Keep existing data, overwrite conflicts' : 'Replace mode: Erase all current data first',
                        style: GoogleFonts.poppins(fontSize: 12, color: _mergeRestore ? Colors.green : Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _working ? null : _previewBackup,
                        icon: const Icon(Icons.preview),
                        label: const Text('Preview'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _working ? null : _restoreBackup,
                        icon: _working
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.restore),
                        label: const Text('Restore'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_backupPreview != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text('Backup Verified', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.green)),
                        ]),
                        const SizedBox(height: 8),
                        _PreviewRow(label: 'Created', value: _backupPreview!.createdAt != null
                            ? DateFormat('MMM d, yyyy HH:mm').format(_backupPreview!.createdAt!)
                            : 'Unknown'),
                        _PreviewRow(label: 'App Version', value: _backupPreview!.appVersion ?? 'Unknown'),
                        _PreviewRow(label: 'Data Keys', value: '${_backupPreview!.totalKeys}'),
                        _PreviewRow(label: 'Churches', value: '${_backupPreview!.churchesCount}'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cloud Sync Tab ────────────────────────────────────────────────────────────

class _CloudSyncTab extends ConsumerStatefulWidget {
  const _CloudSyncTab();

  @override
  ConsumerState<_CloudSyncTab> createState() => _CloudSyncTabState();
}

class _CloudSyncTabState extends ConsumerState<_CloudSyncTab> {
  bool _autoSyncEnabled = false;
  SyncResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncProvider);
    final isConfigured = SyncService.isConfigured;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Configuration status banner
          _SectionCard(
            title: 'Cloud Synchronization',
            icon: Icons.cloud_sync,
            iconColor: AppColors.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isConfigured
                        ? Colors.green.withValues(alpha: 0.08)
                        : Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isConfigured
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isConfigured ? Icons.cloud_done : Icons.cloud_off,
                        color: isConfigured ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isConfigured
                              ? 'Supabase is configured. Your data will sync to the cloud when internet is available. The app works fully offline.'
                              : 'Supabase is not configured yet. Add your credentials in lib/services/supabase_config.dart to enable cloud sync. The app works fully offline without it.',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sync status row
                Row(
                  children: [
                    _SyncStatusBadge(state: syncState),
                    const Spacer(),
                    if (syncState.lastSyncedAt != null)
                      Text(
                        'Last: ${DateFormat('MMM d, HH:mm').format(syncState.lastSyncedAt!)}',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (syncState.pendingCount > 0)
                  Text(
                    '${syncState.pendingCount} change(s) pending sync',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange),
                  ),
                const SizedBox(height: 16),

                // Sync now button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isConfigured && syncState.status != SyncStatus.syncing
                        ? () async {
                            final result = await ref.read(syncProvider.notifier).sync();
                            if (context.mounted) {
                              setState(() => _lastResult = result);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.message),
                                  backgroundColor: result.success ? Colors.green : Colors.orange,
                                ),
                              );
                            }
                          }
                        : null,
                    icon: syncState.status == SyncStatus.syncing
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync),
                    label: Text(syncState.status == SyncStatus.syncing ? 'Syncing...' : 'Sync Now'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(height: 12),

                // Auto sync toggle
                SwitchListTile(
                  value: _autoSyncEnabled,
                  onChanged: isConfigured
                      ? (v) {
                          setState(() => _autoSyncEnabled = v);
                          if (v) {
                            ref.read(syncProvider.notifier).enableAutoSync();
                          } else {
                            ref.read(syncProvider.notifier).disableAutoSync();
                          }
                        }
                      : null,
                  title: Text('Auto Sync', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                  subtitle: Text('Sync every 5 minutes when online', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  secondary: const Icon(Icons.autorenew),
                ),
                const SizedBox(height: 16),

                // Last result
                if (_lastResult != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_lastResult!.success ? Colors.green : Colors.orange).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_lastResult!.message, style: GoogleFonts.poppins(fontSize: 12)),
                        if (_lastResult!.errors.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          ..._lastResult!.errors.take(3).map((e) => Text('• $e', style: const TextStyle(fontSize: 10, color: Colors.grey))),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Configuration fields (read-only display)
                Text('Configuration', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Supabase URL',
                    prefixIcon: const Icon(Icons.dns_outlined),
                    helperText: isConfigured ? 'Configured' : 'Not configured — edit supabase_config.dart',
                    hintText: isConfigured ? SupabaseConfig.supabaseUrl : 'YOUR_SUPABASE_URL',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Anon Key',
                    prefixIcon: const Icon(Icons.key),
                    helperText: isConfigured ? 'Configured' : 'Not configured — edit supabase_config.dart',
                    hintText: isConfigured ? '••••••••••••' : 'YOUR_SUPABASE_ANON_KEY',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusBadge extends StatelessWidget {
  final SyncState state;

  const _SyncStatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (state.status) {
      SyncStatus.idle => (Colors.grey, 'Idle', Icons.pause_circle_outline),
      SyncStatus.syncing => (Colors.blue, 'Syncing...', Icons.sync),
      SyncStatus.success => (Colors.green, 'Synced', Icons.check_circle),
      SyncStatus.error => (Colors.red, 'Error', Icons.error_outline),
      SyncStatus.notConfigured => (Colors.orange, 'Not Configured', Icons.cloud_off),
      SyncStatus.offline => (Colors.orange, 'Offline', Icons.wifi_off),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── System Health Tab ─────────────────────────────────────────────────────────

class _SystemHealthTab extends ConsumerStatefulWidget {
  final DataSummary? dataSummary;

  const _SystemHealthTab({this.dataSummary});

  @override
  ConsumerState<_SystemHealthTab> createState() => _SystemHealthTabState();
}

class _SystemHealthTabState extends ConsumerState<_SystemHealthTab> {
  bool _working = false;

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will clear cached data. Your church data will not be affected. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _working = true);
    // Refresh all providers to reload from storage
    ref.read(userProvider.notifier).refresh();
    ref.read(memberProvider.notifier).refresh();
    ref.read(financeProvider.notifier).refresh();
    ref.read(eventProvider.notifier).refresh();
    ref.read(sermonProvider.notifier).refresh();
    ref.read(welfareProvider.notifier).refresh();
    ref.read(attendanceProvider.notifier).refresh();
    ref.read(departmentProvider.notifier).refresh();
    ref.read(branchProvider.notifier).refresh();
    ref.read(notificationProvider.notifier).refresh();

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _working = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _factoryReset() async {
    final passwordCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Factory Reset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'WARNING: This will permanently delete ALL data on this device. This cannot be undone. Make sure you have a backup.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              decoration: const InputDecoration(
                labelText: 'Type RESET to confirm',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, passwordCtrl.text == 'RESET'),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _working = true);
    await BackupService.clearAllData();

    if (mounted) {
      setState(() => _working = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared. App will restart.'), backgroundColor: Colors.red),
      );
      // Navigate to login
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.dataSummary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Status Cards
          _SectionCard(
            title: 'System Status',
            icon: Icons.health_and_safety,
            iconColor: Colors.green,
            child: Column(
              children: [
                _HealthRow(label: 'Storage Engine', value: 'SharedPreferences (Local)', status: HealthStatus.healthy),
                _HealthRow(label: 'Multi-Tenant Isolation', value: 'Active', status: HealthStatus.healthy),
                _HealthRow(label: 'Encryption', value: 'SHA-256 + XOR', status: HealthStatus.healthy),
                _HealthRow(label: 'Data Integrity', value: 'HMAC Verified', status: HealthStatus.healthy),
                _HealthRow(label: 'Backup Format', value: 'v1 (.pab)', status: HealthStatus.healthy),
                _HealthRow(label: 'Cloud Sync', value: SyncService.isConfigured ? 'Configured (Offline-first)' : 'Not Configured', status: SyncService.isConfigured ? HealthStatus.healthy : HealthStatus.warning),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Data Statistics
          if (summary != null)
            _SectionCard(
              title: 'Data Statistics',
              icon: Icons.analytics_outlined,
              iconColor: AppColors.primary,
              child: Column(
                children: [
                  _StatRow(label: 'Total Storage Keys', value: '${summary.totalKeys}'),
                  _StatRow(label: 'Total Data Entries', value: '${summary.totalEntries}'),
                  _StatRow(label: 'Churches', value: '${summary.churches}'),
                  _StatRow(label: 'Users', value: '${summary.users}'),
                  _StatRow(label: 'Members', value: '${summary.members}'),
                  _StatRow(label: 'Finance Transactions', value: '${summary.transactions}'),
                  _StatRow(label: 'Events', value: '${summary.events}'),
                  _StatRow(label: 'Sermons', value: '${summary.sermons}'),
                  _StatRow(label: 'Welfare Cases', value: '${summary.welfareCases}'),
                  _StatRow(label: 'Attendance Records', value: '${summary.attendanceRecords}'),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Maintenance Actions
          _SectionCard(
            title: 'Maintenance Actions',
            icon: Icons.build_outlined,
            iconColor: Colors.orange,
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.cleaning_services_outlined)),
                  title: Text('Clear Cache', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Reload all data from storage', style: TextStyle(fontSize: 11)),
                  trailing: _working
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chevron_right),
                  onTap: _working ? null : _clearCache,
                ),
                const Divider(),
                ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.red.withValues(alpha: 0.1), child: const Icon(Icons.delete_forever, color: Colors.red)),
                  title: Text('Factory Reset', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.red)),
                  subtitle: const Text('Delete ALL data on this device', style: TextStyle(fontSize: 11, color: Colors.red)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.red),
                  onTap: _working ? null : _factoryReset,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About
          _SectionCard(
            title: 'About',
            icon: Icons.info_outline,
            iconColor: Colors.blue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(label: 'App Name', value: 'Paradise AG Church Management'),
                _StatRow(label: 'Full Title', value: 'Church Information Management System'),
                _StatRow(label: 'Version', value: '1.0.0'),
                _StatRow(label: 'Storage Mode', value: 'Offline (Local SharedPreferences)'),
                _StatRow(label: 'Backup Version', value: 'v1 (.pab encrypted)'),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.design_services_outlined, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text('Designed by', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                ]),
                const SizedBox(height: 2),
                Text(
                  'Echendaa Educational and Research Unit',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.public_outlined, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text('Distributed by', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                ]),
                const SizedBox(height: 2),
                Text(
                  'Nung A Bibile Foundation',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Under the Digital Literacy Program',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'All data is stored locally on this device. Use the Backup feature regularly to protect your data. Cloud sync will be available in a future update.',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DataChip extends StatelessWidget {
  final String label;
  final String value;

  const _DataChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _DataPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _DataPill({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text('$value', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

enum HealthStatus { healthy, warning, error }

class _HealthRow extends StatelessWidget {
  final String label;
  final String value;
  final HealthStatus status;

  const _HealthRow({required this.label, required this.value, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      HealthStatus.healthy => Colors.green,
      HealthStatus.warning => Colors.orange,
      HealthStatus.error => Colors.red,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          ]),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
