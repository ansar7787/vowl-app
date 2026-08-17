import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/usecases/purchase_level_unlock.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/modern_game_dialog.dart';
import 'package:vowl/core/presentation/widgets/key_shop_bottom_sheet.dart';

class KidsTollGateBottomSheet {
  static void show({
    required BuildContext context,
    required int level,
    required String gameType,
    required Color primaryColor,
  }) {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(sheetContext),
          child: GestureDetector(
            onTap: () {}, // Prevent taps on the sheet content from closing it
            child: Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                border: Border.all(color: primaryColor, width: 4.w),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.6),
                    offset: Offset(0, -6.h),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 56.r,
                        color: Colors.amber.shade600,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      context.tr(
                        'games.magic_lock_title',
                        fallback: 'Unlock 3 Magical Levels!',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      context.tr(
                        'games.magic_lock_desc',
                        fallback:
                            'Watch a quick video to unlock the next 3 levels!',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        final user = authState.user;
                        final keys = user?.keys ?? 0;
                        final bool hasKey = keys >= 1;

                        return ScaleButton(
                          onTap: () async {
                            if (!hasKey) {
                              Navigator.pop(sheetContext);
                              // FIX: was `context: context` (BlocBuilder's own,
                              // sheet-scoped context) used right after
                              // Navigator.pop deactivated the sheet it belongs
                              // to. `parentContext` is the stable, outer context.
                              if (!parentContext.mounted) return;
                              KeyShopBottomSheet.show(
                                context: parentContext,
                                isKidsMode: true,
                                primaryColor: primaryColor,
                              );
                              return;
                            }

                            Navigator.pop(sheetContext);
                            final result = await di
                                .sl<PurchaseLevelUnlock>()
                                .call(
                                  PurchaseLevelUnlockParams(
                                    gameType: gameType,
                                    cost: 1, // 1 Key
                                    isKidsMode: true,
                                  ),
                                );

                            if (!parentContext.mounted) return;

                            // FIX: Previously only handled `result.isRight()`.
                            // If the unlock call failed server-side (network
                            // error, insufficient keys race, etc.), the sheet
                            // had already closed and NOTHING told the user.
                            // Now handles both outcomes explicitly with `.fold()`.
                            result.fold(
                              (failure) {
                                showDialog(
                                  context: parentContext,
                                  builder: (ctx) => ModernGameDialog(
                                    title: context.tr(
                                      'store.purchase_failed_title',
                                      fallback: 'UNLOCK FAILED',
                                    ),
                                    description: context.tr(
                                      'store.purchase_failed_desc',
                                      fallback:
                                          'Something went wrong and your key was not spent. Please try again.',
                                    ),
                                    buttonText: context
                                        .tr('common.ok', fallback: 'OK')
                                        .toUpperCase(),
                                    isSuccess: false,
                                    onButtonPressed: () =>
                                        Navigator.of(ctx).pop(),
                                  ),
                                );
                              },
                              (_) {
                                // FIX: Refresh user data so the map immediately
                                // shows the newly unlocked levels without
                                // requiring a manual reload.
                                parentContext.read<AuthBloc>().add(
                                  const AuthReloadUser(),
                                );
                                showDialog(
                                  context: parentContext,
                                  builder: (ctx) => Material(
                                    type: MaterialType.transparency,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ModernGameDialog(
                                          title: 'GATE UNLOCKED!',
                                          description: context.tr(
                                            'games.magic_lock_success',
                                            fallback: '3 Levels Unlocked! ✨',
                                          ),
                                          buttonText: 'AWESOME',
                                          isSuccess: true,
                                          onButtonPressed: () =>
                                              Navigator.of(ctx).pop(),
                                        ),
                                        const Positioned.fill(
                                          child: IgnorePointer(
                                            child: GameConfetti(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              color: hasKey ? Colors.amber : primaryColor,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: hasKey
                                    ? Colors.amber.shade700
                                    : primaryColor.withValues(alpha: 0.8),
                                width: 3.w,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: hasKey
                                      ? Colors.amber.shade700
                                      : primaryColor.withValues(alpha: 0.8),
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  hasKey
                                      ? Icons.lock_open_rounded
                                      : Icons.key_rounded,
                                  color: Colors.white,
                                  size: 20.r,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  hasKey ? "USE 1 KEY TO UNLOCK" : "GET A KEY",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(
                      height: MediaQuery.of(sheetContext).padding.bottom,
                    ),
                    SizedBox(height: 24.h),

                    // Premium Upsell Section
                    ScaleButton(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        if (parentContext.mounted) {
                          parentContext.push(AppRouter.premiumRoute);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.workspace_premium_rounded,
                                color: Colors.amber.shade700,
                                size: 24.r,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr(
                                      'games.premium_upsell_title',
                                      fallback: 'Tired of locks & ads?',
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    context.tr(
                                      'games.premium_upsell_desc',
                                      fallback:
                                          'Get Premium for unlimited levels!',
                                    ),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.grey.shade400,
                              size: 16.r,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


