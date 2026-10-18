// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:vowl/core/services/in_app_purchase_service.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/payment_service.dart';
import 'package:vowl/core/utils/subscription_plans_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/premium/domain/entities/subscription_plan.dart';
import 'package:vowl/features/premium/presentation/pages/premium_screen.dart';
import 'package:vowl/features/premium/presentation/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Mocks & Test Doubles
// ---------------------------------------------------------------------------

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

class MockHapticService extends Mock implements HapticService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockInternetConnection extends Mock implements InternetConnection {}

class MockSubscriptionPlansService extends Mock
    implements SubscriptionPlansService {}

class FakePaymentService implements PaymentService {
  void Function(PaymentSuccessResponse)? onSuccess;
  void Function(PaymentFailureResponse)? onFailure;
  void Function(ExternalWalletResponse)? onExternalWallet;

  bool purchaseSubscriptionResult = true;
  bool shouldThrowOnPurchase = false;
  bool shouldThrowOnUpgrade = false;

  String? lastPurchasedPlanId;
  String? lastUpgradedOrderId;

  @override
  void init({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    this.onSuccess = onSuccess;
    this.onFailure = onFailure;
    this.onExternalWallet = onExternalWallet;
  }

  @override
  bool openCheckout({
    required double amount,
    required String contact,
    required String email,
    String? orderId,
    String currency = 'INR',
    String description = 'Vowl Premium - 30 Days',
  }) => true;

  @override
  Future<Map<String, dynamic>> createOrder({String? planId, String? packId}) async {
    return {'id': 'order_123'};
  }

  @override
  Future<bool> purchaseSubscription({
    required String contact,
    required String email,
    required String planId,
    required int days,
    required String planName,
    String currency = 'INR',
  }) async {
    if (shouldThrowOnPurchase) {
      throw Exception('Order creation network failure');
    }
    lastPurchasedPlanId = planId;
    return purchaseSubscriptionResult;
  }

  @override
  Future<void> upgradeToPremium({
    required String orderId,
    required String paymentId,
    required String signature,
    required int days,
  }) async {
    if (shouldThrowOnUpgrade) {
      throw Exception('Upgrade verification failed on backend');
    }
    lastUpgradedOrderId = orderId;
  }

  @override
  Future<void> verifyCoinPurchase({
    required String orderId,
    required String paymentId,
    required String signature,
    required int coins,
    required int keys,
    required String packId,
  }) async {}

  @override
  void dispose() {}
}

class MockInAppPurchasePlatform extends InAppPurchasePlatform
    with MockPlatformInterfaceMixin {
  bool buyConsumableResult = true;
  ProductDetails? lastBoughtProduct;
  bool restorePurchasesCalled = false;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    return ProductDetailsResponse(
      productDetails: [],
      notFoundIDs: [],
      error: null,
    );
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    lastBoughtProduct = purchaseParam.productDetails;
    return buyConsumableResult;
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restorePurchasesCalled = true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
}

class FakeInAppPurchase implements InAppPurchase {
  final MockInAppPurchasePlatform platform;
  FakeInAppPurchase(this.platform);

  @override
  Future<bool> isAvailable() => platform.isAvailable();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => platform.purchaseStream;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      platform.queryProductDetails(identifiers);

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) =>
      platform.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: autoConsume,
      );

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      platform.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Future<void> restorePurchases({String? applicationUserName}) =>
      platform.restorePurchases(applicationUserName: applicationUserName);

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      platform.completePurchase(purchase);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUrlLauncherPlatform extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  String? lastLaunchedUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    return true;
  }
}

class FakePurchaseDetails extends Fake implements PurchaseDetails {
  @override
  final String purchaseID;
  @override
  final String productID;
  @override
  final PurchaseVerificationData verificationData;
  @override
  final PurchaseStatus status;
  @override
  final bool pendingCompletePurchase;

  FakePurchaseDetails({
    required this.purchaseID,
    required this.productID,
    required this.verificationData,
    this.status = PurchaseStatus.purchased,
    this.pendingCompletePurchase = false,
  });
}

class FakePurchaseVerificationData extends Fake
    implements PurchaseVerificationData {
  @override
  final String serverVerificationData;
  @override
  final String localVerificationData;
  @override
  final String source;

  FakePurchaseVerificationData({
    required this.serverVerificationData,
    this.localVerificationData = '',
    this.source = 'google_play',
  });
}

