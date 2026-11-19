import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Practice Phase screen for Medical Consult ("Patient-Doctor Dialogue Gym").
///
/// Gives learners rapid, low-stakes drills formulating accurate patient symptom
/// descriptions, drug history statements, and onset timelines under doctor inquiry.
class MedicalConsultPracticeScreen extends StatefulWidget {
  final int level;

  const MedicalConsultPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<MedicalConsultPracticeScreen> createState() =>
      _MedicalConsultPracticeScreenState();
}

class _MedicalConsultPracticeScreenState
    extends State<MedicalConsultPracticeScreen> {
  int _exerciseIndex = 0;
  int? _selectedOptionIndex;
  bool _hasChecked = false;
  int _score = 0;
  late List<Map<String, dynamic>> _quests;

  @override
  void initState() {
    super.initState();
    _quests = _fallbackQuests;
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/roleplay/medicalConsult_practice_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_l(\d+)_', caseSensitive: false).firstMatch(id);
        if (match != null) {
          return int.parse(match.group(1)!) == widget.level;
        }
        return false;
      }).toList();

      if (mounted && levelQuests.isNotEmpty) {
        setState(() {
          _quests = levelQuests;
        });
      } else if (mounted && rawQuests.isNotEmpty) {
        final startIdx = ((widget.level - 1) % 10) * 3;
        final sublist = rawQuests.skip(startIdx).take(3).toList();
        if (sublist.isNotEmpty) {
          setState(() {
            _quests = sublist;
          });
        }
      }
    } catch (_) {
      // Retain fallback quests on asset failure
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'mc_practice_fallback_1',
          'doctorQuestion':
              "Can you describe the pain in your shoulder and when it started?",
          'options': [
            "It's a sharp, catching pain when I lift my arm overhead that started three days ago after tennis practice.",
            "It just hurts really bad and I don't like it at all.",
            "My shoulder feels funny sometimes, maybe for a few weeks or days.",
          ],
          'correctAnswerIndex': 0,
          'clinicalScore': 5,
          'pitfallAvoided': 'Avoided vague descriptions and missing timeline details.',
          'explanation':
              "Stating the exact sensation ('sharp, catching'), the precise motion trigger ('lifting arm overhead'), and clear timeline ('three days ago') gives the doctor actionable diagnostic data.",
        },
        {
          'id': 'mc_practice_fallback_2',
          'doctorQuestion':
              "Do you have any allergies or adverse reactions to antibiotics?",
          'options': [
            "I think medicine makes me tired sometimes.",
            "Yes, I broke out in hives and facial swelling from Amoxicillin two years ago, so I avoid all penicillin derivatives.",
            "No, I never take any pills unless someone tells me to.",
          ],
          'correctAnswerIndex': 1,
          'clinicalScore': 5,
          'pitfallAvoided':
              'Avoided dismissing drug allergy history or confusing side effects with true allergies.',
          'explanation':
              "Clearly naming the specific medication ('Amoxicillin'), the allergic manifestation ('hives and facial swelling'), and the drug family ('penicillin') prevents life-threatening prescribing errors.",
        },
        {
          'id': 'mc_practice_fallback_3',
          'doctorQuestion':
              "How severe is your headache on a scale from 1 to 10, and what does it feel like?",
          'options': [
            "It's about a 7; it's a tight, band-like dull pressure wrapping around my entire forehead with no nausea.",
            "It's probably an 11 or 12, it's the worst thing ever in human history.",
            "I don't know numbers, it's just a regular headache.",
          ],
          'correctAnswerIndex': 0,
          'clinicalScore': 5,
          'pitfallAvoided': 'Avoided unrealistic hyperbolic ratings and unhelpful vagueness.',
          'explanation':
              "A calibrated rating (7/10) paired with anatomical description ('tight, band-like dull pressure wrapping around forehead') and negative symptom rule-out ('no nausea') accurately points to tension-type cephalalgia.",
        },
      ];

  void _playAudio(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text);
      }
    } catch (_) {}
  }

  void _onOptionSelected(int index) {
    if (_hasChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().selection();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playClick();
      }
    } catch (_) {}
  }

  void _onCheck() {
    if (_selectedOptionIndex == null || _hasChecked) return;

    final current = _quests[_exerciseIndex.clamp(0, _quests.length - 1)];
    final correctIdx = current['correctAnswerIndex'] as int? ?? 0;
    final isCorrect = _selectedOptionIndex == correctIdx;

    setState(() {
      _hasChecked = true;
      if (isCorrect) {
        _score += 100;
      }
    });

    try {
      if (di.sl.isRegistered<HapticService>()) {
        if (isCorrect) {
          di.sl<HapticService>().success();
        } else {
          di.sl<HapticService>().error();
        }
      }
      if (di.sl.isRegistered<SoundService>()) {
        if (isCorrect) {
          di.sl<SoundService>().playCorrect();
        } else {
          di.sl<SoundService>().playWrong();
        }
      }
    } catch (_) {}
  }

  void _onContinue() {
    if (_exerciseIndex < _quests.length - 1) {
      setState(() {
        _exerciseIndex++;
        _selectedOptionIndex = null;
        _hasChecked = false;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'medicalConsult',
        level: widget.level,
        phase: 'practice',
      );
      try {
        context.pushReplacement(
          '/game?category=roleplay&gameType=medicalConsult&level=${widget.level}',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _quests[_exerciseIndex.clamp(0, _quests.length - 1)];
    final question = current['doctorQuestion'] as String? ?? '';
    final options = (current['options'] as List<dynamic>? ?? []).cast<String>();
    final correctIdx = current['correctAnswerIndex'] as int? ?? 0;
    final pitfallAvoided = current['pitfallAvoided'] as String? ?? '';
    final explanation = current['explanation'] as String? ?? '';
    final isCorrect = _selectedOptionIndex == correctIdx;

    return PracticePhaseScaffold(
      title: 'Medical Consult',
      gameType: 'medicalConsult',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex + 1,
      totalExercises: _quests.length,
      onComplete: _onContinue,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Doctor Inquiry Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.rose500.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rose500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.medical_services_rounded,
                              size: 14.sp,
                              color: AppColors.rose500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'CLINICAL CONSULTATION',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.rose500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emerald500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'SCORE: $_score',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emerald500,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('practice_audio_button'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.rose500,
                          size: 20.sp,
                        ),
                        onPressed: () => _playAudio(question),
                        tooltip: 'Listen to doctor inquiry',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '"$question"',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate100,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Prompt instructions
            Text(
              'Select the most accurate patient description:',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.slate100.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 10.h),

            // Options List
            ...List.generate(options.length, (index) {
              final optionText = options[index];
              final isSelected = _selectedOptionIndex == index;
              final isThisCorrect = index == correctIdx;

              Color borderColor = AppColors.slate800;
              Color bgColor = AppColors.slate900;
              Color textColor = AppColors.slate100;

              if (_hasChecked) {
                if (isThisCorrect) {
                  borderColor = AppColors.emerald500;
                  bgColor = AppColors.emerald500.withValues(alpha: 0.15);
                  textColor = AppColors.emerald500;
                } else if (isSelected) {
                  borderColor = AppColors.rose500;
                  bgColor = AppColors.rose500.withValues(alpha: 0.15);
                  textColor = AppColors.rose500;
                }
              } else if (isSelected) {
                borderColor = AppColors.indigo500;
                bgColor = AppColors.indigo500.withValues(alpha: 0.15);
                textColor = AppColors.indigo500;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: InkWell(
                  key: Key('practice_option_$index'),
                  onTap: () => _onOptionSelected(index),
                  borderRadius: BorderRadius.circular(12.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected || (_hasChecked && isThisCorrect) ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26.r,
                          height: 26.r,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected || (_hasChecked && isThisCorrect)
                                ? borderColor.withValues(alpha: 0.2)
                                : AppColors.slate800,
                          ),
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: textColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (_hasChecked && isThisCorrect)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.emerald500,
                            size: 20.sp,
                          )
                        else if (_hasChecked && isSelected)
                          Icon(
                            Icons.cancel_rounded,
                            color: AppColors.rose500,
                            size: 20.sp,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 8.h),

            // Check Answer Button
            if (!_hasChecked)
              ElevatedButton(
                key: const Key('practice_check_button'),
                onPressed: _selectedOptionIndex != null ? _onCheck : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rose500,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.slate800,
                  disabledForegroundColor: AppColors.slate100.withValues(alpha: 0.3),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'CONFIRM STATEMENT',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),

            // Feedback Card
            if (_hasChecked) ...[
              Container(
                key: const Key('practice_explanation_card'),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isCorrect
                        ? AppColors.emerald500.withValues(alpha: 0.4)
                        : AppColors.rose500.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          color: isCorrect ? AppColors.emerald500 : AppColors.amber500,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            isCorrect ? 'ACCURATE CLINICAL STATEMENT!' : 'CLINICAL FEEDBACK',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: isCorrect ? AppColors.emerald500 : AppColors.amber500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.slate100,
                        height: 1.4,
                      ),
                    ),
                    if (pitfallAvoided.isNotEmpty) ...[
                      SizedBox(height: 10.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            size: 15.sp,
                            color: AppColors.amber500,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              pitfallAvoided,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.slate100.withValues(alpha: 0.85),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              ElevatedButton(
                key: const Key('practice_continue_button'),
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrect ? AppColors.emerald500 : AppColors.rose500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  _exerciseIndex == _quests.length - 1 ? 'COMPLETE PRACTICE' : 'NEXT QUESTION',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
