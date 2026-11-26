import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/social_share/domain/entities/share_card_data.dart';
import 'package:vowl/features/social_share/presentation/widgets/milestone_share_card_widget.dart';

Widget _wrapCard(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, _) => MaterialApp(
      home: Scaffold(
        body: Center(child: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  group('MilestoneShareCardWidget', () {
    testWidgets('defeat card never renders winner/victory/+5 XP copy', (
      tester,
    ) async {
      final data = ShareCardData.fromArenaDefeat(
        userName: 'Ansar',
        myScore: 240,
        rivalScore: 420,
        rivalName: 'Sophia',
        roomCode: 'VOWL-DUEL-482913',
        payoutCoins: 10,
      );

      await tester.pumpWidget(
        _wrapCard(MilestoneShareCardWidget(data: data)),
      );

      expect(find.text('#1v1 DUEL'), findsOneWidget);
      expect(find.text('1v1 DUEL CONTENDER'), findsOneWidget);
      expect(find.text('DUEL RECAP'), findsOneWidget);
      expect(find.text('240 PTS'), findsOneWidget);
      expect(find.text('vs Sophia (420 pts)'), findsOneWidget);
      expect(find.text('10 Coins 🪙 Returned • +0 XP'), findsOneWidget);
      expect(find.text('1v1 ARENA CONTENDER'), findsOneWidget);

      expect(find.text('#DUEL WINNER'), findsNothing);
      expect(find.text('DUEL VICTORY'), findsNothing);
      expect(find.text('1v1 DUEL WINNER'), findsNothing);
      expect(find.textContaining('+ 5 XP'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('victory card renders winner badge and 5 XP reward', (
      tester,
    ) async {
      final data = ShareCardData.fromArenaVictory(
        userName: 'Ansar',
        myScore: 480,
        rivalScore: 310,
        rivalName: 'Sophia',
        roomCode: 'VOWL-DUEL-482913',
        payoutCoins: 50,
      );

      await tester.pumpWidget(
        _wrapCard(MilestoneShareCardWidget(data: data)),
      );

      expect(find.text('#DUEL WINNER'), findsOneWidget);
      expect(find.text('DUEL VICTORY'), findsOneWidget);
      expect(find.text('50 Coins 🪙 + 5 XP ⚡ Won'), findsOneWidget);
      expect(find.text('1v1 DUEL WINNER'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('draw card renders draw badge, 30 coins refunded, and +0 XP', (
      tester,
    ) async {
      final data = ShareCardData.fromArenaDraw(
        userName: 'Ansar',
        myScore: 360,
        rivalScore: 360,
        rivalName: 'Sophia',
        roomCode: 'VOWL-DUEL-482913',
        payoutCoins: 30,
      );

      await tester.pumpWidget(
        _wrapCard(MilestoneShareCardWidget(data: data)),
      );

      expect(find.text('#1v1 DRAW'), findsOneWidget);
      expect(find.text('DUEL DRAW'), findsOneWidget);
      expect(find.text('30 Coins 🪙 Refunded • +0 XP'), findsOneWidget);
      expect(find.text('DEAD EVEN DUEL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('invite and referral cards render without overflow', (
      tester,
    ) async {
      final invite = ShareCardData.fromDuelInvite(
        userName: 'Ansar',
        roomCode: 'VOWL-DUEL-482913',
      );
      await tester.pumpWidget(
        _wrapCard(MilestoneShareCardWidget(data: invite)),
      );
      expect(find.text('DUEL CODE: VOWL-DUEL-482913'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final referral = ShareCardData.fromReferral(
        userName: 'Ansar',
        referralCode: 'VOWL-ANS1234',
      );
      await tester.pumpWidget(
        _wrapCard(MilestoneShareCardWidget(data: referral)),
      );
      expect(find.text('CODE: VOWL-ANS1234'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
