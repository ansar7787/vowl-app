import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/guess_title/presentation/widgets/guess_title_instruction.dart';
import 'package:vowl/features/reading/guess_title/presentation/widgets/guess_title_result.dart';
import 'package:vowl/features/reading/guess_title/presentation/widgets/guess_title_options.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';
import 'package:vowl/core/services/error_journal_collector.dart';

class GuessTitleScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const GuessTitleScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.guessTitle,
  });

  @override
  State<GuessTitleScreen> createState() => _GuessTitleScreenState();
}

class _GuessTitleScreenState extends State<GuessTitleScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _showTypeToConfirm = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _showTypeToConfirm.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitFinalAnswer(
    bool isCorrect, [
    ReadingQuest? quest,
    String? selectedOption,
  ]) {
    if (_isAnswered.value || _showTypeToConfirm.value) return;

    _isAnswered.value = true;
    _isCorrect.value = isCorrect;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _showTypeToConfirm.value = true;
    } else {
      _hapticService.error();
      _soundService.playWrong();
      if (quest != null) {
        ErrorJournalCollector.record(
          userId: 'local',
          gameType: widget.gameType.name,
          question: quest.question ?? quest.instruction,
          userAnswer: selectedOption ?? 'Unknown',
          correctAnswer: quest.correctAnswer ?? '',
          level: widget.level,
        );
      }
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _onTypeConfirmed() {
    _showTypeToConfirm.value = false;
    context.read<ReadingBloc>().add(const SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _showTypeToConfirm.value = false;
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr(
              'reading_games.title_expert',
              fallback: 'TITLE EXPERT!',
            ),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _showTypeToConfirm,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
              onContinue: () =>
                  context.read<ReadingBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<ReadingBloc>().add(const ReadingHintUsed()),
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
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      SizedBox(height: 16.h),
                                      GuessTitleInstruction(
                                        primaryColor: theme.primaryColor,
                                        instruction: quest.instruction,
                                      ),
                                      SizedBox(height: 24.h),
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(24.r),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.05,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.02,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          border: Border.all(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: _buildPassageContent(
                                          quest,
                                          theme.primaryColor,
                                          isDark,
                                        ),
                                      ),
                                      if (!_isAnswered.value ||
                                          _isCorrect.value == null) ...[
                                        SizedBox(height: 24.h),
                                        GuessTitleOptions(
                                          options: quest.options ?? [],
                                          correctAnswer:
                                              quest.correctAnswer ?? "",
                                          primaryColor: theme.primaryColor,
                                          isDark: isDark,
                                          isAnswered: _isAnswered.value,
                                          onOptionSelected:
                                              (isCorrect, selectedOption) {
                                                _submitFinalAnswer(
                                                  isCorrect,
                                                  quest,
                                                  selectedOption,
                                                );
                                              },
                                        ),
                                      ],
                                      if (_isAnswered.value) ...[
                                        SizedBox(height: 30.h),
                                        GuessTitleResult(
                                          quest: quest,
                                          isCorrect: _isCorrect.value == true,
                                          isDark: isDark,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height:
                                      (_showTypeToConfirm.value &&
                                          _isAnswered.value)
                                      ? 380.h
                                      : 60.h,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showTypeToConfirm.value && _isAnswered.value)
                          TypeToConfirmOverlay(
                            expectedText: quest.correctAnswer ?? '',
                            primaryColor: theme.primaryColor,
                            onConfirmed: _onTypeConfirmed,
                            onSkipped: _onTypeConfirmed,
                            allowSkip: true,
                            isPositioned: true,
                          ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildPassageContent(
    ReadingQuest quest,
    Color primaryColor,
    bool isDark,
  ) {
    final passage = quest.passage ?? "";
    final evidence = quest.evidenceLine ?? "";

    if (!_isAnswered.value || evidence.isEmpty || !passage.contains(evidence)) {
      return Text(
        passage,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18.sp,
          height: 1.6,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      );
    }

    final parts = passage.split(evidence);
    if (parts.length != 2) {
      return Text(
        passage,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18.sp,
          height: 1.6,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18.sp,
          height: 1.6,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        children: [
          TextSpan(text: parts[0]),
          TextSpan(
            text: evidence,
            style: TextStyle(
              backgroundColor: primaryColor.withValues(alpha: 0.2),
              color: primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: parts[1]),
        ],
      ),
    );
  }
}
