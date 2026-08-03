import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/social_spark/presentation/widgets/social_spark_instruction.dart';
import 'package:vowl/features/roleplay/social_spark/presentation/widgets/social_spark_connection_monitor.dart';
import 'package:vowl/features/roleplay/social_spark/presentation/widgets/social_spark_galaxy_board.dart';
import 'package:vowl/core/presentation/widgets/speak_to_confirm_overlay.dart';

class SocialSparkScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SocialSparkScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.socialSpark,
  });

  @override
  State<SocialSparkScreen> createState() => _SocialSparkScreenState();
}

class _SocialSparkScreenState extends State<SocialSparkScreen>
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late AnimationController _pulseController;

  int _lastProcessedIndex = -1;

  // Track selected words by their original shuffled index to support duplicate words flawlessly
  final List<int> _selectedIndices = [];

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  bool _phase1Passed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.instruction);
  }

  void _onStarTap(int index) {
    if (_isAnswered || _phase1Passed) return;
    _hapticService.selection();
    _soundService.playHint(); // Play little synth tap note

    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _clearSelection() {
    if (_isAnswered || _phase1Passed) return;
    _hapticService.selection();
    setState(() {
      _selectedIndices.clear();
    });
  }

  void _submitAnswer(List<String> shuffledWords, String correctAnswer) {
    if (_isAnswered || _phase1Passed || _selectedIndices.isEmpty) return;

    // Assemble sentence in correct tapped order
    final String result = _selectedIndices
        .map((idx) => shuffledWords[idx])
        .join(' ');

    // Sanitize punctuation comparisons cleanly
    final sanitizedResult = result.replaceAll(' ?', '?').trim().toLowerCase();
    final sanitizedAnswer = correctAnswer
        .replaceAll(' ?', '?')
        .trim()
        .toLowerCase();

    final bool isCorrect = sanitizedResult == sanitizedAnswer;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _phase1Passed = true;
      });
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitPhase2Evaluation(bool nailedIt) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listener: (context, state) {
        if (state is RoleplayLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndices.clear();
              _phase1Passed = false;
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'CONVERSATION STARTER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final words = quest?.shuffledWords ?? [];

        // Build active joined text representation
        final String currentText = _selectedIndices
            .map((idx) => words[idx])
            .join(' ');

        return Stack(
          children: [
            RoleplayBaseLayout(
              gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
          onHint: () => context.read<RoleplayBloc>().add(RoleplayHintUsed()),
          child: quest == null
              ? const SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxHeight < 580;
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: isCompact ? 5.h : 10.h,
                      ),
                      child: Column(
                        children: [
                          SocialSparkInstruction(
                            primaryColor: theme.primaryColor,
                            instruction: quest.instruction,
                          ),
                          SizedBox(height: isCompact ? 10.h : 16.h),

                          SocialSparkConnectionMonitor(
                            text: currentText,
                            color: theme.primaryColor,
                            isDark: isDark,
                            isAnswered: _isAnswered,
                            isCorrect: _isCorrect,
                          ),
                          SizedBox(height: isCompact ? 12.h : 20.h),

                          SocialSparkGalaxyBoard(
                            words: words,
                            color: theme.primaryColor,
                            isDark: isDark,
                            selectedIndices: _selectedIndices,
                            isAnswered: _isAnswered,
                            isCorrect: _isCorrect,
                            pulseValue: _pulseController.value,
                            onStarTap: _onStarTap,
                          ),
                          SizedBox(height: isCompact ? 12.h : 20.h),

                          // Trigger Action Buttons
                          if (!_isAnswered && _selectedIndices.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ScaleButton(
                                  onTap: _clearSelection,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompact ? 16.w : 24.w,
                                      vertical: isCompact ? 10.h : 12.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(30.r),
                                      border: Border.all(
                                        color: theme.primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.refresh_rounded,
                                          color: theme.primaryColor,
                                          size: isCompact ? 16.r : 18.r,
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          "CLEAR PATH",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: isCompact ? 10.sp : 12.sp,
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: isCompact ? 10.w : 16.w),
                                ScaleButton(
                                  onTap: () => _submitAnswer(
                                    words,
                                    quest.correctAnswer ?? "",
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompact ? 20.w : 32.w,
                                      vertical: isCompact ? 10.h : 12.h,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30.r),
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.primaryColor,
                                          theme.primaryColor.withValues(
                                            alpha: 0.8,
                                          ),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.primaryColor.withValues(
                                            alpha: 0.35,
                                          ),
                                          blurRadius: isCompact ? 10 : 15,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.bolt_rounded,
                                          color: Colors.white,
                                          size: isCompact ? 16.r : 18.r,
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          "IGNITE SPARK",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: isCompact ? 10.sp : 12.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(duration: 300.ms),

                          // Post-answer review cards
                          SizedBox(height: isCompact ? 40.h : 80.h),
                        ],
                      ),
                    );
                  },
                ),
            ),
            if (_phase1Passed && !_isAnswered && quest != null)
              SpeakToConfirmOverlay(
                expectedText: quest.correctAnswer ?? currentText,
                primaryColor: theme.primaryColor,
                onConfirmed: () => _submitPhase2Evaluation(true),
                onSkipped: () => _submitPhase2Evaluation(false),
              ),
          ],
        );
      },
    );
  }
}

