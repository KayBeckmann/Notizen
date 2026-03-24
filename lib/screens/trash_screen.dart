import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';

/// Provider für Papierkorb-Notizen
final trashedNotesProvider = StreamProvider<List<Note>>((ref) {
  return ref.watch(notesDaoProvider).watchTrashedNotes();
});

/// Papierkorb-Bildschirm
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashedNotesAsync = ref.watch(trashedNotesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Papierkorb'),
        actions: [
          trashedNotesAsync.when(
            data: (notes) => notes.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_forever),
                    onPressed: () => _confirmEmptyTrash(context, ref),
                    tooltip: 'Papierkorb leeren',
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: trashedNotesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 80,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Papierkorb ist leer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gelöschte Notizen werden hier angezeigt',
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
                        'Notizen werden nach 30 Tagen automatisch gelöscht',
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
                    return _TrashNoteCard(
                      note: note,
                      onRestore: () => _restoreNote(context, ref, note),
                      onDelete: () => _confirmDeletePermanently(context, ref, note),
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

  void _confirmEmptyTrash(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever, color: Colors.red),
        title: const Text('Papierkorb leeren?'),
        content: const Text(
          'Alle Notizen im Papierkorb werden unwiderruflich gelöscht. '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(notesDaoProvider).emptyTrash();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Papierkorb geleert')),
              );
            },
            child: const Text('Leeren'),
          ),
        ],
      ),
    );
  }

  void _restoreNote(BuildContext context, WidgetRef ref, Note note) {
    ref.read(notesDaoProvider).restoreFromTrash(note.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('„${note.title.isEmpty ? 'Notiz' : note.title}" wiederhergestellt'),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: () {
            ref.read(notesDaoProvider).moveToTrash(note.id);
          },
        ),
      ),
    );
  }

  void _confirmDeletePermanently(BuildContext context, WidgetRef ref, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever, color: Colors.red),
        title: const Text('Endgültig löschen?'),
        content: Text(
          '„${note.title.isEmpty ? 'Notiz' : note.title}" wird unwiderruflich gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(notesDaoProvider).deleteNote(note.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notiz endgültig gelöscht')),
              );
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

class _TrashNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _TrashNoteCard({
    required this.note,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Berechne verbleibende Tage
    final trashedAt = note.trashedAt ?? DateTime.now();
    final deleteAt = trashedAt.add(const Duration(days: 30));
    final daysRemaining = deleteAt.difference(DateTime.now()).inDays;

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
                        'Gelöscht: ${_formatDate(trashedAt)} • '
                        'Noch $daysRemaining Tage',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: daysRemaining <= 7
                              ? colorScheme.error
                              : colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Aktionen
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore),
                  label: const Text('Wiederherstellen'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_forever, color: colorScheme.error),
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
