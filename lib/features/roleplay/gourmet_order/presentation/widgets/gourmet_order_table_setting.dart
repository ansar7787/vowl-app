import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_steam_painter.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color07070f = Color(0xFF07070F);
}

class GourmetOrderTableSetting extends StatefulWidget {
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;
  final List<String> selectedItems;
  final Animation<double> steamAnimation;
  final Function(String) onItemDropped;
  final VoidCallback onHapticFeedback;

  const GourmetOrderTableSetting({
    super.key,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.isCorrect,
    required this.selectedItems,
    required this.steamAnimation,
    required this.onItemDropped,
    required this.onHapticFeedback,
  });

  @override
  State<GourmetOrderTableSetting> createState() =>
      _GourmetOrderTableSettingState();
}

class _GourmetOrderTableSettingState extends State<GourmetOrderTableSetting> {
  final ValueNotifier<bool> _isHoveringPlatter = ValueNotifier(false);

  @override
  void dispose() {
    _isHoveringPlatter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    Color ringColor = widget.color;
    if (widget.isAnswered) {
      ringColor = (widget.isCorrect ?? false)
          ? tokens.gameCorrect
          : tokens.gameIncorrect;
    }

    return DragTarget<String>(
      key: const Key('gourmet_order_table_drag_target'),
      onWillAcceptWithDetails: (data) => !widget.isAnswered,
      onAcceptWithDetails: (details) {
        widget.onItemDropped(details.data);
        _isHoveringPlatter.value = false;
      },
      onMove: (details) {
        if (!_isHoveringPlatter.value) {
          widget.onHapticFeedback();
          _isHoveringPlatter.value = true;
        }
      },
      onLeave: (data) {
        _isHoveringPlatter.value = false;
      },
      builder: (context, candidateData, rejectedData) {
        return ValueListenableBuilder<bool>(
          valueListenable: _isHoveringPlatter,
          builder: (context, isHovering, _) {
            final bool isActiveGlow =
                isHovering || widget.selectedItems.isNotEmpty;

            Widget containerWidget = AnimatedContainer(
              key: const Key('gourmet_order_table_container'),
              duration: const Duration(milliseconds: 250),
              width: 195.r,
              height: 195.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isDark
                    ? _LocalPalette.color07070f
                    : Colors.black.withValues(alpha: 0.02),
                border: Border.all(
                  color: ringColor.withValues(
                    alpha: isActiveGlow ? 0.75 : 0.25,
                  ),
                  width: isActiveGlow ? 3.5 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ringColor.withValues(
                      alpha: isActiveGlow ? 0.22 : 0.04,
                    ),
                    blurRadius: isActiveGlow ? 20 : 10,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glowing steam custom wave painter
                  if (widget.selectedItems.isNotEmpty)
                    Positioned.fill(
                      child: ClipOval(
                        child: AnimatedBuilder(
                          animation: widget.steamAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: SteamWavesPainter(
                                animationValue: widget.steamAnimation.value,
                                themeColor: ringColor,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Cloche cover icon/platter details
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isAnswered
                            ? ((widget.isCorrect ?? false)
                                  ? Icons.done_all_rounded
                                  : Icons.close_rounded)
                            : Icons.room_service_outlined,
                        key: const Key('gourmet_order_table_cloche_icon'),
                        color: ringColor.withValues(
                          alpha: isActiveGlow ? 0.95 : 0.70,
                        ),
                        size: 54.r,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        widget.isAnswered
                            ? ((widget.isCorrect ?? false)
                                  ? "ORDER COMPLETE"
                                  : "INCORRECT ORDER")
                            : "ORDER PLATTER",
                        key: const Key('gourmet_order_table_status_text'),
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          color: ringColor.withValues(
                            alpha: isActiveGlow ? 0.95 : 0.70,
                          ),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (widget.selectedItems.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Container(
                          key: const Key('gourmet_order_table_loaded_badge'),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: ringColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            "${widget.selectedItems.length} ${widget.selectedItems.length == 1 ? 'DISH SELECTED' : 'DISHES SELECTED'}",
                            softWrap: true,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: ringColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );

            if (!reduceMotion) {
              containerWidget = containerWidget
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.03, 1.03),
                    duration: 2.2.seconds,
                    curve: Curves.easeInOut,
                  );
            }

            return containerWidget;
          },
        );
      },
    );
  }
}
