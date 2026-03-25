import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database.dart';
import '../../services/sync/sync_provider.dart';

/// Dialog zur Auflösung von Sync-Konflikten
class ConflictResolutionDialog extends StatelessWidget {
  final SyncConflict conflict;
  final void Function(ConflictResolution) onResolve;

  const ConflictResolutionDialog({
    super.key,
    required this.conflict,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          const Expanded(child: Text('Sync-Konflikt')),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Die Notiz "${conflict.localNote.title.isEmpty ? "Unbenannt" : conflict.localNote.title}" '
              'wurde sowohl lokal als auch auf dem Server geändert.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            // Vergleichsansicht
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lokale Version
                Expanded(
                  child: _VersionCard(
                    title: 'Lokale Version',
                    icon: Icons.phone_android,
                    note: conflict.localNote,
                    modified: conflict.localModified,
                    dateFormat: dateFormat,
                    color: theme.colorScheme.primaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                // Server Version
                Expanded(
                  child: _VersionCard(
                    title: 'Server Version',
                    icon: Icons.cloud,
                    note: conflict.remoteNote,
                    modified: conflict.remoteModified,
                    dateFormat: dateFormat,
                    color: theme.colorScheme.secondaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        // Abbrechen
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Später'),
        ),
        // Beide behalten
        OutlinedButton.icon(
          onPressed: () {
            onResolve(ConflictResolution.keepBoth);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.content_copy, size: 18),
          label: const Text('Beide behalten'),
        ),
        // Lokal behalten
        FilledButton.tonalIcon(
          onPressed: () {
            onResolve(ConflictResolution.keepLocal);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.phone_android, size: 18),
          label: const Text('Lokal'),
        ),
        // Server behalten
        FilledButton.icon(
          onPressed: () {
            onResolve(ConflictResolution.keepRemote);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.cloud, size: 18),
          label: const Text('Server'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }
}

/// Karte für eine Notiz-Version
class _VersionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Note note;
  final DateTime modified;
  final DateFormat dateFormat;
  final Color color;

  const _VersionCard({
    required this.title,
    required this.icon,
    required this.note,
    required this.modified,
    required this.dateFormat,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              note.title.isEmpty ? 'Unbenannt' : note.title,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _getPreviewText(note.content),
              style: theme.textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Geändert: ${dateFormat.format(modified)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${_countWords(note.content)} Wörter',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviewText(String content) {
    final preview = content
        .replaceAll(RegExp(r'#{1,6}\s'), '')
        .replaceAll(RegExp(r'\*{1,2}'), '')
        .replaceAll(RegExp(r'_{1,2}'), '')
        .replaceAll(RegExp(r'`{1,3}'), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();

    return preview.isEmpty ? '(Leer)' : preview;
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }
}

/// Zeigt den Konflikt-Dialog an
Future<ConflictResolution?> showConflictResolutionDialog(
  BuildContext context,
  SyncConflict conflict,
) async {
  ConflictResolution? resolution;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ConflictResolutionDialog(
      conflict: conflict,
      onResolve: (r) => resolution = r,
    ),
  );

  return resolution;
}

/// Liste aller Konflikte anzeigen
class ConflictListDialog extends StatelessWidget {
  final List<SyncConflict> conflicts;
  final void Function(SyncConflict, ConflictResolution) onResolve;

  const ConflictListDialog({
    super.key,
    required this.conflicts,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Text('${conflicts.length} Konflikte'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: conflicts.length,
          itemBuilder: (context, index) {
            final conflict = conflicts[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.description),
                title: Text(
                  conflict.localNote.title.isEmpty
                      ? 'Unbenannt'
                      : conflict.localNote.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Lokal: ${_formatDate(conflict.localModified)} | '
                  'Server: ${_formatDate(conflict.remoteModified)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () async {
                    final resolution = await showConflictResolutionDialog(
                      context,
                      conflict,
                    );
                    if (resolution != null) {
                      onResolve(conflict, resolution);
                    }
                  },
                  tooltip: 'Konflikt lösen',
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Schließen'),
        ),
        FilledButton.icon(
          onPressed: () {
            // Alle mit "neueste gewinnt" auflösen
            for (final conflict in conflicts) {
              final resolution = conflict.localModified.isAfter(conflict.remoteModified)
                  ? ConflictResolution.keepLocal
                  : ConflictResolution.keepRemote;
              onResolve(conflict, resolution);
            }
            Navigator.pop(context);
          },
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('Alle automatisch'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}. ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
