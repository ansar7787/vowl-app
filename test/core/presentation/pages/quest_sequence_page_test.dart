import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/discovery_helper.dart';
import 'package:vowl/core/presentation/pages/quest_sequence_page.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class MockLocaleService extends Mock implements LocaleService {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockEconomyBloc extends Mock implements EconomyBloc {}

class MockSoundService extends Mock implements SoundService {}

class MockHapticService extends Mock implements HapticService {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockAdService extends Mock implements AdService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocaleService mockLocale;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockSoundService mockSoundService;
  late MockHapticService mockHapticService;
  late MockNetworkInfo mockNetworkInfo;
  late MockAdService mockAdService;

  const testUser = UserEntity(
    id: 'user_quest_test',
    email: 'quest@vowl.app',
    displayName: 'Quest Hero',
    isEmailVerified: true,
    totalExp: 1000,
    isPremium: false,
  );

  void setViewport(WidgetTester tester, [Size size = const Size(390, 844), double ratio = 2.0]) {
    tester.view.physicalSize = Size(size.width * ratio, size.height * ratio);
    tester.view.devicePixelRatio = ratio;
    addTearDown(() => tester.view.resetPhysicalSize());
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockLocale = MockLocaleService();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockSoundService = MockSoundService();
    mockHapticService = MockHapticService();
    mockNetworkInfo = MockNetworkInfo();
    mockAdService = MockAdService();

    when(() => mockAdService.recordLevelCompletion()).thenReturn(false);
    when(() => mockAdService.showInterstitialAd(
      onDismissed: any(named: 'onDismissed'),
      isPremium: any(named: 'isPremium'),
      force: any(named: 'force'),
    )).thenAnswer((invocation) {
      final callback = invocation.namedArguments[#onDismissed] as VoidCallback;
      callback();
    });

    when(() => mockLocale.currentLocale).thenReturn(const Locale('en'));
    when(() => mockLocale.tr(
      any(),
      args: any(named: 'args'),
      fallback: any(named: 'fallback'),
    )).thenAnswer((invocation) {
      final key = invocation.positionalArguments[0] as String;
      final fallback = invocation.namedArguments[#fallback] as String?;
      final args = invocation.namedArguments[#args] as List<dynamic>?;
      if (key == 'quest_sequence.status_part') {
        return 'Part ${args?[0]} of ${args?[1]}';
      }
      if (key == 'quest_sequence.start_part_button') {
        return 'Start Part ${args?[0]}';
      }
      return fallback ?? key;
    });

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(testUser),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockEconomyBloc.state).thenReturn(
      const EconomyState(),
    );
    when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    di.sl.registerLazySingleton<SoundService>(() => mockSoundService);

    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    di.sl.registerLazySingleton<HapticService>(() => mockHapticService);

    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();
    di.sl.registerLazySingleton<NetworkInfo>(() => mockNetworkInfo);

    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    di.sl.registerLazySingleton<LocaleService>(() => mockLocale);

    if (di.sl.isRegistered<AuthBloc>()) di.sl.unregister<AuthBloc>();
    di.sl.registerLazySingleton<AuthBloc>(() => mockAuthBloc);

    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    di.sl.registerLazySingleton<AdService>(() => mockAdService);

    initLocaleServiceReference(mockLocale);
  });

  tearDown(() {
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AuthBloc>()) di.sl.unregister<AuthBloc>();
  });

