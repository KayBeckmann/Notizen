import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/drawing.dart';

/// Canvas für Zeichnungen
class DrawingCanvas extends StatefulWidget {
  final Drawing drawing;
  final DrawingSettings settings;
  final Function(Drawing drawing) onDrawingChanged;
  final bool showGrid;
  final Color? gridColor;

  const DrawingCanvas({
    super.key,
    required this.drawing,
    required this.settings,
    required this.onDrawingChanged,
    this.showGrid = false,
    this.gridColor,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  DrawingStroke? _currentStroke;
  Offset? _startPoint;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: ClipRect(
        child: CustomPaint(
          painter: DrawingPainter(
            drawing: widget.drawing,
            currentStroke: _currentStroke,
            showGrid: widget.showGrid,
            gridColor: widget.gridColor ?? Colors.grey.withValues(alpha: 0.2),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final position = details.localPosition;
    _startPoint = position;

    if (widget.settings.tool == DrawingTool.eraser) {
      // Radierer: Striche entfernen
      final newDrawing = widget.drawing.eraseAt(
        position,
        widget.settings.strokeWidth,
      );
      widget.onDrawingChanged(newDrawing);
    } else {
      // Neuen Strich beginnen
      _currentStroke = DrawingStroke(
        id: const Uuid().v4(),
        points: [position],
        color: widget.settings.effectiveColor,
        strokeWidth: widget.settings.strokeWidth,
        tool: widget.settings.tool,
        isFilled: widget.settings.isFilled,
      );
      setState(() {});
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final position = details.localPosition;

    if (widget.settings.tool == DrawingTool.eraser) {
      // Radierer: Weiter Striche entfernen
      final newDrawing = widget.drawing.eraseAt(
        position,
        widget.settings.strokeWidth,
      );
      widget.onDrawingChanged(newDrawing);
    } else if (_currentStroke != null) {
      if (_isShapeTool(widget.settings.tool)) {
        // Formen: Nur Start- und Endpunkt
        setState(() {
          _currentStroke = _currentStroke!.copyWith(
            points: [_startPoint!, position],
          );
        });
      } else {
        // Freihand: Punkte hinzufügen
        setState(() {
          _currentStroke = _currentStroke!.copyWith(
            points: [..._currentStroke!.points, position],
          );
        });
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke != null && _currentStroke!.points.length >= 2) {
      // Strich zur Zeichnung hinzufügen
      final newDrawing = widget.drawing.addStroke(_currentStroke!);
      widget.onDrawingChanged(newDrawing);
    }
    setState(() {
      _currentStroke = null;
      _startPoint = null;
    });
  }

  bool _isShapeTool(DrawingTool tool) {
    return tool == DrawingTool.line ||
        tool == DrawingTool.rectangle ||
        tool == DrawingTool.circle ||
        tool == DrawingTool.arrow;
  }
}

/// CustomPainter für die Zeichnung
class DrawingPainter extends CustomPainter {
  final Drawing drawing;
  final DrawingStroke? currentStroke;
  final bool showGrid;
  final Color gridColor;

  DrawingPainter({
    required this.drawing,
    this.currentStroke,
    this.showGrid = false,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Hintergrund
    final bgPaint = Paint()..color = drawing.backgroundColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Raster
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // Alle Striche zeichnen
    for (final stroke in drawing.strokes) {
      _drawStroke(canvas, stroke);
    }

    // Aktueller Strich
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    const gridSize = 20.0;

    // Vertikale Linien
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Horizontale Linien
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = stroke.isFilled ? PaintingStyle.fill : PaintingStyle.stroke;

    switch (stroke.tool) {
      case DrawingTool.pen:
      case DrawingTool.marker:
        _drawPath(canvas, stroke.points, paint);
        break;
      case DrawingTool.eraser:
        // Radierer zeichnet nicht
        break;
      case DrawingTool.line:
        _drawLine(canvas, stroke, paint);
        break;
      case DrawingTool.rectangle:
        _drawRectangle(canvas, stroke, paint);
        break;
      case DrawingTool.circle:
        _drawCircle(canvas, stroke, paint);
        break;
      case DrawingTool.arrow:
        _drawArrow(canvas, stroke, paint);
        break;
    }
  }

  void _drawPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) {
      // Einzelner Punkt
      if (points.isNotEmpty) {
        canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
      }
      return;
    }

    // Bézier-Kurven für glatte Linien
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final p0 = i > 0 ? points[i - 1] : points.first;
      final p1 = points[i];

      // Kontrollpunkt in der Mitte
      final midPoint = Offset(
        (p0.dx + p1.dx) / 2,
        (p0.dy + p1.dy) / 2,
      );

      path.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
    }

    // Zum letzten Punkt
    path.lineTo(points.last.dx, points.last.dy);

    canvas.drawPath(path, paint);
  }

  void _drawLine(Canvas canvas, DrawingStroke stroke, Paint paint) {
    if (stroke.points.length < 2) return;
    canvas.drawLine(stroke.points.first, stroke.points.last, paint);
  }

  void _drawRectangle(Canvas canvas, DrawingStroke stroke, Paint paint) {
    if (stroke.points.length < 2) return;
    final rect = Rect.fromPoints(stroke.points.first, stroke.points.last);
    canvas.drawRect(rect, paint);
  }

  void _drawCircle(Canvas canvas, DrawingStroke stroke, Paint paint) {
    if (stroke.points.length < 2) return;
    final rect = Rect.fromPoints(stroke.points.first, stroke.points.last);
    canvas.drawOval(rect, paint);
  }

  void _drawArrow(Canvas canvas, DrawingStroke stroke, Paint paint) {
    if (stroke.points.length < 2) return;

    final start = stroke.points.first;
    final end = stroke.points.last;

    // Linie zeichnen
    canvas.drawLine(start, end, paint);

    // Pfeilspitze
    final angle = (end - start).direction;
    const arrowSize = 20.0;
    const arrowAngle = 0.5; // ~30 Grad

    final arrowPoint1 = Offset(
      end.dx - arrowSize * cos(angle - arrowAngle),
      end.dy - arrowSize * sin(angle - arrowAngle),
    );
    final arrowPoint2 = Offset(
      end.dx - arrowSize * cos(angle + arrowAngle),
      end.dy - arrowSize * sin(angle + arrowAngle),
    );

    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();

    final arrowPaint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.fill;

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return drawing != oldDelegate.drawing ||
        currentStroke != oldDelegate.currentStroke ||
        showGrid != oldDelegate.showGrid;
  }
}

// Math helper
double cos(double radians) => ui.Offset.fromDirection(radians).dx;
double sin(double radians) => ui.Offset.fromDirection(radians).dy;