// ---------------------------------------------------------------------------
// Fake HTTP Client for Internet Connection Simulation
// ---------------------------------------------------------------------------

class FakeHttpClient extends Fake implements HttpClient {
  final int statusCode;
  final bool shouldThrow;

  FakeHttpClient({this.statusCode = 200, this.shouldThrow = false});

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    if (shouldThrow) throw const SocketException('No route to host');
    return FakeHttpClientRequest(statusCode: statusCode);
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) async {
    if (shouldThrow) throw const SocketException('No route to host');
    return FakeHttpClientRequest(statusCode: statusCode);
  }
}

class FakeHttpClientRequest extends Fake implements HttpClientRequest {
  final int statusCode;

  FakeHttpClientRequest({this.statusCode = 200});

  @override
  HttpHeaders get headers => FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return FakeHttpClientResponse(statusCode: statusCode);
  }
}

class FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class FakeHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  final int statusCode;

  FakeHttpClientResponse({this.statusCode = 200});

  @override
  int get contentLength => 0;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers => FakeHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return const Stream<List<int>>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class TestHttpOverrides extends HttpOverrides {
  final int statusCode;
  final bool shouldThrow;

  TestHttpOverrides({this.statusCode = 200, this.shouldThrow = false});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return FakeHttpClient(statusCode: statusCode, shouldThrow: shouldThrow);
  }
}

