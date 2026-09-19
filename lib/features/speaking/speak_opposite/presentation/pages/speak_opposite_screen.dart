import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/mixins/speaking_game_screen_mixin.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';

import 'package:vowl/features/speaking/speak_opposite/presentation/widgets/speak_opposite_parser.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/widgets/speak_opposite_positive_pole_panel.dart';

class SpeakOppositeScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const SpeakOppositeScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speakOpposite,
  });

  @override
  State<SpeakOppositeScreen> createState() => _SpeakOppositeScreenState();
}

class _SpeakOppositeScreenState extends State<SpeakOppositeScreen>
    with SpeakingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<bool> _ttsFinished = ValueNotifier(false);
  Timer? _ttsTimer;
  final ScrollController _scrollController = ScrollController();

  List<String> _acceptedAntonyms = [];

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

    initSpeakingGame();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _ttsFinished.dispose();
    _ttsTimer?.cancel();
    disposeSpeakingGame();
    super.dispose();
  }

  void _submitVerbalEvaluation(bool nailedIt, String expectedText) {
    if (isAnsweredNotifier.value) return;

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
          question: 'Speak Opposite',
          userAnswer: '[Failed Antonym/Timer]',
          correctAnswer: expectedText,
          level: widget.level,
        );
      }

      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _ttsFinished.value = false;
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

        String expectedText = "";
        String targetWord = "?";
        String contextText = "";

        if (quest != null) {
          _acceptedAntonyms = List<String>.from(quest.acceptedSynonyms ?? []);
          if (_acceptedAntonyms.isEmpty && quest.correctAnswer != null) {
            String cleaned = quest.correctAnswer!
                .replaceAll(RegExp(r'[^\w\s]'), '')
                .trim();
            if (cleaned.isNotEmpty) {
              _acceptedAntonyms = [cleaned];
            }
          }

          expectedText = _acceptedAntonyms.isNotEmpty
              ? _acceptedAntonyms.first
              : "";

          final parsed = SpeakOppositeParser.parseQuestTexts(
            textToSpeak: quest.textToSpeak ?? "",
            fallbackInstruction: quest.instruction,
          );
          targetWord = parsed.targetWord;
          contextText = parsed.contextText;
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
              _ttsFinished,
            ]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: isAnsweredNotifier.value,
                isCorrect: isCorrectNotifier.value,
                showConfetti: showConfettiNotifier.value,
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
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: 24.h),
                                    SpeakOppositePositivePolePanel(
                                      targetWord: targetWord,
                                      contextText: contextText,
                                      primaryColor: theme.primaryColor,
                                      isDark: isDark,
                                      onPlayTts: () {
                                        if (di
                                            .sl<AudioRecordingService>()
                                            .isRecording) {
                                          return;
                                        }
                                        soundService.playTts(targetWord);
                                      },
                                    ),
                                    SizedBox(height: 48.h),
                                  ],
                                ),
                              ),
                            ),
                            if (!isAnsweredNotifier.value)
                              SliverToBoxAdapter(
                                child: AnimatedOpacity(
                                  opacity: _ttsFinished.value ? 1.0 : 0.4,
                                  duration: const Duration(milliseconds: 300),
                                  child: AbsorbPointer(
                                    absorbing: !_ttsFinished.value,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 16.h,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          SpeakToConfirmOverlay(
                                            expectedText: expectedText,
                                            acceptedSynonyms: _acceptedAntonyms,
                                            primaryColor: theme.primaryColor,
                                            isPositioned: false,
                                            hideExpectedText: true,
                                            allowSkip: false,
                                            title: 'SAY THE OPPOSITE',
                                            subtitle:
                                                'Hold the mic and speak aloud',
                                            onConfirmed: () =>
                                                _submitVerbalEvaluation(
                                                  true,
                                                  expectedText,
                                                ),
                                            onSkipped: () =>
                                                _submitVerbalEvaluation(
                                                  false,
                                                  expectedText,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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
