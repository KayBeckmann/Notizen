import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/database.dart';
import 'sync_provider.dart';

/// WebDAV/Nextcloud Sync-Provider
class WebDAVSyncProvider implements SyncProvider {
  String? _serverUrl;
  String? _username;
  String? _password;
  String? _basePath;
  bool _connected = false;
  DateTime? _lastSyncTime;

  static const String _prefsKeyServer = 'webdav_server';
  static const String _prefsKeyUsername = 'webdav_username';
  static const String _prefsKeyPassword = 'webdav_password';
  static const String _prefsKeyBasePath = 'webdav_base_path';
  static const String _prefsKeyLastSync = 'webdav_last_sync';

  @override
  String get name => 'Nextcloud / WebDAV';

  @override
  bool get isConnected => _connected;

  @override
  DateTime? get lastSyncTime => _lastSyncTime;

  @override
  bool get supportsSyncAll => false;

  /// Konfiguration setzen
  void configure({
    required String serverUrl,
    required String username,
    required String password,
    String basePath = '/notizen',
  }) {
    _serverUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
    _username = username;
    _password = password;
    _basePath = basePath;
  }

  /// Basis-Auth Header erstellen
  Map<String, String> get _authHeaders {
    final credentials = base64Encode(utf8.encode('$_username:$_password'));
    return {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/json',
    };
  }

  /// Vollständige URL für einen Pfad erstellen
  String _buildUrl(String path) {
    return '$_serverUrl$_basePath$path';
  }

