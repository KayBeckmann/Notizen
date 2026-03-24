import 'package:drift/drift.dart';

import 'connection/connection.dart' as connection;
import 'tables/folders.dart';
import 'tables/note_tags.dart';
import 'tables/notes.dart';
import 'tables/tags.dart';

part 'database.g.dart';

/// Hauptdatenbank der Notizen-App
@DriftDatabase(tables: [Folders, Notes, Tags, NoteTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(connection.openConnection());

  /// Für Tests mit einer In-Memory-Datenbank
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Standard-Ordner erstellen
        await _createDefaultFolder();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Zukünftige Migrationen hier
      },
      beforeOpen: (details) async {
        // Foreign Keys aktivieren
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
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
