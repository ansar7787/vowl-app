import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class SCTopBar extends StatelessWidget {
  final AccentLoaded state;
  final ThemeResult theme;
  final bool isDark;
  final VoidCallback onHintPressed;
  final VoidCallback onClose;
  final AccentQuest quest;
  final bool isMidnight;

  const SCTopBar({
    super.key,
    required this.state,
    required this.theme,
    required this.isDark,
    required this.onHintPressed,
    required this.onClose,
    required this.quest,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (state.currentIndex + 1) / state.quests.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 10.h),
      child: Row(
        children: [
          ScaleButton(
            onTap: onClose,
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: isDark ? Colors.black45 : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.close_rounded,
                size: 24.r,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 14.h,
                backgroundColor: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          if (!state.hintUsed) ...[_buildHintButton(), SizedBox(width: 12.w)],
          _buildHeartCount(state.livesRemaining),
        ],
      ),
    );
  }

  Widget _buildHeartCount(int lives) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.black45 : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 20.r),
          SizedBox(width: 6.w),
          Text(
            "$lives",
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: Colors.pinkAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintButton() {
    bool disabled = state.hintUsed;
    return ScaleButton(
      onTap: disabled ? null : onHintPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey.withValues(alpha: 0.1)
              : (isDark ? Colors.black45 : Colors.white),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            if (!disabled)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
          border: Border.all(
            color: disabled
                ? Colors.grey.withValues(alpha: 0.3)
                : theme.primaryColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              disabled
                  ? Icons.lightbulb_outline_rounded
                  : Icons.lightbulb_rounded,
              color: disabled ? Colors.grey : theme.primaryColor,
              size: 20.r,
            ),
            SizedBox(width: 6.w),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final hintCount = authState.user?.hintCount ?? 0;
                return Text(
                  "$hintCount",
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: disabled ? Colors.grey : theme.primaryColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
