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
    String description = 'Vowl Premium - 30 Days',
  });

  /// Triggers a subscription purchase flow.
  ///
  /// Returns `true` if checkout was actually launched.
  bool purchaseSubscription({
    required String contact,
    required String email,
    required double amount,
    required int days,
    required String planName,
  });

  /// Upgrades user subscription validity by calling the secure backend endpoint.
  Future<void> upgradeToPremium({
    required String orderId,
    required String paymentId,
    required String signature,
    required int days,
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
    String description = 'Vowl Premium - 30 Days',
  }) {
    final razorpayKey = dotenv.env['RAZORPAY_KEY_ID'];

    // BUG FIX: previously this only *logged* a warning when the key was
    // missing, then proceeded to call `sdk.open()` anyway with an empty
    // key — handing the user a confusing native SDK failure instead of a
    // clean, predictable in-app outcome. Bail out before ever reaching the
    // SDK so the caller can show a proper "try again later" message.
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

    // BUG FIX (currency precision): `(amount * 100).toInt()` truncates
    // rather than rounds. Due to binary floating-point representation,
    // amounts like 9.99 can evaluate to 998.999999999, which `.toInt()`
    // truncates to 998 paise instead of 999 — silently undercharging by a
    // paisa and risking a mismatch against the price actually shown to the
    // user. `.round()` resolves to the nearest integer paisa instead.
    final amountInPaise = (amount * 100).round();

    final options = {
      'key': razorpayKey,
      'amount': amountInPaise, // Razorpay expects amount in paise
      'name': 'Vowl',
      'description': description,
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
  bool purchaseSubscription({
    required String contact,
    required String email,
    required double amount,
    required int days,
    required String planName,
  }) {
    return openCheckout(
      amount: amount,
      contact: contact,
      email: email,
      description: 'Vowl Pro - $planName ($days Days)',
    );
  }

  @override
  Future<void> upgradeToPremium({
    required String orderId,
    required String paymentId,
    required String signature,
    required int days,
  }) async {
    try {
      final callable = functions.httpsCallable('verifyPayment');
      final response = await callable.call({
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
        'durationDays': days,
      });
      
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
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
