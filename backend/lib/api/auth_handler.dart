import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database_service.dart';

/// Handler für öffentliche Auth-Endpoints (ohne API-Key Authentifizierung)
class AuthHandler {
  final DatabaseService _db;

  AuthHandler(this._db);

  Router get router {
    final router = Router();
    router.post('/register', _registerHandler);
    return router;
  }

  /// POST /api/v1/auth/register
  /// Body: { "username": "string" }
  /// Returns: { "api_key": "string", "username": "string" }
  Future<Response> _registerHandler(Request req) async {
    try {
      final body = await req.readAsString();
      final data = json.decode(body) as Map<String, dynamic>;

      final username = data['username'] as String?;
      if (username == null || username.trim().isEmpty) {
        return Response(
          400,
          body: json.encode({'error': 'Username ist erforderlich'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final trimmedUsername = username.trim();
      if (trimmedUsername.length < 3) {
        return Response(
          400,
          body: json.encode({'error': 'Username muss mindestens 3 Zeichen haben'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final apiKey = _db.createUser(trimmedUsername);

      return Response.ok(
        json.encode({
          'username': trimmedUsername,
          'api_key': apiKey,
        }),
        headers: {'content-type': 'application/json'},
      );
    } on FormatException {
      return Response(
        400,
        body: json.encode({'error': 'Ungültiges JSON-Format'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      // Handle duplicate username (UNIQUE constraint violation)
      if (e.toString().contains('UNIQUE constraint failed')) {
        return Response(
          409,
          body: json.encode({'error': 'Benutzername bereits vergeben'}),
          headers: {'content-type': 'application/json'},
        );
      }
      return Response.internalServerError(
        body: json.encode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
