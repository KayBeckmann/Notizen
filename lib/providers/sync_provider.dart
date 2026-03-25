import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync/sync.dart';

/// Provider für den SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService();

  // Einstellungen beim Start laden
  service.loadSettings();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider für den Sync-Status
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.status;
});

/// Provider für die Verbindung
final syncConnectedProvider = Provider<bool>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.isConnected;
});

/// Provider für ausstehende Änderungen
final pendingChangesCountProvider = Provider<int>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.pendingChangesCount;
});

/// Provider für den letzten Sync-Zeitpunkt
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.lastSyncTime;
});
