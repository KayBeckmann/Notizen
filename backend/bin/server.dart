import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import '../lib/database/database_service.dart';
import '../lib/api/sync_handler.dart';

void main(List<String> args) async {
  // Pfad zur Datenbank aus Umgebungsvariable oder Standard
  final dbPath = Platform.environment['DB_PATH'] ?? 'data/sync.db';
  final db = DatabaseService(dbPath);
  final syncHandler = SyncHandler(db);

  // Router-Konfiguration
  final router = Router()
    ..get('/', (Request req) => Response.ok('Notizen Sync Backend läuft.\n'))
    ..get('/health', (Request req) => Response.ok('{"status": "ok"}', headers: {'content-type': 'application/json'}))
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
}
