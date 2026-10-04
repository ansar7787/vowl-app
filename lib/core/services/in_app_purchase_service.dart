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
  void Function(String)? onPurchaseCanceled;
  void Function()? onPurchaseRestored;

  Future<void> initialize() async {
    // Load the cached country code from SharedPreferences FIRST (awaited)
    // so isUserInIndia is reliable immediately. The HTTP refresh runs
    // in the background after — it only updates the cache for next launch.
    await _loadCachedCountryCode();
    _refreshGeoIpCountryInBackground(); // fire-and-forget HTTP refresh

    isAvailable = await _iap.isAvailable();
    if (!isAvailable) return;

    await _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        if (kDebugMode) debugPrint('IAP stream error: $error');
      },
    );

    await loadProducts();
  }

  /// Synchronously loads the cached country code from SharedPreferences.
  /// This is fast (local disk) and ensures isUserInIndia works on first check.
  Future<void> _loadCachedCountryCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedCountryCode = prefs.getString('cached_geoip_country');
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to load cached country: $e');
    }
  }

  /// Refreshes the GeoIP country code via HTTP in the background.
  /// Updates SharedPreferences cache for future app launches.
  void _refreshGeoIpCountryInBackground() {
    _fetchGeoIpCountry();
  }

  Future<void> _fetchGeoIpCountry() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    try {
      // Only refresh via HTTP — the cached value was already loaded
      // by _loadCachedCountryCode() in initialize().
      final request = await client.getUrl(Uri.parse('https://api.country.is/'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        if (data['country'] != null) {
          _cachedCountryCode = data['country'];
          final prefs = await SharedPreferences.getInstance();
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
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP: Products not found: ${response.notFoundIDs}');
    }
    products = response.productDetails;
  }

  Future<void> buyProduct(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);

    // All products are consumable:
    // - Coin packs are obviously consumable (one-time credit).
    // - Premium plans are TIME-LIMITED (weekly/monthly/yearly) with no
    //   auto-renewal ("one-time payment, no recurring charges"), so they
    //   must also be consumable. Using buyNonConsumable would make Google
    //   Play treat them as permanent one-time purchases, blocking
    //   re-purchase after expiry and restoring expired premium forever.
    final launched = await _iap.buyConsumable(purchaseParam: purchaseParam);
    if (!launched) {
      onPurchaseError?.call('Could not launch purchase. Please try again.');
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Purchase is pending (e.g. parental approval, slow bank)
          // Don't reset processing state - the purchase stream will update later
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndDeliver(purchase);
          break;
        case PurchaseStatus.error:
          onPurchaseError?.call(purchase.error?.message ?? 'Purchase failed');
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.canceled:
          onPurchaseCanceled?.call('Purchase cancelled');
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    try {
      // Call Cloud Function for server-side validation AND granting.
      // The Cloud Function must both validate the Google Play receipt
      // and grant the purchased item (premium days or coins+keys),
      // mirroring the Razorpay verifyPayment/verifyCoinPurchase flow.
      final callable = FirebaseFunctions.instance.httpsCallable(
        'validateIAPReceipt',
      );

      final Map<String, dynamic> payload = {
        'purchaseToken': purchase.verificationData.serverVerificationData,
        'productId': purchase.productID,
      };

      // Tell the Cloud Function what to grant based on product type.
      // The Cloud Function should use productId to determine exact amounts,
      // but we pass the type hint for routing to the correct granting logic.
      if (_isPremiumProduct(purchase.productID)) {
        payload['grantType'] = 'premium';
        // Days are derived from productId on the server, but pass as hint:
        payload['days'] = _getPremiumDays(purchase.productID);
      } else {
        payload['grantType'] = 'coins';
      }

      final result = await callable.call<dynamic>(payload);
      final data = result.data;

      if (data is Map && data['success'] == true) {
        // Only complete purchase AFTER successful server verification
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        onPurchaseSuccess?.call(purchase);
        if (purchase.status == PurchaseStatus.restored) {
          onPurchaseRestored?.call();
        }
      } else {
        onPurchaseError?.call('Verification failed. Contact support.');
        // Do NOT complete purchase - let Google Play retry later
      }
    } catch (e) {
      // If server validation fails, don't deliver
      onPurchaseError?.call('Could not verify purchase. Please try again.');
      // Do NOT complete purchase - let Google Play retry on next app launch
    }
  }

  bool _isPremiumProduct(String productId) {
    return productId == premiumWeekly ||
        productId == premiumMonthly ||
        productId == premiumYearly;
  }

  int _getPremiumDays(String productId) {
    switch (productId) {
      case premiumWeekly:
        return 7;
      case premiumMonthly:
        return 30;
      case premiumYearly:
        return 365;
      default:
        return 30; // safe fallback
    }
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
