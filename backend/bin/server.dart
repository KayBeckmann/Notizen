import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Router-Konfiguration
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/health', _healthHandler)
  ..mount('/api/v1/', _apiProvider());

Response _rootHandler(Request req) {
  return Response.ok('Notizen Sync Backend läuft.\n');
}

Response _healthHandler(Request req) {
  return Response.ok('{"status": "ok"}', headers: {'content-type': 'application/json'});
}

Router _apiProvider() {
  final router = Router();
  
  // TODO: Auth & Sync Endpunkte implementieren
  router.get('sync', (Request req) {
    return Response.ok('{"message": "Sync API bereit"}', headers: {'content-type': 'application/json'});
  });

  return router;
}

void main(List<String> args) async {
  // Port aus Umgebungsvariable oder Standard 8080
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  
  // IP-Adresse binden (0.0.0.0 für Docker)
  final ip = InternetAddress.anyIPv4;

  // Pipeline konfigurieren
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(_router.call);

  // Server starten
  final server = await serve(handler, ip, port);
  print('Server gestartet auf port ${server.port}');
}
