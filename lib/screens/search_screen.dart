import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../models/enums.dart';
import '../providers/database_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/tags_provider.dart';
import '../widgets/note_card.dart';
import 'audio_note_screen.dart';
import 'drawing_note_screen.dart';
import 'image_note_screen.dart';
import 'note_editor_screen.dart';

/// Provider für die Suchanfrage
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider für Suchfilter
final searchFilterProvider = StateProvider<SearchFilter>((ref) => const SearchFilter());

/// Filter für die Suche
class SearchFilter {
  final String? folderId;
  final List<String> tagIds;
  final ContentType? contentType;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const SearchFilter({
    this.folderId,
    this.tagIds = const [],
    this.contentType,
    this.dateFrom,
    this.dateTo,
  });

  SearchFilter copyWith({
    String? folderId,
    List<String>? tagIds,
    ContentType? contentType,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearFolder = false,
    bool clearContentType = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return SearchFilter(
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      tagIds: tagIds ?? this.tagIds,
      contentType: clearContentType ? null : (contentType ?? this.contentType),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
    );
  }

  bool get hasFilters =>
      folderId != null ||
      tagIds.isNotEmpty ||
      contentType != null ||
      dateFrom != null ||
      dateTo != null;
}

/// Provider für Suchergebnisse
final searchResultsProvider = FutureProvider<List<Note>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final filter = ref.watch(searchFilterProvider);
  final notesDao = ref.watch(notesDaoProvider);

  if (query.isEmpty && !filter.hasFilters) {
    return [];
  }

  // Basis-Suche
  List<Note> results;
  if (query.isNotEmpty) {
    results = await notesDao.searchNotes(query);
  } else {
    results = await notesDao.getAllNotes();
  }

  // Filter anwenden
  return results.where((note) {
    // Ordner-Filter
    if (filter.folderId != null && note.folderId != filter.folderId) {
      return false;
    }

    // Content-Type-Filter
    if (filter.contentType != null) {
      final noteType = ContentType.values.firstWhere(
        (t) => t.name == note.contentType,
        orElse: () => ContentType.text,
      );
      if (noteType != filter.contentType) {
        return false;
      }
    }

    // Datum-Filter (erstellt nach)
    if (filter.dateFrom != null && note.createdAt.isBefore(filter.dateFrom!)) {
      return false;
    }

    // Datum-Filter (erstellt vor)
    if (filter.dateTo != null && note.createdAt.isAfter(filter.dateTo!)) {
      return false;
    }

    // Papierkorb und Archiv ausschließen
    if (note.isTrashed || note.isArchived) {
      return false;
    }

    return true;
  }).toList();
});

