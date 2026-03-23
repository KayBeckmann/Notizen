import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';

/// Editor für Notizen (Erstellen und Bearbeiten)
class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final String folderId;

  const NoteEditorScreen({
    super.key,
    this.noteId,
    required this.folderId,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isLoading = true;
  bool _hasChanges = false;
  Note? _existingNote;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _loadNote();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    if (widget.noteId != null) {
      final note = await ref.read(notesDaoProvider).getNoteById(widget.noteId!);
      if (note != null && mounted) {
        setState(() {
          _existingNote = note;
          _titleController.text = note.title;
          _contentController.text = note.content;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }

    // Änderungen tracken
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
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
        appBar: AppBar(
          title: Text(_existingNote == null ? 'Neue Notiz' : 'Bearbeiten'),
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
                if (_existingNote != null) ...[
                  PopupMenuItem(
                    value: 'pin',
                    child: ListTile(
                      leading: Icon(
                        _existingNote!.isPinned
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                      ),
                      title: Text(
                        _existingNote!.isPinned
                            ? 'Nicht mehr anpinnen'
                            : 'Anpinnen',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
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
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildEditor(),
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        // Titel
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: const InputDecoration(
              hintText: 'Titel',
              border: InputBorder.none,
              filled: false,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ),

        const Divider(indent: 16, endIndent: 16),

        // Inhalt
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _contentController,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Notiz eingeben...',
                border: InputBorder.none,
                filled: false,
              ),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ),
      ],
    );
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

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Nicht speichern wenn leer
    if (title.isEmpty && content.isEmpty) {
      if (_existingNote == null) {
        Navigator.of(context).pop();
        return;
      }
    }

    final now = DateTime.now();
    final notesDao = ref.read(notesDaoProvider);

    if (_existingNote != null) {
      // Bestehende Notiz aktualisieren
      await notesDao.updateNote(
        _existingNote!.copyWith(
          title: title,
          content: content,
          updatedAt: now,
        ),
      );
    } else {
      // Neue Notiz erstellen
      await notesDao.createNote(
        NotesCompanion.insert(
          id: const Uuid().v4(),
          folderId: widget.folderId,
          title: Value(title),
          content: Value(content),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    setState(() {
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notiz gespeichert'),
          duration: Duration(seconds: 1),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'pin':
        if (_existingNote != null) {
          ref.read(notesDaoProvider).togglePin(_existingNote!.id);
          setState(() {
            _existingNote = _existingNote!.copyWith(
              isPinned: !_existingNote!.isPinned,
            );
          });
        }
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
