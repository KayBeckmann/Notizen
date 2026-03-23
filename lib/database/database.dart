import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/folders.dart';
import 'tables/note_tags.dart';
import 'tables/notes.dart';
import 'tables/tags.dart';

part 'database.g.dart';

/// Hauptdatenbank der Notizen-App
@DriftDatabase(tables: [Folders, Notes, Tags, NoteTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

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

/// Öffnet die Datenbankverbindung
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'notizen.db'));
    return NativeDatabase.createInBackground(file);
  });
}
