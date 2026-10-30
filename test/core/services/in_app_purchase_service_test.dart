// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/services/in_app_purchase_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

// ---------------------------------------------------------------------------
// Mocks & Test Doubles
// ---------------------------------------------------------------------------

class MockInAppPurchase extends Mock implements InAppPurchase {}

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult<T> extends Mock implements HttpsCallableResult<T> {}

class FakePurchaseParam extends Fake implements PurchaseParam {
  @override
  final ProductDetails productDetails;
  FakePurchaseParam({required this.productDetails});
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
  @override
  final IAPError? error;

  FakePurchaseDetails({
    required this.purchaseID,
    required this.productID,
    required this.verificationData,
    this.status = PurchaseStatus.purchased,
    this.pendingCompletePurchase = true,
    this.error,
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
// Fake HTTP Overrides for GeoIP Network Simulation
// ---------------------------------------------------------------------------

class FakeHttpOverrides extends HttpOverrides {
  final int statusCode;
  final Map<String, dynamic>? responseJson;
  final bool shouldThrow;

  FakeHttpOverrides({
    this.statusCode = 200,
    this.responseJson,
    this.shouldThrow = false,
  });

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return FakeHttpClient(
      statusCode: statusCode,
      responseJson: responseJson ?? {'country': 'DE'},
      shouldThrow: shouldThrow,
    );
  }
}

class FakeHttpClient extends Fake implements HttpClient {
  final int statusCode;
  final Map<String, dynamic> responseJson;
  final bool shouldThrow;

  FakeHttpClient({
    required this.statusCode,
    required this.responseJson,
    required this.shouldThrow,
  });

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    if (shouldThrow) throw const SocketException('Connection failed');
    return FakeHttpClientRequest(
      statusCode: statusCode,
      responseJson: responseJson,
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeHttpClientRequest extends Fake implements HttpClientRequest {
  final int statusCode;
  final Map<String, dynamic> responseJson;

  FakeHttpClientRequest({
    required this.statusCode,
    required this.responseJson,
  });

  @override
  Future<HttpClientResponse> close() async {
    return FakeHttpClientResponse(
      statusCode: statusCode,
      responseJson: responseJson,
    );
  }
}

class FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  final int statusCode;
  final Map<String, dynamic> responseJson;

  FakeHttpClientResponse({
    required this.statusCode,
    required this.responseJson,
  });

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final bytes = utf8.encode(jsonEncode(responseJson));
    return Stream<List<int>>.value(bytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Test Suite
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InAppPurchaseService service;
  late MockInAppPurchase mockIap;
  late MockFirebaseFunctions mockFirebaseFunctions;
  late MockHttpsCallable mockCallable;
  late StreamController<List<PurchaseDetails>> purchaseStreamController;

  final weeklyProduct = ProductDetails(
    id: InAppPurchaseService.premiumWeekly,
    title: 'Weekly Pass',
    description: '7 Days Elite',
    price: '\$1.99',
    rawPrice: 1.99,
    currencyCode: 'USD',
  );

  final monthlyProduct = ProductDetails(
    id: InAppPurchaseService.premiumMonthly,
    title: 'Monthly Pro',
    description: '30 Days Elite',
    price: '\$4.99',
    rawPrice: 4.99,
    currencyCode: 'USD',
  );

  final yearlyProduct = ProductDetails(
    id: InAppPurchaseService.premiumYearly,
    title: 'Annual Master',
    description: '365 Days Elite',
    price: '\$39.99',
    rawPrice: 39.99,
    currencyCode: 'USD',
  );

  final coinProduct = ProductDetails(
    id: InAppPurchaseService.coinPack100,
    title: '100 Coins Pack',
    description: '100 Bonus Coins',
    price: '\$0.99',
    rawPrice: 0.99,
    currencyCode: 'USD',
  );

  setUpAll(() {
    registerFallbackValue(FakePurchaseParam(productDetails: weeklyProduct));
    registerFallbackValue(
      FakePurchaseDetails(
        purchaseID: 'fallback_id',
        productID: 'fallback_prod',
        verificationData: FakePurchaseVerificationData(
          serverVerificationData: 'fallback_token',
        ),
      ),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = InAppPurchaseService.instance;

    mockIap = MockInAppPurchase();
    mockFirebaseFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    purchaseStreamController = StreamController<List<PurchaseDetails>>.broadcast();

    InAppPurchaseService.testIapInstance = mockIap;
    InAppPurchaseService.setCachedCountryCodeForTesting(null);
    InAppPurchaseService.testShouldUseIAPOverride = null;

    service.onPurchaseSuccess = null;
    service.onPurchaseError = null;
    service.onPurchaseCanceled = null;
    service.onPurchaseRestored = null;
    service.products = [];

    when(() => mockIap.purchaseStream).thenAnswer(
      (_) => purchaseStreamController.stream,
    );
    when(() => mockIap.isAvailable()).thenAnswer((_) async => true);
    when(() => mockIap.queryProductDetails(any())).thenAnswer(
      (_) async => ProductDetailsResponse(
        productDetails: [weeklyProduct, monthlyProduct, yearlyProduct, coinProduct],
        notFoundIDs: [],
        error: null,
      ),
    );
    when(() => mockIap.buyConsumable(
      purchaseParam: any(named: 'purchaseParam'),
      autoConsume: any(named: 'autoConsume'),
    )).thenAnswer((_) async => true);
    when(() => mockIap.buyNonConsumable(
      purchaseParam: any(named: 'purchaseParam'),
    )).thenAnswer((_) async => true);
    when(() => mockIap.restorePurchases(applicationUserName: any(named: 'applicationUserName')))
        .thenAnswer((_) async {});
    when(() => mockIap.completePurchase(any())).thenAnswer((_) async {});

    if (di.sl.isRegistered<FirebaseFunctions>()) {
      di.sl.unregister<FirebaseFunctions>();
    }
    di.sl.registerSingleton<FirebaseFunctions>(mockFirebaseFunctions);
    when(() => mockFirebaseFunctions.httpsCallable('validateIAPReceipt'))
        .thenReturn(mockCallable);
  });

  tearDown(() async {
    service.dispose();
    await purchaseStreamController.close();
    InAppPurchaseService.testIapInstance = null;
    InAppPurchaseService.setCachedCountryCodeForTesting(null);
    InAppPurchaseService.testShouldUseIAPOverride = null;
    if (di.sl.isRegistered<FirebaseFunctions>()) {
      di.sl.unregister<FirebaseFunctions>();
    }
    HttpOverrides.global = null;
  });

  // =========================================================================
  // GROUP 1: Singleton & Availability Initialization
  // =========================================================================
  group('Group 1: Singleton & Availability Initialization', () {
    test('instance returns identical singleton reference', () {
      final instance1 = InAppPurchaseService.instance;
      final instance2 = InAppPurchaseService.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('initialize loads cached country from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'cached_geoip_country': 'FR'});

      await service.initialize();

      expect(InAppPurchaseService.isUserInIndia, isFalse);
    });

    test('initialize aborts early without loading products when isAvailable is false', () async {
      when(() => mockIap.isAvailable()).thenAnswer((_) async => false);

      await service.initialize();

      expect(service.isAvailable, isFalse);
      verify(() => mockIap.isAvailable()).called(1);
      verifyNever(() => mockIap.queryProductDetails(any()));
    });

    test('initialize successfully connects, listens to stream, and loads products when available', () async {
      when(() => mockIap.isAvailable()).thenAnswer((_) async => true);

      await service.initialize();

      expect(service.isAvailable, isTrue);
      expect(service.products.length, equals(4));
      verify(() => mockIap.queryProductDetails(any())).called(1);
    });
  });

  // =========================================================================
  // GROUP 2: GeoIP Country & Market Partitioning (India vs International)
  // =========================================================================
  group('Group 2: GeoIP Country & Market Partitioning (India vs International)', () {
    test('isUserInIndia returns true when cached country code is IN', () {
      InAppPurchaseService.setCachedCountryCodeForTesting('IN');
      expect(InAppPurchaseService.isUserInIndia, isTrue);
    });

    test('isUserInIndia returns false when cached country code is outside India', () {
      InAppPurchaseService.setCachedCountryCodeForTesting('US');
      expect(InAppPurchaseService.isUserInIndia, isFalse);

      InAppPurchaseService.setCachedCountryCodeForTesting('GB');
      expect(InAppPurchaseService.isUserInIndia, isFalse);
    });

    test('shouldUseIAP respects testShouldUseIAPOverride', () {
      InAppPurchaseService.testShouldUseIAPOverride = true;
      expect(InAppPurchaseService.shouldUseIAP, isTrue);

      InAppPurchaseService.testShouldUseIAPOverride = false;
      expect(InAppPurchaseService.shouldUseIAP, isFalse);
    });

    test('GeoIP background HTTP refresh updates SharedPreferences cache on 200 response', () async {
      HttpOverrides.global = FakeHttpOverrides(
        statusCode: 200,
        responseJson: {'country': 'CA'},
      );

      await service.initialize();
      // Allow background microtasks and async HTTP to execute
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cached_geoip_country'), equals('CA'));
    });

    test('GeoIP background HTTP refresh handles network error gracefully without crashing', () async {
      HttpOverrides.global = FakeHttpOverrides(shouldThrow: true);

      await service.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(service.isAvailable, isTrue);
    });
  });

  // =========================================================================
  // GROUP 3: Product Catalog Loading
  // =========================================================================
  group('Group 3: Product Catalog Loading', () {
    test('loadProducts queries all 6 target products and assigns products list', () async {
      await service.loadProducts();

      final captured = verify(() => mockIap.queryProductDetails(captureAny())).captured.single as Set<String>;
      expect(captured.contains(InAppPurchaseService.premiumWeekly), isTrue);
      expect(captured.contains(InAppPurchaseService.premiumMonthly), isTrue);
      expect(captured.contains(InAppPurchaseService.premiumYearly), isTrue);
      expect(captured.contains(InAppPurchaseService.coinPack100), isTrue);
      expect(captured.contains(InAppPurchaseService.coinPack500), isTrue);
      expect(captured.contains(InAppPurchaseService.coinPack1000), isTrue);

      expect(service.products.length, equals(4));
    });

    test('loadProducts handles IAP query error without throwing', () async {
      when(() => mockIap.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [],
          notFoundIDs: [],
          error: IAPError(
            source: 'google_play',
            code: 'service_unavailable',
            message: 'Play Store unavailable',
          ),
        ),
      );

      await service.loadProducts();

      expect(service.products, isEmpty);
    });
  });

  // =========================================================================
  // GROUP 4: Purchase Launching & Consumable Pass Handling
  // =========================================================================
  group('Group 4: Purchase Launching & Consumable Pass Handling', () {
    test('buyProduct invokes buyNonConsumable for subscriptions', () async {
      await service.buyProduct(weeklyProduct);

      final captured = verify(
        () => mockIap.buyNonConsumable(
          purchaseParam: captureAny(named: 'purchaseParam'),
        ),
      ).captured.single as PurchaseParam;

      expect(captured.productDetails.id, equals(InAppPurchaseService.premiumWeekly));
    });

    test('buyProduct invokes buyConsumable for coin packs', () async {
      await service.buyProduct(coinProduct);

      final captured = verify(
        () => mockIap.buyConsumable(
          purchaseParam: captureAny(named: 'purchaseParam'),
        ),
      ).captured.single as PurchaseParam;

      expect(captured.productDetails.id, equals(InAppPurchaseService.coinPack100));
    });

    test('buyProduct triggers onPurchaseError callback when launch returns false', () async {
      when(() => mockIap.buyNonConsumable(
        purchaseParam: any(named: 'purchaseParam'),
      )).thenAnswer((_) async => false);
      when(() => mockIap.buyConsumable(
        purchaseParam: any(named: 'purchaseParam'),
      )).thenAnswer((_) async => false);

      String? errorReceived;
      service.onPurchaseError = (err) => errorReceived = err;

      await service.buyProduct(weeklyProduct);

      expect(errorReceived, equals('Could not launch purchase. Please try again.'));
    });
  });

  // =========================================================================
  // GROUP 5: Purchase Stream Updates & Lifecycle
  // =========================================================================
  group('Group 5: Purchase Stream Updates & Lifecycle', () {
    test('PurchaseStatus.pending does not complete purchase or invoke error callback', () async {
      await service.initialize();

      String? errorReceived;
      service.onPurchaseError = (err) => errorReceived = err;

      final pendingPurchase = FakePurchaseDetails(
        purchaseID: 'p_pending',
        productID: InAppPurchaseService.premiumMonthly,
        status: PurchaseStatus.pending,
        verificationData: FakePurchaseVerificationData(serverVerificationData: 'tok'),
      );

      purchaseStreamController.add([pendingPurchase]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(errorReceived, isNull);
      verifyNever(() => mockIap.completePurchase(any()));
    });

    test('PurchaseStatus.error triggers onPurchaseError and completes pending purchase', () async {
      await service.initialize();

      String? errorReceived;
      service.onPurchaseError = (err) => errorReceived = err;

      final errorPurchase = FakePurchaseDetails(
        purchaseID: 'p_error',
        productID: InAppPurchaseService.premiumMonthly,
        status: PurchaseStatus.error,
        pendingCompletePurchase: true,
        error: IAPError(
          source: 'google_play',
          code: 'payment_declined',
          message: 'Payment declined by bank',
        ),
        verificationData: FakePurchaseVerificationData(serverVerificationData: 'tok'),
      );

      purchaseStreamController.add([errorPurchase]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(errorReceived, equals('Payment declined by bank'));
      verify(() => mockIap.completePurchase(errorPurchase)).called(1);
    });

    test('PurchaseStatus.canceled triggers onPurchaseCanceled and completes pending purchase', () async {
      await service.initialize();

      String? cancelReceived;
      service.onPurchaseCanceled = (msg) => cancelReceived = msg;

      final cancelPurchase = FakePurchaseDetails(
        purchaseID: 'p_cancel',
        productID: InAppPurchaseService.premiumMonthly,
        status: PurchaseStatus.canceled,
        pendingCompletePurchase: true,
        verificationData: FakePurchaseVerificationData(serverVerificationData: 'tok'),
      );

      purchaseStreamController.add([cancelPurchase]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cancelReceived, equals('Purchase cancelled'));
      verify(() => mockIap.completePurchase(cancelPurchase)).called(1);
    });

    test('restorePurchases calls _iap.restorePurchases', () async {
      await service.restorePurchases();

      verify(() => mockIap.restorePurchases()).called(1);
    });
  });

  // =========================================================================
  // GROUP 6: Zero Money Leakage: Backend Cloud Function Verification & Anti-Fraud
  // =========================================================================
  group('Group 6: Zero Money Leakage: Backend Cloud Function Verification & Anti-Fraud', () {
    test('PurchaseStatus.purchased for Weekly plan calls validateIAPReceipt with grantType premium and 7 days', () async {
      await service.initialize();

      final mockResult = MockHttpsCallableResult<dynamic>();
      when(() => mockResult.data).thenReturn({'success': true});
      when(() => mockCallable.call<dynamic>(any())).thenAnswer((_) async => mockResult);

      PurchaseDetails? deliveredPurchase;
      service.onPurchaseSuccess = (p) => deliveredPurchase = p;

      final purchase = FakePurchaseDetails(
        purchaseID: 'tx_weekly',
        productID: InAppPurchaseService.premiumWeekly,
        status: PurchaseStatus.purchased,
        pendingCompletePurchase: true,
        verificationData: FakePurchaseVerificationData(serverVerificationData: 'token_weekly_123'),
      );

      purchaseStreamController.add([purchase]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final capturedPayload = verify(
        () => mockCallable.call<dynamic>(captureAny()),
      ).captured.single as Map<String, dynamic>;

      expect(capturedPayload['purchaseToken'], equals('token_weekly_123'));
      expect(capturedPayload['productId'], equals(InAppPurchaseService.premiumWeekly));
      expect(capturedPayload['grantType'], equals('premium'));
      expect(capturedPayload['days'], equals(7));

      // Successfully completed and delivered
      verify(() => mockIap.completePurchase(purchase)).called(1);
      expect(deliveredPurchase?.purchaseID, equals('tx_weekly'));
    });

    test('PurchaseStatus.purchased for Monthly plan passes 30 days and for Yearly passes 365 days', () async {
      await service.initialize();

      final mockResult = MockHttpsCallableResult<dynamic>();
      when(() => mockResult.data).thenReturn({'success': true});
      when(() => mockCallable.call<dynamic>(any())).thenAnswer((_) async => mockResult);

      final monthlyPurchase = FakePurchaseDetails(
        purchaseID: 'tx_monthly',
        productID: InAppPurchaseService.premiumMonthly,
        status: PurchaseStatus.purchased,
        pendingCompletePurchase: false,
        verificationData: FakePurchaseVerificationData(serverVerificationData: 'token_monthly'),
      );

      purchaseStreamController.add([monthlyPurchase]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final capturedMonthly = verify(
        () => mockCallable.call<dynamic>(captureAny()),
      ).captured.single as Map<String, dynamic>;

      expect(capturedMonthly['grantType'], equals('premium'));
      expect(capturedMonthly['days'], equals(30));

      final yearlyPurchase = FakePurchaseDetails(
        purchaseID: 'tx_yearly',
        productID: InAppPurchaseService.premiumYearly,
        status: PurchaseStatus.purchased,
        pendingCompletePurchase: false,
        verificationData: FakePurchaseVerificationData(serverVerificationData: 'token_yearly'),
      );

      purchaseStreamController.add([yearlyPurchase]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final capturedYearly = verify(
        () => mockCallable.call<dynamic>(captureAny()),
      ).captured.last as Map<String, dynamic>;

      expect(capturedYearly['grantType'], equals('premium'));
      expect(capturedYearly['days'], equals(365));
    });

    test('PurchaseStatus.purchased for Coins pack passes grantType coins', () async {
      await service.initialize();

      final mockResult = MockHttpsCallableResult<dynamic>();
      when(() => mockResult.data).thenReturn({'success': true});
      when(() => mockCallable.call<dynamic>(any())).thenAnswer((_) async => mockResult);

      final coinPurchase = FakePurchaseDetails(
        purchaseID: 'tx_coins',
        productID: InAppPurchaseService.coinPack500,
        status: PurchaseStatus.purchased,
        pendingCompletePurchase: true,
        verificationData: FakePurchaseVerificationData(serverVerificationData: 'token_coins'),
      );

      purchaseStreamController.add([coinPurchase]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final captured = verify(
        () => mockCallable.call<dynamic>(captureAny()),
      ).captured.single as Map<String, dynamic>;

      expect(captured['grantType'], equals('coins'));
      expect(captured.containsKey('days'), isFalse);
    });

    test('PurchaseStatus.restored invokes onPurchaseRestored callback upon successful backend validation', () async {
      await service.initialize();

      final mockResult = MockHttpsCallableResult<dynamic>();
      when(() => mockResult.data).thenReturn({'success': true});
      when(() => mockCallable.call<dynamic>(any())).thenAnswer((_) async => mockResult);

      bool restoredInvoked = false;
      service.onPurchaseRestored = () => restoredInvoked = true;

      final restoredPurchase = FakePurchaseDetails(
        purchaseID: 'tx_restored',
        productID: InAppPurchaseService.premiumMonthly,
        status: PurchaseStatus.restored,
        pendingCompletePurchase: true,
        verificationData: FakePurchaseVerificationData(serverVerificationData: 'token_restored'),
      );

      purchaseStreamController.add([restoredPurchase]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(restoredInvoked, isTrue);
      verify(() => mockIap.completePurchase(restoredPurchase)).called(1);
    });

    test('ANTI-FRAUD: Backend rejection (success != true) DOES NOT complete purchase and triggers error', () async {
      await service.initialize();

      final mockResult = MockHttpsCallableResult<dynamic>();
      when(() => mockResult.data).thenReturn({'success': false, 'error': 'Invalid receipt'});
      when(() => mockCallable.call<dynamic>(any())).thenAnswer((_) async => mockResult);

      String? errorReceived;
      service.onPurchaseError = (err) => errorReceived = err;
      bool successInvoked = false;
      service.onPurchaseSuccess = (_) => successInvoked = true;

      final fraudulentPurchase = FakePurchaseDetails(
        purchaseID: 'tx_fraud',
        productID: InAppPurchaseService.premiumMonthly,
        status: PurchaseStatus.purchased,
        pendingCompletePurchase: true,
        verificationData: FakePurchaseVerificationData(serverVerificationData: 'tampered_receipt'),
      );

      purchaseStreamController.add([fraudulentPurchase]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(errorReceived, equals('Verification failed. Contact support.'));
      expect(successInvoked, isFalse);

      // ZERO MONEY LEAKAGE: Never complete purchase when server validation fails!
      verifyNever(() => mockIap.completePurchase(any()));
    });

    test('NETWORK RESILIENCE: Cloud Function exception DOES NOT complete purchase and triggers error', () async {
      await service.initialize();

      when(() => mockCallable.call<dynamic>(any())).thenThrow(
        FirebaseFunctionsException(
          message: 'Backend server timeout',
          code: 'unavailable',
        ),
      );

      String? errorReceived;
      service.onPurchaseError = (err) => errorReceived = err;

      final purchase = FakePurchaseDetails(
        purchaseID: 'tx_net_error',
        productID: InAppPurchaseService.premiumMonthly,
        status: PurchaseStatus.purchased,
        pendingCompletePurchase: true,
        verificationData: FakePurchaseVerificationData(serverVerificationData: 'token_timeout'),
      );

      purchaseStreamController.add([purchase]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(errorReceived, equals('Could not verify purchase. Please try again.'));

      // ZERO MONEY LEAKAGE: Never complete purchase when verification errors out!
      verifyNever(() => mockIap.completePurchase(any()));
    });
  });
}

