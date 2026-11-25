import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Unified tap + eager drag surface for the Mastery word grid.
///
/// Claims the pointer arena immediately on touch-down inside the grid so parent
/// scroll containers cannot steal vertical or diagonal letter-tracing swipes,
/// while still distinguishing clean stationary taps (`< 8dp`) for tap-to-trace.
class SynonymGridTraceDetector extends StatelessWidget {
  final Widget child;
  final ValueChanged<Offset> onTapAt;
  final ValueChanged<Offset> onDragStartAt;
  final ValueChanged<Offset> onDragUpdateAt;
  final VoidCallback onDragEnd;

  const SynonymGridTraceDetector({
    super.key,
    required this.child,
    required this.onTapAt,
    required this.onDragStartAt,
    required this.onDragUpdateAt,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        _BoardTraceGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<_BoardTraceGestureRecognizer>(
              () => _BoardTraceGestureRecognizer(),
              (instance) {
                instance
                  ..onTapAt = onTapAt
                  ..onDragStartAt = onDragStartAt
                  ..onDragUpdateAt = onDragUpdateAt
                  ..onDragEnd = onDragEnd;
              },
            ),
      },
      child: child,
    );
  }
}

class _BoardTraceGestureRecognizer extends OneSequenceGestureRecognizer {
  ValueChanged<Offset>? onTapAt;
  ValueChanged<Offset>? onDragStartAt;
  ValueChanged<Offset>? onDragUpdateAt;
  VoidCallback? onDragEnd;

  int? _activePointer;
  Offset? _downLocalPos;
  bool _hasEnteredDrag = false;

  static const double _dragThresholdPx = 8.0;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_activePointer != null) return;
    _activePointer = event.pointer;
    _downLocalPos = event.localPosition;
    _hasEnteredDrag = false;
    startTrackingPointer(event.pointer, event.transform);
    // Win immediately against ancestor VerticalDragGestureRecognizer (SingleChildScrollView).
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _activePointer) return;

    if (event is PointerMoveEvent) {
      final start = _downLocalPos;
      if (!_hasEnteredDrag && start != null) {
        if ((event.localPosition - start).distance >= _dragThresholdPx) {
          _hasEnteredDrag = true;
          onDragStartAt?.call(start);
          onDragUpdateAt?.call(event.localPosition);
        }
      } else if (_hasEnteredDrag) {
        onDragUpdateAt?.call(event.localPosition);
      }
    } else if (event is PointerUpEvent) {
      if (_hasEnteredDrag) {
        onDragEnd?.call();
      } else {
        onTapAt?.call(event.localPosition);
      }
      stopTrackingPointer(event.pointer);
      _resetPointerState();
    } else if (event is PointerCancelEvent) {
      if (_hasEnteredDrag) {
        onDragEnd?.call();
      }
      stopTrackingPointer(event.pointer);
      _resetPointerState();
    }
  }

  void _resetPointerState() {
    _activePointer = null;
    _downLocalPos = null;
    _hasEnteredDrag = false;
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _resetPointerState();
  }

  @override
  void dispose() {
    _resetPointerState();
    super.dispose();
  }

  @override
  String get debugDescription => 'synonymGridTrace';
}

/// Accessible `>= 48dp` compact pill button for Undo / Clear controls above grid.
class SynonymGridControlPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;

  const SynonymGridControlPill({
    super.key,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = enabled
        ? (isDark ? AppColors.slate100 : AppColors.slate800)
        : (isDark ? AppColors.slate600 : AppColors.slate400);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ScaleButton(
        debounceDuration: const Duration(milliseconds: 120),
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : AppColors.slate100,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isDark ? AppColors.slate700 : AppColors.slate300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14.sp, color: fg),
                SizedBox(width: 4.w),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
