// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$databaseHash() => r'd66464688f3f3beae31aa517238455b4413086f1';

/// Singleton-Instanz der Datenbank
///
/// Copied from [database].
@ProviderFor(database)
final databaseProvider = Provider<AppDatabase>.internal(
  database,
  name: r'databaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$databaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DatabaseRef = ProviderRef<AppDatabase>;
String _$foldersDaoHash() => r'fee4cdef35629aa0a8792b064aea2a8d1af2fcfb';

/// FoldersDao Provider
///
/// Copied from [foldersDao].
@ProviderFor(foldersDao)
final foldersDaoProvider = AutoDisposeProvider<FoldersDao>.internal(
  foldersDao,
  name: r'foldersDaoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$foldersDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FoldersDaoRef = AutoDisposeProviderRef<FoldersDao>;
String _$notesDaoHash() => r'c2c519d8df605d549fc600081eb2ab1ed371da76';

/// NotesDao Provider
///
/// Copied from [notesDao].
@ProviderFor(notesDao)
final notesDaoProvider = AutoDisposeProvider<NotesDao>.internal(
  notesDao,
  name: r'notesDaoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$notesDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotesDaoRef = AutoDisposeProviderRef<NotesDao>;
String _$tagsDaoHash() => r'aca26f11c60c8ef8541f82750f62944b8744165f';

/// TagsDao Provider
///
/// Copied from [tagsDao].
@ProviderFor(tagsDao)
final tagsDaoProvider = AutoDisposeProvider<TagsDao>.internal(
  tagsDao,
  name: r'tagsDaoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tagsDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TagsDaoRef = AutoDisposeProviderRef<TagsDao>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
