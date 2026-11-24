import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/controllers/prefix_suffix_controller.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_clue_banner.dart';

/// Practice Phase Screen for Prefix & Suffix: "Vault Combination Cracker".
///
/// Features:
/// - Contextual missions where learners test affixes against a root word.
/// - Mechanical jamming feedback on invalid combinations with zero heart penalty.
/// - Vault unlatching on valid morphological alignment.
class PrefixSuffixPracticeScreen extends StatefulWidget {
  final int level;

  const PrefixSuffixPracticeScreen({super.key, required this.level});

  @override
  State<PrefixSuffixPracticeScreen> createState() =>
      _PrefixSuffixPracticeScreenState();
}

class _PrefixSuffixPracticeScreenState
    extends State<PrefixSuffixPracticeScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _rawQuests = [];
  bool _isLoading = true;
  late final PrefixSuffixController _controller;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _controller = PrefixSuffixController();
    _loadCurriculum();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _batchStart => ((widget.level - 1) ~/ 10) * 10 + 1;
  int get _batchEnd => _batchStart + 9;

  Future<void> _loadCurriculum() async {
    final batchFile =
        'assets/curriculum/vocabulary/prefixSuffix_practice_${_batchStart}_$_batchEnd.json';
    try {
      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final quests = (data['quests'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final filtered = quests
          .where((q) => (q['level'] as int? ?? widget.level) == widget.level)
          .toList();

      if (mounted) {
        setState(() {
          _rawQuests = filtered.isNotEmpty ? filtered : _buildFallbackQuests();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _rawQuests = _buildFallbackQuests();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildFallbackQuests() => [
    {
      'id': 'VOC_PS_P_L${widget.level}_Q1',
      'level': widget.level,
      'rootWord': 'VIEW',
      'rootMeaning': 'To look at or inspect',
      'correctAnswer': 'PRE-',
      'options': ['PRE-', 'RE-', 'UN-', 'DIS-'],
      'contextSentence': 'We watched the movie {{gap}} before the film began.',
      'hint': 'Means before or in advance.',
      'explanation': 'PRE- combines with VIEW to create PREVIEW.',
    },
  ];

  void _onAffixSelected(String option, String correctAnswer) {
    if (_controller.isUnlocked) return;

    final isCorrect = _controller.slotAffix(option, correctAnswer);
    if (di.sl.isRegistered<HapticService>()) {
      if (isCorrect) {
        di.sl<HapticService>().selection();
      } else {
        di.sl<HapticService>().error();
      }
    }
  }

  void _completePhase() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'prefixSuffix',
      level: widget.level,
      phase: 'practice',
    );
    if (mounted) {
      context.pop();
    }
  }

  void _nextWord() {
    if (_currentIndex < _rawQuests.length - 1) {
      setState(() {
        _currentIndex++;
        _showHint = false;
        _controller.clearSlot();
      });
    } else {
      _completePhase();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ShimmerLoading.rounded(
              width: double.infinity,
              height: 380.h,
              borderRadius: 20,
            ),
          ),
        ),
      );
    }

    final questData = _rawQuests[_currentIndex];
    final rootWord = questData['rootWord'] as String? ?? 'WORD';
    final rootMeaning = questData['rootMeaning'] as String? ?? '';
    final contextSentence =
        questData['contextSentence'] as String? ??
        questData['clueSentence'] as String? ??
        questData['sentence'] as String? ??
        '';
    final correctAnswer =
        questData['correctAnswer'] as String? ??
        questData['targetAffix'] as String? ??
        '';
    final rawOptions =
        (questData['options'] as List<dynamic>?) ??
        (questData['tumblerWheelOptions'] as List<dynamic>?) ??
        [];
    final options = rawOptions.map((e) => e.toString()).toList();
    final hint = questData['hint'] as String? ?? '';
    final explanation =
        questData['explanation'] as String? ??
        questData['jamExplanation'] as String? ??
        '';

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isUnlocked = _controller.isUnlocked;
        final isJammed = _controller.isJammed;

        return PracticePhaseScaffold(
          title: 'Word Vault',
          gameType: 'prefixSuffix',
          level: widget.level,
          currentExerciseIndex: _currentIndex,
          totalExercises: _rawQuests.length,
          actionLabel: _currentIndex < _rawQuests.length - 1
              ? 'Next Question'
              : 'Finish Practice',
          isActionEnabled: isUnlocked,
          onComplete: isUnlocked ? _nextWord : () {},
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              children: [
                // Vault Clue Banner
                PrefixSuffixClueBanner(
                  rootWord: rootWord,
                  rootMeaning: rootMeaning,
                  contextSentence: contextSentence,
                  slottedAffix: _controller.slottedAffix,
                  isJammed: isJammed,
                  isUnlocked: isUnlocked,
                ),
                SizedBox(height: 18.h),

                // Dial Selection Prompt with Practice Reassurance
                Text(
                  isUnlocked
                      ? 'Word unlocked! Great job.'
                      : (isJammed
                            ? 'Not quite — no hearts lost, try another!'
                            : 'Select the matching affix:'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: isUnlocked
                        ? AppColors.emerald500
                        : (isJammed ? AppColors.amber500 : AppColors.slate400),
                  ),
                ),
                SizedBox(height: 14.h),

                // Affix Option Buttons
                Wrap(
                  spacing: 12.w,
                  runSpacing: 12.h,
                  alignment: WrapAlignment.center,
                  children: options.map((option) {
                    final isSelected = _controller.slottedAffix == option;
                    Color btnBorder = AppColors.slate700;
                    Color btnBg = AppColors.slate800;
                    Color textColor = AppColors.slate50;

                    if (isSelected && (isUnlocked || isJammed)) {
                      final activeColor = isUnlocked
                          ? AppColors.emerald500
                          : AppColors.red500;
                      btnBorder = activeColor;
                      btnBg = activeColor.withValues(alpha: 0.15);
                      textColor = activeColor;
                    }

                    return AnimatedScale(
                      scale: isSelected ? 1.03 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: SizedBox(
                        width: 130.w,
                        height: 48.h,
                        child: OutlinedButton(
                          onPressed: isUnlocked
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  _onAffixSelected(option, correctAnswer);
                                },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: btnBg,
                            side: BorderSide(color: btnBorder, width: 2.0),
                            elevation: isSelected ? 4 : 0,
                            shadowColor: btnBorder.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.h),

                // Pedagogical Explanation on unlock
                if (isUnlocked && explanation.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emerald500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.emerald500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      explanation,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: AppColors.emerald500,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                ],

                // Unlimited Hint Button
                if (!isUnlocked && hint.isNotEmpty) ...[
                  TextButton.icon(
                    onPressed: () {
                      _controller.useHint();
                      setState(() {
                        _showHint = true;
                      });
                    },
                    icon: Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18.sp,
                      color: AppColors.amber500,
                    ),
                    label: Text(
                      _showHint ? 'Hint: $hint' : 'Need a hint?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.amber500,
                      ),
                    ),
                  ),
                ],

                // Continue Button when unlocked
                if (isUnlocked) ...[
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: _nextWord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        _currentIndex < _rawQuests.length - 1
                            ? 'Next Question'
                            : 'Finish Practice',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      },
    );
  }
}
