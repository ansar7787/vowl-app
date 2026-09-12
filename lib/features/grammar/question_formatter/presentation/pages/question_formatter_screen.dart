import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
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
import 'package:vowl/features/grammar/question_formatter/presentation/widgets/question_formatter_instruction.dart';
import 'package:vowl/features/grammar/question_formatter/presentation/widgets/question_formatter_crank.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';

class QuestionFormatterScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const QuestionFormatterScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.questionFormatter,
  });

  @override
  State<QuestionFormatterScreen> createState() =>
      _QuestionFormatterScreenState();
}

class _QuestionFormatterScreenState extends State<QuestionFormatterScreen>
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<double> _crankRotation = ValueNotifier(0.0);
  final ValueNotifier<bool> _isCrankComplete = ValueNotifier(false);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;
  final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);
  final ValueNotifier<String?> _selectedOptionText = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _isCrankComplete.removeListener(_onStateChangeAutoScroll);
    _pendingJigsaw.removeListener(_onStateChangeAutoScroll);
    _crankRotation.dispose();
    _isCrankComplete.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _pendingJigsaw.dispose();
    _selectedOptionText.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isCrankComplete.addListener(_onStateChangeAutoScroll);
    _pendingJigsaw.addListener(_onStateChangeAutoScroll);
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onStateChangeAutoScroll() {
    if (_isCrankComplete.value || _pendingJigsaw.value) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _autoSpin() {
    if (_isAnswered.value || _isCrankComplete.value || _pendingJigsaw.value) {
      return;
    }
    _hapticService.success();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    late final Animation<double> animation;
    animation = Tween<double>(
      begin: _crankRotation.value,
      end: 6.28,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOutBack));
    animation.addListener(() {
      _crankRotation.value = animation.value;
      if (animation.value >= 6.28 && !_isCrankComplete.value) {
        _isCrankComplete.value = true;
      }
    });
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) controller.dispose();
    });
    controller.forward();
  }

  void _onCrankUpdate(double delta) {
    if (_isAnswered.value || _pendingJigsaw.value || _isCrankComplete.value) {
      return;
    }
    _crankRotation.value += delta.abs() * 0.02;
    if ((_crankRotation.value * 57.29).abs().toInt() % 10 == 0) {
      _hapticService.selection();
    }
    if (_crankRotation.value.abs() >= 6.28) {
      _isCrankComplete.value = true;
    }
  }

  void _onOptionSelect(int index, int correctIndex, String optionText) {
    if (_isAnswered.value || _pendingJigsaw.value) return;
    bool isCorrect = index == correctIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _selectedOptionText.value = optionText;
      _pendingJigsaw.value = true;
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      _crankRotation.value = 0.0;
      _selectedOptionText.value = optionText;
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
            _crankRotation.value = 0.0;
            _isCrankComplete.value = false;
            _pendingJigsaw.value = false;
            _selectedOptionText.value = null;
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
            title: 'QUESTION MASTER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded)
            ? state.currentQuest as GrammarQuest?
            : null;
        final options =
            quest?.options ??
            ["Is he...?", "Does he...?", "Has he...?", "Was he...?"];

        String cleanTargetSentence = "";
        if (quest != null) {
          final sentence = quest.correctAnswer ?? quest.sentence ?? "";
          if (sentence.isNotEmpty) {
            cleanTargetSentence = sentence
                .replaceAll('[', '')
                .replaceAll(']', '');
          } else if (_selectedOptionText.value != null) {
            cleanTargetSentence = _selectedOptionText.value!;
          }
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _isCrankComplete,
            _pendingJigsaw,
            _selectedOptionText,
          ]),
          builder: (context, _) {
            return GrammarBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: _showConfetti.value,
              useScrolling: false, // Stack layout required for Jigsaw Overlay
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<GrammarBloc>().add(const GrammarHintUsed()),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            RawScrollbar(
                              controller: _scrollController,
                              thumbColor: theme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              crossAxisMargin: 2,
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: Builder(
                                        builder: (context) {
                                          final maxHeight = MediaQuery.of(
                                            context,
                                          ).size.height;
                                          final isCompact = maxHeight < 700;

                                          return Column(
                                            children: [
                                              SizedBox(
                                                height: isCompact ? 4.h : 10.h,
                                              ),
                                              isCompact
                                                  ? SizedBox(
                                                      height: 25.h,
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child:
                                                            QuestionFormatterInstruction(
                                                              primaryColor: theme
                                                                  .primaryColor,
                                                            ),
                                                      ),
                                                    )
                                                  : QuestionFormatterInstruction(
                                                      primaryColor:
                                                          theme.primaryColor,
                                                    ),
                                              SizedBox(
                                                height: isCompact ? 8.h : 20.h,
                                              ),

                                              if (quest.questionType != null ||
                                                  quest.grammarRule !=
                                                      null) ...[
                                                Container(
                                                  margin: EdgeInsets.symmetric(
                                                    horizontal: 24.w,
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16.w,
                                                    vertical: 6.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: theme.primaryColor
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12.r,
                                                        ),
                                                    border: Border.all(
                                                      color: theme.primaryColor
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    quest.grammarRule != null
                                                        ? "RULE: ${quest.grammarRule!.toUpperCase()}"
                                                        : "TYPE: ${quest.questionType?.toUpperCase() ?? 'QUESTION'}",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 12.sp,
                                                      color: theme.primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                ).animate().fadeIn(
                                                  duration: 400.ms,
                                                ),
                                                SizedBox(
                                                  height: isCompact
                                                      ? 12.h
                                                      : 24.h,
                                                ),
                                              ],

                                              // 3D Inverter Context Card
                                              Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 24.w,
                                                        ),
                                                    child: ValueListenableBuilder<double>(
                                                      valueListenable:
                                                          _crankRotation,
                                                      builder:
                                                          (
                                                            context,
                                                            rotation,
                                                            child,
                                                          ) {
                                                            return Transform(
                                                              transform:
                                                                  Matrix4.identity()
                                                                    ..setEntry(
                                                                      3,
                                                                      2,
                                                                      0.001,
                                                                    )
                                                                    ..rotateX(
                                                                      rotation,
                                                                    ),
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: child,
                                                            );
                                                          },
                                                      child: Container(
                                                        width: double.infinity,
                                                        padding: EdgeInsets.all(
                                                          isCompact
                                                              ? 16.r
                                                              : 28.r,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: isDark
                                                              ? Colors.white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.05,
                                                                    )
                                                              : Colors.black
                                                                    .withValues(
                                                                      alpha:
                                                                          0.03,
                                                                    ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                isCompact
                                                                    ? 18.r
                                                                    : 28.r,
                                                              ),
                                                          border: Border.all(
                                                            color: theme
                                                                .primaryColor
                                                                .withValues(
                                                                  alpha: 0.2,
                                                                ),
                                                            width: 1.5,
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: theme
                                                                  .primaryColor
                                                                  .withValues(
                                                                    alpha: 0.05,
                                                                  ),
                                                              blurRadius: 30,
                                                              spreadRadius: 5,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Text(
                                                          quest.sentence ??
                                                              "Missing statement.",
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Outfit',
                                                            fontSize: isCompact
                                                                ? 16.sp
                                                                : 22.sp,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: isDark
                                                                ? Colors.white
                                                                : Colors
                                                                      .black87,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .animate()
                                                  .fadeIn(duration: 600.ms)
                                                  .scale(
                                                    begin: const Offset(
                                                      0.9,
                                                      0.9,
                                                    ),
                                                    end: const Offset(1, 1),
                                                  ),

                                              SizedBox(
                                                height: isCompact ? 16.h : 48.h,
                                              ),

                                              // Game Mechanic Area
                                              Column(
                                                children: [
                                                  if (!_isAnswered.value &&
                                                      !_pendingJigsaw.value &&
                                                      !_isCrankComplete.value)
                                                    ValueListenableBuilder<
                                                      double
                                                    >(
                                                      valueListenable:
                                                          _crankRotation,
                                                      builder:
                                                          (
                                                            context,
                                                            rotation,
                                                            _,
                                                          ) {
                                                            return QuestionFormatterCrank(
                                                              crankRotation:
                                                                  rotation,
                                                              isAnswered:
                                                                  _isAnswered
                                                                      .value ||
                                                                  _pendingJigsaw
                                                                      .value,
                                                              isDark: isDark,
                                                              primaryColor: theme
                                                                  .primaryColor,
                                                              onPanUpdate:
                                                                  _onCrankUpdate,
                                                              onAutoSpin:
                                                                  _autoSpin,
                                                            );
                                                          },
                                                    )
                                                  else if (!_isAnswered.value &&
                                                      !_pendingJigsaw.value)
                                                    _buildQuestionOptions(
                                                      options,
                                                      quest.correctAnswerIndex ??
                                                          0,
                                                      theme.primaryColor,
                                                      isDark,
                                                      isCompact,
                                                    )
                                                  else if (_isAnswered.value)
                                                    _buildResult(
                                                      _isCorrect.value == true
                                                          ? cleanTargetSentence
                                                          : (_selectedOptionText
                                                                    .value ??
                                                                "No selection"),
                                                      theme.primaryColor,
                                                      isDark,
                                                      isCompact,
                                                    ),
                                                ],
                                              ),

                                              SizedBox(
                                                height: isCompact ? 12.h : 40.h,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  if (_pendingJigsaw.value &&
                                      !_isAnswered.value &&
                                      cleanTargetSentence.isNotEmpty)
                                    SliverToBoxAdapter(
                                      child: TypeToConfirmOverlay(
                                        expectedText: cleanTargetSentence,
                                        primaryColor: theme.primaryColor,
                                        onConfirmed: () =>
                                            _submitFinalAnswer(true),
                                        onSkipped: () =>
                                            _submitFinalAnswer(false),
                                        isPositioned: false,
                                        displayText:
                                            "Type the full question to lock it in",
                                      ),
                                    ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(
                                                context,
                                              ).viewInsets.bottom >
                                              0
                                          ? MediaQuery.of(
                                                  context,
                                                ).viewInsets.bottom +
                                                40.h
                                          : 60.h,
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildQuestionOptions(
    List<String> options,
    int correctIndex,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    return Column(
      children: options.asMap().entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: isCompact ? 8.h : 16.h,
            left: 24.w,
            right: 24.w,
          ),
          child: ScaleButton(
            onTap: () => _onOptionSelect(entry.key, correctIndex, entry.value),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(isCompact ? 12.r : 20.r),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(isCompact ? 14.r : 20.r),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: isCompact ? 14.sp : 18.sp,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildResult(
    String result,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final bool correct = _isCorrect.value == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 14.r : 28.r),
        decoration: BoxDecoration(
          color: displayColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(isCompact ? 18.r : 28.r),
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
              size: isCompact ? 28.r : 40.r,
            ),
            SizedBox(height: isCompact ? 6.h : 16.h),
            Text(
              correct
                  ? context
                        .tr('games.correct', fallback: 'Correct')
                        .toUpperCase()
                  : context.tr('games.incorrect_caps', fallback: 'INCORRECT'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 13.sp : 16.sp,
                fontWeight: FontWeight.w900,
                color: displayColor,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: isCompact ? 4.h : 8.h),
            Text(
              result,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 16.sp : 22.sp,
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
          ],
        ),
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
