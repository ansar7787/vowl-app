import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';

class QuestUnavailableScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  final String message;
  final String? technicalError;

  const QuestUnavailableScreen({
    super.key,
    this.onRetry,
    this.message = "We couldn't find any quests for this level yet.",
    this.technicalError,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          MeshGradientBackground(
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [
                    const Color(0xFFF1F5F9),
                    const Color(0xFFE2E8F0),
                  ], // Slightly darker light mode for better text pop
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(32.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sentiment_dissatisfied_rounded,
                      size: 80.r,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.8)
                          : const Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    "QUEST UNAVAILABLE",
                    style: GoogleFonts.outfit(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : const Color(0xFF64748b),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (technicalError != null && kDebugMode)
                    Container(
                      margin: EdgeInsets.only(top: 16.h),
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: SelectableText(
                        "TECHNICAL INFO:\n$technicalError",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.robotoMono(
                          fontSize: 10.sp,
                          color: Colors.redAccent.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  SizedBox(height: 40.h),
                  ScaleButton(
                    onTap: onRetry ?? () => context.pop(),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "TRY AGAIN",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ScaleButton(
                    onTap: () => context.pop(),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Center(
                        child: Text(
                          "EXIT GAME",
                          style: GoogleFonts.outfit(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.8)
                                : const Color(0xFF475569),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
