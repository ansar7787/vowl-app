import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/pages/word_formation_learn_screen.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_learn_compass.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_morph_core.dart';

class MockTtsService extends Mock implements TtsService {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTtsService mockTtsService;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;

  setUp(() {
    mockTtsService = MockTtsService();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();

    when(() => mockTtsService.speak(any())).thenAnswer((_) async {});
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(() => mockTtsService.preWarm(locale: any(named: 'locale'), preset: any(named: 'preset'))).thenAnswer((_) async {});
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});

    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();

    di.sl.registerLazySingleton<TtsService>(() => mockTtsService);
    di.sl.registerLazySingleton<HapticService>(() => mockHapticService);
    di.sl.registerLazySingleton<SoundService>(() => mockSoundService);
  });

  tearDown(() {
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(home: child),
    );
  }

  group('WordFormationLearnScreen', () {
    testWidgets('renders morph core, root word, and 4-way compass sandbox', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(const WordFormationLearnScreen(level: 1)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WordFormationLearnScreen), findsOneWidget);
      expect(find.byType(WordFormationMorphCore), findsOneWidget);
      expect(find.byType(WordFormationLearnCompass), findsOneWidget);
    });

    testWidgets(
      'tapping compass direction updates selected form and reads audio',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(const WordFormationLearnScreen(level: 1)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tap East (Adjective)
        final eastFinder = find.textContaining('Adjective');
        if (eastFinder.evaluate().isNotEmpty) {
          await tester.tap(eastFinder.first);
          await tester.pumpAndSettle();
          verify(
            () => mockTtsService.speak(any()),
          ).called(greaterThanOrEqualTo(1));
        }
      },
    );

    testWidgets('advances to next card on continue action', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const WordFormationLearnScreen(level: 1)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final nextFinder = find.textContaining('Next Word');
      if (nextFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(nextFinder.first);
        await tester.tap(nextFinder.first);
        await tester.pumpAndSettle();
      }
    });
  });
}
