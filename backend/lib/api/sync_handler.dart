import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database_service.dart';

class SyncHandler {
  final DatabaseService _db;

  SyncHandler(this._db);

  Router get router {
    final router = Router();
    
    // Middleware für alle Routen in diesem Handler
    final pipeline = const Pipeline()
        .addMiddleware(_authMiddleware())
        .addHandler(_router.call);
        
    router.all('/<ignored|.*>', pipeline);
    
    return router;
  }

  Router get _router {
    final router = Router();
    router.post('/pull', _pullHandler);
    router.post('/push', _pushHandler);
    router.post('/sync', _syncHandler);
    
    // REST Endpunkte für Notizen (Kompatibilität)
    router.get('/notes', _getNotesHandler);
    router.get('/notes/<id>', _getNoteHandler);
    router.post('/notes', _upsertNoteHandler);
    router.delete('/notes/<id>', _deleteNoteHandler);
    
    return router;
  }

  /// Middleware zur Validierung des API-Keys
  Middleware _authMiddleware() {
    return (Handler innerHandler) {
      return (Request req) async {
        final authHeader = req.headers['Authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return Response.forbidden(json.encode({'error': 'Fehlender oder ungültiger Authorization Header'}));
        }

        final apiKey = authHeader.substring(7);
        final userId = _db.validateApiKey(apiKey);
        
        if (userId == null) {
          return Response.forbidden(json.encode({'error': 'Ungültiger API-Key'}));
        }

        // User-ID im Kontext speichern
        return innerHandler(req.change(context: {'userId': userId}));
      };
    };
  }

  String _getUserId(Request req) => req.context['userId'] as String;

  Future<Response> _getNotesHandler(Request req) async {
    final userId = _getUserId(req);
    final lastSync = int.tryParse(req.url.queryParameters['since'] ?? '0') ?? 0;
    final changes = _db.getChangesSince(userId, lastSync);
    // Nur Notizen filtern
    final notes = changes.where((c) => c['type'] == 'note').toList();
    return Response.ok(json.encode(notes), headers: {'content-type': 'application/json'});
  }

  Future<Response> _getNoteHandler(Request req, String id) async {
    final userId = _getUserId(req);
    final item = _db.getItemById(userId, id);
    if (item == null) return Response.notFound('Notiz nicht gefunden');
    return Response.ok(json.encode(item), headers: {'content-type': 'application/json'});
  }

  Future<Response> _upsertNoteHandler(Request req) async {
    final userId = _getUserId(req);
    final body = await req.readAsString();
    final data = json.decode(body) as Map<String, dynamic>;
    
    // In das generische Format umwandeln
    final item = {
      'id': data['id'],
      'type': 'note',
      'data': body,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'deleted': false,
    };
    
    _db.upsertItems(userId, [item]);
    return Response.ok(json.encode({'status': 'ok'}));
  }

  Future<Response> _deleteNoteHandler(Request req, String id) async {
    final userId = _getUserId(req);
    _db.markDeleted(userId, id);
    return Response.ok(json.encode({'status': 'ok'}));
  }

  /// Voller Sync: Push lokale Änderungen, Pull Remote Änderungen
  Future<Response> _syncHandler(Request req) async {
    try {
      final userId = _getUserId(req);
      final body = await req.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;
      
      final lastSyncTimestamp = data['last_sync_timestamp'] as int? ?? 0;
      final changes = (data['changes'] as List? ?? [])
          .map((i) => i as Map<String, dynamic>)
          .toList();

      // 1. Lokale Änderungen vom Client in Server-DB speichern
      if (changes.isNotEmpty) {
        _db.upsertItems(userId, changes);
      }

      // 2. Änderungen vom Server seit lastSyncTimestamp abrufen
      final serverChanges = _db.getChangesSince(userId, lastSyncTimestamp);
      
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
    final userId = _getUserId(req);
    final lastSync = int.tryParse(req.url.queryParameters['since'] ?? '0') ?? 0;
    final changes = _db.getChangesSince(userId, lastSync);
    return Response.ok(json.encode(changes), headers: {'content-type': 'application/json'});
  }

  Future<Response> _pushHandler(Request req) async {
    final userId = _getUserId(req);
    final body = await req.readAsString();
    final items = (json.decode(body) as List).cast<Map<String, dynamic>>();
    _db.upsertItems(userId, items);
    return Response.ok(json.encode({'status': 'ok'}));
  }
}
