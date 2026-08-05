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
import 'package:vowl/core/presentation/widgets/type_to_confirm_overlay.dart';

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
  bool _showConfetti = false;
  WritingQuest? _lastQuest;
  List<String> _shuffledOptions = [];
  bool _pendingScaleSubmit = false;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onDropArg(String arg, bool isLeft, bool isAnswered) {
    if (isAnswered) return;

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
      _scaleRotation = (diff * 0.06).clamp(-0.15, 0.15);
    });
  }

  void _removeArg(String arg, bool isLeft, bool isAnswered) {
    if (isAnswered) return;
    _hapticService.selection();
    setState(() {
      if (isLeft) {
        _leftPanArgs.remove(arg);
      } else {
        _rightPanArgs.remove(arg);
      }

      double diff = (_leftPanArgs.length - _rightPanArgs.length).toDouble();
      _scaleRotation = (diff * 0.06).clamp(-0.15, 0.15);
    });
  }

  void _submitAnswer(bool isAnswered) {
    if (isAnswered) return;
    setState(() {
      _pendingScaleSubmit = true;
    });
  }

  void _submitFinalAnswer(bool nailedTyping) {
    setState(() {
      _pendingScaleSubmit = false;
    });

    final state = context.read<WritingBloc>().state;
    if (state is! WritingLoaded) return;

    if (!nailedTyping) {
      _hapticService.error();
      context.read<WritingBloc>().add(const SubmitAnswer(false));
      return;
    }

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

    context.read<WritingBloc>().add(
      SubmitAnswer(isLeftCorrect && isRightCorrect),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listenWhen: (prev, curr) =>
          (curr is WritingGameComplete && prev is! WritingGameComplete) ||
          (curr is WritingGameOver && prev is! WritingGameOver) ||
          (curr is WritingLoaded && curr.lastAnswerCorrect == null),
      listener: (context, state) {
        if (state is WritingLoaded && state.lastAnswerCorrect == null) {
          setState(() {
            _leftPanArgs.clear();
            _rightPanArgs.clear();
            _scaleRotation = 0.0;
            _pendingScaleSubmit = false;
            
            // Randomize options for pedagogical integrity
            _shuffledOptions = List.from(state.currentQuest.options ?? []);
            _shuffledOptions.shuffle();
          });
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
        }
      },
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        if (isLoaded) {
          _lastQuest = state.currentQuest;
        }
        final WritingQuest? quest = isLoaded ? state.currentQuest : _lastQuest;

        final options = _shuffledOptions.isNotEmpty ? _shuffledOptions : (quest?.options ?? []);
        final totalPlaced = _leftPanArgs.length + _rightPanArgs.length;
        final bool isAnswered = isLoaded && state.lastAnswerCorrect != null;
        final bool? isCorrect = isLoaded ? state.lastAnswerCorrect : null;
        final bool isFinalFailure = isLoaded ? state.isFinalFailure : (state is WritingGameOver);

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(const NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(const WritingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          children: [
                            SizedBox(height: 16.h),
                            OpinionWritingInstruction(
                              primaryColor: theme.primaryColor,
                            ),
                            SizedBox(height: 16.h),

                            OpinionWritingThesisCard(
                              text: quest.prompt ?? "",
                              color: theme.primaryColor,
                              isDark: isDark,
                            ),
                            SizedBox(height: 8.h),

                            OpinionWritingScaleInterface(
                              scaleRotation: _scaleRotation,
                              leftPanArgs: _leftPanArgs,
                              rightPanArgs: _rightPanArgs,
                              color: theme.primaryColor,
                              isDark: isDark,
                              onDropArg: (arg, isLeft) =>
                                  _onDropArg(arg, isLeft, isAnswered),
                              onRemoveArg: (arg, isLeft) =>
                                  _removeArg(arg, isLeft, isAnswered),
                            ),
                            SizedBox(height: 8.h),

                            OpinionWritingArgumentStones(
                              options: options,
                              leftPanArgs: _leftPanArgs,
                              rightPanArgs: _rightPanArgs,
                              color: theme.primaryColor,
                              isDark: isDark,
                            ),
                            SizedBox(height: 24.h),

                            if (!isAnswered)
                              ScaleButton(
                                onTap: totalPlaced == 4
                                    ? () => _submitAnswer(isAnswered)
                                    : null,
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
                                      totalPlaced == 4
                                          ? "BALANCE THE TRUTH"
                                          : "PLACE ${4 - totalPlaced} MORE CARDS",
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

                            SizedBox(height: 160.h),
                          ],
                        ),
                      ),
                    ),
                    if (_pendingScaleSubmit && !isAnswered)
                      TypeToConfirmOverlay(
                        expectedText: quest.prompt ?? "I have balanced the arguments",
                        displayText: "Type the thesis to seal your argument",
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true),
                        onSkipped: () => _submitFinalAnswer(false),
                        allowSkip: true,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
