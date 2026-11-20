import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/game_error_view.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
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
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

class MockVocabularyBloc extends MockBloc<VocabularyEvent, VocabularyState>
    implements VocabularyBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockTtsService extends Mock implements TtsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockVocabularyBloc mockVocabularyBloc;
  late MockAuthBloc mockAuthBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late StreamController<VocabularyState> vocabularyStreamController;

  const testQuest = VocabularyQuest(
    id: 'VOC_FLASHCARDS_L1_Q1',
    type: QuestType.vocabulary,
    subtype: GameSubtype.flashcards,
    word: 'HELLO',
    correctAnswer:
        'A common greeting used when meeting someone or starting a conversation.',
    definition:
        'A common greeting used when meeting someone or starting a conversation.',
    contextSentence:
        'Hello, I am calling about the apartment you listed online.',
    topicEmoji: '👋',
    instruction: 'CHOOSE THE CORRECT MEANING',
    hint: 'The first word out of your mouth when you answer the phone.',
    explanation: 'Hello is the safest, most neutral greeting in English.',
    difficulty: 1,
  );

  const testLoadedState = VocabularyLoaded(
    quests: [testQuest],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const NextQuestion());
  });

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_flashcards': true,
    });
    mockVocabularyBloc = MockVocabularyBloc();
    mockAuthBloc = MockAuthBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    vocabularyStreamController = StreamController<VocabularyState>.broadcast();

    when(
      () => mockVocabularyBloc.stream,
    ).thenAnswer((_) => vocabularyStreamController.stream);
    when(() => mockVocabularyBloc.state).thenReturn(testLoadedState);
    whenListen(
      mockVocabularyBloc,
      vocabularyStreamController.stream,
      initialState: testLoadedState,
    );

    const testUser = UserEntity(
      id: 'test_user',
      email: 'test@vowl.app',
      vowlMascot: 'vowl_prime',
    );
    when(
      () => mockAuthBloc.state,
    ).thenReturn(AuthState.authenticated(testUser));
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(
      () => mockSoundService.playCorrect(comboStep: any(named: 'comboStep')),
    ).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockTtsService.speak(any())).thenAnswer((_) async {});
    when(() => mockTtsService.stop()).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    vocabularyStreamController.close();
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MultiBlocProvider(
        providers: [
          BlocProvider<VocabularyBloc>.value(value: mockVocabularyBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: MaterialApp(home: child),
      ),
    );
  }

  group('FlashcardsMasteryScreen Widget Tests', () {
    testWidgets('renders shimmer loading when in VocabularyLoading state', (
      tester,
    ) async {
      when(
        () => mockVocabularyBloc.state,
      ).thenReturn(const VocabularyLoading());

      await tester.pumpWidget(
        buildTestableWidget(const FlashcardsMasteryScreen(level: 1)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('renders error view when in VocabularyError state', (
      tester,
    ) async {
      when(
        () => mockVocabularyBloc.state,
      ).thenReturn(const VocabularyError('Failed to load flashcards.'));

      await tester.pumpWidget(
        buildTestableWidget(const FlashcardsMasteryScreen(level: 1)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GameErrorView), findsOneWidget);
      expect(find.text('Failed to load flashcards.'), findsOneWidget);
    });

    testWidgets('renders flashcard front face and flips to reveal back face', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableWidget(const FlashcardsMasteryScreen(level: 2)),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(FlashcardGameBody), findsOneWidget);
      expect(find.text('Clue'), findsOneWidget);

      // Tap card to flip
      final cardDetector = find.byKey(
        const Key('flashcard_card_gesture_detector'),
      );
      expect(cardDetector, findsOneWidget);
      await tester.tap(cardDetector);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Back face shows action buttons (Again & Got It)
      expect(find.text('Again'), findsOneWidget);
      expect(find.text('Got It'), findsOneWidget);

      // Tap Got It to submit mastery
      await tester.tap(find.text('Got It'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));

      verify(
        () => mockVocabularyBloc.add(any(that: isA<SubmitAnswer>())),
      ).called(1);
    });
  });
}
