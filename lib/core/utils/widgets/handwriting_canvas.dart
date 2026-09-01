import 'package:flutter/material.dart' hide Ink;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HandwritingCanvas extends StatefulWidget {
  final Function(Ink ink) onInkUpdated;
  final VoidCallback onClear;
  final Color canvasColor;
  final Color strokeColor;
  final Color borderColor;
  final double borderWidth;

  const HandwritingCanvas({
    super.key,
    required this.onInkUpdated,
    required this.onClear,
    this.canvasColor = Colors.white,
    this.strokeColor = Colors.indigo,
    this.borderColor = const Color(0xFFE0E0E0), // Colors.grey.shade300 approx
    this.borderWidth = 2.0,
  });

  @override
  State<HandwritingCanvas> createState() => HandwritingCanvasState();
}

class HandwritingCanvasState extends State<HandwritingCanvas> {
  final Ink _ink = Ink();
  final ValueNotifier<List<Stroke>> _strokes = ValueNotifier([]);
  Stroke? _currentStroke;

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    _strokes.dispose();
    super.dispose();
  }

  void clearCanvas() {
    _strokes.value = [];
    _ink.strokes.clear();
    widget.onClear();
  }

  void _undoStroke() {
    if (_strokes.value.isNotEmpty) {
      final newStrokes = List<Stroke>.from(_strokes.value);
      newStrokes.removeLast();
      _strokes.value = newStrokes;
      
      // Rebuild Ink object without the last stroke
      _ink.strokes.clear();
      for (var stroke in newStrokes) {
        _ink.strokes.add(stroke);
      }
      
      widget.onInkUpdated(_ink);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.undo2, color: Colors.amber),
              onPressed: _undoStroke,
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
              onPressed: clearCanvas,
            ),
          ],
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: widget.canvasColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.borderColor,
                width: widget.borderWidth,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onPanStart: (details) {
                  _currentStroke = Stroke();
                  _currentStroke!.points.add(
                    StrokePoint(
                      x: details.localPosition.dx,
                      y: details.localPosition.dy,
                      t: DateTime.now().millisecondsSinceEpoch,
                    ),
                  );
                  final newStrokes = List<Stroke>.from(_strokes.value);
                  newStrokes.add(_currentStroke!);
                  _strokes.value = newStrokes;
                },
                onPanUpdate: (details) {
                  _currentStroke?.points.add(
                    StrokePoint(
                      x: details.localPosition.dx,
                      y: details.localPosition.dy,
                      t: DateTime.now().millisecondsSinceEpoch,
                    ),
                  );
                  // Force a redraw
                  _strokes.value = List<Stroke>.from(_strokes.value);
                },
                onPanEnd: (details) {
                  if (_currentStroke != null) {
                    _ink.strokes.add(_currentStroke!);
                    widget.onInkUpdated(_ink);
                    _currentStroke = null;
                  }
                },
                child: ValueListenableBuilder<List<Stroke>>(
                  valueListenable: _strokes,
                  builder: (context, strokes, _) {
                    return CustomPaint(
                      painter: _SignaturePainter(strokes, widget.strokeColor),
                      size: Size.infinite,
                    );
                  }
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Stroke> strokes;
  final Color strokeColor;

  _SignaturePainter(this.strokes, this.strokeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.0
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final path = Path();
      path.moveTo(stroke.points.first.x, stroke.points.first.y);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].x, stroke.points[i].y);
      }

      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) {
    return true;
  }
}
