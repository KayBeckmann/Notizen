import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/database.dart';
import 'sync_provider.dart';

/// Log-Eintrag für Sync-Ereignisse
class SyncLogEntry {
  final DateTime timestamp;
  final SyncLogLevel level;
  final String message;
  final String? details;

  SyncLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.details,
  });
}

/// Log-Level für Sync-Ereignisse
enum SyncLogLevel { info, success, warning, error }

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

  // Sync-Log (max. 100 Einträge)
  final List<SyncLogEntry> _syncLog = [];
  static const int _maxLogEntries = 100;

  // Callbacks
  final List<VoidCallback> _onSyncStartCallbacks = [];
  final List<void Function(SyncResult)> _onSyncCompleteCallbacks = [];

  final AppDatabase db;

  SyncService(this.db);

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
  List<SyncLogEntry> get syncLog => List.unmodifiable(_syncLog);

  /// Log-Eintrag hinzufügen
  void _log(SyncLogLevel level, String message, [String? details]) {
    _syncLog.insert(0, SyncLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      details: details,
    ));
    // Log-Größe begrenzen
    while (_syncLog.length > _maxLogEntries) {
      _syncLog.removeLast();
    }
    notifyListeners();
  }

  /// Log leeren
  void clearLog() {
    _syncLog.clear();
    notifyListeners();
  }

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
    if (_provider == null) {
      _log(SyncLogLevel.error, 'Verbindung fehlgeschlagen', 'Kein Provider konfiguriert');
      return false;
    }

    _log(SyncLogLevel.info, 'Verbindung wird hergestellt...');
    _status = SyncStatus.syncing;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _provider!.connect();
      if (success) {
        _status = SyncStatus.idle;
        _startAutoSync();
        _log(SyncLogLevel.success, 'Verbindung hergestellt');
      } else {
        _status = SyncStatus.error;
        _errorMessage = 'Verbindung fehlgeschlagen';
        _log(SyncLogLevel.error, 'Verbindung fehlgeschlagen');
      }
      notifyListeners();
      return success;
    } catch (e) {
      _status = SyncStatus.error;
      _errorMessage = e.toString();
      _log(SyncLogLevel.error, 'Verbindung fehlgeschlagen', e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Verbindung trennen
  Future<void> disconnect() async {
    _log(SyncLogLevel.info, 'Verbindung wird getrennt...');
    _stopAutoSync();
    if (_provider != null) {
      await _provider!.disconnect();
    }
    _status = SyncStatus.idle;
    _log(SyncLogLevel.success, 'Verbindung getrennt');
    notifyListeners();
  }

  /// Synchronisation starten
  Future<SyncResult> sync() async {
    if (_provider == null) {
      _log(SyncLogLevel.error, 'Sync fehlgeschlagen', 'Kein Provider konfiguriert');
      return SyncResult.error('Kein Provider konfiguriert');
    }

    if (!_provider!.isConnected) {
      _log(SyncLogLevel.error, 'Sync fehlgeschlagen', 'Nicht verbunden');
      return SyncResult.error('Nicht verbunden');
    }

    if (_status == SyncStatus.syncing) {
      _log(SyncLogLevel.warning, 'Sync übersprungen', 'Synchronisation läuft bereits');
      return SyncResult.error('Synchronisation läuft bereits');
    }

    _log(SyncLogLevel.info, 'Synchronisation gestartet');
    _status = SyncStatus.syncing;
    _errorMessage = null;
    notifyListeners();
    _notifySyncStart();

    try {
      if (_provider != null && _provider!.supportsSyncAll) {
        // Optimierter Delta-Sync für das eigene Backend
        final localChanges = _pendingChanges.map((c) => {
          'id': c.id,
          'type': c.type,
          'action': c.action.name,
          'updated_at': c.timestamp.millisecondsSinceEpoch,
          'data': c.data != null ? jsonEncode(c.data) : null,
        }).toList();

        final response = await _provider!.syncAll(
          lastSyncTimestamp: _lastSyncTime?.millisecondsSinceEpoch ?? 0,
          localChanges: localChanges,
        );

        final serverChanges = response['changes'] as List;
        final newTimestamp = response['timestamp'] as int;

        // Remote-Änderungen lokal anwenden
        await _applyRemoteChanges(serverChanges);

        _pendingChanges.clear();
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(newTimestamp);
        _status = SyncStatus.success;
        _log(SyncLogLevel.success, 'Synchronisation erfolgreich', 
            '${localChanges.length} hochgeladen, ${serverChanges.length} heruntergeladen');
      } else {
        // Klassischer Sync für andere Provider (WebDAV etc.)
        if (_pendingChanges.isNotEmpty) {
          _log(SyncLogLevel.info, 'Lade ${_pendingChanges.length} lokale Änderungen hoch...');
        }
        await _uploadPendingChanges();

        _log(SyncLogLevel.info, 'Hole Remote-Änderungen...');
        final result = await _provider!.sync();
        _status = result.status;
        if (result.status == SyncStatus.success) {
          _lastSyncTime = result.timestamp;
        }
      }

      await _saveLastSyncTime();
      notifyListeners();
      _notifySyncComplete(SyncResult.success());
      return SyncResult.success();
    } catch (e) {
      _status = SyncStatus.error;
      _errorMessage = e.toString();
      _log(SyncLogLevel.error, 'Synchronisation fehlgeschlagen', e.toString());
      notifyListeners();

      final result = SyncResult.error(e.toString());
      _notifySyncComplete(result);
      return result;
    }
  }

  /// Remote-Änderungen lokal anwenden
  Future<void> _applyRemoteChanges(List<dynamic> changes) async {
    for (final change in changes) {
      final map = change as Map<String, dynamic>;
      final id = map['id'] as String;
      final type = map['type'] as String;
      final isDeleted = map['deleted'] as bool;
      final dataStr = map['data'] as String;
      final data = jsonDecode(dataStr) as Map<String, dynamic>;

      if (isDeleted) {
        // Lokal löschen
        if (type == 'note') {
          await (db.delete(db.notes)..where((t) => t.id.equals(id))).go();
        } else if (type == 'folder') {
          await (db.delete(db.folders)..where((t) => t.id.equals(id))).go();
        } else if (type == 'tag') {
          await (db.delete(db.tags)..where((t) => t.id.equals(id))).go();
        }
        continue;
      }

      // Upsert (Insert or Replace)
      if (type == 'note') {
        await db.into(db.notes).insertOnConflictUpdate(Note.fromJson(data));
      } else if (type == 'folder') {
        await db.into(db.folders).insertOnConflictUpdate(Folder.fromJson(data));
      } else if (type == 'tag') {
        await db.into(db.tags).insertOnConflictUpdate(Tag.fromJson(data));
      }
    }
  }

  /// Notiz zur Sync-Queue hinzufügen
  void queueNoteChange(Note note, SyncChangeType action) {
    _pendingChanges.add(SyncChange(
      id: note.id,
      type: 'note',
      action: action,
      timestamp: DateTime.now(),
      data: note.toJson(),
    ));
    notifyListeners();
  }

  /// Notiz-Löschung zur Sync-Queue hinzufügen
  void queueNoteDeletion(String noteId) {
    _pendingChanges.add(SyncChange(
      id: noteId,
      type: 'note',
      action: SyncChangeType.deleted,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Löschung zur Sync-Queue hinzufügen
  void queueDeletion(String id, String type) {
    _pendingChanges.add(SyncChange(
      id: id,
      type: type,
      action: SyncChangeType.deleted,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Ordner zur Sync-Queue hinzufügen
  void queueFolderChange(Folder folder, SyncChangeType action) {
    _pendingChanges.add(SyncChange(
      id: folder.id,
      type: 'folder',
      action: action,
      timestamp: DateTime.now(),
      data: folder.toJson(),
    ));
    notifyListeners();
  }

  /// Tag zur Sync-Queue hinzufügen
  void queueTagChange(Tag tag, SyncChangeType action) {
    _pendingChanges.add(SyncChange(
      id: tag.id,
      type: 'tag',
      action: action,
      timestamp: DateTime.now(),
      data: tag.toJson(),
    ));
    notifyListeners();
  }

  /// Ausstehende Änderungen hochladen
  Future<void> _uploadPendingChanges() async {
    if (_provider == null || !_provider!.isConnected) return;

    while (_pendingChanges.isNotEmpty) {
      final change = _pendingChanges.first;

      bool success = false;
      
      // REST API Abwärtskompatibilität für Notizen
      if (change.type == 'note') {
        switch (change.action) {
          case SyncChangeType.created:
          case SyncChangeType.updated:
            if (change.data != null) {
              success = await _provider!.uploadNote(Note.fromJson(change.data!));
            }
            break;
          case SyncChangeType.deleted:
            success = await _provider!.deleteNote(change.id);
            break;
        }
      } else {
        // Andere Typen (Folder, Tag) werden über syncAll abgeglichen
        // Bis das voll integriert ist, markieren wir es als Erfolg
        success = true;
      }

      if (success) {
        _pendingChanges.removeFirst();
      } else {
        break;
      }
    }
    notifyListeners();
  }

  /// Konflikt auflösen
  Future<bool> resolveConflict(SyncConflictInfo conflict, ConflictResolution resolution) async {
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
