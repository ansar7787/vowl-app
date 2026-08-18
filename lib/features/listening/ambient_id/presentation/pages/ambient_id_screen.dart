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
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/listening/ambient_id/presentation/widgets/ambient_id_instruction.dart';
import 'package:vowl/features/listening/ambient_id/presentation/widgets/ambient_id_sonar_field.dart';
import 'package:vowl/features/listening/ambient_id/presentation/widgets/ambient_id_emitter_node.dart';

class AmbientIdScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AmbientIdScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.ambientId,
  });

  @override
  State<AmbientIdScreen> createState() => _AmbientIdScreenState();
}

class _AmbientIdScreenState extends State<AmbientIdScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late AnimationController _radarController;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _submitAnswer(int index, int correct) {
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
            title: 'CONTEXT ANCHOR!',
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
          onHint: () {
            if (quest != null && quest.hint != null && quest.hint!.isNotEmpty) {
              GameDialogHelper.showHintDialog(context, hint: quest.hint!);
            }
          },
          child: quest == null
              ? const SizedBox()
              : CustomScrollView(
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
                              AmbientIdInstruction(
                                color: theme.primaryColor,
                                instruction: context.tr(
                                  'games.ambientId_instruction',
                                  fallback:
                                      'Listen to the sounds and find the location.',
                                ),
                              ),
                              SizedBox(height: 24.h),
                              AmbientIdSonarField(
                                options: quest.options ?? [],
                                correctAnswerIndex:
                                    quest.correctAnswerIndex ?? 0,
                                color: theme.primaryColor,
                                radarController: _radarController,
                                isAnswered: _isAnswered,
                                isCorrectState: _isCorrect,
                                selectedIndex: _selectedIndex,
                                onSubmitAnswer: (index) => _submitAnswer(
                                  index,
                                  quest.correctAnswerIndex ?? 0,
                                ),
                                imageUrl: quest.imageUrl,
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
                              AmbientIdEmitterNode(
                                onTap: () {
                                  _soundService.playTts(
                                    quest.textToSpeak ?? "",
                                  );
                                  _hapticService.selection();
                                },
                                color: theme.primaryColor,
                              ),
                              SizedBox(height: 20.h),
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
}
