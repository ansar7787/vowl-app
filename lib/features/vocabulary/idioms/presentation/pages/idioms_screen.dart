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

class IdiomsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const IdiomsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.idioms,
  });

  @override
  State<IdiomsScreen> createState() => _IdiomsScreenState();
}

class _IdiomsScreenState extends State<IdiomsScreen>
    with VocabularyGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<String?> _selectedOption = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  VocabularyQuest? _lastQuest;

  @override
  void dispose() {
    _selectedOption.dispose();
    _scrollController.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    isAnsweredNotifier.addListener(() {
      if (isAnsweredNotifier.value && mounted && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    initVocabularyGame();
  }

  void _submitAnswer(String selected, String correct) {
    if (isAnsweredNotifier.value) return;
    _selectedOption.value = selected;
    isAnsweredNotifier.value = true;

    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    Future.delayed(600.ms, () {
      if (!mounted) return;
      if (isCorrect) {
        hapticService.success();
        isFirstStagePassedNotifier.value = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            );
          }
        });
      } else {
        hapticService.error();
        soundService.playWrong();
        isCorrectNotifier.value = false;
        context.read<VocabularyBloc>().add(SubmitAnswer(false));
      }
    });
  }

  void _submitFinalAnswer(bool nailedIt, {String? wrongWord}) {
    if (isAnsweredNotifier.value && isCorrectNotifier.value != null) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;
    if (wrongWord != null && wrongWord.isNotEmpty) {
      _selectedOption.value = wrongWord;
    }

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _selectedOption.value = null;
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
        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;

        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            isFirstStagePassedNotifier,
            _selectedOption,
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
              onHint: () =>
                  context.read<VocabularyBloc>().add(VocabularyHintUsed()),
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
                                    child: IgnorePointer(
                                      ignoring:
                                          isFirstStagePassedNotifier.value,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight,
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
                                                    _buildChatInterface(
                                                      quest,
                                                      theme.primaryColor,
                                                      isDarkMode,
                                                      constraints.maxHeight,
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
                                                      height:
                                                          (isAnsweredNotifier
                                                                  .value ||
                                                              isFirstStagePassedNotifier
                                                                  .value)
                                                          ? 40.h
                                                          : 40.h,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
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
                                          child: Column(
                                            children: [
                                              SpeakToConfirmOverlay(
                                                expectedText:
                                                    quest.correctAnswer ?? '',
                                                primaryColor:
                                                    theme.primaryColor,
                                                onConfirmed: () =>
                                                    _submitFinalAnswer(true),
                                                onSkipped: () =>
                                                    _submitFinalAnswer(false),
                                                isPositioned: false,
                                              ),
                                              SizedBox(height: 60.h),
                                            ],
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
        ? (gapUnit * 1).clamp(10.0, 30.0)
        : 10.0;
    final double gapMiddle = remainingHeight > 0
        ? (gapUnit * 1.5).clamp(10.0, 24.0)
        : 10.0;
    final double gapBottom = remainingHeight > 0
        ? (gapUnit * 2.5).clamp(15.0, 40.0)
        : 15.0;

    return Column(
      children: [
        SizedBox(height: gapTop),
        isCompact
            ? SizedBox(
                height: 30.h,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildHeaderBadge(color, isCompact: true),
                ),
              )
            : _buildHeaderBadge(color, isCompact: false),
        SizedBox(height: gapMiddle),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
          child: Column(
            children: [
              IdiomsSystemMessage(
                text: "INCOMING TRANSMISSION...",
                color: color,
              ),
              SizedBox(height: isCompact ? 10.h : 20.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: isCompact ? 14.r : 18.r,
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.psychology_alt_rounded,
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
                SizedBox(height: isCompact ? 8.h : 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: (isCompact ? 28.r : 36.r) + 10.w,
                    ), // alignment with above
                    Flexible(
                      child: IdiomsStrangerTextMessage(
                        text: quest.hint!,
                        color: color,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],

              if (_selectedOption.value != null) ...[
                SizedBox(height: isCompact ? 14.h : 24.h),
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
                        Icons.face_retouching_natural_rounded,
                        size: isCompact ? 16.r : 20.r,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],

              if (isAnsweredNotifier.value &&
                  isCorrectNotifier.value == false) ...[
                SizedBox(height: 10.h),
                IdiomsSystemMessage(
                  text: "DECRYPTION FAILED. RE-EVALUATE SEQUENCE.",
                  color: Colors.redAccent,
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: gapMiddle),

        Container(
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
                    onTap: () => _submitAnswer(o, quest.correctAnswer ?? ""),
                  );
                }).toList(),
              ),
            )
            .animate()
            .fadeIn(delay: 800.ms)
            .slideY(begin: 0.3, curve: Curves.easeOutCubic),
        SizedBox(height: gapBottom),
      ],
    );
  }

  Widget _buildHeaderBadge(Color color, {bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Container(
            width: 8.r,
            height: 8.r,
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
          SizedBox(width: 10.w),
          Text(
            "EMOJIFY: SECURE CHANNEL",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              color: color,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          isCompact ? SizedBox(width: 15.w) : const Spacer(),
          Icon(Icons.lock_outline_rounded, size: 14.r, color: color),
        ],
      ),
    );
  }
}
