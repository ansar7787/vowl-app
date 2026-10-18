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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color020617 = Color(0xFF020617);
}

class _IndiaPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length > 10) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length > 10) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
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
  bool _showExtendPlans = false;
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
    // REAL-WORLD OPTIMIZATION:
    // When a user is already an active Premium member, their plans are not displayed
    // (they see the VIP Member Pass). Skip the network fetch upfront to eliminate
    // latency, reduce Firestore reads, and make the screen open instantaneously.
    // Plans will be lazily loaded only if the user explicitly taps "Extend Membership".
    final user = context.read<AuthBloc>().state.user;
    if (user?.isPremium == true && !_showExtendPlans) {
      return;
    }

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
        fallback: 'Payment request timed out. Please try again.',
      );
      _updateState();
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _cancelPaymentTimeout();
    if (!mounted) return;

    final user = context.read<AuthBloc>().state.user;
    if (user == null) {
      if (mounted) {
        _isProcessingVal = false;
        _paymentCompletedVal = true;
        _paymentSuccessVal = false;
        _errorMessageVal = 'Session expired. Please restart the app.';
        _updateState();
      }
      return;
    }

    void triggerCelebration() {
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthReloadUser());
      di.sl<HapticService>().success();
      _confettiController.play();

      _showExtendPlans = false;
      _isProcessingVal = false;
      _paymentCompletedVal = true;
      _paymentSuccessVal = true;
      _transactionIdVal = response.paymentId;
      _errorMessageVal = null;
      _updateState();
    }

    try {
      final selectedPlan = _activePlansVal[_selectedPlanIndexVal];
      await _paymentService.upgradeToPremium(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
        days: selectedPlan.days,
      );

      if (mounted) {
        triggerCelebration();
      }
    } catch (e, stackTrace) {
      di.sl<AppLogger>().error(
        'Initial upgrade call encountered error, starting resilient verification',
        error: e,
        stackTrace: stackTrace,
      );

      // PRODUCTION RESILIENCE:
      // The gateway already confirmed payment success. An exception at this stage
      // often means Firestore updated the user doc, but the function returned 500
      // during response serialization (e.g., scoping bug), or mobile network dropped.
      // NEVER show "Payment failed - retry card" without checking Firestore state first!
      if (mounted) {
        context.read<AuthBloc>().add(const AuthReloadUser());
      }
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      if (context.read<AuthBloc>().state.user?.isPremium == true) {
        di.sl<AppLogger>().debug(
          'User already has active premium status in Firestore. Displaying success overlay.',
        );
        triggerCelebration();
        return;
      }

      // Retry verification once with backoff (backend endpoint is idempotent)
      try {
        final selectedPlan = _activePlansVal[_selectedPlanIndexVal];
        await _paymentService.upgradeToPremium(
          orderId: response.orderId ?? '',
          paymentId: response.paymentId ?? '',
          signature: response.signature ?? '',
          days: selectedPlan.days,
        );
        if (mounted) {
          triggerCelebration();
          return;
        }
      } catch (retryError) {
        di.sl<AppLogger>().error(
          'Payment upgrade retry also failed',
          error: retryError,
        );
      }

      // Final state check
      if (mounted) {
        context.read<AuthBloc>().add(const AuthReloadUser());
      }
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      if (context.read<AuthBloc>().state.user?.isPremium == true) {
        triggerCelebration();
        return;
      }

      // Reassuring pending status notice — money was debited, never prompt user to retry card!
      di.sl<HapticService>().error();
      _isProcessingVal = false;
      _paymentCompletedVal = true;
      _paymentSuccessVal = false;
      _transactionIdVal = response.paymentId;
      _errorMessageVal = context.tr(
        'premium.payment_verifying_notice',
        fallback: 'Payment received (Ref: ${response.paymentId}). Your transaction was confirmed by your bank, but server synchronization is delayed. Your Pro access will activate shortly. Please do not pay again.',
      );
      _updateState();
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    _cancelPaymentTimeout();
    if (!mounted) return;

    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      // User cancelled checkout / swiped back -- not a failure!
      di.sl<HapticService>().light();
      _isProcessingVal = false;
      _paymentCompletedVal = false;
      _paymentSuccessVal = null;
      _errorMessageVal = null;
      _updateState();
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'premium.payment_cancelled',
          fallback: 'Payment cancelled.',
        ),
        type: CustomSnackBarType.info,
      );
      return;
    }

    di.sl<HapticService>().error();
    _isProcessingVal = false;
    _paymentCompletedVal = true;
    _paymentSuccessVal = false;
    // Razorpay's `response.message` is already a user-safe,
    // gateway-provided description (not a raw exception), so it is
    // fine to surface directly, with a localized fallback.
    _errorMessageVal =
        response.message ??
        context.tr('premium.error_generic', fallback: 'Payment failed. Please try again.');
    _updateState();
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
    // PaymentService is a DI singleton -- disposing it here would destroy
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
      child: PopScope(
        canPop: !_isProcessingVal && !_paymentCompletedVal,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_isProcessingVal) {
            _cancelPaymentTimeout();
            _isProcessingVal = false;
            _updateState();
            return;
          }
          if (_paymentCompletedVal) {
            if (_paymentSuccessVal == true) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            } else {
              _paymentCompletedVal = false;
              _paymentSuccessVal = null;
              _errorMessageVal = null;
              _transactionIdVal = null;
              _updateState();
            }
            return;
          }
        },
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
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
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
                                      fallback: 'VERIFIED PRO',
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
                    AppColors.emerald500,
                    AppColors.emerald400,
                    AppColors.amber500,
                    AppColors.indigo500,
                    AppColors.violet500,
                  ],
                ),
              ),
            ],
          ),
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
  /// screen height. On a small phone (e.g. 320×568), at larger
  /// accessibility text-scale factors (1.3x–3x), or once strings are
  /// translated into a longer language (German, Indian regional scripts
  /// routinely run 30-50% longer than English), that sum can exceed the
  /// screen height — and a `Column` containing `Expanded`/`Spacer`
  /// children cannot be made scrollable without changes, because flexible
  /// children require *bounded* height, which a scroll view's main axis
  /// does not provide. The previous structure would either throw a
  /// "RenderFlex overflowed" error banner or assert on unbounded height,
  /// depending on exactly how it was wrapped.
  ///
  /// Fix: the layout now scrolls when content doesn't fit, and is
  /// perfectly centered (matching the original "stretch to fill" look)
  /// when it does — the standard `LayoutBuilder` +
  /// `ConstrainedBox(minHeight: ...)` + `Column(mainAxisSize: min,
  /// mainAxisAlignment: center)` idiom. The `Spacer()`s are replaced with
  /// fixed, screen-aware gaps (kept at roughly the same 1:1:1:2 ratio the
  /// original four `Spacer`/`Spacer(flex: 2)` had), since flexible gaps
  /// cannot be used inside a scrollable's unbounded main axis.
  Widget _buildAlreadyPremiumCard(bool isDark, user) {
    final DateTime? expiryDate = user?.premiumExpiryDate;
    final int daysLeft = expiryDate != null
        ? ((expiryDate.difference(DateTime.now()).inHours) / 24).ceil()
        : 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28.r),
        gradient: isDark
            ? const LinearGradient(
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E1B4B),
                  Color(0xFF0A0F1D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [
                  Colors.white,
                  Color(0xFFF8FAFC),
                  Color(0xFFEEF2FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(
          color: AppColors.indigo500.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo500.withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: isDark
                ? Colors.black45
                : AppColors.slate200.withValues(alpha: 0.6),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(22.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Metallic Badge & Active Pulsing Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: AppColors.emerald500.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.checkCircle,
                        color: AppColors.emerald500,
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        'VOWL PRO VIP PASS',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                          color: isDark ? Colors.white70 : AppColors.slate700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.emerald500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.emerald500.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7.r,
                      height: 7.r,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.emerald400,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald400,
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: AppColors.emerald500,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Member Profile Spotlight
          Row(
            children: [
              Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.indigo500, AppColors.violet500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo500.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.crown,
                    color: Colors.white,
                    size: 26.r,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        'premium.already_premium',
                        fallback: "You're already a Premium Quester!",
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      user?.displayName ?? 'Valued VIP Quester',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 18.h),

          // Expiry & Countdown Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.amber500.withValues(alpha: 0.12),
                  AppColors.violet500.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.amber500.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.sparkles,
                  color: AppColors.amber400,
                  size: 20.r,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expiryDate != null && daysLeft > 1
                            ? '$daysLeft Days of Unlimited Superpowers'
                            : (expiryDate != null && daysLeft == 1
                                ? '1 Day of Unlimited Superpowers'
                                : (expiryDate != null &&
                                        expiryDate.isAfter(DateTime.now())
                                    ? 'Expiring Today · Unlimited Superpowers'
                                    : 'Active VIP Membership')),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                      if (expiryDate != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          '${context.tr('premium.valid_until', fallback: 'Valid until:')} ${DateFormat.yMMMd().format(expiryDate.toLocal())}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : AppColors.slate500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Primary CTA: Start Questing / Back to Learning
          Semantics(
            button: true,
            label: context.tr(
              'premium.start_questing',
              fallback: 'Start Questing',
            ),
            child: ScaleButton(
              onTap: () {
                di.sl<HapticService>().selection();
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.indigo500, AppColors.violet500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo500.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.compass,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      context.tr(
                        'premium.start_questing',
                        fallback: 'Start Questing',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 10.h),

          // Secondary CTA: Extend Membership
          Semantics(
            button: true,
            label: _showExtendPlans
                ? context.tr('premium.hide_plans', fallback: 'Hide Plans')
                : context.tr(
                    'premium.extend_membership',
                    fallback: 'Extend Membership',
                  ),
            child: ScaleButton(
              onTap: () {
                di.sl<HapticService>().selection();
                setState(() {
                  _showExtendPlans = !_showExtendPlans;
                });
                if (_showExtendPlans) {
                  _loadDynamicPlans();
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.slate100,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : AppColors.slate300,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.calendarPlus,
                      color: isDark ? Colors.white70 : AppColors.slate700,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _showExtendPlans
                          ? context.tr(
                              'premium.hide_plans',
                              fallback: 'Hide Plans',
                            )
                          : context.tr(
                              'premium.extend_membership',
                              fallback: 'Extend Membership',
                            ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppColors.slate800,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      _showExtendPlans
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      color: isDark ? Colors.white70 : AppColors.slate600,
                      size: 16.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
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
          if (isPremium) ...[
            _buildAlreadyPremiumCard(isDark, user),
            if (_showExtendPlans) ...[
              SizedBox(height: 24.h),
              _buildPlanList(),
              SizedBox(height: 24.h),
              _buildPaymentMethodSelector(isDark),
              _buildCTAButton(),
            ],
          ] else ...[
            _buildPlanList(),
          ],
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
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
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
                      fallback: 'Processing Payment...',
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
                    fallback: 'Setting up your payment session. Please wait...',
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
                    context.tr('common.cancel', fallback: 'CANCEL'),
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
      );
  }

  Widget _buildCompletedOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
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
                    context.read<AuthBloc>().add(const AuthReloadUser());
                    final user = context.read<AuthBloc>().state.user;
                    if (user?.isPremium == true) {
                      _paymentSuccessVal = true;
                      _errorMessageVal = null;
                      _updateState();
                      return;
                    }
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
        // Products not loaded yet — show Razorpay price as fallback
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
        ? context.tr('premium.cta_processing', fallback: 'PROCESSING...')
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
      final internetConnection = di.sl.isRegistered<InternetConnection>()
          ? di.sl<InternetConnection>()
          : InternetConnection();
      final hasConnection = await internetConnection.hasInternetAccess;
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
                  fallback: 'We couldn\'t activate your Pro access. Please contact support with your transaction ID.',
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
            'premium.error_product_not_found',
            fallback: 'Product not found',
          );
          _updateState();
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        String contact = prefs.getString('user_payment_contact') ?? '';
        if (contact.isEmpty) {
          try {
            contact = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
          } catch (_) {
            // Firebase not initialized in tests or no user phone available
          }
        }

        if (contact.isEmpty && mounted) {
          _isProcessingVal = false;
          _updateState();

          final enteredPhone = await _showContactBottomSheet(context);
          if (enteredPhone == null) {
            // User cancelled out of the phone prompt
            return;
          }
          contact = enteredPhone;
          if (contact.isNotEmpty) {
            await prefs.setString('user_payment_contact', contact);
          }

          if (!mounted) return;
          _isProcessingVal = true;
          _updateState();
        }

        final checkoutOpened = await _paymentService.purchaseSubscription(
          contact: contact,
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

  Future<String?> _showContactBottomSheet(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _ContactPhoneBottomSheet(),
    );
  }

  Widget _buildSecureTag() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      context.tr(
        'premium.secure_transaction_tag',
        fallback: '100% SECURE CHECKOUT • NO AUTO-RENEWAL',
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
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
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
              padding: EdgeInsets.symmetric(horizontal: 4.w),
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
              padding: EdgeInsets.symmetric(horizontal: 4.w),
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

class _ContactPhoneBottomSheet extends StatefulWidget {
  const _ContactPhoneBottomSheet();

  @override
  State<_ContactPhoneBottomSheet> createState() =>
      _ContactPhoneBottomSheetState();
}

class _ContactPhoneBottomSheetState extends State<_ContactPhoneBottomSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isValid = _controller.text.trim().length == 10;

    return Container(
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.slate200,
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : AppColors.slate300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_android_rounded,
                      color: AppColors.indigo500,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            'premium.contact_prompt_title',
                            fallback: 'UPI & Payment Mobile Number',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          context.tr(
                            'premium.contact_prompt_subtitle',
                            fallback:
                                'Razorpay requires your phone number for UPI routing and receipts.',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            color: isDark ? Colors.white60 : AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofocus: true,
                cursorColor: AppColors.indigo500,
                cursorWidth: 2.2,
                cursorRadius: Radius.circular(2.r),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _IndiaPhoneInputFormatter(),
                ],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (isValid) {
                    Navigator.of(context).pop(_controller.text.trim());
                  }
                },
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.slate900,
                  letterSpacing: 1.0,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.slate100,
                  prefixIcon: Icon(
                    Icons.phone_android_rounded,
                    color: isValid
                        ? AppColors.indigo500
                        : (isDark ? Colors.white38 : AppColors.slate400),
                    size: 20.sp,
                  ),
                  prefixText: '+91  ',
                  prefixStyle: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.slate900,
                    letterSpacing: 0.5,
                  ),
                  hintText: 'Enter 10-digit number',
                  hintStyle: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white30 : AppColors.slate400,
                    letterSpacing: 0.2,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.cancel_rounded,
                            size: 18.sp,
                            color: isDark ? Colors.white38 : AppColors.slate400,
                          ),
                          onPressed: () {
                            _controller.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : AppColors.slate200,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(
                      color: isValid
                          ? AppColors.indigo500
                          : (isDark ? Colors.white12 : AppColors.slate200),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(
                      color: AppColors.indigo500,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              ScaleButton(
                onTap: isValid
                    ? () {
                        Navigator.of(context).pop(_controller.text.trim());
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  height: 52.h,
                  decoration: BoxDecoration(
                    gradient: isValid
                        ? const LinearGradient(
                            colors: [
                              AppColors.indigo500,
                              AppColors.violet500,
                            ],
                          )
                        : null,
                    color: isValid
                        ? null
                        : (isDark ? Colors.white12 : AppColors.slate200),
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: isValid
                        ? [
                            BoxShadow(
                              color: AppColors.indigo500.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    context.tr(
                      'premium.continue_to_payment',
                      fallback: 'Proceed to Payment Options',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: isValid
                          ? Colors.white
                          : (isDark ? Colors.white38 : AppColors.slate400),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop('');
                  },
                  child: Text(
                    context.tr(
                      'common.skip',
                      fallback: 'Skip and enter inside payment gateway',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      color: isDark ? Colors.white54 : AppColors.slate500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
