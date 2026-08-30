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
import 'package:vowl/features/vocabulary/contextual_usage/presentation/widgets/contextual_usage_painters.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/widgets/contextual_usage_card.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/widgets/contextual_usage_option_chip.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/widgets/contextual_usage_register_meter.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';


class ContextualUsageScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ContextualUsageScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.contextualUsage,
  });

  @override
  State<ContextualUsageScreen> createState() => _ContextualUsageScreenState();
}

class _ContextualUsageScreenState extends State<ContextualUsageScreen> {
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

  @override
  void dispose() {
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _isFirstStagePassed.dispose();
    _selectedOption.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitAnswer(String selected, String correct) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    
    _selectedOption.value = selected;
    _isAnswered.value = true;

    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();
        
    Future.delayed(600.ms, () {
      if (!mounted) return;
      if (isCorrect) {
        _hapticService.success();
        _isFirstStagePassed.value = true;
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
        _hapticService.error();
        _soundService.playWrong();
        _isCorrect.value = false;
        context.read<VocabularyBloc>().add(SubmitAnswer(false));
      }
    });
  }

  void _submitFinalAnswer(bool nailedIt, {String? wrongWord}) {
    if (_isAnswered.value && _isCorrect.value != null) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;
    if (wrongWord != null && wrongWord.isNotEmpty) {
      _selectedOption.value = wrongWord;
    }

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
            title: 'USAGE EXPERT!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );
        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;

        if (state is VocabularyLoading ||
            (quest == null &&
                state is! VocabularyGameComplete &&
                state is! VocabularyError)) {
          return Scaffold(
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _isFirstStagePassed, _selectedOption]),
          builder: (context, _) {
            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value && (_isCorrect.value != null || !_isFirstStagePassed.value),
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
                        return Stack(
                          children: [
                            CustomScrollView(
                              controller: _scrollController,
                              physics: (!_isFirstStagePassed.value) ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                              slivers: [
                            SliverToBoxAdapter(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: Stack(
                            children: [
                              Positioned.fill(
                            child: CustomPaint(
                              painter: GridPainter(
                                theme.primaryColor.withValues(
                                  alpha: isDarkMode ? 0.05 : 0.03,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              _buildUnfoldContent(quest, theme.primaryColor, isDarkMode, constraints.maxHeight, constraints.maxWidth),
                              if (_isFirstStagePassed.value)
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                                  child: Column(
                                    children: [
                                      if (quest.registerLevel != null || quest.nuanceDifference != null || quest.usageExample != null || quest.contextSentence != null || quest.example != null)
                                        ContextualUsageRegisterMeter(
                                          registerLevel: quest.registerLevel,
                                          nuanceDifference: quest.nuanceDifference,
                                          usageExample: quest.usageExample ?? quest.contextSentence ?? quest.example,
                                          color: theme.primaryColor,
                                        ),
                                    ],
                                  ),
                                ),
                              SizedBox(height: (_isAnswered.value || _isFirstStagePassed.value) ? 400.h : 60.h),
                            ],
                          ),
                        ],
                      ),
                      ),
                    ),
                  ],
                ),
                if (_isFirstStagePassed.value && (!_isAnswered.value || _isCorrect.value == null))
                  SpeakToConfirmOverlay(
                    expectedText: (quest.prompt ?? "").replaceAll(RegExp(r'_+'), quest.correctAnswer ?? ""),
                    primaryColor: theme.primaryColor,
                    onConfirmed: () => _submitFinalAnswer(true),
                    onSkipped: () => _submitFinalAnswer(false),
                    isPositioned: true,
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

  Widget _buildUnfoldContent(VocabularyQuest quest, Color color, bool isDark, double maxHeight, double maxWidth) {
        final isCompact = maxHeight < 580;

        final double estimatedContentHeight =
            (isCompact ? 40.h : 60.h) +
            (isCompact ? 100.h : 150.h) +
            (isCompact ? 80.h : 120.h) +
            20.h;
        final remainingHeight = maxHeight - estimatedContentHeight;

        final double gapUnit = remainingHeight > 0 ? remainingHeight / 5 : 0;
        final double gapTop = remainingHeight > 0
            ? (gapUnit * 1).clamp(10.0, 40.0)
            : 10.0;
        final double gapMiddle = remainingHeight > 0
            ? (gapUnit * 1.5).clamp(15.0, 40.0)
            : 15.0;
        final double gapBottom = remainingHeight > 0
            ? (gapUnit * 2.5).clamp(20.0, 60.0)
            : 20.0;

        return Column(
              children: [
                SizedBox(height: gapTop),
                isCompact
                    ? SizedBox(
                        height: 25.h,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            quest.instruction.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              color: color,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Text(
                            quest.instruction.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              color: color,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 800.ms)
                          .shimmer(duration: 2.seconds),

                SizedBox(height: gapMiddle),

                isCompact
                    ? SizedBox(
                        height: 120.h,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: maxWidth - 40.w,
                            child: ContextualUsageCard(
                              question: quest.prompt ?? "",
                              color: color,
                              isDark: isDark,
                              isAnswered: _isAnswered.value,
                              isCorrect: _isCorrect.value,
                              selectedOption: _selectedOption.value,
                            ),
                          ),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: ContextualUsageCard(
                          question: quest.prompt ?? "",
                          color: color,
                          isDark: isDark,
                          isAnswered: _isAnswered.value,
                          isCorrect: _isCorrect.value,
                          selectedOption: _selectedOption.value,
                        ),
                      ),

                SizedBox(height: gapMiddle),

                isCompact
                    ? SizedBox(
                        height: 100.h,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: maxWidth,
                            child: _buildChipsWrap(
                              quest,
                              color,
                              isDark,
                              isCompact,
                            ),
                          ),
                        ),
                      )
                    : (!_isFirstStagePassed.value) ? _buildChipsWrap(quest, color, isDark, isCompact) : const SizedBox.shrink(),
                SizedBox(height: gapBottom),
              ],
            );
  }

  Widget _buildChipsWrap(
    VocabularyQuest quest,
    Color color,
    bool isDark,
    bool isCompact,
  ) {
    return Wrap(
          spacing: 16.w,
          runSpacing: isCompact ? 10.h : 16.h,
          alignment: WrapAlignment.center,
          children: (quest.options ?? []).map((o) {
            return ContextualUsageOptionChip(
              text: o,
              color: color,
              isDark: isDark,
              isSelected: _selectedOption.value == o,
              isCorrect: _isCorrect.value,
              onTap: () => _submitAnswer(o, quest.correctAnswer ?? ""),
            );
          }).toList(),
        )
        .animate()
        .fadeIn(delay: 600.ms)
        .slideY(begin: 0.2, curve: Curves.easeOutCubic);
  }
}
