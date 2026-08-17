import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class KidsRoomActionPanel extends StatelessWidget {
  final bool isSleeping;
  final VoidCallback onDecor;
  final VoidCallback onFeed;
  final VoidCallback onPlay;
  final VoidCallback onClean;
  final VoidCallback onSleepToggle;
  final VoidCallback onTalk;
  final VoidCallback onThemeTap;

  const KidsRoomActionPanel({
    super.key,
    required this.isSleeping,
    required this.onDecor,
    required this.onFeed,
    required this.onPlay,
    required this.onClean,
    required this.onSleepToggle,
    required this.onTalk,
    required this.onThemeTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: 16.h,
            bottom: 16.h + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: isDark ? 0.3 : 0.4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.5),
                width: 1.5.w,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: Offset(0, -10.h),
              ),
            ],
          ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              clipBehavior: Clip.none,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModernActionButton(
                    context: context,
                    label: "Decor",
                    emoji: "🎨",
                    color: Colors.indigoAccent,
                    onTap: onDecor,
                    isDark: isDark,
                  ),
                  _buildModernActionButton(
                    context: context,
                    label: "Feed",
                    emoji: "🍎",
                    color: Colors.greenAccent.shade700,
                    onTap: onFeed,
                    isDark: isDark,
                  ),
                  _buildModernActionButton(
                    context: context,
                    label: "Play",
                    emoji: "🎮",
                    color: Colors.orangeAccent.shade700,
                    onTap: onPlay,
                    isDark: isDark,
                  ),
                  _buildModernActionButton(
                    context: context,
                    label: "Clean",
                    emoji: "🧹",
                    color: Colors.tealAccent.shade700,
                    onTap: onClean,
                    isDark: isDark,
                  ),
                  _buildModernActionButton(
                    context: context,
                    label: isSleeping ? "Wake" : "Sleep",
                    emoji: isSleeping ? "☀️" : "🌙",
                    color: Colors.deepPurpleAccent,
                    onTap: onSleepToggle,
                    isDark: isDark,
                  ),
                  _buildModernActionButton(
                    context: context,
                    label: "Talk",
                    emoji: "💬",
                    color: Colors.lightBlueAccent.shade700,
                    onTap: onTalk,
                    isDark: isDark,
                  ),
                  _buildModernActionButton(
                    context: context,
                    label: "Theme",
                    emoji: "✨",
                    color: Colors.pinkAccent.shade400,
                    onTap: onThemeTap,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

  Widget _buildModernActionButton({
    required BuildContext context,
    required String label,
    required String emoji,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: ScaleButton(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.8),
                    color,
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: Offset(0, 5.h),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.4),
                    blurRadius: 0,
                    spreadRadius: 1.5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: 22.sp,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(1, 2),
                    )
                  ]
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                letterSpacing: 1.2,
                shadows: [
                  if (isDark)
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                    )
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}


