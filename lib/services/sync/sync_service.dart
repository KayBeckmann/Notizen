import '../database/database.dart';

abstract class SyncProvider {
  Future<void> connect();
  Future<void> disconnect();
  Future<bool> isConnected();
  Future<void> uploadNote(Note note);
  Future<List<Note>> downloadNotes();
}

class SyncService {
  final SyncProvider? provider;

  SyncService(this.provider);

  Future<void> sync() async {
    if (provider == null || !await provider!.isConnected()) return;
    
    // TODO: Sync-Logik
  }
}
