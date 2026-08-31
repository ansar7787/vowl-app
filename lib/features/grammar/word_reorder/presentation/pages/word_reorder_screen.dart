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
  final ValueNotifier<List<int>> _availableIndices = ValueNotifier([]);
  final ValueNotifier<List<int>> _assembledIndices = ValueNotifier([]);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _pendingTypeSubmit = ValueNotifier(false);

  @override
  void dispose() {
    _availableIndices.dispose();
    _assembledIndices.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _pendingTypeSubmit.dispose();
    super.dispose();
  }
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
    if (_isAnswered.value) return;
    _hapticService.selection();
    _assembledIndices.value = List.from(_assembledIndices.value)..add(index);
    _availableIndices.value = List.from(_availableIndices.value)..remove(index);
  }

  void _onWordRemove(int index) {
    if (_isAnswered.value) return;
    _hapticService.selection();
    _assembledIndices.value = List.from(_assembledIndices.value)..remove(index);
    _availableIndices.value = List.from(_availableIndices.value)..add(index)..sort();
  }

  void _checkSentence(List<int> correctOrder) {
    if (_assembledIndices.value.isEmpty) return;

    bool correct = _assembledIndices.value.length == correctOrder.length;
    if (correct) {
      for (int i = 0; i < correctOrder.length; i++) {
        if (_assembledIndices.value[i] != correctOrder[i]) {
          correct = false;
          break;
        }
      }
    }

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      _pendingTypeSubmit.value = true;
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
    _pendingTypeSubmit.value = false;

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      _isAnswered.value = true;
      _isCorrect.value = true;
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
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
            _pendingTypeSubmit.value = false;

            _assembledIndices.value = [];
            final quest = state.currentQuest;
            if (quest.shuffledWords != null) {
              _availableIndices.value = List.generate(quest.shuffledWords!.length, (i) => i);
            } else {
              _availableIndices.value = [];
            }
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
            (hintUsed && _assembledIndices.value.length < correctOrder.length)
            ? correctOrder[_assembledIndices.value.length]
            : -1;

        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _availableIndices, _assembledIndices, _pendingTypeSubmit]),
          builder: (context, _) {
            return GrammarBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: _showConfetti.value,
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
                            assembledIndices: _assembledIndices.value,
                            shuffledWords: shuffledWords,
                            primaryColor: theme.primaryColor,
                            isDark: isDark,
                            isAnswered: _isAnswered.value,
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
                              children: _availableIndices.value.map((idx) {
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
                        if (!_isAnswered.value && !_pendingTypeSubmit.value)
                          WordReorderCheckButton(
                            hasWords: _assembledIndices.value.isNotEmpty,
                            isDark: isDark,
                            primaryColor: theme.primaryColor,
                            onCheck: () => _checkSentence(correctOrder),
                          ),
                      ],
                    ),
                  ),
                if (_pendingTypeSubmit.value && !_isAnswered.value)
                  SliverToBoxAdapter(
                    child: TypeToConfirmOverlay(
                      expectedText: correctOrder.map((idx) => shuffledWords[idx]).join(" "),
                      primaryColor: theme.primaryColor,
                      onConfirmed: () => _submitFinalAnswer(true),
                      onSkipped: () => _submitFinalAnswer(false),
                      isPositioned: false,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: _isAnswered.value ? 160.h : 60.h),
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
}
