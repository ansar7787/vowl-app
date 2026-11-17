import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/pages/contextual_usage_practice_screen.dart';

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockTtsService extends Mock implements TtsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;

  setUp(() async {
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    await di.sl.reset();
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
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

  group('ContextualUsagePracticeScreen', () {
    testWidgets(
        'renders Drill 1 context fit, Drill 2 register calibration, and advances',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          const ContextualUsagePracticeScreen(level: 1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ContextualUsagePracticeScreen), findsOneWidget);
      expect(find.text('DRILL 1: CONTEXT FIT'), findsOneWidget);

      // Tap BORROW option chip
      final borrowChip = find.text('BORROW');
      expect(borrowChip, findsWidgets);
      await tester.ensureVisible(borrowChip.first);
      await tester.tap(borrowChip.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Drill 2 is now active
      expect(find.text('DRILL 2: REGISTER CALIBRATION'), findsOneWidget);

      // Tap Casual / Everyday register option
      final casualTile = find.text('Casual / Everyday');
      expect(casualTile, findsOneWidget);
      await tester.ensureVisible(casualTile);
      await tester.tap(casualTile, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Continue button should now be enabled
      final continueButton = find.textContaining('Next Practice Quest');
      expect(continueButton, findsOneWidget);
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
