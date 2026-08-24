import 'package:flutter/material.dart';
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
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_instruction.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_floating_tile.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_assembly_card.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_check_button.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';

class WordReorderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const WordReorderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.wordReorder,
  });

  @override
  State<WordReorderScreen> createState() => _WordReorderScreenState();
}

class _WordReorderScreenState extends State<WordReorderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final List<int> _availableIndices = [];
  final List<int> _assembledIndices = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  bool _pendingTypeSubmit = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onWordTap(int index) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _assembledIndices.add(index);
      _availableIndices.remove(index);
    });
  }

  void _onWordRemove(int index) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _assembledIndices.remove(index);
      _availableIndices.add(index);
      _availableIndices.sort();
    });
  }

  void _checkSentence(List<int> correctOrder) {
    if (_assembledIndices.isEmpty) return;

    bool correct = _assembledIndices.length == correctOrder.length;
    if (correct) {
      for (int i = 0; i < correctOrder.length; i++) {
        if (_assembledIndices[i] != correctOrder[i]) {
          correct = false;
          break;
        }
      }
    }

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() => _pendingTypeSubmit = true);
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
    setState(() => _pendingTypeSubmit = false);

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
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
          final isRetry = _isAnswered && !state.answerStatus.isAnswered;
          final livesRestored =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesRestored) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _pendingTypeSubmit = false;

              _assembledIndices.clear();
              _availableIndices.clear();
              final quest = state.currentQuest;
              if (quest.shuffledWords != null) {
                _availableIndices.addAll(
                  List.generate(quest.shuffledWords!.length, (i) => i),
                );
              }
            });
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
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
            title: 'SYNTAX SHARPSHOOTER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final hintUsed = (state is GrammarLoaded) ? state.hintUsed : false;
        final shuffledWords = quest?.shuffledWords ?? [];
        final correctOrder = quest?.correctOrder ?? [];
        final expectedNextIndex =
            (hintUsed && _assembledIndices.length < correctOrder.length)
            ? correctOrder[_assembledIndices.length]
            : -1;

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () =>
              context.read<GrammarBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<GrammarBloc>().add(const GrammarHintUsed()),
          useScrolling: false,
          child: quest == null
              ? const SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          SizedBox(height: 10.h),
                          WordReorderInstruction(primaryColor: theme.primaryColor),
                          SizedBox(height: 16.h),
                          if (quest.structureType != null)
                            Container(
                              margin: EdgeInsets.only(bottom: 16.h, left: 24.w, right: 24.w),
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.account_tree_outlined, color: theme.primaryColor, size: 16.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    "TARGET STRUCTURE: ${quest.structureType!.toUpperCase()}",
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w800,
                                      color: theme.primaryColor,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 8.h),
                          WordReorderAssemblyCard(
                            assembledIndices: _assembledIndices,
                            shuffledWords: shuffledWords,
                            primaryColor: theme.primaryColor,
                            isDark: isDark,
                            isAnswered: _isAnswered,
                            onWordRemove: _onWordRemove,
                          ),
                          SizedBox(height: 30.h),
                        ],
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Wrap(
                              spacing: 12.w,
                              runSpacing: 16.h,
                              alignment: WrapAlignment.center,
                              children: _availableIndices.map((idx) {
                                return WordReorderFloatingTile(
                                  word: shuffledWords[idx],
                                  index: idx,
                                  onTap: () => _onWordTap(idx),
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  isHighlighted: idx == expectedNextIndex,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        if (!_isAnswered && !_pendingTypeSubmit)
                          WordReorderCheckButton(
                            hasWords: _assembledIndices.isNotEmpty,
                            isDark: isDark,
                            primaryColor: theme.primaryColor,
                            onCheck: () => _checkSentence(correctOrder),
                          ),
                        if (_pendingTypeSubmit && !_isAnswered)
                          TypeToConfirmOverlay(
                            expectedText: correctOrder.map((idx) => shuffledWords[idx]).join(" "),
                            primaryColor: theme.primaryColor,
                            onConfirmed: () => _submitFinalAnswer(true),
                            onSkipped: () => _submitFinalAnswer(false),
                            isPositioned: false,
                          ),
                        SizedBox(height: _isAnswered ? 160.h : 60.h),
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
  }
}
