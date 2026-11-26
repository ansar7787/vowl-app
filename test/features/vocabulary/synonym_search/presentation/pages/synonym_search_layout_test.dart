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
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/pages/synonym_search_learn_screen.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/pages/synonym_search_practice_screen.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/pages/synonym_search_screen.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_context_replace_card.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_contrast_swap_card.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_cousin_preview_strip.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_grid_context_header.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_ladder_card.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_learn_spotlight_header.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_makeover_card.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_streak_timer_bar.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_word_grid_board.dart';

class _MockVocabularyBloc extends MockBloc<VocabularyEvent, VocabularyState>
    implements VocabularyBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class _MockHapticService extends Mock implements HapticService {}

class _MockSoundService extends Mock implements SoundService {}

class _MockTtsService extends Mock implements TtsService {}

class _MockAudioRecordingService extends Mock
    implements AudioRecordingService {}

class _MockSpeechService extends Mock implements SpeechService {}

class _MockLocaleService extends Mock implements LocaleService {}

class _MockAppLogger extends Mock implements AppLogger {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

class _MockAdService extends Mock implements AdService {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockVocabularyBloc mockVocabularyBloc;
  late _MockAuthBloc mockAuthBloc;
  late _MockEconomyBloc mockEconomyBloc;
  late StreamController<VocabularyState> streamController;

  const masteryQuest = VocabularyQuest(
    id: 'LAYOUT_Q1',
    type: QuestType.vocabulary,
    subtype: GameSubtype.synonymSearch,
    instruction: 'Find and trace the synonym.',
    word: 'Inexpensive',
    definition: 'Not costing a large sum of money.',
    synonym: 'Affordable',
    correctAnswer: 'Affordable',
    correctAnswerIndex: 0,
    options: ['Affordable', 'Pricey', 'Costly', 'Lavish'],
    contextSentence:
        'Students look for an ___ cafe near campus between classes.',
    usageExample: 'They booked an affordable room overlooking the park.',
    explanation: 'Affordable pairs naturally with budget prices.',
    hint: 'Starts with A and fits daily budgets.',
    difficulty: 2,
  );

  final loadedState = const VocabularyLoaded(
    quests: [masteryQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_synonymSearch': true,
    });
    await di.sl.reset();

    mockVocabularyBloc = _MockVocabularyBloc();
    mockAuthBloc = _MockAuthBloc();
    mockEconomyBloc = _MockEconomyBloc();
    streamController = StreamController<VocabularyState>.broadcast();

