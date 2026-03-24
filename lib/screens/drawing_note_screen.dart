import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../constants/breakpoints.dart';
import '../database/database.dart';
import '../models/drawing.dart';
import '../models/enums.dart';
import '../providers/database_provider.dart';
import '../services/storage_service.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/drawing_toolbar.dart';

/// Screen für Zeichnungen
class DrawingNoteScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final String folderId;

  const DrawingNoteScreen({
    super.key,
    this.noteId,
    required this.folderId,
  });

  @override
  ConsumerState<DrawingNoteScreen> createState() => _DrawingNoteScreenState();
}

class _DrawingNoteScreenState extends ConsumerState<DrawingNoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final GlobalKey _canvasKey = GlobalKey();

  bool _isLoading = true;
  bool _hasChanges = false;
  Note? _existingNote;

  Drawing _drawing = const Drawing();
  DrawingSettings _settings = const DrawingSettings();

  // Undo/Redo
  final List<Drawing> _undoStack = [];
  final List<Drawing> _redoStack = [];

  // Auto-Save
  Timer? _autoSaveTimer;

  // Raster
  bool _showGrid = false;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    if (widget.noteId != null) {
      final note = await ref.read(notesDaoProvider).getNoteById(widget.noteId!);
      if (note != null && mounted) {
        setState(() {
          _existingNote = note;
          _titleController.text = note.title;
          if (note.drawingData != null && note.drawingData!.isNotEmpty) {
            _drawing = Drawing.fromJson(note.drawingData!);
          }
          _undoStack.add(_drawing);
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _undoStack.add(_drawing);
        _isLoading = false;
      });
    }

    _titleController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
    _scheduleAutoSave();
  }

  void _onDrawingChanged(Drawing newDrawing) {
    setState(() {
      _drawing = newDrawing;
      _undoStack.add(newDrawing);
      _redoStack.clear();
      _hasChanges = true;
    });
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 3), () {
      if (_hasChanges && mounted) {
        _saveNote(showMessage: false);
      }
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

  void _clearDrawing() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alles löschen?'),
        content: const Text('Die gesamte Zeichnung wird gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _onDrawingChanged(Drawing(backgroundColor: _drawing.backgroundColor));
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isExpanded(context);

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
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
          const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
              _saveNote(),
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).maybePop(),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: _buildAppBar(),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(isDesktop),
            bottomNavigationBar: !isDesktop
                ? DrawingToolbar(
                    settings: _settings,
                    onSettingsChanged: (s) => setState(() => _settings = s),
                    onUndo: _undo,
                    onRedo: _redo,
                    onClear: _clearDrawing,
                    canUndo: _undoStack.length > 1,
                    canRedo: _redoStack.isNotEmpty,
                    isVertical: false,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: SizedBox(
        width: 200,
        child: TextField(
          controller: _titleController,
          style: Theme.of(context).textTheme.titleLarge,
          decoration: const InputDecoration(
            hintText: 'Titel',
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
      actions: [
        // Raster
        IconButton(
          icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off),
          onPressed: () => setState(() => _showGrid = !_showGrid),
          tooltip: 'Raster anzeigen',
        ),

        // Hintergrundfarbe
        PopupMenuButton<Color>(
          icon: const Icon(Icons.format_color_fill),
          tooltip: 'Hintergrundfarbe',
          onSelected: (color) {
            _onDrawingChanged(_drawing.copyWith(backgroundColor: color));
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: Colors.white,
              child: _ColorRow(color: Colors.white, label: 'Weiß'),
            ),
            PopupMenuItem(
              value: Colors.black,
              child: _ColorRow(color: Colors.black, label: 'Schwarz'),
            ),
            PopupMenuItem(
              value: Colors.grey[200]!,
              child: _ColorRow(color: Colors.grey[200]!, label: 'Hellgrau'),
            ),
            PopupMenuItem(
              value: const Color(0xFFFFFDE7),
              child: _ColorRow(
                  color: const Color(0xFFFFFDE7), label: 'Hellgelb'),
            ),
            PopupMenuItem(
              value: const Color(0xFFE3F2FD),
              child:
                  _ColorRow(color: const Color(0xFFE3F2FD), label: 'Hellblau'),
            ),
          ],
        ),

        // Export
        IconButton(
          icon: const Icon(Icons.save_alt),
          onPressed: _exportAsImage,
          tooltip: 'Als Bild exportieren',
        ),

        // Speichern
        if (_hasChanges)
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _saveNote(),
            tooltip: 'Speichern',
          ),

        // Mehr-Menü
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

  Widget _buildBody(bool isDesktop) {
    if (isDesktop) {
      return Row(
        children: [
          // Sidebar-Toolbar
          DrawingToolbar(
            settings: _settings,
            onSettingsChanged: (s) => setState(() => _settings = s),
            onUndo: _undo,
            onRedo: _redo,
            onClear: _clearDrawing,
            canUndo: _undoStack.length > 1,
            canRedo: _redoStack.isNotEmpty,
            isVertical: true,
          ),
          // Canvas
          Expanded(
            child: RepaintBoundary(
              key: _canvasKey,
              child: DrawingCanvas(
                drawing: _drawing,
                settings: _settings,
                onDrawingChanged: _onDrawingChanged,
                showGrid: _showGrid,
              ),
            ),
          ),
        ],
      );
    }

    return RepaintBoundary(
      key: _canvasKey,
      child: DrawingCanvas(
        drawing: _drawing,
        settings: _settings,
        onDrawingChanged: _onDrawingChanged,
        showGrid: _showGrid,
      ),
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

  Future<void> _saveNote({bool showMessage = true}) async {
    final title = _titleController.text.trim();
    final drawingJson = _drawing.toJson();
    final now = DateTime.now();
    final notesDao = ref.read(notesDaoProvider);

    if (_existingNote != null) {
      await notesDao.updateNote(
        _existingNote!.copyWith(
          title: title.isEmpty ? 'Zeichnung' : title,
          drawingData: Value(drawingJson),
          updatedAt: now,
        ),
      );
    } else {
      final noteId = const Uuid().v4();
      await notesDao.createNote(
        NotesCompanion.insert(
          id: noteId,
          folderId: widget.folderId,
          title: Value(title.isEmpty ? 'Zeichnung' : title),
          contentType: Value(ContentType.drawing),
          drawingData: Value(drawingJson),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Note laden um _existingNote zu setzen
      final note = await notesDao.getNoteById(noteId);
      setState(() {
        _existingNote = note;
      });
    }

    setState(() {
      _hasChanges = false;
    });

    if (showMessage && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gespeichert'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _exportAsImage() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      // Speichern
      final path = await StorageService.instance.saveDrawingBytes(
        Uint8List.fromList(bytes),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exportiert nach: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Export: $e')),
        );
      }
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
        title: const Text('Zeichnung löschen?'),
        content: const Text('Die Zeichnung wird in den Papierkorb verschoben.'),
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

class _ColorRow extends StatelessWidget {
  final Color color;
  final String label;

  const _ColorRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
          ),
        ),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
