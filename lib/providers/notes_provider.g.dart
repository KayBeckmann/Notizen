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
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allNotesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllNotesRef = AutoDisposeStreamProviderRef<List<Note>>;
String _$notesInCurrentFolderHash() =>
    r'd4f348a8d0d3031819a0cd805b24e256bd7cfd3a';

/// Stream der Notizen im aktuellen Ordner
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
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pinnedNotesHash,
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
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trashedNotesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TrashedNotesRef = AutoDisposeStreamProviderRef<List<Note>>;
String _$searchResultsHash() => r'f7ab9df64a5cd676c979efc2da11d5c691e054fb';

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
String _$selectedNoteHash() => r'86ef90cd55e859fefafb068998baa3254fb2523a';

/// Aktuell ausgewählte Notiz
///
/// Copied from [SelectedNote].
@ProviderFor(SelectedNote)
final selectedNoteProvider =
    AutoDisposeNotifierProvider<SelectedNote, String?>.internal(
      SelectedNote.new,
      name: r'selectedNoteProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$selectedNoteHash,
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
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$searchQueryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SearchQuery = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
