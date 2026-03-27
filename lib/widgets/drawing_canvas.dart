import 'dart:ui';
import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset point;
  final Paint paint;

  DrawingPoint({required this.point, required this.paint});
}

class DrawingCanvas extends StatefulWidget {
  final Function(List<DrawingPoint?> points) onDrawingChanged;
  final List<DrawingPoint?> initialPoints;

  const DrawingCanvas({
    super.key,
    required this.onDrawingChanged,
    this.initialPoints = const [],
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  late List<DrawingPoint?> _points;
  final Color _selectedColor = Colors.black;
  double _strokeWidth = 5.0;

  @override
  void initState() {
    super.initState();
    _points = List.from(widget.initialPoints);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
                icon: const Icon(Icons.color_lens),
                onPressed: () {
                  // TODO: Color picker
                }),
            Slider(
              value: _strokeWidth,
              min: 1.0,
              max: 20.0,
              onChanged: (v) => setState(() => _strokeWidth = v),
            ),
            IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() => _points.clear());
                  widget.onDrawingChanged(_points);
                }),
          ],
        ),
        Expanded(
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                _points.add(DrawingPoint(
                  point: renderBox.globalToLocal(details.globalPosition),
                  paint: Paint()
                    ..strokeCap = StrokeCap.round
                    ..isAntiAlias = true
                    ..color = _selectedColor
                    ..strokeWidth = _strokeWidth,
                ));
              });
              widget.onDrawingChanged(_points);
            },
            onPanStart: (details) {
              setState(() {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                _points.add(DrawingPoint(
                  point: renderBox.globalToLocal(details.globalPosition),
                  paint: Paint()
                    ..strokeCap = StrokeCap.round
                    ..isAntiAlias = true
                    ..color = _selectedColor
                    ..strokeWidth = _strokeWidth,
                ));
              });
            },
            onPanEnd: (details) {
              setState(() {
                _points.add(null);
              });
              widget.onDrawingChanged(_points);
            },
            child: CustomPaint(
              painter: DrawingPainter(points: _points),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
            points[i]!.point, points[i + 1]!.point, points[i]!.paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(
            PointMode.points, [points[i]!.point], points[i]!.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
