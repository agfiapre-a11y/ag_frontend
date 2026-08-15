import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../models/attendance_record.dart';
import '../../models/member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/gps_service.dart';

class TakeAttendanceScreen extends ConsumerStatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  ConsumerState<TakeAttendanceScreen> createState() =>
      _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState
    extends ConsumerState<TakeAttendanceScreen> {
  final _uuid = const Uuid();
  String _serviceType = ServiceTypes.sundayService;
  DateTime _date = DateTime.now();
  final Set<String> _presentIds = {};
  bool _loading = false;
  String _search = '';

  // GPS fields
  double? _latitude;
  double? _longitude;
  int _proximityRadius = 100;
  bool _gpsLoading = false;
  bool _enableGps = false;

  @override
  void initState() {
    super.initState();
  }

  List<Member> _branchMembers(List<Member> all) {
    return all;
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

  Future<void> _captureGps() async {
    setState(() => _gpsLoading = true);
    try {
      final loc = await GpsService.getCurrentLocation();
      setState(() {
        _latitude = loc.latitude;
        _longitude = loc.longitude;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS location captured'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _save() async {
    final appState = ref.read(appStateProvider);
    final user = appState.user!;

    if (_enableGps && (_latitude == null || _longitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture GPS location first')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final record = AttendanceRecord(
        id: _uuid.v4(),
        churchId: appState.church?.id ?? "",
        branchId: '',
        serviceType: _serviceType,
        date: _date,
        presentMemberIds: _presentIds.toList(),
        recordedById: user.id,
        createdAt: DateTime.now(),
        latitude: _enableGps ? _latitude : null,
        longitude: _enableGps ? _longitude : null,
        proximityRadius: _enableGps ? _proximityRadius : 100,
      );
      final error = await ref.read(attendanceProvider.notifier).save(record);
      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved locally: $error'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance saved'),
              backgroundColor: Colors.green,
            ),
          );
        }
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

    final branchMembers = _branchMembers(allMembers)
        .where((m) => m.isActive)
        .toList();
    final visibleMembers = _filtered(branchMembers);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Attendance'),
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
                // GPS Proximity Section
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _enableGps,
                  onChanged: (v) => setState(() => _enableGps = v),
                  title: Text(
                    'Enable GPS Self-Check-In',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Members can check in from their phone within the set radius',
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                if (_enableGps) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _gpsLoading ? null : _captureGps,
                          icon: _gpsLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.my_location),
                          label: Text(
                            _latitude != null
                                ? 'Location Captured'
                                : 'Capture My Location',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _latitude != null
                                ? AppColors.success
                                : AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_latitude != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.green.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Proximity Radius: ${_proximityRadius}m',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: _proximityRadius.toDouble(),
                    min: 10,
                    max: 500,
                    divisions: 49,
                    thumbColor: AppColors.primary,
                    label: '${_proximityRadius}m',
                    onChanged: (v) =>
                        setState(() => _proximityRadius = v.round()),
                  ),
                  Text(
                    'Members within ${_proximityRadius}m of this location can mark themselves present from their device.',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Attendance header
          if (_enableGps)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GPS self-check-in enabled. You can also manually mark members below.',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.blue.shade800),
                    ),
                  ),
                ],
              ),
            ),
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

          Expanded(
            child: visibleMembers.isEmpty
                ? Center(
                    child: Text(
                      _search.isEmpty
                          ? 'No active members'
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
