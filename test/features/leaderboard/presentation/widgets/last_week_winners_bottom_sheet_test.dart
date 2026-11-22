import 'package:flutter/material.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/last_week_winners_bottom_sheet.dart';

class MockLocaleService extends Mock implements LocaleService {}

class MockSoundService extends Mock implements SoundService {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocaleService mockLocaleService;
  late MockSoundService mockSoundService;
  late MockAuthBloc mockAuthBloc;

  final targetWeekKey = '2026-W45';

  final testCurrentUserWinnerUnclaimed = UserEntity(
    id: 'user_me_winner',
    email: 'me@vowl.app',
    displayName: 'My Champion Self',
    totalExp: 20000,
    previousRank: 1,
    previousRankWeekKey: targetWeekKey,
    claimedWeeklyRewardWeekKeys: const [],
  );

  final testCurrentUserWinnerClaimed = UserEntity(
    id: 'user_me_winner',
    email: 'me@vowl.app',
    displayName: 'My Champion Self',
    totalExp: 20000,
    previousRank: 1,
    previousRankWeekKey: targetWeekKey,
    claimedWeeklyRewardWeekKeys: [targetWeekKey],
  );

  setUp(() {
    mockLocaleService = MockLocaleService();
    mockSoundService = MockSoundService();
    mockAuthBloc = MockAuthBloc();

    when(() => mockAuthBloc.state).thenReturn(const AuthState.unknown());

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    di.sl.registerSingleton<LocaleService>(mockLocaleService);

    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
    di.sl.registerSingleton<SoundService>(mockSoundService);

    when(
      () => mockLocaleService.tr(
        any(),
        args: any(named: 'args'),
        fallback: any(named: 'fallback'),
      ),
    ).thenAnswer((inv) {
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

    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});
  });

  tearDown(() {
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
  });

  Widget buildTestWidget(Widget child, {UserEntity? currentUser}) {
    if (currentUser != null) {
      when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(currentUser));
    }
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'renders real weekly winners with strictly unique sequential ranks 1 to 10',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Pass 10 winners with some out-of-order or duplicate rank numbers to test sanitization
      final rawWinners = List.generate(10, (i) {
        return {
          'id': 'winner_$i',
          'rank': 10, // Intentionally same number rank to test deduplication!
          'displayName': 'Weekly Learner $i',
          'photoUrl': null,
          'weeklyXp': (10 - i) * 500,
          'currentStreak': 5 + i,
          'weekKey': targetWeekKey,
        };
      });

      await tester.pumpWidget(
        buildTestWidget(
          LastWeekWinnersBottomSheet(
            winners: rawWinners,
            weekKey: targetWeekKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Last Week's Champions"), findsOneWidget);
      expect(find.text('Nov 2 – Nov 8, 2026'), findsOneWidget);

      // Verify ranks 1, 2, 3 have distinct podium icons, VIP labels, and coin values
      expect(find.text('Weekly Learner 0'), findsOneWidget);
      expect(find.text('5000 XP'), findsOneWidget);
      expect(find.text('7d VIP · '), findsOneWidget);
      expect(find.text('+500'), findsOneWidget);

      expect(find.text('Weekly Learner 1'), findsOneWidget);
      expect(find.text('4500 XP'), findsOneWidget);
      expect(find.text('3d VIP · '), findsOneWidget);
      expect(find.text('+300'), findsOneWidget);

      expect(find.text('Weekly Learner 2'), findsOneWidget);
      expect(find.text('4000 XP'), findsOneWidget);
      expect(find.text('1d VIP · '), findsOneWidget);
      expect(find.text('+200'), findsOneWidget);

      // Check ranks 4 through 10 have proper unique #4..#10 badges
      expect(find.text('#4'), findsOneWidget);
      expect(find.text('#5'), findsOneWidget);
      expect(find.text('#6'), findsOneWidget);
      expect(find.text('#7'), findsOneWidget);
      expect(find.text('#8'), findsOneWidget);
      expect(find.text('#9'), findsOneWidget);
      expect(find.text('#10'), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on_rounded), findsWidgets);
    },
  );

