import 'browser_title_stub.dart'
    if (dart.library.js_interop) 'browser_title_web.dart';

/// Service zum Aktualisieren des Browser-Tab-Titels (nur Web)
class BrowserTitleService {
  static const String _appName = 'Notizen';

  /// Setzt den Browser-Tab-Titel
  static void setTitle(String? title) {
    final displayTitle = title == null || title.isEmpty
        ? _appName
        : '$title - $_appName';
    setDocumentTitle(displayTitle);
  }

  /// Setzt den Titel auf den Standard-App-Namen
  static void resetTitle() {
    setDocumentTitle(_appName);
  }

  /// Setzt den Titel für eine Notiz
  static void setNoteTitle(String noteTitle) {
    if (noteTitle.isEmpty) {
      setTitle('Neue Notiz');
    } else {
      setTitle(noteTitle);
    }
  }

  /// Setzt den Titel für einen Ordner
  static void setFolderTitle(String folderName) {
    setTitle(folderName);
  }
}
