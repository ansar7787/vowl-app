import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/opinion_writing/presentation/widgets/opinion_writing_instruction.dart';
import 'package:vowl/features/writing/opinion_writing/presentation/widgets/opinion_writing_thesis_card.dart';
import 'package:vowl/features/writing/opinion_writing/presentation/widgets/opinion_writing_scale_interface.dart';
import 'package:vowl/features/writing/opinion_writing/presentation/widgets/opinion_writing_argument_stones.dart';
import 'package:vowl/features/writing/opinion_writing/presentation/widgets/opinion_writing_explanation_card.dart';

class OpinionWritingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const OpinionWritingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.opinionWriting,
  });

  @override
  State<OpinionWritingScreen> createState() => _OpinionWritingScreenState();
}

class _OpinionWritingScreenState extends State<OpinionWritingScreen> {
  final _hapticService = di.sl<HapticService>();

  final List<String> _leftPanArgs = [];
  final List<String> _rightPanArgs = [];

  double _scaleRotation = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onDropArg(String arg, bool isLeft) {
    if (_isAnswered) return;

    _hapticService.success();
    setState(() {
      _leftPanArgs.remove(arg);
      _rightPanArgs.remove(arg);

      if (isLeft) {
        _leftPanArgs.add(arg);
      } else {
        _rightPanArgs.add(arg);
      }

      double diff = (_leftPanArgs.length - _rightPanArgs.length).toDouble();
      _scaleRotation = (diff * 0.1).clamp(-0.3, 0.3);
    });
  }

  void _removeArg(String arg, bool isLeft) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      if (isLeft) {
        _leftPanArgs.remove(arg);
      } else {
        _rightPanArgs.remove(arg);
      }

      double diff = (_leftPanArgs.length - _rightPanArgs.length).toDouble();
      _scaleRotation = (diff * 0.1).clamp(-0.3, 0.3);
    });
  }

  void _submitAnswer() {
    final state = context.read<WritingBloc>().state;
    if (state is! WritingLoaded || _isAnswered) return;

    final quest = state.currentQuest;
    final options = quest.options ?? [];
    final correctProsIndices = quest.correctOrder ?? [0, 1];

    final correctPros = correctProsIndices.map((idx) => options[idx]).toSet();
    final correctCons = options
        .where((opt) => !correctPros.contains(opt))
        .toSet();

    bool isLeftCorrect =
        _leftPanArgs.length == 2 &&
        _leftPanArgs.every((arg) => correctPros.contains(arg));
    bool isRightCorrect =
        _rightPanArgs.length == 2 &&
        _rightPanArgs.every((arg) => correctCons.contains(arg));

    if (isLeftCorrect && isRightCorrect) {
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<WritingBloc>().add(SubmitAnswer(true));
    } else {
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<WritingBloc>().add(SubmitAnswer(false));

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isAnswered = false;
            _isCorrect = null;
            _leftPanArgs.clear();
            _rightPanArgs.clear();
            _scaleRotation = 0.0;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listener: (context, state) {
        if (state is WritingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _leftPanArgs.clear();
              _rightPanArgs.clear();
              _scaleRotation = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'LOGIC MASTER!',
            enableDoubleUp: true,
          );
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<WritingBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final WritingQuest? quest = (state is WritingLoaded)
            ? state.currentQuest
            : null;

        final options = quest?.options ?? [];
        final totalPlaced = _leftPanArgs.length + _rightPanArgs.length;

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        SizedBox(height: 16.h),
                        OpinionWritingInstruction(
                          primaryColor: theme.primaryColor,
                        ),
                        SizedBox(height: 24.h),

                        OpinionWritingThesisCard(
                          text: quest.prompt ?? "",
                          color: theme.primaryColor,
                          isDark: isDark,
                        ),
                        SizedBox(height: 24.h),

                        OpinionWritingScaleInterface(
                          scaleRotation: _scaleRotation,
                          leftPanArgs: _leftPanArgs,
                          rightPanArgs: _rightPanArgs,
                          color: theme.primaryColor,
                          isDark: isDark,
                          onDropArg: _onDropArg,
                          onRemoveArg: _removeArg,
                        ),
                        SizedBox(height: 32.h),

                        OpinionWritingArgumentStones(
                          options: options,
                          leftPanArgs: _leftPanArgs,
                          rightPanArgs: _rightPanArgs,
                          color: theme.primaryColor,
                          isDark: isDark,
                        ),
                        SizedBox(height: 36.h),

                        if (!_isAnswered)
                          ScaleButton(
                            onTap: totalPlaced == 4 ? _submitAnswer : null,
                            child: Container(
                              width: double.infinity,
                              height: 60.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.r),
                                color: totalPlaced == 4
                                    ? theme.primaryColor
                                    : Colors.grey,
                                boxShadow: [
                                  if (totalPlaced == 4)
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 15,
                                    ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "BALANCE THE TRUTH",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        if (_isAnswered) ...[
                          SizedBox(height: 30.h),
                          OpinionWritingExplanationCard(
                            quest: quest,
                            isCorrect: _isCorrect == true,
                            primaryColor: theme.primaryColor,
                            isDark: isDark,
                          ),
                        ],
                        SizedBox(height: 60.h),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
