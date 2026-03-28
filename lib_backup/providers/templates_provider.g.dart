// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'templates_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$templatesDaoHash() => r'377d1a8b08649c1a9a9ff41ac0dbf4275bd4735e';

/// Provider für den TemplatesDao
///
/// Copied from [templatesDao].
@ProviderFor(templatesDao)
final templatesDaoProvider = AutoDisposeProvider<TemplatesDao>.internal(
  templatesDao,
  name: r'templatesDaoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$templatesDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TemplatesDaoRef = AutoDisposeProviderRef<TemplatesDao>;
String _$allTemplatesHash() => r'8110c01270cd3e4139b50591193489c3b66763db';

/// Stream aller Vorlagen
///
/// Copied from [allTemplates].
@ProviderFor(allTemplates)
final allTemplatesProvider = AutoDisposeStreamProvider<List<Template>>.internal(
  allTemplates,
  name: r'allTemplatesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allTemplatesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllTemplatesRef = AutoDisposeStreamProviderRef<List<Template>>;
String _$templatesByTypeHash() => r'd9c9eda1850f80762b410b8938f54118bab9333d';

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

/// Vorlagen für bestimmten Content-Type
///
/// Copied from [templatesByType].
@ProviderFor(templatesByType)
const templatesByTypeProvider = TemplatesByTypeFamily();

/// Vorlagen für bestimmten Content-Type
///
/// Copied from [templatesByType].
class TemplatesByTypeFamily extends Family<AsyncValue<List<Template>>> {
  /// Vorlagen für bestimmten Content-Type
  ///
  /// Copied from [templatesByType].
  const TemplatesByTypeFamily();

  /// Vorlagen für bestimmten Content-Type
  ///
  /// Copied from [templatesByType].
  TemplatesByTypeProvider call(
    String contentType,
  ) {
    return TemplatesByTypeProvider(
      contentType,
    );
  }

  @override
  TemplatesByTypeProvider getProviderOverride(
    covariant TemplatesByTypeProvider provider,
  ) {
    return call(
      provider.contentType,
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
  String? get name => r'templatesByTypeProvider';
}

/// Vorlagen für bestimmten Content-Type
///
/// Copied from [templatesByType].
class TemplatesByTypeProvider
    extends AutoDisposeStreamProvider<List<Template>> {
  /// Vorlagen für bestimmten Content-Type
  ///
  /// Copied from [templatesByType].
  TemplatesByTypeProvider(
    String contentType,
  ) : this._internal(
          (ref) => templatesByType(
            ref as TemplatesByTypeRef,
            contentType,
          ),
          from: templatesByTypeProvider,
          name: r'templatesByTypeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$templatesByTypeHash,
          dependencies: TemplatesByTypeFamily._dependencies,
          allTransitiveDependencies:
              TemplatesByTypeFamily._allTransitiveDependencies,
          contentType: contentType,
        );

  TemplatesByTypeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.contentType,
  }) : super.internal();

  final String contentType;

  @override
  Override overrideWith(
    Stream<List<Template>> Function(TemplatesByTypeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TemplatesByTypeProvider._internal(
        (ref) => create(ref as TemplatesByTypeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        contentType: contentType,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Template>> createElement() {
    return _TemplatesByTypeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TemplatesByTypeProvider && other.contentType == contentType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, contentType.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TemplatesByTypeRef on AutoDisposeStreamProviderRef<List<Template>> {
  /// The parameter `contentType` of this provider.
  String get contentType;
}

class _TemplatesByTypeProviderElement
    extends AutoDisposeStreamProviderElement<List<Template>>
    with TemplatesByTypeRef {
  _TemplatesByTypeProviderElement(super.provider);

  @override
  String get contentType => (origin as TemplatesByTypeProvider).contentType;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
