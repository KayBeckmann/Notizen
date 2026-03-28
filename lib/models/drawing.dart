import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Zeichenwerkzeug-Typen
enum DrawingTool {
  pen,
  marker,
  eraser,
  line,
  rectangle,
  circle,
  arrow,
}

/// Ein einzelner Strich/Pfad in der Zeichnung
class DrawingStroke {
  final String id;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DrawingTool tool;
  final bool isFilled;

  const DrawingStroke({
    required this.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.tool,
    this.isFilled = false,
  });

  /// Erstellt eine Kopie mit geänderten Werten
  DrawingStroke copyWith({
    String? id,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    DrawingTool? tool,
    bool? isFilled,
  }) {
    return DrawingStroke(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      tool: tool ?? this.tool,
      isFilled: isFilled ?? this.isFilled,
    );
  }

  /// Konvertiert zu JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'tool': tool.name,
      'isFilled': isFilled,
    };
  }

  /// Erstellt aus JSON
  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      id: json['id'] as String,
      points: (json['points'] as List)
          .map((p) => Offset(
                (p['x'] as num).toDouble(),
                (p['y'] as num).toDouble(),
              ))
          .toList(),
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      tool: DrawingTool.values.firstWhere(
        (t) => t.name == json['tool'],
        orElse: () => DrawingTool.pen,
      ),
      isFilled: json['isFilled'] as bool? ?? false,
    );
  }

  /// Prüft ob ein Punkt den Strich berührt (für Radierer)
  bool containsPoint(Offset point, double tolerance) {
    for (int i = 0; i < points.length; i++) {
      if ((points[i] - point).distance < tolerance + strokeWidth / 2) {
        return true;
      }
      // Prüfe auch Linien zwischen Punkten
      if (i > 0) {
        if (_pointToLineDistance(point, points[i - 1], points[i]) <
            tolerance + strokeWidth / 2) {
          return true;
        }
      }
    }
    return false;
  }

  double _pointToLineDistance(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      return (point - lineStart).distance;
    }

    final t = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) /
        lengthSquared;
    final clampedT = t.clamp(0.0, 1.0);

    final projection = Offset(
      lineStart.dx + clampedT * dx,
      lineStart.dy + clampedT * dy,
    );

    return (point - projection).distance;
  }
}

/// Komplette Zeichnung mit allen Strichen
class Drawing {
  final List<DrawingStroke> strokes;
  final Color backgroundColor;
  final Size? canvasSize;

  /// Optionaler Hintergrundbild-Pfad (für "Auf Bild zeichnen")
  final String? backgroundImagePath;

  const Drawing({
    this.strokes = const [],
    this.backgroundColor = Colors.white,
    this.canvasSize,
    this.backgroundImagePath,
  });

  /// Erstellt eine Kopie mit geänderten Werten
  Drawing copyWith({
    List<DrawingStroke>? strokes,
    Color? backgroundColor,
    Size? canvasSize,
    String? backgroundImagePath,
    bool clearBackgroundImage = false,
  }) {
    return Drawing(
      strokes: strokes ?? this.strokes,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      canvasSize: canvasSize ?? this.canvasSize,
      backgroundImagePath: clearBackgroundImage
          ? null
          : (backgroundImagePath ?? this.backgroundImagePath),
    );
  }

  /// Fügt einen Strich hinzu
  Drawing addStroke(DrawingStroke stroke) {
    return copyWith(strokes: [...strokes, stroke]);
  }

  /// Entfernt einen Strich
  Drawing removeStroke(String strokeId) {
    return copyWith(
      strokes: strokes.where((s) => s.id != strokeId).toList(),
    );
  }

  /// Entfernt Striche die einen Punkt berühren
  Drawing eraseAt(Offset point, double eraserSize) {
    final newStrokes = strokes
        .where((s) => !s.containsPoint(point, eraserSize / 2))
        .toList();
    return copyWith(strokes: newStrokes);
  }

  /// Konvertiert zu JSON-String
  String toJson() {
    return jsonEncode({
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'backgroundColor': backgroundColor.value,
      'canvasSize': canvasSize != null
          ? {'width': canvasSize!.width, 'height': canvasSize!.height}
          : null,
      if (backgroundImagePath != null)
        'backgroundImagePath': backgroundImagePath,
    });
  }

  /// Erstellt aus JSON-String
  factory Drawing.fromJson(String jsonString) {
    if (jsonString.isEmpty) {
      return const Drawing();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Drawing(
        strokes: (json['strokes'] as List?)
                ?.map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        backgroundColor: json['backgroundColor'] != null
            ? Color(json['backgroundColor'] as int)
            : Colors.white,
        canvasSize: json['canvasSize'] != null
            ? Size(
                (json['canvasSize']['width'] as num).toDouble(),
                (json['canvasSize']['height'] as num).toDouble(),
              )
            : null,
        backgroundImagePath: json['backgroundImagePath'] as String?,
      );
    } catch (e) {
      return const Drawing();
    }
  }

  /// Prüft ob die Zeichnung leer ist
  bool get isEmpty => strokes.isEmpty;

  /// Prüft ob die Zeichnung nicht leer ist
  bool get isNotEmpty => strokes.isNotEmpty;
}

/// Einstellungen für das aktuelle Zeichenwerkzeug
class DrawingSettings {
  final DrawingTool tool;
  final Color color;
  final double strokeWidth;
  final bool isFilled;
  final List<Color> recentColors;

  const DrawingSettings({
    this.tool = DrawingTool.pen,
    this.color = Colors.black,
    this.strokeWidth = 3.0,
    this.isFilled = false,
    this.recentColors = const [],
  });

  DrawingSettings copyWith({
    DrawingTool? tool,
    Color? color,
    double? strokeWidth,
    bool? isFilled,
    List<Color>? recentColors,
  }) {
    return DrawingSettings(
      tool: tool ?? this.tool,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isFilled: isFilled ?? this.isFilled,
      recentColors: recentColors ?? this.recentColors,
    );
  }

  /// Fügt eine Farbe zu den zuletzt verwendeten hinzu
  DrawingSettings addRecentColor(Color newColor) {
    final colors = [newColor, ...recentColors.where((c) => c != newColor)];
    return copyWith(recentColors: colors.take(8).toList());
  }

  /// Standard-Stiftdicke für das Werkzeug
  double get defaultStrokeWidth {
    switch (tool) {
      case DrawingTool.pen:
        return 3.0;
      case DrawingTool.marker:
        return 20.0;
      case DrawingTool.eraser:
        return 30.0;
      case DrawingTool.line:
      case DrawingTool.rectangle:
      case DrawingTool.circle:
      case DrawingTool.arrow:
        return 3.0;
    }
  }

  /// Gibt die tatsächliche Farbe zurück (transparent für Marker)
  Color get effectiveColor {
    if (tool == DrawingTool.marker) {
      return color.withValues(alpha: 0.4);
    }
    return color;
  }
}

/// Standard-Farbpalette
class DrawingColors {
  static const List<Color> palette = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
  ];
}
