import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/features/scan_and_learn/presentation/widgets/scan_bounty_target.dart';
import 'package:vowl/features/scan_and_learn/presentation/widgets/scan_empty_state.dart';
import 'package:vowl/features/scan_and_learn/presentation/widgets/scan_result_block.dart';

Widget _wrap(
  Widget child, {
  Size size = const Size(390, 844),
  bool disableAnimations = false,
}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Scan and Learn Widget Tests', () {
    testWidgets('ScanBountyTarget renders correctly without overflow on small screens',
        (tester) async {
      bool shuffled = false;

      await tester.pumpWidget(
        _wrap(
          ScanBountyTarget(
            currentBounty: 'Extremely Long Public Safety Signboard Name For Test',
            bountyFound: false,
            dailyCount: 2,
            onShuffle: () => shuffled = true,
          ),
          size: const Size(320, 568), // Small screen (iPhone SE 1st gen)
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Extremely Long Public Safety Signboard Name For Test'),
        findsOneWidget,
      );
      expect(find.text('2/3'), findsOneWidget);

      final shuffleFinder = find.byIcon(LucideIcons.shuffle);
      expect(shuffleFinder, findsOneWidget);
      await tester.tap(shuffleFinder);
      expect(shuffled, isTrue);

      // Verify tapping (i) button opens explanation dialog
      final infoFinder = find.byIcon(Icons.info_outline_rounded);
      expect(infoFinder, findsOneWidget);
      await tester.tap(infoFinder);
      await tester.pumpAndSettle();

      expect(find.text('HOW SIGN BOUNTIES WORK'), findsOneWidget);
      expect(find.text('GOT IT!'), findsOneWidget);

      final closeFinder = find.byIcon(Icons.close_rounded);
      expect(closeFinder, findsOneWidget);
      await tester.tap(closeFinder);
      await tester.pumpAndSettle();
      expect(find.text('HOW SIGN BOUNTIES WORK'), findsNothing);
    });

    testWidgets('ScanEmptyState renders without overflow on ultra-short screen (320x480)',
        (tester) async {
      bool cameraTapped = false;

      await tester.pumpWidget(
        _wrap(
          ScanEmptyState(
            onPickImage: (src) async => cameraTapped = true,
          ),
          size: const Size(320, 480), // Ultra-short 4:3 screen
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scan & Learn'), findsOneWidget);
      expect(find.text('SIGN & TEXT READER'), findsOneWidget);
      expect(find.text('Street Signs'), findsOneWidget);

      final cameraFinder = find.text('Camera');
      expect(cameraFinder, findsOneWidget);
      await tester.ensureVisible(cameraFinder);
      await tester.pumpAndSettle();
      await tester.tap(cameraFinder);
      expect(cameraTapped, isTrue);
    });

    testWidgets('ScanResultBlock renders text, tip, translation, and action buttons',
        (tester) async {
      final block = TextBlock(
        text: 'EMERGENCY EXIT ONLY - PUSH BAR TO OPEN',
        lines: const [],
        boundingBox: const Rect.fromLTWH(0, 0, 200, 50),
        recognizedLanguages: const ['en'],
        cornerPoints: const [
          Point<int>(0, 0),
          Point<int>(200, 0),
          Point<int>(200, 50),
          Point<int>(0, 50),
        ],
      );

      bool pronunciationCalled = false;
      bool savedToggled = false;

      await tester.pumpWidget(
        _wrap(
          ScanResultBlock(
            block: block,
            index: 0,
            translatedText: 'SALIDA DE EMERGENCIA SOLAMENTE\n\nConsejo de lectura',
            isTranslating: false,
            containsBounty: true,
            bountyWord: 'Exit',
            isSaved: false,
            onTranslate: (idx, txt) {},
            onPlayPronunciation: (txt) => pronunciationCalled = true,
            onToggleSave: (txt) => savedToggled = true,
          ),
          size: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('EMERGENCY EXIT ONLY'), findsOneWidget);
      expect(find.text('SALIDA DE EMERGENCIA SOLAMENTE'), findsOneWidget);
      expect(find.text('TARGET WORD DETECTED: "Exit"'), findsOneWidget);
      expect(find.textContaining('7 words'), findsOneWidget);

      final copyFinder = find.byIcon(LucideIcons.copy);
      expect(copyFinder, findsOneWidget);
      await tester.tap(copyFinder);
      await tester.pump();

      final audioFinder = find.bySemanticsLabel('Listen to scanned text');
      expect(audioFinder, findsOneWidget);
      await tester.tap(audioFinder);
      expect(pronunciationCalled, isTrue);

      final starFinder = find.byIcon(Icons.star_outline_rounded);
      expect(starFinder, findsOneWidget);
      await tester.tap(starFinder);
      expect(savedToggled, isTrue);
    });
  });
}

