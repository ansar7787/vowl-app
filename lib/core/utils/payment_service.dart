import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
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
  void openCheckout({
    required double amount,
    required String contact,
    required String email,
    String description = 'Vowl Premium - 30 Days',
  });

  /// Triggers a subscription purchase flow.
  void purchaseSubscription({
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
  void openCheckout({
    required double amount,
    required String contact,
    required String email,
    String description = 'Vowl Premium - 30 Days',
  }) {
    final razorpayKey = dotenv.env['RAZORPAY_KEY_ID'];
    if (razorpayKey == null || razorpayKey.isEmpty) {
      debugPrint('WARNING: Razorpay Key ID is not configured in .env variables.');
    }

    final options = {
      'key': razorpayKey ?? '',
      'amount': (amount * 100).toInt(), // Razorpay expects amount in paise
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

    final sdk = _razorpay;
    if (sdk == null) {
      debugPrint('CRITICAL: PaymentService.init() was not called before openCheckout.');
      return;
    }

    try {
      sdk.open(options);
    } catch (e) {
      debugPrint('Razorpay Checkout Execution Error: $e');
    }
  }

  @override
  void purchaseSubscription({
    required String contact,
    required String email,
    required double amount,
    required int days,
    required String planName,
  }) {
    openCheckout(
      amount: amount,
      contact: contact,
      email: email,
      description: 'Vowl Pro - $planName ($days Days)',
    );
  }

  @override
  Future<void> upgradeToPremium(String userId, int days) async {
    try {
      final expiryDate = DateTime.now().add(Duration(days: days));
      await firestore.collection('users').doc(userId).update({
        'isPremium': true,
        'premiumExpiryDate': Timestamp.fromDate(expiryDate),
      });
      debugPrint('User subscription upgraded successfully for $days days.');
    } catch (e) {
      debugPrint('Failed to upgrade user subscription: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