  testWidgets(
    'never displays global all-time users as weekly winners when no weekly data exists',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 10 all-time global users with totalExp, but previousRankWeekKey does not match weekly and no weekly XP
      final globalUsers = List.generate(10, (i) {
        return UserEntity(
          id: 'global_user_$i',
          email: 'global_$i@vowl.app',
          displayName: 'Global AllTime $i',
          totalExp: 50000 - (i * 1000),
          previousRank: i + 1,
          previousRankWeekKey: '2025-W01', // ancient/unmatched week key
          dailyXpHistory: const {}, // 0 weekly XP
        );
      });

      await tester.pumpWidget(
        buildTestWidget(
          LastWeekWinnersBottomSheet(
            winners: const [],
            allUsers: globalUsers,
            weekKey: targetWeekKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must NOT display global users
      expect(find.text('Global AllTime 0'), findsNothing);
      expect(find.text('Global AllTime 1'), findsNothing);

      // Must display clean prize tier overview explaining finalization
      expect(find.text('Weekly League Prize Tiers'), findsOneWidget);
      expect(find.text('Weekly results finalize every Sunday at 23:59 UTC. Complete quests this week to secure a top 10 spot!'), findsOneWidget);
    },
  );

  testWidgets(
    'shows claim button when current user placed in top 3 and has not claimed, and executes claim',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool claimInvoked = false;

      final winners = [
        {
          'id': testCurrentUserWinnerUnclaimed.id,
          'rank': 1,
          'displayName': testCurrentUserWinnerUnclaimed.displayName,
          'photoUrl': null,
          'weeklyXp': 6500,
          'currentStreak': 14,
          'weekKey': targetWeekKey,
        },
        {
          'id': 'winner_runner_up',
          'rank': 2,
          'displayName': 'Second Place Champ',
          'photoUrl': null,
          'weeklyXp': 5200,
          'currentStreak': 10,
          'weekKey': targetWeekKey,
        },
      ];

      await tester.pumpWidget(
        buildTestWidget(
          LastWeekWinnersBottomSheet(
            winners: winners,
            currentUser: testCurrentUserWinnerUnclaimed,
            weekKey: targetWeekKey,
            onClaimReward: (rank, vipDays, coins, weekKey) async {
              claimInvoked = true;
            },
          ),
          currentUser: testCurrentUserWinnerUnclaimed,
        ),
      );
      await tester.pumpAndSettle();

      // Spotlight banner shows user's finish and claim button
      expect(find.text('YOUR FINISH · RANK #1'), findsOneWidget);
      expect(find.text('Weekly League Champion'), findsOneWidget);
      expect(find.text('Claim Reward (7d VIP · '), findsOneWidget);
      expect(find.text('+500)'), findsOneWidget);

      // Tap Claim
      await tester.tap(find.text('Claim Reward (7d VIP · '));
      await tester.pumpAndSettle();

      expect(claimInvoked, isTrue);
    },
  );

  testWidgets(
    'shows claimed state with exact numbers when current user already claimed reward',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final winners = [
        {
          'id': testCurrentUserWinnerClaimed.id,
          'rank': 1,
          'displayName': testCurrentUserWinnerClaimed.displayName,
          'photoUrl': null,
          'weeklyXp': 6500,
          'currentStreak': 14,
          'weekKey': targetWeekKey,
        },
      ];

      await tester.pumpWidget(
        buildTestWidget(
          LastWeekWinnersBottomSheet(
            winners: winners,
            currentUser: testCurrentUserWinnerClaimed,
            weekKey: targetWeekKey,
          ),
          currentUser: testCurrentUserWinnerClaimed,
        ),
      );
      await tester.pumpAndSettle();

      // Spotlight banner shows Claimed with exact numbers
      expect(find.text('YOUR FINISH · RANK #1'), findsOneWidget);
      expect(find.text('Claimed: '), findsOneWidget);
      expect(find.text('7d VIP · '), findsNWidgets(2)); // in banner and card
      expect(find.text('+500'), findsNWidgets(2)); // in banner and card
      // No claim button
      expect(find.text('Claim Reward (7d VIP · '), findsNothing);
      // Winner card in list also shows Claimed status
      expect(find.text('Claimed'), findsOneWidget);
    },
  );

