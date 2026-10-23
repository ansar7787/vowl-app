import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Stream list containing draggable candidates for email section slots.
class WritingEmailDataStream extends StatelessWidget {
  /// Complete list of email candidate segments.
  final List<String> items;

  /// Mapping of current slot positions to assigned sentence fragments.
  final Map<String, String?> slots;

  /// Theme accent color applied to chips and drag shadows.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Callback invoked when an item is tapped for fast placement.
  final Function(String) onTapItem;

  /// Creates a [WritingEmailDataStream] widget.
  const WritingEmailDataStream({
    super.key,
    required this.items,
    required this.slots,
    required this.color,
    required this.isDark,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    List<String> availableItems = List.from(items);
    for (var val in slots.values) {
      if (val != null) {
        availableItems.remove(val);
      }
    }

    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      constraints: BoxConstraints(minHeight: 80.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: availableItems
            .map(
              (i) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Semantics(
                  label: "Email part: $i",
                  hint: "Double tap to place in next available slot",
                  button: true,
                  child: GestureDetector(
                    key: Key('writing_email_option_$i'),
                    onTap: () => onTapItem(i),
                    child: Draggable<String>(
                      data: i,
                      feedback: Material(
                        color: Colors.transparent,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: screenWidth - 48.w,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(14.r),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              i,
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2230) : Colors.white,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: color.withValues(
                              alpha: isDark ? 0.35 : 0.25,
                            ),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(
                                alpha: isDark ? 0.2 : 0.06,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          i,
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.95)
                                : const Color(0xFF1E293B),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
