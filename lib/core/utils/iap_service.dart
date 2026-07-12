import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class IapService {
  bool _isInitialized = false;

  /// Initialize RevenueCat SDK
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final apiKey = Platform.isAndroid
          ? dotenv.env['REVENUECAT_API_KEY_ANDROID']
          : dotenv.env['REVENUECAT_API_KEY_IOS'];

      if (apiKey == null || apiKey.isEmpty) {
        if (kDebugMode) {
          debugPrint('IapService: RevenueCat API Key not found in .env');
        }
        return;
      }

      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      await Purchases.configure(PurchasesConfiguration(apiKey));
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('IapService: RevenueCat configured successfully.');
      }
    } catch (e, stack) {
      if (kDebugMode) debugPrint('IapService Init Error: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'IapService Init Failed',
      );
    }
  }

  /// Fetches the current offerings (products) from RevenueCat
  Future<Offerings?> getOfferings() async {
    if (!_isInitialized) {
      if (kDebugMode) {
        debugPrint('IapService: Cannot fetch offerings, not initialized.');
      }
      return null;
    }

    try {
      final offerings = await Purchases.getOfferings();
      return offerings;
    } on Exception catch (e, stack) {
      if (kDebugMode) debugPrint('IapService fetchOfferings Error: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Failed to fetch offerings',
      );
      return null;
    }
  }

  /// Attempts to purchase a specific package
  Future<bool> purchasePackage(Package package) async {
    if (!_isInitialized) return false;

    try {
      // ignore: deprecated_member_use
      await Purchases.purchasePackage(package);
      // Determine if successful by checking entitlements or if the purchase went through
      // Since consumable purchases (coins/keys) often don't have active entitlements,
      // we check if the purchase threw an error. If we reach here, it succeeded.
      return true;
    } on Exception catch (e, stack) {
      if (kDebugMode) debugPrint('IapService purchasePackage Error: $e');
      // Ignore user cancellation errors
      if (e.toString().contains('Purchase was cancelled')) {
        return false;
      }
      FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'Purchase failed',
      );
      return false;
    }
  }
}
