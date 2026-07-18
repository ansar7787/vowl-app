import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Shared confirmation dialog for spending Vowl Coins on hints.
///
/// REFACTOR NOTE: this widget replaces two near-identical ~90-line private
/// methods, `_purchaseHint` + `_showSuccessSnackbar`, that were copy-pasted
/// between `adventure_level_screen.dart` and `quest_coins_screen.dart`
/// (duplicate code flagged under the Code Cleanliness / Shared Component
/// Strategy review). The two originals differed only in their title/body
/// copy and in some incidental button styling (one had button padding,
/// shape and entrance animation, the other didn't) - those differences are
/// now parameters, and the small styling gaps were closed by adopting the
/// more complete of the two original treatments for both call sites.
///
/// Suggested location if your project structure differs from this
/// assumption: `lib/core/presentation/widgets/hint_purchase_dialog.dart`
/// (promoted to `core` since 2+ features now use it).
class HintPurchaseDialog {
  const HintPurchaseDialog._();

  /// Shows the insufficient-funds toast and returns `false`, or shows the
  /// confirmation dialog and returns `true`. [onConfirm] is invoked (after
  /// the dialog is dismissed) only if the user confirms; it is the
  /// caller's responsibility to dispatch the relevant Bloc event there,
  /// since that differs per screen.
  static void show({
    required BuildContext context,
    required UserEntity user,
    required int cost,
    required int amount,
    required String Function(int amount) titleBuilder,
    required String Function(int cost, int amount) bodyBuilder,
    required VoidCallback onConfirm,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user.coins < cost) {
      di.sl<HapticService>().light();
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'economy.insufficient_coins',
          fallback: 'Not enough coins',
          args: ['$cost'],
        ),
        type: CustomSnackBarType.error,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          child: GlassTile(
            borderRadius: BorderRadius.circular(32.r),
            padding: EdgeInsets.all(24.r),
            borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lightbulb_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 40.r,
                  ),
                ).animate().scale(delay: 100.ms).fadeIn(),
                SizedBox(height: 16.h),
                Text(
                  titleBuilder(amount),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  bodyBuilder(cost, amount),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                        ),
                        child: Text(
                          context
                              .tr('common.cancel', fallback: 'Cancel')
                              .toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onConfirm();
                        },
                        child: Text(
                          context
                              .tr('common.confirm', fallback: 'Confirm')
                              .toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
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
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
    );
  }

  /// The "+N hints" confirmation toast shown after a successful purchase.
  /// Both original call sites used byte-identical copy for this.
  static void showSuccessSnackbar(BuildContext context, int amount) {
    CustomSnackBar.show(
      context: context,
      message: context.tr(
        'economy.inventory_updated_hints',
        fallback: 'Hints added to your inventory!',
        args: ['$amount'],
      ),
      type: CustomSnackBarType.success,
    );
  }
}
