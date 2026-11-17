import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/game_mechanics/arranging/context_sentence_builder.dart';
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
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/pages/phrasal_verbs_mastery_screen.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_literal_comparison.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_option_key.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

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

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeVocabularyEvent extends Fake implements VocabularyEvent {}

class FakeVocabularyState extends Fake implements VocabularyState {}

class FakeEconomyEvent extends Fake implements EconomyEvent {}

class FakeEconomyState extends Fake implements EconomyState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({
    'has_seen_briefing_phrasalVerbs': true,
  });

  late MockVocabularyBloc mockVocabularyBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<VocabularyState> vocabularyStreamController;

  const testQuest = VocabularyQuest(
    id: 'VOC_PHRASALVERBS_L1_Q1',
    type: QuestType.vocabulary,
    subtype: GameSubtype.phrasalVerbs,
    word: 'call',
    correctAnswer: 'off',
    options: ['off', 'out', 'up', 'on'],
    instruction: 'Select the correct particle to complete the phrasal verb.',
    hint: 'To cancel an event.',
    explanation: "'Call off' means to cancel a planned event.",
    literalVsFigurative:
        'Literal: To shout away. Figurative: To cancel a planned event.',
    contextSentence: 'They decided to call __ the concert due to heavy rain.',
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
    registerFallbackValue(FakeVocabularyEvent());
    registerFallbackValue(FakeVocabularyState());
    registerFallbackValue(FakeEconomyEvent());
    registerFallbackValue(FakeEconomyState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
  });

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    await di.sl.reset();

    mockVocabularyBloc = MockVocabularyBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();
    mockNetworkInfo = MockNetworkInfo();

    vocabularyStreamController = StreamController<VocabularyState>.broadcast();

    when(() => mockVocabularyBloc.state).thenReturn(testLoadedState);
    whenListen(
      mockVocabularyBloc,
      vocabularyStreamController.stream,
      initialState: testLoadedState,
    );

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_vocab',
          email: 'vocab@vowl.app',
          displayName: 'Vocab Explorer',
          hintCount: 3,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);
  });

  tearDown(() async {
    await vocabularyStreamController.close();
    await di.sl.reset();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<VocabularyBloc>.value(value: mockVocabularyBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const MediaQuery(
              data: MediaQueryData(
                size: Size(390, 844),
                disableAnimations: true,
              ),
              child: PhrasalVerbsMasteryScreen(level: 1),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> advanceToPhase2(WidgetTester tester) async {
    await pumpScreen(tester);
    final optionKey = tester.widget<PhrasalVerbsOptionKey>(
      find.widgetWithText(PhrasalVerbsOptionKey, 'OFF'),
    );
    optionKey.onTap();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('PhrasalVerbsMasteryScreen', () {
    testWidgets(
        'Stage 1: renders vault handle, unlocks on particle tap, and reveals Stage 2 bonus arena',
        (tester) async {
      await pumpScreen(tester);

      expect(find.byType(PhrasalVerbsMasteryScreen), findsOneWidget);
      expect(find.text('CALL'), findsOneWidget);
      expect(find.text('OFF'), findsWidgets);

      // Trigger selection
      final optionKey = tester.widget<PhrasalVerbsOptionKey>(
        find.widgetWithText(PhrasalVerbsOptionKey, 'OFF'),
      );
      optionKey.onTap();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 600));

      // Stage 2 revealed
      expect(find.byType(PhrasalVerbsLiteralComparison), findsOneWidget);
      expect(find.textContaining('BONUS XP ARENA'), findsOneWidget);
      expect(find.text('Skip Sentence Builder & Bank Win'), findsOneWidget);
      expect(find.byType(ContextSentenceBuilder), findsOneWidget);
    });

    testWidgets(
        'Stage 2: tapping Skip Sentence Builder & Bank Win banks the win without losing lives',
        (tester) async {
      await advanceToPhase2(tester);

      // Verify Stage 2 Bonus Arena and Skip button exist
      expect(find.byType(PhrasalVerbsLiteralComparison), findsOneWidget);
      expect(find.textContaining('BONUS XP ARENA'), findsOneWidget);
      expect(find.text('Skip Sentence Builder & Bank Win'), findsOneWidget);
      expect(find.byType(ContextSentenceBuilder), findsOneWidget);

      // Trigger skip via sentence builder callback
      final builder = tester.widget<ContextSentenceBuilder>(
        find.byType(ContextSentenceBuilder),
      );
      builder.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verifies SubmitAnswer(true) was dispatched to bank the win without penalty!
      verify(() => mockVocabularyBloc.add(any(
            that: isA<SubmitAnswer>().having(
              (e) => e.isCorrect,
              'isCorrect',
              true,
            ),
          ))).called(1);
    });
  });
}
