import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/domain/usecases/add_golden_key.dart';

/// A coin/key pack available for purchase in the Premium Store.
///
/// Prices are in INR. Razorpay converts to paise internally.
class _CoinPack {
  final String id;
  final String titleKey;
  final String titleFallback;
  final int coins;
  final int keys;
  final double price; // INR
  final IconData icon;
  final Color color;
  final bool isBestValue;

  const _CoinPack({
    required this.id,
    required this.titleKey,
    required this.titleFallback,
    required this.coins,
    required this.keys,
    required this.price,
    required this.icon,
    required this.color,
    this.isBestValue = false,
  });

  String get priceString => '₹${price.toInt()}';
}

class PremiumStoreBottomSheet extends StatefulWidget {
  final bool isKidsMode;

  const PremiumStoreBottomSheet({super.key, this.isKidsMode = false});

  static Future<void> show({
    required BuildContext context,
    bool isKidsMode = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PremiumStoreBottomSheet(isKidsMode: isKidsMode),
    );
  }

  @override
  State<PremiumStoreBottomSheet> createState() =>
      _PremiumStoreBottomSheetState();
}

class _PremiumStoreBottomSheetState extends State<PremiumStoreBottomSheet> {
  Razorpay? _razorpay;
  bool _isProcessing = false;

  // The pack that is currently being purchased — set before opening checkout
  // so the success handler knows what coins/keys to grant.
  _CoinPack? _pendingPack;

  static const List<_CoinPack> _packs = [
    _CoinPack(
      id: 'starter_pack',
      titleKey: 'store.starter_pack',
      titleFallback: 'Starter Pack',
      coins: 500,
      keys: 0,
      price: 9,
      icon: Icons.monetization_on_rounded,
      color: Colors.amber,
    ),
    _CoinPack(
      id: 'explorer_pack',
      titleKey: 'store.explorer_pack',
      titleFallback: 'Explorer Pack',
      coins: 1200,
      keys: 2,
      price: 19,
      icon: Icons.explore_rounded,
      color: Color(0xFF3B82F6),
    ),
    _CoinPack(
      id: 'master_pack',
      titleKey: 'store.master_pack',
      titleFallback: 'Master Pack',
      coins: 4000,
      keys: 8,
      price: 29,
      icon: Icons.diamond_rounded,
      color: Color(0xFFEC4899),
      isBestValue: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentFailure);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    super.dispose();
  }

  // ─── Payment Handlers ──────────────────────────────────────────────────────

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final pack = _pendingPack;
    if (pack == null || !mounted) return;

    di.sl<HapticService>().success();

    // Grant coins
    if (pack.coins > 0 && mounted) {
      context.read<EconomyBloc>().add(
        EconomyAddCoinsRequested(
          pack.coins,
          title: 'iap_${pack.id}',
        ),
      );
    }

