import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/laurel_trophy_3d_artwork.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('LaurelTrophy3DArtwork Tests', () {
    testWidgets('renders Rank 1 Gold Trophy with Champion pedestal and #1 emblem', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const LaurelTrophy3DArtwork(rank: 1, size: 160),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('#1'), findsOneWidget);
      expect(find.text('CHAMPION'), findsOneWidget);
    });

    testWidgets('renders Rank 2 Silver Medallion with SILVER text and #2', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const LaurelTrophy3DArtwork(rank: 2, size: 160),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('#2'), findsOneWidget);
      expect(find.text('SILVER'), findsOneWidget);
    });

    testWidgets('renders Rank 3 Bronze Medallion with BRONZE text and #3', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const LaurelTrophy3DArtwork(rank: 3, size: 160),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('#3'), findsOneWidget);
      expect(find.text('BRONZE'), findsOneWidget);
    });

    testWidgets('renders Rank 7 Top 10 Shield with TOP 10 text and #7', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const LaurelTrophy3DArtwork(rank: 7, size: 160),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('#7'), findsOneWidget);
      expect(find.text('TOP 10'), findsOneWidget);
    });
  });
}

