import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_learn_screen.dart';

class MockHapticService extends Mock implements HapticService {}

class MockTtsService extends Mock implements TtsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHaptic;
  late MockTtsService mockTts;

  setUp(() {
    mockHaptic = MockHapticService();
    mockTts = MockTtsService();

    when(() => mockHaptic.selection()).thenAnswer((_) async {});
    when(() => mockHaptic.light()).thenAnswer((_) async {});
    when(() => mockTts.speak(any())).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }

    di.sl.registerLazySingleton<HapticService>(() => mockHaptic);
    di.sl.registerLazySingleton<TtsService>(() => mockTts);
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(home: child),
    );
  }

  group('FlashcardsLearnScreen', () {
    testWidgets('renders word, phonetic IPA, syllable chips, and flips card', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(const FlashcardsLearnScreen(level: 1)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FlashcardsLearnScreen), findsOneWidget);
      expect(find.text('AUTHENTIC'), findsWidgets);
      expect(find.text('Flip for Meaning & Context'), findsOneWidget);

      // Verify tap-to-speak syllable chips
      expect(find.text('THEN'), findsOneWidget);
      await tester.tap(find.text('THEN'));
      await tester.pump();
      verify(() => mockTts.speak('then')).called(1);
      await tester.pump(const Duration(milliseconds: 1500));

      // Tap full audio button
      expect(find.text('Tap for Full Audio'), findsOneWidget);
      await tester.tap(find.text('Tap for Full Audio'));
      await tester.pump();
      verify(() => mockTts.speak('AUTHENTIC')).called(1);
      await tester.pump(const Duration(milliseconds: 1500));

      // Flip the card
      await tester.tap(find.text('Flip for Meaning & Context'));
      await tester.pumpAndSettle();

      expect(find.text('NATURAL COLLOCATIONS'), findsOneWidget);
      expect(find.text('Front'), findsOneWidget);
    });
  });
}
