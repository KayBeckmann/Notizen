import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../models/drawing.dart';
import '../models/enums.dart';
import '../providers/database_provider.dart';
import '../services/storage_service.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/image_viewer.dart';
import 'image_annotation_screen.dart';

/// Screen für Bild-Notizen (mit optionaler Zeichnung)
class ImageNoteScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final String folderId;

  const ImageNoteScreen({
    super.key,
    this.noteId,
    required this.folderId,
  });

  @override
  ConsumerState<ImageNoteScreen> createState() => _ImageNoteScreenState();
}

class _ImageNoteScreenState extends ConsumerState<ImageNoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _hasChanges = false;
  Note? _existingNote;
  String? _imagePath;
  Drawing _drawing = const Drawing();

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    if (widget.noteId != null) {
      final note =
          await ref.read(notesDaoProvider).getNoteById(widget.noteId!);
      if (note != null && mounted) {
        Drawing drawing = const Drawing();
        if (note.drawingData != null && note.drawingData!.isNotEmpty) {
          drawing = Drawing.fromJson(note.drawingData!);
        }
        setState(() {
          _existingNote = note;
          _titleController.text = note.title;
          _descriptionController.text = note.content;
          _imagePath = note.mediaPath;
          _drawing = drawing;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      _pickImage();
    }

    _titleController.addListener(_onChanged);
    _descriptionController.addListener(_onChanged);
  }

  Future<void> _reloadDrawing() async {
    if (_existingNote == null) return;
    final note =
        await ref.read(notesDaoProvider).getNoteById(_existingNote!.id);
    if (note != null && mounted) {
      Drawing drawing = const Drawing();
      if (note.drawingData != null && note.drawingData!.isNotEmpty) {
        drawing = Drawing.fromJson(note.drawingData!);
      }
      setState(() {
        _existingNote = note;
        _drawing = drawing;
      });
    }
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldSave = await _showUnsavedChangesDialog();
        if (shouldSave == true) {
          await _saveNote();
        }
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_existingNote == null ? 'Neue Bildnotiz' : 'Bearbeiten'),
      actions: [
        if (_hasChanges)
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
            tooltip: 'Speichern',
          ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            if (_imagePath != null) ...[
              const PopupMenuItem(
                value: 'annotate',
                child: ListTile(
                  leading: Icon(Icons.draw),
                  title: Text('Auf Bild zeichnen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'replace',
                child: ListTile(
                  leading: Icon(Icons.swap_horiz),
                  title: Text('Bild ersetzen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            if (_existingNote != null) ...[
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Löschen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: const InputDecoration(
              hintText: 'Titel',
              border: InputBorder.none,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const Divider(),
          const SizedBox(height: 16),

          if (_imagePath != null) ...[
            GestureDetector(
              onTap: _viewImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildImageWithOverlay(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _viewImage,
                  icon: const Icon(Icons.fullscreen),
                  label: const Text('Vollbild'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _openAnnotation,
                  icon: const Icon(Icons.draw),
                  label: const Text('Zeichnen'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Ersetzen'),
                ),
              ],
            ),
            if (_drawing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.draw,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Zeichnung vorhanden',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
          ] else
            _buildImagePlaceholder(),

          const SizedBox(height: 24),

          Text(
            'Beschreibung (optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Notizen zum Bild...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bild mit Zeichnungs-Overlay (wenn Zeichnung vorhanden)
  Widget _buildImageWithOverlay() {
    if (_drawing.isEmpty) {
      return ImagePreview(imagePath: _imagePath!, fit: BoxFit.cover);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ImagePreview(imagePath: _imagePath!, fit: BoxFit.cover),
        CustomPaint(
          painter: DrawingPainter(
            drawing: _drawing,
            gridColor: Colors.transparent,
            drawBackground: false,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Bild hinzufügen',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamera oder Galerie',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final path = await showImagePickerDialog(context);
    if (path != null) {
      if (_imagePath != null && _imagePath != _existingNote?.mediaPath) {
        await StorageService.instance.deleteFile(_imagePath!);
      }
      setState(() {
        _imagePath = path;
        _hasChanges = true;
      });
      if (_titleController.text.isEmpty) {
        final now = DateTime.now();
        _titleController.text =
            'Bild ${now.day}.${now.month}.${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      }
    } else if (_imagePath == null && _existingNote == null) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _viewImage() {
    if (_imagePath == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          imagePath: _imagePath!,
          title: _titleController.text.isNotEmpty
              ? _titleController.text
              : null,
        ),
      ),
    );
  }

  Future<void> _openAnnotation() async {
    if (_imagePath == null) return;

    // Notiz muss zuerst gespeichert sein, damit wir eine noteId haben
    if (_existingNote == null) {
      await _saveNoteData();
      if (_existingNote == null) return; // Speichern fehlgeschlagen
    }

    if (!mounted) return;
    final annotated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ImageAnnotationScreen(noteId: _existingNote!.id),
      ),
    );

    // Zeichnung neu laden nach Rückkehr
    if (annotated == true && mounted) {
      await _reloadDrawing();
    }
  }

  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ungespeicherte Änderungen'),
        content: const Text('Möchtest du die Änderungen speichern?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Verwerfen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  /// Speichert die Notiz (ohne zu navigieren)
  Future<void> _saveNoteData() async {
    if (_imagePath == null) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final now = DateTime.now();
    final notesDao = ref.read(notesDaoProvider);

    if (_existingNote != null) {
      await notesDao.updateNote(
        _existingNote!.copyWith(
          title: title.isEmpty ? 'Bildnotiz' : title,
          content: description,
          mediaPath: Value(_imagePath),
          updatedAt: now,
        ),
      );
      setState(() => _hasChanges = false);
    } else {
      final id = const Uuid().v4();
      await notesDao.createNote(
        NotesCompanion.insert(
          id: id,
          folderId: widget.folderId,
          title: Value(title.isEmpty ? 'Bildnotiz' : title),
          content: Value(description),
          contentType: Value(ContentType.image.name),
          mediaPath: Value(_imagePath),
          createdAt: now,
          updatedAt: now,
        ),
      );
      final note = await notesDao.getNoteById(id);
      if (mounted) {
        setState(() {
          _existingNote = note;
          _hasChanges = false;
        });
      }
    }
  }

  /// Speichert und schließt den Screen
  Future<void> _saveNote() async {
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte erst ein Bild auswählen')),
      );
      return;
    }
    await _saveNoteData();
    if (mounted) Navigator.of(context).pop();
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'annotate':
        _openAnnotation();
        break;
      case 'replace':
        _pickImage();
        break;
      case 'delete':
        _confirmDelete();
        break;
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notiz löschen?'),
        content: const Text('Die Notiz wird in den Papierkorb verschoben.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (_existingNote != null) {
                ref.read(notesDaoProvider).moveToTrash(_existingNote!.id);
              }
              Navigator.of(this.context).pop();
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
