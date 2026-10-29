import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/offline_banner.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/offline_play_gate_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class MockLocaleService extends Mock implements LocaleService {}

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocaleService mockLocale;
  late MockAuthBloc mockAuthBloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockLocale = MockLocaleService();
    mockAuthBloc = MockAuthBloc();

    when(() => mockLocale.currentLocale).thenReturn(const Locale('en'));
    when(() => mockLocale.tr(
      any(),
      args: any(named: 'args'),
      fallback: any(named: 'fallback'),
    )).thenAnswer((invocation) {
      final fallback = invocation.namedArguments[#fallback] as String?;
      return fallback ?? invocation.positionalArguments[0] as String;
    });

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(const UserEntity(
        id: 'u1',
        email: 'u1@vowl.app',
        isPremium: false,
      )),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    di.sl.registerLazySingleton<LocaleService>(() => mockLocale);

    if (di.sl.isRegistered<AuthBloc>()) di.sl.unregister<AuthBloc>();
    di.sl.registerLazySingleton<AuthBloc>(() => mockAuthBloc);

    initLocaleServiceReference(mockLocale);

    await OfflinePlayGateService.instance.init();
    OfflinePlayGateService.instance.resetQuotaAfterAd();
  });

  tearDown(() {
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AuthBloc>()) di.sl.unregister<AuthBloc>();
    OfflinePlayGateService.instance.resetQuotaAfterAd();
  });

  Widget buildTestHarness({bool isPremium = false}) {
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(UserEntity(
        id: 'u1',
        email: 'u1@vowl.app',
        isPremium: isPremium,
      )),
    );
    return BlocProvider<AuthBloc>.value(
      value: mockAuthBloc,
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: const Scaffold(
            body: OfflineBanner(),
          ),
        ),
      ),
    );
  }

  group('OfflineBanner Reactive Real-time Stream & Updates', () {
    testWidgets('pill updates dynamically from 3/3 to 2/3 to 1/3 to 0 plays left without rebuild of parent', (tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      // 1. Initial state: 3/3 plays left
      expect(find.text('Playing offline · 3/3 plays left'), findsOneWidget);
      expect(find.byIcon(LucideIcons.wifiOff), findsOneWidget);

      // 2. User finishes 1st level offline -> decrements to 2/3
      OfflinePlayGateService.instance.recordOfflineLevel();
      await tester.pumpAndSettle();

      expect(find.text('Playing offline · 2/3 plays left'), findsOneWidget);

      // 3. User finishes 2nd level offline -> decrements to 1/3
      OfflinePlayGateService.instance.recordOfflineLevel();
      await tester.pumpAndSettle();

      expect(find.text('Offline · 1 play left!'), findsOneWidget);
      expect(find.byIcon(LucideIcons.alertTriangle), findsOneWidget);

      // 4. User finishes 3rd level offline -> decrements to 0 plays left
      OfflinePlayGateService.instance.recordOfflineLevel();
      await tester.pumpAndSettle();

      expect(find.text('Offline · 0 plays left'), findsOneWidget);
    });

    testWidgets('never renders banner for premium users', (tester) async {
      await tester.pumpWidget(buildTestHarness(isPremium: true));
      await tester.pumpAndSettle();

      expect(find.textContaining('Offline'), findsNothing);
      expect(find.textContaining('plays left'), findsNothing);
    });

    testWidgets('tapping pill opens bottom sheet with unlimited play reassurance', (tester) async {
      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      final pillFinder = find.text('Playing offline · 3/3 plays left');
      expect(pillFinder, findsOneWidget);

      await tester.tap(pillFinder);
      await tester.pumpAndSettle();

      expect(find.text('Offline Free Plays'), findsOneWidget);
      expect(find.text('3 of 3 free offline plays left'), findsOneWidget);
      expect(
        find.text('Connect to Wi-Fi or mobile data anytime to restore unlimited free play!'),
        findsOneWidget,
      );
      expect(find.text('Got it'), findsOneWidget);
      expect(find.text('View Premium'), findsOneWidget);
    });
  });

  group('OfflinePlayGateService - Reactive Stream & Premium Bypass', () {
    test('emits remaining counts over onRemainingPlaysChange broadcast stream', () async {
      final emitted = <int>[];
      final sub = OfflinePlayGateService.instance.onRemainingPlaysChange.listen(emitted.add);

      OfflinePlayGateService.instance.recordOfflineLevel(); // 2
      OfflinePlayGateService.instance.recordOfflineLevel(); // 1
      OfflinePlayGateService.instance.grantBonusOfflinePlays(); // 3

      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(emitted, equals([2, 1, 3]));
    });

    test('premium users are completely ignored by recordOfflineLevel', () {
      final exhausted = OfflinePlayGateService.instance.recordOfflineLevel(isPremium: true);
      expect(exhausted, isFalse);
      expect(OfflinePlayGateService.instance.offlineLevelsPlayed, equals(0));
      expect(OfflinePlayGateService.instance.remainingOfflinePlays, equals(3));
    });
  });
}
