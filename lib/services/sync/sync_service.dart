import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/database.dart';
import 'sync_provider.dart';

/// Service für die Verwaltung der Synchronisation
class SyncService extends ChangeNotifier {
  SyncProvider? _provider;
  SyncStatus _status = SyncStatus.idle;
  String? _errorMessage;
  DateTime? _lastSyncTime;
  bool _autoSyncEnabled = true;
  int _autoSyncIntervalMinutes = 15;
  bool _syncOnlyOnWifi = true;
  Timer? _autoSyncTimer;

  // Queue für Offline-Änderungen
  final Queue<SyncChange> _pendingChanges = Queue();

  // Callbacks
  final List<VoidCallback> _onSyncStartCallbacks = [];
  final List<void Function(SyncResult)> _onSyncCompleteCallbacks = [];

  SyncService();

  // Getters
  SyncProvider? get provider => _provider;
  SyncStatus get status => _status;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isConnected => _provider?.isConnected ?? false;
  bool get autoSyncEnabled => _autoSyncEnabled;
  int get autoSyncIntervalMinutes => _autoSyncIntervalMinutes;
  bool get syncOnlyOnWifi => _syncOnlyOnWifi;
  int get pendingChangesCount => _pendingChanges.length;
  bool get hasPendingChanges => _pendingChanges.isNotEmpty;

  /// Provider setzen
  Future<void> setProvider(SyncProvider? provider) async {
    if (_provider != null) {
      await _provider!.disconnect();
    }
    _provider = provider;
    notifyListeners();
  }

