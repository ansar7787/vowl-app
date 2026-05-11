import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _paymentService = di.sl<PaymentService>();
  int _selectedPlanIndex = 1;

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
        context.pop();
      }
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    Haptics.vibrate(HapticsType.error);
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
              child: _StaticGlow(color: isDark ? const Color(0x14F59E0B) : const Color(0x08F59E0B)),
            ),
            SafeArea(
              child: Column(
                children: [
                  _PremiumHeader(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        children: [
                          const Spacer(),
                          RepaintBoundary(child: _PremiumHero()),
                          const Spacer(),
                          _buildPlanList(),
                          const Spacer(),
                          _ModernFeatureBar(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPlanList() {
    return Column(
      children: List.generate(_plans.length, (index) {
        return _PlanCard(
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

class _StaticGlow extends StatelessWidget {
  final Color color;
  const _StaticGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350.r,
      height: 350.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)],
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.keyboard_backspace_rounded, color: isDark ? const Color(0x61FFFFFF) : const Color(0x61000000)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x0DFFFFFF) : const Color(0x08000000),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_rounded, color: const Color(0xFFF59E0B), size: 14.r),
                SizedBox(width: 6.w),
                Text('VERIFIED PRO', style: GoogleFonts.outfit(color: isDark ? const Color(0xB3FFFFFF) : const Color(0xDE000000), fontSize: 10.sp, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 70.r,
          height: 70.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEA580C)]),
            boxShadow: [BoxShadow(color: const Color(0x4DF59E0B), blurRadius: 20)],
          ),
          child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36.r),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
        SizedBox(height: 16.h),
        Text(
          'Unlimited Growth.',
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 30.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({required this.plan, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = plan['color'] as Color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0x0DFFFFFF) : const Color(0x08000000)) : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isSelected ? accentColor : (isDark ? const Color(0x1AFFFFFF) : const Color(0x1E000000)), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan['name'].toString().toUpperCase(), style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black, fontSize: 15.sp, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      if (plan['tag'] != null) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6.r)),
                          child: Text(plan['tag'] as String, style: GoogleFonts.outfit(color: accentColor, fontSize: 8.sp, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ],
                  ),
                  Text('${plan['days']} days of elite access', style: GoogleFonts.outfit(color: isDark ? const Color(0x61FFFFFF) : const Color(0x61000000), fontSize: 10.sp, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    if (plan['oldPrice'] != null)
                      Text('₹${(plan['oldPrice'] as double).toInt()}', style: GoogleFonts.outfit(color: isDark ? const Color(0x3DFFFFFF) : const Color(0x42000000), fontSize: 13.sp, decoration: TextDecoration.lineThrough)),
                    SizedBox(width: 6.w),
                    Text('₹${(plan['price'] as double).toInt()}', style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black, fontSize: 20.sp, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernFeatureBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x08FFFFFF) : const Color(0x05000000),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _FeatureItem(icon: Icons.block_rounded, label: 'ZERO ADS'),
          _FeatureItem(icon: Icons.auto_graph_rounded, label: '2X SPEED'),
          _FeatureItem(icon: Icons.psychology_rounded, label: 'AI UNLIMITED'),
          _FeatureItem(icon: Icons.workspace_premium_rounded, label: 'PRO STATUS'),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFF59E0B), size: 18.r),
        SizedBox(height: 6.h),
        Text(label, style: GoogleFonts.outfit(color: isDark ? const Color(0x61FFFFFF) : const Color(0x61000000), fontSize: 7.sp, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