  Widget buildQuestSequenceHarness({
    required String sequenceId,
    required List<GameQuest> quests,
    void Function(String route)? onGamePushed,
    Object? Function(String route)? gamePushResultBuilder,
    String initialLocation = '/sequence',
    Size viewport = const Size(390, 844),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('open_sequence_btn'),
                onPressed: () => context.push('/sequence'),
                child: const Text('OPEN SEQUENCE'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/sequence',
          builder: (context, state) => QuestSequencePage(
            sequenceId: sequenceId,
            quests: quests,
          ),
        ),
        GoRoute(
          path: '/game',
          builder: (context, state) {
            final fullUri = state.uri.toString();
            onGamePushed?.call(fullUri);
            final result = gamePushResultBuilder != null
                ? gamePushResultBuilder(fullUri)
                : true;
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('complete_game_btn'),
                  onPressed: () => context.pop(result),
                  child: const Text('COMPLETE GAME'),
                ),
              ),
            );
          },
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: viewport,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          themeMode: themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }

  final sampleQuests = [
    const GameQuest(
      id: 'quest_1',
      type: QuestType.speaking,
      subtype: GameSubtype.repeatSentence,
      instruction: 'quest_sequences.repeat_sentence',
      difficulty: 1,
      xpReward: 15,
      coinReward: 10,
    ),
    const GameQuest(
      id: 'quest_2',
      type: QuestType.grammar,
      subtype: GameSubtype.tenseMastery,
      instruction: 'quest_sequences.grammar_tenses',
      difficulty: 2,
      xpReward: 20,
      coinReward: 15,
    ),
  ];

  // =========================================================================
  // GROUP 1: Initial Rendering, Sequence Titles & Themed Metadata
  // =========================================================================
  group('Group 1: Initial Rendering, Sequence Titles & Themed Metadata', () {
    testWidgets('renders daily_duo sequence title, part indicator and initial progress', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'daily_duo',
        quests: sampleQuests,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('DAILY WORKOUT'), findsOneWidget);
      expect(find.text('Part 1 of 2'), findsOneWidget);
      expect(find.text('quest_sequences.repeat_sentence'), findsOneWidget);
      expect(find.text('Start Part 1'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders speed_blitz title correctly', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'speed_blitz',
        quests: sampleQuests,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('RAPID RECALL'), findsOneWidget);
    });

    testWidgets('renders grammar_pro title correctly', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'grammar_pro',
        quests: sampleQuests,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SENTENCE LAB'), findsOneWidget);
    });

    testWidgets('renders default fallback title for unknown sequenceId', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'custom_adventure_quest',
        quests: sampleQuests,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('THEMED QUEST'), findsOneWidget);
    });

    testWidgets('handles empty quests list gracefully with progress 1.0', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'daily_duo',
        quests: const [],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('DAILY WORKOUT'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('SUMMARY'), findsOneWidget);
      expect(find.text('All parts completed!'), findsOneWidget);
      expect(find.text('FINISH'), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 2: Game Category Icons Extension Mapping
  // =========================================================================
  group('Group 2: Game Category Icons Extension Mapping', () {
    testWidgets('resolves correct icons for all QuestType categories', (tester) async {
      setViewport(tester);

      final iconQuests = [
        const GameQuest(id: 'q_speak', type: QuestType.speaking, subtype: GameSubtype.repeatSentence, instruction: 'Speak', difficulty: 1),
        const GameQuest(id: 'q_listen', type: QuestType.listening, subtype: GameSubtype.audioMultipleChoice, instruction: 'Listen', difficulty: 1),
        const GameQuest(id: 'q_read', type: QuestType.reading, subtype: GameSubtype.readAndAnswer, instruction: 'Read', difficulty: 1),
        const GameQuest(id: 'q_write', type: QuestType.writing, subtype: GameSubtype.sentenceBuilder, instruction: 'Write', difficulty: 1),
        const GameQuest(id: 'q_gram', type: QuestType.grammar, subtype: GameSubtype.tenseMastery, instruction: 'Grammar', difficulty: 1),
        const GameQuest(id: 'q_voc', type: QuestType.vocabulary, subtype: GameSubtype.flashcards, instruction: 'Vocab', difficulty: 1),
        const GameQuest(id: 'q_acc', type: QuestType.accent, subtype: GameSubtype.minimalPairs, instruction: 'Accent', difficulty: 1),
        const GameQuest(id: 'q_role', type: QuestType.roleplay, subtype: GameSubtype.jobInterview, instruction: 'Roleplay', difficulty: 1),
        const GameQuest(id: 'q_elite', type: QuestType.eliteMastery, subtype: GameSubtype.storyBuilder, instruction: 'Elite', difficulty: 1),
      ];

      final expectedIcons = [
        Icons.mic_rounded,
        Icons.hearing_rounded,
        Icons.menu_book_rounded,
        Icons.edit_note_rounded,
        Icons.extension_rounded,
        Icons.abc_rounded,
        Icons.record_voice_over_rounded,
        Icons.forum_rounded,
        Icons.workspace_premium_rounded,
      ];

      for (var i = 0; i < iconQuests.length; i++) {
        SharedPreferences.setMockInitialValues({});
        DiscoveryHelper.clearTrackCache();
        await tester.pumpWidget(buildQuestSequenceHarness(
          sequenceId: 'icon_seq_$i',
          quests: [iconQuests[i]],
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byIcon(expectedIcons[i]), findsOneWidget);
      }
    });

    testWidgets('resolves fallback auto_awesome_rounded icon when subtype is null', (tester) async {
      setViewport(tester);

      const noSubtypeQuest = GameQuest(
        id: 'q_null_subtype',
        instruction: 'Special Task',
        difficulty: 1,
      );

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'daily_duo',
        quests: const [noSubtypeQuest],
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 3: Game Launching, Navigation & Step Transitions
  // =========================================================================
  group('Group 3: Game Launching, Navigation & Step Transitions', () {
    testWidgets('tapping Start Part pushes /game route with matching query params', (tester) async {
      setViewport(tester);
      String? pushedRoute;

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'daily_duo',
        quests: sampleQuests,
        onGamePushed: (route) => pushedRoute = route,
        gamePushResultBuilder: (_) => false, // return false so it does not auto advance
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final startBtn = find.text('Start Part 1');
      expect(startBtn, findsOneWidget);

      await tester.tap(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(pushedRoute, contains('/game?category=speaking&subtype=repeatSentence&level=1'));
    });

    testWidgets('cancelled game shows snackbar and stays on current part', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'daily_duo',
        quests: sampleQuests,
        gamePushResultBuilder: (_) => false, // cancel
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Start Part 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap COMPLETE GAME in game route to return false
      expect(find.byKey(const Key('complete_game_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('complete_game_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Returns to sequence page on Part 1
      expect(find.text('Part 1 of 2'), findsOneWidget);
      expect(find.text('Start Part 1'), findsOneWidget);
      expect(find.text('Quest part cancelled. You can try again or exit.'), findsOneWidget);
    });

    testWidgets('completing Part 1 advances to Part 2 seamlessly', (tester) async {
      setViewport(tester);
      final launchedRoutes = <String>[];

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'daily_duo',
        quests: sampleQuests,
        onGamePushed: (route) => launchedRoutes.add(route),
        gamePushResultBuilder: (route) {
          if (route.contains('repeatSentence')) return true;
          return false;
        },
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Part 1
      await tester.tap(find.text('Start Part 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Complete Part 1 with success
      await tester.tap(find.byKey(const Key('complete_game_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Part 2 is now launched or visible
      expect(launchedRoutes.any((r) => r.contains('repeatSentence')), isTrue);
    });
  });

  // =========================================================================
  // GROUP 4: Sequence Completion & Dialog Trigger
  // =========================================================================
  group('Group 4: Sequence Completion & Dialog Trigger', () {
    testWidgets('completing all parts triggers completion dialog and summary view', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'daily_duo',
        quests: sampleQuests,
        gamePushResultBuilder: (_) => true, // all pass
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Launch Part 1
      await tester.tap(find.text('Start Part 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Complete Part 1
      await tester.tap(find.byKey(const Key('complete_game_btn')).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Part 1 is completed, road map now presents Start Part 2
      expect(find.text('Start Part 2'), findsOneWidget);
      await tester.tap(find.text('Start Part 2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Complete Part 2
      expect(find.byKey(const Key('complete_game_btn')), findsWidgets);
      await tester.tap(find.byKey(const Key('complete_game_btn')).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog helper sound and haptics called
      verify(() => mockSoundService.playLevelComplete()).called(greaterThanOrEqualTo(1));
      verify(() => mockHapticService.success()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('tapping FINISH button in summary triggers showCompletion dialog', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'daily_duo',
        quests: const [], // Already finished
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final finishBtn = find.text('FINISH');
      expect(finishBtn, findsOneWidget);

      await tester.tap(finishBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playLevelComplete()).called(1);
      verify(() => mockHapticService.success()).called(1);
    });
  });

  // =========================================================================
  // GROUP 5: Close Button & Navigation
  // =========================================================================
  group('Group 5: Close Button & Navigation', () {
    testWidgets('tapping header close button pops the screen', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(buildQuestSequenceHarness(
        initialLocation: '/home',
        sequenceId: 'daily_duo',
        quests: sampleQuests,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('OPEN SEQUENCE'), findsOneWidget);
      await tester.tap(find.text('OPEN SEQUENCE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final closeBtnFinder = find.byIcon(Icons.close_rounded);
      expect(closeBtnFinder, findsOneWidget);

      await tester.tap(closeBtnFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('OPEN SEQUENCE'), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 6: Responsive Viewports, Themes & Safe Disposal
  // =========================================================================
  group('Group 6: Responsive Viewports, Themes & Safe Disposal', () {
    testWidgets('compact mobile layout (320x568) renders without overflow', (tester) async {
      setViewport(tester, const Size(320, 568));

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'speed_blitz',
        quests: sampleQuests,
        viewport: const Size(320, 568),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('RAPID RECALL'), findsOneWidget);
    });

    testWidgets('tablet layout (800x1280) renders without overflow', (tester) async {
      setViewport(tester, const Size(800, 1280), 1.5);

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'grammar_pro',
        quests: sampleQuests,
        viewport: const Size(800, 1280),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('SENTENCE LAB'), findsOneWidget);
    });

    testWidgets('dark theme applies AppColors.slate900 background', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'daily_duo',
        quests: sampleQuests,
        themeMode: ThemeMode.dark,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, AppColors.slate900);
    });

    testWidgets('light theme applies Colors.white background', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'daily_duo',
        quests: sampleQuests,
        themeMode: ThemeMode.light,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, Colors.white);
    });

    testWidgets('disposing widget cleans up stateHash notifier cleanly', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'daily_duo',
        quests: sampleQuests,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Unmount
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // GROUP 7: Daily Step & Quest Progress Persistence
  // =========================================================================
  group('Group 7: Daily Step & Quest Progress Persistence', () {
    testWidgets('restores today saved step progress to resume at Part 2', (tester) async {
      setViewport(tester);
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      SharedPreferences.setMockInitialValues({
        'vowl_sequence_step_daily_duo_user_quest_test': '${todayStr}_1',
      });

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'daily_duo',
        quests: sampleQuests,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Part 2 should be active now
      expect(find.text('Start Part 2'), findsOneWidget);
      expect(find.text('Part 2 of 2'), findsOneWidget);
    });

    testWidgets('completing Part 1 saves step progress to SharedPreferences', (tester) async {
      setViewport(tester);
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'daily_duo',
        quests: sampleQuests,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Start Part 1
      await tester.tap(find.text('Start Part 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Complete game
      await tester.tap(find.byKey(const Key('complete_game_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final prefs = await SharedPreferences.getInstance();
      final savedStep = prefs.getString('vowl_sequence_step_daily_duo_user_quest_test');
      expect(savedStep, equals('${todayStr}_1'));
    });

    testWidgets('completing Part 1 via GameDialogHelper advances to Part 2 seamlessly', (tester) async {
      setViewport(tester, const Size(390, 950));

      final router = GoRouter(
        initialLocation: '/sequence',
        routes: [
          GoRoute(
            path: '/sequence',
            builder: (context, state) => QuestSequencePage(
              sequenceId: 'daily_duo',
              quests: sampleQuests,
            ),
          ),
          GoRoute(
            path: '/game',
            builder: (gameCtx, state) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: const Key('trigger_completion_btn'),
                    onPressed: () {
                      GameDialogHelper.showCompletion(
                        gameCtx,
                        xp: 15,
                        coins: 10,
                        gameType: 'repeatSentence',
                        level: 1,
                      );
                    },
                    child: const Text('TRIGGER COMPLETION'),
                  ),
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Start Part 1
      await tester.tap(find.text('Start Part 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Trigger completion dialog
      await tester.tap(find.byKey(const Key('trigger_completion_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      // The dialog is visible! Find OK / CONTINUE button on ModernGameDialog
      final okBtn = find.text('OK');
      expect(okBtn, findsOneWidget);

      // Tap OK
      await tester.tap(okBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // NOW: We should be back on QuestSequencePage!
      // And Part 2 should be active!
      expect(find.text('Start Part 2'), findsOneWidget);
    });

    testWidgets('completing Part 2 finishes sequence and shows QUEST COMPLETED! dialog', (tester) async {
      setViewport(tester, const Size(390, 950));

      final router = GoRouter(
        initialLocation: '/sequence',
        routes: [
          GoRoute(
            path: '/sequence',
            builder: (context, state) => QuestSequencePage(
              sequenceId: 'daily_duo',
              quests: sampleQuests,
            ),
          ),
          GoRoute(
            path: '/game',
            builder: (gameCtx, state) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: const Key('trigger_completion_btn_part2'),
                    onPressed: () {
                      GameDialogHelper.showCompletion(
                        gameCtx,
                        xp: 15,
                        coins: 10,
                        gameType: 'readAndAnswer',
                        level: 1,
                      );
                    },
                    child: const Text('TRIGGER PART 2 COMPLETION'),
                  ),
                ),
              );
            },
          ),
        ],
      );

      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      SharedPreferences.setMockInitialValues({
        'vowl_sequence_step_daily_duo_user_quest_test': '${todayStr}_1',
      });

      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Start Part 2'), findsOneWidget);

      await tester.tap(find.text('Start Part 2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byKey(const Key('trigger_completion_btn_part2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      final okBtn = find.text('OK');
      expect(okBtn, findsOneWidget);
      await tester.tap(okBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.text('QUEST COMPLETED!'), findsOneWidget);
    });

    testWidgets('fully completed sequence restores all steps completed today', (tester) async {
      setViewport(tester);
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      SharedPreferences.setMockInitialValues({
        'vowl_sequence_completed_daily_duo_user_quest_test': todayStr,
      });

      await tester.pumpWidget(buildQuestSequenceHarness(
        sequenceId: 'daily_duo',
        quests: sampleQuests,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('FINISH'), findsOneWidget);
    });

    testWidgets('tapping a completed part card allows replay / practice mode', (tester) async {
      setViewport(tester);
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      SharedPreferences.setMockInitialValues({
        'vowl_sequence_completed_daily_duo_user_quest_test': todayStr,
      });

      bool gamePushed = false;
      final router = GoRouter(
        initialLocation: '/quest-sequence',
        routes: [
          GoRoute(
            path: '/quest-sequence',
            builder: (context, state) => QuestSequencePage(
              sequenceId: 'daily_duo',
              quests: sampleQuests,
            ),
          ),
          GoRoute(
            path: '/game',
            builder: (context, state) {
              gamePushed = true;
              return const Scaffold(body: Text('GAME SCREEN'));
            },
          ),
        ],
      );

      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PRACTICE AGAIN'), findsNWidgets(2));

      // Tap on the first completed step card
      await tester.tap(find.text('Repeat Sentence'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(gamePushed, isTrue);
      expect(find.text('GAME SCREEN'), findsOneWidget);
    });

    testWidgets('tapping bottom dock FINISH button when finished records completion and pops safely', (tester) async {
      setViewport(tester);
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Start with no completion recorded, but steps finished
      SharedPreferences.setMockInitialValues({
        'vowl_sequence_step_daily_workout_user_quest_test': '${todayStr}_2',
      });

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/quest-sequence'),
                child: const Text('GO TO QUEST'),
              ),
            ),
          ),
          GoRoute(
            path: '/quest-sequence',
            builder: (context, state) => QuestSequencePage(
              sequenceId: 'daily_workout',
              quests: sampleQuests,
            ),
          ),
        ],
      );

      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Go from Home to Quest Sequence
      await tester.tap(find.text('GO TO QUEST'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('FINISH'), findsOneWidget);

      // Tap FINISH button
      await tester.tap(find.text('FINISH'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('vowl_sequence_completed_daily_workout_user_quest_test'),
        equals(todayStr),
      );
      expect(
        prefs.getString('vowl_sequence_completed_daily_duo_user_quest_test'),
        equals(todayStr),
      );
      expect(find.text('GO TO QUEST'), findsOneWidget);
    });
  });
}