    when(() => mockVocabularyBloc.state).thenReturn(loadedState);
    whenListen(
      mockVocabularyBloc,
      streamController.stream,
      initialState: loadedState,
    );
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(id: 'u', email: 'u@v.app', displayName: 'U'),
      ),
    );
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(
      () => mockEconomyBloc.stream,
    ).thenAnswer((_) => const Stream<EconomyState>.empty());

    final haptic = _MockHapticService();
    final sound = _MockSoundService();
    final tts = _MockTtsService();
    final audio = _MockAudioRecordingService();
    final speech = _MockSpeechService();
    final net = _MockNetworkInfo();

    when(() => haptic.selection()).thenAnswer((_) async {});
    when(() => haptic.light()).thenAnswer((_) async {});
    when(() => haptic.success()).thenAnswer((_) async {});
    when(() => haptic.error()).thenAnswer((_) async {});
    when(() => sound.stopTts()).thenAnswer((_) async {});
    when(() => sound.stopAudio()).thenAnswer((_) async {});
    when(() => tts.isSpeakingNotifier).thenReturn(ValueNotifier<bool>(false));
    when(
      () => tts.preWarm(locale: any(named: 'locale')),
    ).thenAnswer((_) async {});
    when(() => tts.stop()).thenAnswer((_) async {});
    when(() => audio.isRecording).thenReturn(false);
    when(() => audio.dispose()).thenAnswer((_) async {});
    when(() => speech.isListening).thenReturn(false);
    when(() => speech.isPlaying).thenReturn(false);
    when(() => net.isConnected).thenAnswer((_) async => true);

    di.sl.registerSingleton<HapticService>(haptic);
    di.sl.registerSingleton<SoundService>(sound);
    di.sl.registerSingleton<TtsService>(tts);
    di.sl.registerSingleton<AudioRecordingService>(audio);
    di.sl.registerSingleton<SpeechService>(speech);
    di.sl.registerSingleton<LocaleService>(_MockLocaleService());
    di.sl.registerSingleton<AppLogger>(_MockAppLogger());
    di.sl.registerSingleton<AnalyticsService>(_MockAnalyticsService());
    di.sl.registerSingleton<AdService>(_MockAdService());
    di.sl.registerSingleton<NetworkInfo>(net);
  });

  tearDown(() async {
    await streamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
    await di.sl.reset();
  });

  final viewports = <(String, Size, double)>[
    ('320x568_1.0x', const Size(320, 568), 1.0),
    ('360x640_1.0x', const Size(360, 640), 1.0),
    ('430x932_1.0x', const Size(430, 932), 1.0),
    ('360x640_1.5x', const Size(360, 640), 1.5),
  ];

  void assertZeroEllipsisOnGameWidgets(WidgetTester tester) {
    final roots = <Type>[
      SynonymLearnSpotlightHeader,
      SynonymMakeoverCard,
      SynonymCousinPreviewStrip,
      SynonymContrastSwapCard,
      SynonymLadderCard,
      SynonymContextReplaceCard,
      SynonymGridContextHeader,
      SynonymStreakTimerBar,
      SynonymWordGridBoard,
    ];
    for (final root in roots) {
      for (final finder in find.byType(root).evaluate()) {
        final texts = tester.widgetList<Text>(
          find.descendant(
            of: find.byWidget(finder.widget),
            matching: find.byType(Text),
          ),
        );
        for (final t in texts) {
          expect(
            t.overflow,
            isNot(equals(TextOverflow.ellipsis)),
            reason: 'Forbidden ellipsis inside $root: "${t.data}"',
          );
        }
      }
    }
  }

  for (final vp in viewports) {
    testWidgets(
      'all 3 phase screens fit ${vp.$1} cleanly with zero overflow or ellipsis',
      (tester) async {
        String activeStage = 'init';
        final errors = <String>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          errors.add('[$activeStage] ${details.toString()}');
        };

        tester.view.physicalSize = vp.$2;
        tester.view.devicePixelRatio = 1.0;

        try {
          Widget host(Widget child) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<VocabularyBloc>.value(value: mockVocabularyBloc),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
              ],
              child: ScreenUtilInit(
                designSize: const Size(390, 844),
                minTextAdapt: true,
                builder: (context, _) => MaterialApp(
                  theme: AppTheme.lightTheme,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: vp.$2,
                      textScaler: TextScaler.linear(vp.$3),
                      disableAnimations: true,
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          }

          // 1. Learn Phase
          activeStage = 'Learn';
          await tester.pumpWidget(
            host(
              SynonymSearchLearnScreen(
                level: 1,
                initialItems: [SynonymLearnItem.fallback(1)],
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          assertZeroEllipsisOnGameWidgets(tester);

          // 2. Practice Phase
          activeStage = 'Practice';
          await tester.pumpWidget(
            host(
              SynonymSearchPracticeScreen(
                level: 1,
                initialExercises: SynonymPracticeQuest.fallbackExercises(1),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          assertZeroEllipsisOnGameWidgets(tester);

          // 3. Mastery Phase (Grid Mode - questIndex 0)
          activeStage = 'MasteryGrid';
          when(() => mockVocabularyBloc.state).thenReturn(loadedState);
          await tester.pumpWidget(host(const SynonymSearchScreen(level: 1)));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          assertZeroEllipsisOnGameWidgets(tester);

          for (int i = 0; i < 25; i++) {
            final rect = tester.getRect(find.byKey(Key('grid_cell_$i')));
            expect(rect.width, greaterThanOrEqualTo(48.0));
            expect(rect.height, greaterThanOrEqualTo(48.0));
          }

          // 4. Mastery Phase (Context Match - questIndex 1)
          activeStage = 'MasteryContextReplace';
          const ctxState = VocabularyLoaded(
            quests: [masteryQuest, masteryQuest],
            currentIndex: 1,
            livesRemaining: 3,
            answerStatus: AnswerStatus.unanswered,
          );
          when(() => mockVocabularyBloc.state).thenReturn(ctxState);
          streamController.add(ctxState);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          assertZeroEllipsisOnGameWidgets(tester);
          for (int i = 0; i < 4; i++) {
            final optRect = tester.getRect(
              find.byKey(Key('context_replace_opt_$i')),
            );
            expect(optRect.height, greaterThanOrEqualTo(48.0));
          }

          // 5. Mastery Phase (Recall-First Mode - Level 45 questIndex 2)
          activeStage = 'MasteryRecallFirst';
          const recallState = VocabularyLoaded(
            quests: [masteryQuest, masteryQuest, masteryQuest],
            currentIndex: 2,
            livesRemaining: 3,
            answerStatus: AnswerStatus.unanswered,
          );
          when(() => mockVocabularyBloc.state).thenReturn(recallState);
          streamController.add(recallState);
          await tester.pumpWidget(host(const SynonymSearchScreen(level: 45)));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            find.byKey(const Key('recall_length_hidden_badge')),
            findsOneWidget,
          );
          assertZeroEllipsisOnGameWidgets(tester);

          // Reset BLoC state cleanly for next viewport
          when(() => mockVocabularyBloc.state).thenReturn(loadedState);
          streamController.add(loadedState);
          await tester.pump();

          final barRect = tester.getRect(find.byType(SynonymStreakTimerBar));
          final innerRowRect = tester.getRect(
            find
                .descendant(
                  of: find.byType(SynonymStreakTimerBar),
                  matching: find.byType(Row),
                )
                .first,
          );
          expect(
            barRect.right - innerRowRect.right,
            greaterThanOrEqualTo(56.0),
          );

          // Flush pending animation/widget timers cleanly before teardown
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 300));
        } finally {
          FlutterError.onError = prevOnError;
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        }

        expect(errors, isEmpty, reason: errors.join('\n'));
      },
    );
  }

  testWidgets(
    'all 3 phase screens render cleanly in Dark Mode on 360x640 without errors',
    (tester) async {
      final errors = <String>[];
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details.exceptionAsString());
      };

      const size = Size(360, 640);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      try {
        Widget darkHost(Widget child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<VocabularyBloc>.value(value: mockVocabularyBloc),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
            ],
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              minTextAdapt: true,
              builder: (context, _) => MaterialApp(
                theme: AppTheme.darkTheme,
                home: MediaQuery(
                  data: const MediaQueryData(
                    size: size,
                    disableAnimations: true,
                  ),
                  child: child,
                ),
              ),
            ),
          );
        }

        await tester.pumpWidget(
          darkHost(
            SynonymSearchLearnScreen(
              level: 1,
              initialItems: [SynonymLearnItem.fallback(1)],
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.pumpWidget(
          darkHost(
            SynonymSearchPracticeScreen(
              level: 1,
              initialExercises: SynonymPracticeQuest.fallbackExercises(1),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.pumpWidget(darkHost(const SynonymSearchScreen(level: 1)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        const darkCtxState = VocabularyLoaded(
          quests: [masteryQuest, masteryQuest],
          currentIndex: 1,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
        );
        when(() => mockVocabularyBloc.state).thenReturn(darkCtxState);
        streamController.add(darkCtxState);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
      } finally {
        FlutterError.onError = prevOnError;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }

      expect(errors, isEmpty, reason: errors.join('\n'));
    },
  );

  testWidgets(
    'bottom CTA and Mastery feedback sheet clear old 3-button (56dp) and gesture (24dp) nav bars',
    (tester) async {
      final errors = <String>[];
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details.exceptionAsString());
      };

      const size = Size(360, 640);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      try {
        for (final navHeight in [56.0, 24.0]) {
          Widget navHost(Widget child) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<VocabularyBloc>.value(value: mockVocabularyBloc),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
              ],
              child: ScreenUtilInit(
                designSize: const Size(390, 844),
                minTextAdapt: true,
                builder: (context, _) => MaterialApp(
                  theme: AppTheme.lightTheme,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: size,
                      viewPadding: EdgeInsets.only(bottom: navHeight),
                      padding: EdgeInsets.only(bottom: navHeight),
                      disableAnimations: true,
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          }

          await tester.pumpWidget(
            navHost(
              SynonymSearchLearnScreen(
                level: 1,
                initialItems: [SynonymLearnItem.fallback(1)],
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));
          final learnCtaRect = tester.getRect(find.text('Check 1 Example'));
          expect(
            learnCtaRect.bottom,
            lessThanOrEqualTo(size.height - navHeight),
          );

          await tester.pumpWidget(
            navHost(
              SynonymSearchPracticeScreen(
                level: 1,
                initialExercises: SynonymPracticeQuest.fallbackExercises(1),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));
          final practiceCtaRect = tester.getRect(find.text('Check Answer'));
          expect(
            practiceCtaRect.bottom,
            lessThanOrEqualTo(size.height - navHeight),
          );

          const feedbackState = VocabularyLoaded(
            quests: [masteryQuest],
            currentIndex: 0,
            livesRemaining: 3,
            answerStatus: AnswerStatus.correct,
          );
          when(() => mockVocabularyBloc.state).thenReturn(feedbackState);
          streamController.add(feedbackState);
          await tester.pumpWidget(navHost(const SynonymSearchScreen(level: 1)));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          final continueRect = tester.getRect(find.text('CONTINUE'));
          expect(
            continueRect.bottom,
            lessThanOrEqualTo(size.height - navHeight),
          );
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
      } finally {
        FlutterError.onError = prevOnError;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }

      expect(errors, isEmpty, reason: errors.join('\n'));
    },
  );
}
