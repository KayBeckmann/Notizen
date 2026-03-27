import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../database/database.dart';
import '../providers/notes_provider.dart';
import '../providers/database_provider.dart';
import '../models/enums.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../providers/folders_provider.dart';

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
  String? _selectedFolderId;
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedFolderId = widget.note?.folderId ?? widget.folderId;
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
    final folderId = _selectedFolderId ?? await ref.read(foldersDaoProvider).ensureDefaultFolder();

    if (widget.note == null) {
      if (title.isEmpty && content.isEmpty) return;
      
      final newNote = NotesCompanion.insert(
        id: const Uuid().v4(),
        title: drift.Value(title),
        content: drift.Value(content),
        contentType: ContentType.text,
        folderId: folderId,
        createdAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
      );
      await notesDao.createNote(newNote);
    } else {
      final updatedNote = widget.note!.toCompanion(true).copyWith(
        title: drift.Value(title),
        content: drift.Value(content),
        folderId: drift.Value(folderId),
        updatedAt: drift.Value(DateTime.now()),
      );
      await notesDao.updateNote(updatedNote);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(allFoldersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notiz bearbeiten'),
        actions: [
          foldersAsync.when(
            data: (folders) => DropdownButton<String>(
              value: _selectedFolderId,
              icon: const Icon(Icons.folder_outlined),
              underline: const SizedBox(),
              onChanged: (value) {
                setState(() => _selectedFolderId = value);
              },
              items: folders.map((f) => DropdownMenuItem(
                value: f.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder, color: Color(f.color), size: 18),
                    const SizedBox(width: 8),
                    Text(f.name),
                  ],
                ),
              )).toList(),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
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
