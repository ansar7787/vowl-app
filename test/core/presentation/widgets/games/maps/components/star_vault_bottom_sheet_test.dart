import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/games/maps/components/star_vault_bottom_sheet.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockLocaleService extends Mock implements LocaleService {}

class MockUpdateUserRewards extends Mock implements UpdateUserRewards {}

class MockAdService extends Mock implements AdService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockLocaleService mockLocaleService;
  late MockUpdateUserRewards mockUpdateUserRewards;
  late MockAdService mockAdService;

  const testUser = UserEntity(
    id: 'user_star_vault',
    email: 'aria@vowl.app',
    displayName: 'Aria',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
    mockUpdateUserRewards = MockUpdateUserRewards();
    mockAdService = MockAdService();

    when(() => mockAdService.isRewardedAdLoaded).thenReturn(false);

    di.sl.allowReassignment = true;
    if (di.sl.isRegistered<UpdateUserRewards>()) {
      di.sl.unregister<UpdateUserRewards>();
    }
    di.sl.registerLazySingleton<UpdateUserRewards>(() => mockUpdateUserRewards);

    if (di.sl.isRegistered<AdService>()) {
      di.sl.unregister<AdService>();
    }
    di.sl.registerLazySingleton<AdService>(() => mockAdService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Widget createWidgetUnderTest() {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) {
        return MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: const Scaffold(
              body: StarVaultBottomSheet(
                gameType: 'flashcards',
                primaryColor: Colors.deepPurple,
              ),
            ),
          ),
        );
      },
    );
  }

  group('StarVaultBottomSheet Tests', () {
    testWidgets(
      'displays Vault Stars title and 650 total stars with breakdown when user has magic stars',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        final vaultUser = testUser.copyWith(
          starRatings: {
            'flashcards': {
              '1': 3,
              '2': 3,
              // Gameplay stars = 6
              'magic_stars': 100,
              // Total = 106
            },
          },
        );

        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(vaultUser),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // 1. Vault Stars label
        expect(find.text('Vault Stars'), findsOneWidget);

        // 2. Total stars = 106
        expect(find.text('106'), findsOneWidget);

        // 3. Breakdown pill shows gameplay stars and bonus stars
        expect(find.text('6 Game + 100 Bonus'), findsOneWidget);
      },
    );

    testWidgets(
      'omits bonus breakdown pill when magic_stars is 0',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());
        addTearDown(() => tester.view.resetDevicePixelRatio());

        final pureUser = testUser.copyWith(
          starRatings: {
            'flashcards': {
              '1': 3,
              '2': 3,
              '3': 2,
              // Gameplay stars = 8, no magic stars
            },
          },
        );

        when(() => mockAuthBloc.state).thenReturn(
          AuthState.authenticated(pureUser),
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Vault Stars'), findsOneWidget);
        expect(find.text('8'), findsOneWidget);

        // Breakdown pill should not be shown
        expect(find.textContaining('Bonus'), findsNothing);
      },
    );
  });
}

