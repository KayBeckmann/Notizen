import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';

/// Provider für archivierte Notizen
final archivedNotesProvider = StreamProvider<List<Note>>((ref) {
  return ref.watch(notesDaoProvider).watchArchivedNotes();
});

/// Archiv-Bildschirm
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedNotesAsync = ref.watch(archivedNotesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archiv'),
      ),
      body: archivedNotesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 80,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Archiv ist leer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Archivierte Notizen werden hier angezeigt',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Info-Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Archivierte Notizen erscheinen nicht in der Hauptansicht',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              // Notizliste
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _ArchiveNoteCard(
                      note: note,
                      onUnarchive: () => _unarchiveNote(context, ref, note),
                      onDelete: () => _confirmDelete(context, ref, note),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Fehler: $error')),
      ),
    );
  }

  void _unarchiveNote(BuildContext context, WidgetRef ref, Note note) {
    ref.read(notesDaoProvider).toggleArchive(note.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '„${note.title.isEmpty ? 'Notiz' : note.title}" wiederhergestellt'),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: () {
            ref.read(notesDaoProvider).toggleArchive(note.id);
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('In Papierkorb verschieben?'),
        content: Text(
          '„${note.title.isEmpty ? 'Notiz' : note.title}" wird in den Papierkorb verschoben.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notesDaoProvider).moveToTrash(note.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('In Papierkorb verschoben')),
              );
            },
            child: const Text('Verschieben'),
          ),
        ],
      ),
    );
  }
}

class _ArchiveNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onUnarchive;
  final VoidCallback onDelete;

  const _ArchiveNoteCard({
    required this.note,
    required this.onUnarchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titel und Typ
            Row(
              children: [
                _buildContentTypeIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title.isEmpty ? 'Unbenannt' : note.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Archiviert: ${_formatDate(note.updatedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Vorschau des Inhalts
            if (note.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                note.content,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            // Aktionen
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onUnarchive,
                  icon: const Icon(Icons.unarchive_outlined),
                  label: const Text('Wiederherstellen'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  label: Text(
                    'Löschen',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeIcon(BuildContext context) {
    final theme = Theme.of(context);
    IconData icon;

    switch (note.contentType) {
      case 'audio':
        icon = Icons.mic;
        break;
      case 'image':
        icon = Icons.image;
        break;
      case 'drawing':
        icon = Icons.brush;
        break;
      default:
        icon = Icons.article;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: theme.colorScheme.outline),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMd().add_Hm().format(date);
  }
}
