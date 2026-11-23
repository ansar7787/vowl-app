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
class WordFormation4WayLauncher extends StatelessWidget {
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

  void _handleSelect(String direction) {
    if (isAnswered) return;
    di.sl<HapticService>().selection();
    onDirectionSelected(direction);
  }

  void _handlePanEnd(DragEndDetails details) {
    if (isAnswered) return;
    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;
    final speedSq = vx * vx + vy * vy;
    if (speedSq < 150 * 150) return;

    final angle = math.atan2(vy, vx);
    if (angle >= -math.pi / 4 && angle < math.pi / 4) {
      _handleSelect('east');
    } else if (angle >= math.pi / 4 && angle < 3 * math.pi / 4) {
      _handleSelect('south');
    } else if (angle >= -3 * math.pi / 4 && angle < -math.pi / 4) {
      _handleSelect('north');
    } else {
      _handleSelect('west');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
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
              word: northWord,
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
                    word: westWord,
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
                    word: eastWord,
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
              word: southWord,
              roleColor: WordFormationColors.southAdverb,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterHub(bool isDark) {
    Color orbColor = primaryColor;
    String? comboLabel;
    if (comboStreak == 1) {
      orbColor = WordFormationColors.northNoun;
      comboLabel = '1x';
    } else if (comboStreak == 2) {
      orbColor = WordFormationColors.southAdverb;
      comboLabel = '2x';
    } else if (comboStreak >= 3) {
      orbColor = const Color(0xFFEAB308);
      comboLabel = '3x 🔥';
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
          color: orbColor.withValues(alpha: comboStreak > 0 ? 0.7 : 0.28),
          width: comboStreak >= 2 ? 2.2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: orbColor.withValues(alpha: comboStreak >= 2 ? 0.4 : 0.12),
            blurRadius: comboStreak >= 3 ? 16 : (comboStreak >= 1 ? 10 : 8),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: comboLabel != null
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
                color: primaryColor,
                size: 20.r,
              ),
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
    final isSelected = selectedDirection == direction;
    final isTargetCorrect = correctDirection == direction;

    Color borderColor = roleColor.withValues(alpha: 0.28);
    Color bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.02);
    double opacity = 1.0;
    Widget? trailingStatus;

    if (isAnswered) {
      if (isSelected) {
        if (isTargetCorrect) {
          borderColor = AppColors.gameCorrect;
          bgColor = AppColors.gameCorrect.withValues(alpha: 0.18);
          trailingStatus = Icon(
            Icons.check_circle_rounded,
            color: AppColors.gameCorrect,
            size: 18.r,
          );
        } else {
          borderColor = AppColors.gameIncorrect;
          bgColor = AppColors.gameIncorrect.withValues(alpha: 0.18);
          trailingStatus = Icon(
            Icons.cancel_rounded,
            color: AppColors.gameIncorrect,
            size: 18.r,
          );
        }
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
              if (isSelected)
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.25),
                  blurRadius: 10,
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
