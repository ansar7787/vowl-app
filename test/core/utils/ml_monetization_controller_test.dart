import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/ml_monetization_controller.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

Widget _wrapWithAuth(Widget child, {required bool isPremium}) {
  final mockBloc = MockAuthBloc();
  final user = UserEntity(
    id: 'test_user',
    email: 'test@vowl.app',
    displayName: 'Learner',
    isPremium: isPremium,
  );
  when(() => mockBloc.state).thenReturn(AuthState.authenticated(user));
  when(
    () => mockBloc.stream,
  ).thenAnswer((_) => Stream.value(AuthState.authenticated(user)));

  return ScreenUtilInit(
    designSize: const Size(390, 844),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockBloc,
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sl = GetIt.instance;

  setUp(() async {
    sl.reset();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(prefs);
  });

  tearDown(() {
    sl.reset();
  });

  group('MlMonetizationController Daily Quota Tests', () {
    test('initial state reports full daily allowance (3 scans)', () async {
      final remaining = await MlMonetizationController.getRemainingDailyScans(
        'scan_test',
        freeDailyLimit: 3,
      );
      final used = await MlMonetizationController.getUsedDailyScans(
        'scan_test',
      );

      expect(remaining, equals(3));
      expect(used, equals(0));
    });

    testWidgets(
      'allows 3 free scans sequentially for free users without showing gate',
      (tester) async {
        int successCount = 0;

        await tester.pumpWidget(
          _wrapWithAuth(
            Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  MlMonetizationController.attemptFeature(
                    ctx,
                    featureKey: 'scan_test',
                    freeDailyLimit: 3,
                    featureIcon: Icons.camera,
                    featureTitle: 'Scan',
                    featureSubtitle: 'Test Scan',
                    adButtonLabel: 'Ad',
                    onSuccess: () => successCount++,
                  );
                },
                child: const Text('Scan'),
              ),
            ),
            isPremium: false,
          ),
        );
        await tester.pumpAndSettle();

        // Scan 1
        await tester.tap(find.text('Scan'));
        await tester.pumpAndSettle();
        expect(successCount, equals(1));
        expect(
          await MlMonetizationController.getUsedDailyScans('scan_test'),
          equals(1),
        );
        expect(
          await MlMonetizationController.getRemainingDailyScans('scan_test'),
          equals(2),
        );

        // Scan 2
        await tester.tap(find.text('Scan'));
        await tester.pumpAndSettle();
        expect(successCount, equals(2));
        expect(
          await MlMonetizationController.getUsedDailyScans('scan_test'),
          equals(2),
        );
        expect(
          await MlMonetizationController.getRemainingDailyScans('scan_test'),
          equals(1),
        );

        // Scan 3
        await tester.tap(find.text('Scan'));
        await tester.pumpAndSettle();
        expect(successCount, equals(3));
        expect(
          await MlMonetizationController.getUsedDailyScans('scan_test'),
          equals(3),
        );
        expect(
          await MlMonetizationController.getRemainingDailyScans('scan_test'),
          equals(0),
        );

        // No modal sheet shown during first 3 scans
        expect(find.text('DAILY SCANS USED (3/3)'), findsNothing);
      },
    );

    testWidgets('triggers monetization modal on 4th scan for free user', (
      tester,
    ) async {
      int successCount = 0;

      await tester.pumpWidget(
        _wrapWithAuth(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                MlMonetizationController.attemptFeature(
                  ctx,
                  featureKey: 'photo_test',
                  freeDailyLimit: 3,
                  featureIcon: Icons.camera,
                  featureTitle: 'Photo Vocab',
                  featureSubtitle: 'Test',
                  adButtonLabel: 'Watch Ad (+1 Bonus)',
                  onSuccess: () => successCount++,
                );
              },
              child: const Text('Scan'),
            ),
          ),
          isPremium: false,
        ),
      );
      await tester.pumpAndSettle();

      // Consume 3 scans
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Scan'));
        await tester.pumpAndSettle();
      }
      expect(successCount, equals(3));

      // 4th Scan: triggers gate modal!
      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();

      // Success not invoked for 4th scan yet
      expect(successCount, equals(3));

      // Monetization modal is displayed!
      expect(find.text('DAILY SCANS USED (3/3)'), findsOneWidget);
      expect(find.text('Watch Ad (+1 Bonus)'), findsOneWidget);
    });

    testWidgets(
      'premium users bypass unconditionally with zero quota consumed',
      (tester) async {
        int successCount = 0;

        await tester.pumpWidget(
          _wrapWithAuth(
            Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  MlMonetizationController.attemptFeature(
                    ctx,
                    featureKey: 'premium_test',
                    freeDailyLimit: 3,
                    featureIcon: Icons.camera,
                    featureTitle: 'Scan',
                    featureSubtitle: 'Test',
                    adButtonLabel: 'Ad',
                    onSuccess: () => successCount++,
                  );
                },
                child: const Text('Scan'),
              ),
            ),
            isPremium: true,
          ),
        );
        await tester.pumpAndSettle();

        // Execute 10 scans
        for (int i = 0; i < 10; i++) {
          await tester.tap(find.text('Scan'));
          await tester.pumpAndSettle();
        }

        expect(successCount, equals(10));
        // 0 daily quota consumed for premium users
        expect(
          await MlMonetizationController.getUsedDailyScans('premium_test'),
          equals(0),
        );
        expect(find.text('DAILY SCANS USED (3/3)'), findsNothing);
      },
    );

    test(
      'resets daily quota count when date changes (midnight rollover)',
      () async {
        final prefs = sl<SharedPreferences>();
        // Simulate yesterday's exhausted quota
        await prefs.setString('ml_quota_date_rollover_test', '2020-01-01');
        await prefs.setInt('ml_quota_count_rollover_test', 3);

        final remaining = await MlMonetizationController.getRemainingDailyScans(
          'rollover_test',
          freeDailyLimit: 3,
        );
        final used = await MlMonetizationController.getUsedDailyScans(
          'rollover_test',
        );

        expect(remaining, equals(3));
        expect(used, equals(0));
      },
    );
  });
}
