import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';

/// Manages the monetization flow for ML Kit Translations.
/// 
/// Intercepts a user's request to translate text (hint, explanation, etc.).
/// - If the user is Premium: Translates instantly for free.
/// - If the user is Free: Shows an upsell dialog to watch a Rewarded Ad or upgrade.
///   - On Ad Success: Translates the text.
class TranslationMonetizationController {
  
  /// Attempts to perform a translation action.
  /// 
  /// [onSuccess] is called if the user is Premium, or if they successfully watch an ad.
  static Future<void> attemptTranslation(
    BuildContext context, {
    required VoidCallback onSuccess,
    bool isKidsZone = false,
  }) async {
    final authState = context.read<AuthBloc>().state;
    final isPremium = authState.user?.isPremium ?? false;

    if (isPremium) {
      onSuccess();
      return;
    }

    // Show Free User Dialog (Watch Ad or Upgrade)
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          ctx.tr('translation.premium_upsell', fallback: 'Hate ads? Get Premium to translate instantly for free!'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          ctx.tr('translation.translate_cta', fallback: 'Watch an ad to translate'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('common.cancel', fallback: 'CANCEL')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_fill, size: 18),
                SizedBox(width: 4),
                Text("Watch Ad"),
              ],
            ),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      // User chose to watch ad
      final adService = di.sl<AdService>();
      
      adService.showRewardedAd(
        context: context,
        isPremium: isPremium, // We know it's false here
        childSafe: isKidsZone,
        onUserEarnedReward: (RewardItem item) {
          // Ad watched successfully
          if (context.mounted) {
            onSuccess();
          }
        },
        onDismissed: () {
          // If they dismissed the ad early, onUserEarnedReward won't fire.
        },
      );
    }
  }
}
