import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/usecases/purchase_level_unlock.dart';
import 'package:vowl/core/presentation/widgets/game_confetti.dart';
import 'package:vowl/core/presentation/widgets/modern_game_dialog.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/key_shop_bottom_sheet.dart';

class TollGateBottomSheet {
  static void show({
    required BuildContext context,
    required int level,
    required String gameType,
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
                border: Border(
                  top: BorderSide(
                    color: Colors.amber.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        margin: EdgeInsets.only(bottom: 16.h),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 56.r,
                        color: Colors.amber.shade600,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .shake(hz: 2, curve: Curves.easeInOutSine, duration: 1500.ms)
                        .then(delay: 2000.ms),
                    SizedBox(height: 16.h),
                    Text(
                      context.tr(
                        'games.unlock_level_title',
                        fallback: 'Unlock Next 3 Levels!',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      context.tr(
                        'store.toll_need_key_desc',
                        fallback:
                            'You need 1 Golden Key to unlock the next 3 levels.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
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
                              // BUG FIX (STALE CONTEXT): was `context: context`
                              // (this BlocBuilder's own, sheet-scoped context) -
                              // happened to work only because it ran
                              // synchronously right after Navigator.pop with no
                              // `await` in between (Element deactivation is
                              // deferred to the next frame). `parentContext` is
                              // what the async branch below already correctly
                              // uses for the same "sheet just closed, need a
                              // still-valid anchor" situation - using it here too
                              // removes a latent fragility rather than relying
                              // on that timing coincidence.
                              KeyShopBottomSheet.show(
                                context: parentContext,
                                isKidsMode: false,
                                primaryColor: Colors.amber,
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
                                    isKidsMode: false,
                                  ),
                                );

                            if (!parentContext.mounted) return;

                            // BUG FIX (SILENT FAILURE): same missing-error-path
                            // issue found and fixed in key_shop_bottom_sheet.dart
                            // and star_vault_bottom_sheet.dart - only the success
                            // branch was handled here. If the unlock call failed
                            // server-side, the user's key had already been
                            // deducted from their local intent with zero
                            // feedback that anything went wrong.
                            result.fold(
                              (failure) {
                                showDialog(
                                  context: parentContext,
                                  builder: (ctx) => ModernGameDialog(
                                    title: context.tr(
                                      'store.purchase_failed_title',
                                      fallback: 'PURCHASE FAILED',
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
                                // FIX: Refresh user data so the map
                                // immediately shows newly unlocked levels.
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
                                          title: context.tr(
                                            'store.gate_unlocked_title',
                                            fallback: 'GATE UNLOCKED!',
                                          ),
                                          description: context.tr(
                                            'games.level_unlocked_success',
                                            fallback: 'Next 3 Levels Unlocked!',
                                          ),
                                          buttonText: context.tr(
                                            'store.awesome',
                                            fallback: 'AWESOME',
                                          ),
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
                              gradient: LinearGradient(
                                colors: hasKey
                                    ? [
                                        Colors.amber.shade400,
                                        Colors.amber.shade600,
                                      ]
                                    : [
                                        Colors.indigo.shade400,
                                        Colors.indigo.shade600,
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                if (hasKey)
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.3),
                                    blurRadius: 10.r,
                                    offset: Offset(0, 4.h),
                                  )
                                else
                                  BoxShadow(
                                    color: Colors.indigo.withValues(alpha: 0.3),
                                    blurRadius: 10.r,
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
                                  hasKey
                                      ? context.tr(
                                          'store.use_key_to_unlock',
                                          fallback: 'USE 1 KEY TO UNLOCK',
                                        )
                                      : context.tr(
                                          'store.get_a_key',
                                          fallback: 'GET A KEY',
                                        ),
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
                    SizedBox(height: 24.h),

                    // Premium Upsell Section
                    ScaleButton(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        // FIX: was `context.push(...)` (BlocBuilder's own
                        // context) — that context is invalidated the moment
                        // Navigator.pop deactivates the sheet widget tree.
                        // `parentContext` is the stable, outer context that
                        // survives the sheet dismissal.
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
