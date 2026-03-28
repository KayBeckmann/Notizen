import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/tags_provider.dart';

/// Karte für eine Notiz in der Liste
class NoteCard extends ConsumerWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? searchQuery;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onLongPress,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tagsAsync = ref.watch(tagsForNoteProvider(note.id));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Titel und Pin-Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content-Type Icon
                  _buildContentTypeIcon(context),
                  const SizedBox(width: 12),

                  // Titel und Vorschau
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titel
                        _buildHighlightedText(
                          context,
                          note.title.isEmpty ? 'Unbenannt' : note.title,
                          theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),

                        // Vorschau des Inhalts
                        if (note.content.isNotEmpty)
                          _buildHighlightedText(
                            context,
                            _getPreviewText(),
                            theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                          ),
                      ],
                    ),
                  ),

                  // Pin-Icon
                  if (note.isPinned)
                    Icon(
                      Icons.push_pin,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Footer mit Tags und Datum
              Row(
                children: [
                  // Tags
                  Expanded(
                    child: tagsAsync.when(
                      data: (tags) => _buildTags(context, tags),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),

                  // Datum
                  Text(
                    _formatDate(note.updatedAt),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
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
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 20,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildTags(BuildContext context, List<Tag> tags) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Color(tag.color).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tag.name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Color(tag.color),
                ),
          ),
        );
      }).toList(),
    );
  }

  String _getPreviewText() {
    // Markdown-Formatierung für Vorschau entfernen
    final preview = note.content
        .replaceAll(RegExp(r'#{1,6}\s'), '')
        .replaceAll(RegExp(r'\*{1,2}'), '')
        .replaceAll(RegExp(r'_{1,2}'), '')
        .replaceAll(RegExp(r'`{1,3}'), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();

    return preview;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      return DateFormat.Hm().format(date);
    } else if (noteDate == today.subtract(const Duration(days: 1))) {
      return 'Gestern';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat.E().format(date);
    } else {
      return DateFormat.yMd().format(date);
    }
  }

  /// Erstellt einen Text mit hervorgehobenem Suchbegriff
  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    TextStyle? style, {
    int maxLines = 1,
  }) {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final query = searchQuery!.toLowerCase();
    final textLower = text.toLowerCase();
    final highlightColor = Theme.of(context).colorScheme.primaryContainer;
    final highlightTextColor = Theme.of(context).colorScheme.onPrimaryContainer;

    final List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final index = textLower.indexOf(query, start);
      if (index == -1) {
        // Rest des Textes hinzufügen
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }

      // Text vor dem Treffer
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      // Hervorgehobener Treffer
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: highlightColor,
          color: highlightTextColor,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
