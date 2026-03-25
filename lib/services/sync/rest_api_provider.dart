import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/database.dart';
import 'sync_provider.dart';

/// REST API Sync-Provider für eigene Server
class RestApiSyncProvider implements SyncProvider {
  String? _serverUrl;
  String? _apiKey;
  bool _connected = false;
  DateTime? _lastSyncTime;

  static const String _prefsKeyServer = 'rest_api_server';
  static const String _prefsKeyApiKey = 'rest_api_key';
  static const String _prefsKeyLastSync = 'rest_api_last_sync';

  @override
  String get name => 'REST API Server';

  @override
  bool get isConnected => _connected;

  @override
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Konfiguration setzen
  void configure({
    required String serverUrl,
    required String apiKey,
  }) {
    _serverUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
    _apiKey = apiKey;
  }

  /// Auth Header erstellen
  Map<String, String> get _authHeaders {
    return {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Vollständige URL erstellen
  String _buildUrl(String endpoint) {
    return '$_serverUrl$endpoint';
  }

  @override
  Future<bool> connect() async {
    if (_serverUrl == null || _apiKey == null) {
      return false;
    }

    final success = await testConnection();
    if (success) {
      _connected = true;
      await _saveCredentials();
    }
    return success;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _serverUrl = null;
    _apiKey = null;
    _lastSyncTime = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyServer);
    await prefs.remove(_prefsKeyApiKey);
    await prefs.remove(_prefsKeyLastSync);
  }

  @override
  Future<bool> testConnection() async {
    if (_serverUrl == null || _apiKey == null) return false;

    try {
      final response = await http
          .get(
            Uri.parse(_buildUrl('/health')),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<SyncResult> sync() async {
    if (!_connected) {
      return SyncResult.error('Nicht verbunden');
    }

    int uploaded = 0;
    int downloaded = 0;
    final conflicts = <SyncConflict>[];

    try {
      // Delta-Sync Endpoint aufrufen
      final since = _lastSyncTime?.toIso8601String() ?? '';
      final response = await http.get(
        Uri.parse(_buildUrl('/sync?since=$since')),
        headers: _authHeaders,
      );

      if (response.statusCode != 200) {
        return SyncResult.error('Server-Fehler: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final remoteNotes = (data['notes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final deletedIds = (data['deleted'] as List?)?.cast<String>() ?? [];

      // Remote-Änderungen verarbeiten
      for (final noteData in remoteNotes) {
        // TODO: Konfliktprüfung mit lokalen Änderungen
        downloaded++;
      }

      // Löschungen verarbeiten
      for (final id in deletedIds) {
        // TODO: Lokal löschen
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
  Future<bool> uploadNote(Note note) async {
    if (!_connected) return false;

    try {
      final response = await http.put(
        Uri.parse(_buildUrl('/notes/${note.id}')),
        headers: _authHeaders,
        body: _noteToJson(note),
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
        Uri.parse(_buildUrl('/notes/$noteId')),
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
        Uri.parse(_buildUrl('/notes/$noteId')),
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

    try {
      final response = await http.get(
        Uri.parse(_buildUrl('/changes?since=${since.toIso8601String()}')),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) {
          final change = item as Map<String, dynamic>;
          return SyncChange(
            noteId: change['noteId'] as String,
            type: _parseChangeType(change['type'] as String),
            timestamp: DateTime.parse(change['timestamp'] as String),
            note: change['note'] != null
                ? _noteFromJson(change['note'] as Map<String, dynamic>)
                : null,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<String?> uploadMedia(String localPath, String mediaType) async {
    if (!_connected) return null;

    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_buildUrl('/media')),
      );
      request.headers.addAll(_authHeaders);
      request.files.add(await http.MultipartFile.fromPath('file', localPath));
      request.fields['type'] = mediaType;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['id'] as String?;
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
  Future<bool> resolveConflict(SyncConflict conflict, ConflictResolution resolution) async {
    switch (resolution) {
      case ConflictResolution.keepLocal:
        return await uploadNote(conflict.localNote);
      case ConflictResolution.keepRemote:
        return true; // Remote-Version beim nächsten Sync
      case ConflictResolution.keepBoth:
        // TODO: Kopie mit neuem Namen erstellen
        return false;
    }
  }

  /// Credentials speichern
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyServer, _serverUrl ?? '');
    await prefs.setString(_prefsKeyApiKey, _apiKey ?? '');
  }

  /// Credentials laden
  Future<bool> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString(_prefsKeyServer);
    _apiKey = prefs.getString(_prefsKeyApiKey);

    final lastSyncMs = prefs.getInt(_prefsKeyLastSync);
    if (lastSyncMs != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    }

    if (_serverUrl != null && _apiKey != null) {
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

  SyncChangeType _parseChangeType(String type) {
    switch (type) {
      case 'created':
        return SyncChangeType.created;
      case 'updated':
        return SyncChangeType.updated;
      case 'deleted':
        return SyncChangeType.deleted;
      default:
        return SyncChangeType.updated;
    }
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
}
