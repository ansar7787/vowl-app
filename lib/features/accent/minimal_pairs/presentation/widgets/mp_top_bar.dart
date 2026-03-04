import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  MpTopBar — Close + Progress + Hint + Hearts
// ═══════════════════════════════════════════════════════════════════════════

class MpTopBar extends StatelessWidget {
  final bool isDark;
  final ThemeResult theme;
  final double progress;
  final AccentLoaded state;
  final List<String> words;
  final String correctWord;
  final VoidCallback onClose;
  final void Function(AccentLoaded, List<String>, String) onHint;

  const MpTopBar({
    super.key,
    required this.isDark,
    required this.theme,
    required this.progress,
    required this.state,
    required this.words,
    required this.correctWord,
    required this.onClose,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 10.h),
      child: Row(
        children: [
          // Close button
          ScaleButton(
            onTap: onClose,
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black12,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 24.r,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Progress bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 14.h,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                valueColor: AlwaysStoppedAnimation(theme.primaryColor),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Hint button
          if (!state.hintUsed) ...[
            _HintButton(
              state: state,
              primaryColor: theme.primaryColor,
              onTap: () => onHint(state, words, correctWord),
            ),
            SizedBox(width: 12.w),
          ],

          // Hearts
          _HeartBadge(lives: state.livesRemaining),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  _HeartBadge
// ═══════════════════════════════════════════════════════════════════════════

class _HeartBadge extends StatelessWidget {
  final int lives;
  const _HeartBadge({required this.lives});

  static final _style = GoogleFonts.outfit(
    fontWeight: FontWeight.w900,
    color: Colors.pinkAccent,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 20.r),
          SizedBox(width: 6.w),
          Text('$lives', style: _style.copyWith(fontSize: 16.sp)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  _HintButton — with buildWhen for efficient rebuilds
// ═══════════════════════════════════════════════════════════════════════════

class _HintButton extends StatelessWidget {
  final AccentLoaded state;
  final Color primaryColor;
  final VoidCallback onTap;

  const _HintButton({
    required this.state,
    required this.primaryColor,
    required this.onTap,
  });

  static final _style = GoogleFonts.outfit(fontWeight: FontWeight.w900);

  @override
  Widget build(BuildContext context) {
    final disabled = state.hintUsed;
    final c = disabled ? Colors.grey : primaryColor;

    return ScaleButton(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: c.withValues(alpha: disabled ? 0.3 : 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              disabled
                  ? Icons.lightbulb_outline_rounded
                  : Icons.lightbulb_rounded,
              color: c,
              size: 20.r,
            ),
            SizedBox(width: 6.w),
            BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (p, n) => p.user?.hintCount != n.user?.hintCount,
              builder: (_, authState) {
                final count = authState.user?.hintCount ?? 0;
                return Text(
                  '$count',
                  style: _style.copyWith(fontSize: 16.sp, color: c),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
