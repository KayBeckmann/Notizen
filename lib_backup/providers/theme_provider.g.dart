// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$themeModeNotifierHash() => r'8a659900e44dd8004fb460d066213c9b5db7ad81';

/// Theme-Modus Provider (System/Light/Dark)
///
/// Copied from [ThemeModeNotifier].
@ProviderFor(ThemeModeNotifier)
final themeModeNotifierProvider =
    AutoDisposeNotifierProvider<ThemeModeNotifier, ThemeMode>.internal(
  ThemeModeNotifier.new,
  name: r'themeModeNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$themeModeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ThemeModeNotifier = AutoDisposeNotifier<ThemeMode>;
String _$seedColorNotifierHash() => r'f145468f3a7619f4192eba3effd5766c5813d4dd';

/// Seed-Color Provider (Custom Akzentfarbe)
///
/// Copied from [SeedColorNotifier].
@ProviderFor(SeedColorNotifier)
final seedColorNotifierProvider =
    AutoDisposeNotifierProvider<SeedColorNotifier, Color>.internal(
  SeedColorNotifier.new,
  name: r'seedColorNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$seedColorNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SeedColorNotifier = AutoDisposeNotifier<Color>;
String _$useDynamicColorNotifierHash() =>
    r'4902517142e479c759aef5f3bc4d81f1ffcacba8';

/// Dynamic Color Provider (Material You An/Aus)
///
/// Copied from [UseDynamicColorNotifier].
@ProviderFor(UseDynamicColorNotifier)
final useDynamicColorNotifierProvider =
    AutoDisposeNotifierProvider<UseDynamicColorNotifier, bool>.internal(
  UseDynamicColorNotifier.new,
  name: r'useDynamicColorNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$useDynamicColorNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UseDynamicColorNotifier = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
