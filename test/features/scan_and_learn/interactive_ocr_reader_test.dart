import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:vowl/features/scan_and_learn/domain/entities/scanned_word_token.dart';
import 'package:vowl/features/scan_and_learn/presentation/widgets/interactive_ocr_reader.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScannedWordToken Entity Tests', () {
    test('instantiates correctly and implements equality', () {
      const token1 = ScannedWordToken(
        text: 'Hospital!',
        cleanWord: 'hospital',
        boundingBox: Rect.fromLTWH(10, 10, 50, 20),
        isKeyword: true,
        ipa: '/ˈhɒs.pɪ.təl/',
      );

      const token2 = ScannedWordToken(
        text: 'Hospital!',
        cleanWord: 'hospital',
        boundingBox: Rect.fromLTWH(10, 10, 50, 20),
        isKeyword: true,
        ipa: '/ˈhɒs.pɪ.təl/',
      );

      expect(token1, equals(token2));
      expect(token1.cleanWord, equals('hospital'));
      expect(token1.isKeyword, isTrue);

      final updated = token1.copyWith(isKeyword: false);
      expect(updated.isKeyword, isFalse);
      expect(updated.cleanWord, equals('hospital'));
    });
  });

  group('InteractiveOcrReader Widget Tests', () {
    final element = TextElement(
      text: 'Emergency',
      boundingBox: const Rect.fromLTWH(0, 0, 100, 20),
      cornerPoints: const [
        Point(0, 0),
        Point(100, 0),
        Point(100, 20),
        Point(0, 20),
      ],
      recognizedLanguages: const ['en'],
      symbols: const [],
      confidence: 0.99,
      angle: 0.0,
    );
    final line = TextLine(
      text: 'Emergency',
      elements: [element],
      boundingBox: const Rect.fromLTWH(0, 0, 100, 20),
      cornerPoints: const [
        Point(0, 0),
        Point(100, 0),
        Point(100, 20),
        Point(0, 20),
      ],
      recognizedLanguages: const ['en'],
      confidence: 0.99,
      angle: 0.0,
    );
    final block = TextBlock(
      text: 'Emergency',
      lines: [line],
      boundingBox: const Rect.fromLTWH(0, 0, 100, 20),
      cornerPoints: const [
        Point(0, 0),
        Point(100, 0),
        Point(100, 20),
        Point(0, 20),
      ],
      recognizedLanguages: const ['en'],
    );
    final recognizedText = RecognizedText(text: 'Emergency', blocks: [block]);

    testWidgets('renders interactive tokens and challenge banner', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          InteractiveOcrReader(
            recognizedText: recognizedText,
            selectedToken: null,
            onSelectToken: (_) {},
            onStartChallenge: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Emergency'), findsOneWidget);
      expect(find.text('SNAP CHALLENGE • 3 QUESTIONS'), findsOneWidget);
      expect(
        find.text('Test Your Real-World Vocabulary (+10 Coins)'),
        findsOneWidget,
      );
      expect(find.text('INTERACTIVE TEXT CANVAS'), findsOneWidget);
    });

    testWidgets('fires onSelectToken when word chip is tapped', (tester) async {
      ScannedWordToken? selected;

      await tester.pumpWidget(
        _wrap(
          InteractiveOcrReader(
            recognizedText: recognizedText,
            selectedToken: null,
            onSelectToken: (token) => selected = token,
            onStartChallenge: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Emergency'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.cleanWord, equals('emergency'));
      expect(selected!.isKeyword, isTrue);
    });

    testWidgets('fires onStartChallenge when banner is tapped', (tester) async {
      bool challengeStarted = false;

      await tester.pumpWidget(
        _wrap(
          InteractiveOcrReader(
            recognizedText: recognizedText,
            selectedToken: null,
            onSelectToken: (_) {},
            onStartChallenge: () => challengeStarted = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('SNAP CHALLENGE • 3 QUESTIONS'));
      await tester.pumpAndSettle();

      expect(challengeStarted, isTrue);
    });
  });
}
