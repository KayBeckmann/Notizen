import 'package:drift/drift.dart';

import 'connection/connection.dart' as connection;
import 'daos/sync_dao.dart';
import 'tables/folders.dart';
import 'tables/note_tags.dart';
import 'tables/notes.dart';
import 'tables/sync_queue.dart';
import 'tables/tags.dart';
import 'tables/templates.dart';

part 'database.g.dart';

/// Hauptdatenbank der Notizen-App
@DriftDatabase(
  tables: [Folders, Notes, Tags, NoteTags, SyncQueue, SyncConflicts, Templates],
  daos: [SyncDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(connection.openConnection());

  /// Für Tests mit einer In-Memory-Datenbank
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Standard-Ordner erstellen
        await _createDefaultFolder();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Migration zu Version 2: Sync-Unterstützung
          await m.addColumn(notes, notes.syncedAt);
          await m.addColumn(notes, notes.syncStatus);
          await m.addColumn(notes, notes.remoteId);
          await m.createTable(syncQueue);
          await m.createTable(syncConflicts);
        }
        if (from < 3) {
          // Migration zu Version 3: Vorlagen
          await m.createTable(templates);
        }
        
        // Immer sicherstellen, dass der Standard-Ordner existiert
        await _ensureDefaultFolder();
      },
      beforeOpen: (details) async {
        // Foreign Keys aktivieren
        await customStatement('PRAGMA foreign_keys = ON');
        
        // Erneut sicherstellen, dass der Standard-Ordner existiert (für Robustheit)
        await _ensureDefaultFolder();
      },
    );
  }

  /// Stellt sicher, dass der Standard-Ordner existiert
  Future<void> _ensureDefaultFolder() async {
    final defaultFolder = await (select(folders)..where((t) => t.id.equals('default'))).getSingleOrNull();
    if (defaultFolder == null) {
      await _createDefaultFolder();
    }
  }

  /// Erstellt den Standard-Ordner "Notizen"
  Future<void> _createDefaultFolder() async {
    final now = DateTime.now();
    await into(folders).insert(
      FoldersCompanion.insert(
        id: 'default',
        name: 'Notizen',
        color: 0xFF6750A4,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
