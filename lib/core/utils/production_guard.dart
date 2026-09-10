import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class ProductionGuard {
  static void checkConfiguration() {
    final logger = di.sl<AppLogger>();
    final razorpayKey = dotenv.env['RAZORPAY_KEY_ID'];

    if (kReleaseMode) {
      if (razorpayKey == null || razorpayKey.isEmpty) {
        const msg =
            'CRITICAL: RAZORPAY_KEY_ID is missing or empty in production.';
        logger.error(msg, tag: 'ProductionGuard');
        throw AssertionError(msg);
      }

      final isProductionEnv =
          const String.fromEnvironment('ENV') == 'production';

      if (razorpayKey.startsWith('rzp_test_')) {
        if (isProductionEnv) {
          const msg =
              'CRITICAL: Using a test Razorpay key in production release mode!';
          logger.error(msg, tag: 'ProductionGuard');
          throw AssertionError(msg);
        } else {
          logger.warning(
            'WARNING: Using a test Razorpay key in a release build. This is okay for Razorpay reviewers or staging testing.',
            tag: 'ProductionGuard',
          );
        }
      }

      if (razorpayKey.startsWith('rzp_live_YOUR_')) {
        logger.warning(
          'WARNING: Placeholder Razorpay key detected in production.',
          tag: 'ProductionGuard',
        );
      }
    } else {
      if (razorpayKey != null && razorpayKey.startsWith('rzp_test_')) {
        logger.debug(
          'Using test keys (expected in debug mode).',
          tag: 'ProductionGuard',
        );
      }
    }
  }
}
