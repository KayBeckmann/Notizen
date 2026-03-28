import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

/// Keys für SharedPreferences
class ThemePrefsKeys {
  static const String themeMode = 'theme_mode';
  static const String seedColor = 'seed_color';
  static const String useDynamicColor = 'use_dynamic_color';
}

/// Standard-Seed-Farbe (Material Design 3 Primary)
const Color defaultSeedColor = Color(0xFF6750A4);

/// Theme-Modus Provider (System/Light/Dark)
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.system;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(ThemePrefsKeys.themeMode) ?? 0;
    state = ThemeMode.values[modeIndex];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(ThemePrefsKeys.themeMode, mode.index);
  }
}

/// Seed-Color Provider (Custom Akzentfarbe)
@riverpod
class SeedColorNotifier extends _$SeedColorNotifier {
  @override
  Color build() {
    _loadFromPrefs();
    return defaultSeedColor;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(ThemePrefsKeys.seedColor);
    if (colorValue != null) {
      state = Color(colorValue);
    }
  }

  Future<void> setSeedColor(Color color) async {
    state = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(ThemePrefsKeys.seedColor, color.toARGB32());
  }

  void reset() {
    setSeedColor(defaultSeedColor);
  }
}

/// Dynamic Color Provider (Material You An/Aus)
@riverpod
class UseDynamicColorNotifier extends _$UseDynamicColorNotifier {
  @override
  bool build() {
    _loadFromPrefs();
    return true;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final useDynamic = prefs.getBool(ThemePrefsKeys.useDynamicColor) ?? true;
    state = useDynamic;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ThemePrefsKeys.useDynamicColor, state);
  }

  Future<void> setUseDynamicColor(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ThemePrefsKeys.useDynamicColor, value);
  }
}
