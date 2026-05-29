import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    final hapticService = di.sl<HapticService>();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8.w,
          runSpacing: 16.h,
          children: List.generate(words.length * 2 + 1, (index) {
            if (index % 2 == 1) {
              return Text(
                words[index ~/ 2],
                style: GoogleFonts.fredoka(
                  fontSize: 22.sp,
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

                  return Container(
                    width: isOccupied ? 90.w : 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      color: isOccupied
                          ? primaryColor.withValues(alpha: 0.1)
                          : (isHighlight
                              ? primaryColor.withValues(alpha: 0.2)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: isOccupied ? primaryColor : borderCol,
                        width: isHighlight || isOccupied ? 2 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: isOccupied
                          ? GestureDetector(
                              onTap: () {
                                if (isAnswered) return;
                                hapticService.selection();
                                onSlotReset();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  modifier,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ).animate().shimmer(duration: 2.seconds),
                            )
                          : (isHighlight
                              ? Icon(Icons.add, color: primaryColor, size: 18.r)
                              : null),
                    ),
                  )
                  .animate(target: isOccupied ? 1 : 0)
                  .scale(duration: 300.ms, curve: Curves.easeOutBack);
                },
              );
            }
          }),
        ),
      ),
    );
  }
}