  @override
  Future<bool> connect() async {
    if (_serverUrl == null || _username == null || _password == null) {
      return false;
    }

    // Verbindung testen
    final success = await testConnection();
    if (success) {
      _connected = true;
      await _saveCredentials();
      await _ensureBasePath();
    }
    return success;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _serverUrl = null;
    _username = null;
    _password = null;
    _lastSyncTime = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyServer);
    await prefs.remove(_prefsKeyUsername);
    await prefs.remove(_prefsKeyPassword);
    await prefs.remove(_prefsKeyBasePath);
    await prefs.remove(_prefsKeyLastSync);
  }

  @override
  Future<bool> testConnection() async {
    if (_serverUrl == null || _username == null) return false;

    try {
      final response = await http
          .head(
            Uri.parse(_serverUrl!),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 207;
    } catch (e) {
      return false;
    }
  }

  /// Sicherstellen, dass der Basis-Pfad existiert
  Future<void> _ensureBasePath() async {
    try {
      // MKCOL request to create directory
      final response = await http.Request('MKCOL', Uri.parse(_buildUrl('')))
        ..headers.addAll(_authHeaders);

      final streamedResponse = await response.send();
      // 201 = created, 405 = already exists
      if (streamedResponse.statusCode != 201 && streamedResponse.statusCode != 405) {
        // Ordner existiert möglicherweise bereits
      }
    } catch (e) {
      // Ignorieren wenn Ordner bereits existiert
    }
  }

  @override
  Future<SyncResult> sync() async {
    if (!_connected) {
      return SyncResult.error('Nicht verbunden');
    }

    int uploaded = 0;
    int downloaded = 0;
    final conflicts = <SyncConflictInfo>[];

    try {
      // 1. Remote-Änderungen abrufen
      final remoteChanges = await getRemoteChanges(_lastSyncTime ?? DateTime(2000));

      // 2. Konflikte prüfen und lösen
      // TODO: Implementierung der Konfliktprüfung

      // 3. Remote-Änderungen herunterladen
      for (final change in remoteChanges) {
        if (change.action == SyncChangeType.deleted) {
          // TODO: Lokal löschen
        } else if (change.type == 'note') {
          final note = await downloadNote(change.id);
          if (note != null) {
            downloaded++;
          }
        }
      }

      _lastSyncTime = DateTime.now();
      await _saveLastSyncTime();

      if (conflicts.isNotEmpty) {
        return SyncResult.conflict(conflicts);
      }

      return SyncResult.success(
        uploadedCount: uploaded,
        downloadedCount: downloaded,
      );
    } catch (e) {
      return SyncResult.error(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> syncAll({
    required int lastSyncTimestamp,
    required List<Map<String, dynamic>> localChanges,
  }) {
    throw UnimplementedError('syncAll ist für WebDAV aktuell nicht implementiert');
  }

  @override
  Future<bool> uploadNote(Note note) async {
    if (!_connected) return false;

    try {
      final json = _noteToJson(note);
      final response = await http.put(
        Uri.parse(_buildUrl('/notes/${note.id}.json')),
        headers: _authHeaders,
        body: json,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Note?> downloadNote(String noteId) async {
    if (!_connected) return null;

    try {
      final response = await http.get(
        Uri.parse(_buildUrl('/notes/$noteId.json')),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _noteFromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> deleteNote(String noteId) async {
    if (!_connected) return false;

    try {
      final response = await http.delete(
        Uri.parse(_buildUrl('/notes/$noteId.json')),
        headers: _authHeaders,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<SyncChange>> getRemoteChanges(DateTime since) async {
    if (!_connected) return [];

    final changes = <SyncChange>[];

    try {
      // PROPFIND request to list files
      final request = http.Request('PROPFIND', Uri.parse(_buildUrl('/notes/')))
        ..headers.addAll(_authHeaders)
        ..headers['Depth'] = '1';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 207) {
        // Parse WebDAV XML response
        // TODO: Vollständige XML-Parsing Implementierung
        // Für jetzt: Leere Liste zurückgeben
      }
    } catch (e) {
      // Fehler ignorieren
    }

    return changes;
  }

  @override
  Future<String?> uploadMedia(String localPath, String mediaType) async {
    if (!_connected) return null;

    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final fileName = localPath.split('/').last;
      final bytes = await file.readAsBytes();

      final response = await http.put(
        Uri.parse(_buildUrl('/media/$fileName')),
        headers: {
          ..._authHeaders,
          'Content-Type': _getMediaContentType(mediaType),
        },
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return fileName;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> downloadMedia(String remoteId, String localPath) async {
    if (!_connected) return null;

    try {
      final response = await http.get(
        Uri.parse(_buildUrl('/media/$remoteId')),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        return localPath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> resolveConflict(SyncConflictInfo conflict, ConflictResolution resolution) async {
    switch (resolution) {
      case ConflictResolution.keepLocal:
        return await uploadNote(conflict.localNote);
      case ConflictResolution.keepRemote:
        // Remote-Version wird beim nächsten Sync heruntergeladen
        return true;
      case ConflictResolution.keepBoth:
        // Lokale Version mit neuem Namen speichern
        // TODO: Implementierung
        return false;
    }
  }

  /// Credentials speichern
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyServer, _serverUrl ?? '');
    await prefs.setString(_prefsKeyUsername, _username ?? '');
    await prefs.setString(_prefsKeyPassword, _password ?? '');
    await prefs.setString(_prefsKeyBasePath, _basePath ?? '/notizen');
  }

  /// Credentials laden
  Future<bool> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString(_prefsKeyServer);
    _username = prefs.getString(_prefsKeyUsername);
    _password = prefs.getString(_prefsKeyPassword);
    _basePath = prefs.getString(_prefsKeyBasePath) ?? '/notizen';

    final lastSyncMs = prefs.getInt(_prefsKeyLastSync);
    if (lastSyncMs != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    }

    if (_serverUrl != null && _username != null && _password != null) {
      _connected = await testConnection();
      return _connected;
    }
    return false;
  }

  /// Letzten Sync-Zeitpunkt speichern
  Future<void> _saveLastSyncTime() async {
    if (_lastSyncTime == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyLastSync, _lastSyncTime!.millisecondsSinceEpoch);
  }

  /// Notiz zu JSON konvertieren
  String _noteToJson(Note note) {
    return jsonEncode({
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'contentType': note.contentType,
      'folderId': note.folderId,
      'isPinned': note.isPinned,
      'isArchived': note.isArchived,
      'isTrashed': note.isTrashed,
      'trashedAt': note.trashedAt?.toIso8601String(),
      'mediaPath': note.mediaPath,
      'drawingData': note.drawingData,
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt.toIso8601String(),
    });
  }

  /// Notiz aus JSON erstellen
  Note _noteFromJson(Map<String, dynamic> data) {
    return Note(
      id: data['id'] as String,
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      contentType: data['contentType'] as String? ?? 'text',
      folderId: data['folderId'] as String,
      isPinned: data['isPinned'] as bool? ?? false,
      isArchived: data['isArchived'] as bool? ?? false,
      isTrashed: data['isTrashed'] as bool? ?? false,
      trashedAt: data['trashedAt'] != null ? DateTime.parse(data['trashedAt'] as String) : null,
      mediaPath: data['mediaPath'] as String?,
      drawingData: data['drawingData'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      syncedAt: null,
      syncStatus: 'synced',
      remoteId: data['id'] as String,
    );
  }

  /// Content-Type für Medientyp ermitteln
  String _getMediaContentType(String mediaType) {
    switch (mediaType) {
      case 'audio':
        return 'audio/mpeg';
      case 'image':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
