import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Affix Hub for the Prefix & Suffix Learn Phase ("Affix Tumbler Sandbox").
///
/// Features:
/// - Single-affix mode: Displays a focused, compact affix hero card without gesture conflicts.
/// - Multi-affix mode: Displays interactive horizontal selector chips allowing instant 1-tap switching.
/// - Full light mode and dark mode support.
/// - Haptic selection feedback on affix changes.
class PrefixSuffixTumblerCylinder extends StatefulWidget {
  /// Items to display along the cylinder / selector tray.
  final List<String> items;

  /// Currently selected index in [items].
  final int initialIndex;

  /// Callback when a new cylinder slot settles into focus.
  final ValueChanged<int> onSelectedItemChanged;

  /// Header title for the cylinder (e.g. "Choose Prefix" or "Choose Suffix").
  final String title;

  /// Optional accent theme color for this cylinder dial.
  final Color? accentColor;

  const PrefixSuffixTumblerCylinder({
    super.key,
    required this.items,
    this.initialIndex = 0,
    required this.onSelectedItemChanged,
    this.title = 'AFFIX DIAL',
    this.accentColor,
  });

  @override
  State<PrefixSuffixTumblerCylinder> createState() =>
      _PrefixSuffixTumblerCylinderState();
}

class _PrefixSuffixTumblerCylinderState
    extends State<PrefixSuffixTumblerCylinder> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.items.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.items.length - 1);
  }

  @override
  void didUpdateWidget(covariant PrefixSuffixTumblerCylinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.initialIndex != widget.initialIndex) {
      final targetIndex = widget.items.isEmpty
          ? 0
          : widget.initialIndex.clamp(0, widget.items.length - 1);
      if (_currentIndex != targetIndex) {
        setState(() {
          _currentIndex = targetIndex;
        });
      }
    }
  }

  void _handleItemChanged(int index) {
    if (index != _currentIndex && index >= 0 && index < widget.items.length) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex = index;
      });
      widget.onSelectedItemChanged(index);
    }
  }

  Widget _buildSingleAffixHero(String affix, Color themeColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppColors.slate800 : AppColors.slate200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: themeColor, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.22),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 14.sp,
                  color: themeColor,
                ),
                SizedBox(width: 6.w),
                Text(
                  affix,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: themeColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              'Combines with root below',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiAffixTray(Color themeColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppColors.slate800 : AppColors.slate200,
          width: 1.5,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < widget.items.length; i++) ...[
              _buildAffixChip(widget.items[i], i, themeColor, isDark),
              if (i < widget.items.length - 1) SizedBox(width: 8.w),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAffixChip(
    String item,
    int index,
    Color themeColor,
    bool isDark,
  ) {
    final isSelected = index == _currentIndex;
    final bg = isSelected
        ? themeColor.withValues(alpha: 0.16)
        : (isDark ? AppColors.slate800 : const Color(0xFFF1F5F9));
    final border = isSelected
        ? themeColor
        : (isDark ? AppColors.slate700 : AppColors.slate300);
    final text = isSelected
        ? themeColor
        : (isDark ? AppColors.slate400 : AppColors.slate600);

    return GestureDetector(
      onTap: () => _handleItemChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: border, width: isSelected ? 1.8 : 1.2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_circle_rounded, size: 13.sp, color: themeColor),
              SizedBox(width: 4.w),
            ],
            Text(
              item,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.8,
                color: text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = widget.accentColor ?? AppColors.indigo500;
    final isMulti = widget.items.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: themeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isMulti ? Icons.tune_rounded : Icons.auto_awesome_rounded,
                    size: 12.sp,
                    color: themeColor,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: themeColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isMulti) ...[
              SizedBox(width: 8.w),
              Text(
                'Tap to explore',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.slate400 : AppColors.slate600,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        if (isMulti)
          _buildMultiAffixTray(themeColor, isDark)
        else
          _buildSingleAffixHero(
            widget.items.isNotEmpty ? widget.items[0] : '',
            themeColor,
            isDark,
          ),
      ],
    );
  }
}
