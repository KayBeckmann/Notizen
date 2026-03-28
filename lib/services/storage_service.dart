import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Service für Mediendateien-Verwaltung
class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  StorageService._();

  /// Web-spezifischer In-Memory-Cache für Bilder (blob URL → Bytes)
  static final Map<String, Uint8List> _webImageCache = {};

  /// Basis-Verzeichnis der App
  Directory? _appDirectory;

  /// Unterverzeichnisse
  static const String _audioSubdir = 'audio';
  static const String _imagesSubdir = 'images';
  static const String _drawingsSubdir = 'drawings';
  static const String _tempSubdir = 'temp';

  /// Initialisiert den Storage-Service
  Future<void> init() async {
    if (kIsWeb) {
      // Web: Kein lokales Dateisystem
      return;
    }

    _appDirectory = await getApplicationDocumentsDirectory();
    await _ensureDirectoriesExist();
  }

  /// Stellt sicher, dass alle Unterverzeichnisse existieren
  Future<void> _ensureDirectoriesExist() async {
    if (_appDirectory == null) return;

    final subdirs = [_audioSubdir, _imagesSubdir, _drawingsSubdir, _tempSubdir];

    for (final subdir in subdirs) {
      final dir = Directory(p.join(_appDirectory!.path, 'notizen_media', subdir));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  /// Gibt den Pfad zum Medien-Verzeichnis zurück
  String get mediaBasePath {
    if (_appDirectory == null) {
      throw StateError('StorageService nicht initialisiert. Rufe init() auf.');
    }
    return p.join(_appDirectory!.path, 'notizen_media');
  }

  /// Gibt den Pfad zum Audio-Verzeichnis zurück
  String get audioPath => p.join(mediaBasePath, _audioSubdir);

  /// Gibt den Pfad zum Bilder-Verzeichnis zurück
  String get imagesPath => p.join(mediaBasePath, _imagesSubdir);

  /// Gibt den Pfad zum Zeichnungen-Verzeichnis zurück
  String get drawingsPath => p.join(mediaBasePath, _drawingsSubdir);

  /// Gibt den Pfad zum temporären Verzeichnis zurück
  String get tempPath => p.join(mediaBasePath, _tempSubdir);

  /// Generiert einen eindeutigen Dateinamen mit der gegebenen Erweiterung
  String generateFilename(String extension) {
    final uuid = const Uuid().v4();
    return '$uuid.$extension';
  }

  /// Speichert eine Datei im Audio-Verzeichnis
  Future<String> saveAudioFile(File sourceFile, {String? filename}) async {
    return _saveFile(sourceFile, audioPath, filename: filename ?? generateFilename('m4a'));
  }

  /// Speichert eine Datei im Bilder-Verzeichnis
  Future<String> saveImageFile(File sourceFile, {String? filename, String extension = 'jpg'}) async {
    return _saveFile(sourceFile, imagesPath, filename: filename ?? generateFilename(extension));
  }

  /// Speichert Bytes im Bilder-Verzeichnis
  Future<String> saveImageBytes(Uint8List bytes, {String? filename, String extension = 'jpg'}) async {
    final fname = filename ?? generateFilename(extension);
    final targetPath = p.join(imagesPath, fname);
    final file = File(targetPath);
    await file.writeAsBytes(bytes);
    return targetPath;
  }

  /// Speichert Bild-Bytes für Web (in-memory, nur für aktuelle Session)
  String saveImageBytesForWeb(Uint8List bytes, {String extension = 'jpg'}) {
    final id = const Uuid().v4();
    final key = 'web://$id.$extension';
    _webImageCache[key] = bytes;
    return key;
  }

  /// Gibt Bild-Bytes für einen Web-Pfad zurück
  static Uint8List? getWebImageBytes(String webPath) {
    return _webImageCache[webPath];
  }

  /// Prüft ob ein Pfad ein Web-Pfad ist
  static bool isWebPath(String path) => path.startsWith('web://');

  /// Speichert eine Datei im Zeichnungen-Verzeichnis
  Future<String> saveDrawingFile(File sourceFile, {String? filename}) async {
    return _saveFile(sourceFile, drawingsPath, filename: filename ?? generateFilename('png'));
  }

  /// Speichert Bytes im Zeichnungen-Verzeichnis (für Export)
  Future<String> saveDrawingBytes(Uint8List bytes, {String? filename}) async {
    final fname = filename ?? generateFilename('png');
    final targetPath = p.join(drawingsPath, fname);
    final file = File(targetPath);
    await file.writeAsBytes(bytes);
    return targetPath;
  }

  /// Interne Methode zum Speichern einer Datei
  Future<String> _saveFile(File sourceFile, String targetDir, {required String filename}) async {
    final targetPath = p.join(targetDir, filename);
    final targetFile = File(targetPath);

    // Kopiere die Datei
    await sourceFile.copy(targetPath);

    return targetPath;
  }

  /// Liest eine Datei
  Future<File?> readFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Löscht eine Datei
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Fehler beim Löschen der Datei: $e');
      return false;
    }
  }

  /// Prüft ob eine Datei existiert
  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  /// Gibt die Dateigröße zurück (in Bytes)
  Future<int> getFileSize(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Formatiert die Dateigröße für Anzeige
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Listet alle Dateien in einem Verzeichnis auf
  Future<List<FileSystemEntity>> listFiles(String directory) async {
    final dir = Directory(directory);
    if (await dir.exists()) {
      return dir.listSync();
    }
    return [];
  }

  /// Räumt verwaiste Dateien auf (Dateien die nicht mehr referenziert werden)
  Future<CleanupResult> cleanupOrphanedFiles({
    required Set<String> referencedAudioPaths,
    required Set<String> referencedImagePaths,
    required Set<String> referencedDrawingPaths,
    bool dryRun = true,
  }) async {
    int audioDeleted = 0;
    int imagesDeleted = 0;
    int drawingsDeleted = 0;
    int bytesFreed = 0;

    // Audio-Dateien überprüfen
    final audioFiles = await listFiles(audioPath);
    for (final file in audioFiles) {
      if (file is File && !referencedAudioPaths.contains(file.path)) {
        bytesFreed += await file.length();
        if (!dryRun) {
          await file.delete();
        }
        audioDeleted++;
      }
    }

    // Bild-Dateien überprüfen
    final imageFiles = await listFiles(imagesPath);
    for (final file in imageFiles) {
      if (file is File && !referencedImagePaths.contains(file.path)) {
        bytesFreed += await file.length();
        if (!dryRun) {
          await file.delete();
        }
        imagesDeleted++;
      }
    }

    // Zeichnungs-Dateien überprüfen
    final drawingFiles = await listFiles(drawingsPath);
    for (final file in drawingFiles) {
      if (file is File && !referencedDrawingPaths.contains(file.path)) {
        bytesFreed += await file.length();
        if (!dryRun) {
          await file.delete();
        }
        drawingsDeleted++;
      }
    }

    // Temp-Verzeichnis leeren
    final tempFiles = await listFiles(tempPath);
    for (final file in tempFiles) {
      if (file is File) {
        bytesFreed += await file.length();
        if (!dryRun) {
          await file.delete();
        }
      }
    }

    return CleanupResult(
      audioFilesDeleted: audioDeleted,
      imageFilesDeleted: imagesDeleted,
      drawingFilesDeleted: drawingsDeleted,
      bytesFreed: bytesFreed,
      dryRun: dryRun,
    );
  }

  /// Gibt den gesamten Speicherverbrauch zurück
  Future<StorageStats> getStorageStats() async {
    int audioBytes = 0;
    int imageBytes = 0;
    int drawingBytes = 0;
    int audioCount = 0;
    int imageCount = 0;
    int drawingCount = 0;

    final audioFiles = await listFiles(audioPath);
    for (final file in audioFiles) {
      if (file is File) {
        audioBytes += await file.length();
        audioCount++;
      }
    }

    final imageFiles = await listFiles(imagesPath);
    for (final file in imageFiles) {
      if (file is File) {
        imageBytes += await file.length();
        imageCount++;
      }
    }

    final drawingFiles = await listFiles(drawingsPath);
    for (final file in drawingFiles) {
      if (file is File) {
        drawingBytes += await file.length();
        drawingCount++;
      }
    }

    return StorageStats(
      audioBytes: audioBytes,
      imageBytes: imageBytes,
      drawingBytes: drawingBytes,
      audioCount: audioCount,
      imageCount: imageCount,
      drawingCount: drawingCount,
    );
  }
}

