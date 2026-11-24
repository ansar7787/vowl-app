import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'word_formation_colors.dart';

/// Spatial 4-way morphological compass launcher.
///
/// Binds North (Noun), East (Adjective), South (Adverb), and West (Opposite)
/// with tactile swipe gestures, distinct sensory color identities, and
/// high-fidelity selection feedback.
class WordFormation4WayLauncher extends StatefulWidget {
  final String northWord;
  final String eastWord;
  final String southWord;
  final String westWord;
  final String? selectedDirection;
  final String? correctDirection;
  final bool isAnswered;
  final Color primaryColor;
  final int comboStreak;
  final ValueChanged<String> onDirectionSelected;

  const WordFormation4WayLauncher({
    super.key,
    required this.northWord,
    required this.eastWord,
    required this.southWord,
    required this.westWord,
    this.selectedDirection,
    this.correctDirection,
    required this.isAnswered,
    required this.primaryColor,
    this.comboStreak = 0,
    required this.onDirectionSelected,
  });

  @override
  State<WordFormation4WayLauncher> createState() =>
      _WordFormation4WayLauncherState();
}

class _WordFormation4WayLauncherState extends State<WordFormation4WayLauncher> {
  String? _dragTarget;
  Offset _dragAccumulator = Offset.zero;

  void _handleSelect(String direction) {
    if (widget.isAnswered) return;
    di.sl<HapticService>().selection();
    widget.onDirectionSelected(direction);
  }

  String _targetFromAngle(double angle) {
    if (angle >= -math.pi / 4 && angle < math.pi / 4) return 'east';
    if (angle >= math.pi / 4 && angle < 3 * math.pi / 4) return 'south';
    if (angle >= -3 * math.pi / 4 && angle < -math.pi / 4) return 'north';
    return 'west';
  }

  IconData _dragIcon(String dir) {
    switch (dir) {
      case 'north': return Icons.north_rounded;
      case 'east': return Icons.east_rounded;
      case 'south': return Icons.south_rounded;
      default: return Icons.west_rounded;
    }
  }

