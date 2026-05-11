import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vowl/features/auth/domain/usecases/get_current_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  late Razorpay _razorpay;
  final GetCurrentUser getCurrentUser;
  final FirebaseFirestore firestore;

  PaymentService({required this.getCurrentUser, required this.firestore});

  void init({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  void openCheckout({
    required double amount,
    required String contact,
    required String email,
    String description = 'Vowl Premium - 30 Days',
  }) {
    var options = {
      'key': dotenv.env['RAZORPAY_KEY_ID'] ?? '',
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'Vowl',
      'description': description,
      'prefill': {'contact': contact, 'email': email},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

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

  Future<void> upgradeToPremium(String userId, int days) async {
    final expiryDate = DateTime.now().add(Duration(days: days));
    await firestore.collection('users').doc(userId).update({
      'isPremium': true,
      'premiumExpiryDate': Timestamp.fromDate(expiryDate),
    });
  }

  void dispose() {
    _razorpay.clear();
  }
}
