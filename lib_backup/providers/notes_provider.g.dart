// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allNotesHash() => r'ec2618a4cb4e42af27c068314a1f954d955f5ed3';

/// Stream aller Notizen (nicht im Papierkorb)
///
/// Copied from [allNotes].
@ProviderFor(allNotes)
final allNotesProvider = AutoDisposeStreamProvider<List<Note>>.internal(
  allNotes,
  name: r'allNotesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allNotesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllNotesRef = AutoDisposeStreamProviderRef<List<Note>>;
String _$notesInCurrentFolderRawHash() =>
    r'b9f9a1e041b3d7190da8c86e6860d2378e58106a';

/// Stream der Notizen im aktuellen Ordner (unsortiert)
///
/// Copied from [notesInCurrentFolderRaw].
@ProviderFor(notesInCurrentFolderRaw)
final notesInCurrentFolderRawProvider =
    AutoDisposeStreamProvider<List<Note>>.internal(
  notesInCurrentFolderRaw,
  name: r'notesInCurrentFolderRawProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notesInCurrentFolderRawHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotesInCurrentFolderRawRef = AutoDisposeStreamProviderRef<List<Note>>;
String _$notesInCurrentFolderHash() =>
    r'4b205c82429ffc3c9acfde30e107c88ce0debcab';

/// Stream der Notizen im aktuellen Ordner (sortiert)
///
/// Copied from [notesInCurrentFolder].
@ProviderFor(notesInCurrentFolder)
final notesInCurrentFolderProvider =
    AutoDisposeStreamProvider<List<Note>>.internal(
  notesInCurrentFolder,
  name: r'notesInCurrentFolderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notesInCurrentFolderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotesInCurrentFolderRef = AutoDisposeStreamProviderRef<List<Note>>;
String _$pinnedNotesHash() => r'c126e4744be2df27a5e909398f0264b1969ad251';

/// Stream der angepinnten Notizen
///
/// Copied from [pinnedNotes].
@ProviderFor(pinnedNotes)
final pinnedNotesProvider = AutoDisposeStreamProvider<List<Note>>.internal(
  pinnedNotes,
  name: r'pinnedNotesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$pinnedNotesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PinnedNotesRef = AutoDisposeStreamProviderRef<List<Note>>;
String _$archivedNotesHash() => r'05a6beb5e2a1b6d863bc0b06beb91ee1cecce441';

/// Stream der archivierten Notizen
///
/// Copied from [archivedNotes].
@ProviderFor(archivedNotes)
final archivedNotesProvider = AutoDisposeStreamProvider<List<Note>>.internal(
  archivedNotes,
  name: r'archivedNotesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$archivedNotesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ArchivedNotesRef = AutoDisposeStreamProviderRef<List<Note>>;
String _$trashedNotesHash() => r'83effe1777803e322b028e2d1ac4557eb0d965c3';

/// Stream der Notizen im Papierkorb
///
/// Copied from [trashedNotes].
@ProviderFor(trashedNotes)
final trashedNotesProvider = AutoDisposeStreamProvider<List<Note>>.internal(
  trashedNotes,
  name: r'trashedNotesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$trashedNotesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TrashedNotesRef = AutoDisposeStreamProviderRef<List<Note>>;
String _$searchResultsHash() => r'1ac94d4ffe8c0f200481782bd35388157a007d51';

/// Suchergebnisse
///
/// Copied from [searchResults].
@ProviderFor(searchResults)
final searchResultsProvider = AutoDisposeStreamProvider<List<Note>>.internal(
  searchResults,
  name: r'searchResultsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchResultsRef = AutoDisposeStreamProviderRef<List<Note>>;
String _$noteCountsByFolderHash() =>
    r'5eb0257e49b73a34efeb2918efe0cfd0051c70d5';

/// Notizanzahl pro Ordner
///
/// Copied from [noteCountsByFolder].
@ProviderFor(noteCountsByFolder)
final noteCountsByFolderProvider =
    AutoDisposeStreamProvider<Map<String, int>>.internal(
  noteCountsByFolder,
  name: r'noteCountsByFolderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$noteCountsByFolderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NoteCountsByFolderRef = AutoDisposeStreamProviderRef<Map<String, int>>;
String _$pinnedCountHash() => r'a2fceb85e68a299f31d496e712f7b49eac85092c';

/// Anzahl angepinnter Notizen
///
/// Copied from [pinnedCount].
@ProviderFor(pinnedCount)
final pinnedCountProvider = AutoDisposeStreamProvider<int>.internal(
  pinnedCount,
  name: r'pinnedCountProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$pinnedCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PinnedCountRef = AutoDisposeStreamProviderRef<int>;
String _$archivedCountHash() => r'efead08ae6c6aa2bfec907f5494b06b446086db5';

/// Anzahl archivierter Notizen
///
/// Copied from [archivedCount].
@ProviderFor(archivedCount)
final archivedCountProvider = AutoDisposeStreamProvider<int>.internal(
  archivedCount,
  name: r'archivedCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$archivedCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ArchivedCountRef = AutoDisposeStreamProviderRef<int>;
String _$trashedCountHash() => r'2d84eb08eea4f7f221866cbe98faddb0490a0749';

/// Anzahl Notizen im Papierkorb
///
/// Copied from [trashedCount].
@ProviderFor(trashedCount)
final trashedCountProvider = AutoDisposeStreamProvider<int>.internal(
  trashedCount,
  name: r'trashedCountProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$trashedCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TrashedCountRef = AutoDisposeStreamProviderRef<int>;
String _$selectedNoteHash() => r'86ef90cd55e859fefafb068998baa3254fb2523a';

/// Aktuell ausgewählte Notiz
///
/// Copied from [SelectedNote].
@ProviderFor(SelectedNote)
final selectedNoteProvider =
    AutoDisposeNotifierProvider<SelectedNote, String?>.internal(
  SelectedNote.new,
  name: r'selectedNoteProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedNoteHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedNote = AutoDisposeNotifier<String?>;
String _$searchQueryHash() => r'b07ebd22fb9cb0db36c8d833cc6e21f4fcbd9b7b';

/// Suchbegriff
///
/// Copied from [SearchQuery].
@ProviderFor(SearchQuery)
final searchQueryProvider =
    AutoDisposeNotifierProvider<SearchQuery, String>.internal(
  SearchQuery.new,
  name: r'searchQueryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$searchQueryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SearchQuery = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
