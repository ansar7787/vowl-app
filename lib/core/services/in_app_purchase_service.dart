import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static String? _cachedCountryCode;

  // Callbacks
  void Function(PurchaseDetails)? onPurchaseSuccess;
  void Function(String error)? onPurchaseError;
  void Function()? onPurchaseRestored;

  Future<void> initialize() async {
    _fetchGeoIpCountry(); // Run asynchronously in the background
    
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

  Future<void> _fetchGeoIpCountry() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedCountryCode = prefs.getString('cached_geoip_country');

      // Refresh it in the background
      final request = await client.getUrl(Uri.parse('https://api.country.is/'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        if (data['country'] != null) {
          _cachedCountryCode = data['country'];
          await prefs.setString('cached_geoip_country', _cachedCountryCode!);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('GeoIP fetch failed: $e');
    } finally {
      client.close(); // Prevent socket leaks
    }
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
          onPurchaseError?.call('Purchase cancelled');
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
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

  /// Whether the user is located in India based on GeoIP (or locale fallback).
  static bool get isUserInIndia {
    if (_cachedCountryCode != null) {
      return _cachedCountryCode == 'IN';
    }
    final countryCode = ui.PlatformDispatcher.instance.locale.countryCode;
    return countryCode == 'IN';
  }

  /// Whether to use IAP (non-India) or Razorpay (India) by default.
  static bool get shouldUseIAP {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    return !isUserInIndia;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
