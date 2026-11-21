import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speech_to_text/speech_to_text.dart' show ListenMode;
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_learn_screen.dart';

class MockHapticService extends Mock implements HapticService {}

class MockTtsService extends Mock implements TtsService {}

class MockSpeechService extends Mock implements SpeechService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(ListenMode.dictation);
    registerFallbackValue((List<String> _, bool _) {});
    registerFallbackValue(() {});
  });

  late MockHapticService mockHaptic;
  late MockTtsService mockTts;
  late MockSpeechService mockSpeech;

  setUp(() {
    mockHaptic = MockHapticService();
    mockTts = MockTtsService();
    mockSpeech = MockSpeechService();

    when(() => mockHaptic.selection()).thenAnswer((_) async {});
    when(() => mockHaptic.light()).thenAnswer((_) async {});
    when(() => mockHaptic.success()).thenAnswer((_) async {});
    when(
      () => mockTts.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
        pauseMarkers: any(named: 'pauseMarkers'),
        forcedPreset: any(named: 'forcedPreset'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockTts.engineStatus).thenReturn(TtsEngineStatus.ready);

    when(() => mockSpeech.initializeStt()).thenAnswer((_) async => true);
    when(() => mockSpeech.isListening).thenReturn(false);
    when(() => mockSpeech.stop()).thenAnswer((_) async {});
    when(
      () => mockSpeech.listen(
        onResult: any(named: 'onResult'),
        onDone: any(named: 'onDone'),
        onSoundLevelChange: any(named: 'onSoundLevelChange'),
        localeId: any(named: 'localeId'),
        pauseFor: any(named: 'pauseFor'),
        listenMode: any(named: 'listenMode'),
      ),
    ).thenAnswer((invocation) async {
      final onResult =
          invocation.namedArguments[#onResult] as SpeechResultCallback?;
      onResult?.call(['AUTHENTIC'], true);
    });

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    if (di.sl.isRegistered<SpeechService>()) {
      di.sl.unregister<SpeechService>();
    }

    di.sl.registerLazySingleton<HapticService>(() => mockHaptic);
    di.sl.registerLazySingleton<TtsService>(() => mockTts);
    di.sl.registerLazySingleton<SpeechService>(() => mockSpeech);
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    if (di.sl.isRegistered<SpeechService>()) {
      di.sl.unregister<SpeechService>();
    }
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(home: child),
    );
  }

  group('FlashcardsLearnScreen', () {
    testWidgets(
      'renders word, phonetic IPA, syllable chips, verifies echo, flips card, and opens nuance matrix',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(const FlashcardsLearnScreen(level: 1)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(FlashcardsLearnScreen), findsOneWidget);
        expect(find.text('AUTHENTIC'), findsWidgets);
        expect(find.text('Compare Words'), findsOneWidget);
        expect(find.text('Tap to Flip'), findsOneWidget);
        expect(find.text('3D DECK'), findsNothing);
        expect(find.text('Flip for Meaning & Context'), findsOneWidget);

        // Verify tap-to-speak syllable chips
        expect(find.text('THEN'), findsOneWidget);
        await tester.tap(find.text('THEN'));
        await tester.pump();
        verify(() => mockTts.speak('THEN', rate: any(named: 'rate'))).called(1);
        await tester.pump(const Duration(milliseconds: 1500));

        // Tap full audio button
        expect(find.byKey(const ValueKey('btn_full_audio')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('btn_full_audio')));
        await tester.pump();
        verify(() => mockTts.speak('AUTHENTIC', rate: any(named: 'rate'))).called(1);
        await tester.pump(const Duration(milliseconds: 1500));

        // Tap Practice Speaking button
        expect(find.text('Practice Speaking'), findsOneWidget);
        await tester.ensureVisible(find.text('Practice Speaking'));
        await tester.tap(find.text('Practice Speaking'));
        await tester.pumpAndSettle();
        expect(find.text('Pronunciation Verified ✓'), findsOneWidget);

        // Flip the card to back face by tapping the Tap to Flip badge or card body
        await tester.ensureVisible(find.text('Tap to Flip'));
        await tester.tap(find.text('Tap to Flip'));
        await tester.pumpAndSettle();

        expect(find.text('NATURAL COLLOCATIONS'), findsOneWidget);
        expect(find.text('Front'), findsOneWidget);

        // Flip back to front face
        await tester.ensureVisible(find.text('Front'));
        await tester.tap(find.text('Front'));
        await tester.pumpAndSettle();
        expect(find.text('Flip for Meaning & Context'), findsOneWidget);

        // Verify horizontal swipe navigation between cards in cluster
        // Swipe Left: transitions from Word 1 (AUTHENTIC) to Word 2 (GENUINE)
        await tester.fling(
          find.text('AUTHENTIC').first,
          const Offset(-300, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.text('GENUINE'), findsWidgets);

        // Swipe Right: transitions back from Word 2 (GENUINE) to Word 1 (AUTHENTIC)
        await tester.fling(
          find.text('GENUINE').first,
          const Offset(300, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.text('AUTHENTIC'), findsWidgets);

        // Tap "Compare Words" to view the Nuance Duel / Cluster Contrast Matrix
        await tester.ensureVisible(find.text('Compare Words'));
        await tester.tap(find.text('Compare Words'));
        await tester.pumpAndSettle();

        expect(find.text('HOW TO CHOOSE'), findsOneWidget);
        expect(find.text('Word Usage Distinction'), findsOneWidget);
        expect(find.text('Start Guided Practice'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsWidgets);
        expect(find.text('Cards'), findsOneWidget);

        // Toggle back to individual card view via "Cards" button
        await tester.ensureVisible(find.text('Cards'));
        await tester.tap(find.text('Cards'));
        await tester.pumpAndSettle();
        expect(find.text('AUTHENTIC'), findsWidgets);

        // Re-open "Compare Words" and verify swiping right returns to cards
        await tester.ensureVisible(find.text('Compare Words'));
        await tester.tap(find.text('Compare Words'));
        await tester.pumpAndSettle();
        expect(find.text('HOW TO CHOOSE'), findsOneWidget);

        // Swipe right on contrast matrix to return to cards
        await tester.fling(
          find.text('HOW TO CHOOSE'),
          const Offset(300, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.text('AUTHENTIC'), findsWidgets);
      },
    );

    testWidgets(
      'requires card flip before advancing and dynamically switches button label to Next Word',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(const FlashcardsLearnScreen(level: 1)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Initial state: Card is on front face (AUTHENTIC)
        expect(find.text('AUTHENTIC'), findsWidgets);
        expect(find.text('Flip Card to Continue'), findsOneWidget);
        expect(find.text('Next Word'), findsNothing);

        // Attempting to advance via bottom button when not flipped: flips card to back face
        await tester.ensureVisible(find.text('Flip Card to Continue'));
        await tester.tap(find.text('Flip Card to Continue'));
        await tester.pumpAndSettle();

        // Card is now flipped to back face (revealing collocations & context)
        expect(find.text('NATURAL COLLOCATIONS'), findsOneWidget);
        expect(find.text('Next Word'), findsOneWidget);
        expect(find.text('Flip Card to Continue'), findsNothing);

        // Now that the card has been flipped, tapping Next Word advances to Word 2 (GENUINE)
        await tester.ensureVisible(find.text('Next Word'));
        await tester.tap(find.text('Next Word'));
        await tester.pumpAndSettle();

        expect(find.text('GENUINE'), findsWidgets);
        // On Word 2, button resets to "Flip Card to Continue" to enforce pedagogy
        expect(find.text('Flip Card to Continue'), findsOneWidget);
        expect(find.text('Next Word'), findsNothing);

        // Swiping left without flipping Word 2 flips it to back face instead of skipping to Word 3
        await tester.fling(
          find.text('GENUINE').first,
          const Offset(-300, 0),
          1000,
        );
        await tester.pumpAndSettle();

        // Word 2 is now on back face, not skipped!
        expect(find.text('NATURAL COLLOCATIONS'), findsOneWidget);
        expect(find.text('Next Word'), findsOneWidget);
      },
    );
  });
}
