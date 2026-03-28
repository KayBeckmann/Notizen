// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allFoldersHash() => r'c0c7ba97a9dd46a814a238f843ec55e48600408e';

/// Stream aller Ordner
///
/// Copied from [allFolders].
@ProviderFor(allFolders)
final allFoldersProvider = AutoDisposeStreamProvider<List<Folder>>.internal(
  allFolders,
  name: r'allFoldersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allFoldersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllFoldersRef = AutoDisposeStreamProviderRef<List<Folder>>;
String _$rootFoldersHash() => r'16dab4910e04a3c4184c235b25ba34ddddfde552';

/// Stream der Root-Ordner
///
/// Copied from [rootFolders].
@ProviderFor(rootFolders)
final rootFoldersProvider = AutoDisposeStreamProvider<List<Folder>>.internal(
  rootFolders,
  name: r'rootFoldersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$rootFoldersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RootFoldersRef = AutoDisposeStreamProviderRef<List<Folder>>;
String _$childFoldersHash() => r'6f01ad0275dc0b6673a627bd54153c0f04d9502e';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Stream der Kind-Ordner
///
/// Copied from [childFolders].
@ProviderFor(childFolders)
const childFoldersProvider = ChildFoldersFamily();

/// Stream der Kind-Ordner
///
/// Copied from [childFolders].
class ChildFoldersFamily extends Family<AsyncValue<List<Folder>>> {
  /// Stream der Kind-Ordner
  ///
  /// Copied from [childFolders].
  const ChildFoldersFamily();

  /// Stream der Kind-Ordner
  ///
  /// Copied from [childFolders].
  ChildFoldersProvider call(
    String parentId,
  ) {
    return ChildFoldersProvider(
      parentId,
    );
  }

  @override
  ChildFoldersProvider getProviderOverride(
    covariant ChildFoldersProvider provider,
  ) {
    return call(
      provider.parentId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'childFoldersProvider';
}

/// Stream der Kind-Ordner
///
/// Copied from [childFolders].
class ChildFoldersProvider extends AutoDisposeStreamProvider<List<Folder>> {
  /// Stream der Kind-Ordner
  ///
  /// Copied from [childFolders].
  ChildFoldersProvider(
    String parentId,
  ) : this._internal(
          (ref) => childFolders(
            ref as ChildFoldersRef,
            parentId,
          ),
          from: childFoldersProvider,
          name: r'childFoldersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$childFoldersHash,
          dependencies: ChildFoldersFamily._dependencies,
          allTransitiveDependencies:
              ChildFoldersFamily._allTransitiveDependencies,
          parentId: parentId,
        );

  ChildFoldersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.parentId,
  }) : super.internal();

  final String parentId;

  @override
  Override overrideWith(
    Stream<List<Folder>> Function(ChildFoldersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChildFoldersProvider._internal(
        (ref) => create(ref as ChildFoldersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        parentId: parentId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Folder>> createElement() {
    return _ChildFoldersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChildFoldersProvider && other.parentId == parentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, parentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChildFoldersRef on AutoDisposeStreamProviderRef<List<Folder>> {
  /// The parameter `parentId` of this provider.
  String get parentId;
}

class _ChildFoldersProviderElement
    extends AutoDisposeStreamProviderElement<List<Folder>>
    with ChildFoldersRef {
  _ChildFoldersProviderElement(super.provider);

  @override
  String get parentId => (origin as ChildFoldersProvider).parentId;
}

String _$folderTreeHash() => r'901409d0a0169e890ff8f627997687b66aee440c';

/// Ordnerbaum Provider
///
/// Copied from [folderTree].
@ProviderFor(folderTree)
final folderTreeProvider = AutoDisposeFutureProvider<List<FolderNode>>.internal(
  folderTree,
  name: r'folderTreeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$folderTreeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FolderTreeRef = AutoDisposeFutureProviderRef<List<FolderNode>>;
String _$currentFolderHash() => r'c2965e2aa8a792fcc5886fc27bdb3953631d270c';

/// Aktuell ausgewählter Ordner (persistiert)
///
/// Copied from [CurrentFolder].
@ProviderFor(CurrentFolder)
final currentFolderProvider =
    AutoDisposeNotifierProvider<CurrentFolder, String?>.internal(
  CurrentFolder.new,
  name: r'currentFolderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentFolderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentFolder = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
