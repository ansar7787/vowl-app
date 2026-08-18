import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_event.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/widgets/detail_spotlight_instruction.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/widgets/detail_spotlight_emitter.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/widgets/detail_spotlight_prompt.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/widgets/detail_spotlight_dark_field.dart';

class DetailSpotlightScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DetailSpotlightScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.detailSpotlight,
  });

  @override
  State<DetailSpotlightScreen> createState() => _DetailSpotlightScreenState();
}

class _DetailSpotlightScreenState extends State<DetailSpotlightScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  int? _selectedIndex;
  final ValueNotifier<Offset> _spotlightPos = ValueNotifier(const Offset(0, 0));

  @override
  void dispose() {
    _spotlightPos.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitFinalAnswer(int index, int correct) {
    if (_isAnswered) return;
    
    setState(() => _selectedIndex = index);
    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<ListeningBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<ListeningBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: (context, state) {
        if (state is ListeningLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
              _spotlightPos.value = const Offset(0, 0);
            });
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SPECIFIC PULSER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;

        return ListeningBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          useScrolling: false,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: 6.h),
                                DetailSpotlightInstruction(
                                  isAnswered: _isAnswered,
                                  color: theme.primaryColor,
                                  instruction: quest.instruction,
                                ),
                                SizedBox(height: 24.h),
                                DetailSpotlightEmitter(
                                  onTap: () {
                                    _soundService.playTts(
                                      quest.textToSpeak ?? "",
                                    );
                                    _hapticService.selection();
                                  },
                                  color: theme.primaryColor,
                                  emoji: quest.emoji,
                                  isCorrectState: _isCorrect,
                                ),
                                SizedBox(height: 32.h),
                                DetailSpotlightPrompt(
                                  isAnswered: _isAnswered,
                                  detail: quest.targetDetail ?? "Detail",
                                  color: theme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  height: 350.h,
                                  child: DetailSpotlightDarkField(
                                    options: quest.options ?? [],
                                    correctAnswerIndex: quest.correctAnswerIndex ?? 0,
                                    color: theme.primaryColor,
                                    isAnswered: _isAnswered,
                                    isCorrectState: _isCorrect,
                                    selectedIndex: _selectedIndex,
                                    spotlightPos: _spotlightPos,
                                    onSearch: (pos) {
                                      if (!_isAnswered) {
                                        _spotlightPos.value = pos;
                                      }
                                    },
                                    onSelect: (index) {
                                      _submitFinalAnswer(
                                        index,
                                        quest.correctAnswerIndex ?? 0,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}
