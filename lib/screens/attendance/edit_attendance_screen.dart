import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/attendance_record.dart';
import '../../models/member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';

class EditAttendanceScreen extends ConsumerStatefulWidget {
  final String recordId;

  const EditAttendanceScreen({super.key, required this.recordId});

  @override
  ConsumerState<EditAttendanceScreen> createState() =>
      _EditAttendanceScreenState();
}

class _EditAttendanceScreenState
    extends ConsumerState<EditAttendanceScreen> {
  String _serviceType = ServiceTypes.sundayService;
  DateTime _date = DateTime.now();
  String? _branchId;
  final Set<String> _presentIds = {};
  bool _loading = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadAttendanceRecord();
  }

  void _loadAttendanceRecord() {
    final record = LocalDb.getAttendanceRecordById(widget.recordId);
    if (record != null) {
      setState(() {
        _serviceType = record.serviceType;
        _date = record.date;
        _branchId = record.branchId;
        _presentIds.addAll(record.presentMemberIds);
      });
    }
  }

  List<Member> _branchMembers(List<Member> all) {
    if (_branchId == null || _branchId!.isEmpty) return all;
    return all.where((m) => m.branchId == _branchId).toList();
  }

  List<Member> _filtered(List<Member> members) {
    if (_search.isEmpty) return members;
    final q = _search.toLowerCase();
    return members
        .where((m) =>
            m.name.toLowerCase().contains(q) ||
            m.phone.contains(q))
        .toList();
  }

  void _markAll(List<Member> members, bool present) {
    setState(() {
      if (present) {
        _presentIds.addAll(members.map((m) => m.id));
      } else {
        _presentIds.removeAll(members.map((m) => m.id));
      }
    });
  }

  Future<void> _save() async {
    if (_branchId == null || _branchId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a branch')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final existingRecord = LocalDb.getAttendanceRecordById(widget.recordId);
      if (existingRecord == null) {
        throw Exception('Attendance record not found');
      }

      final updatedRecord = AttendanceRecord(
        id: existingRecord.id,
        churchId: existingRecord.churchId,
        branchId: _branchId!,
        serviceType: _serviceType,
        date: _date,
        presentMemberIds: _presentIds.toList(),
        recordedById: existingRecord.recordedById,
        createdAt: existingRecord.createdAt,
      );
      await ref.read(attendanceProvider.notifier).update(updatedRecord);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance updated'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allMembers = ref.watch(memberProvider);
    final branches = ref.watch(branchProvider);
    final user = ref.watch(appStateProvider).user!;
    final isSuperAdmin = AppRoles.crossBranchRoles.contains(user.role);

    final branchMembers = _branchMembers(allMembers)
        .where((m) => m.isActive)
        .toList();
    final visibleMembers = _filtered(branchMembers);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Attendance'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Session info panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _serviceType,
                  decoration: const InputDecoration(
                    labelText: 'Service Type',
                    prefixIcon: Icon(Icons.church),
                    isDense: true,
                  ),
                  items: ServiceTypes.all
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _serviceType = v!),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      isDense: true,
                    ),
                    child: Text(
                      DateFormat('EEE, MMM d, yyyy').format(_date),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ),
                if (isSuperAdmin && branches.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _branchId,
                    decoration: const InputDecoration(
                      labelText: 'Branch',
                      prefixIcon: Icon(Icons.account_tree),
                      isDense: true,
                    ),
                    hint: const Text('Select branch'),
                    items: branches
                        .map((b) =>
                            DropdownMenuItem(value: b.id, child: Text(b.name)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _branchId = v;
                      _presentIds.clear();
                    }),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Attendance header
          if (_branchId != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '${_presentIds.intersection(branchMembers.map((m) => m.id).toSet()).length} / ${branchMembers.length} present',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primary),
                  ),
                  Text('Active members',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary)),
                ]),
                const Spacer(),
                TextButton(
                  onPressed: () => _markAll(branchMembers, true),
                  child: const Text('Mark All'),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => _markAll(branchMembers, false),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary),
                  child: const Text('Clear'),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search members…',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _search = ''),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],

          Expanded(
            child: _branchId == null
                ? Center(
                    child: Text(
                      isSuperAdmin
                          ? 'Select a branch to start'
                          : 'No branch assigned to your account',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary),
                    ),
                  )
                : visibleMembers.isEmpty
                    ? Center(
                        child: Text(
                          _search.isEmpty
                              ? 'No active members in this branch'
                              : 'No results for "$_search"',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: visibleMembers.length,
                        itemBuilder: (_, i) {
                          final member = visibleMembers[i];
                          final isPresent =
                              _presentIds.contains(member.id);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: CheckboxListTile(
                              value: isPresent,
                              onChanged: (_) => setState(() {
                                if (isPresent) {
                                  _presentIds.remove(member.id);
                                } else {
                                  _presentIds.add(member.id);
                                }
                              }),
                              title: Text(
                                member.name,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                              subtitle: member.phone.isNotEmpty
                                  ? Text(member.phone,
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.textSecondary))
                                  : null,
                              secondary: CircleAvatar(
                                backgroundColor: isPresent
                                    ? AppColors.success
                                    : Colors.grey.shade300,
                                radius: 18,
                                child: Text(
                                  member.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: isPresent
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              activeColor: AppColors.success,
                              controlAffinity:
                                  ListTileControlAffinity.trailing,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