/// Ergebnis der Aufräum-Operation
class CleanupResult {
  final int audioFilesDeleted;
  final int imageFilesDeleted;
  final int drawingFilesDeleted;
  final int bytesFreed;
  final bool dryRun;

  const CleanupResult({
    required this.audioFilesDeleted,
    required this.imageFilesDeleted,
    required this.drawingFilesDeleted,
    required this.bytesFreed,
    required this.dryRun,
  });

  int get totalFilesDeleted =>
      audioFilesDeleted + imageFilesDeleted + drawingFilesDeleted;

  @override
  String toString() {
    final action = dryRun ? 'würden gelöscht' : 'gelöscht';
    return 'Aufräumen: $totalFilesDeleted Dateien $action (${StorageService.instance.formatFileSize(bytesFreed)} freigegeben)';
  }
}

/// Speicherstatistiken
class StorageStats {
  final int audioBytes;
  final int imageBytes;
  final int drawingBytes;
  final int audioCount;
  final int imageCount;
  final int drawingCount;

  const StorageStats({
    required this.audioBytes,
    required this.imageBytes,
    required this.drawingBytes,
    required this.audioCount,
    required this.imageCount,
    required this.drawingCount,
  });

  int get totalBytes => audioBytes + imageBytes + drawingBytes;
  int get totalCount => audioCount + imageCount + drawingCount;
}
