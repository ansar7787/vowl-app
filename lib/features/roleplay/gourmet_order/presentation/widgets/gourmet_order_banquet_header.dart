import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Header widget displaying patron order requests and dining instructions.
class GourmetOrderBanquetHeader extends StatelessWidget {
  /// Prompt text describing the patron's request.
  final String prompt;

  /// Custom gameplay instructions or objective text.
  final String? instruction;

  /// Primary theme accent color.
  final Color color;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Creates a [GourmetOrderBanquetHeader] widget.
  const GourmetOrderBanquetHeader({
    super.key,
    required this.prompt,
    this.instruction,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.16), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            key: const Key('gourmet_order_banquet_client_request_row'),
            children: [
              Icon(Icons.room_service_rounded, color: color, size: 16.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  "CUSTOMER ORDER",
                  key: const Key('gourmet_order_banquet_client_request_label'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    color: color,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            prompt,
            key: const Key('gourmet_order_banquet_prompt_text'),
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
          ),
          if (instruction != null) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: color.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: color.withValues(alpha: 0.85),
                    size: 16.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      instruction!,
                      key: const Key('gourmet_order_banquet_instruction_text'),
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : color.withValues(alpha: 0.95),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
