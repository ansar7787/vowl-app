import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
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
import 'package:vowl/features/vocabulary/topic_vocab/presentation/pages/topic_vocab_mastery_screen.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_fusion_tile.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_fusion_timer.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_matrix_grid.dart';

class MockVocabularyBloc extends MockBloc<VocabularyEvent, VocabularyState> implements VocabularyBloc {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState> implements EconomyBloc {}
class MockHapticService extends Mock implements HapticService {}
class MockSoundService extends Mock implements SoundService {}
class MockTtsService extends Mock implements TtsService {}
class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockVocabularyBloc mockVocabularyBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late StreamController<VocabularyState> vocabularyStreamController;

  final testQuest = VocabularyQuest(
    id: 'VOC_TOPICVOCAB_L2_MASTERY_Q1',
    instruction: 'Fuse the matching topic clusters before time expires!',
    difficulty: 1,
    topicEmoji: '🌡️',
    topicBuckets: const ['Intense Heat', 'Extreme Cold'],
    options: const ['Boiling', 'Scorching', 'Steaming', 'Freezing', 'Icy', 'Chilly'],
    correctAnswer:
        'Intense Heat:Boiling, Intense Heat:Scorching, Intense Heat:Steaming, Extreme Cold:Freezing, Extreme Cold:Icy, Extreme Cold:Chilly',
    relatedWords: const ['Boiling: Liquid at 100C', 'Freezing: Ice at 0C'],
    explanation: 'Heat terms vs Cold terms.',
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
  });

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_topicVocab': true,
    });

    mockVocabularyBloc = MockVocabularyBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();

    vocabularyStreamController = StreamController<VocabularyState>.broadcast();

    final loadedState = VocabularyLoaded(
      quests: [testQuest],
      currentIndex: 0,
      livesRemaining: 3,
      answerStatus: AnswerStatus.unanswered,
    );

    when(() => mockVocabularyBloc.state).thenReturn(loadedState);
    whenListen(
      mockVocabularyBloc,
      vocabularyStreamController.stream,
      initialState: loadedState,
    );

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_topic',
          email: 'topic@vowl.app',
          displayName: 'Topic Master',
          hintCount: 3,
        ),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream<EconomyState>.empty());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playCorrect(comboStep: any(named: 'comboStep'))).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playSoftWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(() => mockTtsService.speak(any(), rate: any(named: 'rate'), locale: any(named: 'locale')))
        .thenAnswer((_) async {});

    await di.sl.reset();
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    vocabularyStreamController.close();
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MultiBlocProvider(
        providers: [
          BlocProvider<VocabularyBloc>.value(value: mockVocabularyBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
  }

  group('TopicVocabMasteryScreen', () {
    testWidgets('renders matrix grid, countdown timer, and fetches quests', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const TopicVocabMasteryScreen(level: 2)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockVocabularyBloc.add(any(that: isA<FetchVocabularyQuests>()))).called(1);
      expect(find.byType(TopicFusionTimer), findsOneWidget);
      expect(find.byType(TopicMatrixGrid), findsOneWidget);
      expect(find.text('Boiling'), findsOneWidget);
      expect(find.text('Freezing'), findsOneWidget);
    });

    testWidgets('selecting matching tiles enables fuse button and triggers fusion', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const TopicVocabMasteryScreen(level: 2)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap 3 heat words using find.widgetWithText(TopicFusionTile, ...)
      final boilingFinder = find.widgetWithText(TopicFusionTile, 'Boiling');
      await tester.ensureVisible(boilingFinder);
      await tester.tap(boilingFinder, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final scorchingFinder = find.widgetWithText(TopicFusionTile, 'Scorching');
      await tester.ensureVisible(scorchingFinder);
      await tester.tap(scorchingFinder, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final steamingFinder = find.widgetWithText(TopicFusionTile, 'Steaming');
      await tester.ensureVisible(steamingFinder);
      await tester.tap(steamingFinder, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Group button should show (3/3)
      final fuseButton = find.text('Group Words (3/3)');
      expect(fuseButton, findsOneWidget);

      await tester.ensureVisible(fuseButton);
      await tester.tap(fuseButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.heavy()).called(1);
    });
  });
}
