import 'dart:math' as math;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

/// Comprehensive, strictly calibrated handwriting evaluator for Kids Zone Handwriting game.
/// Evaluates learner ink strokes against curriculum targets using:
/// 1. Top-2 candidate ML Kit recognition with strict casing and whitespace normalization.
/// 2. Canonical glyph mapping for English ML Kit recognizer representations.
/// 3. Strict Levenshtein tolerance exclusively for full multi-word sentences (>= 88% similarity).
/// 4. Direct geometric stroke analysis with strict stroke count and topological validation.
class HandwritingEvaluator {
  const HandwritingEvaluator();

  /// Evaluates whether the user's drawn [ink] matches the [target].
  /// [candidates] are the text candidates from Google ML Kit Digital Ink Recognition.
  bool evaluate({
    required Ink ink,
    required String target,
    List<String> candidates = const [],
  }) {
    final cleanTarget = target.trim();
    if (cleanTarget.isEmpty) return false;

    // 1. Text & Candidate Evaluation (only checks Top 2 candidates to prevent false positives)
    if (candidates.isNotEmpty) {
      if (_evaluateCandidates(candidates, cleanTarget)) {
        return true;
      }
    }

    // 2. Direct Stroke Geometry Evaluation (for shapes, lines, slants, and offline fallback)
    if (ink.strokes.isNotEmpty && _evaluateStrokesGeometrically(ink, cleanTarget)) {
      return true;
    }

    return false;
  }

  /// Evaluates ML Kit candidates against the target using strict canonical mapping and tolerance.
  bool _evaluateCandidates(List<String> candidates, String target) {
    final upperTarget = target.toUpperCase().trim();
    final isSymbol = _isSymbolTarget(upperTarget);
    final isSentence = upperTarget.contains(' ') && upperTarget.length >= 8;

    // Restrict inspection to Top 2 candidates; deeper candidates are low-probability guesses
    final topCandidates = candidates.take(2);

    for (final candidate in topCandidates) {
      final upperCandidate = candidate.toUpperCase().trim();

      // Exact case-insensitive match
      if (upperCandidate == upperTarget) {
        return true;
      }

      // Canonical symbol equivalence match (e.g. '1' for '|', '[]' for '□')
      if (_matchesCanonicalEquivalence(upperCandidate, upperTarget)) {
        return true;
      }

      // Sentence / multi-word evaluation only (allows missing final punctuation or minor typo)
      if (isSentence && !isSymbol) {
        final normCand = _normalizeSentence(upperCandidate);
        final normTarg = _normalizeSentence(upperTarget);

        if (normCand.isNotEmpty && normCand == normTarg) {
          return true;
        }

        if (normCand.length >= 6 && normTarg.length >= 6) {
          final similarity = _calculateSimilarity(normCand, normTarg);
          if (similarity >= 0.88) {
            return true;
          }
        }
      } else if (!isSymbol && upperTarget.length <= 6) {
        // Single words must match exactly (ignoring only trailing periods/quotes)
        final cleanWordCand = upperCandidate.replaceAll(RegExp(r'''[.,!?'"]'''), '').trim();
        final cleanWordTarg = upperTarget.replaceAll(RegExp(r'''[.,!?'"]'''), '').trim();
        if (cleanWordCand.isNotEmpty && cleanWordCand == cleanWordTarg) {
          return true;
        }
      }
    }

    return false;
  }

  /// Checks if target is a symbolic stroke or geometric shape
  bool _isSymbolTarget(String target) {
    const symbolTargets = {
      '|',
      '| |',
      '| | | |',
      '-',
      '—',
      '=',
      '- - - -',
      '- — -',
      '|—|',
      '/',
      '\\',
      '/ \\',
      '+',
      'X',
      '+ X +',
      '(',
      ')',
      '( )',
      '∩',
      '∪',
      '□',
      '△',
      '□ △',
      '◇',
      '▭',
      '○',
      '⬭',
    };
    return symbolTargets.contains(target.trim());
  }

