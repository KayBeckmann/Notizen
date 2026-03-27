// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notesInFolderHash() => r'7bbb03a99b1e3305e4a30d9ea8834f2b0978c51b';

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

/// See also [notesInFolder].
@ProviderFor(notesInFolder)
const notesInFolderProvider = NotesInFolderFamily();

/// See also [notesInFolder].
class NotesInFolderFamily extends Family<AsyncValue<List<Note>>> {
  /// See also [notesInFolder].
  const NotesInFolderFamily();

  /// See also [notesInFolder].
  NotesInFolderProvider call(
    String? folderId,
  ) {
    return NotesInFolderProvider(
      folderId,
    );
  }

  @override
  NotesInFolderProvider getProviderOverride(
    covariant NotesInFolderProvider provider,
  ) {
    return call(
      provider.folderId,
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
  String? get name => r'notesInFolderProvider';
}

/// See also [notesInFolder].
class NotesInFolderProvider extends AutoDisposeStreamProvider<List<Note>> {
  /// See also [notesInFolder].
  NotesInFolderProvider(
    String? folderId,
  ) : this._internal(
          (ref) => notesInFolder(
            ref as NotesInFolderRef,
            folderId,
          ),
          from: notesInFolderProvider,
          name: r'notesInFolderProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$notesInFolderHash,
          dependencies: NotesInFolderFamily._dependencies,
          allTransitiveDependencies:
              NotesInFolderFamily._allTransitiveDependencies,
          folderId: folderId,
        );

  NotesInFolderProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.folderId,
  }) : super.internal();

  final String? folderId;

  @override
  Override overrideWith(
    Stream<List<Note>> Function(NotesInFolderRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NotesInFolderProvider._internal(
        (ref) => create(ref as NotesInFolderRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        folderId: folderId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Note>> createElement() {
    return _NotesInFolderProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotesInFolderProvider && other.folderId == folderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, folderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NotesInFolderRef on AutoDisposeStreamProviderRef<List<Note>> {
  /// The parameter `folderId` of this provider.
  String? get folderId;
}

class _NotesInFolderProviderElement
    extends AutoDisposeStreamProviderElement<List<Note>> with NotesInFolderRef {
  _NotesInFolderProviderElement(super.provider);

  @override
  String? get folderId => (origin as NotesInFolderProvider).folderId;
}

String _$currentFolderHash() => r'22a9b9945e934581531f4cf2542a4dcfa7ed5577';

/// See also [CurrentFolder].
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
