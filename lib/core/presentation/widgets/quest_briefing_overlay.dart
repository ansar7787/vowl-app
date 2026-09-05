import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// Cinematic full-screen mission briefing shown before a quest begins.
///
/// The [_isExiting] flag drives a coordinated fade + slide exit animation
/// that completes before [onStart] is invoked.
class QuestBriefingOverlay extends StatefulWidget {
  final String title;
  final String objective;
  final List<String> rules;
  final String actionText;
  final String tip;
  final IconData icon;
  final Color primaryColor;
  final VoidCallback onStart;

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
  });

  @override
  State<QuestBriefingOverlay> createState() => _QuestBriefingOverlayState();
}

class _QuestBriefingOverlayState extends State<QuestBriefingOverlay> {
  static const Duration _exitAnimDuration = Duration(milliseconds: 400);
  final ValueNotifier<bool> _isExitingNotifier = ValueNotifier(false);

  // Pre-build rule items once to avoid list allocation on every build().
  late final List<Widget> _ruleWidgets;

  @override
  void initState() {
    super.initState();
    _ruleWidgets = widget.rules
        .map((rule) => _RuleItem(rule: rule, primaryColor: widget.primaryColor))
        .toList(growable: false);
  }

  @override
  void dispose() {
    _isExitingNotifier.dispose();
    super.dispose();
  }

  void _handleStart() {
    if (_isExitingNotifier.value || !mounted) return;
    _isExitingNotifier.value = true;
    // Align delay with the defined exit animation duration plus a tiny buffer.
    Future<void>.delayed(
      _exitAnimDuration + const Duration(milliseconds: 20),
      () {
        if (mounted) widget.onStart();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr(
        'common.mission_briefing',
        fallback: 'Mission Briefing',
      ),
      child: Material(
        color: Colors.transparent,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isExitingNotifier,
          builder: (context, isExiting, _) {
            return Stack(
              children: [
                // Background dim overlay
                Positioned.fill(
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.85))
                      .animate(target: isExiting ? 1 : 0)
                      .fadeOut(duration: _exitAnimDuration),
                ),

                // Content card
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: 50.h),
                    physics: const BouncingScrollPhysics(),
                    child:
                        Container(
                              width: 0.85.sw,
                              constraints: const BoxConstraints(maxWidth: 450),
                              padding: EdgeInsets.all(24.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(40.r),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Animated hero icon
                                  RepaintBoundary(
                                    child:
                                        Container(
                                              padding: EdgeInsets.all(16.r),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    widget.primaryColor,
                                                    widget.primaryColor
                                                        .withValues(alpha: 0.6),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: widget.primaryColor
                                                        .withValues(alpha: 0.5),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 10),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                widget.icon,
                                                color: Colors.white,
                                                size: 32.r,
                                              ),
                                            )
                                            .animate(
                                              onPlay: (c) =>
                                                  c.repeat(reverse: true),
                                            )
                                            .scale(
                                              begin: const Offset(1, 1),
                                              end: const Offset(1.1, 1.1),
                                              duration: 1.seconds,
                                            ),
                                  ),

                                  SizedBox(height: 24.h),

                                  // Category label
                                  Text(
                                    context
                                        .tr('common.mission_briefing')
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w800,
                                      color: widget.primaryColor,
                                      letterSpacing: 4,
                                    ),
                                  ),

                                  SizedBox(height: 8.h),

                                  // Quest title
                                  AutoSizeText(
                                    widget.title.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    minFontSize: 14,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),

                                  SizedBox(height: 24.h),

                                  // Objective
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(16.r),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Text(
                                      widget.objective,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 24.h),

                                  // Pre-built rule items (no per-build allocation)
                                  ..._ruleWidgets,

                                  SizedBox(height: 24.h),

                                  // Pro-tip card
                                  Container(
                                        padding: EdgeInsets.all(12.r),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                          border: Border.all(
                                            color: Colors.amber.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.tips_and_updates_rounded,
                                              color: Colors.amber,
                                              size: 18.r,
                                            ),
                                            SizedBox(width: 10.w),
                                            Expanded(
                                              child: Text(
                                                widget.tip,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 12.sp,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.8),
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .animate()
                                      .fadeIn(delay: 400.ms)
                                      .slideY(begin: 0.1),

                                  SizedBox(height: 32.h),

                                  // Start button
                                  RepaintBoundary(
                                    child: Semantics(
                                      button: true,
                                      label: widget.actionText,
                                      child: ScaleButton(
                                        onTap: _handleStart,
                                        child: Container(
                                          width: double.infinity,
                                          height: 56.h,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                widget.primaryColor,
                                                widget.primaryColor.withValues(
                                                  alpha: 0.8,
                                                ),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20.r,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: widget.primaryColor
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 15,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 16.w,
                                              ),
                                              child: AutoSizeText(
                                                widget.actionText.toUpperCase(),
                                                maxLines: 1,
                                                minFontSize: 10,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate(target: isExiting ? 1 : 0)
                            .slideY(
                              begin: 0,
                              end: -0.2,
                              duration: _exitAnimDuration,
                              curve: Curves.easeIn,
                            )
                            .fadeOut(duration: 300.ms),
                  ),
                ),
              ],
            );
          },
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

// ---------------------------------------------------------------------------
// Pre-built rule row — extracted to avoid closure allocations in build().
// ---------------------------------------------------------------------------

class _RuleItem extends StatelessWidget {
  final String rule;
  final Color primaryColor;

  const _RuleItem({required this.rule, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: primaryColor, size: 16.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              rule,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
