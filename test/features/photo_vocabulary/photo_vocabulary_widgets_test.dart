import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/features/photo_vocabulary/presentation/widgets/photo_bounty_target.dart';
import 'package:vowl/features/photo_vocabulary/presentation/widgets/photo_empty_state.dart';
import 'package:vowl/features/photo_vocabulary/presentation/widgets/photo_result_chip.dart';

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

  group('Photo Vocabulary Widget Tests', () {
    testWidgets('PhotoBountyTarget renders correctly without overflow on small screens',
        (tester) async {
      bool shuffled = false;

      await tester.pumpWidget(
        _wrap(
          PhotoBountyTarget(
            currentBounty: 'Extremely Long Vocabulary Target Object Name For Test',
            bountyFound: false,
            dailyCount: 1,
            dailyLimit: 3,
            onShuffle: () => shuffled = true,
          ),
          size: const Size(320, 568), // Small screen (iPhone SE 1st gen)
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Extremely Long Vocabulary Target Object Name For Test'),
        findsOneWidget,
      );
      expect(find.textContaining('Today: 1/3 found'), findsOneWidget);

      final shuffleFinder = find.byIcon(LucideIcons.shuffle);
      expect(shuffleFinder, findsOneWidget);
      await tester.tap(shuffleFinder);
      expect(shuffled, isTrue);

      // Verify tapping (i) button opens explanation dialog
      final infoFinder = find.byIcon(Icons.info_outline_rounded);
      expect(infoFinder, findsOneWidget);
      await tester.tap(infoFinder);
      await tester.pumpAndSettle();

      expect(find.text('HOW OBJECT BOUNTIES WORK'), findsOneWidget);
      expect(find.text('GOT IT!'), findsOneWidget);

      final closeFinder = find.byIcon(Icons.close_rounded);
      expect(closeFinder, findsOneWidget);
      await tester.tap(closeFinder);
      await tester.pumpAndSettle();
      expect(find.text('HOW OBJECT BOUNTIES WORK'), findsNothing);
    });

    testWidgets('PhotoResultChip renders word, IPA, definition, example without clipping',
        (tester) async {
      final label = ImageLabel(
        label: 'Coffee cup',
        confidence: 0.94,
        index: 0,
      );

      bool pronunciationCalled = false;
      bool savedToggled = false;

      await tester.pumpWidget(
        _wrap(
          PhotoResultChip(
            label: label,
            index: 0,
            isBountyTarget: true,
            isSaved: false,
            translatedText: 'Taza de café\n\nÉl dejó su taza de café en el platillo.',
            isTranslating: false,
            onTranslate: (idx, txt) {},
            onPlayPronunciation: (txt) => pronunciationCalled = true,
            onToggleSave: (word) => savedToggled = true,
          ),
          size: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Coffee cup'), findsOneWidget);
      expect(find.text('Taza de café'), findsOneWidget);
      expect(find.text('DAILY BOUNTY TARGET'), findsOneWidget);
      expect(find.text('94%'), findsOneWidget);

      final audioFinder = find.bySemanticsLabel('Listen to pronunciation for Coffee cup');
      expect(audioFinder, findsOneWidget);
      await tester.tap(audioFinder);
      expect(pronunciationCalled, isTrue);

      final starFinder = find.bySemanticsLabel('Save Coffee cup to Vocab Notebook');
      expect(starFinder, findsOneWidget);
      await tester.tap(starFinder);
      expect(savedToggled, isTrue);
    });

    testWidgets('PhotoEmptyState renders without overflow on ultra-short screen',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          PhotoEmptyState(onPickImage: (_) async {}),
          size: const Size(320, 480), // Ultra short height
          disableAnimations: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Photo Vocabulary'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
