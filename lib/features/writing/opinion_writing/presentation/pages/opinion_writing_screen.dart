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
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

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

  final ValueNotifier<List<String>> _leftPanArgs = ValueNotifier([]);
  final ValueNotifier<List<String>> _rightPanArgs = ValueNotifier([]);

  final ValueNotifier<double> _scaleRotation = ValueNotifier(0.0);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  WritingQuest? _lastQuest;
  final ValueNotifier<List<String>> _shuffledOptions = ValueNotifier([]);
  final ValueNotifier<bool> _pendingScaleSubmit = ValueNotifier(false);

  @override
  void dispose() {
    _leftPanArgs.dispose();
    _rightPanArgs.dispose();
    _scaleRotation.dispose();
    _showConfetti.dispose();
    _shuffledOptions.dispose();
    _pendingScaleSubmit.dispose();
    super.dispose();
  }

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
    final newLeft = List<String>.from(_leftPanArgs.value)..remove(arg);
    final newRight = List<String>.from(_rightPanArgs.value)..remove(arg);

    if (isLeft) {
      newLeft.add(arg);
    } else {
      newRight.add(arg);
    }

    _leftPanArgs.value = newLeft;
    _rightPanArgs.value = newRight;

    double diff = (newLeft.length - newRight.length).toDouble();
    _scaleRotation.value = (diff * 0.06).clamp(-0.15, 0.15);
  }

  void _removeArg(String arg, bool isLeft, bool isAnswered) {
    if (isAnswered) return;
    _hapticService.selection();
    final newLeft = List<String>.from(_leftPanArgs.value);
    final newRight = List<String>.from(_rightPanArgs.value);

    if (isLeft) {
      newLeft.remove(arg);
    } else {
      newRight.remove(arg);
    }
    
    _leftPanArgs.value = newLeft;
    _rightPanArgs.value = newRight;

    double diff = (newLeft.length - newRight.length).toDouble();
    _scaleRotation.value = (diff * 0.06).clamp(-0.15, 0.15);
  }

  void _submitAnswer(bool isAnswered) {
    if (isAnswered) return;
    _pendingScaleSubmit.value = true;
  }

  void _submitFinalAnswer(bool nailedTyping) {
    _pendingScaleSubmit.value = false;

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
        _leftPanArgs.value.length == 2 &&
        _leftPanArgs.value.every((arg) => correctPros.contains(arg));
    bool isRightCorrect =
        _rightPanArgs.value.length == 2 &&
        _rightPanArgs.value.every((arg) => correctCons.contains(arg));

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
          (curr is WritingLoaded && !curr.answerStatus.isAnswered),
      listener: (context, state) {
        if (state is WritingLoaded && !state.answerStatus.isAnswered) {
          _leftPanArgs.value = [];
          _rightPanArgs.value = [];
          _scaleRotation.value = 0.0;
          _pendingScaleSubmit.value = false;
          _shuffledOptions.value = List.from(state.currentQuest.options ?? [])..shuffle();
        }
        if (state is WritingGameComplete) {
          _showConfetti.value = true;
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


        final bool isAnswered = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;
        final bool isFinalFailure = isLoaded
            ? state.isFinalFailure
            : (state is WritingGameOver);

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
          showConfetti: _showConfetti.value,
          useScrolling: false,
          onContinue: () =>
              context.read<WritingBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<WritingBloc>().add(const WritingHintUsed()),
          child: ListenableBuilder(
            listenable: Listenable.merge([_showConfetti, _leftPanArgs, _rightPanArgs, _scaleRotation, _shuffledOptions, _pendingScaleSubmit]),
            builder: (context, _) {
              final options = _shuffledOptions.value.isNotEmpty
                  ? _shuffledOptions.value
                  : (quest?.options ?? []);
              final totalPlaced = _leftPanArgs.value.length + _rightPanArgs.value.length;

              return quest == null
                  ? const SizedBox()
                  : Stack(
                  children: [
                    CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children: [
                                SizedBox(height: 16.h),
                                OpinionWritingInstruction(
                                  primaryColor: theme.primaryColor,
                                ),
                                SizedBox(height: 16.h),
                                if (quest.structureGuide != null)
                                  Container(
                                    margin: EdgeInsets.only(bottom: 16.h),
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.format_list_bulleted, color: theme.primaryColor, size: 16.sp),
                                        SizedBox(width: 8.w),
                                        Text(
                                          quest.structureGuide!,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w700,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                OpinionWritingThesisCard(
                                  text: quest.prompt ?? "",
                                  color: theme.primaryColor,
                                  isDark: isDark,
                                ),
                                SizedBox(height: 8.h),

                                OpinionWritingScaleInterface(
                                  scaleRotation: _scaleRotation.value,
                                  leftPanArgs: _leftPanArgs.value,
                                  rightPanArgs: _rightPanArgs.value,
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
                                  leftPanArgs: _leftPanArgs.value,
                                  rightPanArgs: _rightPanArgs.value,
                                  color: theme.primaryColor,
                                  isDark: isDark,
                                ),
                                SizedBox(height: 24.h),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
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
                                SizedBox(height: isAnswered ? 160.h : 60.h),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_pendingScaleSubmit.value && !isAnswered)
                      SpeakToConfirmOverlay(
                        expectedText: quest.prompt ?? "I have balanced the arguments",
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true),
                        onSkipped: () => _submitFinalAnswer(false),
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