  testWidgets(
    'preserves Rank #4 for 4th-place finisher based on exact weekly XP and enables 100 coin claim',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? claimedRank;
      int? claimedCoins;

      final testFourthPlaceUser = UserEntity(
        id: 'user_rank_4',
        email: 'rank4@vowl.app',
        displayName: 'Fourth Place Winner',
        totalExp: 12000,
        previousRank: 4,
        previousRankWeekKey: targetWeekKey,
        dailyXpHistory: {'2026-11-04': 850}, // 4th highest XP
        claimedWeeklyRewardWeekKeys: const [],
      );

      // Top 3 users with higher weekly XP
      final top3Users = [
        UserEntity(
          id: 'user_top_1',
          email: 'top1@vowl.app',
          displayName: 'Finisher 1',
          totalExp: 15000,
          dailyXpHistory: {'2026-11-04': 1000}, // Rank 1
        ),
        UserEntity(
          id: 'user_top_2',
          email: 'top2@vowl.app',
          displayName: 'Finisher 2',
          totalExp: 14000,
          dailyXpHistory: {'2026-11-04': 950}, // Rank 2
        ),
        UserEntity(
          id: 'user_top_3',
          email: 'top3@vowl.app',
          displayName: 'Finisher 3',
          totalExp: 13000,
          dailyXpHistory: {'2026-11-04': 900}, // Rank 3
        ),
      ];

      // 6 lower users to complete the top 10
      final lowerUsers = List.generate(6, (i) {
        return UserEntity(
          id: 'user_lower_$i',
          email: 'lower_$i@vowl.app',
          displayName: 'Finisher ${i + 5}',
          totalExp: 9000 - (i * 500),
          dailyXpHistory: {'2026-11-04': 800 - (i * 50)}, // Ranks 5 to 10
        );
      });

      await tester.pumpWidget(
        buildTestWidget(
          LastWeekWinnersBottomSheet(
            winners: const [],
            allUsers: [...top3Users, testFourthPlaceUser, ...lowerUsers],
            currentUser: testFourthPlaceUser,
            weekKey: targetWeekKey,
            onClaimReward: (rank, vipDays, coins, weekKey) async {
              claimedRank = rank;
              claimedCoins = coins;
            },
          ),
          currentUser: testFourthPlaceUser,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Authoritative Rank #4 Check: User must NEVER be forced to Rank #1
      expect(find.text('YOUR FINISH · RANK #4'), findsOneWidget);
      expect(find.text('Weekly Top 10 Finisher'), findsOneWidget);
      expect(find.text('YOUR FINISH · RANK #1'), findsNothing);
      expect(find.text('Weekly League Champion'), findsNothing);

      // 2. Full Top 10 Slotting: All 10 ranks must be present
      expect(find.text('#4'), findsOneWidget);
      expect(find.text('#5'), findsOneWidget);
      expect(find.text('#10'), findsOneWidget);
      expect(find.text('YOU'), findsOneWidget);

      // 3. Claim button for 100 coins
      expect(find.text('Claim Reward ('), findsOneWidget);
      expect(find.text('+100)'), findsOneWidget);

      // Tap Claim
      await tester.tap(find.text('Claim Reward ('));
      await tester.pumpAndSettle();

      expect(claimedRank, equals(4));
      expect(claimedCoins, equals(100));
    },
  );

  testWidgets(
    'orders winners strictly descending by weekly XP (95 XP user ranks ahead of 30 XP user)',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // User with 95 XP, user with 85 XP, user with 30 XP
      final userWith95Xp = UserEntity(
        id: 'user_95_xp',
        email: 'user95@vowl.app',
        displayName: 'User 95 XP',
        dailyXpHistory: {'2026-11-04': 95},
      );

      final userWith85Xp = UserEntity(
        id: 'user_85_xp',
        email: 'user85@vowl.app',
        displayName: 'User 85 XP',
        dailyXpHistory: {'2026-11-04': 85},
      );

      final userWith30Xp = UserEntity(
        id: 'user_30_xp',
        email: 'user30@vowl.app',
        displayName: 'User 30 XP',
        dailyXpHistory: {'2026-11-04': 30},
      );

      await tester.pumpWidget(
        buildTestWidget(
          LastWeekWinnersBottomSheet(
            winners: const [],
            // Pass out of order: 30 XP, 95 XP, 85 XP
            allUsers: [userWith30Xp, userWith95Xp, userWith85Xp],
            currentUser: userWith95Xp,
            weekKey: targetWeekKey,
          ),
          currentUser: userWith95Xp,
        ),
      );
      await tester.pumpAndSettle();

      // User 95 XP MUST be Rank #1 (Champion)
      expect(find.text('YOUR FINISH · RANK #1'), findsOneWidget);
      expect(find.text('User 95 XP'), findsOneWidget);
      expect(find.text('95 XP'), findsOneWidget);

      // User 85 XP is 2nd
      expect(find.text('User 85 XP'), findsOneWidget);
      expect(find.text('85 XP'), findsOneWidget);

      // User 30 XP is 3rd
      expect(find.text('User 30 XP'), findsOneWidget);
      expect(find.text('30 XP'), findsOneWidget);
    },
  );
}
