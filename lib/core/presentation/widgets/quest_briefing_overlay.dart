import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'quest_briefing_rule_item.dart';

/// Mission briefing overlay shown before a quest begins or on-demand from the header.
///
/// Engineered with clean typographic hierarchy, responsive 3-mode theming
/// (Light, Dark, Midnight AMOLED), top-right dismiss action, and zero artificial neon glows.
class QuestBriefingOverlay extends StatefulWidget {
  final String title;
  final String objective;
  final List<String> rules;
  final String actionText;
  final String tip;
  final IconData icon;
  final Color primaryColor;
  final VoidCallback onStart;
  final String? phaseBadge;

  const QuestBriefingOverlay({
    super.key,
    required this.title,
    required this.objective,
    required this.rules,
    required this.actionText,
    required this.tip,
    required this.icon,
    required this.primaryColor,
    required this.onStart,
    this.phaseBadge,
  });

  @override
  State<QuestBriefingOverlay> createState() => _QuestBriefingOverlayState();
}

class _QuestBriefingOverlayState extends State<QuestBriefingOverlay> {
  static const Duration _animDuration = Duration(milliseconds: 260);
  final ValueNotifier<bool> _isExitingNotifier = ValueNotifier(false);
  late final List<Widget> _ruleWidgets;

  @override
  void initState() {
    super.initState();
    _ruleWidgets = widget.rules.asMap().entries.map((entry) {
      final isLast = entry.key == widget.rules.length - 1;
      return QuestBriefingRuleItem(
        index: entry.key + 1,
        rule: entry.value,
        primaryColor: widget.primaryColor,
        isLast: isLast,
      );
    }).toList(growable: false);
  }

  @override
  void dispose() {
    _isExitingNotifier.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    if (_isExitingNotifier.value || !mounted) return;
    try {
      di.sl<HapticService>().light();
    } catch (_) {}
    _isExitingNotifier.value = true;
    Future<void>.delayed(
      _animDuration + const Duration(milliseconds: 20),
      () {
        if (mounted) widget.onStart();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    // ── Pure Deliberate Surfaces (Zero Neon, No Flat Blinding White) ────────
    // Pure #FFFFFF against dark scrim creates extreme glare and looks flat.
    // We use a warm porcelain surface (0xFFFAFBFC) paired with a dual-tier shadow system.
    final cardBg = isMidnight
        ? Colors.black
        : (isDark ? const Color(0xFF18181B) : const Color(0xFFFAFBFC));

    final cardBorder = isMidnight
        ? Colors.white.withValues(alpha: 0.16)
        : (isDark
              ? Colors.white.withValues(alpha: 0.10)
              : const Color(0xFFE2E8F0));

    final backdropColor = isMidnight
        ? Colors.black.withValues(alpha: 0.85)
        : (isDark
              ? Colors.black.withValues(alpha: 0.72)
              : Colors.black.withValues(alpha: 0.45));

    final cardShadows = isMidnight
        ? null
        : (isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                  const BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 28,
                    offset: Offset(0, 10),
                  ),
                ]);

    final titleCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleCol =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569);

