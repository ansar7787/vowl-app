import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Manages Google Play Billing purchases for non-India markets.
///
/// For India, the app uses Razorpay (protected by CCI ruling).
/// For all other countries, Google Play Billing is required.
class InAppPurchaseService {
  static final InAppPurchaseService _instance = InAppPurchaseService._();
  static InAppPurchaseService get instance => _instance;
  InAppPurchaseService._();

  @visibleForTesting
  static InAppPurchase? testIapInstance;

  InAppPurchase get _iap => testIapInstance ?? InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Product IDs matching what you configure in Google Play Console
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

  /// Resolves the Google Play Billing product ID for a given subscription plan.
  /// Matches on plan ID, name, duration, or index so it never mistakenly defaults to monthly.
  static String getPremiumProductId({
    String? planId,
    String? planName,
    int? days,
    int? index,
  }) {
    final id = (planId ?? '').toLowerCase().trim();
    final name = (planName ?? '').toLowerCase().trim();
    final d = days ?? 0;

    // 1. Weekly checks:
    if (id == 'weekly' ||
        id == premiumWeekly ||
        id.contains('week') ||
        name.contains('week') ||
        (d > 0 && d <= 14) ||
        index == 0) {
      return premiumWeekly;
    }

    // 2. Yearly checks:
    if (id == 'yearly' ||
        id == premiumYearly ||
        id.contains('year') ||
        id.contains('annual') ||
        name.contains('year') ||
        name.contains('annual') ||
        d >= 180 ||
        index == 2) {
      return premiumYearly;
    }

    // 3. Monthly checks / default:
    return premiumMonthly;
  }

  /// Resolves the Google Play Billing product ID for a given coin pack (100, 500, 1000 coins).
  static String getCoinPackProductId({
    String? packId,
    int? coins,
    int? index,
  }) {
    final id = (packId ?? '').toLowerCase().trim();
    final c = coins ?? 0;

    // 1. Starter pack (100 coins / index 0)
    if (id == 'starter_pack' ||
        id.contains('starter') ||
        id.contains('100') ||
        index == 0 ||
        (c > 0 && c <= 200)) {
      return coinPack100;
    }

    // 2. Master pack (1000 coins / index 2)
    if (id == 'master_pack' ||
        id.contains('master') ||
        id.contains('1000') ||
        index == 2 ||
        c >= 3000) {
      return coinPack1000;
    }

    // 3. Explorer pack (500 coins / index 1)
    if (id == 'explorer_pack' ||
        id.contains('explorer') ||
        id.contains('500') ||
        index == 1 ||
        (c >= 400 && c <= 2000)) {
      return coinPack500;
    }

    return coinPack100;
  }

  List<ProductDetails> products = [];
  bool isAvailable = false;

  static String? _cachedCountryCode;

  @visibleForTesting
  static void setCachedCountryCodeForTesting(String? code) {
    _cachedCountryCode = code;
  }

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

    try {
      isAvailable = await _iap.isAvailable().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      if (!isAvailable) return;

      await _subscription?.cancel();
      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          if (kDebugMode) debugPrint('IAP stream error: $error');
        },
      );

      await loadProducts().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('IAP loadProducts timed out (likely offline)');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('IAP initialize error: $e');
      }
    }
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
    try {
      final response = await _iap
          .queryProductDetails(_productIds)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () => ProductDetailsResponse(
              productDetails: [],
              notFoundIDs: _productIds.toList(),
              error: null,
            ),
          );
      if (response.error != null) {
        if (kDebugMode) debugPrint('IAP query error: ${response.error}');
        return;
      }
      if (response.notFoundIDs.isNotEmpty && kDebugMode) {
        debugPrint('IAP: Products not found: ${response.notFoundIDs}');
      }
      products = response.productDetails;
    } catch (e) {
      if (kDebugMode) debugPrint('IAP loadProducts failed: $e');
    }
  }

  Future<void> buyProduct(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    bool launched = false;

    try {
      if (_isPremiumProduct(product.id)) {
        // Subscriptions in Google Play Billing and StoreKit must be purchased
        // via buyNonConsumable. Calling buyConsumable on subscriptions throws DEVELOPER_ERROR.
        launched = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        // Coins are consumable items
        launched = await _iap.buyConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('IAP purchase launch error, attempting alternative mode: $e');
      }
      try {
        if (_isPremiumProduct(product.id)) {
          launched = await _iap.buyConsumable(purchaseParam: purchaseParam);
        } else {
          launched = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          debugPrint('IAP fallback failed: $fallbackError');
        }
      }
    }

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
      final functions = di.sl.isRegistered<FirebaseFunctions>()
          ? di.sl<FirebaseFunctions>()
          : FirebaseFunctions.instance;
      final callable = functions.httpsCallable('validateIAPReceipt');

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

  @visibleForTesting
  static bool? testShouldUseIAPOverride;

  /// Whether to use IAP (non-India) or Razorpay (India) by default.
  static bool get shouldUseIAP {
    if (testShouldUseIAPOverride != null) return testShouldUseIAPOverride!;
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    return !isUserInIndia;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
