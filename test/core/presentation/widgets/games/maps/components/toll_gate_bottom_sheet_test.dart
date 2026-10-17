import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/games/maps/components/toll_gate_bottom_sheet.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_level_unlock.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockLocaleService extends Mock implements LocaleService {}

class MockPurchaseLevelUnlock extends Mock implements PurchaseLevelUnlock {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockLocaleService mockLocaleService;
  late MockPurchaseLevelUnlock mockPurchaseLevelUnlock;

  const testUser = UserEntity(
    id: 'user_123',
    email: 'learner@vowl.app',
    displayName: 'Aria',
    keys: 2,
  );

  setUpAll(() {
    registerFallbackValue(
      const PurchaseLevelUnlockParams(
        gameType: 'flashcards',
        cost: 1,
        isKidsMode: false,
      ),
    );
  });

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockLocaleService = MockLocaleService();
    try {
      initLocaleServiceReference(mockLocaleService);
    } catch (_) {}

    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));
    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (inv) =>
          inv.namedArguments[#fallback] as String? ??
          inv.positionalArguments.first as String,
    );

    mockAuthBloc = MockAuthBloc();
    when(
      () => mockAuthBloc.state,
    ).thenReturn(AuthState.authenticated(testUser));

    mockPurchaseLevelUnlock = MockPurchaseLevelUnlock();
    when(
      () => mockPurchaseLevelUnlock.call(any()),
    ).thenAnswer((_) async => const Right(null));

    if (di.sl.isRegistered<PurchaseLevelUnlock>()) {
      di.sl.unregister<PurchaseLevelUnlock>();
    }
    di.sl.registerLazySingleton<PurchaseLevelUnlock>(
      () => mockPurchaseLevelUnlock,
    );
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<PurchaseLevelUnlock>()) {
      di.sl.unregister<PurchaseLevelUnlock>();
    }
  });

  Widget buildTestWidget({required int level, required String gameType}) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) {
        return BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    TollGateBottomSheet.show(
                      context: ctx,
                      level: level,
                      gameType: gameType,
                    );
                  },
                  child: const Text('Open Toll Gate'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  testWidgets(
    'displays normal 3 levels unlock when level is standard (e.g. level 11)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(
        buildTestWidget(level: 11, gameType: 'flashcards'),
      );
      await tester.pump();

      await tester.tap(find.text('Open Toll Gate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Unlock Next 3 Levels!'), findsOneWidget);
      expect(
        find.text('You need 1 Golden Key to unlock the next 3 levels.'),
        findsOneWidget,
      );

      Navigator.of(tester.element(find.text('Unlock Next 3 Levels!'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    },
  );

  testWidgets(
    'displays Final 2 Levels when level is 199 (for 200-level game)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(
        buildTestWidget(level: 199, gameType: 'flashcards'),
      );
      await tester.pump();

      await tester.tap(find.text('Open Toll Gate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Unlock Final 2 Levels!'), findsOneWidget);
      expect(
        find.text('You need 1 Golden Key to unlock the final 2 levels.'),
        findsOneWidget,
      );

      Navigator.of(tester.element(find.text('Unlock Final 2 Levels!'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    },
  );

  testWidgets('displays Final Level when level is 200 (for 200-level game)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(
      buildTestWidget(level: 200, gameType: 'flashcards'),
    );
    await tester.pump();

    await tester.tap(find.text('Open Toll Gate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Unlock Final Level!'), findsOneWidget);
    expect(
      find.text('You need 1 Golden Key to unlock the final Level 200.'),
      findsOneWidget,
    );

    Navigator.of(tester.element(find.text('Unlock Final Level!'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });
}
