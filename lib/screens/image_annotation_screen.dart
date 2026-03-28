import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../models/drawing.dart';
import '../providers/database_provider.dart';
import '../services/storage_service.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/drawing_toolbar.dart';

/// Screen zum Zeichnen auf einem Bild – speichert alles in einer Notiz
class ImageAnnotationScreen extends ConsumerStatefulWidget {
  final String noteId;

  const ImageAnnotationScreen({super.key, required this.noteId});

  @override
  ConsumerState<ImageAnnotationScreen> createState() =>
      _ImageAnnotationScreenState();
}

class _ImageAnnotationScreenState
    extends ConsumerState<ImageAnnotationScreen> {
  Note? _note;
  Drawing _drawing = const Drawing();
  DrawingSettings _settings = const DrawingSettings();
  ui.Image? _backgroundImage;

  bool _isLoading = true;
  bool _hasChanges = false;

  final List<Drawing> _undoStack = [];
  final List<Drawing> _redoStack = [];

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final note =
        await ref.read(notesDaoProvider).getNoteById(widget.noteId);
    if (note == null || !mounted) return;

    Drawing drawing = const Drawing();
    if (note.drawingData != null && note.drawingData!.isNotEmpty) {
      drawing = Drawing.fromJson(note.drawingData!);
    }

    setState(() {
      _note = note;
      _drawing = drawing;
      _undoStack.add(drawing);
      _isLoading = false;
    });

    if (note.mediaPath != null) {
      await _loadBackgroundImage(note.mediaPath!);
    }
  }

  Future<void> _loadBackgroundImage(String path) async {
    try {
      Uint8List? bytes;
      if (kIsWeb && StorageService.isWebPath(path)) {
        bytes = StorageService.getWebImageBytes(path);
      } else if (!kIsWeb) {
        final file = File(path);
        if (await file.exists()) bytes = await file.readAsBytes();
      }
      if (bytes == null || !mounted) return;

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _backgroundImage = frame.image;
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Laden des Hintergrundbildes: $e');
    }
  }

  void _onDrawingChanged(Drawing drawing) {
    setState(() {
      _drawing = drawing;
      _undoStack.add(drawing);
      _redoStack.clear();
      _hasChanges = true;
    });
  }

  void _undo() {
    if (_undoStack.length > 1) {
      setState(() {
        final current = _undoStack.removeLast();
        _redoStack.add(current);
        _drawing = _undoStack.last;
        _hasChanges = true;
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        final drawing = _redoStack.removeLast();
        _undoStack.add(drawing);
        _drawing = drawing;
        _hasChanges = true;
      });
    }
  }

  void _clearAnnotations() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zeichnung löschen?'),
        content:
            const Text('Alle Zeichnungen auf dem Bild werden entfernt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _onDrawingChanged(const Drawing());
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_note == null) return;
    await ref.read(notesDaoProvider).updateNote(
          _note!.copyWith(
            drawingData: Value(_drawing.isEmpty ? null : _drawing.toJson()),
            updatedAt: DateTime.now(),
          ),
        );
    setState(() => _hasChanges = false);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zeichnung speichern?'),
        content: const Text(
            'Die Zeichnung wurde noch nicht gespeichert.'),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldSave = await _showUnsavedChangesDialog();
        if (shouldSave == true) {
          await _save();
        } else if (context.mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
              _undo,
          const SingleActivator(LogicalKeyboardKey.keyY, control: true):
              _redo,
          const SingleActivator(LogicalKeyboardKey.keyS, control: true):
              _save,
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Text(_note?.title ?? 'Auf Bild zeichnen'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: _undoStack.length > 1 ? _undo : null,
                  tooltip: 'Rückgängig',
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: _redoStack.isNotEmpty ? _redo : null,
                  tooltip: 'Wiederholen',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: _drawing.isNotEmpty ? _clearAnnotations : null,
                  tooltip: 'Zeichnung löschen',
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _save,
                  tooltip: 'Speichern',
                ),
              ],
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : DrawingCanvas(
                    drawing: _drawing,
                    settings: _settings,
                    onDrawingChanged: _onDrawingChanged,
                    backgroundImage: _backgroundImage,
                  ),
            bottomNavigationBar: DrawingToolbar(
              settings: _settings,
              onSettingsChanged: (s) => setState(() => _settings = s),
              onUndo: _undo,
              onRedo: _redo,
              onClear: _clearAnnotations,
              canUndo: _undoStack.length > 1,
              canRedo: _redoStack.isNotEmpty,
              isVertical: false,
            ),
          ),
        ),
      ),
    );
  }
}