  void _handlePanStart(DragStartDetails details) {
    if (widget.isAnswered) return;
    _dragAccumulator = Offset.zero;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.isAnswered) return;
    _dragAccumulator += details.delta;
    if (_dragAccumulator.distanceSquared > 25 * 25) {
      final newTarget = _targetFromAngle(
        math.atan2(_dragAccumulator.dy, _dragAccumulator.dx),
      );
      if (_dragTarget != newTarget) {
        di.sl<HapticService>().selection();
        setState(() => _dragTarget = newTarget);
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (widget.isAnswered) return;
    final target = _dragTarget;
    setState(() {
      _dragTarget = null;
      _dragAccumulator = Offset.zero;
    });

    if (target != null) {
      _handleSelect(target);
      return;
    }

    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;
    if (vx * vx + vy * vy >= 150 * 150) {
      _handleSelect(_targetFromAngle(math.atan2(vy, vx)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NORTH: NOUN (Sky Blue)
            _buildPad(
              direction: 'north',
              icon: Icons.north_rounded,
              roleLabel: 'NOUN',
              word: widget.northWord,
              roleColor: WordFormationColors.northNoun,
              isDark: isDark,
            ),
            SizedBox(height: 8.h),

            // MIDDLE ROW: WEST (Purple) & CENTRAL MORPH HUB & EAST (Green)
            Row(
              children: [
                Expanded(
                  child: _buildPad(
                    direction: 'west',
                    icon: Icons.west_rounded,
                    roleLabel: 'OPPOSITE',
                    word: widget.westWord,
                    roleColor: WordFormationColors.westOpposite,
                    isDark: isDark,
                  ),
                ),
                SizedBox(width: 8.w),
                _buildCenterHub(isDark),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildPad(
                    direction: 'east',
                    icon: Icons.east_rounded,
                    roleLabel: 'ADJECTIVE',
                    word: widget.eastWord,
                    roleColor: WordFormationColors.eastAdjective,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // SOUTH: ADVERB (Amber)
            _buildPad(
              direction: 'south',
              icon: Icons.south_rounded,
              roleLabel: 'ADVERB',
              word: widget.southWord,
              roleColor: WordFormationColors.southAdverb,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterHub(bool isDark) {
    Color orbColor = widget.primaryColor;
    String? comboLabel;
    if (_dragTarget != null) {
      orbColor = WordFormationColors.forDirection(_dragTarget!);
    } else if (widget.comboStreak == 1) {
      orbColor = WordFormationColors.northNoun;
      comboLabel = '1x';
    } else if (widget.comboStreak == 2) {
      orbColor = WordFormationColors.southAdverb;
      comboLabel = '2x';
    } else if (widget.comboStreak >= 3) {
      orbColor = const Color(0xFFEAB308);
      comboLabel = '${widget.comboStreak}x';
    }

    return Container(
      width: 42.r,
      height: 42.r,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : orbColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: orbColor.withValues(
            alpha: (_dragTarget != null || widget.comboStreak > 0) ? 0.75 : 0.28,
          ),
          width: (_dragTarget != null || widget.comboStreak >= 2) ? 2.2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: orbColor.withValues(
              alpha: _dragTarget != null ? 0.5 : (widget.comboStreak >= 2 ? 0.4 : 0.12),
            ),
            blurRadius: _dragTarget != null ? 14 : (widget.comboStreak >= 3 ? 16 : 8),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: _dragTarget != null
            ? Icon(_dragIcon(_dragTarget!), color: orbColor, size: 20.r)
            : (comboLabel != null
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      comboLabel,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: orbColor,
                      ),
                    ),
                  )
                : Icon(
                    Icons.explore_rounded,
                    color: widget.primaryColor,
                    size: 20.r,
                  )),
      ),
    );
  }

  Widget _buildPad({
    required String direction,
    required IconData icon,
    required String roleLabel,
    required String word,
    required Color roleColor,
    required bool isDark,
  }) {
    final isSelected = widget.selectedDirection == direction;
    final isTargetCorrect = widget.correctDirection == direction;
    final isDragged = _dragTarget == direction;

    Color borderColor = isDragged
        ? roleColor
        : roleColor.withValues(alpha: 0.28);
    Color bgColor = isDragged
        ? roleColor.withValues(alpha: 0.18)
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02));
    double opacity = 1.0;
    Widget? trailingStatus;

    if (widget.isAnswered) {
      if (isSelected) {
        borderColor = isTargetCorrect
            ? AppColors.gameCorrect
            : AppColors.gameIncorrect;
        bgColor = borderColor.withValues(alpha: 0.18);
        trailingStatus = Icon(
          isTargetCorrect
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded,
          color: borderColor,
          size: 18.r,
        );
      } else if (isTargetCorrect) {
        borderColor = AppColors.gameCorrect;
        bgColor = AppColors.gameCorrect.withValues(alpha: 0.12);
        trailingStatus = Icon(
          Icons.check_rounded,
          color: AppColors.gameCorrect,
          size: 18.r,
        );
      } else {
        opacity = 0.55;
      }
    } else if (isSelected && widget.correctDirection != null && !isTargetCorrect) {
      borderColor = AppColors.gameIncorrect;
      bgColor = AppColors.gameIncorrect.withValues(alpha: 0.15);
      trailingStatus = Icon(
        Icons.cancel_rounded,
        color: AppColors.gameIncorrect,
        size: 18.r,
      );
    }

    return Opacity(
      opacity: opacity,
      child: ScaleButton(
        onTap: () => _handleSelect(direction),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.0 : 1.5,
            ),
            boxShadow: [
              if (isSelected || isDragged)
                BoxShadow(
                  color: (isDragged ? roleColor : borderColor).withValues(
                    alpha: isDragged ? 0.35 : 0.25,
                  ),
                  blurRadius: isDragged ? 14 : 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(5.r),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: roleColor, size: 14.r),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: roleColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        word.toUpperCase(),
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.slate900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingStatus != null) ...[
                SizedBox(width: 4.w),
                trailingStatus,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
