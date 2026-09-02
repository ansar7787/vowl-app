import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/grammar/modals_selection/presentation/widgets/modals_selection_instruction.dart';
import 'package:vowl/features/grammar/modals_selection/presentation/widgets/modals_rotary_dial.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';

class ModalsSelectionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ModalsSelectionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.modalsSelection,
  });

  @override
  State<ModalsSelectionScreen> createState() => _ModalsSelectionScreenState();
}

class _ModalsSelectionScreenState extends State<ModalsSelectionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<int> _selectedIndex = ValueNotifier(0);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;
  final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _selectedIndex.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _pendingJigsaw.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitAnswer(int correctIndex) {
    if (_isAnswered.value || _pendingJigsaw.value) return;

    bool isCorrect = _selectedIndex.value == correctIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _pendingJigsaw.value = true;
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
    _pendingJigsaw.value = false;
    _isAnswered.value = true;
    _isCorrect.value = correct;

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  List<InlineSpan> _buildSentenceWithBlank(
    String template,
    String? selected,
    Color primaryColor,
    bool isDark,
  ) {
    final parts = template.contains("____")
        ? template.split("____")
        : template.split("___");
    List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child:
                Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected != null
                                ? primaryColor
                                : (isDark ? Colors.white38 : Colors.black38),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        selected ?? "      ",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    )
                    .animate(target: selected != null ? 1 : 0)
                    .shimmer(duration: 2.seconds),
          ),
        );
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesRestored =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesRestored) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _pendingJigsaw.value = false;
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'MODAL MASTER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest as GrammarQuest? : null;
        final options = quest?.options ?? ["CAN", "COULD", "MUST", "SHOULD"];

        String cleanTargetSentence = "";
        if (quest != null) {
          final sentence = quest.sentence ?? quest.question ?? "";
          String fullSentence = sentence;
          if (sentence.contains("___")) {
            fullSentence = sentence.replaceFirst(
              RegExp(r'_{3,}'),
              options[_selectedIndex.value],
            );
          }
          cleanTargetSentence = fullSentence
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
        }

        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _selectedIndex, _pendingJigsaw]),
          builder: (context, _) {
            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: _showConfetti.value,
              useScrolling: false, // Stack needs finite space to anchor to bottom
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<GrammarBloc>().add(const GrammarHintUsed()),
              child: quest == null
                  ? const SizedBox()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            RawScrollbar(
                              controller: _scrollController,
                              thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final maxHeight = constraints.maxHeight;
                                              final isCompact = maxHeight < 580;

                                              final double estimatedContentHeight =
                                                  (isCompact ? 30.h : 40.h) +
                                                  (isCompact ? 50.h : 80.h) +
                                                  (isCompact ? 180.r : 280.r) +
                                                  (isCompact ? 40.h : 65.h) +
                                                  40.h;
                                              final remainingHeight =
                                                  maxHeight - estimatedContentHeight;

                                              final double gapUnit = remainingHeight > 0
                                                  ? remainingHeight / 5
                                                  : 0;
                                              final double gapTop = remainingHeight > 0
                                                  ? (gapUnit * 1).clamp(4.0, 15.0)
                                                  : 4.0;
                                              final double gapMiddle = remainingHeight > 0
                                                  ? (gapUnit * 1.5).clamp(6.0, 20.0)
                                                  : 6.0;
                                              final double gapBottom = remainingHeight > 0
                                                  ? (gapUnit * 2.5).clamp(10.0, 30.0)
                                                  : 10.0;

                                              return Column(
                                                children: [
                                                  SizedBox(height: gapTop),
                                                  isCompact
                                                      ? SizedBox(
                                                          height: 25.h,
                                                          child: FittedBox(
                                                            fit: BoxFit.scaleDown,
                                                            child: ModalsSelectionInstruction(
                                                              primaryColor: theme.primaryColor,
                                                            ),
                                                          ),
                                                        )
                                                      : ModalsSelectionInstruction(
                                                          primaryColor: theme.primaryColor,
                                                        ),
                                                  SizedBox(height: gapMiddle),

                                                  if (quest.modalMeaning != null) ...[
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                                                      decoration: BoxDecoration(
                                                        color: theme.primaryColor.withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(12.r),
                                                        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          Text(
                                                            "MEANING: ${quest.modalMeaning!.toUpperCase()}",
                                                            style: TextStyle(
                                                              fontFamily: 'Outfit',
                                                              fontSize: 12.sp,
                                                              color: theme.primaryColor,
                                                              fontWeight: FontWeight.bold,
                                                              letterSpacing: 1.2,
                                                            ),
                                                          ),
                                                          SizedBox(height: 4.h),
                                                          Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Text("LOW (might) ", style: TextStyle(fontSize: 10.sp, color: theme.primaryColor.withValues(alpha: 0.6))),
                                                              Icon(Icons.arrow_right_alt, color: theme.primaryColor, size: 16.sp),
                                                              Text(" HIGH (must)", style: TextStyle(fontSize: 10.sp, color: theme.primaryColor.withValues(alpha: 0.6))),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ).animate().fadeIn(duration: 400.ms),
                                                    SizedBox(height: isCompact ? 12.h : 20.h),
                                                  ],

                                                  // Context Card with Fill-in-the-Blank
                                                  Padding(
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal: 24.w,
                                                        ),
                                                        child: Container(
                                                          width: double.infinity,
                                                          padding: EdgeInsets.all(
                                                            isCompact ? 14.r : 22.r,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: isDark
                                                                ? Colors.white.withValues(alpha: 0.05)
                                                                : Colors.black.withValues(
                                                                    alpha: 0.03,
                                                                  ),
                                                            borderRadius: BorderRadius.circular(
                                                              isCompact ? 18.r : 28.r,
                                                            ),
                                                            border: Border.all(
                                                              color: theme.primaryColor.withValues(
                                                                alpha: 0.15,
                                                              ),
                                                              width: 1.5,
                                                            ),
                                                          ),
                                                          child: RichText(
                                                            textAlign: TextAlign.center,
                                                            text: TextSpan(
                                                              style: TextStyle(
                                                                fontFamily: 'Outfit',
                                                                fontSize: isCompact ? 15.sp : 20.sp,
                                                                color: isDark
                                                                    ? Colors.white
                                                                    : Colors.black87,
                                                                height: 1.5,
                                                              ),
                                                              children: _buildSentenceWithBlank(
                                                                quest.question ?? "___ sentence.",
                                                                options[_selectedIndex.value],
                                                                theme.primaryColor,
                                                                isDark,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                      .animate()
                                                      .fadeIn(duration: 600.ms)
                                                      .slideY(begin: 0.2, end: 0),

                                                  // Result Feedback
                                                  if (_isAnswered.value) ...[
                                                    SizedBox(height: isCompact ? 8.h : 24.h),
                                                    _buildResult(
                                                      quest,
                                                      theme.primaryColor,
                                                      isDark,
                                                      isCompact,
                                                    ),
                                                  ],

                                                  // Rotary Dial
                                                  Expanded(
                                                    child: ModalsRotaryDial(
                                                      options: options,
                                                      isAnswered: _isAnswered.value || _pendingJigsaw.value,
                                                      isDark: isDark,
                                                      primaryColor: theme.primaryColor,
                                                      onSelectionChanged: (index) {
                                                        if (_isAnswered.value || _pendingJigsaw.value) return;
                                                        _selectedIndex.value = index;
                                                      },
                                                      isCompact: isCompact,
                                                    ),
                                                  ),

                                                  // Submit Button
                                                  if (!_isAnswered.value && !_pendingJigsaw.value)
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                                                      child: ScaleButton(
                                                        onTap: () => _submitAnswer(
                                                          quest.correctAnswerIndex ?? 0,
                                                        ),
                                                        child: Container(
                                                          width: double.infinity,
                                                          height: isCompact ? 48.h : 65.h,
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(
                                                              isCompact ? 14.r : 22.r,
                                                            ),
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
                                                                  alpha: 0.3,
                                                                ),
                                                                blurRadius: 15,
                                                                offset: const Offset(0, 5),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              "LOCK CONFIGURATION",
                                                              style: TextStyle(
                                                                fontFamily: 'Outfit',
                                                                fontSize: isCompact ? 12.sp : 14.sp,
                                                                fontWeight: FontWeight.w900,
                                                                color: Colors.white,
                                                                letterSpacing: 2,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                  SizedBox(height: gapBottom),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height: (_pendingJigsaw.value && !_isAnswered.value) ? 380.h : 60.h,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_pendingJigsaw.value &&
                                !_isAnswered.value &&
                                cleanTargetSentence.isNotEmpty)
                              TypeToConfirmOverlay(
                                expectedText: cleanTargetSentence,
                                primaryColor: theme.primaryColor,
                                onConfirmed: () => _submitFinalAnswer(true),
                                onSkipped: () => _submitFinalAnswer(false),
                                isPositioned: true,
                                displayText: "Type the full sentence to lock it in",
                              ),
                          ],
                        );
                      },
                ),
            );
          },
        );
      },
    );
  }

  Widget _buildResult(
    GameQuest quest,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final bool correct = _isCorrect.value == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12.r : 24.r),
        decoration: BoxDecoration(
          color: displayColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(isCompact ? 16.r : 24.r),
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
              size: isCompact ? 24.r : 40.r,
            ),
            SizedBox(height: isCompact ? 4.h : 12.h),
            Text(
              correct
                  ? context
                        .tr('games.correct', fallback: 'Correct')
                        .toUpperCase()
                  : context.tr('games.incorrect_caps', fallback: 'INCORRECT'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 12.sp : 16.sp,
                fontWeight: FontWeight.w900,
                color: displayColor,
                letterSpacing: 2,
              ),
            ),
            if (!isCompact && quest.explanation != null) ...[
              SizedBox(height: 12.h),
              Text(
                quest.explanation!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
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
