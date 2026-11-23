import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Spatial 4-way morphological compass launcher (North: Noun, East: Adj, South: Adv, West: Opp).
class WordFormation4WayLauncher extends StatelessWidget {
  final String northWord;
  final String eastWord;
  final String southWord;
  final String westWord;
  final String? selectedDirection;
  final String? correctDirection;
  final bool isAnswered;
  final Color primaryColor;
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
    required this.onDirectionSelected,
  });

  void _handleSelect(String direction) {
    if (isAnswered) return;
    di.sl<HapticService>().selection();
    onDirectionSelected(direction);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (isAnswered) return;
        final vx = details.primaryVelocity ?? 0;
        if (vx > 250) {
          _handleSelect('east');
        } else if (vx < -250) {
          _handleSelect('west');
        }
      },
      onVerticalDragEnd: (details) {
        if (isAnswered) return;
        final vy = details.primaryVelocity ?? 0;
        if (vy < -250) {
          _handleSelect('north');
        } else if (vy > 250) {
          _handleSelect('south');
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NORTH: NOUN
            _buildPad(
              direction: 'north',
              icon: Icons.north_rounded,
              roleLabel: 'NOUN',
              word: northWord,
              isDark: isDark,
            ),
            SizedBox(height: 8.h),

            // MIDDLE ROW: WEST & EAST
            Row(
              children: [
                // WEST: OPPOSITE
                Expanded(
                  child: _buildPad(
                    direction: 'west',
                    icon: Icons.west_rounded,
                    roleLabel: 'OPPOSITE',
                    word: westWord,
                    isDark: isDark,
                  ),
                ),
                SizedBox(width: 8.w),

                // EAST: ADJECTIVE
                Expanded(
                  child: _buildPad(
                    direction: 'east',
                    icon: Icons.east_rounded,
                    roleLabel: 'ADJECTIVE',
                    word: eastWord,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // SOUTH: ADVERB
            _buildPad(
              direction: 'south',
              icon: Icons.south_rounded,
              roleLabel: 'ADVERB',
              word: southWord,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPad({
    required String direction,
    required IconData icon,
    required String roleLabel,
    required String word,
    required bool isDark,
  }) {
    final isSelected = selectedDirection == direction;
    final isTargetCorrect = correctDirection == direction;

    Color borderColor = primaryColor.withValues(alpha: 0.22);
    Color bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    if (isAnswered) {
      if (isSelected) {
        if (isTargetCorrect) {
          borderColor = AppColors.gameCorrect;
          bgColor = AppColors.gameCorrect.withValues(alpha: 0.15);
        } else {
          borderColor = AppColors.gameIncorrect;
          bgColor = AppColors.gameIncorrect.withValues(alpha: 0.15);
        }
      } else if (isTargetCorrect) {
        borderColor = AppColors.gameCorrect;
        bgColor = AppColors.gameCorrect.withValues(alpha: 0.1);
      }
    }

    return ScaleButton(
      onTap: () => _handleSelect(direction),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.5),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: borderColor.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryColor, size: 14.r),
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
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                        letterSpacing: 0.8,
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
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.slate900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
