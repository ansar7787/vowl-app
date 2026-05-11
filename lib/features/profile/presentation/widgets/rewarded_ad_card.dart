import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class RewardedAdCard extends StatefulWidget {
  final String title;
  final String subtitle;

  const RewardedAdCard({
    super.key,
    this.title = 'GET FREE COINS',
    this.subtitle = 'Watch a short ad to earn 20 coins',
  });

  @override
  State<RewardedAdCard> createState() => _RewardedAdCardState();
}

class _RewardedAdCardState extends State<RewardedAdCard> {
  bool _isLoading = false;

  void _handleWatchAd() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate ad loading and watching
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Dispatch event to add coins
    final economyBloc = context.read<EconomyBloc>();
    economyBloc.add(
      const EconomyAddCoinsRequested(
        20,
        title: 'Watched Rewarded Ad',
        isEarned: true,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20.r),
            SizedBox(width: 8.w),
            Text(
              'Reward Earned! +20 Vowl Coins',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.1),
            const Color(0xFFA855F7).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.all(24.r),
      child: Row(
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              LucideIcons.playCircle,
              color: const Color(0xFF6366F1),
              size: 28.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleWatchAd,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    children: [
                      Icon(LucideIcons.coins, size: 14.r),
                      SizedBox(width: 4.w),
                      Text(
                        '+20',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }
}