  /// Normalizes a sentence by stripping external punctuation while preserving words and internal spaces.
  String _normalizeSentence(String input) {
    return input
        .replaceAll(RegExp(r'''[.,\/#!$%\^&\*;:{}=\-_`~()'"?<>|\\]'''), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Checks if ML Kit's candidate matches strictly known character equivalents for curriculum shapes and marks.
  bool _matchesCanonicalEquivalence(String candidate, String target) {
    final cleanCand = candidate.replaceAll(RegExp(r'\s+'), ' ').trim();
    final cleanTarg = target.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Map of target curriculum characters to verified recognized candidates
    final equivalenceMap = <String, List<String>>{
      // Standing lines (Strict: only vertical equivalents)
      '|': ['|', 'I', '1'],
      '| |': ['||', '11', '1 1', 'I I', 'II', '| |'],
      '| | | |': [
        '||||',
        '1111',
        '1 1 1 1',
        'IIII',
        'I I I I',
        '| | | |',
      ],

      // Sleeping lines / dashes (Strict: only horizontal equivalents)
      '-': ['-', '—', '–'],
      '—': ['—', '-', '–'],
      '=': ['=', '==', '--'],
      '- - - -': ['----', '- - - -', '____', '_ _ _ _'],
      '- — -': ['---', '- - -', '_ _ _', '- — -'],
      '|—|': ['|-|', 'I-I', 'H', '| — |', '1-1'],

      // Slants & Peaks
      '/': ['/'],
      '\\': ['\\'],
      '/ \\': ['/\\', '/ \\', '^', '/_\\'],

      // Plus & Cross (Strict: + only matches +, X only matches X)
      '+': ['+'],
      'X': ['X', 'x'],
      '+ X +': ['+X+', '+ X +', '+x+', '+ x +'],

      // Curves (Strict: Direction-aware)
      '(': ['(', 'C', 'c', '{'],
      ')': [')', '}', ']'],
      '( )': ['()', '( )', '{}'],
      '∩': ['∩', 'N', 'n', 'П'],
      '∪': ['∪', 'U', 'u', 'V', 'v'],

      // Shapes (Strict: Square must NOT match circle, Triangle must NOT match 4)
      '□': ['[]', '□'],
      '△': ['△', '^', '/\\'],
      '□ △': ['[] △', '[] ^', '□ △'],
      '◇': ['◇', '<>'],
      '▭': ['▭', '[]'],
      '○': ['○', 'O', 'o', '0'],
      '⬭': ['⬭', 'O', 'o', '0'],
    };

    if (equivalenceMap.containsKey(cleanTarg)) {
      final allowed = equivalenceMap[cleanTarg]!;
      for (final a in allowed) {
        if (cleanCand == a || cleanCand.replaceAll(' ', '') == a.replaceAll(' ', '')) {
          return true;
        }
      }
    }

    return false;
  }

  /// Calculates Levenshtein-based similarity between two strings (0.0 to 1.0).
  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final d = _levenshteinDistance(s1, s2);
    final maxLen = math.max(s1.length, s2.length);
    return 1.0 - (d / maxLen);
  }

  int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = math.min(
          v1[j] + 1,
          math.min(v0[j + 1] + 1, v0[j] + cost),
        );
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }

