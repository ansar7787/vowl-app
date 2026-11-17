import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/pages/word_formation_learn_screen.dart';

class MockTtsService extends Mock implements TtsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTtsService mockTtsService;

  setUp(() async {
    mockTtsService = MockTtsService();
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    await di.sl.reset();
    di.sl.registerSingleton<TtsService>(mockTtsService);
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: child,
        ),
      ),
    );
  }

  group('WordFormationLearnScreen', () {
    testWidgets(
        'renders base root hub, morphological formation, family tree, interactive affix tryout, and advances',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          const WordFormationLearnScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WordFormationLearnScreen), findsOneWidget);
      expect(find.text('MORPHOLOGICAL FORMATION'), findsOneWidget);
      expect(find.text('WORD FAMILY TREE'), findsOneWidget);
      expect(find.text('INTERACTIVE AFFIX FUSION TRYOUT'), findsOneWidget);

      // Tap an affix chip to test interactive fusion
      final affixChip = find.text('-FUL');
      expect(affixChip, findsWidgets);
      await tester.ensureVisible(affixChip.first);
      await tester.tap(affixChip.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Advance to next root
      final nextButton = find.textContaining('Next Root');
      expect(nextButton, findsOneWidget);
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
