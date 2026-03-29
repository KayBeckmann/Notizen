import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database_service.dart';

class SyncHandler {
  final DatabaseService _db;

  SyncHandler(this._db);

  Router get router {
    final router = Router();
    router.post('/pull', _pullHandler);
    router.post('/push', _pushHandler);
    router.post('/sync', _syncHandler);
    return router;
  }

  /// Voller Sync: Push lokale Änderungen, Pull Remote Änderungen
  Future<Response> _syncHandler(Request req) async {
    try {
      final body = await req.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;
      
      final lastSyncTimestamp = data['last_sync_timestamp'] as int? ?? 0;
      final changes = (data['changes'] as List? ?? [])
          .map((i) => i as Map<String, dynamic>)
          .toList();

      // 1. Lokale Änderungen vom Client in Server-DB speichern
      if (changes.isNotEmpty) {
        _db.upsertItems(changes);
      }

      // 2. Änderungen vom Server seit lastSyncTimestamp abrufen
      final serverChanges = _db.getChangesSince(lastSyncTimestamp);
      
      // 3. Neue Synchronisationszeit ermitteln (jetzt)
      final now = DateTime.now().millisecondsSinceEpoch;

      return Response.ok(
        json.encode({
          'timestamp': now,
          'changes': serverChanges,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: json.encode({'error': e.toString()}));
    }
  }

  Future<Response> _pullHandler(Request req) async {
    final lastSync = int.tryParse(req.url.queryParameters['since'] ?? '0') ?? 0;
    final changes = _db.getChangesSince(lastSync);
    return Response.ok(json.encode(changes), headers: {'content-type': 'application/json'});
  }

  Future<Response> _pushHandler(Request req) async {
    final body = await req.readAsString();
    final items = (json.decode(body) as List).cast<Map<String, dynamic>>();
    _db.upsertItems(items);
    return Response.ok(json.encode({'status': 'ok'}));
  }
}
