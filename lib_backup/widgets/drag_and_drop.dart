import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';

/// Daten die beim Drag & Drop übertragen werden
class NoteDragData {
  final String noteId;
  final String noteTitle;
  final String currentFolderId;

  const NoteDragData({
    required this.noteId,
    required this.noteTitle,
    required this.currentFolderId,
  });
}

class FolderDragData {
  final String folderId;
  final String folderName;
  final String? parentId;

  const FolderDragData({
    required this.folderId,
    required this.folderName,
    this.parentId,
  });
}

/// Draggable Wrapper für Notiz-Karten
class DraggableNoteCard extends StatelessWidget {
  final Note note;
  final Widget child;
  final bool enabled;

  const DraggableNoteCard({
    super.key,
    required this.note,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final colorScheme = Theme.of(context).colorScheme;

    return LongPressDraggable<NoteDragData>(
      data: NoteDragData(
        noteId: note.id,
        noteTitle: note.title,
        currentFolderId: note.folderId,
      ),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.article,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.title.isEmpty ? 'Unbenannt' : note.title,
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: child,
      ),
      child: child,
    );
  }
}

/// Drop-Ziel für Ordner (akzeptiert Notizen)
class FolderDropTarget extends ConsumerStatefulWidget {
  final Folder folder;
  final Widget child;
  final VoidCallback? onDropSuccess;

  const FolderDropTarget({
    super.key,
    required this.folder,
    required this.child,
    this.onDropSuccess,
  });

  @override
  ConsumerState<FolderDropTarget> createState() => _FolderDropTargetState();
}

class _FolderDropTargetState extends ConsumerState<FolderDropTarget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DragTarget<NoteDragData>(
      onWillAcceptWithDetails: (details) {
        // Nicht akzeptieren wenn Notiz bereits in diesem Ordner ist
        final willAccept = details.data.currentFolderId != widget.folder.id;
        if (willAccept && !_isHovering) {
          setState(() => _isHovering = true);
        }
        return willAccept;
      },
      onLeave: (_) {
        setState(() => _isHovering = false);
      },
      onAcceptWithDetails: (details) async {
        setState(() => _isHovering = false);

        // Notiz verschieben
        await ref.read(notesDaoProvider).moveNote(
          details.data.noteId,
          widget.folder.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '„${details.data.noteTitle}" nach „${widget.folder.name}" verschoben',
              ),
              action: SnackBarAction(
                label: 'Rückgängig',
                onPressed: () {
                  ref.read(notesDaoProvider).moveNote(
                    details.data.noteId,
                    details.data.currentFolderId,
                  );
                },
              ),
            ),
          );
        }

        widget.onDropSuccess?.call();
      },
      builder: (context, candidateData, rejectedData) {
        if (_isHovering) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: widget.child,
          );
        }
        return widget.child;
      },
    );
  }
}

/// Draggable Wrapper für Ordner (für Neuordnung)
class DraggableFolder extends StatelessWidget {
  final Folder folder;
  final Widget child;
  final bool enabled;

  const DraggableFolder({
    super.key,
    required this.folder,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final colorScheme = Theme.of(context).colorScheme;

    return LongPressDraggable<FolderDragData>(
      data: FolderDragData(
        folderId: folder.id,
        folderName: folder.name,
        parentId: folder.parentId,
      ),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder,
                color: Color(folder.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  folder.name,
                  style: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: child,
      ),
      child: child,
    );
  }
}

/// Drop-Ziel für Ordner-Neuanordnung (Ordner als Parent setzen)
class FolderReorderTarget extends ConsumerStatefulWidget {
  final Folder folder;
  final Widget child;
  final VoidCallback? onDropSuccess;

  const FolderReorderTarget({
    super.key,
    required this.folder,
    required this.child,
    this.onDropSuccess,
  });

  @override
  ConsumerState<FolderReorderTarget> createState() => _FolderReorderTargetState();
}

class _FolderReorderTargetState extends ConsumerState<FolderReorderTarget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DragTarget<FolderDragData>(
      onWillAcceptWithDetails: (details) {
        // Nicht akzeptieren wenn Ordner auf sich selbst gezogen wird
        // oder wenn er bereits ein Kind dieses Ordners ist
        final willAccept = details.data.folderId != widget.folder.id &&
            details.data.parentId != widget.folder.id;
        if (willAccept && !_isHovering) {
          setState(() => _isHovering = true);
        }
        return willAccept;
      },
      onLeave: (_) {
        setState(() => _isHovering = false);
      },
      onAcceptWithDetails: (details) async {
        setState(() => _isHovering = false);

        // Ordner als Unterordner verschieben
        await ref.read(foldersDaoProvider).moveFolder(
          details.data.folderId,
          widget.folder.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '„${details.data.folderName}" nach „${widget.folder.name}" verschoben',
              ),
            ),
          );
        }

        widget.onDropSuccess?.call();
      },
      builder: (context, candidateData, rejectedData) {
        if (_isHovering) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.secondary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.secondary.withValues(alpha: 0.1),
            ),
            child: widget.child,
          );
        }
        return widget.child;
      },
    );
  }
}

