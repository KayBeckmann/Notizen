import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Einstellungen und Storage initialisieren
  await SettingsService.instance.init();
  await StorageService.instance.init();

  runApp(
    const ProviderScope(
      child: NotizenApp(),
    ),
  );
}

/// Haupt-App Widget
class NotizenApp extends ConsumerWidget {
  const NotizenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    final seedColor = ref.watch(seedColorNotifierProvider);
    final useDynamicColor = ref.watch(useDynamicColorNotifierProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Notizen',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightTheme(
            dynamicColorScheme: lightDynamic,
            seedColor: seedColor,
            useDynamicColor: useDynamicColor,
          ),
          darkTheme: AppTheme.darkTheme(
            dynamicColorScheme: darkDynamic,
            seedColor: seedColor,
            useDynamicColor: useDynamicColor,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
