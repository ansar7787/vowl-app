import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/listening/domain/entities/listening_quest.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/mixins/listening_game_screen_mixin.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/features/listening/listening_inference/presentation/widgets/listening_inference_instruction.dart';
import 'package:vowl/features/listening/listening_inference/presentation/widgets/listening_inference_radar_core.dart';
import 'package:vowl/features/listening/listening_inference/presentation/widgets/listening_inference_grid.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/features/listening/listening_inference/presentation/widgets/listening_inference_explanation.dart';

/// Screen for the Listening Inference quest.
///
/// Prompts the learner to deduce hidden meanings, contextual undertones,
/// or implied settings from spoken dialogue using a radar pulse audio interface.
class ListeningInferenceScreen extends StatefulWidget {
  /// Progression level index.
  final int level;

  /// Specific game subtype variant.
  final GameSubtype gameType;

  /// Creates a [ListeningInferenceScreen] instance.
  const ListeningInferenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.listeningInference,
  });

  @override
  State<ListeningInferenceScreen> createState() =>
      _ListeningInferenceScreenState();
}

class _ListeningInferenceScreenState extends State<ListeningInferenceScreen>
    with
        SingleTickerProviderStateMixin,
        GameScreenMixin<ListeningInferenceScreen>,
        ListeningGameScreenMixin<ListeningInferenceScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => context.tr(
        'listening.games.listening_inference_title',
        fallback: 'Level Complete!',
      );

  late AnimationController _pulseController;
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    if (reduceMotion) {
      if (_pulseController.isAnimating) _pulseController.stop();
    } else {
      if (!_pulseController.isAnimating) _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _selectedIndex.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    disposeListeningGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    timerKey = GlobalKey<SpeedChallengeTimerState>();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    initListeningGame();
  }

  void _submitFinalAnswer(int index, int correct, GameQuest quest) {
    if (isAnsweredNotifier.value) return;
    _pulseController.stop();
    timerKey?.currentState?.stop();

    _selectedIndex.value = index;
    bool isCorrect = index == correct;

    if (isCorrect) {
      submitCorrectAnswer();
    } else {
      String uAns = (quest.options != null && quest.options!.length > index)
          ? quest.options![index]
          : index.toString();

      submitWrongAnswer(quest: quest, userAnswer: uAns);
    }
  }

  void _submitWrongAnswer(dynamic quest) {
    if (isAnsweredNotifier.value) return;
    _pulseController.stop();
    timerKey?.currentState?.stop();
    if (quest is GameQuest) {
      submitWrongAnswer(quest: quest, userAnswer: '[Timeout]');
    }
  }

  void _playAudio(ListeningQuest quest) {
    final rawAudio = quest.textToSpeak ??
        quest.prompt ??
        quest.question ??
        quest.sentence ??
        quest.audioTranscript ??
        "";
    final text = rawAudio.trim();
    if (text.isEmpty) return;
    if (text.startsWith('http')) {
      soundService.playUrl(text);
    } else {
      soundService.playTts(text, pauseMarkers: quest.pauseMarkers);
    }
    hapticService.selection();
  }

  void _showTranscriptBottomSheet(
    BuildContext context,
    String text,
    dynamic theme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.closed_caption_rounded,
                      color: theme.primaryColor,
                      size: 22.r,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      "Audio Transcript",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Text(
                  text,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    elevation: 0,
                  ),
                  child: Text(
                    "Close",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void onQuestionReset() {
    _selectedIndex.value = null;
    timerKey?.currentState?.start();
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    if (!reduceMotion && !_pulseController.isAnimating) {
      _pulseController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      'listening',
      level: widget.level,
      isDark: isDark,
    );

    return BlocConsumer<ListeningBloc, ListeningState>(
      listenWhen: listeningListenWhen,
      listener: onListeningStateChanged,
      buildWhen: (previous, current) =>
          current is ListeningLoaded ||
          current is ListeningGameOver ||
          current is ListeningGameComplete,
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _selectedIndex,
          ]),
          builder: (context, _) {
            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              useScrolling: false,
              disablePadding: true,
              onContinue: dispatchNextQuestion,
              onHint: () => hapticService.selection(),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
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
                                  horizontal: 20.w,
                                  vertical: 12.h,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(height: 4.h),
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 14.h),
                                        child: SpeedChallengeTimer(
                                          key: timerKey,
                                          durationSeconds: 30,
                                          primaryColor: theme.primaryColor,
                                          onTimeUp: () =>
                                              _submitWrongAnswer(quest),
                                        ),
                                      ),
                                      ListeningInferenceInstruction(
                                        key: const Key(
                                          'listening_inference_instruction',
                                        ),
                                        color: theme.primaryColor,
                                        instruction: context.tr(
                                          'games.listeningInference_instruction',
                                          fallback: quest.instruction.isNotEmpty
                                              ? quest.instruction
                                              : 'Listen carefully and deduce what is implied.',
                                        ),
                                      ),
                                      SizedBox(height: 18.h),
                                      ListeningInferenceRadarCore(
                                        key: const Key(
                                          'listening_inference_radar_core',
                                        ),
                                        onTap: () => _playAudio(quest),
                                        pulseController: _pulseController,
                                        color: theme.primaryColor,
                                        emoji: quest.emoji,
                                        isCorrectState: isCorrectNotifier.value,
                                      ),
                                      SizedBox(height: 14.h),
                                      Semantics(
                                        button: true,
                                        label: 'Show audio transcript',
                                        child: GestureDetector(
                                          key: const Key(
                                            'listening_inference_show_text_btn',
                                          ),
                                          onTap: () {
                                            hapticService.selection();
                                            _showTranscriptBottomSheet(
                                              context,
                                              quest.textToSpeak ?? '',
                                              theme,
                                            );
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 14.w,
                                              vertical: 7.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.primaryColor
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                              border: Border.all(
                                                color: theme.primaryColor
                                                    .withValues(alpha: 0.2),
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.closed_caption_rounded,
                                                  size: 16.r,
                                                  color: theme.primaryColor,
                                                ),
                                                SizedBox(width: 6.w),
                                                Text(
                                                  'Show Transcript',
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 12.5.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: theme.primaryColor,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 18.h),
                                      if (quest.question != null &&
                                          quest.question!.trim().isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                          ),
                                          child: Text(
                                            quest.question!,
                                            textAlign: TextAlign.center,
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 17.5.sp,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                              height: 1.35,
                                              letterSpacing: 0.1,
                                            ),
                                          ),
                                        ),
                                      SizedBox(height: 18.h),
                                      ListeningInferenceGrid(
                                        key: const Key(
                                          'listening_inference_grid',
                                        ),
                                        options: quest.options ?? [],
                                        correctAnswerIndex:
                                            quest.correctAnswerIndex ?? 0,
                                        color: theme.primaryColor,
                                        isAnswered: isAnsweredNotifier.value,
                                        isCorrectState: isCorrectNotifier.value,
                                        selectedIndex: _selectedIndex.value,
                                        onSubmitAnswer: (index) {
                                          hapticService.selection();
                                          _submitFinalAnswer(
                                            index,
                                            quest.correctAnswerIndex ?? 0,
                                            quest,
                                          );
                                        },
                                      ),
                                      if (isAnsweredNotifier.value &&
                                          quest.explanation != null)
                                        AnimatedSize(
                                          duration: const Duration(
                                            milliseconds: 350,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          child: ListeningInferenceExplanation(
                                            key: const Key(
                                              'listening_inference_explanation',
                                            ),
                                            explanation: quest.explanation!,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      SizedBox(height: 24.h),
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
