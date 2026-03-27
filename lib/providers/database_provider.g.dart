// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$databaseHash() => r'397e5c893a29d7b17310deb6724df71242a8ab08';

/// See also [database].
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
String _$foldersDaoHash() => r'ca1ac3c97e15a6aaf6b16687dd419de0f89f0640';

/// See also [foldersDao].
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
String _$notesDaoHash() => r'8942aa32358f40e027e7bca661557187f7866ff1';

/// See also [notesDao].
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
String _$tagsDaoHash() => r'9ff286abf369eda5a7ae6dd22f41381df538500d';

/// See also [tagsDao].
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
