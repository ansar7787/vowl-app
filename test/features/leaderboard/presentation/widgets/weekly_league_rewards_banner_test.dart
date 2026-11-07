import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/weekly_league_rewards_banner.dart';

class MockLocaleService extends Mock implements LocaleService {}
class MockSoundService extends Mock implements SoundService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocaleService mockLocaleService;
  late MockSoundService mockSoundService;

  final unclaimedUser = UserEntity(
    id: 'user_winner_1',
    email: 'winner@vowl.app',
    displayName: 'Winner One',
    totalExp: 18000,
    previousRank: 1,
    claimedWeeklyRewardWeekKeys: const [],
  );

  setUp(() {
    mockLocaleService = MockLocaleService();
    mockSoundService = MockSoundService();

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    di.sl.registerSingleton<LocaleService>(mockLocaleService);

    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
    di.sl.registerSingleton<SoundService>(mockSoundService);

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

  Widget buildTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('calculates ISO-8601 week key deterministically', (tester) async {
    // 2026-11-04 is a Wednesday in ISO week 45 of 2026
    final date = DateTime.utc(2026, 11, 4);
    final weekKey = WeeklyLeagueRewardsBanner.getCurrentWeekKey(date);
    expect(weekKey, equals('2026-W45'));

    // Previous week is week 44
    final prevWeek = WeeklyLeagueRewardsBanner.getPreviousWeekKey(date);
    expect(prevWeek, equals('2026-W44'));
  });

  testWidgets('renders premier prize badges and unclaimed prize alert when user won top rank', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        WeeklyLeagueRewardsBanner(
          currentUser: unclaimedUser,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gold Division'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('1st'), findsOneWidget);
    expect(find.text('7d VIP'), findsOneWidget);
    expect(find.text('+500'), findsOneWidget);
    expect(find.text('2nd'), findsOneWidget);
    expect(find.text('3d VIP'), findsOneWidget);
    expect(find.text('+300'), findsOneWidget);
    expect(find.text('3rd'), findsOneWidget);
    expect(find.text('1d VIP'), findsOneWidget);
    expect(find.text('+200'), findsOneWidget);
    expect(find.text('4-10th'), findsOneWidget);
    expect(find.text('Top 10'), findsOneWidget);
    expect(find.text('+100'), findsOneWidget);
    expect(find.byIcon(Icons.monetization_on_rounded), findsNWidgets(4));

    // Unclaimed banner
    expect(find.text('Rank #1 Last Week! 🏆'), findsOneWidget);
    expect(find.text('Claim'), findsOneWidget);
  });
}

