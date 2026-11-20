import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_screen.dart';

class MockVocabularyBloc extends MockBloc<VocabularyEvent, VocabularyState>
    implements VocabularyBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockTtsService extends Mock implements TtsService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAdService extends Mock implements AdService {}

class FakeVocabularyEvent extends Fake implements VocabularyEvent {}

class FakeVocabularyState extends Fake implements VocabularyState {}

class FakeEconomyEvent extends Fake implements EconomyEvent {}

class FakeEconomyState extends Fake implements EconomyState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockVocabularyBloc mockVocabBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHaptic;
  late MockSoundService mockSound;
  late MockTtsService mockTts;
  late MockLocaleService mockLocale;
  late StreamController<VocabularyState> vocabStreamController;

  const testQuest = VocabularyQuest(
    id: 'VOC_FLASHCARDS_L2_MAST_Q1',
    word: 'AUTHENTIC',
    definition: 'Genuine, real, and true to original traditions.',
    contextSentence:
        'The museum verified that the ancient artifact was completely _____.',
    collocations: ['authentic cuisine', 'authentic leadership'],
    wrongCollocations: ['authentic weather', 'authentic price'],
    options: ['authentic', 'authoritarian', 'automatic'],
    correctAnswer: 'authentic',
    correctAnswerIndex: 0,
    difficulty: 2,
    topicEmoji: '📜',
    instruction: 'Slam the natural collocation before the fuse burns down!',
  );

  setUpAll(() {
    registerFallbackValue(FakeVocabularyEvent());
    registerFallbackValue(FakeVocabularyState());
    registerFallbackValue(FakeEconomyEvent());
    registerFallbackValue(FakeEconomyState());
    registerFallbackValue(const SubmitAnswer(true));
  });

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_flashcards': true,
    });
    await di.sl.reset();

    mockVocabBloc = MockVocabularyBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHaptic = MockHapticService();
    mockSound = MockSoundService();
    mockTts = MockTtsService();
    mockLocale = MockLocaleService();
    vocabStreamController = StreamController<VocabularyState>.broadcast();

    const testLoadedState = VocabularyLoaded(
      quests: [testQuest],
      currentIndex: 0,
      livesRemaining: 3,
    );
    when(() => mockVocabBloc.state).thenReturn(testLoadedState);
    whenListen(
      mockVocabBloc,
      vocabStreamController.stream,
      initialState: testLoadedState,
    );

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'user_1',
          email: 'test@vowl.app',
          displayName: 'Test Learner',
          hintCount: 3,
        ),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockHaptic.selection()).thenAnswer((_) async {});
    when(() => mockHaptic.success()).thenAnswer((_) async {});
    when(() => mockHaptic.error()).thenAnswer((_) async {});
    when(() => mockHaptic.light()).thenAnswer((_) async {});
    when(() => mockHaptic.heavy()).thenAnswer((_) async {});
    when(() => mockHaptic.warning()).thenAnswer((_) async {});

    when(() => mockTts.speak(any())).thenAnswer((_) async {});
    when(() => mockTts.stop()).thenAnswer((_) async {});
    when(() => mockSound.stopAudio()).thenAnswer((_) async {});
    when(() => mockSound.stopTts()).thenAnswer((_) async {});
    when(
      () => mockSound.playCorrect(comboStep: any(named: 'comboStep')),
    ).thenAnswer((_) async {});
    when(() => mockSound.playCorrect()).thenAnswer((_) async {});
    when(() => mockSound.playWrong()).thenAnswer((_) async {});

    when(
      () => mockLocale.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (inv) =>
          inv.namedArguments[#fallback] as String? ??
          inv.positionalArguments.first as String,
    );

    di.sl.registerSingleton<HapticService>(mockHaptic);
    di.sl.registerSingleton<SoundService>(mockSound);
    di.sl.registerSingleton<TtsService>(mockTts);
    di.sl.registerSingleton<LocaleService>(mockLocale);
    di.sl.registerSingleton<AnalyticsService>(MockAnalyticsService());
    di.sl.registerSingleton<AdService>(MockAdService());
    di.sl.registerSingleton<AppLogger>(MockAppLogger());
  });

  tearDown(() async {
    await vocabStreamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<VocabularyBloc>.value(value: mockVocabBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: MediaQueryData(size: size, disableAnimations: true),
              child: const Scaffold(body: FlashcardsScreen(level: 2)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('FlashcardsScreen Mastery', () {
    testWidgets(
      'renders speed fuse, target word, and Stage 1 collocation slam',
      (tester) async {
        await pumpScreen(tester);

        expect(find.byType(FlashcardsScreen), findsOneWidget);
        expect(find.text('SPEED FUSE'), findsOneWidget);
        expect(find.text('AUTHENTIC'), findsWidgets);
        expect(
          find.text('STAGE 1: SLAM THE AUTHENTIC COLLOCATION'),
          findsOneWidget,
        );
        expect(find.text('authentic cuisine'), findsOneWidget);
        expect(find.text('authentic weather'), findsOneWidget);

        // Tap authentic cuisine
        await tester.tap(find.text('authentic cuisine'));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        // Should advance to Stage 2 Precision Strike
        expect(find.text('STAGE 2: PRECISION SENTENCE STRIKE'), findsOneWidget);
        expect(find.text('AUTHENTIC'), findsWidgets);

        // Strike candidate word via dedicated key
        expect(find.byKey(const ValueKey('candidate_0')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('candidate_0')));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        verify(() => mockHaptic.success()).called(2);
      },
    );
  });
}
