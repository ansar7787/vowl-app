import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/mixins/speaking_game_screen_mixin.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/shadow_playback_compare.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_header.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_scratch_panel.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_usage_panel.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';

class DailyExpressionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const DailyExpressionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.dailyExpression,
  });

  @override
  State<DailyExpressionScreen> createState() => _DailyExpressionScreenState();
}

class _DailyExpressionScreenState extends State<DailyExpressionScreen>
    with SingleTickerProviderStateMixin, SpeakingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<double> _scratchProgress = ValueNotifier(0.0);

  late AnimationController _glowController;
  final ValueNotifier<double> _timeVal = ValueNotifier(0.0);
  String _targetExpression = "";
  final ScrollController _scrollController = ScrollController();
  bool _reduceComplexGestures = false;

  @override
  void initState() {
    super.initState();
    isAnsweredNotifier.addListener(() {
      if (isAnsweredNotifier.value && mounted && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    _loadAccessibilitySettings();
    initSpeakingGame();

    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addListener(() {
            _timeVal.value = _glowController.value;
          });
    _glowController.repeat();
  }

  Future<void> _loadAccessibilitySettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _reduceComplexGestures =
            prefs.getBool('reduce_complex_gestures') ?? false;
      });
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scratchProgress.dispose();
    _timeVal.dispose();
    _scrollController.dispose();
    disposeSpeakingGame();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleScratchUpdate(double delta) {
    if (_scratchProgress.value >= 1.0) return;
    _scratchProgress.value += delta;
    if (_scratchProgress.value >= 0.85) {
      _scratchProgress.value = 1.0;
      hapticService.selection();
      soundService.playTts(_targetExpression);
      _scrollToBottom();
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value || _scratchProgress.value < 1.0) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<SpeakingBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();

      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated &&
          authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: 'Speak to confirm expression',
          userAnswer: '[Failed Speak to Confirm]',
          correctAnswer: _targetExpression,
          level: widget.level,
        );
      }

      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _scratchProgress.value = 0.0;

    _timeVal.value = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);
    final mediaQuery = MediaQuery.of(context);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listenWhen: speakingListenWhen,
      listener: onSpeakingStateChanged,
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;
        final hintUsed = (state is SpeakingLoaded) && state.hintUsed;

        if (quest != null) {
          _targetExpression = quest.expression ?? "Idiom";
        }

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              isAnsweredNotifier,
              isCorrectNotifier,
              showConfettiNotifier,
            ]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: isAnsweredNotifier.value,
                isCorrect: isCorrectNotifier.value,
                disablePadding: true,
                onContinue: () =>
                    context.read<SpeakingBloc>().add(const NextQuestion()),
                onHint: () =>
                    context.read<SpeakingBloc>().add(const SpeakingHintUsed()),
                child: quest == null
                    ? GameShimmerLoading(primaryColor: theme.primaryColor)
                    : RawScrollbar(
                        controller: _scrollController,
                        thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                        radius: Radius.circular(8.r),
                        thickness: 4.w,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 16.h,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: ValueListenableBuilder<double>(
                                  valueListenable: _scratchProgress,
                                  builder: (context, scratchProgress, _) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        DailyExpressionHeader(
                                          primaryColor: theme.primaryColor,
                                          instruction: context.tr(
                                            'games.daily_expression_instruction',
                                            fallback: 'Speak the daily idiom',
                                          ),
                                        ),
                                        SizedBox(height: 24.h),
                                        if (hintUsed && quest.hint != null)
                                          Container(
                                                width: double.infinity,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                  vertical: 12.h,
                                                ),
                                                margin: EdgeInsets.only(
                                                  bottom: 24.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.primaryColor
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        16.r,
                                                      ),
                                                  border: Border.all(
                                                    color: theme.primaryColor
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .lightbulb_outline_rounded,
                                                      color: theme.primaryColor,
                                                      size: 18.r,
                                                    ),
                                                    SizedBox(width: 8.w),
                                                    Expanded(
                                                      child: Text(
                                                        quest.hint!,
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 14.sp,
                                                          color: isDark
                                                              ? Colors.white70
                                                              : Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                              .animate()
                                              .fadeIn(duration: 300.ms)
                                              .slideY(begin: -0.1),
                                        DailyExpressionScratchPanel(
                                          quest: quest,
                                          primaryColor: theme.primaryColor,
                                          isDark: isDark,
                                          scratchProgressNotifier:
                                              _scratchProgress,
                                          timeValNotifier: _timeVal,
                                          reduceComplexGestures:
                                              _reduceComplexGestures,
                                          onPlayTts: () {
                                            if (di
                                                .sl<AudioRecordingService>()
                                                .isRecording) {
                                              return;
                                            }
                                            soundService.playTts(
                                              quest.expression ?? "",
                                            );
                                          },
                                          onScratchUpdate: _handleScratchUpdate,
                                        ),
                                        SizedBox(height: 32.h),
                                        if (scratchProgress > 0.3)
                                          DailyExpressionUsagePanel(
                                                quest: quest,
                                                primaryColor:
                                                    theme.primaryColor,
                                                isDark: isDark,
                                              )
                                              .animate()
                                              .fadeIn(duration: 300.ms)
                                              .slideY(begin: 0.1),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                            ValueListenableBuilder<double>(
                              valueListenable: _scratchProgress,
                              builder: (context, scratchProgress, _) {
                                if (!isAnsweredNotifier.value &&
                                    scratchProgress >= 1.0) {
                                  return SliverToBoxAdapter(
                                    child: ShadowPlaybackCompare(
                                      expectedText: _targetExpression,
                                      primaryColor: theme.primaryColor,
                                      isPositioned: false,
                                      showExpectedText: false,
                                      onConfirmed: () =>
                                          _submitVerbalEvaluation(true),
                                      onSkipped: () =>
                                          _submitVerbalEvaluation(false),
                                    ),
                                  );
                                }
                                return const SliverToBoxAdapter(
                                  child: SizedBox.shrink(),
                                );
                              },
                            ),
                            SliverToBoxAdapter(child: SizedBox(height: 120.h)),
                          ],
                        ),
                      ),
              );
            },
          ),
        );
      },
    );
  }
}
