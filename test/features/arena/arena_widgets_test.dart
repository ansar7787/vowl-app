import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_matching_loader.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_quit_match_dialog.dart';

Widget _wrapWithScreenUtil(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, _) => MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Arena Widgets', () {
    testWidgets('ArenaMatchingLoader renders animated blades and custom message', (tester) async {
      await tester.pumpWidget(
        _wrapWithScreenUtil(
          const ArenaMatchingLoader(
            customMessage: 'Loading next vocabulary question...',
            showShareCode: false,
          ),
        ),
      );

      expect(find.text('1v1 ARENA MATCHMAKING'), findsOneWidget);
      expect(find.text('Loading next vocabulary question...'), findsOneWidget);
    });

    testWidgets('ArenaMatchingLoader shows room code and copy action when showShareCode is true', (tester) async {
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
    });

    testWidgets('ArenaQuitMatchDialog displays forfeit warning and actions', (tester) async {
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

      expect(find.text('Forfeit 1v1 Arena Duel?'), findsOneWidget);
      expect(find.textContaining('Your 30 coins will be awarded to your opponent'), findsOneWidget);
      expect(find.text('Stay & Fight'), findsOneWidget);
      expect(find.text('Forfeit Match (-30🪙)'), findsOneWidget);

      await tester.ensureVisible(find.text('Forfeit Match (-30🪙)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forfeit Match (-30🪙)'));
      expect(forfeited, true);
    });
  });
}
