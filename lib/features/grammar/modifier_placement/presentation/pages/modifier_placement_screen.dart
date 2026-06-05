import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/grammar/modifier_placement/presentation/widgets/modifier_placement_instruction.dart';
import 'package:vowl/features/grammar/modifier_placement/presentation/widgets/modifier_magnetic_arena.dart';

class ModifierPlacementScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ModifierPlacementScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.modifierPlacement,
  });

  @override
  State<ModifierPlacementScreen> createState() => _ModifierPlacementScreenState();
}

class _ModifierPlacementScreenState extends State<ModifierPlacementScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _targetIndex = -1;
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

  void _submitAnswer(GrammarQuest quest) {
    if (_isAnswered || _targetIndex == -1) return;

    final allWords = quest.shuffledWords ?? [];
    if (allWords.isEmpty) return;

    final modifier = allWords[0];
    final words = allWords.skip(1).toList();

    final resultingWords = List<String>.from(words);
    resultingWords.insert(_targetIndex, modifier);

    final result = resultingWords.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    bool isCorrect = result.toLowerCase() == (quest.correctAnswer ?? "").toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
    } else {
      _hapticService.error();
      _soundService.playWrong();
    }

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });
    context.read<GrammarBloc>().add(SubmitAnswer(isCorrect));
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
              _targetIndex = -1;
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
            title: 'SYNTAX SHAPER!',
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
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final allWords = quest?.shuffledWords ?? [];
        if (allWords.isEmpty) return const SizedBox();

        final modifier = allWords[0];
        final words = allWords.skip(1).toList();

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
                    ModifierPlacementInstruction(primaryColor: theme.primaryColor),
                    SizedBox(height: 20.h),

                    // Context Card
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(22.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(28.r),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          "Insert the modifier '$modifier' into the correct position.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Outfit', 
                            fontSize: 18.sp,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

                    // Result Feedback
                    if (_isAnswered) ...[
                      SizedBox(height: 32.h),
                      _buildResult(quest, theme.primaryColor, isDark),
                    ],

                    // Magnetic Arena
                    Expanded(
                      child: Center(
                        child: ModifierMagneticArena(
                          words: words,
                          modifier: modifier,
                          targetIndex: _targetIndex,
                          isAnswered: _isAnswered,
                          isDark: isDark,
                          primaryColor: theme.primaryColor,
                          onSlotAccepted: (idx) => setState(() => _targetIndex = idx),
                          onSlotReset: () => setState(() => _targetIndex = -1),
                        ),
                      ),
                    ),

                    // Draggable Magnet
                    if (!_isAnswered && _targetIndex == -1)
                      Draggable<String>(
                        data: modifier,
                        feedback: _buildTactileMagnet(modifier, theme.primaryColor, isDragging: true),
                        childWhenDragging: Opacity(
                          opacity: 0.2,
                          child: _buildTactileMagnet(modifier, theme.primaryColor),
                        ),
                        child: _buildTactileMagnet(modifier, theme.primaryColor),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                    // Submit Button
                    if (!_isAnswered && _targetIndex != -1) ...[
                      SizedBox(height: 16.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: ScaleButton(
                          onTap: () => _submitAnswer(quest),
                          child: Container(
                            width: double.infinity,
                            height: 65.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24.r),
                              gradient: LinearGradient(
                                colors: [
                                  theme.primaryColor,
                                  theme.primaryColor.withValues(alpha: 0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 25,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "FINALIZE SYNTAX",
                                style: TextStyle(fontFamily: 'Outfit', 
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 40.h),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTactileMagnet(String modifier, Color primaryColor, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.4),
              blurRadius: isDragging ? 25 : 12,
              offset: isDragging ? const Offset(0, 10) : const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          modifier,
          style: TextStyle(fontFamily: 'Outfit', 
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildResult(GrammarQuest quest, Color primaryColor, bool isDark) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(24.r),
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
              size: 40.r,
            ),
            SizedBox(height: 12.h),
            Text(
              correct ? "CORRECT!" : "INCORRECT",
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: displayColor,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "CORRECT SYNTAX:",
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white60 : Colors.black54,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              quest.correctAnswer ?? "",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: displayColor,
              ),
            ),
            if (quest.explanation != null) ...[
              SizedBox(height: 12.h),
              Text(
                quest.explanation!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 13.sp,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
