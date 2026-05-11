import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
                ? [Colors.black, const Color(0xFF020617), const Color(0xFF0F172A)]
                : (isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                    : [const Color(0xFFE0F2FE), const Color(0xFFF0FDF4), const Color(0xFFFFF7ED)]),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                SizedBox(height: 20.h),
                Text(
                  "Choose Your Buddy!",
                  style: GoogleFonts.poppins(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  "Which friend will join your quest?",
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black45,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(vertical: 30.h),
                      child: Wrap(
                        spacing: 20.w,
                        runSpacing: 30.h,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildMascotCard(
                            context,
                            "owly",
                            "Owly",
                            "Wise and Helpful",
                            Colors.indigo,
                          ),
                          _buildMascotCard(
                            context,
                            "foxie",
                            "Foxie",
                            "Playful and Fast",
                            Colors.orange,
                          ),
                          _buildMascotCard(
                            context,
                            "dino",
                            "Dino",
                            "Strong and Brave",
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Row(
        children: [
          ScaleButton(
            onTap: () => context.pop(),
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
        ],
      ),
    );
  }

  Widget _buildMascotCard(
    BuildContext context,
    String id,
    String name,
    String trait,
    Color color,
  ) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isSelected = state.user?.kidsMascot == id;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ScaleButton(
          onTap: () {
            context.read<ProfileBloc>().add(ProfileUpdateMascotRequested(id));
            _showSuccessOverlay(context, name);
          },
          child: Container(
            width: 160.w,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 4.r,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? color.withValues(alpha: 0.3)
                      : (isDark ? Colors.black26 : Colors.black12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 120.h,
                  width: 120.w,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: VowlMascot(
                      size: 90.r,
                      mascotId: id,
                      isKidsMode: true,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  trait,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black38,
                  ),
                ),
                if (isSelected) ...[
                  SizedBox(height: 8.h),
                  Icon(Icons.check_circle_rounded, color: color, size: 24.r),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessOverlay(BuildContext context, String name) {
    _showModernNotification(context, "$name IS NOW YOUR BUDDY! ✨");
  }

  void _showModernNotification(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.h,
        left: 20.w,
        right: 20.w,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(25.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.greenAccent.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 24),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    message, 
                    style: GoogleFonts.outfit(
                      fontSize: 13.sp, 
                      fontWeight: FontWeight.w800, 
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: -1, end: 0, curve: Curves.easeOutBack).fadeIn().then(delay: 2000.ms).fadeOut().slideY(begin: 0, end: -1),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }
}