    return Semantics(
      label: context.tr(
        'common.mission_briefing',
        fallback: 'MISSION BRIEFING',
      ),
      child: Material(
        color: Colors.transparent,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isExitingNotifier,
          builder: (context, isExiting, _) {
            return Stack(
              children: [
                // Backdrop
                Positioned.fill(
                  child: ColoredBox(color: backdropColor)
                      .animate(target: isExiting ? 1 : 0)
                      .fadeOut(duration: _animDuration),
                ),

                // Card Center
                Center(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 24.h,
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 460),
                        padding: EdgeInsets.all(22.r),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(color: cardBorder, width: 1.0),
                          boxShadow: cardShadows,
                        ),
                        child: Stack(
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 1. Centered Hero Icon
                                Center(
                                  child: Container(
                                    width: 44.r,
                                    height: 44.r,
                                    decoration: BoxDecoration(
                                      color: widget.primaryColor.withValues(
                                        alpha: isDark ? 0.16 : 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(14.r),
                                      border: Border.all(
                                        color: widget.primaryColor.withValues(
                                          alpha: isDark ? 0.35 : 0.22,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        widget.icon,
                                        color: widget.primaryColor,
                                        size: 22.r,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10.h),

                                // 2. Centered Phase Badge or Mission Briefing Pill
                                Center(
                                  child: _buildBadge(context, isDark),
                                ),
                                SizedBox(height: 12.h),

                                // 3. Centered Title (Elevated scale, w800 bold anchor)
                                Text(
                                  widget.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 23.sp,
                                    fontWeight: FontWeight.w800,
                                    color: titleCol,
                                    letterSpacing: -0.4,
                                    height: 1.22,
                                  ),
                                ),

                                // 4. Centered Objective Subtitle (No flat feel)
                                if (widget.objective.isNotEmpty) ...[
                                  SizedBox(height: 6.h),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                    ),
                                    child: Text(
                                      widget.objective,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w400,
                                        color: subtitleCol,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],

                                // 5. "HOW TO PLAY" Recessed Island Container
                                if (_ruleWidgets.isNotEmpty) ...[
                                  SizedBox(height: 16.h),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(14.r),
                                    decoration: BoxDecoration(
                                      color: isMidnight
                                          ? const Color(0xFF0F0F12)
                                          : (isDark
                                                ? const Color(0xFF202024)
                                                : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color: isMidnight
                                            ? Colors.white.withValues(
                                                alpha: 0.10,
                                              )
                                            : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.07,
                                                    )
                                                  : const Color(0xFFE2E8F0)),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.checklist_rounded,
                                              size: 15.r,
                                              color: isDark
                                                  ? Colors.white38
                                                  : const Color(0xFF64748B),
                                            ),
                                            SizedBox(width: 6.w),
                                            Text(
                                              context
                                                  .tr(
                                                    'games.how_to_play',
                                                    fallback: 'HOW TO PLAY',
                                                  )
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.1,
                                                color: isDark
                                                    ? Colors.white38
                                                    : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12.h),
                                        ..._ruleWidgets,
                                      ],
                                    ),
                                  ),
                                ],

                                // 6. Pro-Tip Strip (Subtle, elegant warm accent)
                                if (widget.tip.isNotEmpty)
                                  _buildTipStrip(isDark, isMidnight),

                                // 7. Solid Tactile Primary CTA Button (Zero Neon Glow, Modern Chevron)
                                SizedBox(height: 18.h),
                                _buildCtaButton(),
                              ],
                            ),

                            // Top-Right Dismiss / Close Button (✕)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: _buildCloseButton(isDark, isMidnight),
                            ),
                          ],
                        ),
                      )
                          .animate(target: isExiting ? 1 : 0)
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(0.95, 0.95),
                            duration: _animDuration,
                            curve: Curves.easeIn,
                          )
                          .fadeOut(duration: 200.ms),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ).animate().fadeIn(duration: 220.ms),
    );
  }

  Widget _buildBadge(BuildContext context, bool isDark) {
    if (widget.phaseBadge != null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.5.h),
        decoration: BoxDecoration(
          color: widget.primaryColor.withValues(
            alpha: isDark ? 0.15 : 0.10,
          ),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: widget.primaryColor.withValues(
              alpha: isDark ? 0.35 : 0.25,
            ),
            width: 1,
          ),
        ),
        child: Text(
          widget.phaseBadge!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textScaler: const TextScaler.linear(1.0),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w700,
            color: widget.primaryColor,
            letterSpacing: 0.6,
          ),
        ),
      );
    }

    return Text(
      context
          .tr('common.mission_briefing', fallback: 'MISSION BRIEFING')
          .toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textScaler: const TextScaler.linear(1.0),
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 10.5.sp,
        fontWeight: FontWeight.w700,
        color: widget.primaryColor,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCloseButton(bool isDark, bool isMidnight) {
    return Semantics(
      button: true,
      label: 'Close briefing',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: _handleDismiss,
          child: Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: isMidnight
                  ? Colors.white.withValues(alpha: 0.08)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF1F5F9)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.close_rounded,
                size: 18.r,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipStrip(bool isDark, bool isMidnight) {
    final tipText = widget.tip.startsWith('Tip: ')
        ? widget.tip.substring(5)
        : widget.tip;

    final bg = isMidnight
        ? AppColors.amber500.withValues(alpha: 0.06)
        : (isDark
              ? AppColors.amber500.withValues(alpha: 0.08)
              : const Color(0xFFFFFBEB)); // Amber-50

    final border = isMidnight
        ? AppColors.amber500.withValues(alpha: 0.24)
        : (isDark
              ? AppColors.amber500.withValues(alpha: 0.22)
              : const Color(0xFFFDE68A)); // Amber-200

    final iconCol = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    final textCol = isDark
        ? Colors.white.withValues(alpha: 0.90)
        : const Color(0xFF1E293B);

    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: iconCol, size: 16.r),
          SizedBox(width: 8.w),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Pro-Tip: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: iconCol,
                    ),
                  ),
                  TextSpan(
                    text: tipText,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: textCol,
                    ),
                  ),
                ],
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5.sp,
                height: 1.42,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButton() {
    return Semantics(
      button: true,
      label: widget.actionText.isNotEmpty
          ? widget.actionText
          : 'Got It · Continue',
      child: ScaleButton(
        onTap: _handleDismiss,
        child: Container(
          width: double.infinity,
          height: 50.h,
          decoration: BoxDecoration(
            color: widget.primaryColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.actionText.isNotEmpty
                    ? widget.actionText
                    : 'Got It · Continue',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13.r,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