  /// Mit Provider verbinden
  Future<bool> connect() async {
    if (_provider == null) return false;

    _status = SyncStatus.syncing;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _provider!.connect();
      if (success) {
        _status = SyncStatus.idle;
        _startAutoSync();
      } else {
        _status = SyncStatus.error;
        _errorMessage = 'Verbindung fehlgeschlagen';
      }
      notifyListeners();
      return success;
    } catch (e) {
      _status = SyncStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Verbindung trennen
  Future<void> disconnect() async {
    _stopAutoSync();
    if (_provider != null) {
      await _provider!.disconnect();
    }
    _status = SyncStatus.idle;
    notifyListeners();
  }

  /// Synchronisation starten
  Future<SyncResult> sync() async {
    if (_provider == null) {
      return SyncResult.error('Kein Provider konfiguriert');
    }

    if (!_provider!.isConnected) {
      return SyncResult.error('Nicht verbunden');
    }

    if (_status == SyncStatus.syncing) {
      return SyncResult.error('Synchronisation läuft bereits');
    }

    _status = SyncStatus.syncing;
    _errorMessage = null;
    notifyListeners();
    _notifySyncStart();

    try {
      // Zuerst ausstehende lokale Änderungen hochladen
      await _uploadPendingChanges();

      // Dann vollständige Synchronisation durchführen
      final result = await _provider!.sync();

      _status = result.status;
      if (result.status == SyncStatus.success) {
        _lastSyncTime = result.timestamp;
        await _saveLastSyncTime();
      } else if (result.status == SyncStatus.error) {
        _errorMessage = result.errorMessage;
      }

      notifyListeners();
      _notifySyncComplete(result);
      return result;
    } catch (e) {
      _status = SyncStatus.error;
      _errorMessage = e.toString();
      notifyListeners();

      final result = SyncResult.error(e.toString());
      _notifySyncComplete(result);
      return result;
    }
  }

  /// Notiz zur Sync-Queue hinzufügen
  void queueNoteChange(Note note, SyncChangeType type) {
    _pendingChanges.add(SyncChange(
      noteId: note.id,
      type: type,
      timestamp: DateTime.now(),
      note: note,
    ));
    notifyListeners();
  }

  /// Notiz-Löschung zur Sync-Queue hinzufügen
  void queueNoteDeletion(String noteId) {
    _pendingChanges.add(SyncChange(
      noteId: noteId,
      type: SyncChangeType.deleted,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Ausstehende Änderungen hochladen
  Future<void> _uploadPendingChanges() async {
    if (_provider == null || !_provider!.isConnected) return;

    while (_pendingChanges.isNotEmpty) {
      final change = _pendingChanges.first;

      bool success = false;
      switch (change.type) {
        case SyncChangeType.created:
        case SyncChangeType.updated:
          if (change.note != null) {
            success = await _provider!.uploadNote(change.note!);
          }
          break;
        case SyncChangeType.deleted:
          success = await _provider!.deleteNote(change.noteId);
          break;
      }

      if (success) {
        _pendingChanges.removeFirst();
      } else {
        // Bei Fehler Queue nicht weiter abarbeiten
        break;
      }
    }
    notifyListeners();
  }

  /// Konflikt auflösen
  Future<bool> resolveConflict(SyncConflict conflict, ConflictResolution resolution) async {
    if (_provider == null) return false;
    return await _provider!.resolveConflict(conflict, resolution);
  }

  /// Auto-Sync Einstellungen setzen
  Future<void> setAutoSyncEnabled(bool enabled) async {
    _autoSyncEnabled = enabled;
    if (enabled) {
      _startAutoSync();
    } else {
      _stopAutoSync();
    }
    await _saveSettings();
    notifyListeners();
  }

  /// Auto-Sync Intervall setzen (in Minuten)
  Future<void> setAutoSyncInterval(int minutes) async {
    _autoSyncIntervalMinutes = minutes;
    if (_autoSyncEnabled) {
      _stopAutoSync();
      _startAutoSync();
    }
    await _saveSettings();
    notifyListeners();
  }

  /// Nur über WLAN synchronisieren
  Future<void> setSyncOnlyOnWifi(bool value) async {
    _syncOnlyOnWifi = value;
    await _saveSettings();
    notifyListeners();
  }

  /// Einstellungen laden
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoSyncEnabled = prefs.getBool('sync_auto_enabled') ?? true;
    _autoSyncIntervalMinutes = prefs.getInt('sync_interval_minutes') ?? 15;
    _syncOnlyOnWifi = prefs.getBool('sync_only_wifi') ?? true;

    final lastSyncMs = prefs.getInt('sync_last_time');
    if (lastSyncMs != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    }

    notifyListeners();
  }

  /// Einstellungen speichern
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sync_auto_enabled', _autoSyncEnabled);
    await prefs.setInt('sync_interval_minutes', _autoSyncIntervalMinutes);
    await prefs.setBool('sync_only_wifi', _syncOnlyOnWifi);
  }

  /// Letzten Sync-Zeitpunkt speichern
  Future<void> _saveLastSyncTime() async {
    if (_lastSyncTime == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sync_last_time', _lastSyncTime!.millisecondsSinceEpoch);
  }

  /// Auto-Sync Timer starten
  void _startAutoSync() {
    _stopAutoSync();
    if (!_autoSyncEnabled || _provider == null || !_provider!.isConnected) {
      return;
    }

    _autoSyncTimer = Timer.periodic(
      Duration(minutes: _autoSyncIntervalMinutes),
      (_) => _performAutoSync(),
    );
  }

  /// Auto-Sync Timer stoppen
  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Auto-Sync durchführen
  Future<void> _performAutoSync() async {
    if (_status == SyncStatus.syncing) return;

    // TODO: WLAN-Check implementieren wenn syncOnlyOnWifi aktiviert

    await sync();
  }

  /// Callback für Sync-Start registrieren
  void addOnSyncStartListener(VoidCallback callback) {
    _onSyncStartCallbacks.add(callback);
  }

  /// Callback für Sync-Start entfernen
  void removeOnSyncStartListener(VoidCallback callback) {
    _onSyncStartCallbacks.remove(callback);
  }

  /// Callback für Sync-Complete registrieren
  void addOnSyncCompleteListener(void Function(SyncResult) callback) {
    _onSyncCompleteCallbacks.add(callback);
  }

  /// Callback für Sync-Complete entfernen
  void removeOnSyncCompleteListener(void Function(SyncResult) callback) {
    _onSyncCompleteCallbacks.remove(callback);
  }

  void _notifySyncStart() {
    for (final callback in _onSyncStartCallbacks) {
      callback();
    }
  }

  void _notifySyncComplete(SyncResult result) {
    for (final callback in _onSyncCompleteCallbacks) {
      callback(result);
    }
  }

  @override
  void dispose() {
    _stopAutoSync();
    super.dispose();
  }
}
