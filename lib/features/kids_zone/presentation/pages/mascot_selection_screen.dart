import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/theme/theme_cubit.dart';

class MascotSelectionScreen extends StatelessWidget {
  const MascotSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          MeshGradientBackground(
            colors: isMidnight
                ? [
                    Colors.black,
                    const Color(0xFF020617),
                    const Color(0xFF0F172A),
                  ]
                : (isDark
                      ? [
                          const Color(0xFF0F172A),
                          const Color(0xFF1E1B4B),
                          const Color(0xFF312E81),
                        ]
                      : [
                          const Color(0xFFE0F2FE),
                          const Color(0xFFF0FDF4),
                          const Color(0xFFFFF7ED),
                        ]),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leadingWidth: 80.w,
                leading: Padding(
                  padding: EdgeInsets.only(left: 24.w, top: 8.h, bottom: 8.h),
                  child: ScaleButton(
                    onTap: () => context.pop(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
                          width: 3.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.blue.shade900 : Colors.blue.shade100,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 28.r,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 10.h),
                      Text(
                        context.tr('kids_zone.choose_buddy', fallback: 'Choose Your Buddy!'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                      Text(
                        context.tr('kids_zone.which_friend', fallback: 'Which friend will join your quest?'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black45,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                      SizedBox(height: 30.h),
                      Column(
                        children: [
                          KidsMascotCard(
                            id: "owly",
                            name: "Owly",
                            trait: "Wise and Helpful",
                            color: Colors.indigo,
                            index: 0,
                          ),
                          SizedBox(height: 20.h),
                          KidsMascotCard(
                            id: "foxie",
                            name: "Foxie",
                            trait: "Playful and Fast",
                            color: Colors.orange,
                            index: 1,
                          ),
                          SizedBox(height: 20.h),
                          KidsMascotCard(
                            id: "dino",
                            name: "Dino",
                            trait: "Strong and Brave",
                            color: Colors.green,
                            index: 2,
                          ),
                        ],
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class KidsMascotCard extends StatefulWidget {
  final String id;
  final String name;
  final String trait;
  final Color color;
  final int index;

  const KidsMascotCard({
    super.key,
    required this.id,
    required this.name,
    required this.trait,
    required this.color,
    required this.index,
  });

  @override
  State<KidsMascotCard> createState() => _KidsMascotCardState();
}

class _KidsMascotCardState extends State<KidsMascotCard> {
  bool _isTrying = false;

  void _handleTryMe() {
    if (_isTrying) return;
    setState(() => _isTrying = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isTrying = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isSelected = state.user?.kidsMascot == widget.id;
        
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(
              color: isSelected
                  ? widget.color
                  : (isDark ? Colors.blue.shade900 : Colors.blue.shade100),
              width: isSelected ? 4.w : 3.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? widget.color.withValues(alpha: 0.6)
                    : (isDark ? Colors.blue.shade900 : Colors.blue.shade100),
                offset: Offset(0, 6.h),
                blurRadius: isSelected ? 15 : 0,
              ),
            ],
          ),
          child: Row(
            children: [
              ScaleButton(
                onTap: _handleTryMe,
                child: Container(
                  height: 110.h,
                  width: 110.w,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VowlMascot(
                        size: 80.r,
                        mascotId: widget.id,
                        isKidsMode: true,
                        state: _isTrying ? VowlMascotState.happy : VowlMascotState.neutral,
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: widget.color,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            "Try me!",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -4),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      widget.trait,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: widget.color,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ScaleButton(
                      onTap: () {
                        context.read<ProfileBloc>().add(ProfileUpdateMascotRequested(widget.id));
                        CustomSnackBar.show(
                          context: context,
                          message: context.tr('kids_zone.buddy_selected', fallback: '${widget.name} is now your buddy! \u2728', args: [widget.name]),
                          type: CustomSnackBarType.success,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: isSelected ? widget.color : (isDark ? Colors.white10 : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Center(
                          child: Text(
                            isSelected ? "SELECTED" : "SELECT",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black45),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (200 + widget.index * 100).ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
      },
    );
  }
}
