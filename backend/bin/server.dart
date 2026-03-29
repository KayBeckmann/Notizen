import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import '../lib/database/database_service.dart';
import '../lib/api/auth_handler.dart';
import '../lib/api/sync_handler.dart';

void main(List<String> args) async {
  // Pfad zur Datenbank aus Umgebungsvariable oder Standard
  final dbPath = Platform.environment['DB_PATH'] ?? 'data/sync.db';
  
  // Sicherstellen, dass das Verzeichnis existiert
  final dbDir = Directory(dbPath).parent;
  if (!dbDir.existsSync()) {
    dbDir.createSync(recursive: true);
  }
  
  final db = DatabaseService(dbPath);

  // CLI Befehle verarbeiten
  if (args.isNotEmpty) {
    if (args[0] == 'adduser' && args.length > 1) {
      final username = args[1];
      try {
        final apiKey = db.createUser(username);
        print('Benutzer $username erfolgreich erstellt.');
        print('API-Key: $apiKey');
        print('WICHTIG: Speichere diesen Key gut auf, er wird nur einmal angezeigt!');
      } catch (e) {
        print('Fehler beim Erstellen des Benutzers: $e');
      }
      return;
    } else if (args[0] == 'listusers') {
      final users = db.getUsers();
      print('Registrierte Benutzer:');
      for (final user in users) {
        print('- ${user['username']} (Key: ${user['api_key']})');
      }
      return;
    }
  }

  // Nur starten wenn kein CLI Befehl verarbeitet wurde
  await _startServer(db);
}

Future<void> _startServer(DatabaseService db) async {
  final authHandler = AuthHandler(db);
  final syncHandler = SyncHandler(db);

  // Router-Konfiguration
  final router = Router()
    ..get('/', (Request req) => Response.ok('Notizen Sync Backend läuft.\n'))
    ..get('/health', (Request req) => Response.ok('{"status": "ok"}', headers: {'content-type': 'application/json'}))
    ..mount('/api/v1/auth/', authHandler.router.call)
    ..mount('/api/v1/sync/', syncHandler.router.call);

  // Port aus Umgebungsvariable oder Standard 8080
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  
  // IP-Adresse binden (0.0.0.0 für Docker)
  final ip = InternetAddress.anyIPv4;

  // Pipeline konfigurieren
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  // Server starten
  final server = await serve(handler, ip, port);
  print('Server gestartet auf port ${server.port}');
  print('Benutze "dart bin/server.dart adduser <name>" um einen neuen User anzulegen.');
}
