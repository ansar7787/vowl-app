import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_painters.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_lcd.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_vault_handle.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_option_key.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_literal_comparison.dart';
import 'package:vowl/core/presentation/game_mechanics/context_sentence_builder.dart';

class PhrasalVerbsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PhrasalVerbsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.phrasalVerbs,
  });

  @override
  State<PhrasalVerbsScreen> createState() => _PhrasalVerbsScreenState();
}

class _PhrasalVerbsScreenState extends State<PhrasalVerbsScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);
  final ValueNotifier<String?> _selectedOption = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  late AnimationController _vaultController;

  @override
  void initState() {
    super.initState();
    _vaultController = AnimationController(vsync: this, duration: 1.seconds);
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _isFirstStagePassed.dispose();
    _selectedOption.dispose();
    _scrollController.dispose();
    _vaultController.dispose();
    super.dispose();
  }

  void _submitChoice(String selected, String correct) async {
    if (_isAnswered.value || _isFirstStagePassed.value || _selectedOption.value != null) return;

    _selectedOption.value = selected;
    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.selection();
      _vaultController.forward(from: 0);
      _isFirstStagePassed.value = true;
      
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  String? _getFormattedExampleSentence(VocabularyQuest quest) {
    String? sentence = quest.contextSentence;

    if (sentence == null || sentence.isEmpty) {
      if (quest.explanation != null && quest.explanation!.isNotEmpty) {
        final matches = RegExp(r"'([^']+)'").allMatches(quest.explanation!);
        if (matches.isNotEmpty) {
          sentence = matches.last.group(1);
        }
      }
    }

    if (sentence == null || sentence.isEmpty) return null;

    final word = quest.word ?? "";
    final answer = quest.correctAnswer ?? "";

    // Determine which part of the phrasal verb is missing in the sentence
    final replacementWord = sentence.contains(answer) ? word : answer;
    
    if (sentence.contains('__')) {
      return sentence.replaceAll('__', replacementWord);
    }
    return sentence;
  }

  void _submitFinalAnswer(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;

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
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;

          if (isNewQuestion || isRetry) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
              );
            }
            _lastQuest = state.currentQuest;
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _selectedOption.value = null;
            _isFirstStagePassed.value = false;
            _vaultController.reset();
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
        }
        if (state is VocabularyGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'VAULT CRACKED!',
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
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;
        final isFinalFailure = (state is VocabularyLoaded)
            ? state.isFinalFailure
            : false;

        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _isFirstStagePassed, _selectedOption]),
          builder: (context, _) {
            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
              onContinue: () {
                final currentState = context.read<VocabularyBloc>().state;
                if (currentState is VocabularyLoaded &&
                    !currentState.isFinalFailure &&
                    _isCorrect.value == false) {
                  _isAnswered.value = false;
                  _isCorrect.value = null;
                  _isFirstStagePassed.value = false;
                  _selectedOption.value = null;
                  _vaultController.reset();
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
                  ? const SizedBox()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final maxHeight = constraints.maxHeight;
                        final isCompact = maxHeight < 580;

                        final double estimatedContentHeight =
                            (isCompact ? 30.h : 40.h) +
                            (quest.instruction.isNotEmpty
                                ? (isCompact ? 60.h : 80.h)
                                : 0) +
                            (isCompact ? 70.h : 90.h) +
                            (isCompact ? 110.h : 160.h) +
                            (isCompact ? 90.h : 130.h) +
                            20.h;
                        final remainingHeight =
                            maxHeight - estimatedContentHeight;

                        final double gapUnit = remainingHeight > 0
                            ? remainingHeight / 6
                            : 0;
                        final double gapTop = remainingHeight > 0
                            ? (gapUnit * 1).clamp(6.0, 24.0)
                            : 6.0;
                        final double gapMiddle = remainingHeight > 0
                            ? (gapUnit * 1.5).clamp(10.0, 30.0)
                            : 10.0;
                        final double gapBottom = remainingHeight > 0
                            ? (gapUnit * 2).clamp(12.0, 40.0)
                            : 12.0;

                        return CustomScrollView(
                          controller: _scrollController,
                          physics: (!_isFirstStagePassed.value) ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: maxHeight),
                                child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: GridPainter(
                                theme.primaryColor.withValues(
                                  alpha: isDark ? 0.05 : 0.03,
                                ),
                              ),
                            ),
                          ),
                          Column(
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
                                            height: 30.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: _buildVaultStatus(
                                                theme.primaryColor,
                                                isDark,
                                              ),
                                            ),
                                          )
                                        : _buildVaultStatus(
                                            theme.primaryColor,
                                            isDark,
                                          ),
                                    if (quest.instruction.isNotEmpty) ...[
                                      SizedBox(height: gapTop / 2),
                                      _buildInstruction(
                                        quest.instruction,
                                        theme.primaryColor,
                                        isCompact,
                                      ),
                                    ],
                                    SizedBox(height: gapMiddle),

                                    // LCD Display
                                    isCompact
                                        ? SizedBox(
                                            height: 70.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width:
                                                    constraints.maxWidth - 40.w,
                                                child: PhrasalVerbsLcd(
                                                  text:
                                                      quest.hint?.replaceFirst(
                                                        "DEFINITION: ",
                                                        "",
                                                      ) ??
                                                      "ANALYZING VAULT...",
                                                  color: theme.primaryColor,
                                                  isDark: isDark,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 20.w,
                                            ),
                                            child: PhrasalVerbsLcd(
                                              text:
                                                  quest.hint?.replaceFirst(
                                                    "DEFINITION: ",
                                                    "",
                                                  ) ??
                                                  "ANALYZING VAULT...",
                                              color: theme.primaryColor,
                                              isDark: isDark,
                                            ),
                                          ),
                                  ],
                                ),

                                // The Central Vault Handle
                                isCompact
                                    ? SizedBox(
                                        height: 110.h,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: PhrasalVerbsVaultHandle(
                                            verb: quest.word ?? "VERB",
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            vaultController: _vaultController,
                                          ),
                                        ),
                                      )
                                    : PhrasalVerbsVaultHandle(
                                        verb: quest.word ?? "VERB",
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                        vaultController: _vaultController,
                                      ),

                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapMiddle),
                                    // Key Options (Particles)
                                    isCompact
                                        ? SizedBox(
                                            height: 90.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width: constraints.maxWidth,
                                                child: _buildOptionsWrap(
                                                  quest,
                                                  theme.primaryColor,
                                                  isDark,
                                                  isFinalFailure,
                                                  isCompact,
                                                  state is VocabularyLoaded
                                                      ? state.hintUsed
                                                      : false,
                                                ),
                                              ),
                                            ),
                                          )
                                        : _buildOptionsWrap(
                                            quest,
                                            theme.primaryColor,
                                            isDark,
                                            isFinalFailure,
                                            isCompact,
                                            state is VocabularyLoaded
                                                ? state.hintUsed
                                                : false,
                                          ),
                                    SizedBox(height: gapBottom),
                                  ],
                                ),
                              ],
                            ),
                            if (_isFirstStagePassed.value && !_isAnswered.value)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: Column(
                                  children: [
                                    if (quest.literalVsFigurative != null && quest.literalVsFigurative!.isNotEmpty) ...[
                                      PhrasalVerbsLiteralComparison(
                                        literalVsFigurative: quest.literalVsFigurative!,
                                        color: theme.primaryColor,
                                      ),
                                      SizedBox(height: 24.h),
                                    ],
                                  ],
                                ),
                              ),
                            if (_isFirstStagePassed.value && !_isAnswered.value)
                              ContextSentenceBuilder(
                                targetKeyword: "${quest.word} ${quest.correctAnswer}".trim(),
                                primaryColor: theme.primaryColor,
                                onConfirmed: () => _submitFinalAnswer(true),
                                onSkipped: () => _submitFinalAnswer(false),
                                isPositioned: false,
                                exampleSentence: _getFormattedExampleSentence(quest),
                              ),
                            SizedBox(height: 40.h),
                          ],
                        ),
                      ],
                    ),
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

  Widget _buildVaultStatus(Color color, bool isDark) {
    return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.vpn_key_rounded, size: 16.r, color: color),
              SizedBox(width: 10.w),
              AutoSizeText(
                "VAULT SECURITY: L-${widget.level}",
                maxLines: 1,
                minFontSize: 4,
                stepGranularity: 0.5,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        )
        .animate()
        .shimmer(duration: 2.seconds);
  }

  Widget _buildInstruction(String text, Color color, bool isCompact) {
    if (text.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: isCompact ? 60.h : 80.h,
      width: double.infinity,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: AutoSizeText(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            minFontSize: 8,
            stepGranularity: 1,
            overflowReplacement: AutoSizeText(
              text,
              textAlign: TextAlign.center,
              maxLines: 4,
              minFontSize: 6,
              stepGranularity: 0.5,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.9),
                height: 1.3,
              ),
            ),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsWrap(
    VocabularyQuest quest,
    Color color,
    bool isDark,
    bool isFinalFailure,
    bool isCompact,
    bool hintUsed,
  ) {
    return Wrap(
      spacing: 15.w,
      runSpacing: isCompact ? 10.h : 15.h,
      alignment: WrapAlignment.center,
      children: (quest.options ?? []).asMap().entries.map((entry) {
        return PhrasalVerbsOptionKey(
          text: entry.value,
          correct: quest.correctAnswer ?? "",
          color: color,
          isDark: isDark,
          isAnswered: _isAnswered.value,
          isCorrect: _isCorrect.value,
          selectedOption: _selectedOption.value,
          isFinalFailure: isFinalFailure,
          index: entry.key,
          isHintUsed: hintUsed,
          onTap: () => _submitChoice(entry.value, quest.correctAnswer ?? ""),
        );
      }).toList(),
    );
  }
}
