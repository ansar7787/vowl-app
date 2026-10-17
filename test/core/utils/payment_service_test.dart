// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:vowl/core/utils/payment_service.dart';

// ---------------------------------------------------------------------------
// Mocks & Test Doubles
// ---------------------------------------------------------------------------

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult<T> extends Mock implements HttpsCallableResult<T> {}

class MockRazorpay extends Mock implements Razorpay {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockRazorpay mockRazorpay;
  late RazorpayPaymentService paymentService;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockRazorpay = MockRazorpay();

    paymentService = RazorpayPaymentService(functions: mockFunctions);
    paymentService.testRazorpayInstance = mockRazorpay;

    dotenv.loadFromString(envString: 'RAZORPAY_KEY_ID=rzp_test_1234567890');

    when(() => mockRazorpay.on(any(), any())).thenReturn(null);
    when(() => mockRazorpay.clear()).thenReturn(null);
    when(() => mockRazorpay.open(any())).thenReturn(null);
  });

  tearDown(() {
    paymentService.dispose();
  });

  // =========================================================================
  // GROUP 1: Contract Factory, Initialization & Lifecycle
  // =========================================================================
  group('Group 1: Contract Factory, Initialization & Lifecycle', () {
    test('PaymentService factory constructor creates RazorpayPaymentService instance', () {
      final service = PaymentService(functions: mockFunctions);
      expect(service, isA<RazorpayPaymentService>());
    });

    test('init registers event handlers on Razorpay instance', () {
      void onSuccess(PaymentSuccessResponse r) {}
      void onFailure(PaymentFailureResponse r) {}
      void onExternalWallet(ExternalWalletResponse r) {}

      paymentService.init(
        onSuccess: onSuccess,
        onFailure: onFailure,
        onExternalWallet: onExternalWallet,
      );

      verify(() => mockRazorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess)).called(1);
      verify(() => mockRazorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure)).called(1);
      verify(() => mockRazorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet)).called(1);
    });

    test('calling init multiple times clears previous instance to prevent leaks', () {
      paymentService.init(
        onSuccess: (_) {},
        onFailure: (_) {},
        onExternalWallet: (_) {},
      );

      paymentService.init(
        onSuccess: (_) {},
        onFailure: (_) {},
        onExternalWallet: (_) {},
      );

      verify(() => mockRazorpay.clear()).called(1);
    });

    test('dispose clears and nullifies Razorpay instance', () {
      paymentService.init(
        onSuccess: (_) {},
        onFailure: (_) {},
        onExternalWallet: (_) {},
      );

      paymentService.dispose();

      verify(() => mockRazorpay.clear()).called(1);

      // Attempting to open checkout after dispose fails because instance is null
      final result = paymentService.openCheckout(
        amount: 100,
        contact: '9999999999',
        email: 'test@vowl.app',
      );
      expect(result, isFalse);
    });
  });

  // =========================================================================
  // GROUP 2: Checkout Options & Pre-Flight Validation
  // =========================================================================
  group('Group 2: Checkout Options & Pre-Flight Validation', () {
    test('openCheckout returns false when RAZORPAY_KEY_ID is missing from env', () {
      dotenv.clean(); // Empty env

      paymentService.init(
        onSuccess: (_) {},
        onFailure: (_) {},
        onExternalWallet: (_) {},
      );

      final result = paymentService.openCheckout(
        amount: 149.0,
        contact: '9999999999',
        email: 'test@vowl.app',
      );

      expect(result, isFalse);
      verifyNever(() => mockRazorpay.open(any()));
    });

    test('openCheckout returns false when init was not called before checkout', () {
      // paymentService has not called init(), so _razorpay is null
      final uninitializedService = RazorpayPaymentService(functions: mockFunctions);

      final result = uninitializedService.openCheckout(
        amount: 149.0,
        contact: '9999999999',
        email: 'test@vowl.app',
      );

      expect(result, isFalse);
    });

    test('openCheckout constructs options map with smallest currency unit (amount * 100)', () {
      paymentService.init(
        onSuccess: (_) {},
        onFailure: (_) {},
        onExternalWallet: (_) {},
      );

      final result = paymentService.openCheckout(
        amount: 149.0,
        contact: '9876543210',
        email: 'quester@vowl.app',
        orderId: 'order_test_999',
        currency: 'inr',
        description: 'Vowl Pro 30 Days',
      );

      expect(result, isTrue);

      final captured = verify(() => mockRazorpay.open(captureAny())).captured.single as Map<String, dynamic>;
      expect(captured['key'], equals('rzp_test_1234567890'));
      expect(captured['amount'], equals(14900)); // 149.0 * 100
      expect(captured['currency'], equals('INR')); // Uppercase
      expect(captured['name'], equals('Vowl'));
      expect(captured['description'], equals('Vowl Pro 30 Days'));
      expect(captured['order_id'], equals('order_test_999'));

      final prefill = captured['prefill'] as Map<String, dynamic>;
      expect(prefill['contact'], equals('9876543210'));
      expect(prefill['email'], equals('quester@vowl.app'));
    });

    test('openCheckout omits empty prefill contact and orderId when not supplied', () {
      paymentService.init(
        onSuccess: (_) {},
        onFailure: (_) {},
        onExternalWallet: (_) {},
      );

      final result = paymentService.openCheckout(
        amount: 49.0,
        contact: '',
        email: 'solo@vowl.app',
        orderId: null,
      );

      expect(result, isTrue);

      final captured = verify(() => mockRazorpay.open(captureAny())).captured.single as Map<String, dynamic>;
      expect(captured.containsKey('order_id'), isFalse);
      final prefill = captured['prefill'] as Map<String, dynamic>;
      expect(prefill.containsKey('contact'), isFalse);
      expect(prefill['email'], equals('solo@vowl.app'));
    });

    test('openCheckout catches SDK exception and returns false safely', () {
      when(() => mockRazorpay.open(any())).thenThrow(Exception('Native bridge failure'));

      paymentService.init(
        onSuccess: (_) {},
        onFailure: (_) {},
        onExternalWallet: (_) {},
      );

      final result = paymentService.openCheckout(
        amount: 149.0,
        contact: '9999999999',
        email: 'test@vowl.app',
      );

      expect(result, isFalse);
    });
  });

  // =========================================================================
  // GROUP 3: Server-Side Order Creation (createOrder)
  // =========================================================================
  group('Group 3: Server-Side Order Creation (createOrder)', () {
    test('createOrder calls createOrder Cloud Function with planId for subscriptions', () async {
      when(() => mockFunctions.httpsCallable('createOrder')).thenReturn(mockCallable);
      final mockResult = MockHttpsCallableResult<dynamic>();
      when(() => mockResult.data).thenReturn({
        'orderId': 'order_server_123',
        'amount': 14900,
        'currency': 'INR',
      });
      when(() => mockCallable.call<dynamic>(any())).thenAnswer((_) async => mockResult);

      final orderData = await paymentService.createOrder(planId: 'monthly');

      expect(orderData['orderId'], equals('order_server_123'));
      expect(orderData['amount'], equals(14900));

      final captured = verify(() => mockCallable.call<dynamic>(captureAny())).captured.single as Map<String, dynamic>;
      expect(captured['planId'], equals('monthly'));
      expect(captured.containsKey('packId'), isFalse);
    });

    test('createOrder calls createOrder Cloud Function with packId for coin packs', () async {
      when(() => mockFunctions.httpsCallable('createOrder')).thenReturn(mockCallable);
      final mockResult = MockHttpsCallableResult<dynamic>();
      when(() => mockResult.data).thenReturn({
        'orderId': 'order_coin_456',
        'amount': 4900,
        'currency': 'INR',
      });
      when(() => mockCallable.call<dynamic>(any())).thenAnswer((_) async => mockResult);

      final orderData = await paymentService.createOrder(packId: 'coins_100');

      expect(orderData['orderId'], equals('order_coin_456'));

      final captured = verify(() => mockCallable.call<dynamic>(captureAny())).captured.single as Map<String, dynamic>;
      expect(captured['packId'], equals('coins_100'));
      expect(captured.containsKey('planId'), isFalse);
    });

    test('createOrder asserts when both planId and packId are null', () {
      expect(
        () => paymentService.createOrder(),
        throwsA(isA<AssertionError>()),
      );
    });

    test('createOrder transforms TimeoutException into user-friendly error', () async {
      when(() => mockFunctions.httpsCallable('createOrder')).thenReturn(mockCallable);
      when(() => mockCallable.call<dynamic>(any())).thenAnswer(
        (_) => Future<HttpsCallableResult<dynamic>>.delayed(
          const Duration(seconds: 35),
        ),
      );

      // We test the timeout branch using a direct simulation
      final timeoutService = RazorpayPaymentService(functions: mockFunctions);
      when(() => mockCallable.call<dynamic>(any())).thenThrow(TimeoutException('timed out'));

      expect(
        () => timeoutService.createOrder(planId: 'monthly'),
        throwsA(
          predicate<Exception>(
            (e) => e.toString().contains('Order creation timed out. Please try again.'),
          ),
        ),
      );
    });

    test('createOrder rethrows server exceptions', () async {
      when(() => mockFunctions.httpsCallable('createOrder')).thenReturn(mockCallable);
      when(() => mockCallable.call<dynamic>(any())).thenThrow(
        FirebaseFunctionsException(
          message: 'Server error creating order',
          code: 'internal',
        ),
      );

      expect(
        () => paymentService.createOrder(planId: 'monthly'),
        throwsA(isA<FirebaseFunctionsException>()),
      );
    });
  });

  // =========================================================================
  // GROUP 4: Subscription Purchase Flow (purchaseSubscription)
  // =========================================================================
  group('Group 4: Subscription Purchase Flow (purchaseSubscription)', () {
    test('purchaseSubscription locks price via server order before opening checkout', () async {
      when(() => mockFunctions.httpsCallable('createOrder')).thenReturn(mockCallable);
      final mockResult = MockHttpsCallableResult<dynamic>();
      when(() => mockResult.data).thenReturn({
        'orderId': 'order_server_locked_777',
        'amount': 19900, // 199.0 server locked amount
        'currency': 'INR',
      });
      when(() => mockCallable.call<dynamic>(any())).thenAnswer((_) async => mockResult);

      paymentService.init(
        onSuccess: (_) {},
        onFailure: (_) {},
        onExternalWallet: (_) {},
      );

      final launched = await paymentService.purchaseSubscription(
        contact: '9123456780',
        email: 'subscriber@vowl.app',
        planId: 'monthly',
        days: 30,
        planName: 'Monthly Pro',
      );

      expect(launched, isTrue);

      final captured = verify(() => mockRazorpay.open(captureAny())).captured.single as Map<String, dynamic>;
      expect(captured['amount'], equals(19900)); // Locked from server!
      expect(captured['order_id'], equals('order_server_locked_777'));
      expect(captured['description'], equals('Vowl Pro - Monthly Pro (30 Days)'));
    });
  });

  // =========================================================================
  // GROUP 5: Zero Money Leakage: Subscription Upgrade Endpoint (upgradeToPremium)
  // =========================================================================
  group('Group 5: Zero Money Leakage: Subscription Upgrade Endpoint (upgradeToPremium)', () {
    test('upgradeToPremium calls verifyPayment with durationDays and succeeds on success == true', () async {
      when(() => mockFunctions.httpsCallable('verifyPayment')).thenReturn(mockCallable);
      final mockResult = MockHttpsCallableResult<dynamic>();
      when(() => mockResult.data).thenReturn({'success': true});
      when(() => mockCallable.call<dynamic>(any())).thenAnswer((_) async => mockResult);

      await paymentService.upgradeToPremium(
        orderId: 'order_123',
        paymentId: 'pay_456',
        signature: 'sig_789',
        days: 30,
      );

      final captured = verify(() => mockCallable.call<dynamic>(captureAny())).captured.single as Map<String, dynamic>;
      expect(captured['orderId'], equals('order_123'));
      expect(captured['paymentId'], equals('pay_456'));
      expect(captured['signature'], equals('sig_789'));
      expect(captured['durationDays'], equals(30));
    });

    test('ANTI-FRAUD: upgradeToPremium throws Exception when backend rejects verification (success != true)', () async {
      when(() => mockFunctions.httpsCallable('verifyPayment')).thenReturn(mockCallable);
      final mockResult = MockHttpsCallableResult<dynamic>();
      when(() => mockResult.data).thenReturn({'success': false, 'error': 'Invalid signature'});
      when(() => mockCallable.call<dynamic>(any())).thenAnswer((_) async => mockResult);

      expect(
        () => paymentService.upgradeToPremium(
          orderId: 'order_fake',
          paymentId: 'pay_fake',
          signature: 'sig_fake',
          days: 30,
        ),
        throwsA(
          predicate<Exception>(
            (e) => e.toString().contains('Server rejected the payment verification.'),
          ),
        ),
      );
    });

    test('upgradeToPremium rethrows backend network or authorization exceptions', () async {
      when(() => mockFunctions.httpsCallable('verifyPayment')).thenReturn(mockCallable);
      when(() => mockCallable.call<dynamic>(any())).thenThrow(
        FirebaseFunctionsException(message: 'Unauthorized payment', code: 'unauthenticated'),
      );

      expect(
        () => paymentService.upgradeToPremium(
          orderId: 'order_err',
          paymentId: 'pay_err',
          signature: 'sig_err',
          days: 30,
        ),
        throwsA(isA<FirebaseFunctionsException>()),
      );
    });
  });

  // =========================================================================
  // GROUP 6: Zero Money Leakage: Coin Pack Verification Endpoint (verifyCoinPurchase)
  // =========================================================================
  group('Group 6: Zero Money Leakage: Coin Pack Verification Endpoint (verifyCoinPurchase)', () {
    test('verifyCoinPurchase calls verifyCoinPurchase with coins, keys, packId and succeeds on success == true', () async {
      when(() => mockFunctions.httpsCallable('verifyCoinPurchase')).thenReturn(mockCallable);
      final mockResult = MockHttpsCallableResult<dynamic>();
      when(() => mockResult.data).thenReturn({'success': true});
      when(() => mockCallable.call<dynamic>(any())).thenAnswer((_) async => mockResult);

      await paymentService.verifyCoinPurchase(
        orderId: 'order_coin_1',
        paymentId: 'pay_coin_2',
        signature: 'sig_coin_3',
        coins: 500,
        keys: 5,
        packId: 'pack_chest_500',
      );

      final captured = verify(() => mockCallable.call<dynamic>(captureAny())).captured.single as Map<String, dynamic>;
      expect(captured['orderId'], equals('order_coin_1'));
      expect(captured['paymentId'], equals('pay_coin_2'));
      expect(captured['signature'], equals('sig_coin_3'));
      expect(captured['coins'], equals(500));
      expect(captured['keys'], equals(5));
      expect(captured['packId'], equals('pack_chest_500'));
    });

    test('ANTI-FRAUD: verifyCoinPurchase throws Exception when backend rejects coin verification', () async {
      when(() => mockFunctions.httpsCallable('verifyCoinPurchase')).thenReturn(mockCallable);
      final mockResult = MockHttpsCallableResult<dynamic>();
      when(() => mockResult.data).thenReturn({'success': false, 'error': 'Signature mismatch'});
      when(() => mockCallable.call<dynamic>(any())).thenAnswer((_) async => mockResult);

      expect(
        () => paymentService.verifyCoinPurchase(
          orderId: 'order_bad',
          paymentId: 'pay_bad',
          signature: 'sig_bad',
          coins: 1000,
          keys: 10,
          packId: 'pack_vault_1000',
        ),
        throwsA(
          predicate<Exception>(
            (e) => e.toString().contains('Server rejected the coin purchase verification.'),
          ),
        ),
      );
    });

    test('verifyCoinPurchase rethrows backend exceptions', () async {
      when(() => mockFunctions.httpsCallable('verifyCoinPurchase')).thenReturn(mockCallable);
      when(() => mockCallable.call<dynamic>(any())).thenThrow(
        FirebaseFunctionsException(message: 'Database write error', code: 'internal'),
      );

      expect(
        () => paymentService.verifyCoinPurchase(
          orderId: 'order_db_err',
          paymentId: 'pay_db_err',
          signature: 'sig_db_err',
          coins: 100,
          keys: 1,
          packId: 'pack_pouch_100',
        ),
        throwsA(isA<FirebaseFunctionsException>()),
      );
    });
  });
}

