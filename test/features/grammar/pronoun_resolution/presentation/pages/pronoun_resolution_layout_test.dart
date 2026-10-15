import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
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
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/pronoun_resolution/presentation/pages/pronoun_resolution_screen.dart';
import 'package:vowl/features/grammar/pronoun_resolution/presentation/widgets/pronoun_resolution_instruction.dart';

class MockGrammarBloc extends MockBloc<GrammarEvent, GrammarState>
    implements GrammarBloc {}

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

class FakeGrammarEvent extends Fake implements GrammarEvent {}

class FakeGrammarState extends Fake implements GrammarState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGrammarBloc mockGrammarBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;

  setUpAll(() {
    registerFallbackValue(FakeGrammarEvent());
    registerFallbackValue(FakeGrammarState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const GrammarHintUsed());
    registerFallbackValue(const Duration(milliseconds: 50));
  });

  const testQuest1 = GrammarQuest(
    id: 'pronoun_l1_q1',
    instruction: 'ALIGN THE GRAVITY WELL',
    difficulty: 1,
    subtype: GameSubtype.pronounResolution,
    question: 'The scientist analyzed the sample because it was unusual.',
    sentence: 'The scientist analyzed the sample because it was unusual.',
    correctAnswer: 'SAMPLE',
    options: ['SCIENTIST', 'SAMPLE', 'EXPERIMENT'],
    correctAnswerIndex: 1, // 'SAMPLE'
    targetWord: 'it',
    referentHighlight: 'SAMPLE',
    grammarRule: 'Pronoun Antecedent Agreement',
    hint: 'Look for the singular inanimate noun that "it" replaces.',
  );

  const testQuestNoHighlight = GrammarQuest(
    id: 'pronoun_l1_q2',
    instruction: 'TARGET THE ANTECEDENT',
    difficulty: 1,
    subtype: GameSubtype.pronounResolution,
    question: 'The dogs barked when they saw the mail carrier.',
    sentence: 'The dogs barked when they saw the mail carrier.',
    correctAnswer: 'DOGS',
    options: ['DOGS', 'MAIL CARRIER', 'NEIGHBORS'],
    correctAnswerIndex: 0, // 'DOGS'
    targetWord: 'they',
    hint: 'Who saw the mail carrier?',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [testQuest1, testQuestNoHighlight],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    wrongCount: 0,
    isFinalFailure: false,
  );

  setUp(() async {
    mockGrammarBloc = MockGrammarBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();
    mockLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();

    VowlMotion.lowAnimationModeOverride.value = true;

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_pronounResolution': true,
    });

    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (inv) =>
          inv.namedArguments[#fallback] as String? ??
          inv.positionalArguments.first as String,
    );

    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));

    when(() => mockGrammarBloc.state).thenReturn(testLoadedState);
    when(
      () => mockGrammarBloc.stream,
    ).thenAnswer((_) => const Stream<GrammarState>.empty());

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_id',
          email: 'test@vowl.app',
          displayName: 'Test Grammarian',
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

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
        pauseMarkers: any(named: 'pauseMarkers'),
        forcedPreset: any(named: 'forcedPreset'),
        isKids: any(named: 'isKids'),
      ),
    ).thenAnswer((_) async {});

    await di.sl.reset();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
  });

  tearDown(() async {
    await di.sl.reset();
  });

  Future<void> pumpPronounResolution(
    WidgetTester tester, {
    GrammarState? state,
    int level = 2,
    Size size = const Size(390, 844),
    ThemeMode themeMode = ThemeMode.dark,
  }) async {
    if (state != null) {
      when(() => mockGrammarBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<GrammarBloc>.value(value: mockGrammarBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  padding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                ),
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: PronounResolutionScreen(level: level),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
    '1. renders initial quest with instruction, grammar rule box, context card, canvas, and node touch targets',
    (tester) async {
      await pumpPronounResolution(tester);

      expect(find.byType(PronounResolutionInstruction), findsOneWidget);
      expect(find.byKey(const ValueKey('grammar_rule_box')), findsOneWidget);
      expect(find.byKey(const ValueKey('pronoun_context_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('pronoun_gravity_canvas')), findsOneWidget);
      expect(find.byKey(const ValueKey('pronoun_node_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('pronoun_node_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('pronoun_node_2')), findsOneWidget);
      expect(find.textContaining('scientist analyzed the sample'), findsOneWidget);
    },
  );

  testWidgets(
    '2. hides grammar rule box when referentHighlight is null',
    (tester) async {
      await pumpPronounResolution(
        tester,
        state: testLoadedState.copyWith(currentIndex: 1),
      );

      expect(find.byKey(const ValueKey('grammar_rule_box')), findsNothing);
      expect(find.byKey(const ValueKey('pronoun_context_card')), findsOneWidget);
    },
  );

  testWidgets(
    '3. renders custom instruction text in PronounResolutionInstruction',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (context, _) => const PronounResolutionInstruction(
                primaryColor: Colors.blue,
                instruction: 'TARGET THE NOUN',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TARGET THE NOUN'), findsOneWidget);
    },
  );

  testWidgets(
    '4. displays quest hint inside grammar rule box when hintUsed is true',
    (tester) async {
      await pumpPronounResolution(
        tester,
        state: testLoadedState.copyWith(hintUsed: true),
      );

      expect(
        find.text('Look for the singular inanimate noun that "it" replaces.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '5. tapping incorrect node submits wrong answer to GrammarBloc',
    (tester) async {
      await pumpPronounResolution(tester);

      final node0 = find.byKey(const ValueKey('pronoun_node_0'));
      await tester.tap(node0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verify(
        () => mockGrammarBloc.add(
          any(
            that: isA<SubmitAnswer>().having(
              (e) => e.isCorrect,
              'isCorrect',
              false,
            ),
          ),
        ),
      ).called(1);
    },
  );

  testWidgets(
    '6. tapping correct node triggers success haptic and reveals TypeToConfirmOverlay (Phase 2)',
    (tester) async {
      await pumpPronounResolution(tester);

      final node1 = find.byKey(const ValueKey('pronoun_node_1'));
      await tester.tap(node1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.heavy()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);

      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
    },
  );

  testWidgets(
    '7. Phase 2: typing answer in TypeToConfirmOverlay confirms and submits correct answer',
    (tester) async {
      await pumpPronounResolution(tester);

      final node1 = find.byKey(const ValueKey('pronoun_node_1'));
      await tester.tap(node1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      final textFieldFinder = find.byType(TextField);
      await tester.ensureVisible(textFieldFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(textFieldFinder, findsOneWidget);

      await tester.enterText(textFieldFinder, 'SAMPLE');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final submitBtn = find.text('SUBMIT');
      await tester.ensureVisible(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(submitBtn, findsOneWidget);

      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockGrammarBloc.add(const SubmitAnswer(true))).called(1);
    },
  );

  testWidgets(
    '8. Phase 2: skipping confirm (after 3 failed attempts) dispatches wrong answer',
    (tester) async {
      await pumpPronounResolution(tester);

      final node1 = find.byKey(const ValueKey('pronoun_node_1'));
      await tester.tap(node1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      final textFieldFinder = find.byType(TextField);
      await tester.ensureVisible(textFieldFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(textFieldFinder, 'WRONG_ANSWER');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final submitBtn = find.text('SUBMIT');
      await tester.ensureVisible(submitBtn);

      // Attempt 1
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Attempt 2
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Attempt 3
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final continueBtn = find.text('CONTINUE').last;
      await tester.ensureVisible(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(
        () => mockGrammarBloc.add(
          any(
            that: isA<SubmitAnswer>().having(
              (e) => e.isCorrect,
              'isCorrect',
              false,
            ),
          ),
        ),
      ).called(1);
    },
  );

  testWidgets(
    '9. dragging to incorrect node triggers wrong answer submission',
    (tester) async {
      await pumpPronounResolution(tester);

      final canvasFinder = find.byKey(const ValueKey('pronoun_gravity_canvas'));
      expect(canvasFinder, findsOneWidget);

      final node0 = find.byKey(const ValueKey('pronoun_node_0'));
      final target = tester.getCenter(node0);

      final gesture = await tester.startGesture(tester.getCenter(canvasFinder));
      await gesture.moveBy(const Offset(2, 2));
      await tester.pump();
      await gesture.moveTo(target);
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));

      verify(
        () => mockGrammarBloc.add(
          any(
            that: isA<SubmitAnswer>().having(
              (e) => e.isCorrect,
              'isCorrect',
              false,
            ),
          ),
        ),
      ).called(1);
    },
  );

  testWidgets(
    '10. dragging to correct node triggers success audio/haptics and Phase 2',
    (tester) async {
      await pumpPronounResolution(tester);

      final canvasFinder = find.byKey(const ValueKey('pronoun_gravity_canvas'));
      expect(canvasFinder, findsOneWidget);

      final node1 = find.byKey(const ValueKey('pronoun_node_1'));
      final target = tester.getCenter(node1);

      final gesture = await tester.startGesture(target + const Offset(-10, -10));
      await gesture.moveBy(const Offset(2, 2));
      await tester.pump();
      await gesture.moveTo(target);
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.heavy()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);

      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
    },
  );

  testWidgets(
    '11. panning in canvas without reaching any node does not submit answer',
    (tester) async {
      await pumpPronounResolution(tester);

      final canvasFinder = find.byKey(const ValueKey('pronoun_gravity_canvas'));
      final center = tester.getCenter(canvasFinder);

      clearInteractions(mockGrammarBloc);

      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(2, 2));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 200));

      verifyNever(() => mockGrammarBloc.add(any(that: isA<SubmitAnswer>())));
    },
  );

  testWidgets(
    '12. lockout: when question is answered, tapping nodes does not submit another answer',
    (tester) async {
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );

      await pumpPronounResolution(tester, state: answeredState);

      clearInteractions(mockGrammarBloc);

      final node0 = find.byKey(const ValueKey('pronoun_node_0'));
      await tester.ensureVisible(node0);
      await tester.pump();
      await tester.tap(node0, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));

      verifyNever(() => mockGrammarBloc.add(any(that: isA<SubmitAnswer>())));
    },
  );

  testWidgets(
    '13. shimmer loading: displays GameShimmerLoading when state is not loaded',
    (tester) async {
      await pumpPronounResolution(tester, state: const GrammarInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(
        find.byKey(const ValueKey('pronoun_gravity_canvas')),
        findsNothing,
      );
    },
  );

  testWidgets(
    '14. hint button dispatches GrammarHintUsed once without double dispatch',
    (tester) async {
      await pumpPronounResolution(tester);

      final hintFinder = find.byType(QuestHintButton);
      expect(hintFinder, findsOneWidget);

      await tester.tap(hintFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockGrammarBloc.add(const GrammarHintUsed())).called(1);
    },
  );

  testWidgets(
    '15. level 1 briefing dialog displays for first-time user',
    (tester) async {
      await pumpPronounResolution(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
    },
  );

  testWidgets(
    '16. reduced motion: lowAnimationModeOverride gates shimmer and entrance animations',
    (tester) async {
      VowlMotion.lowAnimationModeOverride.value = true;
      await pumpPronounResolution(tester);

      expect(find.byType(PronounResolutionScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('pronoun_gravity_canvas')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '17. compact viewport (320x560) renders cleanly without overflow',
    (tester) async {
      await pumpPronounResolution(tester, size: const Size(320, 560));

      expect(find.byType(PronounResolutionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '18. tablet viewport (800x1280) renders cleanly with proper layout',
    (tester) async {
      await pumpPronounResolution(tester, size: const Size(800, 1280));

      expect(find.byType(PronounResolutionScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('pronoun_gravity_canvas')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('pronoun_node_0')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '19. dark mode renders correctly with dark theme styling',
    (tester) async {
      await pumpPronounResolution(tester, themeMode: ThemeMode.dark);

      expect(find.byType(PronounResolutionScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('pronoun_context_card')), findsOneWidget);
    },
  );

  testWidgets(
    '20. light mode renders correctly with light theme styling',
    (tester) async {
      await pumpPronounResolution(tester, themeMode: ThemeMode.light);

      expect(find.byType(PronounResolutionScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('pronoun_context_card')), findsOneWidget);
    },
  );
}

