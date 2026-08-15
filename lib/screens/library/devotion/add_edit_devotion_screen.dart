import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants.dart';
import '../../../models/devotion_guide.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../services/local_db.dart';

class AddEditDevotionScreen extends ConsumerStatefulWidget {
  final String? devotionId; // null = add mode

  const AddEditDevotionScreen({super.key, this.devotionId});

  @override
  ConsumerState<AddEditDevotionScreen> createState() =>
      _AddEditDevotionScreenState();
}

class _AddEditDevotionScreenState
    extends ConsumerState<AddEditDevotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  final _titleCtrl = TextEditingController();
  final _scriptureRefCtrl = TextEditingController();
  final _scriptureTextCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final List<TextEditingController> _prayerPointCtrls = [];

  DateTime _date = DateTime.now();
  bool _loading = false;
  DevotionGuide? _existing;

  bool get _isEdit => widget.devotionId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _existing = LocalDb.getDevotionGuideById(widget.devotionId!);
      if (_existing != null) {
        _titleCtrl.text = _existing!.title;
        _scriptureRefCtrl.text = _existing!.scriptureReference;
        _scriptureTextCtrl.text = _existing!.scriptureText;
        _contentCtrl.text = _existing!.content;
        _authorCtrl.text = _existing!.author;
        _date = _existing!.date;
        for (final p in _existing!.prayerPoints) {
          _prayerPointCtrls.add(TextEditingController(text: p));
        }
      }
    }
    if (_prayerPointCtrls.isEmpty) {
      _prayerPointCtrls.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _scriptureRefCtrl.dispose();
    _scriptureTextCtrl.dispose();
    _contentCtrl.dispose();
    _authorCtrl.dispose();
    for (final c in _prayerPointCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = ref.read(appStateProvider);
    final user = appState.user!;
    final prayerPoints = _prayerPointCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    setState(() => _loading = true);
    try {
      final devotion = _isEdit && _existing != null
          ? _existing!.copyWith(
              title: _titleCtrl.text.trim(),
              scriptureReference: _scriptureRefCtrl.text.trim(),
              scriptureText: _scriptureTextCtrl.text.trim(),
              content: _contentCtrl.text.trim(),
              prayerPoints: prayerPoints,
              author: _authorCtrl.text.trim(),
              date: _date,
            )
          : DevotionGuide(
              id: _uuid.v4(),
              churchId: appState.church?.id ?? '',
              title: _titleCtrl.text.trim(),
              scriptureReference: _scriptureRefCtrl.text.trim(),
              scriptureText: _scriptureTextCtrl.text.trim(),
              content: _contentCtrl.text.trim(),
              prayerPoints: prayerPoints,
              author: _authorCtrl.text.trim(),
              date: _date,
              addedById: user.id,
              createdAt: DateTime.now(),
            );

      await ref.read(devotionGuideProvider.notifier).save(devotion);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Devotion updated' : 'Devotion added'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(_isEdit ? 'Edit Devotion' : 'Add Devotion')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Devotion Details'),
              const SizedBox(height: 12),
              _field(_titleCtrl, 'Title', Icons.title, required: true),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
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
              _sectionLabel('Scripture'),
              const SizedBox(height: 12),
              _field(_scriptureRefCtrl,
                  'Scripture Reference (e.g. Psalm 23:1)', Icons.menu_book),
              const SizedBox(height: 12),
              TextFormField(
                controller: _scriptureTextCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Scripture Text (optional)',
                  prefixIcon: Icon(Icons.format_quote),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Devotional'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentCtrl,
                maxLines: 8,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Devotional content is required'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Devotional message',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionLabel('Prayer Points'),
                  TextButton.icon(
                    onPressed: () => setState(
                        () => _prayerPointCtrls.add(TextEditingController())),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add point'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._prayerPointCtrls.asMap().entries.map((entry) {
                final i = entry.key;
                final ctrl = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: ctrl,
                          decoration: InputDecoration(
                            labelText: 'Prayer point ${i + 1}',
                            prefixIcon: const Icon(Icons.church),
                          ),
                        ),
                      ),
                      if (_prayerPointCtrls.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () => setState(() {
                            _prayerPointCtrls.removeAt(i).dispose();
                          }),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              _field(_authorCtrl, 'Author / Contributor (optional)',
                  Icons.person_outline),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(_isEdit ? 'Save Changes' : 'Add Devotion'),
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
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}
