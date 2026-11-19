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

/// Interactive Practice Phase screen for Travel Desk ("Airport & Transit Crisis Gym").
///
/// Drills learners on real-time transit desk responses, customs inquiries,
/// missing baggage claim protocols, and high-speed rail ticket regulations.
class TravelDeskPracticeScreen extends StatefulWidget {
  final int level;

  const TravelDeskPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<TravelDeskPracticeScreen> createState() =>
      _TravelDeskPracticeScreenState();
}

class _TravelDeskPracticeScreenState extends State<TravelDeskPracticeScreen> {
  int _exerciseIndex = 0;
  int? _selectedOptionIndex;
  bool _hasChecked = false;
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
        'assets/curriculum/roleplay/travelDesk_practice_${startLevel}_$endLevel.json';

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

      if (levelQuests.isNotEmpty && mounted) {
        setState(() {
          _quests = levelQuests;
        });
      }
    } catch (_) {
      // Fallback quests maintain continuity during testing or missing assets.
    }
  }

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
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().light();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playClick();
      }
    } catch (_) {}

    if (_exerciseIndex < _quests.length - 1) {
      setState(() {
        _exerciseIndex++;
        _selectedOptionIndex = null;
        _hasChecked = false;
      });
    } else {
      _markCompleteAndNavigate();
    }
  }

  void _markCompleteAndNavigate() {
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().success();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playCorrect();
      }
    } catch (_) {}

    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'travelDesk',
      level: widget.level,
      phase: 'practice',
    );

    try {
      context.pushReplacement(
        '/game?category=roleplay&gameType=travelDesk&level=${widget.level}',
      );
    } catch (_) {}
  }

  static final List<Map<String, dynamic>> _fallbackQuests = [
    {
      'id': 'td_practice_l1_q1',
      'level': 1,
      'travelContext': 'AIRPORT CHECK-IN & BAGGAGE ROUTING',
      'travelerPrompt':
          'My connection in Frankfurt departs in 45 minutes from Concourse B. Can my bags be checked straight through to Berlin?',
      'travelDocument': 'Baggage Claim Stub & Boarding Pass',
      'question': 'How should the check-in agent instruct the passenger with a tight connection?',
      'options': [
        'Certainly! I have checked your luggage straight through to Berlin. Here are your passes; please take the expedited transit lane to Concourse B Gate 14.',
        'You have 45 minutes, run to baggage claim in Frankfurt and re-check it yourself.',
        'Just go to the gate and ask someone there if your bags made it.',
      ],
      'correctAnswerIndex': 0,
      'correctAnswer':
          'Certainly! I have checked your luggage straight through to Berlin. Here are your passes; please take the expedited transit lane to Concourse B Gate 14.',
      'explanation':
          'Confirming through-check baggage routing and providing clear concourse directions with expedited lane access is exemplary desk service.',
      'deskScore': 5,
    },
    {
      'id': 'td_practice_l1_q2',
      'level': 1,
      'travelContext': 'BORDER CONTROL & CUSTOMS DECLARATION',
      'travelerPrompt':
          'I am traveling with vacuum-packed cured ham and artisanal cheeses gifted by family. Do I need to declare these at customs?',
      'travelDocument': 'Customs Declaration Card',
      'question': 'Select the most professional border agent guidance regarding food items:',
      'options': [
        'If it is vacuum packed you do not need to tell anyone, just walk through.',
        'Yes, all cured meats and dairy products must be declared on your customs card so our biosecurity inspector can verify compliance.',
        'Food is strictly prohibited and you will be arrested if you bring it in.',
      ],
      'correctAnswerIndex': 1,
      'correctAnswer':
          'Yes, all cured meats and dairy products must be declared on your customs card so our biosecurity inspector can verify compliance.',
      'explanation':
          'Instructing the traveler to declare items on their customs form allows official agricultural screening without incurring penalties.',
      'deskScore': 5,
    },
    {
      'id': 'td_practice_l1_q3',
      'level': 1,
      'travelContext': 'PASSPORT CONTROL & TRANSIT VISAS',
      'travelerPrompt':
          'We have an 8-hour layover in Tokyo Narita before our Sydney flight. Can we exit the airport to visit the town without a pre-arranged visa?',
      'travelDocument': 'Biometric Passport & Onward Ticket',
      'question': 'What is the accurate travel advice for transit passengers seeking airport exit?',
      'options': [
        'Nobody is ever allowed to leave the airport on an international ticket.',
        'You can request a temporary Shore Pass at immigration with proof of onward departure within 72 hours and 6 months passport validity.',
        'You can just walk out through baggage exit without speaking to immigration.',
      ],
      'correctAnswerIndex': 1,
      'correctAnswer':
          'You can request a temporary Shore Pass at immigration with proof of onward departure within 72 hours and 6 months passport validity.',
      'explanation':
          'Accurately citing shore pass criteria (72 hours departure window and valid passport) enables safe transit exploration.',
      'deskScore': 5,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final current =
        _quests[_exerciseIndex.clamp(0, _quests.length - 1)];
    final travelContext =
        current['travelContext'] as String? ?? 'TRANSIT PROTOCOL';
    final travelerPrompt =
        current['travelerPrompt'] as String? ?? '';
    final travelDocument =
        current['travelDocument'] as String? ?? 'Travel Documents';
    final question =
        current['question'] as String? ?? 'Select the optimal desk response:';
    final options = (current['options'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final correctIdx = current['correctAnswerIndex'] as int? ?? 0;
    final explanation = current['explanation'] as String? ?? '';
    final isCorrect = _selectedOptionIndex == correctIdx;

    return PracticePhaseScaffold(
      title: 'Travel Desk Practice',
      gameType: 'travelDesk',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex,
      totalExercises: _quests.length,
      onComplete: _markCompleteAndNavigate,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Traveler Inquiry Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.cyan400.withValues(alpha: 0.35),
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
                    runSpacing: 6.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan400.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flight_takeoff_rounded,
                              size: 14.sp,
                              color: AppColors.cyan400,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'PASSENGER INQUIRY',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.cyan400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            constraints: BoxConstraints(maxWidth: 150.w),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.slate800,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              travelContext,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blue300,
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          IconButton(
                            key: const Key('practice_audio_button'),
                            icon: Icon(
                              Icons.volume_up_rounded,
                              size: 18.sp,
                              color: AppColors.cyan400,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _playAudio(travelerPrompt),
                            tooltip: 'Listen to inquiry',
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '"$travelerPrompt"',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate100,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.slate800.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: AppColors.cyan400.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.badge_rounded,
                          size: 13.sp,
                          color: AppColors.cyan400,
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            'DOCUMENT: $travelDocument',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: AppColors.blue300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Question Prompt
            Text(
              question,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.slate100,
              ),
            ),
            SizedBox(height: 12.h),

            // Options List
            ...List.generate(options.length, (idx) {
              final opt = options[idx];
              final isSelected = _selectedOptionIndex == idx;
              final isThisCorrect = idx == correctIdx;

              Color borderColor = AppColors.slate800;
              Color bgColor = AppColors.slate900;
              Color letterBgColor = AppColors.slate800;
              Color letterTextColor = AppColors.slate300;

              if (_hasChecked) {
                if (isThisCorrect) {
                  borderColor = AppColors.emerald500;
                  bgColor = AppColors.emerald500.withValues(alpha: 0.12);
                  letterBgColor = AppColors.emerald500;
                  letterTextColor = AppColors.white;
                } else if (isSelected && !isThisCorrect) {
                  borderColor = AppColors.rose500;
                  bgColor = AppColors.rose500.withValues(alpha: 0.12);
                  letterBgColor = AppColors.rose500;
                  letterTextColor = AppColors.white;
                }
              } else if (isSelected) {
                borderColor = AppColors.cyan400;
                bgColor = AppColors.cyan400.withValues(alpha: 0.1);
                letterBgColor = AppColors.cyan400;
                letterTextColor = AppColors.white;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('practice_option_$idx'),
                    onTap: _hasChecked ? null : () => _onOptionSelected(idx),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: borderColor,
                          width: (isSelected || (_hasChecked && isThisCorrect))
                              ? 2.0
                              : 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28.w,
                            height: 28.w,
                            decoration: BoxDecoration(
                              color: letterBgColor,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              String.fromCharCode(65 + idx),
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: letterTextColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              opt,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.slate100,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 14.h),

            // Check Answer Button
            if (!_hasChecked)
              ElevatedButton(
                key: const Key('practice_check_button'),
                onPressed: _selectedOptionIndex != null ? _onCheck : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan400,
                  disabledBackgroundColor:
                      AppColors.slate800.withValues(alpha: 0.5),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'CHECK RESPONSE',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: _selectedOptionIndex != null
                        ? AppColors.white
                        : AppColors.slate500,
                  ),
                ),
              ),

            // Explanation & Next Steps Card
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
                          isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          color: isCorrect
                              ? AppColors.emerald500
                              : AppColors.amber500,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            isCorrect
                                ? 'EXEMPLARY DESK PROTOCOL!'
                                : 'BORDER & TRANSIT FEEDBACK',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.amber500,
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
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              ElevatedButton(
                key: const Key('practice_continue_button'),
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isCorrect ? AppColors.emerald500 : AppColors.cyan400,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  _exerciseIndex == _quests.length - 1
                      ? 'ENTER CUSTOMS TERMINAL (MASTERY)'
                      : 'NEXT TRAVEL INQUIRY',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
