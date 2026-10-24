import 'package:flutter/material.dart' hide Ink;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

/// Zero-allocation notifier for real-time stroke drawing updates.
class StrokeNotifier extends ChangeNotifier {
  bool _isDisposed = false;
  final List<Stroke> _strokes = [];
  final Ink _ink = Ink();
  Stroke? _activeStroke;
  int _revision = 0;

  /// The collection of recorded strokes.
  List<Stroke> get strokes => _strokes;

  /// The active ML Kit digital ink container.
  Ink get ink => _ink;

  /// Revision counter indicating stroke point updates.
  int get revision => _revision;

  /// Whether any strokes or active drawing points exist.
  bool get hasStrokes => _strokes.isNotEmpty || _activeStroke != null;

  /// Total count of completed and active strokes.
  int get strokeCount => _strokes.length + (_activeStroke != null ? 1 : 0);

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void startStroke(Offset point) {
    if (_isDisposed) return;
    _activeStroke = Stroke();
    _activeStroke!.points.add(
      StrokePoint(
        x: point.dx,
        y: point.dy,
        t: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    _strokes.add(_activeStroke!);
    _revision++;
    notifyListeners();
  }

  void appendPoint(Offset point) {
    if (_activeStroke == null) return;
    _activeStroke!.points.add(
      StrokePoint(
        x: point.dx,
        y: point.dy,
        t: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    _revision++;
    notifyListeners();
  }

  void endStroke() {
    if (_activeStroke != null) {
      _ink.strokes.add(_activeStroke!);
      _activeStroke = null;
      _revision++;
      notifyListeners();
    }
  }

  void undoStroke() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      _ink.strokes.clear();
      for (final s in _strokes) {
        _ink.strokes.add(s);
      }
      _revision++;
      notifyListeners();
    }
  }

  void clear() {
    _strokes.clear();
    _ink.strokes.clear();
    _activeStroke = null;
    _revision++;
    notifyListeners();
  }
}

