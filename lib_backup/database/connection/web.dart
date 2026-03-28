import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Öffnet die Datenbankverbindung für Web (sql.js)
/// Die Daten werden in IndexedDB persistiert
QueryExecutor openConnection() {
  return WebDatabase('notizen_db');
}
