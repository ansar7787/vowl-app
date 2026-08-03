import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Renders the scrollable (or fixed) content area with title, subtitle, and
/// the question-specific [child] widget.
///
/// Extracted from [AccentBaseLayout] to eliminate the verbatim duplication
/// of padding + title + subtitle across the `useScrolling` branches.
///
/// Callers only set [useScrolling] — all layout differences are internal.
class AccentContentBody extends StatelessWidget {
  final bool useScrolling;
  final bool disablePadding;
  final bool isAnswered;
  final String title;
  final String subtitle;

  /// The game's accent colour — used for the category label above the subtitle.
  final Color primaryColor;
  final bool isDark;
  final Widget child;

  const AccentContentBody({
    super.key,
    required this.useScrolling,
    required this.disablePadding,
    required this.isAnswered,
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.isDark,
    required this.child,
  });

  // ── Padding ─────────────────────────────────────────────────────────────
  //
  // Uses MediaQuery.viewInsetsOf (not MediaQuery.of) so this widget only
  // rebuilds when the keyboard inset changes, not on every MediaQuery update.

  EdgeInsets _padding(BuildContext context) {
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final horizontal =
        0.0; // Let individual game screens manage their horizontal padding
    final top = disablePadding ? 0.0 : 20.h;
    final bottom = (disablePadding ? 0.0 : 40.h) + keyboardBottom;
    return EdgeInsets.only(
      left: horizontal,
      right: horizontal,
      top: top,
      bottom: bottom,
    );
  }

  // ── Title + Subtitle ─────────────────────────────────────────────────────

  Widget _titleSection() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 24.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: primaryColor,
          ),
        ).animate().fadeIn(),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          // Prevents overflow on small phones with accessibility text scaling
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        SizedBox(height: 32.h),
      ],
    ),
  );

  // ── Build ─────────────────────────────────────────────────────────────────
  //
  // Tablet breakpoint: on screens wider than 600 logical pixels the content
  // is constrained to a centred 520 px column so it doesn't stretch across
  // the full width of a tablet display.

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget content;

        if (useScrolling) {
          content = SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: _padding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [_titleSection(), child],
                ),
              ),
            ),
          );
        } else {
          content = Padding(
            padding: _padding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _titleSection(),
                Expanded(child: child),
              ],
            ),
          );
        }

        return content;
      },
    );
  }
}
