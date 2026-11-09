import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/referral/domain/entities/referral_info.dart';
import 'package:vowl/features/referral/domain/repositories/referral_repository.dart';
import 'package:vowl/features/referral/presentation/pages/referral_hub_screen.dart';
import 'package:vowl/features/referral/presentation/widgets/monthly_cup_leaderboard.dart';
import 'package:vowl/features/referral/presentation/widgets/referral_stats_card.dart';

class MockReferralRepository extends Mock implements ReferralRepository {}

class MockHapticService extends Mock implements HapticService {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReferralRepository mockReferralRepo;
  late MockHapticService mockHapticService;
  late MockAuthBloc mockAuthBloc;

  const testUser = UserEntity(
    id: 'user_ambassador',
    email: 'ambassador@vowl.app',
    displayName: 'Ambassador Lex',
    coins: 400,
    totalReferralsCount: 2,
    monthlyReferralsCount: 0,
    referralCode: 'VOWL-AMBASSADOR',
  );

  final nowUtc = DateTime.now().toUtc();
  final currentMonthKey =
      '${nowUtc.year}-${nowUtc.month.toString().padLeft(2, '0')}';

  final testUserQualified = UserEntity(
    id: 'user_ambassador_qualified',
    email: 'qualified@vowl.app',
    displayName: 'Champion Lex',
    coins: 800,
    totalReferralsCount: 5,
    monthlyReferralsCount: 2,
    currentReferralMonthKey: currentMonthKey,
    referralCode: 'VOWL-CHAMP',
  );

  setUpAll(() {
    registerFallbackValue(testUser);
  });

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockReferralRepo = MockReferralRepository();
    mockHapticService = MockHapticService();
    mockAuthBloc = MockAuthBloc();

    when(
      () => mockReferralRepo.getOrCreateReferralCode(any()),
    ).thenAnswer((_) async => 'VOWL-AMBASSADOR');
    when(
      () => mockReferralRepo.syncAmbassadorRewards(any()),
    ).thenAnswer((_) async => 0);
    when(
      () => mockReferralRepo.getMonthlyAmbassadorLeaderboard(
        monthKey: any(named: 'monthKey'),
      ),
    ).thenAnswer(
      (_) async => [
        const AmbassadorLeaderboardItem(
          rank: 1,
          userId: 'user_1',
          displayName: 'Alpha Reader',
          photoUrl: null,
          referralCount: 6,
        ),
        const AmbassadorLeaderboardItem(
          rank: 2,
          userId: 'user_2',
          displayName: 'Beta Speaker',
          photoUrl: null,
          referralCount: 3,
        ),
      ],
    );

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    if (di.sl.isRegistered<ReferralRepository>()) {
      di.sl.unregister<ReferralRepository>();
    }
    di.sl.registerSingleton<ReferralRepository>(mockReferralRepo);

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<ReferralRepository>()) {
      di.sl.unregister<ReferralRepository>();
    }
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
  });

  Widget buildSubject({required UserEntity user, int initialTab = 0}) {
    when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(user));

    return ScreenUtilInit(
      designSize: const Size(393, 852),
      builder: (context, _) => BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: MaterialApp(home: ReferralHubScreen(initialTab: initialTab)),
      ),
    );
  }

  group('ReferralHubScreen Segmented Switcher & Layout Tests', () {
    testWidgets(
      'renders segmented switcher and starts on Invite & Earn tab by default',
      (tester) async {
        await tester.pumpWidget(buildSubject(user: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Ambassador Hub'), findsOneWidget); // AppBar title
        expect(find.text('Invite & Earn'), findsOneWidget); // switcher tab
        expect(find.text('Monthly Cup'), findsWidgets); // switcher tab + bento

        // Verifies Tab 0 components are active
        expect(find.byType(ReferralStatsCard), findsOneWidget);
        expect(find.text('How Rewards Work'), findsOneWidget);

        // Verifies Tab 1 (Leaderboard) is not shown on Tab 0
        expect(find.byType(MonthlyCupLeaderboard), findsNothing);
      },
    );

    testWidgets(
      'tapping Monthly Cup tab switches view and displays leaderboard with zero crown icons',
      (tester) async {
        await tester.pumpWidget(buildSubject(user: testUser));
        await tester.pumpAndSettle();

        // Tap Monthly Cup tab button via trophy icon
        await tester.tap(find.byIcon(LucideIcons.trophy));
        await tester.pumpAndSettle();

        // Verifies Tab 1 is now displayed
        expect(find.byType(MonthlyCupLeaderboard), findsOneWidget);
        expect(find.text('TOP 50 LEADERBOARD'), findsOneWidget);

        // Verifies zero crown icons exist anywhere in the view
        expect(find.byIcon(LucideIcons.crown), findsNothing);

        // Verifies trophy icon is used instead
        expect(find.byIcon(LucideIcons.trophy), findsWidgets);
      },
    );

    testWidgets(
      'shows milestone qualification requirement for 0 monthly referrals',
      (tester) async {
        await tester.pumpWidget(buildSubject(user: testUser, initialTab: 1));
        await tester.pumpAndSettle();

        expect(
          find.text('1 Referral Needed to Enter Prize Pool'),
          findsOneWidget,
        );
        expect(find.text('0 / 1 INVITED'), findsOneWidget);
      },
    );

    testWidgets(
      'shows qualified milestone banner when user has referrals this month',
      (tester) async {
        await tester.pumpWidget(
          buildSubject(user: testUserQualified, initialTab: 1),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('You are Qualified for Monthly Prizes!'),
          findsOneWidget,
        );
        expect(find.text('QUALIFIED'), findsWidgets);
      },
    );

    testWidgets(
      'renders cached UserAvatar in podium and pinned user standing card',
      (tester) async {
        const userWithPhoto = UserEntity(
          id: 'user_with_avatar',
          email: 'avatar@vowl.app',
          displayName: 'Avatar User',
          photoUrl: 'https://images.example.com/avatar123.jpg',
          coins: 500,
          totalReferralsCount: 4,
          monthlyReferralsCount: 2,
          referralCode: 'VOWL-AVATAR',
        );

        await tester.pumpWidget(
          buildSubject(user: userWithPhoto, initialTab: 1),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verifies UserAvatar widgets exist on screen
        final avatarFinder = find.byType(UserAvatar);
        expect(avatarFinder, findsWidgets);

        // Verifies the user's avatar is specifically passed to UserAvatar
        final userAvatars = tester.widgetList<UserAvatar>(avatarFinder);
        final hasUserPhoto = userAvatars.any(
          (avatar) =>
              avatar.photoUrl == 'https://images.example.com/avatar123.jpg',
        );
        expect(hasUserPhoto, isTrue);

        // Verifies pinned standing card text
        expect(find.text('Your Monthly Standing'), findsOneWidget);
      },
    );
  });
}
