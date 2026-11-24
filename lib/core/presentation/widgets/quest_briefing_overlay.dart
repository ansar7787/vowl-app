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
        : (isDark ? const Color(0xFF131B2B) : Colors.white);

    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);

    final backdropColor = isMidnight
        ? Colors.black.withValues(alpha: 0.85)
        : (isDark
              ? Colors.black.withValues(alpha: 0.72)
              : Colors.black.withValues(alpha: 0.65));

    final cardShadows = isMidnight
        ? null
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ];

    final titleCol = isDark ? Colors.white : AppColors.slate900;
    final subtitleCol =
        isDark ? AppColors.slate400 : AppColors.slate600;

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
                // 1. Dimmed Backdrop Scrim (Tap to Dismiss)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _handleDismiss,
                    child: ColoredBox(color: backdropColor),
                  )
                      .animate(target: isExiting ? 1 : 0)
                      .fadeIn(duration: 220.ms)
                      .fadeOut(duration: _animDuration),
                ),

                // 2. Slide-Up Bottom Sheet with Sticky CTA Footer
                Align(
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! > 250) {
                        _handleDismiss();
                      }
                    },
                    child: AnimatedSlide(
                      offset: isExiting ? const Offset(0, 1.0) : Offset.zero,
                      duration: _animDuration,
                      curve: Curves.easeInCubic,
                      child: AnimatedOpacity(
                        opacity: isExiting ? 0.0 : 1.0,
                        duration: 200.ms,
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            maxWidth: 500,
                            maxHeight: MediaQuery.of(context).size.height * 0.85,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(28.r),
                            ),
                            border: Border(
                              top: BorderSide(color: cardBorder, width: 1.0),
                              left: BorderSide(color: cardBorder, width: 1.0),
                              right: BorderSide(color: cardBorder, width: 1.0),
                            ),
                            boxShadow: cardShadows,
                          ),
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Top Drag Handle Pill with dedicated touch hit zone
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onVerticalDragEnd: (details) {
                                    if (details.primaryVelocity != null &&
                                        details.primaryVelocity! > 200) {
                                      _handleDismiss();
                                    }
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.only(
                                      top: 12.h,
                                      bottom: 8.h,
                                    ),
                                    color: Colors.transparent,
                                    child: Center(
                                      child: Container(
                                        width: 40.w,
                                        height: 4.h,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.20,
                                                )
                                              : AppColors.slate300,
                                          borderRadius: BorderRadius.circular(
                                            2.r,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Flexible Scrollable Body with overscroll flick-down listener
                                Flexible(
                                  child:
                                      NotificationListener<
                                        ScrollEndNotification
                                      >(
                                        onNotification: (notification) {
                                          if (notification.metrics.pixels <=
                                                  0 &&
                                              notification
                                                      .dragDetails
                                                      ?.primaryVelocity !=
                                                  null &&
                                              notification
                                                      .dragDetails!
                                                      .primaryVelocity! >
                                                  200) {
                                            _handleDismiss();
                                            return true;
                                          }
                                          return false;
                                        },
                                        child: ScrollConfiguration(
                                          behavior: ScrollConfiguration.of(
                                            context,
                                          ).copyWith(scrollbars: false),
                                          child: SingleChildScrollView(
                                            physics:
                                                const BouncingScrollPhysics(),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 22.w,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                // 1. Centered Level/Phase Badge
                                                Center(
                                                  child: _buildBadge(
                                                    context,
                                                    isDark,
                                                  ),
                                                ),
                                                SizedBox(height: 10.h),

                                                // 2. Title with Icon Row (Matching VowlPauseBottomSheet's high-contrast header)
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      widget.icon,
                                                      color:
                                                          widget.primaryColor,
                                                      size: 24.r,
                                                    ),
                                                    SizedBox(width: 8.w),
                                                    Flexible(
                                                      child: Text(
                                                        widget.title
                                                            .toUpperCase(),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 20.sp,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color: titleCol,
                                                          letterSpacing: 1.2,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                // 3. Subtitle (Matching VowlPauseBottomSheet's subtitle styling)
                                                if (widget.objective
                                                    .isNotEmpty) ...[
                                                  SizedBox(height: 6.h),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 14.w,
                                                        ),
                                                    child: Text(
                                                      widget.objective,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 13.sp,
                                                        color: subtitleCol,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ),
                                                ],

                                                // 5. "HOW TO PLAY" Recessed Island Container
                                                if (_ruleWidgets
                                                    .isNotEmpty) ...[
                                                  SizedBox(height: 16.h),
                                                  Container(
                                                    width: double.infinity,
                                                    padding: EdgeInsets.all(
                                                      14.r,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: isMidnight
                                                          ? const Color(
                                                              0xFF0F0F12,
                                                            )
                                                          : (isDark
                                                                ? const Color(
                                                                    0xFF202024,
                                                                  )
                                                                : const Color(
                                                                    0xFFF1F5F9,
                                                                  )),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16.r,
                                                          ),
                                                      border: Border.all(
                                                        color: isMidnight
                                                            ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.10,
                                                                )
                                                            : (isDark
                                                                  ? Colors.white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.07,
                                                                      )
                                                                  : const Color(
                                                                      0xFFE2E8F0,
                                                                    )),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .checklist_rounded,
                                                              size: 15.r,
                                                              color: isDark
                                                                  ? Colors
                                                                      .white38
                                                                  : const Color(
                                                                      0xFF64748B,
                                                                    ),
                                                            ),
                                                            SizedBox(
                                                              width: 6.w,
                                                            ),
                                                            Text(
                                                              context
                                                                  .tr(
                                                                    'games.how_to_play',
                                                                    fallback:
                                                                        'HOW TO PLAY',
                                                                  )
                                                                  .toUpperCase(),
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Outfit',
                                                                fontSize: 11.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                letterSpacing:
                                                                    1.1,
                                                                color: isDark
                                                                    ? Colors
                                                                        .white38
                                                                    : const Color(
                                                                        0xFF64748B,
                                                                      ),
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
                                                  _buildTipStrip(
                                                    isDark,
                                                    isMidnight,
                                                  ),

                                                SizedBox(height: 14.h),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                ),

                                // 7. Sticky Pinned Bottom CTA Footer (Always under thumb)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    22.w,
                                    6.h,
                                    22.w,
                                    16.h +
                                        (MediaQuery.of(context).viewPadding.bottom > 0
                                            ? MediaQuery.of(context).viewPadding.bottom
                                            : MediaQuery.of(context).padding.bottom),
                                  ),
                                  child: _buildCtaButton(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate().slideY(
                    begin: 1.0,
                    end: 0.0,
                    duration: 280.ms,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, bool isDark) {
    final badgeText = widget.phaseBadge ??
        context
            .tr('common.mission_briefing', fallback: 'MISSION BRIEFING')
            .toUpperCase();

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
        badgeText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textScaler: const TextScaler.linear(1.0),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w700,
          color: widget.primaryColor,
          letterSpacing: 0.8,
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
    final label = context.tr('games.resume', fallback: 'RESUME PLAYING');

    return Semantics(
      button: true,
      label: label,
      child: ScaleButton(
        onTap: _handleDismiss,
        child: Container(
          width: double.infinity,
          height: 52.h,
          decoration: BoxDecoration(
            color: widget.primaryColor,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                size: 24.r,
                color: Colors.white,
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