    // Grant keys
    if (pack.keys > 0) {
      await di.sl<AddGoldenKey>().call(AddGoldenKeyParams(amount: pack.keys));
      if (mounted) {
        context.read<AuthBloc>().add(const AuthReloadUser());
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'store.purchase_success',
          fallback: 'Purchase successful! Enjoy your items.',
        ),
        type: CustomSnackBarType.success,
      );
    }

    _pendingPack = null;
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    di.sl<HapticService>().error();
    _pendingPack = null;
    if (mounted) {
      setState(() => _isProcessing = false);
      // Don't show error for user cancellations
      if (response.code != Razorpay.PAYMENT_CANCELLED) {
        CustomSnackBar.show(
          context: context,
          message: response.message ??
              context.tr(
                'store.purchase_failed',
                fallback: 'Purchase failed. Please try again.',
              ),
          type: CustomSnackBarType.error,
        );
      }
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _pendingPack = null;
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  // ─── Purchase Flow ─────────────────────────────────────────────────────────

  void _onPackTap(_CoinPack pack) {
    if (_isProcessing) return;

    final razorpayKey = dotenv.env['RAZORPAY_KEY_ID'];
    if (razorpayKey == null || razorpayKey.isEmpty) {
      di.sl<AppLogger>().error('PremiumStore: Razorpay key not configured');
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'store.payment_not_configured',
          fallback: 'Payment system is being set up. Please try again later.',
        ),
        type: CustomSnackBarType.error,
      );
      return;
    }

    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    di.sl<HapticService>().selection();

    setState(() => _isProcessing = true);
    _pendingPack = pack;

    final amountInPaise = (pack.price * 100).round();
    final packTitle = context.tr(pack.titleKey, fallback: pack.titleFallback);

    final options = {
      'key': razorpayKey,
      'amount': amountInPaise,
      'name': 'Vowl',
      'description': 'Vowl Store - $packTitle',
      'prefill': {
        if (user.email.isNotEmpty) 'email': user.email,
      },
    };

    try {
      _razorpay?.open(options);
    } catch (e) {
      di.sl<AppLogger>().error('PremiumStore: Failed to open checkout', error: e);
      setState(() => _isProcessing = false);
      _pendingPack = null;
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'store.checkout_error',
          fallback: 'Could not open payment. Please try again.',
        ),
        type: CustomSnackBarType.error,
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 12.h, bottom: 20.h),
                    width: 48.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 28.r,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(
                                'store.premium_store_label',
                                fallback: 'PREMIUM STORE',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF8B5CF6),
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              context.tr(
                                'store.stock_up',
                                fallback: 'Stock up on supplies!',
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ScaleButton(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white70 : Colors.black54,
                            size: 20.r,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Content
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Vowl Premium Subscription Upsell
                      _buildPremiumUpsell(context, isDark)
                          .animate()
                          .fadeIn()
                          .moveX(begin: -20, end: 0, delay: 100.ms),

                      SizedBox(height: 32.h),

                      Text(
                        context.tr(
                          'store.coins_and_keys_label',
                          fallback: 'COINS & KEYS',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          letterSpacing: 1.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      SizedBox(height: 16.h),

                      // Real coin packs
                      ...List.generate(_packs.length, (index) {
                        final pack = _packs[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: _buildPackCard(
                            context: context,
                            isDark: isDark,
                            pack: pack,
                            delay: 300 + (index * 100),
                          ),
                        );
                      }),

                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .moveY(begin: 40, end: 0, curve: Curves.easeOutBack);
  }

  Widget _buildPremiumUpsell(BuildContext context, bool isDark) {
    return ScaleButton(
      onTap: () {
        Navigator.pop(context);
        context.push(AppRouter.premiumRoute);
      },
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56.r,
              height: 56.r,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 32.r,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      'store.vowl_premium_label',
                      fallback: 'VOWL PREMIUM',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    context.tr(
                      'store.ad_free_unlimited',
                      fallback: 'Ad-Free & Unlimited',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackCard({
    required BuildContext context,
    required bool isDark,
    required _CoinPack pack,
    required int delay,
  }) {
    final title = context.tr(pack.titleKey, fallback: pack.titleFallback);

    return ScaleButton(
          onTap: _isProcessing ? null : () => _onPackTap(pack),
          child: AnimatedOpacity(
            opacity: _isProcessing ? 0.6 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: pack.isBestValue
                      ? pack.color
                      : (isDark ? Colors.white10 : Colors.black12),
                  width: pack.isBestValue ? 2.w : 1.w,
                ),
                boxShadow: [
                  if (pack.isBestValue)
                    BoxShadow(
                      color: pack.color.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      // Icon Box
                      Container(
                        width: 60.r,
                        height: 60.r,
                        decoration: BoxDecoration(
                          color: pack.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Center(
                          child: Icon(pack.icon, color: pack.color, size: 32.r),
                        ),
                      ),
                      SizedBox(width: 16.w),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.monetization_on_rounded,
                                  color: Colors.amber,
                                  size: 14.r,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${pack.coins}',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                                  ),
                                ),
                                if (pack.keys > 0) ...[
                                  SizedBox(width: 12.w),
                                  Icon(
                                    Icons.key_rounded,
                                    color: Colors.amber.shade700,
                                    size: 14.r,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '${pack.keys}',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Price Button
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: pack.color,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          pack.priceString,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Best Value Badge
                  if (pack.isBestValue)
                    Positioned(
                      top: -30.h,
                      right: 10.w,
                      child:
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(8.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  color: Colors.white,
                                  size: 12.r,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  context.tr(
                                    'store.best_value',
                                    fallback: 'BEST VALUE',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().scale(
                            delay: (delay + 300).ms,
                            curve: Curves.elasticOut,
                          ),
                    ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: delay.ms)
        .moveY(begin: 20, end: 0, curve: Curves.easeOutBack);
  }
}
