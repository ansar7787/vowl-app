import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
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
  final Map<String, String> _translatedExamples = {};
  final Map<String, String> _exampleLanguages = {};
  final Map<String, bool> _showTranslatedExample = {};

  @override
  void didUpdateWidget(covariant WordFormationLearnCompass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.northNoun != widget.northNoun) {
      _activeDirection = 'north';
      _translatedExamples.clear();
      _exampleLanguages.clear();
      _showTranslatedExample.clear();
    }
  }

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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.6,
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    activeWord,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.slate900,
                      letterSpacing: 0.8,
                    ),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _showTranslatedExample[_activeDirection] == true
                              ? () => setState(() =>
                                  _showTranslatedExample[_activeDirection] = false)
                              : null,
                          child: Text(
                            _showTranslatedExample[_activeDirection] == true &&
                                    _translatedExamples[_activeDirection] != null
                                ? '"${_translatedExamples[_activeDirection]}"'
                                : '"$activeExample"',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      TranslateButtonWidget(
                        originalText: activeExample,
                        onTranslationComplete: (t) => setState(() {
                          _translatedExamples[_activeDirection] = t;
                          _showTranslatedExample[_activeDirection] = true;
                        }),
                        onTranslationWithLanguage: (t, code) => setState(() {
                          _translatedExamples[_activeDirection] = t;
                          _exampleLanguages[_activeDirection] = code ?? '';
                          _showTranslatedExample[_activeDirection] = true;
                        }),
                        iconSize: 13.r,
                        iconColor: activeColor,
                        padding: EdgeInsets.all(2.r),
                      ),
                    ],
                  ),
                  if (_translatedExamples[_activeDirection] != null) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        ScaleButton(
                          onTap: () => setState(() => _showTranslatedExample[_activeDirection] =
                              !(_showTranslatedExample[_activeDirection] ?? false)),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: activeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(color: activeColor.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.undo_rounded, size: 10.r, color: activeColor),
                                SizedBox(width: 3.w),
                                Text(
                                  _showTranslatedExample[_activeDirection] == true ? 'Original (EN)' : 'Translated',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w700,
                                    color: activeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showTranslatedExample[_activeDirection] == true &&
                            _exampleLanguages[_activeDirection] != null &&
                            _exampleLanguages[_activeDirection]!.isNotEmpty) ...[
                          SizedBox(width: 6.w),
                          TtsSpeakerButtonWidget(
                            text: _translatedExamples[_activeDirection]!,
                            locale: _exampleLanguages[_activeDirection],
                            color: activeColor,
                            size: 13.r,
                          ),
                        ],
                      ],
                    ),
                  ],
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
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
