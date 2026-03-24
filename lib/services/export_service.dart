import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database.dart';

/// Service für Export-Funktionen
class ExportService {
  static final ExportService _instance = ExportService._();
  static ExportService get instance => _instance;

  ExportService._();

  /// Notiz als Markdown-Datei exportieren
  Future<String> exportAsMarkdown(Note note) async {
    final content = _buildMarkdownContent(note);
    final fileName = _sanitizeFileName(note.title.isEmpty ? 'Notiz' : note.title);

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.md');
    await file.writeAsString(content);

    return file.path;
  }

  /// Notiz als Markdown teilen
  Future<void> shareAsMarkdown(Note note) async {
    final filePath = await exportAsMarkdown(note);
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: note.title.isEmpty ? 'Notiz' : note.title,
    );
  }

  /// Notiz als Text exportieren (ohne Markdown-Formatierung)
  Future<String> exportAsText(Note note) async {
    final content = _stripMarkdown(note.content);
    final fileName = _sanitizeFileName(note.title.isEmpty ? 'Notiz' : note.title);

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.txt');
    await file.writeAsString(content);

    return file.path;
  }

  /// Notiz als Text teilen
  Future<void> shareAsText(Note note) async {
    final content = _stripMarkdown(note.content);
    await Share.share(
      content,
      subject: note.title.isEmpty ? 'Notiz' : note.title,
    );
  }

  /// Notiz-Inhalt in Zwischenablage kopieren
  Future<void> copyToClipboard(Note note) async {
    await Clipboard.setData(ClipboardData(text: note.content));
  }

  /// Markdown-Inhalt für Export erstellen
  String _buildMarkdownContent(Note note) {
    final buffer = StringBuffer();

    // Titel als H1
    if (note.title.isNotEmpty) {
      buffer.writeln('# ${note.title}');
      buffer.writeln();
    }

    // Inhalt
    buffer.writeln(note.content);

    // Metadaten als Kommentar
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('<!-- ');
    buffer.writeln('Erstellt: ${_formatDate(note.createdAt)}');
    buffer.writeln('Geändert: ${_formatDate(note.updatedAt)}');
    buffer.writeln(' -->');

    return buffer.toString();
  }

  /// Markdown-Formatierung entfernen
  String _stripMarkdown(String markdown) {
    return markdown
        // Überschriften
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
        // Fett/Kursiv
        .replaceAll(RegExp(r'\*{1,3}([^*]+)\*{1,3}'), r'$1')
        .replaceAll(RegExp(r'_{1,3}([^_]+)_{1,3}'), r'$1')
        // Durchgestrichen
        .replaceAll(RegExp(r'~~([^~]+)~~'), r'$1')
        // Code inline
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        // Code-Blöcke
        .replaceAll(RegExp(r'```[\s\S]*?```', multiLine: true), '')
        // Links
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
        // Bilder
        .replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]+\)'), r'$1')
        // Listen
        .replaceAll(RegExp(r'^[-*+]\s+', multiLine: true), '• ')
        .replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '')
        // Checkboxen
        .replaceAll(RegExp(r'^\s*- \[[ x]\]\s*', multiLine: true), '')
        // Blockquotes
        .replaceAll(RegExp(r'^>\s+', multiLine: true), '')
        // Horizontale Linien
        .replaceAll(RegExp(r'^[-*_]{3,}$', multiLine: true), '')
        // Mehrfache Leerzeilen reduzieren
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// Dateinamen bereinigen
  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Datum formatieren
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Mehrere Notizen exportieren
class BatchExportService {
  static final BatchExportService _instance = BatchExportService._();
  static BatchExportService get instance => _instance;

  BatchExportService._();

  /// Mehrere Notizen als einzelne Markdown-Dateien in einem Ordner exportieren
  Future<String> exportNotesAsMarkdownFolder(
    List<Note> notes, {
    String folderName = 'Notizen_Export',
  }) async {
    final directory = await getTemporaryDirectory();
    final exportDir = Directory('${directory.path}/$folderName');

    if (await exportDir.exists()) {
      await exportDir.delete(recursive: true);
    }
    await exportDir.create();

    for (final note in notes) {
      final content = _buildMarkdownContent(note);
      final fileName = _sanitizeFileName(note.title.isEmpty ? 'Notiz_${note.id.substring(0, 8)}' : note.title);
      final file = File('${exportDir.path}/$fileName.md');
      await file.writeAsString(content);
    }

    return exportDir.path;
  }

  /// Mehrere Notizen in einer Markdown-Datei zusammenfassen
  Future<String> exportNotesAsMarkdownSingle(List<Note> notes) async {
    final buffer = StringBuffer();

    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];

      if (note.title.isNotEmpty) {
        buffer.writeln('# ${note.title}');
        buffer.writeln();
      }

      buffer.writeln(note.content);

      if (i < notes.length - 1) {
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/Notizen_Export.md');
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  String _buildMarkdownContent(Note note) {
    return ExportService.instance._buildMarkdownContent(note);
  }

  String _sanitizeFileName(String name) {
    return ExportService.instance._sanitizeFileName(name);
  }
}
