import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'word_formation_colors.dart';

/// Interactive discovery compass card used in Learn phase to explore 4-way morphological shifts.
class WordFormationLearnCompass extends StatefulWidget {
  final Map<String, dynamic> northNoun;
  final Map<String, dynamic> eastAdjective;
  final Map<String, dynamic> southAdverb;
  final Map<String, dynamic> westOpposite;
  final Color primaryColor;

  const WordFormationLearnCompass({
    super.key,
    required this.northNoun,
    required this.eastAdjective,
    required this.southAdverb,
    required this.westOpposite,
    required this.primaryColor,
  });

  @override
  State<WordFormationLearnCompass> createState() =>
      _WordFormationLearnCompassState();
}

class _WordFormationLearnCompassState extends State<WordFormationLearnCompass> {
  String _activeDirection = 'north';

  Map<String, dynamic> get _activeData {
    switch (_activeDirection) {
      case 'east':
        return widget.eastAdjective;
      case 'south':
        return widget.southAdverb;
      case 'west':
        return widget.westOpposite;
      case 'north':
      default:
        return widget.northNoun;
    }
  }

  void _selectDirection(String dir) {
    if (_activeDirection != dir) {
      setState(() {
        _activeDirection = dir;
      });
      di.sl<HapticService>().selection();
      final word = _activeData['word']?.toString() ?? '';
      if (word.isNotEmpty) {
        di.sl<TtsService>().speak(word);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _activeData;
    final activeWord = (active['word'] as String? ?? '').toUpperCase();
    final activeRole = (active['role'] as String? ?? '').toUpperCase();
    final activeRule = active['rule'] as String? ?? '';
    final activeExample = active['example'] as String? ?? '';
    final activeColor = WordFormationColors.forDirection(_activeDirection);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 4-Way Compass Switcher Chips with distinct role hues
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRoleChip(
                  direction: 'north',
                  label: 'NOUN',
                  icon: Icons.north_rounded,
                  color: WordFormationColors.northNoun,
                ),
                SizedBox(width: 8.w),
                _buildRoleChip(
                  direction: 'east',
                  label: 'ADJECTIVE',
                  icon: Icons.east_rounded,
                  color: WordFormationColors.eastAdjective,
                ),
                SizedBox(width: 8.w),
                _buildRoleChip(
                  direction: 'south',
                  label: 'ADVERB',
                  icon: Icons.south_rounded,
                  color: WordFormationColors.southAdverb,
                ),
                SizedBox(width: 8.w),
                _buildRoleChip(
                  direction: 'west',
                  label: 'OPPOSITE',
                  icon: Icons.west_rounded,
                  color: WordFormationColors.westOpposite,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Active Morph Display
          Container(
            key: ValueKey(_activeDirection),
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: activeColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        activeRole,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ScaleButton(
                      onTap: () {
                        if (activeWord.isNotEmpty) {
                          di.sl<TtsService>().speak(activeWord);
                        }
                      },
                      child: Icon(
                        Icons.volume_up_rounded,
                        color: activeColor,
                        size: 20.r,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  activeWord,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.slate900,
                    letterSpacing: 1.5,
                  ),
                ),
                if (activeRule.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_fix_high_rounded,
                        color: activeColor,
                        size: 14.r,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          activeRule,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: activeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (activeExample.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    '"$activeExample"',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.05, end: 0),
        ],
      ),
    );
  }

  Widget _buildRoleChip({
    required String direction,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _activeDirection == direction;

    return ScaleButton(
      onTap: () => _selectDirection(direction),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.28),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13.r,
              color: isSelected ? Colors.white : color,
            ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
