import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';

class AddEditEventScreen extends ConsumerStatefulWidget {
  final String? eventId;

  const AddEditEventScreen({super.key, this.eventId});

  @override
  ConsumerState<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends ConsumerState<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _organizerCtrl;

  String _category = EventCategory.sundayService;
  bool _isAllDay = false;
  late DateTime _startDate;
  late DateTime _startTime;
  late DateTime _endDate;
  late DateTime _endTime;
  bool _isSaving = false;

  ChurchEvent? _existing;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final roundedHour = DateTime(now.year, now.month, now.day, now.hour + 1);

    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _locationCtrl = TextEditingController();
    _organizerCtrl = TextEditingController();

    _startDate = now;
    _startTime = roundedHour;
    _endDate = now;
    _endTime = roundedHour.add(const Duration(hours: 2));

    if (widget.eventId != null) {
      _existing = LocalDb.getEventById(widget.eventId!);
      if (_existing != null) {
        _titleCtrl.text = _existing!.title;
        _descCtrl.text = _existing!.description;
        _locationCtrl.text = _existing!.location;
        _organizerCtrl.text = _existing!.organizer;
        _category = _existing!.category;
        _isAllDay = _existing!.isAllDay;
        _startDate = _existing!.startDate;
        _startTime = _existing!.startDate;
        _endDate = _existing!.endDate;
        _endTime = _existing!.endDate;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _organizerCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => _existing != null;

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    setState(() {
      if (isStart) {
        _startDate = date;
        if (_endDate.isBefore(date)) _endDate = date;
      } else {
        _endDate = date;
      }
    });
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final ref = isStart ? _startDate : _endDate;
    final updated =
        DateTime(ref.year, ref.month, ref.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = updated;
      } else {
        _endTime = updated;
      }
    });
  }

  DateTime _combinedStart() {
    if (_isAllDay) {
      return DateTime(_startDate.year, _startDate.month, _startDate.day);
    }
    return DateTime(_startDate.year, _startDate.month, _startDate.day,
        _startTime.hour, _startTime.minute);
  }

  DateTime _combinedEnd() {
    if (_isAllDay) {
      return DateTime(
          _endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
    }
    return DateTime(_endDate.year, _endDate.month, _endDate.day,
        _endTime.hour, _endTime.minute);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final start = _combinedStart();
    final end = _combinedEnd();
    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('End date/time cannot be before start'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final appState = ref.read(appStateProvider);
      final user = appState.user!;
      final churchId = appState.church?.id ?? "";

      final departmentId = user.role == AppRoles.ministryHead
          ? user.departmentId
          : (_existing?.departmentId ?? '');

      final event = ChurchEvent(
        id: _existing?.id ?? const Uuid().v4(),
        churchId: churchId,
        branchId: '',
        departmentId: departmentId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        location: _locationCtrl.text.trim(),
        organizer: _organizerCtrl.text.trim(),
        startDate: start,
        endDate: end,
        isAllDay: _isAllDay,
        recordedById: user.id,
        createdAt: _existing?.createdAt ?? DateTime.now(),
      );

      await ref.read(eventProvider.notifier).save(event);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Event updated' : 'Event created'),
          backgroundColor: AppColors.success,
        ));
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Event' : 'New Event'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader('Event Details'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title *',
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: EventCategory.all
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _organizerCtrl,
              decoration: const InputDecoration(
                labelText: 'Organizer',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            _SectionHeader('Date & Time'),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('All-day event'),
              subtitle: const Text('No specific start/end time'),
              value: _isAllDay,
              onChanged: (v) => setState(() => _isAllDay = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            // Start row
            Row(children: [
              Expanded(
                child: _DateTimeTile(
                  label: 'Start date',
                  text: DateFormat('EEE, MMM d, yyyy').format(_startDate),
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _pickDate(true),
                ),
              ),
              if (!_isAllDay) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTimeTile(
                    label: 'Start time',
                    text: DateFormat('h:mm a').format(_startTime),
                    icon: Icons.access_time,
                    onTap: () => _pickTime(true),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 12),
            // End row
            Row(children: [
              Expanded(
                child: _DateTimeTile(
                  label: 'End date',
                  text: DateFormat('EEE, MMM d, yyyy').format(_endDate),
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _pickDate(false),
                ),
              ),
              if (!_isAllDay) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTimeTile(
                    label: 'End time',
                    text: DateFormat('h:mm a').format(_endTime),
                    icon: Icons.access_time,
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 24),
            _SectionHeader('Description'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: Icon(_isEdit ? Icons.save_outlined : Icons.event_note),
              label: Text(_isEdit ? 'Save Changes' : 'Create Event'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: AppColors.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final String label;
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _DateTimeTile({
    required this.label,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(icon, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(text,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
