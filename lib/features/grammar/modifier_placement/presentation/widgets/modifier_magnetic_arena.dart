import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class ModifierMagneticArena extends StatelessWidget {
  final List<String> words;
  final String modifier;
  final int targetIndex;
  final bool isAnswered;
  final bool isDark;
  final Color primaryColor;
  final ValueChanged<int> onSlotAccepted;
  final VoidCallback onSlotReset;
  final bool isCompact;

  const ModifierMagneticArena({
    super.key,
    required this.words,
    required this.modifier,
    required this.targetIndex,
    required this.isAnswered,
    required this.isDark,
    required this.primaryColor,
    required this.onSlotAccepted,
    required this.onSlotReset,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = di.sl<HapticService>();
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return SingleChildScrollView(
      key: const ValueKey('modifier_magnetic_arena'),
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: isCompact ? 8.h : 14.h,
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: isCompact ? 6.w : 8.w,
          runSpacing: isCompact ? 10.h : 14.h,
          children: List.generate(words.length * 2 + 1, (index) {
            if (index % 2 == 1) {
              return Text(
                words[index ~/ 2],
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isCompact ? 15.sp : 17.5.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.3,
                ),
              );
            } else {
              final slotIndex = index ~/ 2;
              final isOccupied = targetIndex == slotIndex;

              return DragTarget<String>(
                onWillAcceptWithDetails: (_) => !isAnswered,
                onAcceptWithDetails: (details) {
                  hapticService.selection();
                  onSlotAccepted(slotIndex);
                },
                builder: (context, candidateData, rejectedData) {
                  final isHighlight = candidateData.isNotEmpty;
                  final borderCol = isHighlight
                      ? primaryColor
                      : primaryColor.withValues(alpha: 0.2);

                  final double? slotWidth = isOccupied
                      ? null
                      : (isCompact ? 34.r : 44.r);
                  final double? slotHeight = isOccupied
                      ? null
                      : (isCompact ? 28.r : 36.r);

                  return GestureDetector(
                    key: ValueKey('modifier_slot_$slotIndex'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (isAnswered) return;
                      hapticService.selection();
                      onSlotAccepted(slotIndex);
                    },
                    child: Semantics(
                      label: isOccupied
                          ? "Slot occupied by $modifier"
                          : "Empty slot for modifier",
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: slotWidth,
                        height: slotHeight,
                        decoration: BoxDecoration(
                          color: isOccupied
                              ? primaryColor.withValues(alpha: 0.12)
                              : (isHighlight
                                    ? primaryColor.withValues(alpha: 0.2)
                                    : primaryColor.withValues(alpha: 0.04)),
                          borderRadius: BorderRadius.circular(
                            isCompact ? 10.r : 14.r,
                          ),
                          border: Border.all(
                            color: isOccupied ? primaryColor : borderCol,
                            width: isHighlight || isOccupied ? 1.8 : 1.2,
                          ),
                        ),
                        child: Center(
                          widthFactor: 1.0,
                          heightFactor: 1.0,
                          child: isOccupied
                              ? GestureDetector(
                                  key: ValueKey(
                                    'modifier_occupied_chip_$slotIndex',
                                  ),
                                  onTap: () {
                                    if (isAnswered) return;
                                    hapticService.selection();
                                    onSlotReset();
                                  },
                                  child: reduceMotion
                                      ? Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isCompact ? 8.w : 12.w,
                                            vertical: isCompact ? 3.h : 5.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            borderRadius: BorderRadius.circular(
                                              isCompact ? 8.r : 10.r,
                                            ),
                                          ),
                                          child: Text(
                                            modifier,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: isCompact
                                                  ? 14.sp
                                                  : 16.5.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isCompact ? 8.w : 12.w,
                                            vertical: isCompact ? 3.h : 5.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            borderRadius: BorderRadius.circular(
                                              isCompact ? 8.r : 10.r,
                                            ),
                                          ),
                                          child: Text(
                                            modifier,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: isCompact
                                                  ? 14.sp
                                                  : 16.5.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ).animate().shimmer(
                                          duration: 2.seconds,
                                        ),
                                )
                              : (isHighlight
                                    ? Icon(
                                        Icons.add_rounded,
                                        color: primaryColor,
                                        size: isCompact ? 14.r : 18.r,
                                      )
                                    : null),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          }),
        ),
      ),
    );
  }
}
