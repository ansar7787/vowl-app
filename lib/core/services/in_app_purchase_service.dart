import 'dart:async';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Manages Google Play Billing purchases for non-India markets.
///
/// For India, the app uses Razorpay (protected by CCI ruling).
/// For all other countries, Google Play Billing is required.
class InAppPurchaseService {
  static final InAppPurchaseService _instance = InAppPurchaseService._();
  static InAppPurchaseService get instance => _instance;
  InAppPurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Product IDs matching what you'll configure in Play Console
  static const String premiumWeekly = 'vowl_premium_weekly';
  static const String premiumMonthly = 'vowl_premium_monthly';
  static const String premiumYearly = 'vowl_premium_yearly';
  static const String coinPack100 = 'vowl_coins_100';
  static const String coinPack500 = 'vowl_coins_500';
  static const String coinPack1000 = 'vowl_coins_1000';

  static const Set<String> _productIds = {
    premiumWeekly,
    premiumMonthly,
    premiumYearly,
    coinPack100,
    coinPack500,
    coinPack1000,
  };

  List<ProductDetails> products = [];
  bool isAvailable = false;

  // Callbacks
  void Function(PurchaseDetails)? onPurchaseSuccess;
  void Function(String error)? onPurchaseError;
  void Function()? onPurchaseRestored;

  Future<void> initialize() async {
    isAvailable = await _iap.isAvailable();
    if (!isAvailable) return;

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        if (kDebugMode) debugPrint('IAP stream error: $error');
      },
    );

    await loadProducts();
  }

  Future<void> loadProducts() async {
    final response = await _iap.queryProductDetails(_productIds);
    if (response.error != null) {
      if (kDebugMode) debugPrint('IAP query error: ${response.error}');
      return;
    }
    products = response.productDetails;
  }

  Future<void> buyProduct(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);

    // Consumables (coins) vs non-consumables (premium)
    if (_isConsumable(product.id)) {
      await _iap.buyConsumable(purchaseParam: purchaseParam);
    } else {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Show loading indicator
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndDeliver(purchase);
          break;
        case PurchaseStatus.error:
          onPurchaseError?.call(purchase.error?.message ?? 'Purchase failed');
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.canceled:
          break;
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    try {
      // Call Cloud Function for server-side validation
      final callable = FirebaseFunctions.instance.httpsCallable(
        'validateIAPReceipt',
      );
      final result = await callable.call({
        'purchaseToken': purchase.verificationData.serverVerificationData,
        'productId': purchase.productID,
      });

      if (result.data['success'] == true) {
        onPurchaseSuccess?.call(purchase);
        if (purchase.status == PurchaseStatus.restored) {
          onPurchaseRestored?.call();
        }
      } else {
        onPurchaseError?.call('Purchase validation failed');
      }
    } catch (e) {
      // If server validation fails, don't deliver
      onPurchaseError?.call('Could not verify purchase. Please try again.');
    } finally {
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  bool _isConsumable(String productId) {
    return productId.contains('coins');
  }

  /// Whether to use IAP (non-India) or Razorpay (India)
  static bool get shouldUseIAP {
    // Platform.localeName gives locale like 'en_IN'
    // We use Razorpay for India, IAP everywhere else
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    final locale = Platform.localeName;
    return !locale.endsWith('_IN');
  }

  void dispose() {
    _subscription?.cancel();
  }
}
