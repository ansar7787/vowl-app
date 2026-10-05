import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/payment_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:confetti/confetti.dart';
import 'package:vowl/core/utils/subscription_plans_service.dart';
import 'package:vowl/features/premium/domain/entities/subscription_plan.dart';
import 'package:vowl/features/premium/presentation/widgets/widgets.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:vowl/core/services/in_app_purchase_service.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color020617 = Color(0xFF020617);
}

enum PaymentMethod { razorpay, googlePlay }

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _paymentService = di.sl<PaymentService>();
  int _selectedPlanIndexVal = 0;
  bool _isProcessingVal = false;
  bool _paymentCompletedVal = false;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.razorpay;
  bool? _paymentSuccessVal;
  String? _errorMessageVal;
  String? _transactionIdVal;
  Timer? _paymentTimeout;
  Timer? _restoreTimer;
  late ConfettiController _confettiController;

  static const List<SubscriptionPlan> _fallbackPlans = [
    SubscriptionPlan(
      id: 'weekly',
      name: 'Weekly',
      price: 49.0,
      oldPrice: 59.0,
      days: 7,
      tag: '',
      color: '#F43F5E',
      displayOrder: 0,
    ),
    SubscriptionPlan(
      id: 'monthly',
      name: 'Monthly',
      price: 129.0,
      oldPrice: 199.0,
      days: 30,
      tag: 'MOST POPULAR',
      color: '#6366F1',
      displayOrder: 1,
    ),
    SubscriptionPlan(
      id: 'yearly',
      name: 'Yearly',
      price: 999.0,
      oldPrice: 1799.0,
      days: 365,
      tag: 'BEST VALUE',
      color: '#10B981',
      displayOrder: 2,
    ),
  ];

  List<SubscriptionPlan> _activePlansVal = _fallbackPlans;

  /// Triggers a UI rebuild. Uses setState instead of an orphaned ValueNotifier
  /// that nothing in the widget tree was listening to.
  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    if (!InAppPurchaseService.isUserInIndia) {
      _selectedPaymentMethod = PaymentMethod.googlePlay;
    }
    _paymentService.init(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
    _loadDynamicPlans();
  }

  Future<void> _loadDynamicPlans() async {
    try {
      final plans = await di.sl<SubscriptionPlansService>().fetchPlans();
      if (mounted && plans.isNotEmpty) {
        _activePlansVal = plans;
        if (_selectedPlanIndexVal >= _activePlansVal.length) {
          _selectedPlanIndexVal = _activePlansVal.isNotEmpty ? 0 : 0;
        }
        _updateState();
      }
    } catch (e) {
      di.sl<AppLogger>().warning(
        'Failed to load dynamic plans, falling back to local defaults.',
      );
    }
  }

  void _startPaymentTimeout() {
    _paymentTimeout?.cancel();
    // Timeout after 2 minutes if no response
    _paymentTimeout = Timer(const Duration(minutes: 2), () {
      if (mounted && _isProcessingVal) {
        _handlePaymentTimeout();
      }
    });
  }

  void _cancelPaymentTimeout() {
    _paymentTimeout?.cancel();
    _paymentTimeout = null;
  }

  void _handlePaymentTimeout() {
    di.sl<HapticService>().error();
    if (mounted) {
      _isProcessingVal = false;
      _paymentCompletedVal = true;
      _paymentSuccessVal = false;
      _errorMessageVal = context.tr(
        'premium.error_timeout',
        fallback: 'Request timed out',
      );
      _updateState();
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _cancelPaymentTimeout();
    if (!mounted) return;

    try {
      final user = context.read<AuthBloc>().state.user;
      if (user != null) {
        final selectedPlan = _activePlansVal[_selectedPlanIndexVal];
        await _paymentService.upgradeToPremium(
          orderId: response.orderId ?? '',
          paymentId: response.paymentId ?? '',
          signature: response.signature ?? '',
          days: selectedPlan.days,
        );

        if (mounted) {
          // Refresh user state to reflect premium status
          context.read<AuthBloc>().add(const AuthReloadUser());

          di.sl<HapticService>().success();
          _confettiController.play();

          _isProcessingVal = false;
          _paymentCompletedVal = true;
          _paymentSuccessVal = true;
          _transactionIdVal = response.paymentId;
          _errorMessageVal = null;
          _updateState();
        }
      } else {
        _isProcessingVal = false;
        _paymentCompletedVal = true;
        _paymentSuccessVal = false;
        _errorMessageVal = 'Session expired. Please restart the app.';
        _updateState();
      }
    } catch (e, stackTrace) {
      // SECURITY / UX FIX: the original code surfaced `e.toString()`
      // directly to the user (e.g. "Failed to upgrade account:
      // _TypeError: ..."), which can leak internal implementation detail
      // and is confusing/unactionable for a paying customer. The raw
      // error is still logged for diagnostics; the user only ever sees a
      // safe, localized, generic message.
      di.sl<AppLogger>().error(
        'Premium upgrade failed after successful payment',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        di.sl<HapticService>().error();
        _isProcessingVal = false;
        _paymentCompletedVal = true;
        _paymentSuccessVal = false;
        _errorMessageVal = context.tr(
          'premium.error_upgrade_failed',
          fallback: 'Upgrade Failed',
        );
        _updateState();
      }
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    _cancelPaymentTimeout();
    di.sl<HapticService>().error();
    if (mounted) {
      _isProcessingVal = false;
      _paymentCompletedVal = true;
      _paymentSuccessVal = false;
      // Razorpay's `response.message` is already a user-safe,
      // gateway-provided description (not a raw exception), so it is
      // fine to surface directly, with a localized fallback.
      _errorMessageVal =
          response.message ??
          context.tr('premium.error_generic', fallback: 'An error occurred');
      _updateState();
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _cancelPaymentTimeout();
    if (mounted) {
      _isProcessingVal = false;
      _paymentCompletedVal = true;
      _paymentSuccessVal = false;
      _errorMessageVal = context.tr(
        'premium.external_wallet_info',
        fallback:
            'External wallet selected. If payment was completed, your premium will activate shortly.',
      );
      _updateState();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _cancelPaymentTimeout();
    _restoreTimer?.cancel();
    final iap = InAppPurchaseService.instance;
    iap.onPurchaseSuccess = null;
    iap.onPurchaseError = null;
    iap.onPurchaseRestored = null;
    iap.onPurchaseCanceled = null;
    // NOTE: Do NOT call _paymentService.dispose() here.
    // PaymentService is a DI singleton â€” disposing it here would destroy
    // the Razorpay instance for ALL other screens. Each widget's init()
    // already re-creates the Razorpay instance safely.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? _LocalPalette.color020617
        : AppColors.slate50;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(color: backgroundColor),
          child: Stack(
            children: [
              // 2026 Ultra-Premium Mesh Gradient Background
              Positioned(
                top: -150.h,
                right: -100.w,
                child: StaticGlow(
                  color: isDark
                      ? AppColors.indigo500.withValues(alpha: 0.15)
                      : AppColors.indigo500.withValues(alpha: 0.08),
                  radius: 300,
                ),
              ),
              Positioned(
                bottom: -100.h,
                left: -100.w,
                child: StaticGlow(
                  color: isDark
                      ? AppColors.violet500.withValues(alpha: 0.15)
                      : AppColors.violet500.withValues(alpha: 0.08),
                  radius: 250,
                ),
              ),
              Positioned(
                top: 200.h,
                left: -50.w,
                child: StaticGlow(
                  color: isDark
                      ? IllustrationColors.richPurple.withValues(alpha: 0.1)
                      : IllustrationColors.richPurple.withValues(alpha: 0.05),
                  radius: 200,
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        pinned: true,
                        centerTitle: false,
                        leading: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                        ),
                        actions: [
                          Padding(
                            padding: EdgeInsets.only(right: 16.w),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: 0.2),
                                    const Color(
                                      0xFF8B5CF6,
                                    ).withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.workspace_premium_rounded,
                                    color: AppColors.indigo500,
                                    size: 14.r,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    context.tr(
                                      'premium.verified_pro_badge',
                                      fallback: 'Verified Pro',
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildScrollableBody(),
                      ),
                    ],
                  );
                },
              ),
              if (_isProcessingVal) _buildProcessingOverlay(),
              if (_paymentCompletedVal) _buildCompletedOverlay(),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.1,
                  colors: [
                    AppColors.indigo500,
                    AppColors.violet500,
                    IllustrationColors.richPurple,
                    AppColors.indigo500,
                    AppColors.rose500,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// RESPONSIVENESS / OVERFLOW FIX
  ///
  /// The original layout was a non-scrolling `Column` that relied on
  /// `Spacer()` widgets to distribute the gap between the hero, plan list,
  /// feature bar and CTA button. That works only as long as the sum of the
  /// *fixed-size* children (hero text, 3 plan cards, feature bar, CTA
  /// button, secure-transaction label) is shorter than the available
  /// screen height. On a small phone (e.g. 320Ã—568), at larger
  /// accessibility text-scale factors (1.3xâ€“3x), or once strings are
  /// translated into a longer language (German, Indian regional scripts
  /// routinely run 30-50% longer than English), that sum can exceed the
  /// screen height â€” and a `Column` containing `Expanded`/`Spacer`
  /// children cannot be made scrollable without changes, because flexible
  /// children require *bounded* height, which a scroll view's main axis
  /// does not provide. The previous structure would either throw a
  /// "RenderFlex overflowed" error banner or assert on unbounded height,
  /// depending on exactly how it was wrapped.
  ///
  /// Fix: the layout now scrolls when content doesn't fit, and is
  /// perfectly centered (matching the original "stretch to fill" look)
  /// when it does â€” the standard `LayoutBuilder` +
  /// `ConstrainedBox(minHeight: ...)` + `Column(mainAxisSize: min,
  /// mainAxisAlignment: center)` idiom. The `Spacer()`s are replaced with
  /// fixed, screen-aware gaps (kept at roughly the same 1:1:1:2 ratio the
  /// original four `Spacer`/`Spacer(flex: 2)` had), since flexible gaps
  /// cannot be used inside a scrollable's unbounded main axis.
  Widget _buildAlreadyPremiumCard(bool isDark, user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.emerald500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.emerald500.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.checkCircle,
            color: AppColors.emerald500,
            size: 48.r,
          ),
          SizedBox(height: 16.h),
          Text(
            context.tr(
              'premium.already_premium',
              fallback: "You're already a Premium Quester!",
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          if (user.premiumExpiryDate != null) ...[
            SizedBox(height: 8.h),
            Text(
              '${context.tr('premium.valid_until', fallback: 'Valid until:')} ${DateFormat.yMMMd().format(user.premiumExpiryDate!.toLocal())}',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppColors.slate500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScrollableBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthBloc>().state.user;
    final isPremium = user?.isPremium ?? false;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 16.h),
          const PremiumHero(),
          SizedBox(height: 24.h),
          if (isPremium)
            _buildAlreadyPremiumCard(isDark, user)
          else
            _buildPlanList(),
          SizedBox(height: 24.h),
          const ModernFeatureBar(),
          SizedBox(height: 32.h),
          if (!isPremium) ...[
            _buildPaymentMethodSelector(isDark),
            _buildCTAButton(),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: () async {
                di.sl<HapticService>().selection();
                if (InAppPurchaseService.shouldUseIAP) {
                  _isProcessingVal = true;
                  _updateState();

                  final iap = InAppPurchaseService.instance;
                  iap.onPurchaseRestored = () {
                    if (mounted) {
                      context.read<AuthBloc>().add(const AuthReloadUser());
                      _isProcessingVal = false;
                      _updateState();
                      CustomSnackBar.show(
                        context: context,
                        message: context.tr(
                          'premium.restore_success',
                          fallback: 'Purchases restored successfully.',
                        ),
                        type: CustomSnackBarType.success,
                      );
                    }
                  };
                  iap.onPurchaseError = (error) {
                    if (mounted) {
                      _isProcessingVal = false;
                      _updateState();
                      CustomSnackBar.show(
                        context: context,
                        message: error,
                        type: CustomSnackBarType.error,
                      );
                    }
                  };

                  await iap.restorePurchases();

                  // If there are no past purchases, the stream won't emit anything.
                  // We should timeout the loading state just in case.
                  _restoreTimer?.cancel();
                  _restoreTimer = Timer(const Duration(seconds: 5), () {
                    if (mounted && _isProcessingVal) {
                      _isProcessingVal = false;
                      _updateState();
                    }
                  });
                } else {
                  CustomSnackBar.show(
                    context: context,
                    message: context.tr(
                      'premium.restore_not_supported',
                      fallback:
                          'Your premium is linked to your account and restored automatically when you sign in. Contact support if you need help.',
                    ),
                    type: CustomSnackBarType.info,
                  );
                }
              },
              child: Text(
                context.tr(
                  'premium.restore_purchases',
                  fallback: 'Restore Purchases',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : Colors.black54,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          SizedBox(height: 20.h),
          _buildSecureTag(),
          SizedBox(height: 8.h),
          _buildTermsAndPolicy(),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60.r,
                  height: 60.r,
                  child: const VowlButtonSpinner(color: AppColors.amber500),
                ),
                SizedBox(height: 20.h),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    context.tr(
                      'premium.processing_title',
                      fallback: 'Processing...',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  context.tr(
                    'premium.processing_subtitle',
                    fallback: 'Please wait while we confirm your purchase.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                TextButton(
                  onPressed: () {
                    _cancelPaymentTimeout();
                    _isProcessingVal = false;
                    _updateState();
                  },
                  child: Text(
                    context.tr('common.cancel', fallback: 'Cancel'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white60,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: _paymentSuccessVal == true
                ? PremiumSuccessOverlay(
                    transactionId: _transactionIdVal,
                    onBeginAdventure: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                  )
                : PremiumFailureOverlay(
                    errorMessage: _errorMessageVal,
                    onRetry: () {
                      _paymentCompletedVal = false;
                      _paymentSuccessVal = null;
                      _errorMessageVal = null;
                      _transactionIdVal = null;
                      _updateState();
                    },
                    onClose: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanList() {
    return Column(
      children: List.generate(_activePlansVal.length, (index) {
        final plan = _activePlansVal[index];

        // When Google Play is selected, find the matching product price
        String? googlePlayPrice;
        if (_selectedPaymentMethod == PaymentMethod.googlePlay) {
          String productId;
          switch (plan.id) {
            case 'weekly':
              productId = InAppPurchaseService.premiumWeekly;
              break;
            case 'monthly':
              productId = InAppPurchaseService.premiumMonthly;
              break;
            case 'yearly':
              productId = InAppPurchaseService.premiumYearly;
              break;
            default:
              productId = InAppPurchaseService.premiumMonthly;
          }
          final iap = InAppPurchaseService.instance;
          final match = iap.products.where((p) => p.id == productId);
          if (match.isNotEmpty) {
            googlePlayPrice = match.first.price;
          }
        }

        return PremiumPlanCard(
          plan: plan,
          isSelected: _selectedPlanIndexVal == index,
          googlePlayPrice: googlePlayPrice,
          onTap: () {
            di.sl<HapticService>().selection();
            _selectedPlanIndexVal = index;
            _updateState();
          },
        );
      }),
    );
  }

  Widget _buildPaymentMethodSelector(bool isDark) {
    if (!InAppPurchaseService.isUserInIndia) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              context
                  .tr(
                    'premium.select_payment_method',
                    fallback: 'PAYMENT METHOD',
                  )
                  .toUpperCase(),
              style: TextStyle(
                fontFamily: 'Outfit',
                color: isDark ? Colors.white70 : AppColors.slate500,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppColors.slate200,
                width: 1,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.slate200.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              children: [
                _buildPaymentTile(
                  isDark: isDark,
                  method: PaymentMethod.razorpay,
                  title: context.tr(
                    'premium.payment_razorpay',
                    fallback: 'UPI / Credit Card',
                  ),
                  subtitle: context.tr(
                    'premium.payment_razorpay_subtitle',
                    fallback: 'Zero extra platform fees',
                  ),
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppColors.violet500,
                  isFirst: true,
                  isLast: false,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.slate100,
                  indent: 56.w,
                ),
                _buildPaymentTile(
                  isDark: isDark,
                  method: PaymentMethod.googlePlay,
                  title: context.tr(
                    Platform.isIOS
                        ? 'premium.payment_app_store'
                        : 'premium.payment_google_play',
                    fallback: Platform.isIOS
                        ? 'App Store'
                        : 'Google Play Billing',
                  ),
                  subtitle: context.tr(
                    'premium.payment_google_play_subtitle',
                    fallback: 'Includes local taxes & fees',
                  ),
                  icon: Platform.isIOS
                      ? Icons.apple_rounded
                      : Icons.play_arrow_rounded,
                  iconColor: AppColors.emerald500,
                  isFirst: false,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile({
    required bool isDark,
    required PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isFirst,
    required bool isLast,
  }) {
    final isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          di.sl<HapticService>().selection();
          setState(() {
            _selectedPaymentMethod = method;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.indigo500.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? Radius.circular(20.r) : Radius.zero,
            bottom: isLast ? Radius.circular(20.r) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isDark ? Colors.white60 : AppColors.slate500,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: const BoxDecoration(
                  color: AppColors.indigo500,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14.sp,
                ),
              )
            else
              Container(
                width: 22.r,
                height: 22.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white30 : AppColors.slate300,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTAButton() {
    final selectedPlan = _activePlansVal[_selectedPlanIndexVal];

    String priceFormatted;
    if (_selectedPaymentMethod == PaymentMethod.googlePlay) {
      // Use the ACTUAL Google Play price (localized, with correct currency)
      // instead of guessing with a hardcoded 30% markup.
      String productId;
      switch (selectedPlan.id) {
        case 'weekly':
          productId = InAppPurchaseService.premiumWeekly;
          break;
        case 'monthly':
          productId = InAppPurchaseService.premiumMonthly;
          break;
        case 'yearly':
          productId = InAppPurchaseService.premiumYearly;
          break;
        default:
          productId = InAppPurchaseService.premiumMonthly;
      }
      final iap = InAppPurchaseService.instance;
      final matchingProducts = iap.products.where((p) => p.id == productId);
      if (matchingProducts.isNotEmpty) {
        priceFormatted = matchingProducts.first.price;
      } else {
        // Products not loaded yet â€” show Razorpay price as fallback
        priceFormatted = NumberFormat.simpleCurrency(
          locale: Localizations.localeOf(context).toString(),
          name: selectedPlan.currency,
          decimalDigits: 0,
        ).format(selectedPlan.price);
      }
    } else {
      priceFormatted = NumberFormat.simpleCurrency(
        locale: Localizations.localeOf(context).toString(),
        name: selectedPlan.currency,
        decimalDigits: 0,
      ).format(selectedPlan.price);
    }

    final leftText = _isProcessingVal
        ? context.tr('premium.cta_processing', fallback: 'Processing...')
        : context.tr('premium.cta_continue', fallback: 'Continue');

    return Semantics(
      button: true,
      enabled: !_isProcessingVal,
      label: leftText,
      child: ScaleButton(
        onTap: _isProcessingVal ? null : _onActivatePressed,
        child: Container(
          width: double.infinity,
          height: 60.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.indigo500, AppColors.violet500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.indigo500.withValues(alpha: 0.4),
                blurRadius: 25,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_isProcessingVal)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const VowlButtonSpinner(color: Colors.white),
                      SizedBox(width: 12.w),
                      Text(
                        leftText,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    leftText,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                if (!_isProcessingVal)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        priceFormatted,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onActivatePressed() async {
    di.sl<HapticService>().heavy();
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    _restoreTimer?.cancel();

    _isProcessingVal = true;
    _updateState();

    final plan = _activePlansVal[_selectedPlanIndexVal];

    try {
      final hasConnection = await InternetConnection().hasInternetAccess;
      if (!hasConnection) {
        if (!mounted) return;
        di.sl<HapticService>().error();
        _isProcessingVal = false;
        _paymentCompletedVal = true;
        _paymentSuccessVal = false;
        _errorMessageVal = context.tr(
          'premium.no_network',
          fallback:
              'No internet connection. Please check your network and try again.',
        );
        _updateState();
        return;
      }

      if (_selectedPaymentMethod == PaymentMethod.googlePlay) {
        String productId;
        switch (plan.id) {
          case 'weekly':
            productId = InAppPurchaseService.premiumWeekly;
            break;
          case 'monthly':
            productId = InAppPurchaseService.premiumMonthly;
            break;
          case 'yearly':
            productId = InAppPurchaseService.premiumYearly;
            break;
          default:
            productId = InAppPurchaseService.premiumMonthly;
        }

        final iap = InAppPurchaseService.instance;
        try {
          final matchingProducts = iap.products
              .where((p) => p.id == productId)
              .toList();
          if (matchingProducts.isEmpty) {
            // Reset processing and show error
            _isProcessingVal = false;
            _paymentCompletedVal = true;
            _paymentSuccessVal = false;
            _errorMessageVal = 'Product not available. Please try again later.';
            _updateState();
            return;
          }
          final product = matchingProducts.first;
          iap.onPurchaseSuccess = (purchase) async {
            _cancelPaymentTimeout();
            if (!mounted) return;
            try {
              final user = context.read<AuthBloc>().state.user;
              if (user != null) {
                // The InAppPurchaseService._verifyAndDeliver() has already
                // called the validateIAPReceipt Cloud Function which validates
                // the receipt AND grants premium on the server. Now refresh
                // the local user state to reflect the new premium status.
                if (mounted) {
                  context.read<AuthBloc>().add(const AuthReloadUser());
                  di.sl<HapticService>().success();
                  _confettiController.play();
                  _isProcessingVal = false;
                  _paymentCompletedVal = true;
                  _paymentSuccessVal = true;
                  _transactionIdVal = purchase.purchaseID;
                  _errorMessageVal = null;
                  _updateState();
                }
              } else {
                _isProcessingVal = false;
                _paymentCompletedVal = true;
                _paymentSuccessVal = false;
                _errorMessageVal = 'Session expired. Please restart the app.';
                _updateState();
              }
            } catch (e, stackTrace) {
              di.sl<AppLogger>().error(
                'IAP upgrade failed after purchase',
                error: e,
                stackTrace: stackTrace,
              );
              if (mounted) {
                di.sl<HapticService>().error();
                _isProcessingVal = false;
                _paymentCompletedVal = true;
                _paymentSuccessVal = false;
                _errorMessageVal = context.tr(
                  'premium.error_upgrade_failed',
                  fallback: 'Upgrade Failed',
                );
                _updateState();
              }
            }
          };
          iap.onPurchaseError = (error) {
            _cancelPaymentTimeout();
            di.sl<HapticService>().error();
            if (mounted) {
              _isProcessingVal = false;
              _paymentCompletedVal = true;
              _paymentSuccessVal = false;
              _errorMessageVal = error;
              _updateState();
            }
          };
          iap.onPurchaseCanceled = (message) {
            if (!mounted) return;
            _cancelPaymentTimeout();
            _isProcessingVal = false;
            // Just reset to plan selection, no error overlay
            _updateState();
            di.sl<HapticService>().light();
          };
          await iap.buyProduct(product);
          _startPaymentTimeout();
        } catch (e) {
          if (!mounted) return;
          _isProcessingVal = false;
          _paymentCompletedVal = true;
          _paymentSuccessVal = false;
          _errorMessageVal = context.tr(
            'premium.error_checkout_failed',
            fallback: 'Product not found',
          );
          _updateState();
        }
      } else {
        final checkoutOpened = await _paymentService.purchaseSubscription(
          contact: '',
          email: user.email,
          planId: plan.id,
          days: plan.days,
          planName: plan.name,
          currency: plan.currency,
        );

        if (checkoutOpened) {
          _startPaymentTimeout();
        } else {
          // Checkout failed to open (missing key, uninitialized SDK, etc.)
          if (!mounted) return;
          di.sl<HapticService>().error();
          _isProcessingVal = false;
          _paymentCompletedVal = true;
          _paymentSuccessVal = false;
          _errorMessageVal = context.tr(
            'premium.error_checkout_failed',
            fallback: 'Could not open payment. Please try again later.',
          );
          _updateState();
        }
      }
    } catch (e) {
      // Order creation failed (network, server error, etc.)
      if (!mounted) return;
      di.sl<HapticService>().error();
      _isProcessingVal = false;
      _paymentCompletedVal = true;
      _paymentSuccessVal = false;
      _errorMessageVal = context.tr(
        'premium.error_order_failed',
        fallback:
            'Unable to create payment order. Please check your connection and try again.',
      );
      _updateState();
    }
  }

  Widget _buildSecureTag() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      context.tr(
        'premium.secure_transaction_tag',
        fallback: 'Secure Transaction',
      ),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Outfit',
        color: isDark ? const Color(0x3DFFFFFF) : const Color(0x42000000),
        fontSize: 9.sp,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTermsAndPolicy() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white38 : Colors.black38;

    return Column(
      children: [
        Text(
          context.tr(
            'premium.cancellation_note',
            fallback:
                'One-time payment. Access for the selected duration. No recurring charges.',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: muted,
            fontSize: 11.sp,
            height: 1.4,
          ),
        ),
        SizedBox(height: 6.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(4.r),
              onTap: () {
                final url = Uri.parse(
                  'https://vowl-official.github.io/vowl-legal/terms.html',
                );
                launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                child: Text(
                  context.tr('premium.terms', fallback: 'Terms'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: muted,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: muted,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                '•',
                style: TextStyle(color: muted, fontSize: 10.sp),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(4.r),
              onTap: () {
                final url = Uri.parse(
                  'https://vowl-official.github.io/vowl-legal/privacy.html',
                );
                launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                child: Text(
                  context.tr('premium.privacy', fallback: 'Privacy'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: muted,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: muted,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                '•',
                style: TextStyle(color: muted, fontSize: 10.sp),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(4.r),
              onTap: () {
                final url = Uri.parse(
                  'https://vowl-official.github.io/vowl-legal/refund.html',
                );
                launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                child: Text(
                  context.tr(
                    'premium.refund_policy',
                    fallback: 'Refund Policy',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: muted,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