/// Such-Screen
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Autofokus auf Suchfeld
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(searchQueryProvider.notifier).state = _searchController.text;
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final filter = ref.watch(searchFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          decoration: InputDecoration(
            hintText: 'Notizen durchsuchen...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: filter.hasFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterSheet,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter-Chips
          if (filter.hasFilters) _buildFilterChips(filter),

          // Suchergebnisse
          Expanded(
            child: resultsAsync.when(
              data: (notes) => _buildResults(notes),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Fehler: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(SearchFilter filter) {
    final foldersAsync = ref.watch(allFoldersProvider);
    final tagsAsync = ref.watch(allTagsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Ordner-Filter
          if (filter.folderId != null)
            foldersAsync.when(
              data: (folders) {
                final folder = folders.firstWhere(
                  (f) => f.id == filter.folderId,
                  orElse: () => folders.first,
                );
                return InputChip(
                  avatar: Icon(Icons.folder, color: Color(folder.color), size: 18),
                  label: Text(folder.name),
                  onDeleted: () {
                    ref.read(searchFilterProvider.notifier).state =
                        filter.copyWith(clearFolder: true);
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

          // Tag-Filter
          ...filter.tagIds.map((tagId) {
            return tagsAsync.when(
              data: (tags) {
                final tag = tags.firstWhere(
                  (t) => t.id == tagId,
                  orElse: () => tags.first,
                );
                return InputChip(
                  avatar: CircleAvatar(
                    backgroundColor: Color(tag.color),
                    radius: 8,
                  ),
                  label: Text(tag.name),
                  onDeleted: () {
                    final newTagIds = List<String>.from(filter.tagIds)..remove(tagId);
                    ref.read(searchFilterProvider.notifier).state =
                        filter.copyWith(tagIds: newTagIds);
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          }),

          // Content-Type-Filter
          if (filter.contentType != null)
            InputChip(
              avatar: Icon(_getContentTypeIcon(filter.contentType!), size: 18),
              label: Text(_getContentTypeName(filter.contentType!)),
              onDeleted: () {
                ref.read(searchFilterProvider.notifier).state =
                    filter.copyWith(clearContentType: true);
              },
            ),

          // Alle Filter löschen
          if (filter.hasFilters)
            ActionChip(
              avatar: const Icon(Icons.clear_all, size: 18),
              label: const Text('Alle löschen'),
              onPressed: () {
                ref.read(searchFilterProvider.notifier).state = const SearchFilter();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResults(List<Note> notes) {
    final query = ref.watch(searchQueryProvider);

    if (query.isEmpty && !ref.watch(searchFilterProvider).hasFilters) {
      return _buildEmptyState(
        icon: Icons.search,
        title: 'Suche starten',
        subtitle: 'Gib einen Suchbegriff ein oder wähle Filter',
      );
    }

    if (notes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'Keine Ergebnisse',
        subtitle: 'Versuche einen anderen Suchbegriff oder Filter',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: NoteCard(
            note: note,
            onTap: () => _openNote(note),
            searchQuery: query.isNotEmpty ? query : null,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  void _openNote(Note note) {
    final contentType = ContentType.values.firstWhere(
      (t) => t.name == note.contentType,
      orElse: () => ContentType.text,
    );

    Widget screen;
    switch (contentType) {
      case ContentType.text:
        screen = NoteEditorScreen(noteId: note.id, folderId: note.folderId);
        break;
      case ContentType.audio:
        screen = AudioNoteScreen(noteId: note.id, folderId: note.folderId);
        break;
      case ContentType.image:
        screen = ImageNoteScreen(noteId: note.id, folderId: note.folderId);
        break;
      case ContentType.drawing:
        screen = DrawingNoteScreen(noteId: note.id, folderId: note.folderId);
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _FilterSheet(),
    );
  }

  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.text:
        return Icons.article;
      case ContentType.audio:
        return Icons.mic;
      case ContentType.image:
        return Icons.image;
      case ContentType.drawing:
        return Icons.brush;
    }
  }

  String _getContentTypeName(ContentType type) {
    switch (type) {
      case ContentType.text:
        return 'Text';
      case ContentType.audio:
        return 'Audio';
      case ContentType.image:
        return 'Bild';
      case ContentType.drawing:
        return 'Zeichnung';
    }
  }
}

/// Filter-BottomSheet
class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(searchFilterProvider);
    final foldersAsync = ref.watch(allFoldersProvider);
    final tagsAsync = ref.watch(allTagsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Titel
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(searchFilterProvider.notifier).state =
                            const SearchFilter();
                        Navigator.pop(context);
                      },
                      child: const Text('Zurücksetzen'),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Filter-Optionen
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Ordner-Filter
                    Text(
                      'Ordner',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    foldersAsync.when(
                      data: (folders) => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: folders.map((folder) {
                          final isSelected = filter.folderId == folder.id;
                          return FilterChip(
                            avatar: Icon(
                              Icons.folder,
                              color: Color(folder.color),
                              size: 18,
                            ),
                            label: Text(folder.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              ref.read(searchFilterProvider.notifier).state =
                                  filter.copyWith(
                                folderId: selected ? folder.id : null,
                                clearFolder: !selected,
                              );
                            },
                          );
                        }).toList(),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Fehler beim Laden'),
                    ),

                    const SizedBox(height: 24),

                    // Notiz-Typ-Filter
                    Text(
                      'Notiz-Typ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ContentType.values.map((type) {
                        final isSelected = filter.contentType == type;
                        return FilterChip(
                          avatar: Icon(
                            _getContentTypeIcon(type),
                            size: 18,
                          ),
                          label: Text(_getContentTypeName(type)),
                          selected: isSelected,
                          onSelected: (selected) {
                            ref.read(searchFilterProvider.notifier).state =
                                filter.copyWith(
                              contentType: selected ? type : null,
                              clearContentType: !selected,
                            );
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Tag-Filter
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    tagsAsync.when(
                      data: (tags) {
                        if (tags.isEmpty) {
                          return Text(
                            'Keine Tags vorhanden',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.outline,
                                ),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tags.map((tag) {
                            final isSelected = filter.tagIds.contains(tag.id);
                            return FilterChip(
                              avatar: CircleAvatar(
                                backgroundColor: Color(tag.color),
                                radius: 8,
                              ),
                              label: Text(tag.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                final newTagIds = List<String>.from(filter.tagIds);
                                if (selected) {
                                  newTagIds.add(tag.id);
                                } else {
                                  newTagIds.remove(tag.id);
                                }
                                ref.read(searchFilterProvider.notifier).state =
                                    filter.copyWith(tagIds: newTagIds);
                              },
                            );
                          }).toList(),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Fehler beim Laden'),
                    ),
                  ],
                ),
              ),

              // Anwenden-Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Filter anwenden'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.text:
        return Icons.article;
      case ContentType.audio:
        return Icons.mic;
      case ContentType.image:
        return Icons.image;
      case ContentType.drawing:
        return Icons.brush;
    }
  }

  String _getContentTypeName(ContentType type) {
    switch (type) {
      case ContentType.text:
        return 'Text';
      case ContentType.audio:
        return 'Audio';
      case ContentType.image:
        return 'Bild';
      case ContentType.drawing:
        return 'Zeichnung';
    }
  }
}
