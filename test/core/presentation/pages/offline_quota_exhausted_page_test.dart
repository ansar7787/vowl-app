import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/pages/offline_quota_exhausted_page.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/offline_play_gate_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class MockAdService extends Mock implements AdService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAdService mockAdService;
  late MockLocaleService mockLocale;
  late MockAuthBloc mockAuthBloc;

  const testUser = UserEntity(
    id: 'user_123',
    email: 'user@vowl.app',
    displayName: 'Test User',
    isEmailVerified: true,
  );

  void setViewport(WidgetTester tester, [Size size = const Size(390, 844), double ratio = 2.0]) {
    tester.view.physicalSize = Size(size.width * ratio, size.height * ratio);
    tester.view.devicePixelRatio = ratio;
    addTearDown(() => tester.view.resetPhysicalSize());
  }

  setUpAll(() {
    registerFallbackValue(RewardItem(3, 'offline_plays'));
  });

  setUp(() async {
    mockAdService = MockAdService();
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
      AuthState.authenticated(testUser),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    // By default, ad is loaded
    when(() => mockAdService.isRewardedAdLoaded).thenReturn(true);

    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    di.sl.registerLazySingleton<AdService>(() => mockAdService);

    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    di.sl.registerLazySingleton<LocaleService>(() => mockLocale);

    if (di.sl.isRegistered<AuthBloc>()) di.sl.unregister<AuthBloc>();
    di.sl.registerLazySingleton<AuthBloc>(() => mockAuthBloc);

    initLocaleServiceReference(mockLocale);

    SharedPreferences.setMockInitialValues({
      'offline_levels_played': 3,
      'offline_levels_timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    await OfflinePlayGateService.instance.init();
  });

  tearDown(() {
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AuthBloc>()) di.sl.unregister<AuthBloc>();
    OfflinePlayGateService.instance.resetQuotaAfterAd();
  });

  Widget buildOfflineQuotaHarness({
    Future<void> Function()? onRetry,
    VoidCallback? onAdWatched,
    VoidCallback? onClose,
    ThemeMode themeMode = ThemeMode.light,
    Size viewport = const Size(390, 844),
    bool disableAnimations = false,
  }) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MediaQuery(
        data: MediaQueryData(
          size: viewport,
          disableAnimations: disableAnimations,
        ),
        child: MaterialApp(
          themeMode: themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: OfflineQuotaExhaustedPage(
            onRetry: onRetry ?? () async {},
            onAdWatched: onAdWatched ?? () {},
            onClose: onClose ?? () {},
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // GROUP 1: Initial Rendering & Quota Display
  // =========================================================================
  group('Group 1: Initial Rendering & Quota Display', () {
    testWidgets('renders quota icon, levels count, header title and subtitle', (tester) async {
      setViewport(tester);

      await tester.pumpWidget(buildOfflineQuotaHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(LucideIcons.wifiOff), findsOneWidget);
      expect(find.text('3/3'), findsOneWidget);
      expect(find.text('OFFLINE LIMIT REACHED'), findsOneWidget);
      expect(
        find.text("You've played 3 levels offline. Reconnect or watch an ad to keep playing!"),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
      expect(find.text('RETRY CONNECTION'), findsOneWidget);
      expect(find.text('Play Offline with Premium'), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 2: Watch Ad Button Lifecycle & Reward Flow
  // =========================================================================
  group('Group 2: Watch Ad Button Lifecycle & Reward Flow', () {
    testWidgets('renders Watch Ad button when ad is loaded and grants bonus plays on completion', (tester) async {
      setViewport(tester);
      var adWatchedCallbackInvoked = false;

      when(() => mockAdService.isRewardedAdLoaded).thenReturn(true);
      when(() => mockAdService.showRewardedAd(
        context: any(named: 'context'),
        isPremium: any(named: 'isPremium'),
        onUserEarnedReward: any(named: 'onUserEarnedReward'),
        onDismissed: any(named: 'onDismissed'),
      )).thenAnswer((invocation) async {
        final onReward = invocation.namedArguments[#onUserEarnedReward] as void Function(RewardItem);
        final onDismiss = invocation.namedArguments[#onDismissed] as VoidCallback?;
        onReward(RewardItem(3, 'offline_plays'));
        onDismiss?.call();
      });

      await tester.pumpWidget(buildOfflineQuotaHarness(
        onAdWatched: () => adWatchedCallbackInvoked = true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final watchAdFinder = find.text('WATCH AD FOR +3 LEVELS');
      expect(watchAdFinder, findsOneWidget);

      await tester.tap(watchAdFinder);
      await tester.pump();

      verify(() => mockAdService.showRewardedAd(
        context: any(named: 'context'),
        isPremium: false,
        onUserEarnedReward: any(named: 'onUserEarnedReward'),
        onDismissed: any(named: 'onDismissed'),
      )).called(1);

      expect(adWatchedCallbackInvoked, isTrue);
      expect(OfflinePlayGateService.instance.offlineLevelsPlayed, 0);
    });

    testWidgets('hides Watch Ad button when rewarded ad is not loaded', (tester) async {
      setViewport(tester);
      when(() => mockAdService.isRewardedAdLoaded).thenReturn(false);

      await tester.pumpWidget(buildOfflineQuotaHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('WATCH AD FOR +3 LEVELS'), findsNothing);
      expect(
        find.text("You've played 3 levels offline. Reconnect to restore unlimited free play!"),
        findsOneWidget,
      );
      expect(find.text('RETRY CONNECTION'), findsOneWidget);
    });

    testWidgets('ad polling timer dynamically reveals Watch Ad button when ad becomes ready', (tester) async {
      setViewport(tester);
      when(() => mockAdService.isRewardedAdLoaded).thenReturn(false);

      await tester.pumpWidget(buildOfflineQuotaHarness());
      await tester.pump();
      expect(find.text('WATCH AD FOR +3 LEVELS'), findsNothing);

      // Transition ad status to loaded
      when(() => mockAdService.isRewardedAdLoaded).thenReturn(true);

      // Advance periodic timer past 2 seconds
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('WATCH AD FOR +3 LEVELS'), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 3: Retry Connection Interaction
  // =========================================================================
  group('Group 3: Retry Connection Interaction', () {
    testWidgets('tapping Retry triggers onRetry and shows loading spinner', (tester) async {
      setViewport(tester);
      final completer = Completer<void>();
      var retryCalledCount = 0;

      await tester.pumpWidget(buildOfflineQuotaHarness(
        onRetry: () async {
          retryCalledCount++;
          await completer.future;
        },
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final retryBtnFinder = find.text('RETRY CONNECTION');
      expect(retryBtnFinder, findsOneWidget);

      await tester.tap(retryBtnFinder);
      await tester.pump();
      await tester.pump();

      // In-flight retry shows loading spinner
      expect(find.byType(VowlButtonSpinner), findsOneWidget);
      expect(retryCalledCount, 1);

      // Tap again while checking â€” must be guarded and not re-invoke
      await tester.tap(find.byType(VowlButtonSpinner));
      await tester.pump();
      expect(retryCalledCount, 1);

      // Complete retry
      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Loading spinner clears
      expect(find.byType(VowlButtonSpinner), findsNothing);
      expect(find.text('RETRY CONNECTION'), findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 4: Close Action & Navigation Triggers
  // =========================================================================
  group('Group 4: Close Action & Navigation Triggers', () {
    testWidgets('tapping close button triggers onClose callback', (tester) async {
      setViewport(tester);
      var closeInvoked = false;

      await tester.pumpWidget(buildOfflineQuotaHarness(
        onClose: () => closeInvoked = true,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final closeBtnFinder = find.byIcon(LucideIcons.x);
      expect(closeBtnFinder, findsOneWidget);

      await tester.tap(closeBtnFinder);
      await tester.pump();

      expect(closeInvoked, isTrue);
    });

    testWidgets('tapping premium upsell button triggers haptic feedback', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(buildOfflineQuotaHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final premiumFinder = find.text('Play Offline with Premium');
      expect(premiumFinder, findsOneWidget);

      await tester.tap(premiumFinder);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // GROUP 5: Responsive Viewports, Themes & Reduced Motion
  // =========================================================================
  group('Group 5: Responsive Viewports, Themes & Reduced Motion', () {
    testWidgets('compact mobile layout (320x568) renders without overflow', (tester) async {
      setViewport(tester, const Size(320, 568));

      await tester.pumpWidget(buildOfflineQuotaHarness(
        viewport: const Size(320, 568),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('OFFLINE LIMIT REACHED'), findsOneWidget);
    });

    testWidgets('tablet layout (800x1280) renders without overflow', (tester) async {
      setViewport(tester, const Size(800, 1280), 1.5);

      await tester.pumpWidget(buildOfflineQuotaHarness(
        viewport: const Size(800, 1280),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('OFFLINE LIMIT REACHED'), findsOneWidget);
    });

    testWidgets('reduced motion mode disables entrance animations cleanly', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(buildOfflineQuotaHarness(disableAnimations: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('OFFLINE LIMIT REACHED'), findsOneWidget);
      expect(find.text('RETRY CONNECTION'), findsOneWidget);
    });

    testWidgets('dark theme adapts background color overlay', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(buildOfflineQuotaHarness(themeMode: ThemeMode.dark));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('OFFLINE LIMIT REACHED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposing widget cancels timers cleanly without pending timers', (tester) async {
      setViewport(tester);
      await tester.pumpWidget(buildOfflineQuotaHarness());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Unmount widget
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
