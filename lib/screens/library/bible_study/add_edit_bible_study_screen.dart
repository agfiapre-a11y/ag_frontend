import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants.dart';
import '../../../models/bible_study_resource.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../services/local_db.dart';

class AddEditBibleStudyScreen extends ConsumerStatefulWidget {
  final String? studyId; // null = add mode

  const AddEditBibleStudyScreen({super.key, this.studyId});

  @override
  ConsumerState<AddEditBibleStudyScreen> createState() =>
      _AddEditBibleStudyScreenState();
}

class _AddEditBibleStudyScreenState
    extends ConsumerState<AddEditBibleStudyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _scriptureRefsCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final List<TextEditingController> _questionCtrls = [];

  String _category = BibleStudyCategory.foundations;
  bool _loading = false;
  BibleStudyResource? _existing;

  bool get _isEdit => widget.studyId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _existing = LocalDb.getBibleStudyResourceById(widget.studyId!);
      if (_existing != null) {
        _titleCtrl.text = _existing!.title;
        _descriptionCtrl.text = _existing!.description;
        _scriptureRefsCtrl.text = _existing!.scriptureReferences;
        _contentCtrl.text = _existing!.content;
        _category = _existing!.category;
        for (final q in _existing!.discussionQuestions) {
          _questionCtrls.add(TextEditingController(text: q));
        }
      }
    }
    if (_questionCtrls.isEmpty) {
      _questionCtrls.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _scriptureRefsCtrl.dispose();
    _contentCtrl.dispose();
    for (final c in _questionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = ref.read(appStateProvider);
    final user = appState.user!;
    final questions = _questionCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    setState(() => _loading = true);
    try {
      final study = _isEdit && _existing != null
          ? _existing!.copyWith(
              title: _titleCtrl.text.trim(),
              category: _category,
              description: _descriptionCtrl.text.trim(),
              scriptureReferences: _scriptureRefsCtrl.text.trim(),
              content: _contentCtrl.text.trim(),
              discussionQuestions: questions,
            )
          : BibleStudyResource(
              id: _uuid.v4(),
              churchId: appState.church?.id ?? '',
              title: _titleCtrl.text.trim(),
              category: _category,
              description: _descriptionCtrl.text.trim(),
              scriptureReferences: _scriptureRefsCtrl.text.trim(),
              content: _contentCtrl.text.trim(),
              discussionQuestions: questions,
              addedById: user.id,
              createdAt: DateTime.now(),
            );

      await ref.read(bibleStudyResourceProvider.notifier).save(study);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_isEdit ? 'Bible study updated' : 'Bible study added'),
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
      appBar: AppBar(
          title: Text(_isEdit ? 'Edit Bible Study' : 'Add Bible Study')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Study Details'),
              const SizedBox(height: 12),
              _field(_titleCtrl, 'Title', Icons.title, required: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: BibleStudyCategory.all
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              _field(_scriptureRefsCtrl,
                  'Scripture References (e.g. Romans 1-8)', Icons.menu_book),
              const SizedBox(height: 20),
              _sectionLabel('Overview'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Short overview (optional)',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Study Content'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentCtrl,
                maxLines: 8,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Study content is required'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Main teaching / study body',
                  prefixIcon: Icon(Icons.article_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionLabel('Discussion Questions'),
                  TextButton.icon(
                    onPressed: () => setState(
                        () => _questionCtrls.add(TextEditingController())),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add question'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._questionCtrls.asMap().entries.map((entry) {
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
                            labelText: 'Question ${i + 1}',
                            prefixIcon: const Icon(Icons.help_outline),
                          ),
                        ),
                      ),
                      if (_questionCtrls.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () => setState(() {
                            _questionCtrls.removeAt(i).dispose();
                          }),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(_isEdit ? 'Save Changes' : 'Add Bible Study'),
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
