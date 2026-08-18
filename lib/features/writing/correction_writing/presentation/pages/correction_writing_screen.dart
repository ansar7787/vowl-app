import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_instruction.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_sentence_card.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_vault.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_keyboard_input.dart';

class CorrectionWritingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const CorrectionWritingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.correctionWriting,
  });

  @override
  State<CorrectionWritingScreen> createState() =>
      _CorrectionWritingScreenState();
}

class _CorrectionWritingScreenState extends State<CorrectionWritingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  String? _selectedCorrection;
  WritingQuest? _lastQuest;

  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onSelectCorrection(String choice, bool isAnswered) {
    if (isAnswered) return;
    _hapticService.selection();
    setState(() {
      _selectedCorrection = choice;
    });
  }

  static String _normalizeAnswer(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  void _submitAnswer(bool isAnswered, [String? typedText]) {
    final currentState = context.read<WritingBloc>().state;
    if (currentState is! WritingLoaded) return;

    final WritingQuest? quest = currentState.currentQuest as WritingQuest?;
    final isHardMode = widget.level >= 6;

    if (quest == null ||
        isAnswered ||
        (!isHardMode && _selectedCorrection == null) ||
        (isHardMode && typedText == null)) {
      return;
    }

    bool correct = false;
    if (isHardMode && typedText != null) {
      final rawText = typedText.trim();
      if (!RegExp(r'^[A-Z]').hasMatch(rawText)) {
        CustomSnackBar.show(
          context: context,
          message: "Please start your sentence with a capital letter.",
          type: CustomSnackBarType.warning,
        );
        _hapticService.selection();
        return;
      }

      final lastChar = rawText.isNotEmpty ? rawText[rawText.length - 1] : '';
      if (!['.', '!', '?'].contains(lastChar)) {
        CustomSnackBar.show(
          context: context,
          message:
              "Please end your sentence with proper punctuation (., !, or ?).",
          type: CustomSnackBarType.warning,
        );
        _hapticService.selection();
        return;
      }

      String expectedSentence = (quest.passage ?? "").replaceAll(
        RegExp(r'\[(.*?)\]'),
        quest.correctAnswer ?? "",
      );
      correct =
          _normalizeAnswer(typedText) == _normalizeAnswer(expectedSentence);
    } else {
      correct = _selectedCorrection == quest.correctAnswer;
    }

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
    } else {
      _hapticService.error();
      _soundService.playWrong();
    }

    context.read<WritingBloc>().add(SubmitAnswer(correct));
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
          setState(() {
            _selectedCorrection = null;
          });
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SYNTAX AUDITOR!',
            enableDoubleUp: true,
          );
        }

        if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () =>
                context.read<WritingBloc>().add(const RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        final WritingQuest? quest = isLoaded
            ? state.currentQuest as WritingQuest?
            : null;

        if (quest != null) {
          _lastQuest = quest;
        }

        final activeQuest = quest ?? _lastQuest;

        final options = activeQuest?.options ?? [];
        final bool isAnswered = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          showConfetti: _showConfetti,
          useScrolling: false,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: activeQuest == null
              ? const SizedBox()
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SizedBox(height: 16.h),
                            CorrectionWritingInstruction(
                              instruction: activeQuest.instruction,
                              primaryColor: theme.primaryColor,
                            ),
                            SizedBox(height: 24.h),

                            CorrectionWritingSentenceCard(
                              passage: activeQuest.passage ?? "",
                              selectedCorrection: widget.level >= 6
                                  ? null
                                  : _selectedCorrection,
                              color: theme.primaryColor,
                              isDark: isDark,
                            ),
                            SizedBox(height: 32.h),

                            if (widget.level >= 6) ...[
                              GestureDetector(
                                onTap: () {
                                  CustomSnackBar.show(
                                    context: context,
                                    message:
                                        "Hard Mode! Tapping is disabled. Please type your answer below.",
                                    type: CustomSnackBarType.info,
                                  );
                                },
                                child: AbsorbPointer(
                                  child: Opacity(
                                    opacity: 0.8,
                                    child: CorrectionWritingVault(
                                      options: options,
                                      selectedCorrection: null,
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                      onSelectCorrection: (_) {},
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              CorrectionWritingKeyboardInput(
                                color: theme.primaryColor,
                                isDark: isDark,
                                onSubmit: (text) => _submitAnswer(isAnswered, text),
                              ),
                            ] else
                              CorrectionWritingVault(
                                options: options,
                                selectedCorrection: _selectedCorrection,
                                color: theme.primaryColor,
                                isDark: isDark,
                                onSelectCorrection: (choice) =>
                                    _onSelectCorrection(choice, isAnswered),
                              ),
                            SizedBox(height: 36.h),
                          ],
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!isAnswered && widget.level < 6)
                              ScaleButton(
                                onTap: _selectedCorrection != null
                                    ? () => _submitAnswer(isAnswered)
                                    : null,
                                child: Container(
                                  width: double.infinity,
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.r),
                                    color: _selectedCorrection != null
                                        ? theme.primaryColor
                                        : Colors.grey,
                                    boxShadow: [
                                      if (_selectedCorrection != null)
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
                                      "AUDIT SYNTAX",
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
        );
      },
    );
  }
}
