import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// 3D Mechanical Tumbler Cylinder for the Prefix & Suffix Learn Phase ("Affix Tumbler Sandbox").
///
/// Simulates a precision combination dial using [ListWheelScrollView.useDelegate].
/// Features:
/// - 3D cylindrical perspective curvature with top/bottom fade gradients.
/// - Center crosshair focus reticle with illuminated active item.
/// - Haptic selection feedback on dial rotation.
class PrefixSuffixTumblerCylinder extends StatefulWidget {
  /// Items to display along the cylindrical tumbler barrel.
  final List<String> items;

  /// Currently selected index in [items].
  final int initialIndex;

  /// Callback when a new cylinder slot settles into focus.
  final ValueChanged<int> onSelectedItemChanged;

  /// Header title for the cylinder (e.g. "AFFIX DIAL" or "ROOT STEM").
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
  late FixedExtentScrollController _scrollController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _scrollController = FixedExtentScrollController(initialItem: _currentIndex);
  }

  @override
  void didUpdateWidget(covariant PrefixSuffixTumblerCylinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.initialIndex != widget.initialIndex) {
      final targetIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
      if (_currentIndex != targetIndex) {
        _currentIndex = targetIndex;
        if (_scrollController.hasClients) {
          _scrollController.jumpToItem(_currentIndex);
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.accentColor ?? AppColors.indigo500;
    final itemExtent = 52.h;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Dial Label Badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: themeColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            widget.title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: themeColor,
            ),
          ),
        ),
        SizedBox(height: 10.h),

        // 3D Cylinder Housing
        Container(
          height: 190.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.slate800,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.slate700, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Center Focus Reticle
              Positioned(
                left: 12.w,
                right: 12.w,
                height: itemExtent,
                child: Container(
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: themeColor, width: 1.5),
                  ),
                ),
              ),

              // Wheel Scroll View
              ListWheelScrollView.useDelegate(
                controller: _scrollController,
                itemExtent: itemExtent,
                perspective: 0.003,
                diameterRatio: 1.6,
                magnification: 1.15,
                useMagnifier: true,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: _handleItemChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: widget.items.length,
                  builder: (context, index) {
                    final isSelected = index == _currentIndex;
                    final itemText = widget.items[index];

                    return Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 150),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isSelected ? 18.sp : 14.sp,
                          fontWeight: isSelected
                              ? FontWeight.w900
                              : FontWeight.w600,
                          letterSpacing: 1.2,
                          color: isSelected
                              ? AppColors.slate50
                              : AppColors.slate500,
                        ),
                        child: Text(itemText),
                      ),
                    );
                  },
                ),
              ),

              // Top Vignette Gradient
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 50.h,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.slate800,
                          AppColors.slate800.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Vignette Gradient
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 50.h,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20.r),
                        bottomRight: Radius.circular(20.r),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.slate800,
                          AppColors.slate800.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
