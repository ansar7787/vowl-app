import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_mastery_screen.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_game_body.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_swipe_back.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_swipe_front.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

class MockVocabularyBloc extends MockBloc<VocabularyEvent, VocabularyState>
    implements VocabularyBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockTtsService extends Mock implements TtsService {}

class MockSoundService extends Mock implements SoundService {}

class FakeVocabularyEvent extends Fake implements VocabularyEvent {}

class FakeVocabularyState extends Fake implements VocabularyState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockVocabularyBloc mockVocabBloc;
  late MockAuthBloc mockAuthBloc;
  late MockHapticService mockHapticService;
  late MockTtsService mockTtsService;
  late MockSoundService mockSoundService;

  const testQuest = VocabularyQuest(
    id: 'VOC_FLASHCARDS_L1_Q1',
    instruction: 'CHOOSE THE CORRECT MEANING',
    difficulty: 1,
    subtype: GameSubtype.flashcards,
    word: 'HELLO',
    definition: 'A common greeting used when meeting someone.',
    contextSentence: "Hello, I'm calling about the apartment.",
    topicEmoji: '👋',
    hint: 'First word out of your mouth on the phone.',
  );

  setUpAll(() {
    registerFallbackValue(FakeVocabularyEvent());
    registerFallbackValue(FakeVocabularyState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const VocabularyHintUsed());

    mockHapticService = MockHapticService();
    mockTtsService = MockTtsService();
    mockSoundService = MockSoundService();

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.rhythmicTick()).thenAnswer((_) async {});

    when(() => mockTtsService.speak(any())).thenAnswer((_) async {});
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    di.sl.registerSingleton<TtsService>(mockTtsService);

    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
    di.sl.registerSingleton<SoundService>(mockSoundService);
  });

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({
      'haptics_enabled': true,
      'has_seen_briefing_flashcards': true,
    });

    mockVocabBloc = MockVocabularyBloc();
    mockAuthBloc = MockAuthBloc();

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user',
          email: 'test@vowl.app',
          displayName: 'Tester',
          vowlMascot: 'vowl_prime',
        ),
      ),
    );
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  tearDownAll(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  Future<void> pumpMastery(
    WidgetTester tester, {
    VocabularyState? state,
    int level = 2,
    double width = 390,
    double height = 844,
  }) async {
    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.devicePixelRatio = 2.0;

    when(() => mockVocabBloc.state).thenReturn(
      state ??
          const VocabularyLoaded(
            quests: [testQuest],
            currentIndex: 0,
            livesRemaining: 3,
          ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<VocabularyBloc>.value(value: mockVocabBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) => MaterialApp(
            home: Scaffold(
              body: FlashcardsMasteryScreen(level: level),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('FlashcardsMasteryScreen', () {
    test('is a type alias of FlashcardsScreen', () {
      const widget = FlashcardsMasteryScreen(level: 1);
      expect(widget, isA<FlashcardsScreen>());
      expect(widget.level, equals(1));
    });

    testWidgets(
      'renders front clue, flips to definition, and handles answer submissions',
      (tester) async {
        await pumpMastery(tester);

        // Verifies game body and front card
        expect(find.byType(FlashcardGameBody), findsOneWidget);
        expect(find.byType(FlashcardSwipeFront), findsOneWidget);

        // Tap card to flip
        await tester.tap(find.byType(FlashcardSwipeFront), warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(FlashcardSwipeBack), findsOneWidget);
        expect(find.text('HELLO'), findsOneWidget);

        // Tap "Got It" to submit mastered answer
        final gotItBtn = find.text('Got It');
        expect(gotItBtn, findsOneWidget);
        await tester.tap(gotItBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        verify(() => mockVocabBloc.add(any(that: isA<SubmitAnswer>()))).called(1);
      },
    );
  });
}
