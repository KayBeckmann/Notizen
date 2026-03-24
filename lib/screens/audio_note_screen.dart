import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../models/enums.dart';
import '../providers/database_provider.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/audio_recorder.dart';

/// Screen für Audio-Notizen
class AudioNoteScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final String folderId;

  const AudioNoteScreen({
    super.key,
    this.noteId,
    required this.folderId,
  });

  @override
  ConsumerState<AudioNoteScreen> createState() => _AudioNoteScreenState();
}

class _AudioNoteScreenState extends ConsumerState<AudioNoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _hasChanges = false;
  bool _isRecording = false;
  Note? _existingNote;
  String? _audioPath;

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
      final note = await ref.read(notesDaoProvider).getNoteById(widget.noteId!);
      if (note != null && mounted) {
        setState(() {
          _existingNote = note;
          _titleController.text = note.title;
          _descriptionController.text = note.content;
          _audioPath = note.mediaPath;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _isRecording = true; // Direkt Aufnahme starten
      });
    }

    _titleController.addListener(_onChanged);
    _descriptionController.addListener(_onChanged);
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
      title: Text(_existingNote == null ? 'Neue Sprachnotiz' : 'Bearbeiten'),
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
          // Titel
          TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: const InputDecoration(
              hintText: 'Titel der Aufnahme',
              border: InputBorder.none,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const Divider(),
          const SizedBox(height: 16),

          // Audio-Bereich
          if (_isRecording)
            AudioRecorderWidget(
              onRecordingComplete: _onRecordingComplete,
              onCancel: () {
                setState(() {
                  _isRecording = false;
                });
                if (_audioPath == null && _existingNote == null) {
                  Navigator.of(context).pop();
                }
              },
            )
          else if (_audioPath != null) ...[
            AudioPlayerWidget(
              audioPath: _audioPath!,
              showSpeedControl: true,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isRecording = true;
                });
              },
              icon: const Icon(Icons.mic),
              label: const Text('Neue Aufnahme'),
            ),
          ] else
            Center(
              child: FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _isRecording = true;
                  });
                },
                icon: const Icon(Icons.mic),
                label: const Text('Aufnahme starten'),
              ),
            ),

          const SizedBox(height: 24),

          // Optionale Beschreibung
          Text(
            'Beschreibung (optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Notizen zur Aufnahme...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onRecordingComplete(String path) {
    setState(() {
      _audioPath = path;
      _isRecording = false;
      _hasChanges = true;
    });

    // Auto-Titel generieren wenn leer
    if (_titleController.text.isEmpty) {
      final now = DateTime.now();
      _titleController.text =
          'Aufnahme ${now.day}.${now.month}.${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
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

  Future<void> _saveNote() async {
    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte erst eine Aufnahme erstellen')),
      );
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final now = DateTime.now();
    final notesDao = ref.read(notesDaoProvider);

    if (_existingNote != null) {
      await notesDao.updateNote(
        _existingNote!.copyWith(
          title: title.isEmpty ? 'Sprachnotiz' : title,
          content: description,
          mediaPath: Value(_audioPath),
          updatedAt: now,
        ),
      );
    } else {
      await notesDao.createNote(
        NotesCompanion.insert(
          id: const Uuid().v4(),
          folderId: widget.folderId,
          title: Value(title.isEmpty ? 'Sprachnotiz' : title),
          content: Value(description),
          contentType: Value(ContentType.audio),
          mediaPath: Value(_audioPath),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    setState(() {
      _hasChanges = false;
    });

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
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
