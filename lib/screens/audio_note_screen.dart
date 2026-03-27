import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/audio_recorder.dart';
import '../widgets/audio_player_widget.dart';
import '../database/database.dart';
import '../providers/notes_provider.dart';
import '../providers/database_provider.dart';
import '../models/enums.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

class AudioNoteScreen extends ConsumerStatefulWidget {
  final Note? note;
  final String? folderId;

  const AudioNoteScreen({
    super.key,
    this.note,
    this.folderId,
  });

  @override
  ConsumerState<AudioNoteScreen> createState() => _AudioNoteScreenState();
}

class _AudioNoteScreenState extends ConsumerState<AudioNoteScreen> {
  late TextEditingController _titleController;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _audioPath = widget.note?.mediaPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text;
    final notesDao = ref.read(notesDaoProvider);

    if (widget.note == null) {
      if (_audioPath == null) return;
      
      final newNote = NotesCompanion.insert(
        id: const Uuid().v4(),
        title: drift.Value(title),
        contentType: ContentType.audio,
        folderId: widget.folderId ?? 'default',
        mediaPath: drift.Value(_audioPath),
        createdAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
      );
      await notesDao.createNote(newNote);
    } else {
      final updatedNote = widget.note!.toCompanion(true).copyWith(
        title: drift.Value(title),
        mediaPath: drift.Value(_audioPath),
        updatedAt: drift.Value(DateTime.now()),
      );
      await notesDao.updateNote(updatedNote);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio-Notiz'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Titel'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            if (_audioPath == null)
              AudioRecorderWidget(onStop: (path) {
                setState(() => _audioPath = path);
              })
            else
              Column(
                children: [
                  AudioPlayerWidget(source: _audioPath!),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _audioPath = null);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Neu aufnehmen'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
