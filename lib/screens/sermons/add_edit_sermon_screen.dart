import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../models/attendance_record.dart';
import '../../models/sermon.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';

class AddEditSermonScreen extends ConsumerStatefulWidget {
  final String? sermonId; // null = add mode

  const AddEditSermonScreen({super.key, this.sermonId});

  @override
  ConsumerState<AddEditSermonScreen> createState() =>
      _AddEditSermonScreenState();
}

class _AddEditSermonScreenState extends ConsumerState<AddEditSermonScreen> {
  final _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _speakerCtrl = TextEditingController();
  final _seriesCtrl = TextEditingController();
  final _scriptureCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _audioCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();

  String _serviceType = ServiceTypes.sundayService;
  DateTime _date = DateTime.now();
  String? _branchId;
  bool _loading = false;
  Sermon? _existing;

  bool get _isEdit => widget.sermonId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _existing = LocalDb.getSermonById(widget.sermonId!);
      if (_existing != null) {
        _titleCtrl.text = _existing!.title;
        _speakerCtrl.text = _existing!.speaker;
        _seriesCtrl.text = _existing!.series;
        _scriptureCtrl.text = _existing!.scriptureReference;
        _notesCtrl.text = _existing!.notes;
        _audioCtrl.text = _existing!.audioUrl;
        _videoCtrl.text = _existing!.videoUrl;
        _serviceType = _existing!.serviceType.isNotEmpty
            ? _existing!.serviceType
            : ServiceTypes.sundayService;
        _date = _existing!.date;
        _branchId = _existing!.branchId.isNotEmpty ? _existing!.branchId : null;
      }
    } else {
      final user = ref.read(appStateProvider).user!;
      if (!AppRoles.crossBranchRoles.contains(user.role) &&
          user.branchId.isNotEmpty) {
        _branchId = user.branchId;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _speakerCtrl.dispose();
    _seriesCtrl.dispose();
    _scriptureCtrl.dispose();
    _notesCtrl.dispose();
    _audioCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = ref.read(appStateProvider);
    final user = appState.user!;
    final isSuperAdmin = AppRoles.crossBranchRoles.contains(user.role);

    if (isSuperAdmin && (_branchId == null || _branchId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a branch')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final sermon = _isEdit && _existing != null
          ? _existing!.copyWith(
              title: _titleCtrl.text.trim(),
              speaker: _speakerCtrl.text.trim(),
              series: _seriesCtrl.text.trim(),
              scriptureReference: _scriptureCtrl.text.trim(),
              notes: _notesCtrl.text.trim(),
              audioUrl: _audioCtrl.text.trim(),
              videoUrl: _videoCtrl.text.trim(),
              serviceType: _serviceType,
              date: _date,
              branchId: _branchId ?? user.branchId,
            )
          : Sermon(
              id: _uuid.v4(),
              churchId: appState.church?.id ?? "",
              branchId: _branchId ?? user.branchId,
              title: _titleCtrl.text.trim(),
              speaker: _speakerCtrl.text.trim(),
              series: _seriesCtrl.text.trim(),
              scriptureReference: _scriptureCtrl.text.trim(),
              notes: _notesCtrl.text.trim(),
              audioUrl: _audioCtrl.text.trim(),
              videoUrl: _videoCtrl.text.trim(),
              serviceType: _serviceType,
              date: _date,
              recordedById: user.id,
              createdAt: DateTime.now(),
            );

      await ref.read(sermonProvider.notifier).save(sermon);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_isEdit ? 'Sermon updated' : 'Sermon added'),
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
    final user = ref.watch(appStateProvider).user!;
    final branches = ref.watch(branchProvider);
    final isSuperAdmin = AppRoles.crossBranchRoles.contains(user.role);

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEdit ? 'Edit Sermon' : 'Add Sermon')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Sermon Details'),
              const SizedBox(height: 12),
              _field(_titleCtrl, 'Sermon Title', Icons.title, required: true),
              const SizedBox(height: 12),
              _field(_speakerCtrl, 'Speaker / Preacher', Icons.person_outline,
                  required: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _serviceType,
                decoration: const InputDecoration(
                  labelText: 'Service Type',
                  prefixIcon: Icon(Icons.church),
                ),
                items: ServiceTypes.all
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _serviceType = v!),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _date = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('EEE, MMM d, yyyy').format(_date),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel('References'),
              const SizedBox(height: 12),
              _field(_scriptureCtrl, 'Scripture Reference (e.g. John 3:16)',
                  Icons.menu_book),
              const SizedBox(height: 12),
              _field(_seriesCtrl, 'Series Name (optional)', Icons.layers),
              const SizedBox(height: 20),
              _sectionLabel('Notes'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Sermon Notes / Outline (optional)',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Media Links (optional)'),
              const SizedBox(height: 12),
              _field(_audioCtrl, 'Audio URL', Icons.headphones,
                  type: TextInputType.url),
              const SizedBox(height: 12),
              _field(_videoCtrl, 'Video URL', Icons.play_circle_outline,
                  type: TextInputType.url),
              if (isSuperAdmin && branches.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionLabel('Branch'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _branchId,
                  decoration: const InputDecoration(
                    labelText: 'Branch *',
                    prefixIcon: Icon(Icons.account_tree),
                  ),
                  hint: const Text('Select branch'),
                  items: branches
                      .map((b) =>
                          DropdownMenuItem(value: b.id, child: Text(b.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _branchId = v),
                ),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(_isEdit ? 'Save Changes' : 'Add Sermon'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontSize: 13),
      );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? type,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}
