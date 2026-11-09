import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_micro_loader.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';

class ReferralClaimDialog extends StatefulWidget {
  final Function(String code) onClaim;
  final bool isLoading;
  final String? errorMessage;
  final String? initialCode;

  const ReferralClaimDialog({
    super.key,
    required this.onClaim,
    this.isLoading = false,
    this.errorMessage,
    this.initialCode,
  });

  @override
  State<ReferralClaimDialog> createState() => _ReferralClaimDialogState();
}

class _ReferralClaimDialogState extends State<ReferralClaimDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final surfaceColor = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.midnightNavy : (tokens?.surface ?? Colors.white));
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);
    final textPrimary = isDark
        ? Colors.white
        : (tokens?.textPrimary ?? const Color(0xFF0F172A));
    final textSecondary = isDark
        ? AppColors.slate400
        : (tokens?.textSecondary ?? const Color(0xFF64748B));

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(color: borderColor, width: 1.0),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(22.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon & Header
              Center(
                child: Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    size: 24.r,
                    color: AppColors.indigo500,
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'Enter Invite Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Enter your friend\'s invite code to unlock 100 Bonus Coins and 1 Day of VIP access.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: textSecondary,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 18.h),

              // Input field
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. VOWL-ALEX892',
                  hintStyle: TextStyle(
                    fontSize: 14.sp,
                    letterSpacing: 0.5,
                    color: isDark
                        ? AppColors.slate600
                        : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: Icon(
                    LucideIcons.tag,
                    size: 16.sp,
                    color: AppColors.indigo500,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF070A12)
                      : const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.indigo500,
                      width: 1.5.w,
                    ),
                  ),
                ),
              ),

              if (widget.errorMessage != null) ...[
                SizedBox(height: 10.h),
                Text(
                  widget.errorMessage!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.rose500,
                  ),
                ),
              ],

              SizedBox(height: 20.h),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ScaleButton(
                      onTap: widget.isLoading
                          ? () {}
                          : () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : AppColors.slate100,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: borderColor),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ScaleButton(
                      onTap: widget.isLoading
                          ? () {}
                          : () {
                              final code = _controller.text.trim();
                              if (code.isNotEmpty) {
                                widget.onClaim(code);
                              }
                            },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        alignment: Alignment.center,
                        child: widget.isLoading
                            ? VowlMicroLoader(size: 16.w, color: Colors.white)
                            : Text(
                                'Claim Reward',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
