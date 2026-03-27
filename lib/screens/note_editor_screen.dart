import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../database/database.dart';
import '../providers/notes_provider.dart';
import '../providers/database_provider.dart';
import '../models/enums.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? note;
  final String? folderId;

  const NoteEditorScreen({
    super.key,
    this.note,
    this.folderId,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text;
    final content = _contentController.text;
    final notesDao = ref.read(notesDaoProvider);

    if (widget.note == null) {
      if (title.isEmpty && content.isEmpty) return;
      
      final newNote = NotesCompanion.insert(
        id: const Uuid().v4(),
        title: drift.Value(title),
        content: drift.Value(content),
        contentType: ContentType.text,
        folderId: widget.folderId ?? 'default', // TODO: Handle default folder
        createdAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
      );
      await notesDao.createNote(newNote);
    } else {
      final updatedNote = widget.note!.toCompanion(true).copyWith(
        title: drift.Value(title),
        content: drift.Value(content),
        updatedAt: drift.Value(DateTime.now()),
      );
      await notesDao.updateNote(updatedNote);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notiz bearbeiten'),
        actions: [
          IconButton(
            icon: Icon(_isPreview ? Icons.edit : Icons.visibility),
            onPressed: () {
              setState(() {
                _isPreview = !_isPreview;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              await _saveNote();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Titel',
                border: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isPreview
                ? Markdown(data: _contentController.text)
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Inhalt (Markdown unterstützt)',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
