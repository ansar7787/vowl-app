import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/morph_injection_rail.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_family_tree.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/controllers/word_formation_controller.dart';

class WordFormationScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const WordFormationScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.wordFormation,
  });

  @override
  State<WordFormationScreen> createState() => _WordFormationScreenState();
}

class _WordFormationScreenState extends State<WordFormationScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late final WordFormationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WordFormationController(
      hapticService: _hapticService,
      soundService: _soundService,
      onSubmitAnswer: (isCorrect) {
        if (mounted) {
          context.read<VocabularyBloc>().add(SubmitAnswer(isCorrect));
        }
      },
    );
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _controller.lastProcessedIndex;
          final isRetry = !state.answerStatus.isAnswered && _controller.isAnswered;

          if (isNewQuestion || isRetry) {
            _controller.reset(state.currentQuest, state.currentIndex, isRetry);
          } else if (state.answerStatus.isAnswered && !_controller.isAnswered) {
            _controller.isAnswered = true;
            _controller.isCorrect = state.answerStatus.asBoolOrNull;
          }
        }
        if (state is VocabularyGameComplete) {
          final xp = state.xpEarned;
          final coins = state.coinsEarned;
          _controller.completeGame();
          if (!context.mounted) return;
          GameDialogHelper.showCompletion(
            context,
            xp: xp,
            coins: coins,
            title: 'WORD ARCHITECT!',
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
                _controller.lastQuest == null &&
                state is! VocabularyLoaded &&
                state is! VocabularyError)) {
          return Scaffold(
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _controller.lastQuest;
        final options = quest?.options ?? [];
        final root = quest?.rootWord ?? quest?.word ?? "";

        // Use hovering suffix if dragging, otherwise use active selection
        final displaySuffixIndex = _controller.hoveringSuffixIndex ?? _controller.activeSuffixIndex;
        final activeSuffix =
            (displaySuffixIndex != null &&
                options.isNotEmpty &&
                displaySuffixIndex < options.length)
            ? options[displaySuffixIndex]
            : null;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _controller.isAnswered,
          isCorrect: _controller.isCorrect,
          showConfetti: _controller.showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () {
            // Find correct suffix index
            final correct = quest?.correctAnswer ?? "";

            // Speak the target word as a powerful audio hint
            if (correct.isNotEmpty) {
              di.sl<TtsService>().speak(correct);
            }

            final options = quest?.options ?? [];
            int? correctIdx;
            for (int i = 0; i < options.length; i++) {
              final cleanS = options[i]
                  .replaceAll('-', '')
                  .trim()
                  .toLowerCase();
              if (correct.toLowerCase().endsWith(cleanS) ||
                  correct.toLowerCase().startsWith(cleanS)) {
                correctIdx = i;
                break;
              }
            }
            if (correctIdx != null) {
              _controller.setHoveringIndex(correctIdx);
              // Auto-reset after a short delay if they don't drag
              Future.delayed(2.seconds, () {
                if (mounted && !_controller.isAnswered) {
                  _controller.setHoveringIndex(null);
                }
              });
            }
          },
          child: quest == null
              ? const SizedBox()
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                    final maxHeight = constraints.maxHeight;
                    final isCompact = maxHeight < 580;

                    // Spacing calculations
                    final double estimatedContentHeight =
                        (isCompact ? 60.h : 80.h) +
                        (isCompact ? 120.h : 180.h) +
                        (options.length * (isCompact ? 46.h : 72.h)) +
                        20.h;
                    final remainingHeight = maxHeight - estimatedContentHeight;

                    final double gapUnit = remainingHeight > 0
                        ? remainingHeight / 5
                        : 0;
                    final double gapTop = remainingHeight > 0
                        ? (gapUnit * 1).clamp(6.0, 20.0)
                        : 6.0;
                    final double gapMiddle = remainingHeight > 0
                        ? (gapUnit * 1.5).clamp(10.0, 25.0)
                        : 10.0;
                    final double gapBottom = remainingHeight > 0
                        ? (gapUnit * 2).clamp(12.0, 30.0)
                        : 12.0;



                    return Column(
                          key: ValueKey(quest.id),
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: gapTop),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child:
                                      _buildInstruction(
                                            theme.primaryColor,
                                            quest,
                                          )
                                          .animate()
                                          .fadeIn(duration: 500.ms)
                                          .slideY(
                                            begin: -0.5,
                                            end: 0,
                                            duration: 500.ms,
                                            curve: Curves.easeOutBack,
                                          ),
                                ),
                                SizedBox(height: gapMiddle),

                                // Reaction Core
                                (isCompact
                                        ? SizedBox(
                                            height: 120.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width: constraints.maxWidth,
                                                child: _buildReactionCore(
                                                  quest,
                                                  root,
                                                  activeSuffix,
                                                  theme.primaryColor,
                                                  isDark,
                                                ),
                                              ),
                                            ),
                                          )
                                        : _buildReactionCore(
                                            quest,
                                            root,
                                            activeSuffix,
                                            theme.primaryColor,
                                            isDark,
                                          ))
                                    .animate()
                                    .scale(
                                      begin: const Offset(0.8, 0.8),
                                      end: const Offset(1.0, 1.0),
                                      duration: 600.ms,
                                      curve: Curves.easeOutBack,
                                    )
                                    .fadeIn(duration: 600.ms),
                              ],
                            ),

                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: gapMiddle),
                                // Injection Rails
                                _buildInjectionRails(
                                  options,
                                  root,
                                  quest.correctAnswer ?? "",
                                  theme.primaryColor,
                                  isDark,
                                  isCompact,
                                ),
                                SizedBox(height: gapBottom),
                              ],
                            ),
                          ],
                    );
                  },
                ),
              ),
              if (_controller.isFirstStagePassed && !_controller.isAnswered)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                    child: Column(
                      children: [
                        if (quest.familyTree != null && quest.familyTree!.isNotEmpty)
                          WordFormationFamilyTree(
                            familyTree: quest.familyTree!,
                            color: theme.primaryColor,
                          ),
                        if (quest.explanation != null && quest.explanation!.isNotEmpty) ...[
                          SizedBox(height: 16.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              quest.explanation!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 20.h),
                        TypeToConfirmOverlay(
                          expectedText: quest.correctAnswer ?? '',
                          displayText: "Type the correct form:\n${quest.correctAnswer?.toUpperCase()}",
                          primaryColor: theme.primaryColor,
                          onConfirmed: () => _controller.submitFinalAnswer(true),
                          onSkipped: () => _controller.submitFinalAnswer(false),
                          onBypassed: () => _controller.submitFinalAnswer(true),
                          isPositioned: false,
                        ),
                        SizedBox(height: 60.h),
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

  Widget _buildInstruction(Color color, GameQuest? quest) {
    final text =
        quest?.hint ??
        quest?.instruction ??
        "Analyze the meaning and select the correct ending.";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: AutoSizeText(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        minFontSize: 8,
        stepGranularity: 1,
        overflowReplacement: AutoSizeText(
          text,
          textAlign: TextAlign.center,
          maxLines: 3,
          minFontSize: 6,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.2,
            height: 1.2,
          ),
        ),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildReactionCore(
    GameQuest? quest,
    String root,
    String? suffix,
    Color color,
    bool isDark,
  ) {
    return SizedBox(
      height: 180.h,
      width: 1.sw,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Energy Field Glow - RepaintBoundary for optimization
          RepaintBoundary(
            child:
                Container(
                      width: 200.r,
                      height: 200.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.15),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                      duration: 2.seconds,
                    ),
          ),

          // Hexagonal Chamber
          RepaintBoundary(
                child: Container(
                  width: 240.w,
                  height: 140.h,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30.r),
                    child: Stack(
                      children: [
                        // Dynamic Liquid/Energy Background
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  color.withValues(alpha: 0.05),
                                  color.withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Word Text with Shimmer
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    ((_controller.isAnswered || _controller.isFirstStagePassed)
                                            ? (quest?.correctAnswer ?? "")
                                            : root)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn().shimmer(duration: 2.seconds),
                              if (suffix != null && !_controller.isAnswered && !_controller.isFirstStagePassed) ...[
                                SizedBox(height: 8.h),
                                Icon(
                                  Icons.add_rounded,
                                  color: color,
                                  size: 20.r,
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      suffix.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ).animate().slideY(begin: 0.5, end: 0),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: -5,
                end: 5,
                duration: 3.seconds,
                curve: Curves.easeInOutQuad,
              ),

          // Particle Orbits - Optimized with RepaintBoundary
          ...List.generate(3, (index) {
            return RepaintBoundary(child: _buildEnergyOrbit(index, color));
          }),
        ],
      ),
    );
  }

  Widget _buildEnergyOrbit(int index, Color color) {
    final duration = (2 + index).seconds;
    return Container(
      width: (260 + (index * 20)).w,
      height: (160 + (index * 20)).h,
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        borderRadius: BorderRadius.circular(100.r),
      ),
    ).animate(onPlay: (c) => c.repeat()).rotate(duration: duration);
  }

  Widget _buildInjectionRails(
    List<String> options,
    String root,
    String correct,
    Color color,
    bool isDark,
    bool isCompact,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: options.asMap().entries.map((entry) {
          return Padding(
                padding: EdgeInsets.only(bottom: isCompact ? 6.h : 12.h),
                child: SizedBox(
                  width: 1.sw,
                  height: isCompact ? 40.h : 60.h,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: 1.sw - 48.w,
                      height: 60.h,
                      child: MorphInjectionRail(
                        index: entry.key,
                        suffix: entry.value,
                        color: color,
                        isDark: isDark,
                        isBlocked: _controller.isAnswered || _controller.isFirstStagePassed,
                        onMorph: (suffix) {
                          _controller.submitMorph(suffix, root, correct, entry.key);
                        },
                        onHover: (index) {
                          if (!_controller.isAnswered && !_controller.isFirstStagePassed) {
                            _controller.setHoveringIndex(index);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: (entry.key * 100).ms)
              .slideX(
                begin: 0.5,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOutCubic,
                delay: (entry.key * 100).ms,
              );
        }).toList(),
      ),
    );
  }
}

