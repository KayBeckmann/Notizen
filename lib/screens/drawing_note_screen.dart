import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/drawing_canvas.dart';
import '../database/database.dart';
import '../providers/notes_provider.dart';
import '../providers/database_provider.dart';
import '../models/enums.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';

class DrawingNoteScreen extends ConsumerStatefulWidget {
  final Note? note;
  final String? folderId;

  const DrawingNoteScreen({
    super.key,
    this.note,
    this.folderId,
  });

  @override
  ConsumerState<DrawingNoteScreen> createState() => _DrawingNoteScreenState();
}

class _DrawingNoteScreenState extends ConsumerState<DrawingNoteScreen> {
  late TextEditingController _titleController;
  List<DrawingPoint?> _points = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    if (widget.note?.drawingData != null) {
      // TODO: Deserialisieren von Zeichnungsdaten
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text;
    final notesDao = ref.read(notesDaoProvider);

    // TODO: Serialisieren von Zeichnungsdaten
    final drawingData = jsonEncode([]);

    if (widget.note == null) {
      final newNote = NotesCompanion.insert(
        id: const Uuid().v4(),
        title: drift.Value(title),
        contentType: ContentType.drawing,
        folderId: widget.folderId ?? 'default',
        drawingData: drift.Value(drawingData),
        createdAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
      );
      await notesDao.createNote(newNote);
    } else {
      final updatedNote = widget.note!.toCompanion(true).copyWith(
        title: drift.Value(title),
        drawingData: drift.Value(drawingData),
        updatedAt: drift.Value(DateTime.now()),
      );
      await notesDao.updateNote(updatedNote);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zeichnung'),
        actions: [
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
              decoration: const InputDecoration(hintText: 'Titel'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: DrawingCanvas(
              onDrawingChanged: (points) {
                _points = points;
              },
            ),
          ),
        ],
      ),
    );
  }
}
