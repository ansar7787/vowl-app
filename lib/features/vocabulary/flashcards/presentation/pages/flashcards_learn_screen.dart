import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Rich, interactive Learn Phase screen for Flashcards.
///
/// Teaches each target word in depth before the learner enters guided practice.
class FlashcardsLearnScreen extends StatefulWidget {
  final int level;

  const FlashcardsLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<FlashcardsLearnScreen> createState() => _FlashcardsLearnScreenState();
}

class _FlashcardsLearnScreenState extends State<FlashcardsLearnScreen> {
  List<PhasedQuest> _quests = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _loadLearnQuests();
  }

  Future<void> _loadLearnQuests() async {
    try {
      final batchIndex = ((widget.level - 1) ~/ 10) + 1;
      final startLevel = (batchIndex - 1) * 10 + 1;
      final endLevel = batchIndex * 10;
      final path =
          'assets/curriculum/vocabulary/flashcards_learn_${startLevel}_$endLevel.json';
      final jsonStr = await rootBundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);

      final levelQuests =
          batch.quests.where((q) => q.level == widget.level).toList();

      if (mounted) {
        setState(() {
          _quests = levelQuests.isNotEmpty ? levelQuests : batch.quests;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Graceful fallback quests if asset is missing
      if (mounted) {
        setState(() {
          _quests = [
            PhasedQuest(
              id: 'FALLBACK_L${widget.level}_1',
              level: widget.level,
              word: 'WELCOME',
              pronunciation: '/ˈwɛlkəm/',
              definition: 'Greeting used to welcome someone kindly.',
              example: 'Welcome to your Vowl learning session!',
              nativeTip: 'Warm and friendly across all contexts.',
              visualAnchor: '🤝 Open hands greeting a friend',
            ),
          ];
          _isLoading = false;
        });
      }
    }
  }

  void _speak(String text) {
    if (di.sl.isRegistered<TtsService>()) {
      di.sl<TtsService>().speak(text);
    }
  }

  void _nextWord() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
    } else {
      _finishLearnPhase();
    }
  }

  void _finishLearnPhase() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'flashcards',
      level: widget.level,
      phase: 'learn',
    );
    // Navigate to Practice Phase
    final target =
        '/practice?category=vocabulary&gameType=flashcards&level=${widget.level}';
    context.pushReplacement(target);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.slate950 : AppColors.slate50,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final quest = _quests.isNotEmpty ? _quests[_currentIndex] : null;
    if (quest == null) {
      return LearnPhaseScaffold(
        title: 'Word Discovery',
        gameType: 'flashcards',
        level: widget.level,
        onComplete: _finishLearnPhase,
        child: const Center(child: Text('No learning material available.')),
      );
    }

    final isLast = _currentIndex == _quests.length - 1;

    return LearnPhaseScaffold(
      title: 'Word ${_currentIndex + 1} of ${_quests.length}',
      gameType: 'flashcards',
      level: widget.level,
      actionLabel: isLast ? 'Start Practice ✋' : 'Next Word ➔',
      onComplete: _nextWord,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Word Card
            GestureDetector(
              onTap: () {
                setState(() => _isFlipped = !_isFlipped);
                if (quest.word != null) _speak(quest.word!);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: _isFlipped
                        ? AppColors.indigo500
                        : (isDark ? AppColors.slate800 : AppColors.slate200),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo500.withValues(alpha: 0.1),
                      blurRadius: 16.r,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Pronunciation and Audio
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          quest.word ?? '',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.slate900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        IconButton(
                          icon: Icon(
                            Icons.volume_up_rounded,
                            color: AppColors.indigo500,
                            size: 26.r,
                          ),
                          onPressed: () {
                            if (quest.word != null) _speak(quest.word!);
                          },
                          tooltip: 'Listen',
                        ),
                      ],
                    ),
                    if (quest.pronunciation != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        quest.pronunciation!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          color: AppColors.indigo400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    SizedBox(height: 16.h),
                    Divider(
                      color: isDark ? AppColors.slate800 : AppColors.slate100,
                    ),
                    SizedBox(height: 12.h),

                    // Definition
                    Text(
                      _isFlipped
                          ? (quest.definition ?? 'No definition available')
                          : 'Tap card to reveal definition',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        color: _isFlipped
                            ? (isDark ? AppColors.slate200 : AppColors.slate800)
                            : (isDark
                                ? AppColors.slate500
                                : AppColors.slate400),
                        fontStyle:
                            _isFlipped ? FontStyle.normal : FontStyle.italic,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Native Speaker Tip
            if (quest.nativeTip != null)
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡', style: TextStyle(fontSize: 20.sp)),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NATIVE SPEAKER TIP',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.amber.shade300
                                  : Colors.amber.shade800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            quest.nativeTip!,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              color: isDark
                                  ? AppColors.slate300
                                  : AppColors.slate800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 14.h),

            // In Action Example
            if (quest.example != null)
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IN REAL CONVERSATION',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.indigo500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '"${quest.example!}"',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15.sp,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? AppColors.slate200
                                  : AppColors.slate900,
                              height: 1.4,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.play_circle_outline_rounded,
                            color: AppColors.indigo500,
                            size: 24.r,
                          ),
                          onPressed: () => _speak(quest.example!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            SizedBox(height: 14.h),

            // Visual Anchor
            if (quest.visualAnchor != null)
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.slate900.withValues(alpha: 0.6)
                      : AppColors.slate100,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    Text('🧠', style: TextStyle(fontSize: 18.sp)),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        quest.visualAnchor!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Common Mistake Alert
            if (quest.commonMistake != null) ...[
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚠️', style: TextStyle(fontSize: 16.sp)),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PITFALL TO AVOID',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.red.shade400,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            quest.commonMistake!,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              color: isDark
                                  ? AppColors.slate300
                                  : AppColors.slate800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
