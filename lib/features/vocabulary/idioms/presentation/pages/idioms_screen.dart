import 'dart:async';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/widgets/idioms_painters.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/widgets/idioms_chat_bubbles.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/widgets/idioms_option_chip.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/widgets/idioms_origin_card.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';


/// Interactive chat-style idioms game screen where learners decipher figurative idioms from emoji and dialogue clues.
class IdiomsScreen extends StatefulWidget {
  /// The active curriculum difficulty level.
  final int level;

  /// The active game subtype.
  final GameSubtype gameType;

  /// Creates an [IdiomsScreen] instance.
  const IdiomsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.idioms,
  });

  @override
  State<IdiomsScreen> createState() => _IdiomsScreenState();
}

class _IdiomsScreenState extends State<IdiomsScreen>
    with
        GameScreenMixin<IdiomsScreen>,
        VocabularyGameScreenMixin<IdiomsScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<String?> _selectedOption = ValueNotifier(null);
  final ValueNotifier<bool> _showHint = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  Timer? _submitTimer;
  Timer? _scrollTimer;

  VocabularyQuest? _lastQuest;

  @override
  void dispose() {
    _submitTimer?.cancel();
    _scrollTimer?.cancel();
    _selectedOption.dispose();
    _showHint.dispose();
    _scrollController.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initVocabularyGame();
  }

  void _submitAnswer(String selected, String correct, GameQuest quest) {
    if (isAnsweredNotifier.value) return;
    _selectedOption.value = selected;
    isAnsweredNotifier.value = true;

    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    _submitTimer?.cancel();
    _submitTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (isCorrect) {
        hapticService.success();
        isFirstStagePassedNotifier.value = true;
        _scrollTimer?.cancel();
        _scrollTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            );
          }
        });
      } else {
        isAnsweredNotifier.value = false;
        submitWrongAnswer(quest: quest, userAnswer: selected);
      }
    });
  }

  void _submitFinalAnswer(
    bool nailedIt, {
    GameQuest? quest,
    String? wrongWord,
  }) {
    if (isAnsweredNotifier.value && isCorrectNotifier.value != null) return;

    if (wrongWord != null && wrongWord.isNotEmpty) {
      _selectedOption.value = wrongWord;
    }

    isAnsweredNotifier.value = false;
    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      final q = quest ?? _lastQuest;
      if (q != null) {
        submitWrongAnswer(quest: q, userAnswer: wrongWord);
      } else {
        submitWrongAnswer(quest: quest!, userAnswer: '');
      }
    }
  }

  @override
  void onQuestionReset() {
    _submitTimer?.cancel();
    _scrollTimer?.cancel();
    _selectedOption.value = null;
    _showHint.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listenWhen: vocabularyListenWhen,
      listener: onVocabularyStateChanged,
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );
        if (state is VocabularyLoaded) {
          _lastQuest = state.currentQuestOrNull ?? _lastQuest;
          if (state.hintUsed) {
            _showHint.value = true;
          }
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuestOrNull
            : _lastQuest;

        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            isFirstStagePassedNotifier,
            _selectedOption,
            _showHint,
          ]),
          builder: (context, _) {
            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  isAnsweredNotifier.value &&
                  (isCorrectNotifier.value != null ||
                      !isFirstStagePassedNotifier.value),
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              hasStage2: true,
              onContinue: () {
                final currentState = context.read<VocabularyBloc>().state;
                if (currentState is VocabularyLoaded &&
                    !currentState.isFinalFailure &&
                    isCorrectNotifier.value == false) {
                  isAnsweredNotifier.value = false;
                  isCorrectNotifier.value = null;
                  isFirstStagePassedNotifier.value = false;
                  _selectedOption.value = null;
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  }
                } else {
                  context.read<VocabularyBloc>().add(NextQuestion());
                }
              },
              onHint: () {
                _showHint.value = true;
              },
              customHintText: quest?.hint,
              useScrolling: false,
              disablePadding: true,
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
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: (!isFirstStagePassedNotifier.value)
                                    ? const NeverScrollableScrollPhysics()
                                    : const BouncingScrollPhysics(),
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: isFirstStagePassedNotifier.value
                                            ? 0
                                            : constraints.maxHeight,
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: GridPainter(
                                                theme.primaryColor.withValues(
                                                  alpha: isDarkMode
                                                      ? 0.05
                                                      : 0.03,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: ConstrainedBox(
                                              constraints:
                                                  const BoxConstraints(
                                                    maxWidth: 600,
                                                  ),
                                              child: Column(
                                                children: [
                                                  IgnorePointer(
                                                    ignoring:
                                                        isFirstStagePassedNotifier.value,
                                                    child: _buildChatInterface(
                                                      quest,
                                                      theme.primaryColor,
                                                      isDarkMode,
                                                      constraints.maxHeight,
                                                    ),
                                                  ),
                                                  if (isFirstStagePassedNotifier
                                                      .value)
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 20.w,
                                                          ),
                                                      child: Column(
                                                        children: [
                                                          if ((quest.origin !=
                                                                      null &&
                                                                  quest
                                                                      .origin!
                                                                      .isNotEmpty) ||
                                                              quest.literalVsFigurative !=
                                                                  null ||
                                                              quest.contextSentence !=
                                                                  null ||
                                                              quest.example !=
                                                                  null)
                                                            IdiomsOriginCard(
                                                              origin: quest
                                                                  .origin,
                                                              literalVsFigurative:
                                                                  quest
                                                                      .literalVsFigurative,
                                                              contextSentence:
                                                                  quest
                                                                      .contextSentence ??
                                                                  quest
                                                                      .example,
                                                              color: theme
                                                                  .primaryColor,
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  SizedBox(
                                                    height: 30.h,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isFirstStagePassedNotifier.value &&
                                      (!isAnsweredNotifier.value ||
                                          isCorrectNotifier.value == null))
                                    SliverToBoxAdapter(
                                      child: Center(
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 600,
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 20.w,
                                            ),
                                            child: Column(
                                              children: [
                                                SpeakToConfirmOverlay(
                                                  expectedText:
                                                      quest.correctAnswer ?? '',
                                                  primaryColor:
                                                      theme.primaryColor,
                                                  onConfirmed: () =>
                                                      _submitFinalAnswer(
                                                        true,
                                                        quest: quest,
                                                      ),
                                                  onSkipped: () =>
                                                      _submitFinalAnswer(
                                                        false,
                                                        quest: quest,
                                                      ),
                                                  isPositioned: false,
                                                ),
                                                SizedBox(height: 60.h),
                                              ],
                                            ),
                                          ),
                                        ),
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

  Widget _buildChatInterface(
    VocabularyQuest quest,
    Color color,
    bool isDark,
    double screenHeight,
  ) {
    final isCompact = screenHeight < 580;

    final double estimatedContentHeight =
        (isCompact ? 30.h : 40.h) +
        (isCompact ? 40.h : 60.h) +
        (isCompact ? 100.h : 180.h) +
        (isCompact ? 20.h : 40.h);
    final remainingHeight = screenHeight - estimatedContentHeight;

    final double gapUnit = remainingHeight > 0 ? remainingHeight / 5 : 0;
    final double gapTop = remainingHeight > 0
        ? (gapUnit * 1).clamp(10.0, 24.0)
        : 10.0;
    final double gapMiddle = remainingHeight > 0
        ? (gapUnit * 1.5).clamp(10.0, 20.0)
        : 10.0;
    final double gapBottom = remainingHeight > 0
        ? (gapUnit * 2.5).clamp(15.0, 36.0)
        : 15.0;

    return Column(
      children: [
        SizedBox(height: gapTop),
        _buildHeaderBadge(color, isCompact: isCompact),
        SizedBox(height: isCompact ? 6.h : 10.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            "Guess the idiom that matches the emoji clues",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isCompact ? 13.sp : 15.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.slate800,
              height: 1.35,
            ),
          ),
        ),
        SizedBox(height: gapMiddle),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: isCompact ? 14.r : 18.r,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.help_outline_rounded,
                      size: isCompact ? 16.r : 20.r,
                      color: color,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  IdiomsStrangerMessage(
                    emojis: quest.topicEmoji ?? "❓",
                    color: color,
                    isDark: isDark,
                  ),
                ],
              ),
              if (quest.hint != null && quest.hint!.isNotEmpty) ...[
                if (_showHint.value) ...[
                  SizedBox(height: isCompact ? 8.h : 12.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: (isCompact ? 28.r : 36.r) + 10.w,
                      ),
                      Flexible(
                        child: IdiomsStrangerTextMessage(
                          text: quest.hint!,
                          color: color,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ] else if (!isAnsweredNotifier.value) ...[
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      SizedBox(
                        width: (isCompact ? 28.r : 36.r) + 10.w,
                      ),
                      GestureDetector(
                        onTap: () {
                          _showHint.value = true;
                          context
                              .read<VocabularyBloc>()
                              .add(const VocabularyHintUsed());
                          // Only VocabularyBloc consumes the hint — avoids double decrement
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: color.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 13.r,
                                color: color,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                "Need a clue?",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],

              if (_selectedOption.value != null) ...[
                SizedBox(height: isCompact ? 14.h : 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: IdiomsUserMessage(
                        text: _selectedOption.value!,
                        color: color,
                        isCorrect: isCorrectNotifier.value,
                        isDark: isDark,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    CircleAvatar(
                      radius: isCompact ? 14.r : 18.r,
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person_rounded,
                        size: isCompact ? 16.r : 20.r,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],

              if (isAnsweredNotifier.value &&
                  isCorrectNotifier.value == false) ...[
                SizedBox(height: 12.h),
                IdiomsSystemMessage(
                  text: "Not quite right. Try again!",
                  color: AppColors.gameIncorrect,
                  icon: Icons.info_outline_rounded,
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: gapMiddle),

        Builder(
          builder: (context) {
            final reduceMotion =
                (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
                VowlMotion.lowAnimationModeOverride.value;

            final optionsBox = Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Wrap(
                spacing: 12.w,
                runSpacing: isCompact ? 8.h : 12.h,
                alignment: WrapAlignment.center,
                children: (quest.options ?? []).map((o) {
                  return IdiomsOptionChip(
                    text: o,
                    correct: quest.correctAnswer ?? "",
                    color: color,
                    isDark: isDark,
                    isAnswered: isAnsweredNotifier.value,
                    isCorrect: isCorrectNotifier.value,
                    selectedOption: _selectedOption.value,
                    onTap: () =>
                        _submitAnswer(o, quest.correctAnswer ?? "", quest),
                  );
                }).toList(),
              ),
            );

            return reduceMotion
                ? optionsBox
                : optionsBox
                    .animate()
                    .fadeIn(delay: 500.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOutCubic);
          },
        ),
        SizedBox(height: gapBottom),
      ],
    );
  }

  Widget _buildHeaderBadge(Color color, {bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isCompact ? 4.h : 6.h,
        horizontal: isCompact ? 12.w : 16.w,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.extension_rounded,
            size: isCompact ? 12.r : 14.r,
            color: color,
          ),
          SizedBox(width: 6.w),
          Text(
            "IDIOM PUZZLE",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isCompact ? 10.sp : 11.sp,
              color: color,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