/// Kombiniertes Drop-Target für Notizen UND Ordner
class CombinedFolderDropTarget extends ConsumerStatefulWidget {
  final Folder folder;
  final Widget child;
  final VoidCallback? onDropSuccess;

  const CombinedFolderDropTarget({
    super.key,
    required this.folder,
    required this.child,
    this.onDropSuccess,
  });

  @override
  ConsumerState<CombinedFolderDropTarget> createState() =>
      _CombinedFolderDropTargetState();
}

class _CombinedFolderDropTargetState
    extends ConsumerState<CombinedFolderDropTarget> {
  bool _isHoveringNote = false;
  bool _isHoveringFolder = false;

  bool get _isHovering => _isHoveringNote || _isHoveringFolder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Notiz-Drop-Target
    return DragTarget<NoteDragData>(
      onWillAcceptWithDetails: (details) {
        final willAccept = details.data.currentFolderId != widget.folder.id;
        if (willAccept && !_isHoveringNote) {
          setState(() => _isHoveringNote = true);
        }
        return willAccept;
      },
      onLeave: (_) {
        setState(() => _isHoveringNote = false);
      },
      onAcceptWithDetails: (details) async {
        setState(() => _isHoveringNote = false);
        await ref.read(notesDaoProvider).moveNote(
          details.data.noteId,
          widget.folder.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '„${details.data.noteTitle}" nach „${widget.folder.name}" verschoben',
              ),
              action: SnackBarAction(
                label: 'Rückgängig',
                onPressed: () {
                  ref.read(notesDaoProvider).moveNote(
                    details.data.noteId,
                    details.data.currentFolderId,
                  );
                },
              ),
            ),
          );
        }
        widget.onDropSuccess?.call();
      },
      builder: (context, noteCandidates, noteRejected) {
        // Ordner-Drop-Target (verschachtelt)
        return DragTarget<FolderDragData>(
          onWillAcceptWithDetails: (details) {
            final willAccept = details.data.folderId != widget.folder.id &&
                details.data.parentId != widget.folder.id;
            if (willAccept && !_isHoveringFolder) {
              setState(() => _isHoveringFolder = true);
            }
            return willAccept;
          },
          onLeave: (_) {
            setState(() => _isHoveringFolder = false);
          },
          onAcceptWithDetails: (details) async {
            setState(() => _isHoveringFolder = false);
            await ref.read(foldersDaoProvider).moveFolder(
              details.data.folderId,
              widget.folder.id,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '„${details.data.folderName}" nach „${widget.folder.name}" verschoben',
                  ),
                ),
              );
            }
            widget.onDropSuccess?.call();
          },
          builder: (context, folderCandidates, folderRejected) {
            if (_isHovering) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isHoveringNote
                        ? colorScheme.primary
                        : colorScheme.secondary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: (_isHoveringNote
                          ? colorScheme.primary
                          : colorScheme.secondary)
                      .withValues(alpha: 0.1),
                ),
                child: widget.child,
              );
            }
            return widget.child;
          },
        );
      },
    );
  }
}

/// Drop-Zone für Root-Level (Ordner aus Unterordner herausnehmen)
class RootDropZone extends ConsumerStatefulWidget {
  final Widget child;

  const RootDropZone({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<RootDropZone> createState() => _RootDropZoneState();
}

class _RootDropZoneState extends ConsumerState<RootDropZone> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DragTarget<FolderDragData>(
      onWillAcceptWithDetails: (details) {
        // Nur akzeptieren wenn Ordner aktuell einen Parent hat
        final willAccept = details.data.parentId != null;
        if (willAccept && !_isHovering) {
          setState(() => _isHovering = true);
        }
        return willAccept;
      },
      onLeave: (_) {
        setState(() => _isHovering = false);
      },
      onAcceptWithDetails: (details) async {
        setState(() => _isHovering = false);

        // Ordner zu Root-Level verschieben
        await ref.read(foldersDaoProvider).moveFolder(
          details.data.folderId,
          null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '„${details.data.folderName}" auf Root-Ebene verschoben',
              ),
            ),
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        if (_isHovering) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.tertiary,
                width: 2,
              ),
              color: colorScheme.tertiary.withValues(alpha: 0.1),
            ),
            child: widget.child,
          );
        }
        return widget.child;
      },
    );
  }
}
