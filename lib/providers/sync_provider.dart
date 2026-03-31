import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_provider.dart';
import 'notes_provider.dart';
import 'folders_provider.dart';
import 'tags_provider.dart';
import '../services/connectivity_service.dart';
import '../services/sync/sync.dart';

/// Provider für den SyncService
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(ref.watch(databaseProvider));

  // Einstellungen beim Start laden
  service.loadSettings();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider der auf Datenbankänderungen lauscht und den Sync triggert
final syncTriggerProvider = Provider<void>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  
  // Lausche auf alle relevanten Datenquellen
  ref.listen(allNotesProvider, (previous, next) {
    if (previous != null && next is AsyncData) {
      syncService.triggerSync();
    }
  });

  ref.listen(allFoldersProvider, (previous, next) {
    if (previous != null && next is AsyncData) {
      syncService.triggerSync();
    }
  });

  ref.listen(allTagsProvider, (previous, next) {
    if (previous != null && next is AsyncData) {
      syncService.triggerSync();
    }
  });
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

/// Provider für den Connectivity-Service
final connectivityServiceProvider = ChangeNotifierProvider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Provider für den Online-Status
final isOnlineProvider = Provider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.isOnline;
});
