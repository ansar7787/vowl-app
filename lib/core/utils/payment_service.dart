import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vowl/features/auth/domain/usecases/get_current_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstract contract defining the payment processing system.
///
/// Decouples the concrete Razorpay implementation from the application core,
/// satisfying the Dependency Inversion Principle (DIP).
abstract class PaymentService {
  /// Factory constructor to support seamless backwards compatibility for callers.
  factory PaymentService({
    required GetCurrentUser getCurrentUser,
    required FirebaseFirestore firestore,
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

  /// Upgrades user subscription validity in backend records.
  Future<void> upgradeToPremium(String userId, int days);

  /// Releases resources, event listeners, and pending transactions.
  void dispose();
}

/// Concrete implementation of [PaymentService] integrated with Razorpay gateway.
class RazorpayPaymentService implements PaymentService {
  final GetCurrentUser getCurrentUser;
  final FirebaseFirestore firestore;

  Razorpay? _razorpay;

  RazorpayPaymentService({
    required this.getCurrentUser,
    required this.firestore,
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
      'external': {
        'wallets': ['paytm'],
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
  Future<void> upgradeToPremium(String userId, int days) async {
    // ──────────────────────────────────────────────────────────────────
    // CRITICAL SECURITY NOTE — DO NOT REMOVE THIS COMMENT WHEN EDITING:
    //
    // This method grants a real paid entitlement (`isPremium: true`) based
    // solely on a CLIENT-OBSERVED Razorpay success callback. The Razorpay
    // client SDK's "success" event is NOT cryptographically verified on
    // device — it can be spoofed by a modified client, a MITM proxy, or by
    // directly invoking this method. For a production release this MUST be
    // re-architected so the entitlement is granted by a trusted backend
    // (e.g. a Cloud Function / webhook) that independently verifies the
    // Razorpay payment signature server-side using the secret key, which
    // must never be shipped to the client. The client should call that
    // verified endpoint (or simply re-read the user doc after the backend
    // updates it) rather than writing `isPremium` directly from here.
    //
    // Left intact functionally (so this PR doesn't silently break premium
    // purchases) pending that backend work — tracked as a Critical finding
    // in the accompanying review, not something safe to "fix" blindly
    // without the corresponding server-side verification endpoint.
    // ──────────────────────────────────────────────────────────────────
    try {
      final expiryDate = DateTime.now().add(Duration(days: days));
      await firestore.collection('users').doc(userId).update({
        'isPremium': true,
        'premiumExpiryDate': Timestamp.fromDate(expiryDate),
      });
      if (kDebugMode) {
        debugPrint('User subscription upgraded successfully for $days days.');
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
