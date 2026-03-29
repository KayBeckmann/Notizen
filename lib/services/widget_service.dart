import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../database/database.dart';

class WidgetService {
  static const String _androidWidgetName = 'NoteWidgetProvider';
  static const String _groupId = 'group.com.kaybeckmann.notizen';

  /// Initialisiert das Home-Widget.
  static Future<void> init() async {
    if (kIsWeb) return;
    
    // Unter iOS müssen wir die App Group setzen (falls wir iOS-Widgets hinzufügen)
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(_groupId);
    }
  }

  /// Aktualisiert das Widget mit der neuesten Notiz.
  static Future<void> updateWidgetWithLatestNote(Note? note) async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      if (note != null) {
        final title = note.title.isNotEmpty ? note.title : 'Unbenannt';
        final content = _getPreviewText(note.content);

        await HomeWidget.saveWidgetData<String>('widget_title', title);
        await HomeWidget.saveWidgetData<String>('widget_content', content);
      } else {
        await HomeWidget.saveWidgetData<String>('widget_title', 'Keine Notiz');
        await HomeWidget.saveWidgetData<String>('widget_content', 'Tippe hier, um eine Notiz zu erstellen.');
      }

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
      );
    } catch (e) {
      debugPrint('Fehler beim Aktualisieren des Widgets: $e');
    }
  }

  /// Hilfsfunktion, um Markdown für das Widget zu bereinigen.
  static String _getPreviewText(String content) {
    if (content.isEmpty) return 'Kein Inhalt';
    
    final preview = content
        .replaceAll(RegExp(r'#{1,6}\s'), '')
        .replaceAll(RegExp(r'\*{1,2}'), '')
        .replaceAll(RegExp(r'_{1,2}'), '')
        .replaceAll(RegExp(r'`{1,3}'), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();

    return preview.isNotEmpty ? preview : 'Kein Inhalt';
  }
}
