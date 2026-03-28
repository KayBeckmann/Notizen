// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tags_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allTagsHash() => r'33dbc634616fb3a666b88284a7ada8ee3f148288';

/// Stream aller Tags
///
/// Copied from [allTags].
@ProviderFor(allTags)
final allTagsProvider = AutoDisposeStreamProvider<List<Tag>>.internal(
  allTags,
  name: r'allTagsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allTagsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllTagsRef = AutoDisposeStreamProviderRef<List<Tag>>;
String _$tagsForNoteHash() => r'bb8a01b285e88c23b77528ee02138d8323ba6531';

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

/// Stream der Tags einer bestimmten Notiz
///
/// Copied from [tagsForNote].
@ProviderFor(tagsForNote)
const tagsForNoteProvider = TagsForNoteFamily();

/// Stream der Tags einer bestimmten Notiz
///
/// Copied from [tagsForNote].
class TagsForNoteFamily extends Family<AsyncValue<List<Tag>>> {
  /// Stream der Tags einer bestimmten Notiz
  ///
  /// Copied from [tagsForNote].
  const TagsForNoteFamily();

  /// Stream der Tags einer bestimmten Notiz
  ///
  /// Copied from [tagsForNote].
  TagsForNoteProvider call(
    String noteId,
  ) {
    return TagsForNoteProvider(
      noteId,
    );
  }

  @override
  TagsForNoteProvider getProviderOverride(
    covariant TagsForNoteProvider provider,
  ) {
    return call(
      provider.noteId,
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
  String? get name => r'tagsForNoteProvider';
}

/// Stream der Tags einer bestimmten Notiz
///
/// Copied from [tagsForNote].
class TagsForNoteProvider extends AutoDisposeStreamProvider<List<Tag>> {
  /// Stream der Tags einer bestimmten Notiz
  ///
  /// Copied from [tagsForNote].
  TagsForNoteProvider(
    String noteId,
  ) : this._internal(
          (ref) => tagsForNote(
            ref as TagsForNoteRef,
            noteId,
          ),
          from: tagsForNoteProvider,
          name: r'tagsForNoteProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$tagsForNoteHash,
          dependencies: TagsForNoteFamily._dependencies,
          allTransitiveDependencies:
              TagsForNoteFamily._allTransitiveDependencies,
          noteId: noteId,
        );

  TagsForNoteProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.noteId,
  }) : super.internal();

  final String noteId;

  @override
  Override overrideWith(
    Stream<List<Tag>> Function(TagsForNoteRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TagsForNoteProvider._internal(
        (ref) => create(ref as TagsForNoteRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        noteId: noteId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Tag>> createElement() {
    return _TagsForNoteProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TagsForNoteProvider && other.noteId == noteId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, noteId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TagsForNoteRef on AutoDisposeStreamProviderRef<List<Tag>> {
  /// The parameter `noteId` of this provider.
  String get noteId;
}

class _TagsForNoteProviderElement
    extends AutoDisposeStreamProviderElement<List<Tag>> with TagsForNoteRef {
  _TagsForNoteProviderElement(super.provider);

  @override
  String get noteId => (origin as TagsForNoteProvider).noteId;
}

String _$noteCountsByTagHash() => r'8999c17081b873e9b0aa5a92affee3d4b7ebd26f';

/// Notizanzahl pro Tag
///
/// Copied from [noteCountsByTag].
@ProviderFor(noteCountsByTag)
final noteCountsByTagProvider =
    AutoDisposeStreamProvider<Map<String, int>>.internal(
  noteCountsByTag,
  name: r'noteCountsByTagProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$noteCountsByTagHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NoteCountsByTagRef = AutoDisposeStreamProviderRef<Map<String, int>>;
String _$selectedTagHash() => r'85063674780d99a18a3fa0c8e632ed1877847aac';

/// Aktuell ausgewählter Tag zum Filtern
///
/// Copied from [SelectedTag].
@ProviderFor(SelectedTag)
final selectedTagProvider =
    AutoDisposeNotifierProvider<SelectedTag, String?>.internal(
  SelectedTag.new,
  name: r'selectedTagProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedTagHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedTag = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
