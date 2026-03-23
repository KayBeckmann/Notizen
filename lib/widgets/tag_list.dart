import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/tags_provider.dart';
import 'tag_dialog.dart';

/// Widget das alle Tags als Chips anzeigt
class TagList extends ConsumerWidget {
  final String? selectedTagId;
  final Function(String? tagId)? onTagSelected;
  final bool showAddButton;

  const TagList({
    super.key,
    this.selectedTagId,
    this.onTagSelected,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(allTagsProvider);

    return tagsAsync.when(
      data: (tags) => _buildTagList(context, ref, tags),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
    );
  }

  Widget _buildTagList(
    BuildContext context,
    WidgetRef ref,
    List<Tag> tags,
  ) {
    if (tags.isEmpty && !showAddButton) {
      return const Center(
        child: Text('Keine Tags vorhanden'),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "Alle" Chip zum Zurücksetzen des Filters
        if (onTagSelected != null)
          FilterChip(
            label: const Text('Alle'),
            selected: selectedTagId == null,
            onSelected: (_) => onTagSelected!(null),
          ),
        // Tag Chips
        ...tags.map((tag) => _TagChip(
              tag: tag,
              isSelected: selectedTagId == tag.id,
              onTap: onTagSelected != null ? () => onTagSelected!(tag.id) : null,
              onLongPress: () => _showTagOptions(context, ref, tag),
            )),
        // Add Button
        if (showAddButton)
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('Neu'),
            onPressed: () => _showCreateTagDialog(context),
          ),
      ],
    );
  }

  void _showCreateTagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateTagDialog(),
    );
  }

  void _showTagOptions(BuildContext context, WidgetRef ref, Tag tag) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Bearbeiten'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => EditTagDialog(tag: tag),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Löschen'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDeleteTagDialog(context, tag);
                if (confirmed == true) {
                  ref.read(tagsDaoProvider).deleteTag(tag.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Einzelner Tag-Chip
class _TagChip extends StatelessWidget {
  final Tag tag;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _TagChip({
    required this.tag,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: FilterChip(
        label: Text(tag.name),
        selected: isSelected,
        onSelected: onTap != null ? (_) => onTap!() : null,
        backgroundColor: Color(tag.color).withValues(alpha: 0.2),
        selectedColor: Color(tag.color).withValues(alpha: 0.4),
        checkmarkColor: Color(tag.color),
        side: BorderSide(
          color: isSelected ? Color(tag.color) : Colors.transparent,
        ),
      ),
    );
  }
}

/// Tag-Sektion für den Drawer
class TagDrawerSection extends ConsumerWidget {
  const TagDrawerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(allTagsProvider);
    final selectedTagId = ref.watch(selectedTagProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tags',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _showCreateTagDialog(context),
                tooltip: 'Neuer Tag',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: tagsAsync.when(
            data: (tags) => _buildTagChips(context, ref, tags, selectedTagId),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Fehler: $e'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagChips(
    BuildContext context,
    WidgetRef ref,
    List<Tag> tags,
    String? selectedTagId,
  ) {
    if (tags.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Keine Tags vorhanden',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        final isSelected = selectedTagId == tag.id;
        return GestureDetector(
          onLongPress: () => _showTagOptions(context, ref, tag),
          child: FilterChip(
            label: Text(tag.name),
            selected: isSelected,
            onSelected: (_) {
              if (isSelected) {
                ref.read(selectedTagProvider.notifier).clear();
              } else {
                ref.read(selectedTagProvider.notifier).select(tag.id);
              }
            },
            backgroundColor: Color(tag.color).withValues(alpha: 0.2),
            selectedColor: Color(tag.color).withValues(alpha: 0.4),
            checkmarkColor: Color(tag.color),
            side: BorderSide(
              color: isSelected ? Color(tag.color) : Colors.transparent,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showCreateTagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateTagDialog(),
    );
  }

  void _showTagOptions(BuildContext context, WidgetRef ref, Tag tag) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Bearbeiten'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => EditTagDialog(tag: tag),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Löschen'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDeleteTagDialog(context, tag);
                if (confirmed == true) {
                  ref.read(tagsDaoProvider).deleteTag(tag.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
