import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:async';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/payment_service.dart';
import 'package:vowl/core/utils/subscription_plans_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/premium/domain/entities/subscription_plan.dart';
import 'package:vowl/features/premium/presentation/widgets/widgets.dart';
import 'package:vowl/features/premium/presentation/widgets/premium_plan_card_v2.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _paymentService = di.sl<PaymentService>();
  final _plansService = di.sl<SubscriptionPlansService>();

  int _selectedPlanIndex = 1;
  bool _isProcessing = false;
  bool _paymentCompleted = false;
  bool? _paymentSuccess;
  String? _errorMessage;
  String? _transactionId;
  Timer? _paymentTimeout;

  // Plans fetched from Firebase
  List<SubscriptionPlan> _plans = [];
  bool _isLoadingPlans = false;
  String? _plansError;

  @override
  void initState() {
    super.initState();
    _paymentService.init(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
    _fetchPlans();
  }

  /// Fetch subscription plans from Firebase
  Future<void> _fetchPlans() async {
    if (!mounted) return;

    setState(() {
      _isLoadingPlans = true;
      _plansError = null;
    });

    try {
      final plans = await _plansService.fetchPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
          _isLoadingPlans = false;
          // Select "Most Popular" plan by default (usually index 1)
          _selectedPlanIndex = plans.isNotEmpty ? 1 : 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPlans = false;
          _plansError = 'Failed to load plans. Please try again.';
        });
        debugPrint('Failed to fetch plans: $e');
      }
    }
  }

  void _startPaymentTimeout() {
    // Timeout after 2 minutes if no response
    _paymentTimeout = Timer(const Duration(minutes: 2), () {
      if (mounted && _isProcessing) {
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
      setState(() {
        _isProcessing = false;
        _paymentCompleted = true;
        _paymentSuccess = false;
        _errorMessage = 'Payment request timed out. Please try again.';
      });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _cancelPaymentTimeout();
    if (!mounted) return;

    try {
      final user = context.read<AuthBloc>().state.user;
      if (user != null) {
        // Validate email before upgrading
        if (user.email.isEmpty || !user.email.contains('@')) {
          throw Exception('Invalid email: ${user.email}');
        }

        // Prevent re-purchasing if already premium
        if (user.isPremium) {
          throw Exception('User is already premium');
        }

        final selectedPlan = _plans[_selectedPlanIndex];
        await _paymentService.upgradeToPremium(user.id, selectedPlan.days);

        if (mounted) {
          // Refresh user state to reflect premium status
          context.read<AuthBloc>().add(AuthReloadUser());

          di.sl<HapticService>().success();
          setState(() {
            _isProcessing = false;
            _paymentCompleted = true;
            _paymentSuccess = true;
            _transactionId = response.paymentId;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        di.sl<HapticService>().error();
        setState(() {
          _isProcessing = false;
          _paymentCompleted = true;
          _paymentSuccess = false;
          _errorMessage = 'Failed to upgrade account: ${e.toString()}';
        });
      }
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    _cancelPaymentTimeout();
    di.sl<HapticService>().error();
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _paymentCompleted = true;
        _paymentSuccess = false;
        _errorMessage = response.message ?? 'Payment failed. Please try again.';
      });
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _cancelPaymentTimeout();
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _cancelPaymentTimeout();
    _paymentService.dispose();
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
              Positioned(
                top: -100,
                right: -50,
                child: StaticGlow(
                  color: isDark
                      ? const Color(0x14F59E0B)
                      : const Color(0x08F59E0B),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const PremiumHeader(),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          children: [
                            const Spacer(),
                            const PremiumHero(),
                            const Spacer(),
                            _buildPlanList(),
                            const Spacer(),
                            const ModernFeatureBar(),
                            const Spacer(flex: 2),
                            _buildCTAButton(),
                            SizedBox(height: 20.h),
                            _buildSecureTag(isDark),
                            SizedBox(height: 12.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isProcessing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.85),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 60.r,
                            height: 60.r,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFFF59E0B),
                              ),
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            'Processing Payment...',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Please wait while we process your request',
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
              if (_paymentCompleted)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.85),
                    child: Center(
                      child: _paymentSuccess == true
                          ? PremiumSuccessOverlay(
                              transactionId: _transactionId,
                              onBeginAdventure: () => context.pop(),
                            )
                          : PremiumFailureOverlay(
                              errorMessage: _errorMessage,
                              onRetry: () {
                                setState(() {
                                  _paymentCompleted = false;
                                  _paymentSuccess = null;
                                  _errorMessage = null;
                                  _transactionId = null;
                                });
                              },
                              onClose: () => context.pop(),
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

  Widget _buildPlanList() {
    if (_isLoadingPlans) {
      return Center(
        child: CircularProgressIndicator(
          valueColor:
              AlwaysStoppedAnimation<Color>(const Color(0xFFF59E0B)),
        ),
      );
    }

    if (_plansError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFF43F5E), size: 48),
            SizedBox(height: 16.h),
            Text(
              _plansError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _fetchPlans,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_plans.isEmpty) {
      return Center(
        child: Text(
          'No plans available',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(_plans.length, (index) {
        final plan = _plans[index];
        return PremiumPlanCardV2(
          plan: plan,
          isSelected: _selectedPlanIndex == index,
          onTap: () {
            di.sl<HapticService>().selection();
            setState(() => _selectedPlanIndex = index);
          },
        );
      }),
    );
  }

  Widget _buildCTAButton() {
    final user = context.read<AuthBloc>().state.user;
    final isAlreadyPremium = user?.isPremium ?? false;
    final isButtonDisabled = _isProcessing || _plans.isEmpty || isAlreadyPremium;

    return ScaleButton(
      onTap: isButtonDisabled
          ? null
          : () {
              // Check if already premium
              if (isAlreadyPremium) {
                _showSnackBar('You are already a premium member!');
                return;
              }

              // Validate email
              if (user == null || user.email.isEmpty || !user.email.contains('@')) {
                _showSnackBar('Invalid email. Please update your profile.');
                return;
              }

              di.sl<HapticService>().heavy();
              setState(() => _isProcessing = true);
              _startPaymentTimeout();

              final plan = _plans[_selectedPlanIndex];
              _paymentService.purchaseSubscription(
                contact: '',
                email: user.email,
                amount: plan.price,
                days: plan.days,
                planName: plan.name,
              );
            },
      child: Container(
        width: double.infinity,
        height: 60.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isButtonDisabled
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : [const Color(0xFFF59E0B), const Color(0xFFEA580C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: isButtonDisabled
              ? []
              : [
                  BoxShadow(
                    color: const Color(0x4DF59E0B),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isAlreadyPremium
                    ? 'ALREADY PREMIUM'
                    : _isProcessing
                        ? 'PROCESSING...'
                        : 'ACTIVATE PRO ACCESS',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              if (!_isProcessing && !isAlreadyPremium) ...[
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
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSecureTag(bool isDark) {
    return Text(
      'SECURE TRANSACTION • CANCEL ANYTIME',
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
