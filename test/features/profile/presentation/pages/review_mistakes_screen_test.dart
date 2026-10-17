import 'dart:convert';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/profile/presentation/pages/review_mistakes_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockTtsService extends Mock implements TtsService {}

class MockAdService extends Mock implements AdService {}

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;
  late MockTtsService mockTtsService;
  late MockAdService mockAdService;
  late MockAppLogger mockLogger;
  late List<String> navigatedRoutes;

  const testUser = UserEntity(
    id: 'local',
    email: 'guest@vowl.app',
    displayName: 'Local Guest',
    isPremium: true,
  );

  final now = DateTime.now();

  Map<String, dynamic> makeEntryJson({
    required String id,
    required String gameType,
    required String question,
    required String userAnswer,
    required String correctAnswer,
    int level = 1,
    DateTime? timestamp,
  }) {
    return {
      'id': id,
      'gameType': gameType,
      'question': question,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'level': level,
      'timestamp': (timestamp ?? now).toIso8601String(),
    };
  }

  Future<void> setJournalEntries(List<String> entries) async {
    SharedPreferences.setMockInitialValues({
      'vowl_local_error_journal': entries,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('vowl_local_error_journal', entries);
  }

  setUpAll(() {
    registerFallbackValue(const AuthReloadUser());
  });

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    navigatedRoutes = [];

    mockAuthBloc = MockAuthBloc();
    mockHapticService = MockHapticService();
    mockLocaleService = MockLocaleService();
    mockTtsService = MockTtsService();
    mockAdService = MockAdService();
    mockLogger = MockAppLogger();

    when(() => mockAuthBloc.state)
        .thenReturn(AuthState.authenticated(testUser));

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});

    when(() => mockTtsService.speak(any(), rate: any(named: 'rate')))
        .thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    when(() => mockLocaleService.tr(
          any(),
          args: any(named: 'args'),
          fallback: any(named: 'fallback'),
        )).thenAnswer((invocation) {
      final key = invocation.positionalArguments[0] as String;
      final args = (invocation.namedArguments[#args] as List<String>?) ?? [];
      final fallback = invocation.namedArguments[#fallback] as String?;
      String text = fallback ?? key;
      for (int i = 0; i < args.length; i++) {
        text = text.replaceAll('{$i}', args[i]);
      }
      return text;
    });
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    initLocaleServiceReference(mockLocaleService);

    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    di.sl.registerSingleton<TtsService>(mockTtsService);

    if (di.sl.isRegistered<AdService>()) {
      di.sl.unregister<AdService>();
    }
    di.sl.registerSingleton<AdService>(mockAdService);

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    di.sl.registerSingleton<AppLogger>(mockLogger);
  });

  Widget buildTestWidget({
    Size screenSize = const Size(390, 844),
    ThemeMode themeMode = ThemeMode.light,
    double textScaleFactor = 1.0,
    bool startAtRoot = false,
  }) {
    final router = GoRouter(
      initialLocation: startAtRoot ? '/' : '/review-mistakes',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/review-mistakes'),
                child: const Text('Root Route'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/review-mistakes',
          builder: (context, state) => const ReviewMistakesScreen(),
        ),
        GoRoute(
          path: '/game',
          builder: (context, state) {
            final cat = state.uri.queryParameters['category'] ?? '';
            final sub = state.uri.queryParameters['subtype'] ?? '';
            final lvl = state.uri.queryParameters['level'] ?? '';
            navigatedRoutes.add('/game?category=$cat&subtype=$sub&level=$lvl');
            return Scaffold(body: Text('Game Screen: $cat - $sub - $lvl'));
          },
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MediaQuery(
          data: MediaQueryData(
            size: screenSize,
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: MaterialApp.router(
            routerConfig: router,
            themeMode: themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
          ),
        ),
      ),
    );
  }

  group('Group 1: Empty State', () {
    testWidgets('renders empty state when error journal has zero mistakes', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': <String>[],
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(find.text("You're All Caught Up!"), findsOneWidget);
      expect(find.text('You have mastered all your past challenges.'), findsOneWidget);
    });
  });

  group('Group 2: Populated State & Card Rendering', () {
    testWidgets('renders mistake cards with question, answer, level, and timestamp', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': <String>[
          jsonEncode(makeEntryJson(
            id: 'mistake_1',
            gameType: 'consonantClarity',
            question: 'Pronounce the "th" consonant clearly',
            userAnswer: 'f',
            correctAnswer: 'th',
            level: 2,
          )),
          jsonEncode(makeEntryJson(
            id: 'mistake_2',
            gameType: 'articleInsertion',
            question: 'Choose the correct article for "apple"',
            userAnswer: 'a',
            correctAnswer: 'an',
            level: 1,
          )),
        ],
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Pronounce the "th" consonant clearly'), findsOneWidget);
      expect(find.text('Choose the correct article for "apple"'), findsOneWidget);
      expect(find.text('Lv.2'), findsOneWidget);
      expect(find.text('Lv.1'), findsOneWidget);
      expect(find.text('Tap to Reveal Answer'), findsNWidgets(2));
    });
  });

  group('Group 3: Card Interaction (Reveal & Audio TTS)', () {
    testWidgets('tapping card reveals correct answer and speaker icon plays TTS audio', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': <String>[
          jsonEncode(makeEntryJson(
            id: 'mistake_tts_1',
            gameType: 'consonantClarity',
            question: 'Say "thoughtful"',
            userAnswer: 'thoughtful_miss',
            correctAnswer: 'thoughtful',
            level: 3,
          )),
        ],
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tap to Reveal Answer'), findsOneWidget);
      expect(find.text('thoughtful'), findsNothing);

      // Tap card to reveal
      await tester.tap(find.text('Tap to Reveal Answer'));
      await tester.pumpAndSettle();

      expect(find.text('thoughtful'), findsOneWidget);
      expect(find.byIcon(LucideIcons.volume2), findsOneWidget);

      // Tap volume button to speak
      await tester.tap(find.byIcon(LucideIcons.volume2));
      await tester.pumpAndSettle();

      verify(() => mockTtsService.speak('thoughtful')).called(1);
    });
  });

  group('Group 4: Dismissing Mistakes via Swipe', () {
    testWidgets('swiping card dismisses it from journal', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': <String>[
          jsonEncode(makeEntryJson(
            id: 'dismiss_entry_1',
            gameType: 'consonantClarity',
            question: 'Mistake to Dismiss',
            userAnswer: 'wrong_ans',
            correctAnswer: 'right_ans',
          )),
        ],
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Mistake to Dismiss'), findsOneWidget);

      // Swipe card from right to left
      await tester.drag(find.text('Mistake to Dismiss'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Mistake to Dismiss'), findsNothing);
      expect(find.text("You're All Caught Up!"), findsOneWidget);
    });

    testWidgets('swipe background has solid red color and white trash icon without gradient', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': <String>[
          jsonEncode(makeEntryJson(
            id: 'dismiss_entry_bg',
            gameType: 'consonantClarity',
            question: 'Mistake Background Test',
            userAnswer: 'wrong_ans',
            correctAnswer: 'right_ans',
          )),
        ],
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      final background = dismissible.background as Container;
      final decoration = background.decoration as BoxDecoration;
      expect(decoration.color, AppColors.red500);
      expect(decoration.gradient, isNull);

      final icon = background.child as Icon;
      expect(icon.icon, LucideIcons.trash2);
      expect(icon.color, Colors.white);
    });
  });

  group('Group 5: Category Filter Chips', () {
    testWidgets('formats elite_mastery category as "Elite Mastery" without underscore', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': <String>[
          jsonEncode(makeEntryJson(
            id: 'entry_elite',
            gameType: 'storyBuilder',
            question: 'Elite Story Question',
            userAnswer: 'wrong',
            correctAnswer: 'right',
          )),
        ],
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Elite Mastery'), findsOneWidget);
      expect(find.text('Elite_Mastery'), findsNothing);
      expect(find.text('Elite_mastery'), findsNothing);

      // Tap Elite Mastery chip
      await tester.tap(find.text('Elite Mastery'));
      await tester.pumpAndSettle();
      expect(find.text('Elite Story Question'), findsOneWidget);
    });

    testWidgets('filtering by category displays only matching mistakes and resetting restores all', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': <String>[
          jsonEncode(makeEntryJson(
            id: 'entry_accent',
            gameType: 'consonantClarity',
            question: 'Accent Drill Question',
            userAnswer: 'a_wrong',
            correctAnswer: 'a_right',
          )),
          jsonEncode(makeEntryJson(
            id: 'entry_grammar',
            gameType: 'articleInsertion',
            question: 'Grammar Question',
            userAnswer: 'g_wrong',
            correctAnswer: 'g_right',
          )),
        ],
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Accent Drill Question'), findsOneWidget);
      expect(find.text('Grammar Question'), findsOneWidget);

      // Tap Grammar chip
      await tester.tap(find.text('Grammar'));
      await tester.pumpAndSettle();

      expect(find.text('Grammar Question'), findsOneWidget);
      expect(find.text('Accent Drill Question'), findsNothing);

      // Tap All chip to reset
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('Accent Drill Question'), findsOneWidget);
      expect(find.text('Grammar Question'), findsOneWidget);
    });
  });

  group('Group 6: Pagination', () {
    testWidgets('renders pagination controls and navigating forward/backward updates page', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final List<String> twelveEntries = [];
      for (int i = 1; i <= 12; i++) {
        twelveEntries.add(jsonEncode(makeEntryJson(
          id: 'entry_page_$i',
          gameType: 'consonantClarity',
          question: 'Question Number $i',
          userAnswer: 'u_$i',
          correctAnswer: 'c_$i',
        )));
      }

      await setJournalEntries(twelveEntries);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to pagination controls at bottom
      for (int i = 0; i < 4; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
        await tester.pumpAndSettle();
      }

      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      // Tap next page
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      for (int i = 0; i < 4; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
        await tester.pumpAndSettle();
      }

      expect(find.text('2 / 2'), findsOneWidget);

      // Tap previous page
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      for (int i = 0; i < 4; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
        await tester.pumpAndSettle();
      }

      expect(find.text('1 / 2'), findsOneWidget);
    });
  });

  group('Group 7: Start Mastery Training Button', () {
    testWidgets('tapping Start Mastery Training navigates to game screen', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': <String>[
          jsonEncode(makeEntryJson(
            id: 'training_1',
            gameType: 'consonantClarity',
            question: 'Practice item',
            userAnswer: 'wrong',
            correctAnswer: 'right',
            level: 3,
          )),
        ],
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final trainingButton = find.text('Start Mastery Training');
      expect(trainingButton, findsOneWidget);

      await tester.tap(trainingButton);
      await tester.pumpAndSettle();

      expect(navigatedRoutes.any((r) => r.startsWith('/game?category=accent&subtype=consonantClarity&level=3')), isTrue);
    });
  });

  group('Group 8: AppBar & Back Navigation', () {
    testWidgets('tapping back button in SliverAppBar pops screen', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': <String>[],
      });

      await tester.pumpWidget(buildTestWidget(startAtRoot: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Root Route'));
      await tester.pumpAndSettle();

      expect(find.text('Review & Master'), findsOneWidget);

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Root Route'), findsOneWidget);
    });
  });

  group('Group 9: Responsiveness & Themes', () {
    testWidgets('renders cleanly on compact mobile (320x568) without overflow', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': <String>[
          jsonEncode(makeEntryJson(
            id: 'comp_1',
            gameType: 'consonantClarity',
            question: 'Compact Question',
            userAnswer: 'u',
            correctAnswer: 'c',
          )),
        ],
      });

      await tester.pumpWidget(buildTestWidget(
        screenSize: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet viewport (800x1280) without overflow', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': <String>[
          jsonEncode(makeEntryJson(
            id: 'tab_1',
            gameType: 'consonantClarity',
            question: 'Tablet Question',
            userAnswer: 'u',
            correctAnswer: 'c',
          )),
        ],
      });

      await tester.pumpWidget(buildTestWidget(
        screenSize: const Size(800, 1280),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with 1.3x accessibility text scale', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': <String>[
          jsonEncode(makeEntryJson(
            id: 'a11y_1',
            gameType: 'consonantClarity',
            question: 'A11y Question',
            userAnswer: 'u',
            correctAnswer: 'c',
          )),
        ],
      });

      await tester.pumpWidget(buildTestWidget(
        textScaleFactor: 1.3,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': <String>[
          jsonEncode(makeEntryJson(
            id: 'dark_1',
            gameType: 'consonantClarity',
            question: 'Dark Question',
            userAnswer: 'u',
            correctAnswer: 'c',
          )),
        ],
      });

      await tester.pumpWidget(buildTestWidget(
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in midnight theme mode', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': <String>[
          jsonEncode(makeEntryJson(
            id: 'mid_1',
            gameType: 'consonantClarity',
            question: 'Midnight Question',
            userAnswer: 'u',
            correctAnswer: 'c',
          )),
        ],
      });

      final midnightTheme = AppTheme.darkTheme.copyWith(
        scaffoldBackgroundColor: Colors.black,
      );

      final router = GoRouter(
        initialLocation: '/review-mistakes',
        routes: [
          GoRoute(
            path: '/review-mistakes',
            builder: (context, state) => const ReviewMistakesScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) => MaterialApp.router(
              routerConfig: router,
              theme: midnightTheme,
              darkTheme: midnightTheme,
              themeMode: ThemeMode.dark,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
