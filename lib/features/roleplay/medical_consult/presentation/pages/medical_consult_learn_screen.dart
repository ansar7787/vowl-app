import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Learn Phase screen for Medical Consult ("Symptom Expression Guide").
///
/// Educates learners on clinical vocabulary for articulating physical sensations,
/// onset chronologies, pain characteristics, and medication histories accurately.
class MedicalConsultLearnScreen extends StatefulWidget {
  final int level;

  const MedicalConsultLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<MedicalConsultLearnScreen> createState() =>
      _MedicalConsultLearnScreenState();
}

class _MedicalConsultLearnScreenState extends State<MedicalConsultLearnScreen> {
  int _currentIndex = 0;
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
        'assets/curriculum/roleplay/medicalConsult_learn_${startLevel}_$endLevel.json';

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
        final startIdx = ((widget.level - 1) % 10) * 4;
        final sublist = rawQuests.skip(startIdx).take(4).toList();
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
          'id': 'mc_learn_fallback_1',
          'doctorPrompt':
              'Can you describe the exact sensation you are feeling in your head?',
          'symptomType': 'THROBBING PAIN',
          'clinicalDescriptor':
              'Pulsating, rhythmic ache syncing with heartbeats, typical of vascular migraines or severe sinus pressure.',
          'onsetAndTimeline':
              'Gradual onset over 3 hours, aggravated by bright light or sudden movement.',
          'medicationPrecaution':
              'Avoid excessive caffeine; track whether NSAIDs alleviate or fail to reduce intensity.',
          'optimalResponse':
              "It's a rhythmic, throbbing pain behind my left temple that started about three hours ago and worsens in bright light.",
          'keyTakeaway':
              "Use precise sensory terms like 'throbbing' or 'pulsating' rather than general words like 'bad' or 'weird'.",
        },
        {
          'id': 'mc_learn_fallback_2',
          'doctorPrompt':
              'How would you characterize the discomfort in your lower abdomen?',
          'symptomType': 'DULL ACHE',
          'clinicalDescriptor':
              'Persistent, low-intensity discomfort without sharp spikes, often associated with muscular strain or mild visceral inflammation.',
          'onsetAndTimeline':
              'Constant low-grade discomfort for 48 hours, unaffected by eating or posture.',
          'medicationPrecaution':
              'Monitor for sudden escalation into localized sharp pain which could signal appendicitis.',
          'optimalResponse':
              "It's a continuous, dull ache across my lower stomach that has been steady for the last two days with no sudden spikes.",
          'keyTakeaway':
              "Clarify whether an ache is steady or intermittent, and note whether posture or food triggers changes.",
        },
      ];

  void _playAudio(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text);
      }
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().selection();
      }
    } catch (_) {}
  }

  void _onNext() {
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().light();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playClick();
      }
    } catch (_) {}

    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'medicalConsult',
        level: widget.level,
        phase: 'learn',
      );
      try {
        context.pushReplacement(
          '/game?category=roleplay&gameType=medicalConsult&level=${widget.level}&phase=practice',
        );
      } catch (_) {}
    }
  }

  Widget _buildClinicalPillarCard({
    required IconData icon,
    required String title,
    required String content,
    required Color accentColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.r,
            height: 28.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.2),
              border: Border.all(color: accentColor, width: 1.5),
            ),
            child: Icon(icon, size: 15.sp, color: accentColor),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: accentColor,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.slate100,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _quests[_currentIndex.clamp(0, _quests.length - 1)];
    final doctorPrompt = current['doctorPrompt'] as String? ?? '';
    final symptomType = current['symptomType'] as String? ?? 'SYMPTOM PROFILE';
    final clinicalDescriptor = current['clinicalDescriptor'] as String? ?? '';
    final onsetAndTimeline = current['onsetAndTimeline'] as String? ?? '';
    final medicationPrecaution = current['medicationPrecaution'] as String? ?? '';
    final optimalResponse = current['optimalResponse'] as String? ?? '';
    final keyTakeaway = current['keyTakeaway'] as String? ?? '';

    return LearnPhaseScaffold(
      title: 'Medical Consult',
      gameType: 'medicalConsult',
      level: widget.level,
      actionLabel:
          _currentIndex == _quests.length - 1 ? 'START PRACTICE' : 'NEXT SYMPTOM',
      onComplete: _onNext,
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
                  color: AppColors.rose500.withValues(alpha: 0.4),
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
                              'DOCTOR INQUIRY',
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
                          color: AppColors.indigo500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          symptomType,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.indigo500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '"$doctorPrompt"',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate100,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Clinical Profile Section
            Text(
              'CLINICAL PROFILE BREAKDOWN',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppColors.slate100.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 10.h),

            _buildClinicalPillarCard(
              icon: Icons.sensors_rounded,
              title: 'SENSATION CHARACTERISTIC',
              content: clinicalDescriptor,
              accentColor: AppColors.indigo500,
            ),
            _buildClinicalPillarCard(
              icon: Icons.access_time_rounded,
              title: 'ONSET & TIMELINE',
              content: onsetAndTimeline,
              accentColor: AppColors.amber500,
            ),
            _buildClinicalPillarCard(
              icon: Icons.medication_rounded,
              title: 'MEDICATION & PRECAUTIONS',
              content: medicationPrecaution,
              accentColor: AppColors.rose500,
            ),
            SizedBox(height: 8.h),

            // Model Consultation Delivery Card
            Container(
              key: const Key('medical_learn_optimal_card'),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.4),
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
                          color: AppColors.emerald500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 14.sp,
                              color: AppColors.emerald500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'OPTIMAL STATEMENT',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.emerald500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('medical_learn_audio_btn'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.emerald500,
                          size: 20.sp,
                        ),
                        onPressed: () => _playAudio(optimalResponse),
                        tooltip: 'Listen to patient statement',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.slate950,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      optimalResponse,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontStyle: FontStyle.italic,
                        color: AppColors.slate100,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Clinical Takeaway Card
            if (keyTakeaway.isNotEmpty) ...[
              Container(
                key: const Key('medical_learn_strategy_card'),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: AppColors.amber500,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CLINICAL TAKEAWAY',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.amber500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            keyTakeaway,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.slate100,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ],
        ),
      ),
    );
  }
}
