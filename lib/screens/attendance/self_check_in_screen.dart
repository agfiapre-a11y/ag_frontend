import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/attendance_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/gps_service.dart';

class SelfCheckInScreen extends ConsumerStatefulWidget {
  const SelfCheckInScreen({super.key});

  @override
  ConsumerState<SelfCheckInScreen> createState() => _SelfCheckInScreenState();
}

class _SelfCheckInScreenState extends ConsumerState<SelfCheckInScreen> {
  bool _loading = false;
  bool _gpsLoading = false;
  double? _myLat;
  double? _myLng;
  String? _resultMessage;
  bool _checkInSuccess = false;

  Future<void> _getLocation() async {
    setState(() {
      _gpsLoading = true;
      _resultMessage = null;
    });
    try {
      final loc = await GpsService.getCurrentLocation();
      setState(() {
        _myLat = loc.latitude;
        _myLng = loc.longitude;
      });
    } catch (e) {
      setState(() {
        _resultMessage = e.toString();
        _checkInSuccess = false;
      });
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _checkIn(AttendanceRecord record) async {
    if (_myLat == null || _myLng == null) {
      await _getLocation();
      if (_myLat == null || _myLng == null) return;
    }

    setState(() {
      _loading = true;
      _resultMessage = null;
    });

    try {
      final result = await ref
          .read(attendanceProvider.notifier)
          .selfCheckIn(record.id, _myLat!, _myLng!);

      setState(() {
        _checkInSuccess = result.success;
        _resultMessage = result.message;
      });
    } catch (e) {
      setState(() {
        _resultMessage = e.toString();
        _checkInSuccess = false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceRecords = ref.watch(attendanceProvider);
    final user = ref.watch(appStateProvider).user!;

    // Filter to active sessions with GPS enabled, today's date
    final today = DateTime.now();
    final activeSessions = attendanceRecords.where((r) {
      if (!r.isActive) return false;
      if (!r.hasGpsLocation) return false;
      final rDate = DateTime(r.date.year, r.date.month, r.date.day);
      final tDate = DateTime(today.year, today.month, today.day);
      return rDate.isAtSameMomentAs(tDate);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Self Check-In'),
      ),
      body: Column(
        children: [
          // GPS status card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _myLat != null
                  ? Colors.green.shade50
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _myLat != null
                    ? Colors.green.shade200
                    : Colors.blue.shade200,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _myLat != null ? Icons.location_on : Icons.location_searching,
                  size: 40,
                  color: _myLat != null ? Colors.green : Colors.blue,
                ),
                const SizedBox(height: 8),
                Text(
                  _myLat != null
                      ? 'Your location is ready'
                      : 'Get your location to check in',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (_myLat != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lat: ${_myLat!.toStringAsFixed(6)}, Lng: ${_myLng!.toStringAsFixed(6)}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _gpsLoading ? null : _getLocation,
                    icon: _gpsLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: Text(
                      _myLat != null ? 'Update Location' : 'Get My Location',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _myLat != null ? Colors.green : AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Result message
          if (_resultMessage != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _checkInSuccess
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _checkInSuccess
                      ? Colors.green.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _checkInSuccess ? Icons.check_circle : Icons.cancel,
                    color: _checkInSuccess ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _resultMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _checkInSuccess
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Active attendance sessions
          Expanded(
            child: activeSessions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_busy,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No active attendance sessions',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back when your church admin has opened an attendance session with GPS enabled.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: activeSessions.length,
                    itemBuilder: (context, index) {
                      final record = activeSessions[index];
                      final alreadyCheckedIn =
                          record.presentMemberIds.contains(user.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.church,
                                      color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      record.serviceType,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('EEE, MMM d, yyyy')
                                        .format(record.date),
                                    style: GoogleFonts.poppins(
                                        fontSize: 13, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Radius: ${record.proximityRadius}m',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.people,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${record.presentCount} checked in',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: alreadyCheckedIn
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.green.shade200),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.check_circle,
                                                color: Colors.green),
                                            const SizedBox(width: 8),
                                            Text(
                                              'You are checked in',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ElevatedButton.icon(
                                        onPressed: (_loading || _myLat == null)
                                            ? null
                                            : () => _checkIn(record),
                                        icon: _loading
                                            ? const SizedBox(
                                                height: 16,
                                                width: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2))
                                            : const Icon(Icons.how_to_reg),
                                        label: Text(
                                          'Check In',
                                          style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                      ),
                              ),
                            ],
                          ),
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
