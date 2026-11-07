import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/leaderboard/presentation/widgets/weekly_league_champion_dialog.dart';

class MockLocaleService extends Mock implements LocaleService {}
class MockSoundService extends Mock implements SoundService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocaleService mockLocaleService;
  late MockSoundService mockSoundService;

  final now = DateTime.now();

  final testUser = UserEntity(
    id: 'test_champion_1',
    email: 'champion@vowl.app',
    displayName: 'Victory Queen',
    totalExp: 24000,
    currentStreak: 21,
    coins: 750,
    isPremium: false,
  );

  final testVipUser = UserEntity(
    id: 'test_vip_champion',
    email: 'vip@vowl.app',
    displayName: 'Golden Master',
    totalExp: 31000,
    currentStreak: 50,
    coins: 1200,
    isPremium: true,
    premiumExpiryDate: now.add(const Duration(days: 14)),
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

    when(() => mockSoundService.playLevelComplete())
        .thenAnswer((_) async {});
    when(() => mockSoundService.playCoinTally(count: any(named: 'count')))
        .thenAnswer((_) async {});
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

  testWidgets('renders Rank 1 Champion celebration dialog with 7 days VIP and 500 coins', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    bool claimCalled = false;

    await tester.pumpWidget(
      buildTestWidget(
        WeeklyLeagueChampionDialog(
          user: testUser,
          rank: 1,
          vipDays: 7,
          coins: 500,
          weekKey: '2026-W45',
          onClaim: () async {
            claimCalled = true;
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('LEAGUE CHAMPION 🏆'), findsOneWidget);
    expect(find.text('+7 Days Full VIP Unlocked!'), findsOneWidget);
    expect(find.text('+500 Quest Coins'), findsOneWidget);
    expect(find.text('Golden Champion Avatar Aura'), findsOneWidget);

    verify(() => mockSoundService.playLevelComplete()).called(1);

    // Tap Claim & Celebrate
    final claimButton = find.text('Claim & Celebrate');
    expect(claimButton, findsOneWidget);
    await tester.ensureVisible(claimButton);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(claimButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(claimCalled, isTrue);
    verify(() => mockSoundService.playCoinTally(count: 12)).called(1);
  });

  testWidgets('renders extended VIP messaging when user is already active premium', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        WeeklyLeagueChampionDialog(
          user: testVipUser,
          rank: 2,
          vipDays: 3,
          coins: 300,
          weekKey: '2026-W45',
          onClaim: () async {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('SILVER RUNNER-UP 🥈'), findsOneWidget);
    expect(find.text('+3 Days VIP Extended!'), findsOneWidget);
    expect(find.text('+300 Quest Coins'), findsOneWidget);
    expect(find.textContaining('Valid through'), findsOneWidget);
  });
}

