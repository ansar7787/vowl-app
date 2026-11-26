import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_ui_tokens.dart';

/// Compact informational pill for review origin or Learn-gate guidance.
class SynonymLearnStatusBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const SynonymLearnStatusBanner({
    super.key,
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.slate50 : color;
    return Container(
      width: double.infinity,
      padding: SynonymUiTokens.innerPanelPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(SynonymUiTokens.controlRadius),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: fg),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: SynonymUiTokens.badgeLabel(
                color: SynonymUiTokens.primaryText(isDark),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
