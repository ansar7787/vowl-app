import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/widgets/direct_indirect_speech_instruction.dart';
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/widgets/direct_indirect_speech_mirror.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';

class DirectIndirectSpeechScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DirectIndirectSpeechScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.directIndirectSpeech,
  });

  @override
  State<DirectIndirectSpeechScreen> createState() =>
      _DirectIndirectSpeechScreenState();
}

class _DirectIndirectSpeechScreenState
    extends State<DirectIndirectSpeechScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<double> _rotation = ValueNotifier(0.0);
  final ValueNotifier<int> _selectedReflection = ValueNotifier(-1);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _rotation.dispose();
    _selectedReflection.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _isFirstStagePassed.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  int _lastProcessedIndex = -1;
  int? _lastLives;

  void _onStagePassedScroll() {
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

  @override
  void initState() {
    super.initState();
    _isFirstStagePassed.addListener(_onStagePassedScroll);

    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onReflectionSelect(int index, int correctIndex) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _selectedReflection.value = index;

    bool isCorrect = index == correctIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _isFirstStagePassed.value = true;
      _scrollToBottom();
      _rotation.value = 3.14;
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      _rotation.value = 3.14;
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;
    _isAnswered.value = true;
    _isCorrect.value = nailedIt;
    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
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
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesRestored =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesRestored) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isFirstStagePassed.value = false;
            _selectedReflection.value = -1;
            _rotation.value = 0.0;
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
            title: 'SHADOW MASTER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final GrammarQuest? quest = (state is GrammarLoaded)
            ? state.currentQuest as GrammarQuest?
            : null;
        final rawQuestion = quest?.question ?? "DIRECT SPEECH";
        String displayDirect = quest?.sentence ?? "";
        if (displayDirect.isEmpty) {
          if (rawQuestion.contains(':')) {
            displayDirect = rawQuestion
                .split(':')
                .last
                .replaceAll('"', '')
                .trim();
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

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _isFirstStagePassed,
            _selectedReflection,
            _rotation,
          ]),
          builder: (context, _) {
            return GrammarBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  _isAnswered.value &&
                  (_isCorrect.value != null || !_isFirstStagePassed.value),
              isCorrect: _isCorrect.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: _showConfetti.value,
              useScrolling: false,
              onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
              onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final maxHeight = constraints.maxHeight;
                        final isCompact = maxHeight < 600;

                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          crossAxisMargin: 2,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    SizedBox(height: isCompact ? 16.h : 24.h),
                                    isCompact
                                        ? SizedBox(
                                            height: 25.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child:
                                                  DirectIndirectSpeechInstruction(
                                                    primaryColor:
                                                        theme.primaryColor,
                                                  ),
                                            ),
                                          )
                                        : DirectIndirectSpeechInstruction(
                                            primaryColor: theme.primaryColor,
                                          ),
                                    SizedBox(height: isCompact ? 12.h : 20.h),
                                    if (quest.grammarRule != null ||
                                        (quest.changesList != null &&
                                            quest.changesList!.isNotEmpty)) ...[
                                      _buildRuleAndChangesBox(
                                        quest,
                                        theme,
                                        isCompact,
                                      ),
                                      SizedBox(height: isCompact ? 12.h : 20.h),
                                    ],
                                    DirectIndirectSpeechMirror(
                                      rotation: _rotation.value,
                                      directText: displayDirect,
                                      indirectText: displayIndirect,
                                      isCorrect: _isCorrect.value,
                                      isDark: isDark,
                                      primaryColor: theme.primaryColor,
                                      isCompact: isCompact,
                                    ),
                                    SizedBox(height: isCompact ? 16.h : 30.h),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: isCompact ? 8.w : 12.w,
                                      runSpacing: isCompact ? 8.h : 12.h,
                                      children: List.generate(
                                        options.length,
                                        (i) => _buildReflectionChip(
                                          options[i],
                                          i,
                                          quest.correctAnswerIndex ?? 0,
                                          theme.primaryColor,
                                          isDark,
                                          isCompact,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height:
                                      (_isFirstStagePassed.value &&
                                          !_isAnswered.value)
                                      ? 32.h
                                      : 60.h,
                                ),
                              ),
                              if (_isFirstStagePassed.value &&
                                  !_isAnswered.value)
                                SliverToBoxAdapter(
                                  child: TypeToConfirmOverlay(
                                    expectedText:
                                        options[_selectedReflection.value],
                                    primaryColor: theme.primaryColor,
                                    onConfirmed: () =>
                                        _submitVerbalEvaluation(true),
                                    onSkipped: () =>
                                        _submitVerbalEvaluation(false),
                                    isPositioned: false,
                                    displayText:
                                        "Type the indirect speech to lock it in",
                                  ),
                                ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).viewInsets.bottom >
                                          0
                                      ? MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom +
                                            40.h
                                      : 120.h,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildRuleAndChangesBox(
    GrammarQuest quest,
    ThemeResult theme,
    bool isCompact,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          if (quest.grammarRule != null)
            Text(
              quest.grammarRule!.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 10.sp : 12.sp,
                color: theme.primaryColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          if (quest.grammarRule != null &&
              quest.changesList != null &&
              quest.changesList!.isNotEmpty)
            SizedBox(height: 8.h),
          if (quest.changesList != null && quest.changesList!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: quest.changesList!.map((change) {
                final parts = change.split('->');
                if (parts.length != 2) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      change,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: isCompact ? 9.sp : 11.sp,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        parts[0].trim(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: isCompact ? 9.sp : 11.sp,
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: isCompact ? 10.sp : 12.sp,
                          color: theme.primaryColor.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        parts[1].trim(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: isCompact ? 9.sp : 11.sp,
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildReflectionChip(
    String text,
    int index,
    int correctIndex,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final isSelected = _selectedReflection.value == index;
    final isCorrect =
        (_isAnswered.value || _isFirstStagePassed.value) &&
        index == correctIndex;
    final isWrong = _isAnswered.value && isSelected && index != correctIndex;

    final displayColor = isCorrect
        ? Colors.greenAccent
        : (isWrong
              ? Colors.redAccent
              : (isSelected
                    ? primaryColor
                    : (isDark ? Colors.white : Colors.black87)));

    final bgColor = isCorrect
        ? Colors.greenAccent.withValues(alpha: 0.2)
        : (isWrong
              ? Colors.redAccent.withValues(alpha: 0.2)
              : (isSelected ? primaryColor.withValues(alpha: 0.2) : null));

    final borderColor = isCorrect
        ? Colors.greenAccent
        : (isWrong
              ? Colors.redAccent
              : (isSelected
                    ? primaryColor
                    : Colors.white.withValues(alpha: 0.1)));

    return ScaleButton(
      onTap: () => _onReflectionSelect(index, correctIndex),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        child: GlassTile(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16.w : 24.w,
            vertical: isCompact ? 12.h : 20.h,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isCompact ? 16.r : 24.r),
            topRight: Radius.circular(isCompact ? 16.r : 24.r),
            bottomLeft: Radius.circular(isCompact ? 16.r : 24.r),
            bottomRight: Radius.circular(4.r), // Speech bubble tail
          ),
          color: bgColor,
          border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1.5),
          child: Row(
            children: [
              Icon(
                isCorrect
                    ? Icons.check_circle_rounded
                    : (isWrong
                          ? Icons.cancel_rounded
                          : Icons.chat_bubble_outline_rounded),
                size: isCompact ? 18.r : 24.r,
                color: displayColor.withValues(alpha: 0.8),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: isCompact ? 14.sp : 16.sp,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: displayColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
