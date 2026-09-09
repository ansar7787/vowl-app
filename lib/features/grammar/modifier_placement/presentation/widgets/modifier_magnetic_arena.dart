import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: isCompact ? 8.h : 16.h,
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: isCompact ? 4.w : 8.w,
          runSpacing: isCompact ? 8.h : 16.h,
          children: List.generate(words.length * 2 + 1, (index) {
            if (index % 2 == 1) {
              return Text(
                words[index ~/ 2],
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isCompact ? 16.sp : 22.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
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
                      : primaryColor.withValues(alpha: 0.15);

                  final double? slotWidth = isOccupied
                      ? null
                      : (isCompact ? 36.r : 50.r);
                  final double? slotHeight = isOccupied
                      ? null
                      : (isCompact ? 30.r : 40.r);

                  return Semantics(
                    label: isOccupied
                        ? "Slot occupied by $modifier"
                        : "Empty slot to drop modifier",
                    child:
                        Container(
                              width: slotWidth,
                              height: slotHeight,
                              decoration: BoxDecoration(
                                color: isOccupied
                                    ? primaryColor.withValues(alpha: 0.1)
                                    : (isHighlight
                                          ? primaryColor.withValues(alpha: 0.2)
                                          : Colors.transparent),
                                borderRadius: BorderRadius.circular(
                                  isCompact ? 13.r : 18.r,
                                ),
                                border: Border.all(
                                  color: isOccupied ? primaryColor : borderCol,
                                  width: isHighlight || isOccupied ? 2 : 1.5,
                                ),
                              ),
                              child: Center(
                                widthFactor: 1.0,
                                heightFactor: 1.0,
                                child: isOccupied
                                    ? GestureDetector(
                                        onTap: () {
                                          if (isAnswered) return;
                                          hapticService.selection();
                                          onSlotReset();
                                        },
                                        child:
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isCompact
                                                    ? 6.w
                                                    : 10.w,
                                                vertical: isCompact ? 2.h : 4.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      isCompact ? 8.r : 12.r,
                                                    ),
                                              ),
                                              child: Text(
                                                modifier,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: isCompact
                                                      ? 10.sp
                                                      : 14.sp,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ).animate().shimmer(
                                              duration: 2.seconds,
                                            ),
                                      )
                                    : (isHighlight
                                          ? Icon(
                                              Icons.add,
                                              color: primaryColor,
                                              size: isCompact ? 12.r : 18.r,
                                            )
                                          : null),
                              ),
                            )
                            .animate(target: isHighlight ? 1 : 0)
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.15, 1.15),
                              duration: 200.ms,
                              curve: Curves.easeOutBack,
                            )
                            .animate(target: isOccupied ? 1 : 0)
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.05, 1.05),
                              duration: 300.ms,
                              curve: Curves.easeOutBack,
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
