import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../services/export_service.dart';
import '../services/browser_title_service.dart';

import '../constants/breakpoints.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/tags_provider.dart';
import '../widgets/markdown_preview.dart';
import '../widgets/markdown_toolbar.dart';
import '../widgets/tag_dialog.dart';
import '../widgets/template_dialogs.dart';

/// Editor-Modi
enum EditorMode { edit, preview, split }

/// Editor für Notizen (Erstellen und Bearbeiten)
class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final String folderId;
  final String? initialTitle;
  final String? initialContent;

  const NoteEditorScreen({
    super.key,
    this.noteId,
    required this.folderId,
    this.initialTitle,
    this.initialContent,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _contentFocusNode;

  bool _isLoading = true;
  bool _hasChanges = false;
  bool _isSaving = false;
  Note? _existingNote;
  EditorMode? _editorMode; // Wird beim Laden initialisiert

  // Auto-Save
  Timer? _autoSaveTimer;
  static const _autoSaveDelay = Duration(seconds: 2);

  // Undo/Redo
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  String _lastSavedContent = '';

  // Tags
  List<Tag> _noteTags = [];

  // Scroll-Synchronisation
  final ScrollController _editorScrollController = ScrollController();
  final ScrollController _previewScrollController = ScrollController();
  bool _isSyncingScroll = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _contentFocusNode = FocusNode();
    _setupScrollSync();
    _loadNote();
  }

  /// Scroll-Synchronisation einrichten
  void _setupScrollSync() {
    _editorScrollController.addListener(_onEditorScroll);
    _previewScrollController.addListener(_onPreviewScroll);
  }

  void _onEditorScroll() {
    if (_isSyncingScroll) return;
    if (!_editorScrollController.hasClients || !_previewScrollController.hasClients) return;

    final editorMax = _editorScrollController.position.maxScrollExtent;
    final previewMax = _previewScrollController.position.maxScrollExtent;

    if (editorMax <= 0 || previewMax <= 0) return;

    final ratio = _editorScrollController.offset / editorMax;
    final targetOffset = (ratio * previewMax).clamp(0.0, previewMax);

    _isSyncingScroll = true;
    _previewScrollController.jumpTo(targetOffset);
    _isSyncingScroll = false;
  }

  void _onPreviewScroll() {
    if (_isSyncingScroll) return;
    if (!_editorScrollController.hasClients || !_previewScrollController.hasClients) return;

    final editorMax = _editorScrollController.position.maxScrollExtent;
    final previewMax = _previewScrollController.position.maxScrollExtent;

    if (editorMax <= 0 || previewMax <= 0) return;

    final ratio = _previewScrollController.offset / previewMax;
    final targetOffset = (ratio * editorMax).clamp(0.0, editorMax);

    _isSyncingScroll = true;
    _editorScrollController.jumpTo(targetOffset);
    _isSyncingScroll = false;
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    _editorScrollController.removeListener(_onEditorScroll);
    _previewScrollController.removeListener(_onPreviewScroll);
    _editorScrollController.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    if (widget.noteId != null) {
      final note = await ref.read(notesDaoProvider).getNoteById(widget.noteId!);
      if (note != null && mounted) {
        // Tags laden
        final tags = await ref.read(tagsDaoProvider).getTagsForNote(note.id);

        setState(() {
          _existingNote = note;
          _titleController.text = note.title;
          _contentController.text = note.content;
          _lastSavedContent = note.content;
          _noteTags = tags;
          _isLoading = false;
        });
        // Browser-Tab-Titel aktualisieren
        BrowserTitleService.setNoteTitle(note.title);
      }
    } else {
      // Bei neuen Notizen: initiale Werte aus Vorlage verwenden
      if (widget.initialTitle != null) {
        _titleController.text = widget.initialTitle!;
      }
      if (widget.initialContent != null) {
        _contentController.text = widget.initialContent!;
        _lastSavedContent = widget.initialContent!;
      }
      setState(() {
        _isLoading = false;
      });
      // Browser-Tab-Titel für neue Notiz
      BrowserTitleService.setNoteTitle(widget.initialTitle ?? '');
    }

    // Änderungen tracken
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onContentChanged);
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
    _scheduleAutoSave();
  }

  void _onContentChanged() {
    _onChanged();

    // Undo-Stack aktualisieren
    final currentContent = _contentController.text;
    if (_undoStack.isEmpty || _undoStack.last != currentContent) {
      _undoStack.add(currentContent);
      _redoStack.clear();
      // Stack-Größe begrenzen
      if (_undoStack.length > 50) {
        _undoStack.removeAt(0);
      }
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      if (_hasChanges && mounted) {
        _saveNote(showMessage: false);
      }
    });
  }

  void _undo() {
    if (_undoStack.length > 1) {
      final current = _undoStack.removeLast();
      _redoStack.add(current);
      _contentController.text = _undoStack.last;
      setState(() {});
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      final text = _redoStack.removeLast();
      _undoStack.add(text);
      _contentController.text = text;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isExpanded(context);
    final savedModeIndex = ref.watch(editorModeIndexProvider);
    final useSplitOnDesktop = ref.watch(useSplitOnDesktopProvider);

    // Initialisiere den Editor-Modus beim ersten Build
    if (_editorMode == null) {
      if (widget.noteId == null) {
        // Neue Notiz: Immer Edit-Mode
        _editorMode = EditorMode.edit;
      } else if (isDesktop && useSplitOnDesktop) {
        // Desktop mit aktivierter Split-Präferenz: Split-Mode
        _editorMode = EditorMode.split;
      } else {
        // Ansonsten: gespeicherten Modus verwenden
        _editorMode = EditorMode.values[savedModeIndex.clamp(0, 2)];
      }
    }

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
      child: EditorKeyboardShortcuts(
        controller: _contentController,
        focusNode: _contentFocusNode,
        onSave: () => _saveNote(),
        onUndo: _undoStack.length > 1 ? _undo : null,
        onRedo: _redoStack.isNotEmpty ? _redo : null,
        onEscape: () => Navigator.of(context).maybePop(),
        child: Scaffold(
          appBar: _buildAppBar(),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(),
          bottomNavigationBar: _editorMode != null && _editorMode != EditorMode.preview
              ? MarkdownToolbar(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  onUndo: _undoStack.length > 1 ? _undo : null,
                  onRedo: _redoStack.isNotEmpty ? _redo : null,
                  canUndo: _undoStack.length > 1,
                  canRedo: _redoStack.isNotEmpty,
                )
              : null,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_existingNote == null ? 'Neue Notiz' : 'Bearbeiten'),
      actions: [
        // Editor-Modus Toggle
        SegmentedButton<EditorMode>(
          segments: const [
            ButtonSegment(
              value: EditorMode.edit,
              icon: Icon(Icons.edit, size: 18),
              tooltip: 'Bearbeiten',
            ),
            ButtonSegment(
              value: EditorMode.preview,
              icon: Icon(Icons.visibility, size: 18),
              tooltip: 'Vorschau',
            ),
            ButtonSegment(
              value: EditorMode.split,
              icon: Icon(Icons.vertical_split, size: 18),
              tooltip: 'Geteilt',
            ),
          ],
          selected: {_editorMode!},
          onSelectionChanged: (modes) {
            final newMode = modes.first;
            setState(() {
              _editorMode = newMode;
            });
            // Modus persistieren
            ref.read(editorModeIndexProvider.notifier).setMode(newMode.index);
          },
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),

        // Speichern-Indikator oder Button
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_hasChanges)
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _saveNote(),
            tooltip: 'Speichern (Ctrl+S)',
          ),

        // Teilen-Button
        if (_existingNote != null || _contentController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareNote,
            tooltip: 'Teilen',
          ),

        // Mehr-Menü
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
              PopupMenuItem(
                value: 'archive',
                child: ListTile(
                  leading: Icon(
                    _existingNote!.isArchived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                  ),
                  title: Text(
                    _existingNote!.isArchived
                        ? 'Aus Archiv wiederherstellen'
                        : 'Archivieren',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'tags',
                child: ListTile(
                  leading: Icon(Icons.label_outline),
                  title: Text('Tags bearbeiten'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'move',
                child: ListTile(
                  leading: Icon(Icons.drive_file_move_outlined),
                  title: Text('Verschieben'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'info',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Informationen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'export_md',
                child: ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('Als Markdown exportieren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export_txt',
                child: ListTile(
                  leading: Icon(Icons.text_snippet_outlined),
                  title: Text('Als Text exportieren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('In Zwischenablage kopieren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'save_template',
                child: ListTile(
                  leading: Icon(Icons.save_as_outlined),
                  title: Text('Als Vorlage speichern'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
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
    return Column(
      children: [
        // Titel-Bereich
        _buildTitleSection(),

        // Tags
        if (_noteTags.isNotEmpty || _existingNote != null) _buildTagsSection(),

        const Divider(height: 1),

        // Content-Bereich
        Expanded(
          child: _buildContentArea(),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
    );
  }

  Widget _buildTagsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ..._noteTags.map((tag) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InputChip(
                    label: Text(tag.name),
                    backgroundColor:
                        Color(tag.color).withValues(alpha: 0.2),
                    onDeleted: () => _removeTag(tag),
                    deleteIconColor: Color(tag.color),
                  ),
                )),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Tag'),
              onPressed: _showAddTagDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    switch (_editorMode ?? EditorMode.edit) {
      case EditorMode.edit:
        return _buildEditor();
      case EditorMode.preview:
        return _buildPreview();
      case EditorMode.split:
        return _buildSplitView();
    }
  }

  Widget _buildEditor({bool withScrollSync = false}) {
    final textField = TextField(
      controller: _contentController,
      focusNode: _contentFocusNode,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFamily: 'monospace',
            height: 1.5,
          ),
      decoration: const InputDecoration(
        hintText: 'Notiz eingeben...\n\nTipps:\n- **fett** für fett\n- *kursiv* für kursiv\n- # Überschrift\n- - Liste\n- [ ] Checkbox',
        border: InputBorder.none,
        filled: false,
      ),
      maxLines: null,
      expands: !withScrollSync,
      textAlignVertical: TextAlignVertical.top,
      textCapitalization: TextCapitalization.sentences,
    );

    if (withScrollSync) {
      return SingleChildScrollView(
        controller: _editorScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: textField,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: textField,
    );
  }

  Widget _buildPreview() {
    if (_contentController.text.isEmpty) {
      return const EmptyMarkdownPreview();
    }

    return MarkdownPreview(
      data: _contentController.text,
      scrollController: _previewScrollController,
      onCheckboxChanged: _onCheckboxChanged,
    );
  }

  Widget _buildSplitView() {
    return Row(
      children: [
        // Editor
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: _buildEditor(withScrollSync: true),
          ),
        ),
        // Preview
        Expanded(
          child: _contentController.text.isEmpty
              ? const EmptyMarkdownPreview()
              : MarkdownPreview(
                  data: _contentController.text,
                  scrollController: _previewScrollController,
                  onCheckboxChanged: _onCheckboxChanged,
                ),
        ),
      ],
    );
  }

  void _onCheckboxChanged(bool checked, String taskText) {
    final content = _contentController.text;
    final oldPattern = checked ? '- [ ]' : '- [x]';
    final newPattern = checked ? '- [x]' : '- [ ]';

    // Finde und ersetze die Checkbox im Content
    final lines = content.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains(oldPattern) && lines[i].contains(taskText)) {
        lines[i] = lines[i].replaceFirst(oldPattern, newPattern);
        break;
      }
    }

    _contentController.text = lines.join('\n');
  }

  Future<void> _showAddTagDialog() async {
    final allTags = await ref.read(allTagsProvider.future);
    final availableTags =
        allTags.where((t) => !_noteTags.any((nt) => nt.id == t.id)).toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tag hinzufügen',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (availableTags.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Keine weiteren Tags verfügbar'),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableTags.map((tag) {
                    return ActionChip(
                      label: Text(tag.name),
                      backgroundColor:
                          Color(tag.color).withValues(alpha: 0.2),
                      onPressed: () {
                        Navigator.pop(context);
                        _addTag(tag);
                      },
                    );
                  }).toList(),
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Neuen Tag erstellen'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const CreateTagDialog(),
                ).then((_) {
                  // Tags neu laden falls ein neuer erstellt wurde
                  if (_existingNote != null) {
                    _loadNoteTags();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _loadNoteTags() async {
    if (_existingNote != null) {
      final tags =
          await ref.read(tagsDaoProvider).getTagsForNote(_existingNote!.id);
      setState(() {
        _noteTags = tags;
      });
    }
  }

  void _addTag(Tag tag) {
    if (_existingNote != null) {
      ref.read(tagsDaoProvider).addTagToNote(_existingNote!.id, tag.id);
    }
    setState(() {
      _noteTags = [..._noteTags, tag];
    });
  }

  void _removeTag(Tag tag) {
    if (_existingNote != null) {
      ref.read(tagsDaoProvider).removeTagFromNote(_existingNote!.id, tag.id);
    }
    setState(() {
      _noteTags = _noteTags.where((t) => t.id != tag.id).toList();
    });
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
    if (_isSaving) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Nicht speichern wenn leer
    if (title.isEmpty && content.isEmpty) {
      if (_existingNote == null) {
        Navigator.of(context).pop();
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final notesDao = ref.read(notesDaoProvider);
    String noteId;

    if (_existingNote != null) {
      noteId = _existingNote!.id;
      // Bestehende Notiz aktualisieren
      await notesDao.updateNote(
        _existingNote!.copyWith(
          title: title,
          content: content,
          updatedAt: now,
        ),
      );
      _existingNote = _existingNote!.copyWith(
        title: title,
        content: content,
        updatedAt: now,
      );
    } else {
      // Neue Notiz erstellen
      noteId = const Uuid().v4();
      await notesDao.createNote(
        NotesCompanion.insert(
          id: noteId,
          folderId: widget.folderId,
          title: Value(title),
          content: Value(content),
          createdAt: now,
          updatedAt: now,
        ),
      );
      // Notiz laden um _existingNote zu setzen
      final note = await notesDao.getNoteById(noteId);
      setState(() {
        _existingNote = note;
      });
    }

    // Tags speichern
    if (_existingNote != null) {
      final tagIds = _noteTags.map((t) => t.id).toList();
      await ref.read(tagsDaoProvider).setTagsForNote(_existingNote!.id, tagIds);
    }

    setState(() {
      _hasChanges = false;
      _isSaving = false;
      _lastSavedContent = content;
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
      case 'archive':
        if (_existingNote != null) {
          ref.read(notesDaoProvider).toggleArchive(_existingNote!.id);
          final wasArchived = _existingNote!.isArchived;
          setState(() {
            _existingNote = _existingNote!.copyWith(
              isArchived: !_existingNote!.isArchived,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(wasArchived
                  ? 'Aus Archiv wiederhergestellt'
                  : 'In Archiv verschoben'),
            ),
          );
        }
        break;
      case 'tags':
        _showAddTagDialog();
        break;
      case 'move':
        _showMoveDialog();
        break;
      case 'info':
        _showInfoDialog();
        break;
      case 'export_md':
        _exportAsMarkdown();
        break;
      case 'export_txt':
        _exportAsText();
        break;
      case 'copy':
        _copyToClipboard();
        break;
      case 'save_template':
        _saveAsTemplate();
        break;
      case 'delete':
        _confirmDelete();
        break;
    }
  }

  Future<void> _saveAsTemplate() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SaveAsTemplateDialog(
        title: _titleController.text.trim(),
        content: _contentController.text,
        contentType: 'text',
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vorlage gespeichert')),
      );
    }
  }

  /// Notiz teilen
  Future<void> _shareNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (content.isEmpty && title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nichts zu teilen')),
      );
      return;
    }

    // Inhalt für das Teilen vorbereiten
    final shareText = StringBuffer();
    if (title.isNotEmpty) {
      shareText.writeln('# $title');
      shareText.writeln();
    }
    shareText.write(content);

    try {
      await Share.share(shareText.toString());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Teilen: $e')),
        );
      }
    }
  }

  Future<void> _showMoveDialog() async {
    if (_existingNote == null) return;

    final folders = await ref.read(allFoldersProvider.future);
    if (!mounted) return;

    final folderId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('In Ordner verschieben'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              final isCurrent = folder.id == _existingNote!.folderId;
              return ListTile(
                leading: Icon(Icons.folder, color: Color(folder.color)),
                title: Text(folder.name),
                trailing: isCurrent ? const Icon(Icons.check) : null,
                onTap: isCurrent ? null : () => Navigator.pop(context, folder.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );

    if (folderId != null && mounted) {
      await ref.read(notesDaoProvider).moveNote(_existingNote!.id, folderId);
      setState(() {
        _existingNote = _existingNote!.copyWith(folderId: folderId);
      });
      if (mounted) {
        final folder = folders.firstWhere((f) => f.id == folderId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nach "${folder.name}" verschoben')),
        );
      }
    }
  }

  Future<void> _exportAsMarkdown() async {
    if (_existingNote == null) {
      // Erst speichern
      await _saveNote(showMessage: false);
    }

    if (_existingNote != null) {
      try {
        await ExportService.instance.shareAsMarkdown(_existingNote!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Export: $e')),
          );
        }
      }
    }
  }

  Future<void> _exportAsText() async {
    if (_existingNote == null) {
      await _saveNote(showMessage: false);
    }

    if (_existingNote != null) {
      try {
        await ExportService.instance.shareAsText(_existingNote!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Export: $e')),
          );
        }
      }
    }
  }

  Future<void> _copyToClipboard() async {
    final content = _contentController.text;
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nichts zu kopieren')),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('In Zwischenablage kopiert')),
      );
    }
  }

  void _showInfoDialog() {
    if (_existingNote == null) return;

    final content = _contentController.text;
    final wordCount = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final charCount = content.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informationen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              label: 'Erstellt',
              value: _formatDate(_existingNote!.createdAt),
            ),
            _InfoRow(
              label: 'Geändert',
              value: _formatDate(_existingNote!.updatedAt),
            ),
            const Divider(),
            _InfoRow(
              label: 'Wörter',
              value: wordCount.toString(),
            ),
            _InfoRow(
              label: 'Zeichen',
              value: charCount.toString(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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

/// Info-Zeile für den Info-Dialog
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
