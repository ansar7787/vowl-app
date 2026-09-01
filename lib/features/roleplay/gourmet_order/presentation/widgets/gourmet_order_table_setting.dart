import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_steam_painter.dart';

class GourmetOrderTableSetting extends StatefulWidget {
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;
  final List<String> selectedItems;
  final Animation<double> steamAnimation;
  final Function(String) onItemTapped;
  final VoidCallback onHapticFeedback;

  const GourmetOrderTableSetting({
    super.key,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.isCorrect,
    required this.selectedItems,
    required this.steamAnimation,
    required this.onItemTapped,
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
    Color ringColor = widget.color;
    if (widget.isAnswered) {
      ringColor = (widget.isCorrect ?? false)
          ? Colors.greenAccent
          : Colors.redAccent;
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (data) => !widget.isAnswered,
      onAcceptWithDetails: (details) {
        widget.onItemTapped(details.data);
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
            final bool isActiveGlow = isHovering || widget.selectedItems.isNotEmpty;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 210.r,
              height: 210.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isDark
                    ? const Color(0xFF07070F)
                    : Colors.black.withValues(alpha: 0.02),
                border: Border.all(
                  color: ringColor.withValues(alpha: isActiveGlow ? 0.75 : 0.2),
                  width: isActiveGlow ? 4.5 : 2.5,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isAnswered
                            ? ((widget.isCorrect ?? false)
                                  ? Icons.done_all_rounded
                                  : Icons.close_rounded)
                            : Icons.room_service_outlined,
                        color: ringColor.withValues(
                          alpha: isActiveGlow ? 0.9 : 0.25,
                        ),
                        size: 72.r,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        widget.isAnswered
                            ? ((widget.isCorrect ?? false)
                                  ? "SERVED PERFECTLY"
                                  : "WRONG DISHES")
                            : "SERVING PLATTER",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          color: ringColor.withValues(
                            alpha: isActiveGlow ? 0.9 : 0.35,
                          ),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (widget.selectedItems.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: ringColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            "${widget.selectedItems.length} PLATES LOADED",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              color: ringColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.03, 1.03),
              duration: 2.2.seconds,
              curve: Curves.easeInOut,
            );
          },
        );
      },
    );
  }
}
