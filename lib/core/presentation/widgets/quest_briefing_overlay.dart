import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'quest_briefing_rule_item.dart';

/// Mission briefing overlay shown before a quest begins or on-demand from the header.
///
/// Designed with standard 16.w edge margins, harmonious Light/Dark/Midnight typography,
/// sequential numbered step indicators, left-aligned structured objectives, and zero idle drain.
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
  static const Duration _exitAnimDuration = Duration(milliseconds: 280);
  final ValueNotifier<bool> _isExitingNotifier = ValueNotifier(false);
  late final List<Widget> _ruleWidgets;

  @override
  void initState() {
    super.initState();
    _ruleWidgets = widget.rules.asMap().entries.map((entry) {
      return QuestBriefingRuleItem(
        index: entry.key + 1,
        rule: entry.value,
        primaryColor: widget.primaryColor,
      );
    }).toList(growable: false);
  }

  @override
  void dispose() {
    _isExitingNotifier.dispose();
    super.dispose();
  }

  void _handleStart() {
    if (_isExitingNotifier.value || !mounted) return;
    _isExitingNotifier.value = true;
    Future<void>.delayed(
      _exitAnimDuration + const Duration(milliseconds: 20),
      () {
        if (mounted) widget.onStart();
      },
    );
  }

  LinearGradient _gradient(Color c) {
    final hsl = HSLColor.fromColor(c);
    final darker = hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();
    return LinearGradient(
      colors: [c, darker],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.midnightNavy : Colors.white);
    final cardBorder = isMidnight
        ? Colors.white.withValues(alpha: 0.16)
        : (isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.slate200);
    final backdropColor = isMidnight
        ? Colors.black.withValues(alpha: 0.92)
        : (isDark ? Colors.black.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.65));

    final cardShadow = isDark
        ? BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.25),
            blurRadius: 24.r,
            offset: Offset(0, 8.h),
          )
        : BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24.r,
            offset: Offset(0, 8.h),
          );

    return Semantics(
      label: context.tr('common.mission_briefing', fallback: 'MISSION BRIEFING'),
      child: Material(
        color: Colors.transparent,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isExitingNotifier,
          builder: (context, isExiting, _) {
            return Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: backdropColor)
                      .animate(target: isExiting ? 1 : 0)
                      .fadeOut(duration: _exitAnimDuration),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: cardBorder, width: 1.0),
                        boxShadow: [cardShadow],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeroIcon(),
                          SizedBox(height: 12.h),
                          if (widget.phaseBadge != null)
                            _buildPhaseBadge()
                          else
                            _buildCategoryLabel(context),
                          SizedBox(height: 6.h),
                          _buildTitle(isDark),
                          SizedBox(height: 12.h),
                          _buildObjectiveBox(isDark, isMidnight),
                          SizedBox(height: 12.h),
                          ..._ruleWidgets,
                          SizedBox(height: 12.h),
                          _buildTipCard(isDark),
                          SizedBox(height: 16.h),
                          _buildCtaButton(),
                        ],
                      ),
                    )
                        .animate(target: isExiting ? 1 : 0)
                        .slideY(begin: 0, end: -0.15, duration: _exitAnimDuration, curve: Curves.easeIn)
                        .fadeOut(duration: 250.ms),
                  ),
                ),
              ],
            );
          },
        ),
      ).animate().fadeIn(duration: 280.ms),
    );
  }

  Widget _buildHeroIcon() => Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          gradient: _gradient(widget.primaryColor),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withValues(alpha: 0.35),
              blurRadius: 14.r,
              offset: Offset(0, 5.h),
            ),
          ],
        ),
        child: Icon(widget.icon, color: Colors.white, size: 26.r),
      )
          .animate()
          .scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1, 1),
            duration: 350.ms,
            curve: Curves.easeOutBack,
          );

  Widget _buildPhaseBadge() => Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: widget.primaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: widget.primaryColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Text(
          widget.phaseBadge!,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10.sp,
            fontWeight: FontWeight.w800,
            color: widget.primaryColor,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _buildCategoryLabel(BuildContext context) => Text(
        context.tr('common.mission_briefing', fallback: 'MISSION BRIEFING').toUpperCase(),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
          color: widget.primaryColor,
          letterSpacing: 2,
        ),
      );

  Widget _buildTitle(bool isDark) => AutoSizeText(
        widget.title,
        textAlign: TextAlign.center,
        maxLines: 2,
        minFontSize: 13,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18.sp,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : AppColors.slate900,
          letterSpacing: -0.2,
        ),
      );

  Widget _buildObjectiveBox(bool isDark, bool isMidnight) {
    final bg = isMidnight
        ? Colors.white.withValues(alpha: 0.04)
        : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.slate50);
    final border = isDark
        ? Colors.white.withValues(alpha: isMidnight ? 0.12 : 0.08)
        : AppColors.slate200;
    final textCol = isDark ? Colors.white.withValues(alpha: 0.92) : AppColors.slate800;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes_rounded, size: 13.r, color: widget.primaryColor),
              SizedBox(width: 5.w),
              Text(
                'OBJECTIVE',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: widget.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Text(
            widget.objective,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              color: textCol,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(bool isDark) {
    final bg = Colors.amber.withValues(alpha: isDark ? 0.1 : 0.12);
    final border = Colors.amber.withValues(alpha: isDark ? 0.3 : 0.35);
    final textCol = isDark ? Colors.white.withValues(alpha: 0.88) : AppColors.slate800;
    final iconCol = isDark ? Colors.amber : Colors.amber.shade800;
    final tipText = widget.tip.startsWith('Tip: ') ? widget.tip.substring(5) : widget.tip;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_rounded, color: iconCol, size: 15.r),
          SizedBox(width: 8.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.5.sp,
                  color: textCol,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: 'Tip: ',
                    style: TextStyle(fontWeight: FontWeight.w800, color: iconCol),
                  ),
                  TextSpan(text: tipText, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButton() => RepaintBoundary(
        child: Semantics(
          button: true,
          label: widget.actionText,
          child: ScaleButton(
            onTap: _handleStart,
            child: Container(
              width: double.infinity,
              height: 48.h,
              decoration: BoxDecoration(
                gradient: _gradient(widget.primaryColor),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.0),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: AutoSizeText(
                          widget.actionText.toUpperCase(),
                          maxLines: 1,
                          minFontSize: 10,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 13.r),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
