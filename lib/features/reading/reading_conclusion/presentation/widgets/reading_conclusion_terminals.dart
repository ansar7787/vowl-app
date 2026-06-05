import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class ReadingConclusionTerminals extends StatelessWidget {
  final List<String> options;
  final String correct;
  final Color color;
  final bool isDark;
  final int? selectedIndex;
  final bool isAnswered;
  final Function(int, String) onBridgeEnd;
  final Function(int, String) onSubmitTap;

  const ReadingConclusionTerminals({
    super.key,
    required this.options,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.selectedIndex,
    required this.isAnswered,
    required this.onBridgeEnd,
    required this.onSubmitTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        options.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: DragTarget<String>(
            onAcceptWithDetails: (details) => onBridgeEnd(index, options[index]),
            builder: (context, candidateData, rejectedData) {
              bool isSelected = selectedIndex == index;
              bool isCorrect = isAnswered && options[index].trim().toLowerCase() == correct.trim().toLowerCase();
              bool isWrong = isAnswered && isSelected && !isCorrect;

              return GestureDetector(
                onTap: () => onSubmitTap(index, options[index]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: EdgeInsets.all(18.r),
                  decoration: BoxDecoration(
                    color: isCorrect 
                        ? Colors.greenAccent.withValues(alpha: 0.25) 
                        : (isWrong 
                            ? Colors.redAccent.withValues(alpha: 0.25) 
                            : (isSelected ? color.withValues(alpha: 0.15) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)))),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isCorrect || isWrong || isSelected 
                          ? (isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : color)) 
                          : (isDark ? Colors.white24 : Colors.black12), 
                      width: 2,
                    ),
                  ),
                  child: Text(
                    options[index].toUpperCase(), 
                    textAlign: TextAlign.center, 
                    style: TextStyle(fontFamily: 'RobotoMono', 
                      fontSize: 12.sp, 
                      fontWeight: FontWeight.bold, 
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
