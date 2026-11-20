import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/game_error_view.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_screen.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_action_buttons.dart';
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
    when(() => mockTtsService.speak(any())).thenAnswer((_) async {});
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.playCorrect(comboStep: any(named: 'comboStep')))
        .thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});

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
      'has_seen_briefing_flashcards': true,
    });

    mockVocabBloc = MockVocabularyBloc();
    mockAuthBloc = MockAuthBloc();

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'user_1',
          email: 'test@vowl.app',
          displayName: 'Learner',
          vowlMascot: 'vowl_prime',
        ),
      ),
    );
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  const testQuest1 = VocabularyQuest(
    id: 'VOC_FC_L1_Q1',
    instruction: 'CHOOSE THE CORRECT MEANING',
    difficulty: 1,
    subtype: GameSubtype.flashcards,
    word: 'HELLO',
    definition: 'A common greeting used when meeting someone.',
    hint: 'First word when answering the phone.',
    contextSentence: 'Hello, how are you today?',
    topicEmoji: '👋',
  );

  Future<void> pumpFlashcards(
    WidgetTester tester, {
    VocabularyState? state,
    int level = 2,
    double width = 390,
    double height = 844,
  }) async {
    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (state != null) {
      when(() => mockVocabBloc.state).thenReturn(state);
    }

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
            home: FlashcardsScreen(level: level),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('FlashcardsScreen Layout & Interaction', () {
    testWidgets('shows GameShimmerLoading during loading state', (tester) async {
      await pumpFlashcards(tester, state: const VocabularyLoading());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('shows GameErrorView on error state with working retry',
        (tester) async {
      await pumpFlashcards(
        tester,
        state: const VocabularyError('Network error loading flashcards'),
      );

      expect(find.byType(GameErrorView), findsOneWidget);
      expect(find.text('Network error loading flashcards'), findsOneWidget);

      final retryButton = find.byType(ScaleButton).first;
      expect(retryButton, findsOneWidget);
      await tester.tap(retryButton);
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockVocabBloc.add(any(that: isA<FetchVocabularyQuests>())))
          .called(2);
    });

    testWidgets(
        'renders front card, flips to back face, and submits mastery with Got It',
        (tester) async {
      await pumpFlashcards(
        tester,
        state: const VocabularyLoaded(
          quests: [testQuest1],
          currentIndex: 0,
          livesRemaining: 3,
        ),
      );

      expect(find.byType(FlashcardGameBody), findsOneWidget);
      expect(find.byType(FlashcardSwipeFront), findsOneWidget);
      expect(find.text('First word when answering the phone.'), findsOneWidget);

      // Tap card stack to flip
      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Back face is revealed
      expect(find.byType(FlashcardSwipeBack), findsOneWidget);
      expect(find.text('HELLO'), findsOneWidget);
      expect(
        find.text('A common greeting used when meeting someone.'),
        findsOneWidget,
      );

      // Action buttons now show Again and Got It
      expect(find.byType(FlashcardActionButtons), findsOneWidget);
      final gotItFinder = find.text('Got It');
      expect(gotItFinder, findsOneWidget);

      await tester.tap(gotItFinder);
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockVocabBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('submits review needed when tapping Again on flipped card',
        (tester) async {
      await pumpFlashcards(
        tester,
        state: const VocabularyLoaded(
          quests: [testQuest1],
          currentIndex: 0,
          livesRemaining: 3,
        ),
      );

      // Tap card stack to flip
      await tester.tap(find.byType(FlashcardSwipeFront));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final againFinder = find.text('Again');
      expect(againFinder, findsOneWidget);

      await tester.tap(againFinder);
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockVocabBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('renders cleanly on 320x568 small screen', (tester) async {
      await pumpFlashcards(
        tester,
        state: const VocabularyLoaded(
          quests: [testQuest1],
          currentIndex: 0,
          livesRemaining: 3,
        ),
        width: 320,
        height: 568,
      );

      expect(find.byType(FlashcardsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on 430x932 large screen', (tester) async {
      await pumpFlashcards(
        tester,
        state: const VocabularyLoaded(
          quests: [testQuest1],
          currentIndex: 0,
          livesRemaining: 3,
        ),
        width: 430,
        height: 932,
      );

      expect(find.byType(FlashcardsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