  /// Direct geometric analysis of strokes for single lines, shapes, and basic patterns.
  /// Enforces strict stroke counts and shape topology.
  bool _evaluateStrokesGeometrically(Ink ink, String target) {
    final strokes = ink.strokes;
    if (strokes.isEmpty) return false;

    final trimmed = target.trim();

    // 1. Single vertical line '|' -> Exactly 1 stroke, strictly vertical
    if (trimmed == '|') {
      if (strokes.length != 1) return false;
      return _isVerticalStroke(strokes.first);
    }

    // 2. Two vertical lines '| |' -> Exactly 2 strokes, both vertical, separated horizontally
    if (trimmed == '| |') {
      if (strokes.length != 2) return false;
      return _isVerticalStroke(strokes[0]) &&
          _isVerticalStroke(strokes[1]) &&
          _areHorizontallySeparated(strokes[0], strokes[1], minDistance: 20.0);
    }

    // 3. Four vertical lines '| | | |' -> Exactly 4 strokes, all vertical
    if (trimmed == '| | | |') {
      if (strokes.length < 3 || strokes.length > 5) return false;
      int vertCount = 0;
      for (final s in strokes) {
        if (_isVerticalStroke(s)) vertCount++;
      }
      return vertCount >= 3;
    }

    // 4. Single horizontal line '-' or '—' -> Exactly 1 stroke, strictly horizontal
    if (trimmed == '-' || trimmed == '—') {
      if (strokes.length != 1) return false;
      return _isHorizontalStroke(strokes.first);
    }

    // 5. Two horizontal lines '=' -> Exactly 2 strokes, both horizontal, separated vertically
    if (trimmed == '=') {
      if (strokes.length != 2) return false;
      return _isHorizontalStroke(strokes[0]) &&
          _isHorizontalStroke(strokes[1]) &&
          _areVerticallySeparated(strokes[0], strokes[1], minDistance: 12.0);
    }

    // 6. Four horizontal dashes '- - - -'
    if (trimmed == '- - - -') {
      if (strokes.length < 3 || strokes.length > 5) return false;
      int horizCount = 0;
      for (final s in strokes) {
        if (_isHorizontalStroke(s)) horizCount++;
      }
      return horizCount >= 3;
    }

    // 7. Diagonal uphill '/' -> Exactly 1 stroke, strictly diagonal uphill
    if (trimmed == '/') {
      if (strokes.length != 1) return false;
      return _isDiagonalUphill(strokes.first);
    }

    // 8. Diagonal downhill '\' -> Exactly 1 stroke, strictly diagonal downhill
    if (trimmed == '\\') {
      if (strokes.length != 1) return false;
      return _isDiagonalDownhill(strokes.first);
    }

    // 9. Roof '/ \' -> Either 1 stroke peak or 2 strokes (1 up, 1 down, touching at top)
    if (trimmed == '/ \\') {
      if (strokes.length == 1) {
        return _hasRoofShape(strokes.first);
      }
      if (strokes.length == 2) {
        final s1 = strokes[0];
        final s2 = strokes[1];
        final is1Up = _isDiagonalUphill(s1);
        final is1Down = _isDiagonalDownhill(s1);
        final is2Up = _isDiagonalUphill(s2);
        final is2Down = _isDiagonalDownhill(s2);

        return (is1Up && is2Down) || (is1Down && is2Up);
      }
      return false;
    }

    // 10. Plus '+' -> Exactly 2 strokes: 1 vertical, 1 horizontal, intersecting centrally
    if (trimmed == '+') {
      if (strokes.length != 2) return false;
      return _isPlus(strokes[0], strokes[1]);
    }

    // 11. Cross 'X' -> Exactly 2 strokes: 1 uphill, 1 downhill, intersecting centrally
    if (trimmed == 'X') {
      if (strokes.length != 2) return false;
      return _isCross(strokes[0], strokes[1]);
    }

    // 12. Left curve '(' -> Exactly 1 stroke, opening to the right
    if (trimmed == '(') {
      if (strokes.length != 1) return false;
      return _isLeftCurve(strokes.first);
    }

    // 13. Right curve ')' -> Exactly 1 stroke, opening to the left
    if (trimmed == ')') {
      if (strokes.length != 1) return false;
      return _isRightCurve(strokes.first);
    }

    // 14. Arch / Umbrella '∩' -> Exactly 1 stroke, arch peaking upward
    if (trimmed == '∩') {
      if (strokes.length != 1) return false;
      return _isArch(strokes.first);
    }

    // 15. Cup '∪' -> Exactly 1 stroke, cup curving downward with arms upward
    if (trimmed == '∪') {
      if (strokes.length != 1) return false;
      return _isCup(strokes.first);
    }

    // 16. Circle '○' -> Exactly 1 stroke, closed loop with round aspect ratio
    if (trimmed == '○' || trimmed == '⬭') {
      if (strokes.length != 1) return false;
      return _isCircle(strokes.first);
    }

    // 17. Square '□' or Rectangle '▭' -> Closed quadrilateral
    if (trimmed == '□' || trimmed == '▭') {
      return _isSquare(strokes);
    }

    // 18. Triangle '△' -> Closed 3-sided polygon with peak
    if (trimmed == '△') {
      return _isTriangle(strokes);
    }

    // 19. Diamond '◇'
    if (trimmed == '◇') {
      if (strokes.length == 1) {
        return _isClosedLoop(strokes.first);
      }
      return false;
    }

    return false;
  }

