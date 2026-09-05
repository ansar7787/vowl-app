import 'package:vowl/core/utils/instruction_helper.dart';
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
import 'package:vowl/features/listening/audio_multiple_choice/presentation/widgets/audio_multiple_choice_instruction.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/widgets/audio_multiple_choice_question.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/widgets/audio_multiple_choice_spinner.dart';
import 'package:vowl/core/presentation/game_mechanics/evidence_highlight_wrapper.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class AudioMultipleChoiceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AudioMultipleChoiceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.audioMultipleChoice,
  });

  @override
  State<AudioMultipleChoiceScreen> createState() =>
      _AudioMultipleChoiceScreenState();
}

class _AudioMultipleChoiceScreenState extends State<AudioMultipleChoiceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<double> _rotation = ValueNotifier(0.0);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _selectedIndex.dispose();
    _rotation.dispose();
    _scrollController.dispose();
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
    if (_isAnswered.value) return;

    _selectedIndex.value = index;
    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _isAnswered.value = true;
      _isCorrect.value = true;
      context.read<ListeningBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<ListeningBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: (context, state) {
        if (state is ListeningLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _selectedIndex.value = null;
            _rotation.value = 0.0;
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SONIC RADAR!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _selectedIndex,
            _rotation,
          ]),
          builder: (context, _) {
            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
              useScrolling: false,
              onContinue: () =>
                  context.read<ListeningBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<ListeningBloc>().add(ListeningHintUsed()),
              child: quest == null
                  ? const SizedBox()
                  : Stack(
                      children: [
                        RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            controller: _scrollController,
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
                                      AudioMultipleChoiceInstruction(
                                        color: theme.primaryColor,
                                        instruction:
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                      ),
                                      SizedBox(height: 24.h),
                                      AudioMultipleChoiceQuestion(
                                        text: quest.question ?? "",
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 16.h,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (_isAnswered.value &&
                                          quest.audioTranscript != null)
                                        SizedBox(
                                          height: 350.h,
                                          child: EvidenceHighlightWrapper(
                                            passage: quest.audioTranscript!,
                                            evidenceWords: [
                                              quest.correctAnswer ??
                                                  quest.options?[quest
                                                          .correctAnswerIndex ??
                                                      0] ??
                                                  '',
                                            ],
                                            primaryColor: theme.primaryColor,
                                            isPositioned: false,
                                            onCorrectHighlight: () {},
                                            onWrongHighlight: () {
                                              final authState = context
                                                  .read<AuthBloc>()
                                                  .state;
                                              if (authState.status ==
                                                      AuthStatus
                                                          .authenticated &&
                                                  authState.user != null) {
                                                ErrorJournalCollector.record(
                                                  userId: authState.user!.id,
                                                  gameType:
                                                      widget.gameType.name,
                                                  question:
                                                      'Evidence Highlight',
                                                  userAnswer:
                                                      '[Wrong evidence tap]',
                                                  correctAnswer:
                                                      quest.correctAnswer ?? '',
                                                  level: widget.level,
                                                );
                                              }
                                            },
                                          ),
                                        )
                                      else
                                        SizedBox(
                                          height: 350.h,
                                          child: AudioMultipleChoiceSpinner(
                                            options: quest.options ?? [],
                                            correct:
                                                quest.correctAnswerIndex ?? 0,
                                            color: theme.primaryColor,
                                            tts: quest.textToSpeak ?? "",
                                            emoji: quest.emoji,
                                            rotation: _rotation.value,
                                            selectedIndex: _selectedIndex.value,
                                            isAnswered: _isAnswered.value,
                                            isCorrectState: _isCorrect.value,
                                            onSpin: (delta) {
                                              if (!_isAnswered.value) {
                                                _rotation.value += delta * 0.01;
                                              }
                                            },
                                            onSelectSatellite: (index) {
                                              _submitFinalAnswer(
                                                index,
                                                quest.correctAnswerIndex ?? 0,
                                              );
                                            },
                                            onTapCore: () {
                                              _soundService.playTts(
                                                quest.textToSpeak ?? "",
                                              );
                                              _hapticService.selection();
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
