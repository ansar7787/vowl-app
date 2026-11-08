import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_matching_loader.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_quit_match_dialog.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_refuel_dialog.dart';

Widget _wrapWithScreenUtil(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, _) => MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('Arena Widgets', () {
    testWidgets(
      'ArenaMatchingLoader renders animated blades and custom message',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithScreenUtil(
            const ArenaMatchingLoader(
              customMessage: 'Loading next vocabulary question...',
              showShareCode: false,
            ),
          ),
        );

        expect(find.text('1v1 ARENA MATCHMAKING'), findsOneWidget);
        expect(
          find.text('Loading next vocabulary question...'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ArenaMatchingLoader shows room code and copy action when showShareCode is true',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithScreenUtil(
            const ArenaMatchingLoader(
              roomCode: 'VOWL-TEST',
              showShareCode: true,
            ),
          ),
        );

        expect(find.text('VOWL-TEST'), findsOneWidget);
        expect(find.text('ROOM CODE'), findsOneWidget);
        expect(find.byType(IconButton), findsNWidgets(2)); // Copy and Share
      },
    );

    testWidgets('ArenaQuitMatchDialog displays forfeit warning and actions', (
      tester,
    ) async {
      bool forfeited = false;

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          ArenaQuitMatchDialog(
            onStay: () {},
            onForfeit: () {
              forfeited = true;
            },
          ),
        ),
      );

      expect(find.text('Forfeit Match?'), findsOneWidget);
      expect(find.textContaining('lose your 30 coins'), findsOneWidget);
      expect(find.text('Keep Playing'), findsOneWidget);
      expect(find.text('Forfeit (-30🪙)'), findsOneWidget);

      await tester.ensureVisible(find.text('Forfeit (-30🪙)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forfeit (-30🪙)'));
      expect(forfeited, true);
    });

    testWidgets(
      'ArenaRefuelDialog displays structured balance card, human copy, and actions',
      (tester) async {
        bool watchedAd = false;
        bool canceled = false;

        await tester.pumpWidget(
          _wrapWithScreenUtil(
            ArenaRefuelDialog(
              currentCoins: 12,
              requiredCoins: 30,
              onWatchAd: () {
                watchedAd = true;
              },
              onCancel: () {
                canceled = true;
              },
            ),
          ),
        );

        expect(find.text('Not Enough Coins'), findsOneWidget);
        expect(find.text('YOUR BALANCE'), findsOneWidget);
        expect(find.text('12 🪙'), findsOneWidget);
        expect(find.text('ENTRY FEE'), findsOneWidget);
        expect(find.text('30 🪙'), findsOneWidget);
        expect(
          find.text('Watch a short video to get 30 coins.'),
          findsOneWidget,
        );
        expect(find.text('Watch Video (+30🪙)'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Verify watch ad action
        await tester.tap(find.text('Watch Video (+30🪙)'));
        expect(watchedAd, true);

        // Verify cancel action
        await tester.tap(find.text('Cancel'));
        expect(canceled, true);
      },
    );

    testWidgets(
      'ArenaRefuelDialog displays VIP instant refuel for premium users',
      (tester) async {
        bool refueled = false;

        await tester.pumpWidget(
          _wrapWithScreenUtil(
            ArenaRefuelDialog(
              currentCoins: 8,
              requiredCoins: 30,
              isPremium: true,
              onWatchAd: () {
                refueled = true;
              },
              onCancel: () {},
            ),
          ),
        );

        expect(find.text('Not Enough Coins'), findsOneWidget);
        expect(find.text('8 🪙'), findsOneWidget);
        expect(find.text('30 🪙'), findsOneWidget);
        expect(
          find.text(
            'As a VIP member, refuel 30 coins instantly with zero ads.',
          ),
          findsOneWidget,
        );
        expect(find.text('VIP Instant Refuel (+30🪙)'), findsOneWidget);

        await tester.tap(find.text('VIP Instant Refuel (+30🪙)'));
        expect(refueled, true);
      },
    );
  });
}