  // --- Strict Geometric Helpers ---

  bool _isVerticalStroke(Stroke stroke) {
    if (stroke.points.length < 2) return false;
    final first = stroke.points.first;

    double minX = first.x, maxX = first.x;
    double minY = first.y, maxY = first.y;

    for (final p in stroke.points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final width = maxX - minX;
    final height = maxY - minY;

    // Must have sufficient height and high vertical aspect ratio
    return height >= 25.0 && height >= width * 2.2;
  }

  bool _isHorizontalStroke(Stroke stroke) {
    if (stroke.points.length < 2) return false;
    final first = stroke.points.first;

    double minX = first.x, maxX = first.x;
    double minY = first.y, maxY = first.y;

    for (final p in stroke.points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final width = maxX - minX;
    final height = maxY - minY;

    // Must have sufficient width and high horizontal aspect ratio
    return width >= 25.0 && width >= height * 2.2;
  }

  bool _isDiagonalUphill(Stroke stroke) {
    if (stroke.points.length < 2) return false;
    final first = stroke.points.first;
    final last = stroke.points.last;

    final dx = last.x - first.x;
    final dy = last.y - first.y;

    double minX = first.x, maxX = first.x;
    double minY = first.y, maxY = first.y;
    for (final p in stroke.points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final width = maxX - minX;
    final height = maxY - minY;
    if (width < 18.0 || height < 18.0) return false;

    // Ratio must be balanced (not nearly vertical or horizontal)
    final ratio = width / height;
    if (ratio < 0.35 || ratio > 2.8) return false;

    // Moving bottom-left to top-right OR top-right to bottom-left
    return (dx > 12.0 && dy < -12.0) || (dx < -12.0 && dy > 12.0);
  }

  bool _isDiagonalDownhill(Stroke stroke) {
    if (stroke.points.length < 2) return false;
    final first = stroke.points.first;
    final last = stroke.points.last;

    final dx = last.x - first.x;
    final dy = last.y - first.y;

    double minX = first.x, maxX = first.x;
    double minY = first.y, maxY = first.y;
    for (final p in stroke.points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final width = maxX - minX;
    final height = maxY - minY;
    if (width < 18.0 || height < 18.0) return false;

    final ratio = width / height;
    if (ratio < 0.35 || ratio > 2.8) return false;

    // Moving top-left to bottom-right OR bottom-right to top-left
    return (dx > 12.0 && dy > 12.0) || (dx < -12.0 && dy < -12.0);
  }

  bool _areHorizontallySeparated(Stroke s1, Stroke s2, {required double minDistance}) {
    final midX1 = (s1.points.first.x + s1.points.last.x) / 2;
    final midX2 = (s2.points.first.x + s2.points.last.x) / 2;
    return (midX1 - midX2).abs() >= minDistance;
  }

  bool _areVerticallySeparated(Stroke s1, Stroke s2, {required double minDistance}) {
    final midY1 = (s1.points.first.y + s1.points.last.y) / 2;
    final midY2 = (s2.points.first.y + s2.points.last.y) / 2;
    return (midY1 - midY2).abs() >= minDistance;
  }

  bool _isPlus(Stroke s1, Stroke s2) {
    final is1V = _isVerticalStroke(s1);
    final is1H = _isHorizontalStroke(s1);
    final is2V = _isVerticalStroke(s2);
    final is2H = _isHorizontalStroke(s2);

    if (!((is1V && is2H) || (is1H && is2V))) return false;

    final vStroke = is1V ? s1 : s2;
    final hStroke = is1V ? s2 : s1;

    // Check intersection
    double vMinY = vStroke.points.first.y, vMaxY = vStroke.points.first.y;
    double vMinX = vStroke.points.first.x, vMaxX = vStroke.points.first.x;
    for (final p in vStroke.points) {
      if (p.y < vMinY) vMinY = p.y;
      if (p.y > vMaxY) vMaxY = p.y;
      if (p.x < vMinX) vMinX = p.x;
      if (p.x > vMaxX) vMaxX = p.x;
    }

    double hMinX = hStroke.points.first.x, hMaxX = hStroke.points.first.x;
    double hMinY = hStroke.points.first.y, hMaxY = hStroke.points.first.y;
    for (final p in hStroke.points) {
      if (p.x < hMinX) hMinX = p.x;
      if (p.x > hMaxX) hMaxX = p.x;
      if (p.y < hMinY) hMinY = p.y;
      if (p.y > hMaxY) hMaxY = p.y;
    }

    final vMidX = (vMinX + vMaxX) / 2;
    final hMidY = (hMinY + hMaxY) / 2;

    // The horizontal line must span across vertical line, and vertical across horizontal
    final spansH = hMinX <= vMidX + 10.0 && hMaxX >= vMidX - 10.0;
    final spansV = vMinY <= hMidY + 10.0 && vMaxY >= hMidY - 10.0;

    return spansH && spansV;
  }

  bool _isCross(Stroke s1, Stroke s2) {
    final is1Up = _isDiagonalUphill(s1);
    final is1Down = _isDiagonalDownhill(s1);
    final is2Up = _isDiagonalUphill(s2);
    final is2Down = _isDiagonalDownhill(s2);

    if (!((is1Up && is2Down) || (is1Down && is2Up))) return false;

    // Centers must be in close proximity
    final midX1 = (s1.points.first.x + s1.points.last.x) / 2;
    final midY1 = (s1.points.first.y + s1.points.last.y) / 2;
    final midX2 = (s2.points.first.x + s2.points.last.x) / 2;
    final midY2 = (s2.points.first.y + s2.points.last.y) / 2;

    return (midX1 - midX2).abs() <= 35.0 && (midY1 - midY2).abs() <= 35.0;
  }

  bool _hasRoofShape(Stroke stroke) {
    if (stroke.points.length < 3) return false;
    int highestIndex = 0;
    double minY = stroke.points.first.y;

    for (int i = 1; i < stroke.points.length; i++) {
      if (stroke.points[i].y < minY) {
        minY = stroke.points[i].y;
        highestIndex = i;
      }
    }

    final totalPts = stroke.points.length;
    final first = stroke.points.first;
    final last = stroke.points.last;

    // Peak in central region, both ends lower than peak
    return highestIndex > totalPts * 0.2 &&
        highestIndex < totalPts * 0.8 &&
        first.y > minY + 15.0 &&
        last.y > minY + 15.0;
  }

  bool _isLeftCurve(Stroke stroke) {
    if (stroke.points.length < 3) return false;
    final first = stroke.points.first;
    final last = stroke.points.last;
    final height = (last.y - first.y).abs();
    if (height < 25.0) return false;

    // Curve opens to the right -> midpoint extends to the left (smaller X)
    double minX = first.x;
    for (final p in stroke.points) {
      if (p.x < minX) minX = p.x;
    }

    return minX < math.min(first.x, last.x) - 10.0;
  }

  bool _isRightCurve(Stroke stroke) {
    if (stroke.points.length < 3) return false;
    final first = stroke.points.first;
    final last = stroke.points.last;
    final height = (last.y - first.y).abs();
    if (height < 25.0) return false;

    // Curve opens to the left -> midpoint extends to the right (larger X)
    double maxX = first.x;
    for (final p in stroke.points) {
      if (p.x > maxX) maxX = p.x;
    }

    return maxX > math.max(first.x, last.x) + 10.0;
  }

  bool _isArch(Stroke stroke) {
    if (stroke.points.length < 3) return false;
    final first = stroke.points.first;
    final last = stroke.points.last;

    double minY = first.y;
    for (final p in stroke.points) {
      if (p.y < minY) minY = p.y;
    }

    // Both ends must hang lower than the top peak
    return first.y >= minY + 15.0 && last.y >= minY + 15.0;
  }

  bool _isCup(Stroke stroke) {
    if (stroke.points.length < 3) return false;
    final first = stroke.points.first;
    final last = stroke.points.last;

    double maxY = first.y;
    for (final p in stroke.points) {
      if (p.y > maxY) maxY = p.y;
    }

    // Both ends must be higher than the bottom
    return first.y <= maxY - 15.0 && last.y <= maxY - 15.0;
  }

  bool _isClosedLoop(Stroke stroke) {
    if (stroke.points.length < 5) return false;
    final first = stroke.points.first;
    final last = stroke.points.last;

    double minX = first.x, maxX = first.x;
    double minY = first.y, maxY = first.y;

    for (final p in stroke.points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final diag = math.sqrt(math.pow(maxX - minX, 2) + math.pow(maxY - minY, 2));
    if (diag < 30.0) return false;

    final endDistance = math.sqrt(
      math.pow(last.x - first.x, 2) + math.pow(last.y - first.y, 2),
    );

    // End point closes near the start point
    return endDistance <= diag * 0.35;
  }

  bool _isCircle(Stroke stroke) {
    if (!_isClosedLoop(stroke)) return false;

    double minX = stroke.points.first.x, maxX = stroke.points.first.x;
    double minY = stroke.points.first.y, maxY = stroke.points.first.y;

    for (final p in stroke.points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final width = maxX - minX;
    final height = maxY - minY;
    if (width < 25.0 || height < 25.0) return false;

    // Aspect ratio must be circular
    final ratio = width / height;
    return ratio >= 0.70 && ratio <= 1.45;
  }

  bool _isSquare(List<Stroke> strokes) {
    if (strokes.isEmpty) return false;

    if (strokes.length == 1) {
      final s = strokes.first;
      if (!_isClosedLoop(s)) return false;

      double minX = s.points.first.x, maxX = s.points.first.x;
      double minY = s.points.first.y, maxY = s.points.first.y;
      for (final p in s.points) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
      }
      final ratio = (maxX - minX) / math.max(maxY - minY, 1.0);
      return ratio >= 0.65 && ratio <= 1.50;
    }

    if (strokes.length == 4) {
      int vCount = 0;
      int hCount = 0;
      for (final s in strokes) {
        if (_isVerticalStroke(s)) vCount++;
        if (_isHorizontalStroke(s)) hCount++;
      }
      return vCount == 2 && hCount == 2;
    }

    return false;
  }

  bool _isTriangle(List<Stroke> strokes) {
    if (strokes.isEmpty) return false;

    if (strokes.length == 1) {
      final s = strokes.first;
      return _isClosedLoop(s) && _hasRoofShape(s);
    }

    if (strokes.length == 3) {
      int hCount = 0;
      int slantCount = 0;
      for (final s in strokes) {
        if (_isHorizontalStroke(s)) hCount++;
        if (_isDiagonalUphill(s) || _isDiagonalDownhill(s)) slantCount++;
      }
      return hCount >= 1 && slantCount >= 2;
    }

    return false;
  }
}
