import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/widgets/speech_instruction.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/widgets/speech_context_card.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/widgets/speech_vortex.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/widgets/speech_draggable_word.dart';

class PartsOfSpeechScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PartsOfSpeechScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.partsOfSpeech,
  });

  @override
  State<PartsOfSpeechScreen> createState() => _PartsOfSpeechScreenState();
}

class _PartsOfSpeechScreenState extends State<PartsOfSpeechScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  Offset _dragOffset = Offset.zero;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(FetchGrammarQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onFlick(int targetIndex, int correctIndex) {
    if (_isAnswered) return;

    bool isCorrect = targetIndex == correctIndex;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
      });
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
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;
          final livesChanged = _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _dragOffset = Offset.zero;
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'POS PRO!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final options = (quest?.options?.length ?? 0) >= 4 ? quest!.options!.sublist(0, 4) : ["Noun", "Verb", "Adj", "Adv"];
        
        return GrammarBaseLayout(
          gameType: widget.gameType, 
          level: widget.level, 
          isAnswered: _isAnswered, 
          isCorrect: _isCorrect, 
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null
              ? const SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = constraints.maxHeight;
                    final isCompact = maxHeight < 580;

                    final double estimatedContentHeight = (isCompact ? 30.h : 40.h) + (isCompact ? 50.h : 80.h) + (isCompact ? 160.h : 260.h) + 40.h;
                    final remainingHeight = maxHeight - estimatedContentHeight;

                    final double gapUnit = remainingHeight > 0 ? remainingHeight / 5 : 0;
                    final double gapTop = remainingHeight > 0 ? (gapUnit * 1).clamp(4.0, 15.0) : 4.0;
                    final double gapMiddle = remainingHeight > 0 ? (gapUnit * 1.5).clamp(6.0, 20.0) : 6.0;
                    final double gapBottom = remainingHeight > 0 ? (gapUnit * 2.5).clamp(10.0, 30.0) : 10.0;

                    return Column(
                      children: [
                        SizedBox(height: gapTop),
                        isCompact
                            ? SizedBox(
                                height: 25.h,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: SpeechInstruction(primaryColor: theme.primaryColor),
                                ),
                              )
                            : SpeechInstruction(primaryColor: theme.primaryColor),
                        SizedBox(height: gapMiddle),

                        SpeechContextCard(
                          quest: quest,
                          primaryColor: theme.primaryColor,
                          isDark: isDark,
                          isCompact: isCompact,
                        ),

                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Vortex Buckets (Corners)
                              SpeechVortex(index: 0, label: options[0], color: Colors.blueAccent, alignment: Alignment.topLeft, isCompact: isCompact),
                              SpeechVortex(index: 1, label: options[1], color: Colors.purpleAccent, alignment: Alignment.topRight, isCompact: isCompact),
                              SpeechVortex(index: 2, label: options[2], color: Colors.orangeAccent, alignment: Alignment.bottomLeft, isCompact: isCompact),
                              SpeechVortex(index: 3, label: options[3], color: Colors.greenAccent, alignment: Alignment.bottomRight, isCompact: isCompact),

                              // The Word to Flick
                              if (!_isAnswered)
                                GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() => _dragOffset += details.delta);
                                    _checkCollision(quest.correctAnswerIndex ?? 0, isCompact: isCompact);
                                  },
                                  onPanEnd: (details) {
                                    setState(() => _dragOffset = Offset.zero);
                                  },
                                  child: Transform.translate(
                                    offset: _dragOffset,
                                    child: Transform.rotate(
                                      angle: _dragOffset.dx / 100,
                                      child: SpeechDraggableWord(
                                        word: quest.targetWord ?? quest.word ?? "??",
                                        primaryColor: theme.primaryColor,
                                        isDark: isDark,
                                        isCompact: isCompact,
                                      ),
                                    ),
                                  ),
                                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                            ],
                          ),
                        ),
                        SizedBox(height: gapBottom),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  void _checkCollision(int correctIndex, {required bool isCompact}) {
    // Calculate the distance from the center (Radial Distance)
    final double distance = _dragOffset.distance;
    final double activationThreshold = isCompact ? 60.r : 100.r;

    if (distance > activationThreshold) {
      // Determine which quadrant the word is in
      if (_dragOffset.dx < 0 && _dragOffset.dy < 0) {
        _onFlick(0, correctIndex); // Top-Left
      } else if (_dragOffset.dx > 0 && _dragOffset.dy < 0) {
        _onFlick(1, correctIndex); // Top-Right
      } else if (_dragOffset.dx < 0 && _dragOffset.dy > 0) {
        _onFlick(2, correctIndex); // Bottom-Left
      } else if (_dragOffset.dx > 0 && _dragOffset.dy > 0) {
        _onFlick(3, correctIndex); // Bottom-Right
      }
    }
  }
}

