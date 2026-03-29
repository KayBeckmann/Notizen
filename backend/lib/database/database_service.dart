import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

class DatabaseService {
  late final Database _db;

  DatabaseService(String dbPath) {
    _db = sqlite3.open(dbPath);
    _initialize();
  }

  void _initialize() {
    // Sync Items Tabelle
    // - id: UUID der Notiz/Ordner/Tag
    // - type: 'note', 'folder', 'tag'
    // - data: JSON-Blob der Daten
    // - updated_at: Zeitstempel der letzten Änderung (für Delta-Sync)
    // - deleted: Flag für gelöschte Einträge (Tombstones)
    _db.execute('''
      CREATE TABLE IF NOT EXISTS sync_items (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted INTEGER DEFAULT 0
      )
    ''');

    // Index für schnelleres Abrufen von Änderungen
    _db.execute('CREATE INDEX IF NOT EXISTS idx_updated_at ON sync_items(updated_at)');
  }

  /// Holt alle Änderungen seit einem bestimmten Zeitstempel
  List<Map<String, dynamic>> getChangesSince(int timestamp) {
    final ResultSet results = _db.select(
      'SELECT id, type, data, updated_at, deleted FROM sync_items WHERE updated_at > ?',
      [timestamp],
    );

    return results.map((row) => {
      'id': row['id'],
      'type': row['type'],
      'data': row['data'],
      'updated_at': row['updated_at'],
      'deleted': row['deleted'] == 1,
    }).toList();
  }

  /// Speichert oder aktualisiert eine Liste von Sync-Items
  void upsertItems(List<Map<String, dynamic>> items) {
    final stmt = _db.prepare(
      'INSERT OR REPLACE INTO sync_items (id, type, data, updated_at, deleted) VALUES (?, ?, ?, ?, ?)'
    );

    try {
      _db.execute('BEGIN TRANSACTION');
      for (final item in items) {
        stmt.execute([
          item['id'],
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

  /// Holt ein einzelnes Item nach ID
  Map<String, dynamic>? getItemById(String id) {
    final results = _db.select('SELECT id, type, data, updated_at, deleted FROM sync_items WHERE id = ?', [id]);
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

  /// Markiert ein Item als gelöscht (Tombstone)
  void markDeleted(String id) {
    _db.execute(
      'UPDATE sync_items SET deleted = 1, updated_at = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch, id],
    );
  }

  void close() {
    _db.dispose();
  }
}
