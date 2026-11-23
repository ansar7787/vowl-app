import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/pages/word_formation_screen.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_4way_launcher.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_sentence_slot.dart';

class MockVocabularyBloc extends MockBloc<VocabularyEvent, VocabularyState>
    implements VocabularyBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockTtsService extends Mock implements TtsService {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockVocabularyBloc mockVocabularyBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockTtsService mockTtsService;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late StreamController<VocabularyState> vocabularyStreamController;

  const testQuest = VocabularyQuest(
    id: 'VOC_WORDFORMATION_L2_Q1',
    type: QuestType.vocabulary,
    subtype: GameSubtype.wordFormation,
    instruction: 'Transform the root word into the correct form.',
    word: 'CREATION',
    rootWord: 'CREATE',
    correctAnswer: 'CREATION',
    correctAnswerIndex: 0,
    contextSentence: 'The artist unveiled her latest _______ to high praise.',
    definition:
        'To bring something into existence through skill or imagination.',
    options: ['CREATION', 'CREATIVE', 'CREATIVELY', 'UNCREATIVE'],
    hint: 'A noun naming the piece of work created.',
    difficulty: 2,
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
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const VocabularyHintUsed());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_wordFormation': true,
    });

    mockVocabularyBloc = MockVocabularyBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockTtsService = MockTtsService();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    vocabularyStreamController = StreamController<VocabularyState>.broadcast();

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_wf',
          email: 'wf@vowl.app',
          displayName: 'Word Morpher',
          hintCount: 3,
        ),
      ),
    );
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(
      () => mockEconomyBloc.stream,
    ).thenAnswer((_) => const Stream<EconomyState>.empty());

    when(() => mockVocabularyBloc.state).thenReturn(testLoadedState);
    when(
      () => mockVocabularyBloc.stream,
    ).thenAnswer((_) => vocabularyStreamController.stream);

    when(() => mockTtsService.speak(any())).thenAnswer((_) async {});
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});

    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(
      () => mockSoundService.playCorrect(comboStep: any(named: 'comboStep')),
    ).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});

    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();

    di.sl.registerLazySingleton<TtsService>(() => mockTtsService);
    di.sl.registerLazySingleton<HapticService>(() => mockHapticService);
    di.sl.registerLazySingleton<SoundService>(() => mockSoundService);
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    vocabularyStreamController.close();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
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
        child: MaterialApp(home: child),
      ),
    );
  }

  group('WordFormationScreen (Mastery Arena)', () {
    testWidgets('renders sentence slot, morph core, and 4-way launcher', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 2.0;
      tester.view.devicePixelRatio = 2.0;

      try {
        await tester.pumpWidget(
          buildTestableWidget(const WordFormationScreen(level: 2)),
        );
        await tester.pump();

        expect(find.byType(WordFormationScreen), findsOneWidget);
        expect(find.byType(WordFormationSentenceSlot), findsOneWidget);
        expect(find.byType(WordFormation4WayLauncher), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });

    testWidgets('tapping correct direction dispatches SubmitAnswer(true)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 2.0;
      tester.view.devicePixelRatio = 2.0;

      try {
        await tester.pumpWidget(
          buildTestableWidget(const WordFormationScreen(level: 2)),
        );
        await tester.pump();

        // Tap North pad (CREATION - correct index 0)
        final northFinder = find.text('CREATION');
        expect(northFinder, findsOneWidget);
        await tester.tap(northFinder, warnIfMissed: false);
        await tester.pump();

        verify(
          () => mockVocabularyBloc.add(const SubmitAnswer(true)),
        ).called(1);
      } finally {
        await tester.pumpWidget(const SizedBox());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });

    testWidgets('tapping wrong direction dispatches SubmitAnswer(false)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 2.0;
      tester.view.devicePixelRatio = 2.0;

      try {
        await tester.pumpWidget(
          buildTestableWidget(const WordFormationScreen(level: 2)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tap East pad (CREATIVE - incorrect for Quest 1)
        final eastFinder = find.text('CREATIVE');
        expect(eastFinder, findsOneWidget);
        await tester.ensureVisible(eastFinder);
        await tester.tap(eastFinder);
        await tester.pump();

        verify(
          () => mockVocabularyBloc.add(const SubmitAnswer(false)),
        ).called(1);
      } finally {
        await tester.pumpWidget(const SizedBox());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });

    testWidgets(
      'tapping hint button dispatches VocabularyHintUsed and reads aloud',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844) * 2.0;
        tester.view.devicePixelRatio = 2.0;

        try {
          await tester.pumpWidget(
            buildTestableWidget(const WordFormationScreen(level: 2)),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          final hintFinder = find.byType(QuestHintButton);
          expect(hintFinder, findsOneWidget);
          final hintButton = tester.widget<QuestHintButton>(hintFinder);
          hintButton.onTap();
          await tester.pump();

          verify(
            () => mockVocabularyBloc.add(const VocabularyHintUsed()),
          ).called(greaterThanOrEqualTo(1));
          verify(
            () => mockTtsService.speak(any()),
          ).called(greaterThanOrEqualTo(1));
        } finally {
          await tester.pumpWidget(const SizedBox());
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        }
      },
    );
  });
}
