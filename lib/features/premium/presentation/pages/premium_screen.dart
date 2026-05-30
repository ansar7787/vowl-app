import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/payment_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/premium/presentation/widgets/premium_widgets.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _paymentService = di.sl<PaymentService>();
  int _selectedPlanIndex = 1;
  bool _paymentCompleted = false;
  bool? _paymentSuccess;

  final List<Map<String, dynamic>> _plans = const [
    {
      'name': 'Weekly',
      'price': 39.0,
      'oldPrice': 49.0,
      'days': 7,
      'tag': 'FESTIVE OFFER',
      'color': Color(0xFFF43F5E),
    },
    {
      'name': 'Monthly',
      'price': 99.0,
      'oldPrice': 149.0,
      'days': 30,
      'tag': 'MOST POPULAR',
      'color': Color(0xFF6366F1),
    },
    {
      'name': 'Yearly',
      'price': 799.0,
      'oldPrice': 1499.0,
      'days': 365,
      'tag': 'BEST VALUE',
      'color': Color(0xFF10B981),
    },
  ];

  @override
  void initState() {
    super.initState();
    _paymentService.init(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      final selectedPlan = _plans[_selectedPlanIndex];
      await _paymentService.upgradeToPremium(user.id, selectedPlan['days'] as int);
      if (mounted) {
        Haptics.vibrate(HapticsType.success);
        setState(() {
          _paymentCompleted = true;
          _paymentSuccess = true;
        });
      }
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    Haptics.vibrate(HapticsType.error);
    if (mounted) {
      setState(() {
        _paymentCompleted = true;
        _paymentSuccess = false;
      });
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -50,
              child: StaticGlow(color: isDark ? const Color(0x14F59E0B) : const Color(0x08F59E0B)),
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
            if (_paymentCompleted)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.85),
                  child: Center(
                    child: _paymentSuccess == true
                        ? PremiumSuccessOverlay(
                            onBeginAdventure: () => context.pop(),
                          )
                        : PremiumFailureOverlay(
                            onRetry: () {
                              setState(() {
                                _paymentCompleted = false;
                                _paymentSuccess = null;
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
    );
  }

  Widget _buildPlanList() {
    return Column(
      children: List.generate(_plans.length, (index) {
        return PremiumPlanCard(
          plan: _plans[index],
          isSelected: _selectedPlanIndex == index,
          onTap: () {
            Haptics.vibrate(HapticsType.selection);
            setState(() => _selectedPlanIndex = index);
          },
        );
      }),
    );
  }

  Widget _buildCTAButton() {
    return ScaleButton(
      onTap: () {
        Haptics.vibrate(HapticsType.heavy);
        final user = context.read<AuthBloc>().state.user;
        if (user != null) {
          final plan = _plans[_selectedPlanIndex];
          _paymentService.purchaseSubscription(
            contact: '', 
            email: user.email, 
            amount: plan['price'] as double, 
            days: plan['days'] as int, 
            planName: plan['name'] as String
          );
        }
      },
      child: Container(
        width: double.infinity,
        height: 60.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
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
                'ACTIVATE PRO ACCESS',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(width: 10.w),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecureTag(bool isDark) {
    return Text(
      'SECURE TRANSACTION • CANCEL ANYTIME',
      style: GoogleFonts.outfit(
        color: isDark ? const Color(0x3DFFFFFF) : const Color(0x42000000),
        fontSize: 9.sp,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
}
