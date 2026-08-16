import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/collocations/presentation/widgets/collocation_anchor_bubble.dart';
import 'package:vowl/features/vocabulary/collocations/presentation/widgets/collocation_option_bubble.dart';
import 'package:vowl/core/presentation/widgets/dynamic_anagram_wrapper.dart';

class CollocationsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const CollocationsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.collocations,
  });

  @override
  State<CollocationsScreen> createState() => _CollocationsScreenState();
}

class _CollocationsScreenState extends State<CollocationsScreen>
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  bool _isFirstStagePassed = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitAnswer(String selected, String correct) {
    if (_isAnswered || _isFirstStagePassed) return;

    setState(() {
      _selectedOption = selected;
      _isAnswered = true;
    });

    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    Future.delayed(400.ms, () {
      if (!mounted) return;

      if (isCorrect) {
        _hapticService.success();
        _soundService.playCorrect();
        setState(() => _isFirstStagePassed = true);
        // Wait for Phase 2
      } else {
        _hapticService.error();
        _soundService.playWrong();
        setState(() => _isCorrect = isCorrect);
        context.read<VocabularyBloc>().add(SubmitAnswer(isCorrect));
      }
    });
  }

  void _submitFinalAnswer(bool nailedIt) {
    if (_isAnswered && _isCorrect != null) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;

          if (isNewQuestion || isRetry) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isFirstStagePassed = false;
              _selectedOption = null;
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'PAIR MASTER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

        if (state is VocabularyLoading ||
            (state is! VocabularyGameComplete &&
                _lastQuest == null &&
                state is! VocabularyLoaded &&
                state is! VocabularyError)) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () {
            final currentState = context.read<VocabularyBloc>().state;
            if (currentState is VocabularyLoaded &&
                !currentState.isFinalFailure &&
                _isCorrect == false) {
              setState(() {
                _isAnswered = false;
                _isCorrect = null;
                _isFirstStagePassed = false;
                _selectedOption = null;
              });
            } else {
              context.read<VocabularyBloc>().add(NextQuestion());
            }
          },
          onHint: () =>
              context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          useScrolling: false,
          child: quest == null
              ? const SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = constraints.maxHeight;
                    final isCompact = maxHeight < 580;

                    final double estimatedContentHeight =
                        20.h +
                        40.h +
                        (isCompact ? 80.h : 110.h) +
                        (isCompact ? 100.h : 180.h) +
                        20.h;
                    final remainingHeight = maxHeight - estimatedContentHeight;

                    final double gapUnit = remainingHeight > 0
                        ? remainingHeight / 6
                        : 0;
                    final double gapTop = remainingHeight > 0
                        ? (gapUnit * 1).clamp(6.0, 16.0)
                        : 6.0;
                    final double gapInstruction = remainingHeight > 0
                        ? (gapUnit * 1.5).clamp(10.0, 30.0)
                        : 10.0;
                    final double gapAnchor = remainingHeight > 0
                        ? (gapUnit * 1.5).clamp(10.0, 40.0)
                        : 10.0;
                    final double gapBottom = remainingHeight > 0
                        ? (gapUnit * 2).clamp(12.0, 60.0)
                        : 12.0;

                    return Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: gapTop),
                                isCompact
                                    ? SizedBox(
                                        height: 35.h,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: _buildInstruction(
                                            theme.primaryColor,
                                            isDark,
                                            quest.instruction,
                                          ),
                                        ),
                                      )
                                    : _buildInstruction(
                                        theme.primaryColor,
                                        isDark,
                                        quest.instruction,
                                      ),
                                SizedBox(height: gapInstruction),
                                isCompact
                                    ? SizedBox(
                                        height: 80.h,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: CollocationAnchorBubble(
                                            text: quest.word ?? "",
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                          ),
                                        ),
                                      )
                                    : CollocationAnchorBubble(
                                        text: quest.word ?? "",
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                      ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: gapAnchor),
                                isCompact
                                    ? SizedBox(
                                        height: 100.h,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: SizedBox(
                                            width: constraints.maxWidth,
                                            child: _buildOptionsWrap(
                                              quest,
                                              theme.primaryColor,
                                              isDark,
                                              state is VocabularyLoaded
                                                  ? state.isFinalFailure
                                                  : false,
                                              isCompact,
                                            ),
                                          ),
                                        ),
                                      )
                                    : _buildOptionsWrap(
                                        quest,
                                        theme.primaryColor,
                                        isDark,
                                        state is VocabularyLoaded
                                            ? state.isFinalFailure
                                            : false,
                                        isCompact,
                                      ),
                                SizedBox(height: gapBottom),
                              ],
                            ),
                          ],
                        ),
                        if (_isFirstStagePassed &&
                            (!_isAnswered || _isCorrect == null))
                          DynamicAnagramWrapper(
                            expectedText: quest.correctAnswer ?? '',
                            primaryColor: theme.primaryColor,
                            onConfirmed: () => _submitFinalAnswer(true),
                            onFailed: () {}, // Optional empty handler
                            onFailedWithSpelling: (wrongWord) => _submitFinalAnswer(false),
                          ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildOptionsWrap(
    VocabularyQuest quest,
    Color color,
    bool isDark,
    bool isFinalFailure,
    bool isCompact,
  ) {
    return Wrap(
      spacing: 20.w,
      runSpacing: isCompact ? 15.h : 30.h,
      alignment: WrapAlignment.center,
      children: (quest.options ?? []).asMap().entries.map((entry) {
        return CollocationOptionBubble(
          text: entry.value,
          correct: quest.correctAnswer ?? "",
          color: color,
          isDark: isDark,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          selectedOption: _selectedOption,
          isFinalFailure: isFinalFailure,
          isFirstStagePassed: _isFirstStagePassed,
          index: entry.key,
          onTap: () {
            if (!_isAnswered) {
              _hapticService.light();
              _submitAnswer(entry.value, quest.correctAnswer ?? "");
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildInstruction(Color color, bool isDark, String instruction) {
    return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark
                ? color.withValues(alpha: 0.1)
                : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            instruction.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 2.seconds);
  }
}
