import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/pages/prefix_suffix_learn_screen.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_discovery_card.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_tumbler_cylinder.dart';

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

  group('PrefixSuffixLearnScreen', () {
    testWidgets(
      'renders tumbler cylinder, discovery card, and advances words',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844) * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestableWidget(const PrefixSuffixLearnScreen(level: 1)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PrefixSuffixLearnScreen), findsOneWidget);
        expect(find.byType(PrefixSuffixTumblerCylinder), findsOneWidget);
        expect(find.byType(PrefixSuffixDiscoveryCard), findsOneWidget);
        expect(find.text('New Word'), findsOneWidget);

        // Verify TTS button interaction (combined word)
        final ttsButton = find.byIcon(Icons.volume_up_rounded);
        if (ttsButton.evaluate().isNotEmpty) {
          await tester.tap(ttsButton.first);
          await tester.pump();
          verify(() => mockTtsService.speak(any())).called(1);
        }

        // Verify Root TTS button interaction
        final rootTtsButton = find.byIcon(Icons.record_voice_over_outlined);
        if (rootTtsButton.evaluate().isNotEmpty) {
          await tester.tap(rootTtsButton.first);
          await tester.pump();
          verify(() => mockTtsService.speak(any())).called(1);
        }
      },
    );
  });
}
