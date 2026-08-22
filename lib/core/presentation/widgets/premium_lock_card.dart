import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/premium_upsell_content.dart';

class PremiumLockCard extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onPremiumTap;

  const PremiumLockCard({super.key, required this.onTap, required this.onPremiumTap});

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      borderColor: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
      borderWidth: 2,
      child: PremiumUpsellContent(
        titleKey: 'translation.limit_reached',
        titleFallback: 'Translation Limit Reached',
        subtitleKey: 'translation.translate_cta',
        subtitleFallback: 'Watch a quick ad to get 3 more translations, or get Premium for unlimited access.',
        adButtonTextKey: 'translation.watch_ad_button',
        adButtonTextFallback: 'Watch Ad (3 Translations)',
        onPremiumTap: onPremiumTap,
        onAdTap: onTap,
      ),
    );
  }
}
