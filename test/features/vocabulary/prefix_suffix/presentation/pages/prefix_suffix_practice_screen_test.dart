import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/pages/prefix_suffix_practice_screen.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_clue_banner.dart';

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
    when(() => mockHapticService.error()).thenAnswer((_) async {});

    when(
      () => mockSoundService.playCorrect(comboStep: any(named: 'comboStep')),
    ).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockTtsService.preWarm(
        locale: any(named: 'locale'),
        preset: any(named: 'preset'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockTtsService.isSpeakingNotifier,
    ).thenReturn(ValueNotifier<bool>(false));

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

  group('PrefixSuffixPracticeScreen', () {
    testWidgets(
      'renders vault clue banner and cracks combination on correct chip',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844) * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestableWidget(const PrefixSuffixPracticeScreen(level: 1)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PrefixSuffixPracticeScreen), findsOneWidget);
        expect(find.byType(PrefixSuffixClueBanner), findsOneWidget);
        expect(find.text('Find the missing affix'), findsOneWidget);

        // Verify incorrect choice triggers jammed feedback
        final wrongOption = find.text('RE-');
        if (wrongOption.evaluate().isNotEmpty) {
          await tester.tap(wrongOption.first);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.text('Not quite — try again'), findsOneWidget);
        }

        // Tap correct choice
        final correctOption = find.text('PRE-');
        expect(correctOption, findsWidgets);
        await tester.tap(correctOption.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Vault is unlatched
        expect(find.text('Unlocked!'), findsOneWidget);
        expect(find.text('Word unlocked! Great job.'), findsOneWidget);

        // Hint trigger
        final hintButton = find.text('Need a hint?');
        if (hintButton.evaluate().isNotEmpty) {
          await tester.tap(hintButton);
          await tester.pump();
        }
      },
    );
  });
}
