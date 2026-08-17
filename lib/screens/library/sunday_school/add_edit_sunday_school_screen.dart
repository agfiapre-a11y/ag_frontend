import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants.dart';
import '../../../models/sunday_school_book.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../services/local_db.dart';
import '../../../services/sunday_school_service.dart';

class AddEditSundaySchoolScreen extends ConsumerStatefulWidget {
  final String? bookId; // null = add mode

  const AddEditSundaySchoolScreen({super.key, this.bookId});

  @override
  ConsumerState<AddEditSundaySchoolScreen> createState() =>
      _AddEditSundaySchoolScreenState();
}

class _AddEditSundaySchoolScreenState
    extends ConsumerState<AddEditSundaySchoolScreen> {
  static const _uuid = Uuid();
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));

  bool _loading = false;
  bool _processing = false;
  SundaySchoolBook? _existing;

  // Holds the result of PDF picking + chapter extraction
  SundaySchoolUploadResult? _uploadResult;
  String? _pickedFileName;

  bool get _isEdit => widget.bookId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _existing = LocalDb.getSundaySchoolBookById(widget.bookId!);
      if (_existing != null) {
        _titleCtrl.text = _existing!.title;
        _authorCtrl.text = _existing!.author;
        _descriptionCtrl.text = _existing!.description;
        _startDate = _existing!.startDate;
        _endDate = _existing!.endDate;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_startDate) ? _endDate : _startDate.add(const Duration(days: 30)),
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _pickPdf() async {
    setState(() {
      _processing = true;
      _loading = true;
    });
    try {
      final result = await SundaySchoolService.pickAndProcessBook(
        startDate: _startDate,
        endDate: _endDate,
      );
      if (result == null) {
        // User cancelled
        return;
      }
      setState(() {
        _uploadResult = result;
        _pickedFileName = result.downloadUrl.split('/').last;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'PDF processed — ${result.chapters.length} chapter${result.chapters.length == 1 ? '' : 's'} mapped to Sundays'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdit && _uploadResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a PDF first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final appState = ref.read(appStateProvider);
    final user = appState.user!;

    setState(() => _loading = true);
    try {
      final bookId = _isEdit ? _existing!.id : _uuid.v4();
      final url = _uploadResult?.downloadUrl ?? (_isEdit ? _existing!.url : '');
      final totalChapters = _uploadResult?.chapters.length ??
          (_isEdit ? _existing!.totalChapters : 0);

      final book = SundaySchoolBook(
        id: bookId,
        churchId: appState.church?.id ?? '',
        title: _titleCtrl.text.trim(),
        author: _authorCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        url: url,
        coverColor: '',
        addedById: _isEdit ? _existing!.addedById : user.id,
        addedByName: _isEdit ? _existing!.addedByName : user.name,
        startDate: _startDate,
        endDate: _endDate,
        totalChapters: totalChapters,
        createdAt: _isEdit ? _existing!.createdAt : DateTime.now(),
      );

      await ref.read(sundaySchoolBookProvider.notifier).save(book);

      // Save chapters (only on new upload — don't overwrite on edit unless a new PDF was picked)
      if (_uploadResult != null) {
        // Delete existing chapters first (edit mode with new PDF)
        if (_isEdit) {
          final existingChapters =
              LocalDb.getSundaySchoolChaptersForBook(bookId);
          for (final c in existingChapters) {
            await LocalDb.deleteSundaySchoolChapter(c.id);
          }
        }
        for (final mc in _uploadResult!.chapters) {
          final chapter = SundaySchoolChapter(
            id: _uuid.v4(),
            bookId: bookId,
            churchId: appState.church?.id ?? '',
            chapterNumber: mc.chapterNumber,
            title: mc.title,
            content: mc.content,
            sundayDate: mc.sundayDate,
            memoryVerseRef: mc.memoryVerseRef,
            memoryVerseText: mc.memoryVerseText,
            createdAt: DateTime.now(),
          );
          await LocalDb.saveSundaySchoolChapter(chapter);
        }
        ref.read(sundaySchoolChapterProvider.notifier).refresh();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Book updated' : 'Book added'),
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
    final fmt = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Sunday School Book' : 'Add Sunday School Book')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Timeline (chapters mapped to Sundays)'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickStartDate,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        prefixIcon: Icon(Icons.event_available),
                      ),
                      child: Text(fmt.format(_startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickEndDate,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        prefixIcon: Icon(Icons.event_busy),
                      ),
                      child: Text(fmt.format(_endDate)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              _sectionLabel('Upload PDF'),
              const SizedBox(height: 8),
              if (_pickedFileName != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _pickedFileName!,
                        style: GoogleFonts.poppins(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_uploadResult != null)
                      Text(
                        '${_uploadResult!.chapters.length} ch.',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.green.shade700),
                      ),
                  ]),
                )
              else
                OutlinedButton.icon(
                  onPressed: _processing ? null : _pickPdf,
                  icon: _processing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file),
                  label: Text(_processing
                      ? 'Processing PDF…'
                      : 'Pick PDF from device'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              if (_pickedFileName == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Text will be extracted and split into chapters. Each chapter maps to a Sunday in the timeline.',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              const SizedBox(height: 24),

              _sectionLabel('Book Details'),
              const SizedBox(height: 12),
              _field(_titleCtrl, 'Book Title', Icons.title, required: true),
              const SizedBox(height: 12),
              _field(_authorCtrl, 'Author', Icons.person_outline),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Short description (optional)',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(_isEdit ? 'Save Changes' : 'Add Book'),
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
