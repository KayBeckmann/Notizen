import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Öffnet die Datenbankverbindung für Web (sql.js + IndexedDB)
QueryExecutor openConnection() {
  return WebDatabase.withStorage(
    DriftWebStorage.indexedDb(
      'notizen_db',
      migrateFromLocalStorage: false,
    ),
  );
}
