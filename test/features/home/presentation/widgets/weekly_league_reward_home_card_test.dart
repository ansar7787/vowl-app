import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/home/presentation/widgets/weekly_league_reward_home_card.dart';
import 'package:vowl/features/leaderboard/domain/utils/weekly_league_reward_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final prevWeekKey = WeeklyLeagueRewardHelper.getPreviousWeekKey();

  Widget buildSubject(UserEntity user) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      builder: (context, _) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: WeeklyLeagueRewardHomeCard(user: user)),
      ),
    );
  }

  group('WeeklyLeagueRewardHomeCard Tests', () {
    testWidgets('renders SizedBox.shrink when user has no unclaimed rewards', (
      tester,
    ) async {
      const user = UserEntity(
        id: 'u_none',
        email: 'none@vowl.app',
        displayName: 'No Reward User',
        previousRank: null,
      );

      await tester.pumpWidget(buildSubject(user));
      await tester.pumpAndSettle();

      expect(find.byType(WeeklyLeagueRewardHomeCard), findsOneWidget);
      expect(find.text('Weekly League Champion'), findsNothing);
      expect(find.text('Claim'), findsNothing);
    });

    testWidgets(
      'renders 1st Place Champion card with exact gold badges and prize breakdown',
      (tester) async {
        final championUser = UserEntity(
          id: 'u_champ',
          email: 'champ@vowl.app',
          displayName: 'Champion User',
          previousRank: 1,
          previousRankWeekKey: prevWeekKey,
          claimedWeeklyRewardWeekKeys: const [],
        );

        await tester.pumpWidget(buildSubject(championUser));
        await tester.pumpAndSettle();

        expect(find.text('Weekly League Champion'), findsOneWidget);
        expect(
          find.text('1st Place Winner · 7d VIP & 500 Coins'),
          findsOneWidget,
        );
        expect(find.text('Claim'), findsOneWidget);
        expect(find.byIcon(LucideIcons.trophy), findsOneWidget);
      },
    );

    testWidgets(
      'renders 2nd Place Silver Runner-Up card with prize breakdown',
      (tester) async {
        final silverUser = UserEntity(
          id: 'u_silver',
          email: 'silver@vowl.app',
          displayName: 'Silver User',
          previousRank: 2,
          previousRankWeekKey: prevWeekKey,
          claimedWeeklyRewardWeekKeys: const [],
        );

        await tester.pumpWidget(buildSubject(silverUser));
        await tester.pumpAndSettle();

        expect(find.text('Weekly Silver Runner-Up'), findsOneWidget);
        expect(
          find.text('2nd Place Winner · 3d VIP & 300 Coins'),
          findsOneWidget,
        );
        expect(find.text('Claim'), findsOneWidget);
        expect(find.byIcon(LucideIcons.medal), findsOneWidget);
      },
    );

    testWidgets(
      'renders 3rd Place Bronze Podium card with prize breakdown',
      (tester) async {
        final bronzeUser = UserEntity(
          id: 'u_bronze',
          email: 'bronze@vowl.app',
          displayName: 'Bronze User',
          previousRank: 3,
          previousRankWeekKey: prevWeekKey,
          claimedWeeklyRewardWeekKeys: const [],
        );

        await tester.pumpWidget(buildSubject(bronzeUser));
        await tester.pumpAndSettle();

        expect(find.text('Weekly Bronze Podium'), findsOneWidget);
        expect(
          find.text('3rd Place Winner · 1d VIP & 200 Coins'),
          findsOneWidget,
        );
        expect(find.text('Claim'), findsOneWidget);
        expect(find.byIcon(LucideIcons.award), findsOneWidget);
      },
    );
  });
}

