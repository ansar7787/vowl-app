import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vowl/features/auth/domain/usecases/get_current_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Abstract contract defining the payment processing system.
///
/// Decouples the concrete Razorpay implementation from the application core,
/// satisfying the Dependency Inversion Principle (DIP).
abstract class PaymentService {
  /// Factory constructor to support seamless backwards compatibility for callers.
  factory PaymentService({
    required GetCurrentUser getCurrentUser,
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  }) = RazorpayPaymentService;

  /// Initializes payment listener handlers.
  void init({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  });

  /// Opens the native checkout interface.
  ///
  /// Returns `true` if checkout was actually launched, `false` if it was
  /// rejected (e.g. missing configuration) before reaching the SDK.
  bool openCheckout({
    required double amount,
    required String contact,
    required String email,
    String? orderId,
    String currency = 'INR',
    String description = 'Vowl Premium - 30 Days',
  });

  /// Creates a server-side Razorpay order with the correct amount locked.
  /// Returns the order details map on success, or throws on failure.
  Future<Map<String, dynamic>> createOrder({String? planId, String? packId});

  /// Triggers a subscription purchase flow.
  ///
  /// Creates a server-side order first, then opens checkout.
  /// Returns `true` if checkout was actually launched.
  Future<bool> purchaseSubscription({
    required String contact,
    required String email,
    required String planId,
    required double amount,
    required int days,
    required String planName,
    String currency = 'INR',
  });

  /// Upgrades user subscription validity by calling the secure backend endpoint.
  Future<void> upgradeToPremium({
    required String orderId,
    required String paymentId,
    required String signature,
    required int days,
  });

  /// Securely verifies a coin pack purchase and grants items via backend.
  Future<void> verifyCoinPurchase({
    required String orderId,
    required String paymentId,
    required String signature,
    required int coins,
    required int keys,
    required String packId,
  });

  /// Releases resources, event listeners, and pending transactions.
  void dispose();
}

/// Concrete implementation of [PaymentService] integrated with Razorpay gateway.
class RazorpayPaymentService implements PaymentService {
  final GetCurrentUser getCurrentUser;
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  Razorpay? _razorpay;

  RazorpayPaymentService({
    required this.getCurrentUser,
    required this.firestore,
    required this.functions,
  });

  @override
  void init({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    // Prevent memory leaks by clearing any existing active instances
    _razorpay?.clear();

    final instance = Razorpay();
    instance.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    instance.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    instance.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);

    _razorpay = instance;
  }

  @override
  bool openCheckout({
    required double amount,
    required String contact,
    required String email,
    String? orderId,
    String currency = 'INR',
    String description = 'Vowl Premium - 30 Days',
  }) {
    final razorpayKey = dotenv.env['RAZORPAY_KEY_ID'];

    if (razorpayKey == null || razorpayKey.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'WARNING: Razorpay Key ID is not configured in .env variables.',
        );
      }
      return false;
    }

    final sdk = _razorpay;
    if (sdk == null) {
      if (kDebugMode) {
        debugPrint(
          'CRITICAL: PaymentService.init() was not called before openCheckout.',
        );
      }
      return false;
    }

    final amountInSmallestUnit = (amount * 100).round();

    final options = {
      'key': razorpayKey,
      'amount': amountInSmallestUnit,
      'currency': currency.toUpperCase(),
      'name': 'Vowl',
      'description': description,
      // ignore: use_null_aware_elements
      if (orderId != null) 'order_id': orderId,
      'prefill': {
        if (contact.isNotEmpty) 'contact': contact,
        if (email.isNotEmpty) 'email': email,
      },
    };

    try {
      sdk.open(options);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Razorpay Checkout Execution Error: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> createOrder({
    String? planId,
    String? packId,
  }) async {
    assert(planId != null || packId != null, 'Must provide planId or packId');
    try {
      final result = await functions
          .httpsCallable('createOrder')
          .call({
            // ignore: use_null_aware_elements
            if (planId != null) 'planId': planId,
            // ignore: use_null_aware_elements
            if (packId != null) 'packId': packId,
          })
          .timeout(const Duration(seconds: 30));
      return Map<String, dynamic>.from(result.data as Map);
    } on TimeoutException {
      throw Exception('Order creation timed out. Please try again.');
    } catch (e) {
      if (kDebugMode) debugPrint('createOrder error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> purchaseSubscription({
    required String contact,
    required String email,
    required String planId,
    required double amount,
    required int days,
    required String planName,
    String currency = 'INR',
  }) async {
    // 1. Create server-side order (amount locked by server)
    final orderData = await createOrder(planId: planId);
    final orderId = orderData['orderId'] as String;
    final serverAmount = (orderData['amount'] as num).toDouble() / 100;
    final serverCurrency = orderData['currency'] as String? ?? currency;

    // 2. Open checkout with server-generated order
    return openCheckout(
      amount: serverAmount,
      contact: contact,
      email: email,
      orderId: orderId,
      currency: serverCurrency,
      description: 'Vowl Pro - $planName ($days Days)',
    );
  }

  /// Bound on the payment-verification round trip. Without this, a bad
  /// network leaves `await callable.call(...)` pending indefinitely,
  /// stranding the caller's "confirming your payment" UI with no way to
  /// resolve - especially damaging here since the user's money has already
  /// left their account by this point in the flow. Mirrors the same
  /// defensive timeout pattern already used elsewhere in this codebase
  /// (`SubscriptionPlansService._fetchTimeout`, `RemoteConfigSettings.
  /// fetchTimeout`).
  static const Duration _verifyPaymentTimeout = Duration(seconds: 30);

  @override
  Future<void> upgradeToPremium({
    required String orderId,
    required String paymentId,
    required String signature,
    required int days,
  }) async {
    try {
      final callable = functions.httpsCallable('verifyPayment');
      final response = await callable
          .call({
            'orderId': orderId,
            'paymentId': paymentId,
            'signature': signature,
            'durationDays': days,
          })
          .timeout(
            _verifyPaymentTimeout,
            onTimeout: () => throw Exception(
              'Payment verification timed out. If the amount was debited, '
              'it will be confirmed automatically - please check your '
              'account status in a few minutes before retrying.',
            ),
          );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception('Server rejected the payment verification.');
      }

      if (kDebugMode) {
        debugPrint('User subscription upgraded securely via Cloud Function.');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to upgrade user subscription: $e');
      rethrow;
    }
  }

  @override
  Future<void> verifyCoinPurchase({
    required String orderId,
    required String paymentId,
    required String signature,
    required int coins,
    required int keys,
    required String packId,
  }) async {
    try {
      final callable = functions.httpsCallable('verifyCoinPurchase');
      final response = await callable
          .call({
            'orderId': orderId,
            'paymentId': paymentId,
            'signature': signature,
            'coins': coins,
            'keys': keys,
            'packId': packId,
          })
          .timeout(
            _verifyPaymentTimeout,
            onTimeout: () => throw Exception(
              'Payment verification timed out. If the amount was debited, '
              'it will be confirmed automatically - please check your '
              'account status in a few minutes before retrying.',
            ),
          );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception('Server rejected the coin purchase verification.');
      }

      if (kDebugMode) {
        debugPrint('Coin purchase verified securely via Cloud Function.');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to verify coin purchase: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