// ---------------------------------------------------------------------------
// Test Suite
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockThemeCubit mockThemeCubit;
  late MockHapticService mockHapticService;
  late MockAppLogger mockAppLogger;
  late MockInternetConnection mockInternetConnection;
  late MockSubscriptionPlansService mockSubscriptionPlansService;
  late FakePaymentService fakePaymentService;
  late MockInAppPurchasePlatform mockInAppPurchasePlatform;
  late MockUrlLauncherPlatform mockUrlLauncherPlatform;

  final testUser = UserEntity(
    id: 'user_123',
    email: 'testquester@vowl.app',
    displayName: 'Test Quester',
    isEmailVerified: true,
    isPremium: false,
    coins: 500,
  );

  final testPremiumUser = UserEntity(
    id: 'premium_user_456',
    email: 'proquester@vowl.app',
    displayName: 'Pro Quester',
    isEmailVerified: true,
    isPremium: true,
    premiumExpiryDate: DateTime(2027, 12, 31),
    coins: 2500,
  );

  final customPlans = [
    const SubscriptionPlan(
      id: 'weekly',
      name: 'Weekly Pass',
      price: 59.0,
      oldPrice: 79.0,
      days: 7,
      tag: 'TRIAL',
      color: '#F43F5E',
      displayOrder: 0,
    ),
    const SubscriptionPlan(
      id: 'monthly',
      name: 'Monthly Pro',
      price: 149.0,
      oldPrice: 199.0,
      days: 30,
      tag: 'POPULAR',
      color: '#6366F1',
      displayOrder: 1,
    ),
    const SubscriptionPlan(
      id: 'yearly',
      name: 'Annual Master',
      price: 1199.0,
      oldPrice: 1999.0,
      days: 365,
      tag: 'CHAMPION',
      color: '#10B981',
      displayOrder: 2,
    ),
  ];

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'dev.flutter.pigeon.in_app_purchase_android.InAppPurchaseApi.startConnection',
      (ByteData? message) async {
        return const StandardMessageCodec().encodeMessage(<Object?>[
          <Object?>[0, 'OK']
        ]);
      },
    );
    registerFallbackValue(const AuthReloadUser());
    registerFallbackValue(ThemeMode.light);
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockThemeCubit = MockThemeCubit();
    mockHapticService = MockHapticService();
    mockAppLogger = MockAppLogger();
    mockInternetConnection = MockInternetConnection();
    mockSubscriptionPlansService = MockSubscriptionPlansService();
    fakePaymentService = FakePaymentService();
    mockInAppPurchasePlatform = MockInAppPurchasePlatform();
    mockUrlLauncherPlatform = MockUrlLauncherPlatform();

    when(() => mockInternetConnection.hasInternetAccess).thenAnswer((_) async => true);

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});

    when(() => mockAppLogger.warning(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(() => mockAppLogger.error(
      any(),
      error: any(named: 'error'),
      stackTrace: any(named: 'stackTrace'),
      tag: any(named: 'tag'),
    )).thenReturn(null);
    when(() => mockAppLogger.debug(any(), tag: any(named: 'tag'))).thenReturn(null);

    InAppPurchasePlatform.instance = mockInAppPurchasePlatform;
    InAppPurchaseService.testIapInstance = FakeInAppPurchase(mockInAppPurchasePlatform);
    UrlLauncherPlatform.instance = mockUrlLauncherPlatform;

    HttpOverrides.global = TestHttpOverrides(statusCode: 200);
    SharedPreferences.setMockInitialValues({'user_payment_contact': '9876543210'});

    // Default InAppPurchase products
    InAppPurchaseService.instance.products = [
      ProductDetails(
        id: InAppPurchaseService.premiumWeekly,
        title: 'Weekly Pass',
        description: 'Weekly Elite Access',
        price: '\$1.99',
        rawPrice: 1.99,
        currencyCode: 'USD',
        currencySymbol: '\$',
      ),
      ProductDetails(
        id: InAppPurchaseService.premiumMonthly,
        title: 'Monthly Pro',
        description: 'Monthly Elite Access',
        price: '\$4.99',
        rawPrice: 4.99,
        currencyCode: 'USD',
        currencySymbol: '\$',
      ),
      ProductDetails(
        id: InAppPurchaseService.premiumYearly,
        title: 'Annual Master',
        description: 'Yearly Elite Access',
        price: '\$39.99',
        rawPrice: 39.99,
        currencyCode: 'USD',
        currencySymbol: '\$',
      ),
    ];

    InAppPurchaseService.setCachedCountryCodeForTesting('IN');

    // DI Setup
    if (di.sl.isRegistered<PaymentService>()) di.sl.unregister<PaymentService>();
    if (di.sl.isRegistered<SubscriptionPlansService>()) {
      di.sl.unregister<SubscriptionPlansService>();
    }
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<InternetConnection>()) {
      di.sl.unregister<InternetConnection>();
    }

    di.sl.registerSingleton<PaymentService>(fakePaymentService);
    di.sl.registerSingleton<SubscriptionPlansService>(
      mockSubscriptionPlansService,
    );
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<InternetConnection>(mockInternetConnection);

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(testUser),
    );
    when(() => mockThemeCubit.state).thenReturn(
      const ThemeState(themeMode: ThemeMode.light, isMidnight: false),
    );

    when(() => mockSubscriptionPlansService.fetchPlans()).thenAnswer(
      (_) async => customPlans,
    );
  });

  tearDown(() {
    InAppPurchaseService.setCachedCountryCodeForTesting(null);
    InAppPurchaseService.testShouldUseIAPOverride = null;
    InAppPurchaseService.testIapInstance = null;
    if (di.sl.isRegistered<InternetConnection>()) {
      di.sl.unregister<InternetConnection>();
    }
    final iap = InAppPurchaseService.instance;
    iap.onPurchaseSuccess = null;
    iap.onPurchaseError = null;
    iap.onPurchaseCanceled = null;
    iap.onPurchaseRestored = null;
    HttpOverrides.global = null;
  });

  Widget buildTestableWidget({
    required Widget child,
    required AuthBloc authBloc,
    ThemeCubit? themeCubit,
    GoRouter? router,
    Size screenSize = const Size(390, 844),
    double textScaleFactor = 1.0,
    ThemeMode themeMode = ThemeMode.light,
    WidgetTester? tester,
  }) {
    if (tester != null) {
      tester.view.physicalSize = Size(
        screenSize.width * 2.0,
        screenSize.height * 2.0,
      );
      tester.view.devicePixelRatio = 2.0;
    }
    final effectiveThemeCubit = themeCubit ?? mockThemeCubit;

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ThemeCubit>.value(value: effectiveThemeCubit),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, _) {
          if (router != null) {
            return MaterialApp.router(
              routerConfig: router,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: themeMode,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: screenSize,
                  textScaler: TextScaler.linear(textScaleFactor),
                  disableAnimations: true,
                ),
                child: child!,
              ),
            );
          }
          return MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeMode,
            home: MediaQuery(
              data: MediaQueryData(
                size: screenSize,
                textScaler: TextScaler.linear(textScaleFactor),
                disableAnimations: true,
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
    await scrollTo(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // =========================================================================
  // GROUP 1: Initial Rendering & Header Navigation
  // =========================================================================
  group('Group 1: Initial Rendering & Header Navigation', () {
    testWidgets('renders pinned SliverAppBar with VERIFIED PRO badge and back button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SliverAppBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.text('VERIFIED PRO'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
      expect(find.byType(PremiumHero), findsOneWidget);
      expect(find.byIcon(LucideIcons.crown), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('back button navigates to /home when context cannot be popped', (
      tester,
    ) async {
      String? lastNavigatedRoute;
      final router = GoRouter(
        initialLocation: '/premium',
        routes: [
          GoRoute(
            path: '/premium',
            builder: (context, state) => const PremiumScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) {
              lastNavigatedRoute = '/home';
              return const Scaffold(body: Text('Home Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const SizedBox(),
          authBloc: mockAuthBloc,
          router: router,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(lastNavigatedRoute, equals('/home'));
      await tester.pumpWidget(const SizedBox());
    });
  });

  // =========================================================================
  // GROUP 2: Dynamic Subscription Plans Loading & Selection
  // =========================================================================
  group('Group 2: Dynamic Subscription Plans Loading & Selection', () {
    testWidgets('loads dynamic plans from SubscriptionPlansService and renders cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      verify(() => mockSubscriptionPlansService.fetchPlans()).called(1);
      expect(find.byType(PremiumPlanCard), findsNWidgets(3));
      expect(find.text('WEEKLY PASS'), findsOneWidget);
      expect(find.text('MONTHLY PRO'), findsOneWidget);
      expect(find.text('ANNUAL MASTER'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('falls back to local defaults if fetchPlans throws error', (
      tester,
    ) async {
      when(() => mockSubscriptionPlansService.fetchPlans()).thenThrow(
        Exception('Network offline'),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      verify(() => mockAppLogger.warning(any())).called(1);
      expect(find.byType(PremiumPlanCard), findsNWidgets(3));
      expect(find.text('WEEKLY'), findsOneWidget);
      expect(find.text('MONTHLY'), findsOneWidget);
      expect(find.text('YEARLY'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tapping different plan card updates selection with haptic feedback', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final monthlyCard = find.text('MONTHLY PRO');
      expect(monthlyCard, findsOneWidget);
      await tester.tap(monthlyCard);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);

      await tester.pumpWidget(const SizedBox());
    });
  });

  // =========================================================================
  // GROUP 3: Already Premium Quester State
  // =========================================================================
  group('Group 3: Already Premium Quester State', () {
    testWidgets('renders already premium card with expiration date when user isPremium is true', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(testPremiumUser),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.checkCircle), findsOneWidget);
      expect(find.text("You're already a Premium Quester!"), findsOneWidget);
      expect(find.textContaining('Valid until:'), findsOneWidget);

      // Plans and checkout button should NOT be rendered
      expect(find.byType(PremiumPlanCard), findsNothing);
      expect(find.text('Continue'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tapping Extend Membership reveals plan list and CTA button, tapping Hide Plans hides them', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(testPremiumUser),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      // Initially plans are hidden
      expect(find.byType(PremiumPlanCard), findsNothing);
      expect(find.text('Continue'), findsNothing);

      // Tap Extend Membership
      final extendBtn = find.text('Extend Membership');
      expect(extendBtn, findsOneWidget);
      await scrollAndTap(tester, extendBtn);
      await tester.pumpAndSettle();

      // Plans and checkout button should now be rendered
      expect(find.byType(PremiumPlanCard), findsNWidgets(3));
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Hide Plans'), findsOneWidget);

      // Tap Hide Plans to collapse again
      final hideBtn = find.text('Hide Plans');
      await scrollAndTap(tester, hideBtn);
      await tester.pumpAndSettle();

      // Plans should be hidden again
      expect(find.byType(PremiumPlanCard), findsNothing);
      expect(find.text('Continue'), findsNothing);
      expect(find.text('Extend Membership'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });

  // =========================================================================
  // GROUP 4: Payment Method Selection (India vs International GeoIP)
  // =========================================================================
  group('Group 4: Payment Method Selection (India vs International GeoIP)', () {
    testWidgets('renders Payment Method selector with Razorpay and Google Play in India', (
      tester,
    ) async {
      InAppPurchaseService.setCachedCountryCodeForTesting('IN');

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('PAYMENT METHOD'));

      expect(find.text('PAYMENT METHOD'), findsOneWidget);
      expect(find.text('UPI / Credit Card'), findsOneWidget);
      expect(find.text('Google Play Billing'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Tapping Google Play switches method
      await tester.tap(find.text('Google Play Billing'));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);

      // Tapping Razorpay switches back
      await tester.tap(find.text('UPI / Credit Card'));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('hides Payment Method selector when user is outside India', (
      tester,
    ) async {
      InAppPurchaseService.setCachedCountryCodeForTesting('US');

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PAYMENT METHOD'), findsNothing);
      expect(find.text('UPI / Credit Card'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });
  });

  // =========================================================================
  // GROUP 5: Razorpay Checkout & Callbacks Flow
  // =========================================================================
  group('Group 5: Razorpay Checkout & Callbacks Flow', () {
    testWidgets('tapping CTA launches Razorpay purchaseSubscription and starts timeout', (
      tester,
    ) async {
      InAppPurchaseService.setCachedCountryCodeForTesting('IN');

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final ctaBtn = find.text('Continue');
      await scrollAndTap(tester, ctaBtn);

      verify(() => mockHapticService.heavy()).called(1);
      expect(fakePaymentService.lastPurchasedPlanId, equals('weekly'));
      expect(find.text('Processing Payment...'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('shows failure overlay when purchaseSubscription returns false', (
      tester,
    ) async {
      InAppPurchaseService.setCachedCountryCodeForTesting('IN');
      fakePaymentService.purchaseSubscriptionResult = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final ctaBtn = find.text('Continue');
      await scrollAndTap(tester, ctaBtn);

      verify(() => mockHapticService.error()).called(1);
      expect(find.byType(PremiumFailureOverlay), findsOneWidget);
      expect(find.text('TRANSACTION FAILED'), findsOneWidget);

      // Tapping RETRY dismisses error overlay
      await tester.tap(find.text('RETRY'));
      await tester.pumpAndSettle();
      expect(find.byType(PremiumFailureOverlay), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('successful Razorpay callback upgrades premium, reloads user, shows success overlay', (
      tester,
    ) async {
      InAppPurchaseService.setCachedCountryCodeForTesting('IN');

      final router = GoRouter(
        initialLocation: '/premium',
        routes: [
          GoRoute(
            path: '/premium',
            builder: (context, state) => const PremiumScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const SizedBox(),
          authBloc: mockAuthBloc,
          router: router,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final ctaBtn = find.text('Continue');
      await scrollAndTap(tester, ctaBtn);

      expect(find.text('Processing Payment...'), findsOneWidget);

      // Trigger payment success
      fakePaymentService.onSuccess?.call(
        PaymentSuccessResponse('pay_98765', 'order_123', 'sig_abc', {}),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakePaymentService.lastUpgradedOrderId, equals('order_123'));
      verify(() => mockAuthBloc.add(const AuthReloadUser())).called(1);
      verify(() => mockHapticService.success()).called(1);
      expect(find.byType(PremiumSuccessOverlay), findsOneWidget);
      expect(find.text('UPGRADE SUCCESSFUL'), findsOneWidget);
      expect(find.text('pay_98765'), findsOneWidget);

      // Tapping BEGIN ADVENTURE pops or navigates
      expect(find.text('BEGIN ADVENTURE'), findsOneWidget);
      await tester.tap(find.text('BEGIN ADVENTURE'));
      await tester.pump(const Duration(seconds: 4));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('failure Razorpay callback displays error overlay with message', (
      tester,
    ) async {
      InAppPurchaseService.setCachedCountryCodeForTesting('IN');

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final ctaBtn = find.text('Continue');
      await scrollAndTap(tester, ctaBtn);

      fakePaymentService.onFailure?.call(
        PaymentFailureResponse(
          Razorpay.NETWORK_ERROR,
          'Network connection lost',
          {},
        ),
      );
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);
      expect(find.byType(PremiumFailureOverlay), findsOneWidget);
      expect(find.text('Network connection lost'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('cancellation Razorpay callback dismisses gracefully without error overlay', (
      tester,
    ) async {
      InAppPurchaseService.setCachedCountryCodeForTesting('IN');

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final ctaBtn = find.text('Continue');
      await scrollAndTap(tester, ctaBtn);

      fakePaymentService.onFailure?.call(
        PaymentFailureResponse(
          Razorpay.PAYMENT_CANCELLED,
          'Payment cancelled by user',
          {},
        ),
      );
      await tester.pumpAndSettle();

      verify(() => mockHapticService.light()).called(1);
      expect(find.byType(PremiumFailureOverlay), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tapping CANCEL on processing overlay dismisses processing state', (
      tester,
    ) async {
      InAppPurchaseService.setCachedCountryCodeForTesting('IN');

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final ctaBtn = find.text('Continue');
      await scrollAndTap(tester, ctaBtn);

      expect(find.text('Processing Payment...'), findsOneWidget);

      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      expect(find.text('Processing Payment...'), findsNothing);
      expect(find.text('Continue'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('contact bottom sheet prompts for phone when contact not saved, validates 10 digits, and submits safely', (
      tester,
    ) async {
      InAppPurchaseService.setCachedCountryCodeForTesting('IN');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_payment_contact');

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final ctaBtn = find.text('Continue');
      await scrollAndTap(tester, ctaBtn);
      await tester.pumpAndSettle();

      expect(find.text('UPI & Payment Mobile Number'), findsOneWidget);
      expect(find.text('Proceed to Payment Options'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      final proceedBtn = find.text('Proceed to Payment Options');
      await tester.tap(proceedBtn);
      await tester.pumpAndSettle();
      expect(find.text('UPI & Payment Mobile Number'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.pumpAndSettle();

      await tester.tap(proceedBtn);
      await tester.pumpAndSettle();

      expect(find.text('UPI & Payment Mobile Number'), findsNothing);
      expect(find.text('Processing Payment...'), findsOneWidget);

      expect(prefs.getString('user_payment_contact'), equals('9876543210'));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('skipping contact bottom sheet proceeds to payment with empty contact', (
      tester,
    ) async {
      InAppPurchaseService.setCachedCountryCodeForTesting('IN');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_payment_contact');

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final ctaBtn = find.text('Continue');
      await scrollAndTap(tester, ctaBtn);
      await tester.pumpAndSettle();

      expect(find.text('UPI & Payment Mobile Number'), findsOneWidget);

      final skipBtn = find.text('Skip and enter inside payment gateway');
      await tester.tap(skipBtn);
      await tester.pumpAndSettle();

      expect(find.text('UPI & Payment Mobile Number'), findsNothing);
      expect(find.text('Processing Payment...'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });

  // =========================================================================
  // GROUP 6: Google Play / IAP Checkout Flow
  // =========================================================================
  group('Group 6: Google Play / IAP Checkout Flow', () {
    testWidgets('tapping CTA with Google Play calls buyConsumable with matching product', (
      tester,
    ) async {
      InAppPurchaseService.setCachedCountryCodeForTesting('US');

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final ctaBtn = find.text('Continue');
      await scrollAndTap(tester, ctaBtn);

      expect(
        mockInAppPurchasePlatform.lastBoughtProduct?.id,
        equals(InAppPurchaseService.premiumWeekly),
      );
      expect(find.text('Processing Payment...'), findsOneWidget);

      // Trigger IAP onPurchaseSuccess
      final purchase = FakePurchaseDetails(
        purchaseID: 'iap_trans_111',
        productID: InAppPurchaseService.premiumWeekly,
        verificationData: FakePurchaseVerificationData(
          serverVerificationData: 'token_123',
        ),
      );
      InAppPurchaseService.instance.onPurchaseSuccess?.call(purchase);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockAuthBloc.add(const AuthReloadUser())).called(1);
      verify(() => mockHapticService.success()).called(1);
      expect(find.byType(PremiumSuccessOverlay), findsOneWidget);
      expect(find.text('iap_trans_111'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('IAP onPurchaseError displays failure overlay', (
      tester,
    ) async {
      InAppPurchaseService.setCachedCountryCodeForTesting('US');

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final ctaBtn = find.text('Continue');
      await scrollAndTap(tester, ctaBtn);

      InAppPurchaseService.instance.onPurchaseError?.call(
        'Billing service unavailable',
      );
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);
      expect(find.byType(PremiumFailureOverlay), findsOneWidget);
      expect(find.text('Billing service unavailable'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('IAP onPurchaseCanceled resets processing overlay without error', (
      tester,
    ) async {
      InAppPurchaseService.setCachedCountryCodeForTesting('US');

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final ctaBtn = find.text('Continue');
      await scrollAndTap(tester, ctaBtn);

      expect(find.text('Processing Payment...'), findsOneWidget);

      InAppPurchaseService.instance.onPurchaseCanceled?.call('Cancelled');
      await tester.pumpAndSettle();

      verify(() => mockHapticService.light()).called(1);
      expect(find.text('Processing Payment...'), findsNothing);
      expect(find.byType(PremiumFailureOverlay), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });
  });

  // =========================================================================
  // GROUP 7: Restore Purchases & Offline Connectivity Handling
  // =========================================================================
  group('Group 7: Restore Purchases & Offline Connectivity Handling', () {
    testWidgets('Restore Purchases calls restorePurchases when shouldUseIAP is true', (
      tester,
    ) async {
      InAppPurchaseService.setCachedCountryCodeForTesting('US');
      InAppPurchaseService.testShouldUseIAPOverride = true;

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final restoreBtn = find.text('Restore Purchases');
      await scrollAndTap(tester, restoreBtn);

      verify(() => mockHapticService.selection()).called(1);
      expect(mockInAppPurchasePlatform.restorePurchasesCalled, isTrue);

      // Trigger restored callback
      InAppPurchaseService.instance.onPurchaseRestored?.call();
      await tester.pump();

      verify(() => mockAuthBloc.add(const AuthReloadUser())).called(1);
      expect(find.text('Purchases restored successfully.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Restore Purchases shows info snackbar when in India (account-linked)', (
      tester,
    ) async {
      InAppPurchaseService.setCachedCountryCodeForTesting('IN');

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final restoreBtn = find.text('Restore Purchases');
      await scrollAndTap(tester, restoreBtn);

      verify(() => mockHapticService.selection()).called(1);
      expect(
        find.text(
          'Your premium is linked to your account and restored automatically when you sign in. Contact support if you need help.',
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('shows no internet error when network is unreachable', (
      tester,
    ) async {
      when(() => mockInternetConnection.hasInternetAccess).thenAnswer((_) async => false);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      final ctaBtn = find.text('Continue');
      await scrollAndTap(tester, ctaBtn);

      verify(() => mockHapticService.error()).called(1);
      expect(find.byType(PremiumFailureOverlay), findsOneWidget);
      expect(
        find.text(
          'No internet connection. Please check your network and try again.',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
    });
  });

  // =========================================================================
  // GROUP 8: Legal Links, Modern Features & Responsive Layout Safety
  // =========================================================================
  group('Group 8: Legal Links, Modern Features & Responsive Layout Safety', () {
    testWidgets('renders secure tag, cancellation note, and modern feature bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      await scrollTo(tester, find.byType(ModernFeatureBar));

      expect(find.byType(ModernFeatureBar), findsOneWidget);
      expect(find.text('PREMIUM PERKS'), findsOneWidget);

      await scrollTo(tester, find.text('100% SECURE CHECKOUT • NO AUTO-RENEWAL'));
      expect(find.text('100% SECURE CHECKOUT • NO AUTO-RENEWAL'), findsOneWidget);
      expect(
        find.text(
          'One-time payment. Access for the selected duration. No recurring charges.',
        ),
        findsOneWidget,
      );
      expect(find.text('Terms'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Refund Policy'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tapping Terms, Privacy, and Refund Policy launches correct legal URLs', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      await scrollAndTap(tester, find.text('Terms'));
      expect(
        mockUrlLauncherPlatform.lastLaunchedUrl,
        equals('https://vowl-official.github.io/vowl-legal/terms.html'),
      );

      await scrollAndTap(tester, find.text('Privacy'));
      expect(
        mockUrlLauncherPlatform.lastLaunchedUrl,
        equals('https://vowl-official.github.io/vowl-legal/privacy.html'),
      );

      await scrollAndTap(tester, find.text('Refund Policy'));
      expect(
        mockUrlLauncherPlatform.lastLaunchedUrl,
        equals('https://vowl-official.github.io/vowl-legal/refund.html'),
      );

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders cleanly on compact mobile viewport (320x568) with zero overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          screenSize: const Size(320, 568),
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders cleanly on large tablet viewport (800x1280) with zero overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          screenSize: const Size(800, 1280),
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders cleanly under 1.3x accessibility text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          textScaleFactor: 1.3,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders cleanly in dark theme mode', (
      tester,
    ) async {
      when(() => mockThemeCubit.state).thenReturn(
        const ThemeState(themeMode: ThemeMode.dark, isMidnight: false),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const PremiumScreen(),
          authBloc: mockAuthBloc,
          themeMode: ThemeMode.dark,
          tester: tester,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
