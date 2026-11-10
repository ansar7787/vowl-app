import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/arena/presentation/pages/arena_stats_screen.dart';
import 'package:vowl/features/arena/presentation/utils/arena_network_helper.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockHapticService extends Mock implements HapticService {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNetworkInfo mockNetworkInfo;
  late MockHapticService mockHapticService;

  setUp(() {
    CustomSnackBar.resetDebounce();
    mockNetworkInfo = MockNetworkInfo();
    mockHapticService = MockHapticService();

    when(() => mockHapticService.warning()).thenAnswer((_) async {});

    if (di.sl.isRegistered<NetworkInfo>()) {
      di.sl.unregister<NetworkInfo>();
    }
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
  });

  tearDown(() {
    CustomSnackBar.resetDebounce();
    if (di.sl.isRegistered<NetworkInfo>()) {
      di.sl.unregister<NetworkInfo>();
    }
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
  });

  Widget buildSubject({required Future<void> Function(BuildContext context) onTrigger}) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () => onTrigger(ctx),
                child: const Text('Test Trigger'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('ArenaNetworkHelper Unit & Widget Tests', () {
    testWidgets('returns true and does not display snackbar when device has real internet', (tester) async {
      when(() => mockNetworkInfo.hasRealConnection).thenAnswer((_) async => true);
      di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);
      di.sl.registerSingleton<HapticService>(mockHapticService);

      bool? result;
      await tester.pumpWidget(
        buildSubject(
          onTrigger: (ctx) async {
            result = await ArenaNetworkHelper.ensureOnline(ctx);
          },
        ),
      );

      await tester.tap(find.text('Test Trigger'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      verifyNever(() => mockHapticService.warning());
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('returns false, fires warning haptic, and displays CustomSnackBar when offline', (tester) async {
      when(() => mockNetworkInfo.hasRealConnection).thenAnswer((_) async => false);
      di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);
      di.sl.registerSingleton<HapticService>(mockHapticService);

      bool? result;
      await tester.pumpWidget(
        buildSubject(
          onTrigger: (ctx) async {
            result = await ArenaNetworkHelper.ensureOnline(ctx);
          },
        ),
      );

      await tester.tap(find.text('Test Trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(result, isFalse);
      verify(() => mockHapticService.warning()).called(1);
      expect(
        find.textContaining('1v1 Arena Duels require an active internet connection'),
        findsOneWidget,
      );
    });

    testWidgets('returns true gracefully if NetworkInfo is not registered in service locator', (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildSubject(
          onTrigger: (ctx) async {
            result = await ArenaNetworkHelper.ensureOnline(ctx);
          },
        ),
      );

      await tester.tap(find.text('Test Trigger'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('ArenaStatsScreen play button is blocked and displays CustomSnackBar when offline', (tester) async {
      when(() => mockNetworkInfo.hasRealConnection).thenAnswer((_) async => false);
      when(() => mockHapticService.selection()).thenAnswer((_) async {});
      di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);
      di.sl.registerSingleton<HapticService>(mockHapticService);

      final mockAuthBloc = MockAuthBloc();
      const testUser = UserEntity(
        id: 'user_1',
        email: 'user1@vowl.app',
        displayName: 'Test Challenger',
        coins: 100,
      );
      when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(testUser));

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (context, _) => BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const MaterialApp(
              home: Scaffold(
                body: ArenaStatsScreen(user: testUser),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final playButton = find.text('Play Arena Duel');
      expect(playButton, findsOneWidget);

      await tester.tap(playButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.warning()).called(1);
      expect(
        find.textContaining('1v1 Arena Duels require an active internet connection'),
        findsOneWidget,
      );
    });
  });
}
