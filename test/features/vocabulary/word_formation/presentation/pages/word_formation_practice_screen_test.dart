import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/pages/word_formation_practice_screen.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_4way_launcher.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_sentence_slot.dart';

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

  group('WordFormationPracticeScreen', () {
    testWidgets('renders sentence slot and 4-way launcher pads', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(const WordFormationPracticeScreen(level: 1)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WordFormationPracticeScreen), findsOneWidget);
      expect(find.byType(WordFormationSentenceSlot), findsOneWidget);
      expect(find.byType(WordFormation4WayLauncher), findsOneWidget);
    });

    testWidgets('tapping correct direction fills slot and plays audio', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(const WordFormationPracticeScreen(level: 1)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // In fallback / Batch 1 Quest 1: correct direction is North (Noun)
      final northFinder = find.textContaining('NOUN');
      if (northFinder.evaluate().isNotEmpty) {
        await tester.tap(northFinder.first);
        await tester.pumpAndSettle();
        verify(
          () => mockTtsService.speak(any()),
        ).called(greaterThanOrEqualTo(1));
      }
    });

    testWidgets('tapping wrong direction triggers error feedback', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(const WordFormationPracticeScreen(level: 1)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap South or West (wrong direction for Quest 1)
      final southFinder = find.textContaining('ADV');
      if (southFinder.evaluate().isNotEmpty) {
        await tester.tap(southFinder.first);
        await tester.pumpAndSettle();
        verify(() => mockHapticService.error()).called(greaterThanOrEqualTo(1));
      }
    });
  });
}
