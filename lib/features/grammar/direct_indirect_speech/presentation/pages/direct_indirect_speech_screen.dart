import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/widgets/direct_indirect_speech_instruction.dart';
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/widgets/direct_indirect_speech_mirror.dart';

class DirectIndirectSpeechScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DirectIndirectSpeechScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.directIndirectSpeech,
  });

  @override
  State<DirectIndirectSpeechScreen> createState() => _DirectIndirectSpeechScreenState();
}

class _DirectIndirectSpeechScreenState extends State<DirectIndirectSpeechScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  double _rotation = 0.0;
  int _selectedReflection = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onReflectionSelect(int index, int correctIndex) {
    if (_isAnswered) return;
    setState(() => _selectedReflection = index);

    bool isCorrect = index == correctIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
        _rotation = 3.14;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _rotation = 3.14;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;
          final livesChanged = _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedReflection = -1;
              _rotation = 0.0;
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SHADOW MASTER!',
            enableDoubleUp: true,
          );
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<GrammarBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final GrammarQuest? quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final rawQuestion = quest?.question ?? "DIRECT SPEECH";
        String displayDirect = quest?.sentence ?? "";
        if (displayDirect.isEmpty) {
          if (rawQuestion.contains(':')) {
            displayDirect = rawQuestion.split(':').last.replaceAll('"', '').trim();
          } else {
            displayDirect = rawQuestion;
          }
        }

        String displayIndirect = quest?.correctAnswer ?? "";
        if (displayIndirect.isEmpty &&
            quest != null &&
            quest.options != null &&
            (quest.correctAnswerIndex ?? 0) < quest.options!.length) {
          displayIndirect = quest.options![quest.correctAnswerIndex!];
        }
        if (displayIndirect.isEmpty) displayIndirect = "INDIRECT SPEECH";

        final options = quest?.options ?? ["REF A", "REF B", "REF C"];

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Column(
                  children: [
                    SizedBox(height: 10.h),
                    DirectIndirectSpeechInstruction(primaryColor: theme.primaryColor),
                    SizedBox(height: 20.h),

                    // Holographic Mirror
                    DirectIndirectSpeechMirror(
                      rotation: _rotation,
                      directText: displayDirect,
                      indirectText: displayIndirect,
                      isCorrect: _isCorrect,
                      isDark: isDark,
                      primaryColor: theme.primaryColor,
                    ),

                    SizedBox(height: 50.h),

                    // Reflection Options
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12.w,
                              runSpacing: 12.h,
                              children: List.generate(
                                options.length,
                                (i) => _buildReflectionChip(
                                  options[i],
                                  i,
                                  quest.correctAnswerIndex ?? 0,
                                  theme.primaryColor,
                                  isDark,
                                ),
                              ),
                            ),
                            if (_isAnswered) ...[
                              SizedBox(height: 30.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: _buildCorrectResult(quest, theme.primaryColor, isDark),
                              ),
                            ],
                            SizedBox(height: 40.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildReflectionChip(
    String text,
    int index,
    int correctIndex,
    Color primaryColor,
    bool isDark,
  ) {
    final isSelected = _selectedReflection == index;
    final isCorrect = _isAnswered && index == correctIndex;
    final isWrong = _isAnswered && isSelected && index != correctIndex;

    return ScaleButton(
      onTap: () => _onReflectionSelect(index, correctIndex),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        child: GlassTile(
          padding: EdgeInsets.all(20.r),
          borderRadius: BorderRadius.circular(24.r),
          color: isCorrect
              ? Colors.greenAccent.withValues(alpha: 0.2)
              : (isWrong
                  ? Colors.redAccent.withValues(alpha: 0.2)
                  : (isSelected ? primaryColor.withValues(alpha: 0.2) : null)),
          border: Border.all(
            color: isCorrect
                ? Colors.greenAccent
                : (isWrong
                    ? Colors.redAccent
                    : (isSelected ? primaryColor : Colors.white.withValues(alpha: 0.1))),
            width: 2,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Outfit', 
              fontSize: 15.sp,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isCorrect
                  ? Colors.greenAccent
                  : (isWrong ? Colors.redAccent : (isDark ? Colors.white : Colors.black87)),
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCorrectResult(GrammarQuest quest, Color primaryColor, bool isDark) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: displayColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: displayColor,
            size: 36.r,
          ),
          SizedBox(height: 10.h),
          Text(
            correct ? "CORRECT!" : "INCORRECT",
            style: TextStyle(fontFamily: 'Outfit', 
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: displayColor,
              letterSpacing: 2,
            ),
          ),
          if (quest.explanation != null) ...[
            SizedBox(height: 10.h),
            Text(
              quest.explanation!,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 12.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
