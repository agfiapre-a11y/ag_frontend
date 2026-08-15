import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants.dart';
import '../../../models/library_book.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../services/local_db.dart';

class AddEditLibraryBookScreen extends ConsumerStatefulWidget {
  final String? bookId; // null = add mode

  const AddEditLibraryBookScreen({super.key, this.bookId});

  @override
  ConsumerState<AddEditLibraryBookScreen> createState() =>
      _AddEditLibraryBookScreenState();
}

class _AddEditLibraryBookScreenState
    extends ConsumerState<AddEditLibraryBookScreen> {
  final _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();

  String _category = LibraryBookCategory.christianClassic;
  bool _loading = false;
  LibraryBook? _existing;

  bool get _isEdit => widget.bookId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _existing = LocalDb.getLibraryBookById(widget.bookId!);
      if (_existing != null) {
        _titleCtrl.text = _existing!.title;
        _authorCtrl.text = _existing!.author;
        _descriptionCtrl.text = _existing!.description;
        _urlCtrl.text = _existing!.url;
        _sourceCtrl.text = _existing!.source;
        _category = _existing!.category;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _descriptionCtrl.dispose();
    _urlCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = ref.read(appStateProvider);
    final user = appState.user!;

    setState(() => _loading = true);
    try {
      final book = _isEdit && _existing != null
          ? _existing!.copyWith(
              title: _titleCtrl.text.trim(),
              author: _authorCtrl.text.trim(),
              category: _category,
              description: _descriptionCtrl.text.trim(),
              url: _urlCtrl.text.trim(),
              source: _sourceCtrl.text.trim(),
            )
          : LibraryBook(
              id: _uuid.v4(),
              churchId: appState.church?.id ?? '',
              title: _titleCtrl.text.trim(),
              author: _authorCtrl.text.trim(),
              category: _category,
              description: _descriptionCtrl.text.trim(),
              url: _urlCtrl.text.trim(),
              source: _sourceCtrl.text.trim(),
              addedById: user.id,
              createdAt: DateTime.now(),
            );

      await ref.read(libraryBookProvider.notifier).save(book);
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Book' : 'Add Book')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Book Details'),
              const SizedBox(height: 12),
              _field(_titleCtrl, 'Book Title', Icons.title, required: true),
              const SizedBox(height: 12),
              _field(_authorCtrl, 'Author', Icons.person_outline),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: LibraryBookCategory.all
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Description'),
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
              const SizedBox(height: 20),
              _sectionLabel('Free Read / Download Link'),
              const SizedBox(height: 12),
              _field(_urlCtrl, 'URL (e.g. ccel.org, archive.org)', Icons.link,
                  required: true, type: TextInputType.url),
              const SizedBox(height: 12),
              _field(_sourceCtrl,
                  'Source attribution (e.g. Christian Classics Ethereal Library)',
                  Icons.public),
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
