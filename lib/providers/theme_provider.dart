import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) => state = mode;
}

@riverpod
class SeedColorNotifier extends _$SeedColorNotifier {
  @override
  Color build() => Colors.deepPurple;

  void setSeedColor(Color color) => state = color;
}
