import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:vowl/features/kids_zone/presentation/utils/handwriting_evaluator.dart';

void main() {
  const evaluator = HandwritingEvaluator();

  group('HandwritingEvaluator - Strict Text & Candidate Evaluation', () {
    test('evaluates exact match and case-insensitivity without false positives', () {
      final ink = Ink();
      expect(evaluator.evaluate(ink: ink, target: 'A', candidates: ['a']), isTrue);
      expect(evaluator.evaluate(ink: ink, target: 'cat', candidates: ['CAT']), isTrue);
      // Different word fails (e.g. car when target is cat)
      expect(evaluator.evaluate(ink: ink, target: 'cat', candidates: ['car']), isFalse);
      expect(evaluator.evaluate(ink: ink, target: 'dog', candidates: ['bird']), isFalse);
    });

    test('ignores low-probability deep candidates beyond top-2', () {
      final ink = Ink();
      // Target is 'CAT', but 'CAT' only appears at candidate index 4 (deep guess)
      expect(
        evaluator.evaluate(
          ink: ink,
          target: 'CAT',
          candidates: ['DOG', 'BIRD', 'PIG', 'COW', 'CAT'],
        ),
        isFalse,
      );

      // But if 'CAT' is in top-2 candidates, it succeeds
      expect(
        evaluator.evaluate(
          ink: ink,
          target: 'CAT',
          candidates: ['COT', 'CAT'],
        ),
        isTrue,
      );
    });

    test('strictly evaluates canonical equivalents for geometric shapes and marks', () {
      final ink = Ink();
      // Square '□' matches '[]' but MUST NOT match circle 'O' or 'D'
      expect(evaluator.evaluate(ink: ink, target: '□', candidates: ['[]']), isTrue);
      expect(evaluator.evaluate(ink: ink, target: '□', candidates: ['O']), isFalse);

      // Triangle '△' recognized as '^' or '/\'
      expect(evaluator.evaluate(ink: ink, target: '△', candidates: ['^']), isTrue);
      expect(evaluator.evaluate(ink: ink, target: '△', candidates: ['/\\']), isTrue);

      // Standing line '|' recognized as 'I' or '1', but NOT 'L' or '/'
      expect(evaluator.evaluate(ink: ink, target: '|', candidates: ['I']), isTrue);
      expect(evaluator.evaluate(ink: ink, target: '|', candidates: ['1']), isTrue);
      expect(evaluator.evaluate(ink: ink, target: '|', candidates: ['L']), isFalse);

      // Four standing lines '| | | |' recognized as '||||' or '1111'
      expect(evaluator.evaluate(ink: ink, target: '| | | |', candidates: ['||||']), isTrue);
      expect(evaluator.evaluate(ink: ink, target: '| | | |', candidates: ['1111']), isTrue);

      // Sleeping line '-' recognized as '—', but NOT '+' or 'T'
      expect(evaluator.evaluate(ink: ink, target: '-', candidates: ['—']), isTrue);
      expect(evaluator.evaluate(ink: ink, target: '—', candidates: ['-']), isTrue);
      expect(evaluator.evaluate(ink: ink, target: '-', candidates: ['+']), isFalse);

      // Cross 'X' and Plus '+' are distinct
      expect(evaluator.evaluate(ink: ink, target: 'X', candidates: ['x']), isTrue);
      expect(evaluator.evaluate(ink: ink, target: '+', candidates: ['+']), isTrue);
      expect(evaluator.evaluate(ink: ink, target: '+', candidates: ['X']), isFalse);
      expect(evaluator.evaluate(ink: ink, target: 'X', candidates: ['+']), isFalse);
    });

    test('evaluates fuzzy similarity strictly for full curriculum sentences', () {
      final ink = Ink();
      const target = 'I have 3 pens and 2 books.';

      // Exact match without punctuation period
      expect(
        evaluator.evaluate(
          ink: ink,
          target: target,
          candidates: ['I have 3 pens and 2 books'],
        ),
        isTrue,
      );

      // Minor 1-char typo in full sentence (>= 88% similarity)
      expect(
        evaluator.evaluate(
          ink: ink,
          target: target,
          candidates: ['I have 3 pens and 2 book.'],
        ),
        isTrue,
      );

      // 90% different text fails completely
      expect(
        evaluator.evaluate(
          ink: ink,
          target: target,
          candidates: ['Something completely different'],
        ),
        isFalse,
      );

      // Short wrong sentence fails
      expect(
        evaluator.evaluate(
          ink: ink,
          target: target,
          candidates: ['I like cats'],
        ),
        isFalse,
      );
    });
  });

  group('HandwritingEvaluator - Geometric Stroke Fallback & Disambiguation', () {
    test('evaluates vertical stroke and rejects horizontal stroke', () {
      final ink = Ink();
      final stroke = Stroke();
      stroke.points.add(StrokePoint(x: 100, y: 50, t: 0));
      stroke.points.add(StrokePoint(x: 102, y: 150, t: 50));
      ink.strokes.add(stroke);

      expect(evaluator.evaluate(ink: ink, target: '|'), isTrue);
      expect(evaluator.evaluate(ink: ink, target: '-'), isFalse);
      expect(evaluator.evaluate(ink: ink, target: '/'), isFalse);
    });

    test('evaluates horizontal stroke and rejects vertical stroke', () {
      final ink = Ink();
      final stroke = Stroke();
      stroke.points.add(StrokePoint(x: 50, y: 100, t: 0));
      stroke.points.add(StrokePoint(x: 180, y: 102, t: 50));
      ink.strokes.add(stroke);

      expect(evaluator.evaluate(ink: ink, target: '-'), isTrue);
      expect(evaluator.evaluate(ink: ink, target: '—'), isTrue);
      expect(evaluator.evaluate(ink: ink, target: '|'), isFalse);
    });

    test('rejects L-shape (2 strokes) when asking for single vertical line', () {
      final ink = Ink();
      final vert = Stroke();
      vert.points.add(StrokePoint(x: 100, y: 50, t: 0));
      vert.points.add(StrokePoint(x: 100, y: 150, t: 50));
      final horiz = Stroke();
      horiz.points.add(StrokePoint(x: 100, y: 150, t: 60));
      horiz.points.add(StrokePoint(x: 150, y: 150, t: 100));
      ink.strokes.addAll([vert, horiz]);

      // Target '|' requires exactly 1 vertical stroke; drawing an 'L' (2 strokes) must FAIL
      expect(evaluator.evaluate(ink: ink, target: '|'), isFalse);
      expect(evaluator.evaluate(ink: ink, target: '-'), isFalse);
    });

    test('evaluates closed loop for shapes geometrically', () {
      final ink = Ink();
      final stroke = Stroke();
      stroke.points.add(StrokePoint(x: 100, y: 100, t: 0));
      stroke.points.add(StrokePoint(x: 150, y: 100, t: 10));
      stroke.points.add(StrokePoint(x: 150, y: 150, t: 20));
      stroke.points.add(StrokePoint(x: 100, y: 150, t: 30));
      stroke.points.add(StrokePoint(x: 102, y: 102, t: 40));
      ink.strokes.add(stroke);

      expect(evaluator.evaluate(ink: ink, target: '□'), isTrue);
      expect(evaluator.evaluate(ink: ink, target: '○'), isTrue);
      // Line targets must fail when drawing a square/circle
      expect(evaluator.evaluate(ink: ink, target: '|'), isFalse);
      expect(evaluator.evaluate(ink: ink, target: '-'), isFalse);
    });
  });
}
