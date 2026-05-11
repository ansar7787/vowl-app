import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LegalContentScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalContentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final bgColor = isMidnight 
        ? Colors.black 
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.h,
            pinned: true,
            backgroundColor: bgColor.withValues(alpha: 0.8),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 20.sp,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              centerTitle: true,
            ),
            leading: IconButton(
              icon: Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(24.r),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: SelectableText(
                  content,
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                    fontSize: 15.sp,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
            ),
          ),
          SliverPadding(padding: EdgeInsets.only(bottom: 40.h)),
        ],
      ),
    );
  }
}

