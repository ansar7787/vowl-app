import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Draggable word cells available to be slotted into the cloze passage blank.
class ClozeTestFuelCells extends StatelessWidget {
  /// Candidate word options for the cloze test.
  final List<String> options;

  /// Theme accent color applied to cell borders and highlights.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// The currently slotted option text, or null if none.
  final String? dockedOption;

  /// Optional callback invoked when a word cell is tapped for quick docking.
  final void Function(String)? onTap;

  /// Creates a [ClozeTestFuelCells] widget.
  const ClozeTestFuelCells({
    super.key,
    required this.options,
    required this.color,
    required this.isDark,
    required this.dockedOption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: options.map((o) {
        final bool isAlreadyDocked = dockedOption == o;
        final bool isAnyDocked = dockedOption != null;
        return Opacity(
          opacity: isAnyDocked ? (isAlreadyDocked ? 0.2 : 0.45) : 1.0,
          child: IgnorePointer(
            ignoring: isAnyDocked,
            child: GestureDetector(
              onTap: () => onTap?.call(o),
              child: Draggable<String>(
                data: o,
                feedback: Material(
                  color: Colors.transparent,
                  child: _buildCellWidget(o, color, isDark, true),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _buildCellWidget(o, color, isDark, false),
                ),
                child: _buildCellWidget(o, color, isDark, false),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCellWidget(
    String text,
    Color color,
    bool isDark,
    bool isFeedback,
  ) {
    final bgColor = isDark ? const Color(0xFF1E212D) : Colors.white;
    final borderColor = isFeedback
        ? color
        : color.withValues(alpha: isDark ? 0.45 : 0.25);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Container(
      constraints: BoxConstraints(
        minWidth: 88.w,
        maxWidth: 160.w,
        minHeight: 48.h,
      ),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : color).withValues(
              alpha: isFeedback ? 0.35 : (isDark ? 0.2 : 0.08),
            ),
            blurRadius: isFeedback ? 18 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
