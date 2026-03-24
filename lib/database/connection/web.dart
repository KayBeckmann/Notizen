import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Öffnet die Datenbankverbindung für Web (IndexedDB)
QueryExecutor openConnection() {
  return WebDatabase('notizen_db');
}
