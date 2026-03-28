import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';

/// Provider für den StorageService (Singleton)
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

/// Provider für die Speicherstatistiken
final storageStatsProvider = FutureProvider<StorageStats>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getStorageStats();
});
