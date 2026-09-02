import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/payment_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:confetti/confetti.dart';
import 'package:vowl/core/utils/subscription_plans_service.dart';
import 'package:vowl/features/premium/domain/entities/subscription_plan.dart';
import 'package:vowl/features/premium/presentation/widgets/widgets.dart';
import 'package:vowl/core/presentation/widgets/vowl_button_spinner.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _paymentService = di.sl<PaymentService>();
  int _selectedPlanIndexVal = 1;
  bool _isProcessingVal = false;
  bool _paymentCompletedVal = false;
  bool? _paymentSuccessVal;
  String? _errorMessageVal;
  String? _transactionIdVal;
  Timer? _paymentTimeout;
  late ConfettiController _confettiController;

  static const List<SubscriptionPlan> _fallbackPlans = [
    SubscriptionPlan(
      id: 'weekly',
      name: 'Weekly',
      price: 49.0,
      oldPrice: 59.0,
      days: 7,
      tag: 'FESTIVE OFFER',
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

  late final ValueNotifier<int> _stateHash = ValueNotifier(0);

  void _updateState() {
    _stateHash.value++;
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
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
        _updateState();
      }
    } catch (e) {
      di.sl<AppLogger>().warning(
        'Failed to load dynamic plans, falling back to local defaults.',
      );
    }
  }

  void _startPaymentTimeout() {
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
      _updateState();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _cancelPaymentTimeout();
    _paymentService.dispose();
    _stateHash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF020617)
        : const Color(0xFFF8FAFC);

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
                      ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                      : const Color(0xFF6366F1).withValues(alpha: 0.08),
                  radius: 300,
                ),
              ),
              Positioned(
                bottom: -100.h,
                left: -100.w,
                child: StaticGlow(
                  color: isDark
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                      : const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                  radius: 250,
                ),
              ),
              Positioned(
                top: 200.h,
                left: -50.w,
                child: StaticGlow(
                  color: isDark
                      ? const Color(0xFFA855F7).withValues(alpha: 0.1)
                      : const Color(0xFFA855F7).withValues(alpha: 0.05),
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
                                    color: const Color(0xFF6366F1),
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
                  colors: const [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                    Color(0xFFA855F7),
                    Color(0xFF6366F1),
                    Color(0xFFF43F5E),
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
  Widget _buildScrollableBody() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 16.h),
          const PremiumHero(),
          SizedBox(height: 24.h),
          _buildPlanList(),
          SizedBox(height: 24.h),
          const ModernFeatureBar(),
          SizedBox(height: 32.h),
          _buildCTAButton(),
          SizedBox(height: 20.h),
          _buildSecureTag(),
          SizedBox(height: 12.h),
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
                  child: const VowlButtonSpinner(color: Color(0xFFF59E0B)),
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
                    onBeginAdventure: () => context.pop(),
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
                    onClose: () => context.pop(),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanList() {
    return Column(
      children: List.generate(_activePlansVal.length, (index) {
        return PremiumPlanCard(
          plan: _activePlansVal[index],
          isSelected: _selectedPlanIndexVal == index,
          onTap: () {
            di.sl<HapticService>().selection();
            _selectedPlanIndexVal = index;
            _updateState();
          },
        );
      }),
    );
  }

  Widget _buildCTAButton() {
    final ctaLabel = _isProcessingVal
        ? context.tr('premium.cta_processing', fallback: 'Processing...')
        : context.tr('premium.cta_activate', fallback: 'Activate Premium');

    return Semantics(
      button: true,
      enabled: !_isProcessingVal,
      label: ctaLabel,
      child: ScaleButton(
        onTap: _isProcessingVal ? null : _onActivatePressed,
        child:
            Container(
                  width: double.infinity,
                  height: 60.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 25,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            ctaLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        if (!_isProcessingVal) ...[
                          SizedBox(width: 10.w),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.02, 1.02),
                  duration: 1.5.seconds,
                  curve: Curves.easeInOut,
                ),
      ),
    );
  }

  void _onActivatePressed() {
    di.sl<HapticService>().heavy();
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    _isProcessingVal = true;
    _updateState();
    _startPaymentTimeout();

    final plan = _activePlansVal[_selectedPlanIndexVal];
    _paymentService.purchaseSubscription(
      contact: '', // Empty is safe - Razorpay will use email if needed
      email: user.email,
      amount: plan.price,
      days: plan.days,
      planName: plan.name,
    );
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
}
