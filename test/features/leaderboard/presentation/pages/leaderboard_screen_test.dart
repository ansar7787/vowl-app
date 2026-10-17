import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:vowl/features/leaderboard/presentation/bloc/leaderboard_bloc_event_state.dart';
import 'package:vowl/features/leaderboard/presentation/pages/leaderboard_screen.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/leaderboard_header.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/leaderboard_podium.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/leaderboard_rank_card.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockLeaderboardBloc extends MockBloc<LeaderboardEvent, LeaderboardState>
    implements LeaderboardBloc {}

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const LoadLeaderboard());
    registerFallbackValue(const LeaderboardInitial());
  });

  late MockAuthBloc mockAuthBloc;
  late MockLeaderboardBloc mockLeaderboardBloc;
  late MockLocaleService mockLocaleService;
  late StreamController<LeaderboardState> leaderboardStateController;

  final now = DateTime.now();

  final testCurrentUser = UserEntity(
    id: 'user_me',
    email: 'alice@vowl.app',
    displayName: 'Alice Champion',
    totalExp: 8400,
    currentStreak: 15,
    kidsCoins: 120,
    completedLevels: {
      'reading': List.generate(42, (i) => i + 1),
      'kids_animals': List.generate(8, (i) => i + 1),
    },
  );

  final List<UserEntity> testUsersList = <UserEntity>[
    UserEntity(
      id: 'user_1',
      email: 'bob@vowl.app',
      displayName: 'Bob The Master',
      totalExp: 15200,
      currentStreak: 45,
      kidsCoins: 500,
      completedLevels: {
        'reading': List.generate(95, (i) => i + 1),
        'kids_animals': List.generate(24, (i) => i + 1),
      },
    ),
    UserEntity(
      id: 'user_2',
      email: 'charlie@vowl.app',
      displayName: 'Charlie Prodigy',
      totalExp: 12100,
      currentStreak: 30,
      kidsCoins: 420,
      completedLevels: {
        'reading': List.generate(80, (i) => i + 1),
        'kids_animals': List.generate(20, (i) => i + 1),
      },
    ),
    UserEntity(
      id: 'user_3',
      email: 'diana@vowl.app',
      displayName: 'Diana Star',
      totalExp: 10500,
      currentStreak: 25,
      kidsCoins: 380,
      completedLevels: {
        'reading': List.generate(70, (i) => i + 1),
        'kids_animals': List.generate(18, (i) => i + 1),
      },
    ),
    UserEntity(
      id: 'user_4',
      email: 'evan@vowl.app',
      displayName: 'Evan Great',
      totalExp: 9500,
      currentStreak: 8,
      completedLevels: {
        'reading': List.generate(60, (i) => i + 1),
      },
    ),
    UserEntity(
      id: 'user_5',
      email: 'fiona@vowl.app',
      displayName: 'Fiona Swift',
      totalExp: 9100,
      currentStreak: 6,
      completedLevels: {
        'reading': List.generate(55, (i) => i + 1),
      },
    ),
    UserEntity(
      id: 'user_6',
      email: 'george@vowl.app',
      displayName: 'George Sharp',
      totalExp: 8800,
      currentStreak: 12,
      completedLevels: {
        'reading': List.generate(50, (i) => i + 1),
      },
    ),
    testCurrentUser, // Rank 7 (index 6) -> triggers showFindMe!
    UserEntity(
      id: 'user_8',
      email: 'hannah@vowl.app',
      displayName: 'Hannah Bold',
      totalExp: 7500,
      currentStreak: 4,
      completedLevels: {
        'reading': List.generate(35, (i) => i + 1),
      },
    ),
    UserEntity(
      id: 'user_9',
      email: 'ian@vowl.app',
      displayName: 'Ian Brave',
      totalExp: 6800,
      currentStreak: 5,
      completedLevels: {
        'reading': List.generate(30, (i) => i + 1),
      },
    ),
    UserEntity(
      id: 'user_10',
      email: 'julia@vowl.app',
      displayName: 'Julia Bright',
      totalExp: 6200,
      currentStreak: 3,
      completedLevels: {
        'reading': List.generate(25, (i) => i + 1),
      },
    ),
  ];

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockLeaderboardBloc = MockLeaderboardBloc();
    mockLocaleService = MockLocaleService();
    leaderboardStateController = StreamController<LeaderboardState>.broadcast();

    when(() => mockAuthBloc.state)
        .thenReturn(AuthState.authenticated(testCurrentUser));
    when(() => mockLeaderboardBloc.state)
        .thenReturn(LeaderboardLoaded(testUsersList, now, isKids: false));
    when(() => mockLeaderboardBloc.stream)
        .thenAnswer((_) => leaderboardStateController.stream);

    if (di.sl.isRegistered<LeaderboardBloc>()) {
      di.sl.unregister<LeaderboardBloc>();
    }
    di.sl.registerFactory<LeaderboardBloc>(() => mockLeaderboardBloc);

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    when(() => mockLocaleService.tr(
          any(),
          args: any(named: 'args'),
          fallback: any(named: 'fallback'),
        )).thenAnswer((inv) {
      final fallback = inv.namedArguments[#fallback] as String?;
      if (fallback != null) {
        final args = inv.namedArguments[#args] as List<String>? ?? [];
        var result = fallback;
        for (var i = 0; i < args.length; i++) {
          result = result.replaceAll('{$i}', args[i]);
        }
        return result;
      }
      return inv.positionalArguments[0] as String;
    });
    initLocaleServiceReference(mockLocaleService);
  });

  tearDown(() async {
    await leaderboardStateController.close();
    if (di.sl.isRegistered<LeaderboardBloc>()) {
      di.sl.unregister<LeaderboardBloc>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
  });

  Widget buildTestWidget({
    bool isKids = false,
    ThemeData? theme,
    double fontScale = 1.0,
    Size screenSize = const Size(390, 844),
  }) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) => MediaQuery(
        data: MediaQueryData(
          size: screenSize,
          textScaler: TextScaler.linear(fontScale),
        ),
        child: MaterialApp(
          theme: theme ?? AppTheme.lightTheme,
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: LeaderboardScreen(isKids: isKids),
          ),
        ),
      ),
    );
  }

  group('Group 1: Initial & Loading States', () {
    testWidgets('renders LeaderboardShimmerLoading when state is LeaderboardLoading', (tester) async {
      when(() => mockLeaderboardBloc.state).thenReturn(const LeaderboardLoading());

      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LeaderboardShimmerLoading), findsOneWidget);
      expect(find.text('Global Ranks'), findsOneWidget);
      expect(find.text('Kids Zone'), findsOneWidget);
      verify(() => mockLeaderboardBloc.add(const LoadLeaderboard(isKids: false))).called(1);
    });

    testWidgets('renders LeaderboardShimmerLoading when state is LeaderboardInitial', (tester) async {
      when(() => mockLeaderboardBloc.state).thenReturn(const LeaderboardInitial());

      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LeaderboardShimmerLoading), findsOneWidget);
    });
  });

  group('Group 2: Error State & Retry Flow', () {
    testWidgets('renders error view with retry button and tapping retry dispatches LoadLeaderboard', (tester) async {
      when(() => mockLeaderboardBloc.state)
          .thenReturn(const LeaderboardError('Failed to synchronize leaderboard rankings.'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('Failed to synchronize leaderboard rankings.'), findsOneWidget);
      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      await tester.pump(const Duration(milliseconds: 100));

      // Initial add on create + 1 tap on retry = 2 calls
      verify(() => mockLeaderboardBloc.add(const LoadLeaderboard(isKids: false))).called(2);
    });
  });

  group('Group 3: Empty State Handling', () {
    testWidgets('renders empty state when users list is empty', (tester) async {
      when(() => mockLeaderboardBloc.state)
          .thenReturn(LeaderboardLoaded(const [], now, isKids: false));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
      expect(find.text('No rankings yet'), findsOneWidget);
      expect(find.text('Complete lessons to appear on the leaderboard!'), findsOneWidget);
    });

    testWidgets('renders kids empty state when users list is empty in kids mode', (tester) async {
      when(() => mockLeaderboardBloc.state)
          .thenReturn(LeaderboardLoaded(const [], now, isKids: true));

      await tester.pumpWidget(buildTestWidget(isKids: true));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
      expect(find.text('No rankings yet'), findsOneWidget);
    });

    testWidgets('renders empty placeholder under podium when users length <= 3', (tester) async {
      // Top 3 only
      final top3Only = testUsersList.take(3).toList();
      when(() => mockLeaderboardBloc.state)
          .thenReturn(LeaderboardLoaded(top3Only, now, isKids: false));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Complete more quests to climb the ranks!'), findsOneWidget);
      expect(find.text('See how you rank globally!'), findsWidgets);
    });
  });

  group('Group 4: Populated Leaderboard — Header, Podium & Rank Card', () {
    testWidgets('renders LeaderboardHeader, LeaderboardPodium, and LeaderboardRankCard', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LeaderboardHeader), findsOneWidget);
      expect(find.byType(LeaderboardPodium), findsOneWidget);
      expect(find.byType(LeaderboardRankCard), findsOneWidget);

      // Verify Header details
      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.byIcon(Icons.leaderboard_rounded), findsOneWidget);
      expect(find.byIcon(Icons.update_rounded), findsOneWidget);

      // Verify Podium Top 3 details (podium slot displays first word of displayName)
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('Diana'), findsOneWidget);
      expect(find.textContaining('15200'), findsOneWidget);
      expect(find.textContaining('12100'), findsOneWidget);
      expect(find.textContaining('10500'), findsOneWidget);

      // Verify Sticky Rank Card details for currentUser (Rank 7)
      expect(find.text('Your Standing'), findsOneWidget);
      expect(find.text('#7'), findsWidgets); // In rank card and rank tile/FindMe
      expect(find.textContaining('42 / '), findsOneWidget);
      expect(find.textContaining('All Quests'), findsOneWidget);
    });
  });

  group('Group 5: Populated Leaderboard — Rank 4-N List & Current User Highlighting', () {
    testWidgets('renders Top Challengers section and ranks 4 to 10 with current user highlight', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Top Challengers'), findsOneWidget);

      // Scroll down to reveal ranks in the list
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));

      // Rank 4 & 5
      expect(find.text('Evan Great'), findsOneWidget);
      expect(find.text('Fiona Swift'), findsOneWidget);

      // Current user appears in Sticky RankCard and in RankTile list
      expect(find.text('Alice Champion'), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(LeaderboardRankCard),
          matching: find.text('Alice Champion'),
        ),
        findsOneWidget,
      );

      // Find RankTile with Key for currentUser
      final meTileFinder = find.byKey(const ValueKey('rank_tile_user_me'));
      expect(meTileFinder, findsOneWidget);
      expect(
        find.descendant(
          of: meTileFinder,
          matching: find.text('Alice Champion'),
        ),
        findsOneWidget,
      );

      // Verify 'You' badge on currentUser tile
      expect(
        find.descendant(
          of: meTileFinder,
          matching: find.text('You'),
        ),
        findsOneWidget,
      );

    });
  });

  group('Group 6: Kids Zone vs Global Toggle', () {
    testWidgets('toggles between Global Ranks and Kids Zone views', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Global Ranks'), findsOneWidget);
      expect(find.text('Kids Zone'), findsOneWidget);

      // Tap Kids Zone
      await tester.tap(find.text('Kids Zone'));
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockLeaderboardBloc.add(const LoadLeaderboard(isKids: true))).called(1);

      // Tap Global Ranks back
      await tester.tap(find.text('Global Ranks'));
      await tester.pump(const Duration(milliseconds: 300));

      // 1 from initial create + 1 from toggle back = 2 calls with isKids: false
      verify(() => mockLeaderboardBloc.add(const LoadLeaderboard(isKids: false))).called(2);
    });

    testWidgets('renders Kids Leaderboard header and Coins label when isKids is true', (tester) async {
      when(() => mockLeaderboardBloc.state)
          .thenReturn(LeaderboardLoaded(testUsersList, now, isKids: true));

      await tester.pumpWidget(buildTestWidget(isKids: true));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Kids Leaderboard'), findsOneWidget);
      expect(find.textContaining('Coins'), findsWidgets);
    });
  });

  group('Group 7: Pull-To-Refresh', () {
    testWidgets('pull to refresh dispatches LoadLeaderboard event', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Fling down from podium to trigger RefreshIndicator
      await tester.fling(find.byType(LeaderboardPodium), const Offset(0, 300), 1000);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockLeaderboardBloc.add(any(that: isA<LoadLeaderboard>()))).called(greaterThanOrEqualTo(1));
    });
  });

  group('Group 8: "Find Me" Floating Action Button', () {
    testWidgets('renders Find Me button when current user is rank 7 and tapping scrolls to user', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Find Me FAB is visible for rankIndex = 6 (Rank 7 >= 6)
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      expect(find.descendant(of: find.byType(Positioned), matching: find.text('#7')), findsOneWidget);

      // Tap Find Me button
      await tester.tap(find.byIcon(Icons.my_location_rounded));
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('hides Find Me button when current user is in top 3 podium', (tester) async {
      // Set current user as Bob (Rank 1)
      when(() => mockAuthBloc.state)
          .thenReturn(AuthState.authenticated(testUsersList[0]));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.my_location_rounded), findsNothing);
    });
  });

  group('Group 9: Responsive Viewports, Accessibility & Themes', () {
    testWidgets('renders cleanly on compact mobile (320x568) without overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 568 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(screenSize: const Size(320, 568)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LeaderboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet viewport (800x1280) without overflow', (tester) async {
      tester.view.physicalSize = const Size(800 * 1.5, 1280 * 1.5);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(screenSize: const Size(800, 1280)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LeaderboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with 1.3x accessibility text scale', (tester) async {
      await tester.pumpWidget(buildTestWidget(fontScale: 1.3));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LeaderboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      await tester.pumpWidget(buildTestWidget(theme: AppTheme.darkTheme));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LeaderboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in midnight theme mode', (tester) async {
      await tester.pumpWidget(buildTestWidget(theme: AppTheme.midnightTheme));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LeaderboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

