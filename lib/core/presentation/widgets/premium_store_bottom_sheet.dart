import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/iap_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/domain/usecases/add_golden_key.dart';

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
  Offerings? _offerings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    final offerings = await di.sl<IapService>().getOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    }
  }

  void _handlePurchase(
    BuildContext context, {
    Package? package,
    String? packName,
    required int coins,
    required int keys,
  }) async {
    if (package != null) {
      CustomSnackBar.show(
        context: context,
        message: 'Processing purchase...',
        type: CustomSnackBarType.info,
      );
      final success = await di.sl<IapService>().purchasePackage(package);
      if (!context.mounted) return;

      if (success) {
        // Grant the items!
        if (coins > 0) {
          context.read<EconomyBloc>().add(
            EconomyAddCoinsRequested(
              coins,
              title:
                  'iap_${packName?.replaceAll(' ', '_').toLowerCase() ?? 'store'}',
            ),
          );
        }
        if (keys > 0) {
          await di.sl<AddGoldenKey>().call(AddGoldenKeyParams(amount: keys));
          if (context.mounted) {
            context.read<AuthBloc>().add(const AuthReloadUser());
          }
        }

        if (context.mounted) {
          CustomSnackBar.show(
            context: context,
            message: 'Purchase successful! Enjoy your items.',
            type: CustomSnackBarType.success,
          );
        }
      } else {
        CustomSnackBar.show(
          context: context,
          message: 'Purchase failed or was cancelled.',
          type: CustomSnackBarType.error,
        );
      }
    } else {
      // Fallback: RevenueCat isn't configured yet — no real IAP package
      // available for this card. Direct the user to the Premium screen
      // (Razorpay-backed) or inform them the coin store is being set up.
      CustomSnackBar.show(
        context: context,
        message: 'Coin packs are being configured. Check back soon!',
        type: CustomSnackBarType.info,
      );
    }
  }

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
                              'PREMIUM STORE',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF8B5CF6),
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              'Stock up on supplies!',
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
                        'COINS & KEYS',
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

                      if (_isLoading)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_offerings?.current != null &&
                          _offerings!.current!.availablePackages.isNotEmpty)
                        ..._offerings!.current!.availablePackages
                            .asMap()
                            .entries
                            .map((entry) {
                              final index = entry.key;
                              final package = entry.value;
                              // RevenueCat packages have a StoreProduct
                              final product = package.storeProduct;
                              final pkgId = package.identifier.toLowerCase();

                              int parsedCoins = 0;
                              int parsedKeys = 0;

                              if (pkgId.contains('starter') ||
                                  pkgId.contains('500') ||
                                  product.title.toLowerCase().contains(
                                    'starter',
                                  )) {
                                parsedCoins = 500;
                              } else if (pkgId.contains('explorer') ||
                                  pkgId.contains('1200') ||
                                  product.title.toLowerCase().contains(
                                    'explorer',
                                  )) {
                                parsedCoins = 1200;
                                parsedKeys = 2;
                              } else if (pkgId.contains('master') ||
                                  pkgId.contains('4000') ||
                                  product.title.toLowerCase().contains(
                                    'master',
                                  )) {
                                parsedCoins = 4000;
                                parsedKeys = 8;
                              }

                              return Padding(
                                padding: EdgeInsets.only(bottom: 16.h),
                                child: _buildPackCard(
                                  context: context,
                                  isDark: isDark,
                                  title: product.title.split('(').first.trim(),
                                  coins: parsedCoins,
                                  keys: parsedKeys,
                                  price: product.priceString,
                                  icon: Icons.shopping_bag_rounded,
                                  color: Colors.amber,
                                  isBestValue:
                                      index ==
                                      _offerings!
                                              .current!
                                              .availablePackages
                                              .length -
                                          1, // Make last one best value
                                  delay: 300 + (index * 100),
                                  package: package,
                                ),
                              );
                            })
                      else ...[
                        // Fallback to placeholder UI if RevenueCat isn't configured yet
                        _buildPackCard(
                          context: context,
                          isDark: isDark,
                          title: 'Starter Pack',
                          coins: 500,
                          keys: 0,
                          price: '₹9',
                          icon: Icons.monetization_on_rounded,
                          color: Colors.amber,
                          isBestValue: false,
                          delay: 300,
                        ),

                        SizedBox(height: 16.h),

                        _buildPackCard(
                          context: context,
                          isDark: isDark,
                          title: 'Explorer Pack',
                          coins: 1200,
                          keys: 2,
                          price: '₹19',
                          icon: Icons.explore_rounded,
                          color: const Color(0xFF3B82F6),
                          isBestValue: false,
                          delay: 400,
                        ),

                        SizedBox(height: 16.h),

                        _buildPackCard(
                          context: context,
                          isDark: isDark,
                          title: 'Master Pack',
                          coins: 4000,
                          keys: 8,
                          price: '₹29',
                          icon: Icons.diamond_rounded,
                          color: const Color(0xFFEC4899),
                          isBestValue: true,
                          delay: 500,
                        ),
                      ],

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
                    'VOWL PREMIUM',
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
                    'Ad-Free & Unlimited',
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
    required String title,
    required int coins,
    required int keys,
    required String price,
    required IconData icon,
    required Color color,
    required bool isBestValue,
    required int delay,
    Package? package,
  }) {
    return ScaleButton(
          onTap: () => _handlePurchase(
            context,
            packName: title,
            package: package,
            coins: coins,
            keys: keys,
          ),
          child: Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isBestValue
                    ? color
                    : (isDark ? Colors.white10 : Colors.black12),
                width: isBestValue ? 2.w : 1.w,
              ),
              boxShadow: [
                if (isBestValue)
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
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
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Center(
                        child: Icon(icon, color: color, size: 32.r),
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
                                '$coins',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700,
                                ),
                              ),
                              if (keys > 0) ...[
                                SizedBox(width: 12.w),
                                Icon(
                                  Icons.key_rounded,
                                  color: Colors.amber.shade700,
                                  size: 14.r,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '$keys',
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
                        color: color,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        price,
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
                if (isBestValue)
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
                                'BEST VALUE',
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
        )
        .animate()
        .fadeIn(delay: delay.ms)
        .moveY(begin: 20, end: 0, curve: Curves.easeOutBack);
  }
}
