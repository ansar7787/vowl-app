import 'package:flutter/material.dart' hide Ink;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HandwritingCanvas extends StatefulWidget {
  final Function(Ink ink) onInkUpdated;
  final VoidCallback onClear;
  
  const HandwritingCanvas({
    super.key,
    required this.onInkUpdated,
    required this.onClear,
  });

  @override
  State<HandwritingCanvas> createState() => HandwritingCanvasState();
}

class HandwritingCanvasState extends State<HandwritingCanvas> {
  final Ink _ink = Ink();
  final List<Stroke> _strokes = [];
  Stroke? _currentStroke;
  
  @override
  void initState() {
    super.initState();
  }

  void clearCanvas() {
    setState(() {
      _strokes.clear();
      _ink.strokes.clear();
    });
    widget.onClear();
  }

  void _undoStroke() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
        // Rebuild Ink object without the last stroke
        _ink.strokes.clear();
        for (var stroke in _strokes) {
          _ink.strokes.add(stroke);
        }
      });
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 2),
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
                  setState(() {
                    _strokes.add(_currentStroke!);
                  });
                },
                onPanUpdate: (details) {
                  _currentStroke?.points.add(
                    StrokePoint(
                      x: details.localPosition.dx,
                      y: details.localPosition.dy,
                      t: DateTime.now().millisecondsSinceEpoch,
                    ),
                  );
                  setState(() {});
                },
                onPanEnd: (details) {
                  if (_currentStroke != null) {
                    _ink.strokes.add(_currentStroke!);
                    widget.onInkUpdated(_ink);
                    _currentStroke = null;
                  }
                },
                child: CustomPaint(
                  painter: _SignaturePainter(_strokes),
                  size: Size.infinite,
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

  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.indigo
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
