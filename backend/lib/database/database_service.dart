import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

class DatabaseService {
  late final Database _db;

  DatabaseService(String dbPath) {
    _db = sqlite3.open(dbPath);
    _initialize();
  }

  void _initialize() {
    // Users Tabelle
    _db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        api_key TEXT UNIQUE NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Sync Items Tabelle (erweitert um user_id)
    _db.execute('''
      CREATE TABLE IF NOT EXISTS sync_items (
        id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted INTEGER DEFAULT 0,
        PRIMARY KEY (id, user_id),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Index für schnelleres Abrufen von Änderungen
    _db.execute('CREATE INDEX IF NOT EXISTS idx_updated_at_user ON sync_items(user_id, updated_at)');
  }

  /// Erstellt einen neuen Benutzer und gibt den API-Key zurück
  String createUser(String username) {
    final userId = DateTime.now().millisecondsSinceEpoch.toString(); // Einfache ID
    final apiKey = _generateApiKey();
    
    _db.execute(
      'INSERT INTO users (id, username, api_key, created_at) VALUES (?, ?, ?, ?)',
      [userId, username, apiKey, DateTime.now().millisecondsSinceEpoch],
    );
    
    return apiKey;
  }

  /// Validiert einen API-Key und gibt die User-ID zurück
  String? validateApiKey(String apiKey) {
    final result = _db.select('SELECT id FROM users WHERE api_key = ?', [apiKey]);
    if (result.isEmpty) return null;
    return result.first['id'] as String;
  }

  /// Holt alle Benutzernamen (für CLI)
  List<Map<String, dynamic>> getUsers() {
    final results = _db.select('SELECT username, api_key FROM users');
    return results.map((row) => {
      'username': row['username'],
      'api_key': row['api_key'],
    }).toList();
  }

  String _generateApiKey() {
    // Einfache API-Key Generierung
    final chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = DateTime.now().microsecondsSinceEpoch;
    return List.generate(32, (index) => chars[(rnd + index) % chars.length]).join();
  }

  /// Holt alle Änderungen seit einem bestimmten Zeitstempel für einen Benutzer
  List<Map<String, dynamic>> getChangesSince(String userId, int timestamp) {
    final ResultSet results = _db.select(
      'SELECT id, type, data, updated_at, deleted FROM sync_items WHERE user_id = ? AND updated_at > ?',
      [userId, timestamp],
    );

    return results.map((row) => {
      'id': row['id'],
      'type': row['type'],
      'data': row['data'],
      'updated_at': row['updated_at'],
      'deleted': row['deleted'] == 1,
    }).toList();
  }

  /// Speichert oder aktualisiert eine Liste von Sync-Items für einen Benutzer
  void upsertItems(String userId, List<Map<String, dynamic>> items) {
    final stmt = _db.prepare(
      'INSERT OR REPLACE INTO sync_items (id, user_id, type, data, updated_at, deleted) VALUES (?, ?, ?, ?, ?, ?)'
    );

    try {
      _db.execute('BEGIN TRANSACTION');
      for (final item in items) {
        stmt.execute([
          item['id'],
          userId,
          item['type'],
          item['data'],
          item['updated_at'],
          (item['deleted'] ?? false) ? 1 : 0,
        ]);
      }
      _db.execute('COMMIT');
    } catch (e) {
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      stmt.dispose();
    }
  }

  /// Holt ein einzelnes Item nach ID für einen Benutzer
  Map<String, dynamic>? getItemById(String userId, String id) {
    final results = _db.select('SELECT id, type, data, updated_at, deleted FROM sync_items WHERE user_id = ? AND id = ?', [userId, id]);
    if (results.isEmpty) return null;
    
    final row = results.first;
    return {
      'id': row['id'],
      'type': row['type'],
      'data': row['data'],
      'updated_at': row['updated_at'],
      'deleted': row['deleted'] == 1,
    };
  }

  /// Markiert ein Item als gelöscht (Tombstone) für einen Benutzer
  void markDeleted(String userId, String id) {
    _db.execute(
      'UPDATE sync_items SET deleted = 1, updated_at = ? WHERE user_id = ? AND id = ?',
      [DateTime.now().millisecondsSinceEpoch, userId, id],
    );
  }

  void close() {
    _db.dispose();
  }
}
