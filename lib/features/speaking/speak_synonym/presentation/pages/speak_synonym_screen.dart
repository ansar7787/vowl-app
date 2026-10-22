import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/mixins/speaking_game_screen_mixin.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

import 'package:vowl/features/speaking/speak_synonym/presentation/widgets/speak_synonym_header.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/widgets/speak_synonym_sentence_panel.dart';

class SpeakSynonymScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const SpeakSynonymScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speakSynonym,
  });

  @override
  State<SpeakSynonymScreen> createState() => _SpeakSynonymScreenState();
}

class _SpeakSynonymScreenState extends State<SpeakSynonymScreen>
    with
        SingleTickerProviderStateMixin,
        GameScreenMixin<SpeakSynonymScreen>,
        SpeakingGameScreenMixin<SpeakSynonymScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<double> _bloomProgress = ValueNotifier(0.0);

  final ValueNotifier<bool> _ttsFinished = ValueNotifier(false);
  Timer? _ttsTimer;
  Timer? _autoPlayTimer;

  final ScrollController _scrollController = ScrollController();

  List<String> _acceptedSyns = [];
  SpeakingQuest? _currentQuest;

  @override
  void initState() {
    super.initState();
    initGameLifecycle();
    initSpeakingGame();

    final initialBlocState = context.read<SpeakingBloc>().state;
    if (initialBlocState is SpeakingLoaded &&
        !initialBlocState.answerStatus.isAnswered) {
      if (VowlMotion.lowAnimationModeOverride.value) {
        _triggerAutoPlay(initialBlocState.currentQuest);
      } else {
        _autoPlayTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted) _triggerAutoPlay(initialBlocState.currentQuest);
        });
      }
    } else {
      _ttsFinished.value = true;
    }
  }

  void _triggerAutoPlay(SpeakingQuest quest) {
    final text = (quest.textToSpeak ?? "").replaceAll('*', '').trim();
    if (text.isNotEmpty) {
      soundService.playTts(text);
      _ttsTimer?.cancel();
      if (VowlMotion.lowAnimationModeOverride.value) {
        _ttsFinished.value = true;
      } else {
        _ttsTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) _ttsFinished.value = true;
        });
      }
    } else {
      _ttsFinished.value = true;
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _ttsTimer?.cancel();
    _bloomProgress.dispose();
    _scrollController.dispose();
    _ttsFinished.dispose();
    disposeSpeakingGame();
    super.dispose();
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;
    _bloomProgress.value = nailedIt ? 1.0 : 0.0;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<SpeakingBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();

      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated &&
          authState.user != null &&
          _currentQuest != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: _currentQuest!.textToSpeak ?? 'Unknown',
          userAnswer: '[Failed Synonym]',
          correctAnswer:
              _currentQuest!.correctAnswer ??
              (_acceptedSyns.isNotEmpty ? _acceptedSyns.first : ''),
          level: widget.level,
        );
      }

      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  @visibleForTesting
  void submitEvaluation(bool nailedIt) => _submitVerbalEvaluation(nailedIt);

  @visibleForTesting
  ValueNotifier<bool> get ttsFinishedNotifier => _ttsFinished;

  @visibleForTesting
  ValueNotifier<double> get bloomProgressNotifier => _bloomProgress;

  void _extractTargetWord(String text, List<String> synonyms, String? correctAnswer) {
    if (synonyms.isNotEmpty) {
      _acceptedSyns = List<String>.from(synonyms);
    } else if (correctAnswer != null && correctAnswer.trim().isNotEmpty) {
      _acceptedSyns = [correctAnswer.trim()];
    } else {
      _acceptedSyns = [];
    }
  }

  @override
  void onQuestionReset() {
    _bloomProgress.value = 0.0;
    _ttsFinished.value = false;
    _ttsTimer?.cancel();
    _autoPlayTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);
    final mediaQuery = MediaQuery.of(context);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listenWhen: speakingListenWhen,
      listener: (context, state) {
        onSpeakingStateChanged(context, state);
        if (state is SpeakingLoaded && !state.answerStatus.isAnswered) {
          _ttsFinished.value = false;
          _ttsTimer?.cancel();
          _autoPlayTimer?.cancel();
          if (VowlMotion.lowAnimationModeOverride.value) {
            _triggerAutoPlay(state.currentQuest);
          } else {
            _autoPlayTimer = Timer(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;
        final hintUsed = (state is SpeakingLoaded) ? state.hintUsed : false;

        String expectedText = "";
        if (quest != null) {
          _currentQuest = quest;
          _extractTargetWord(
            quest.textToSpeak ?? "",
            quest.acceptedSynonyms ?? [],
            quest.correctAnswer,
          );
          if (_acceptedSyns.isNotEmpty) {
            final correct = quest.correctAnswer;
            expectedText = (correct != null && _acceptedSyns.contains(correct))
                ? correct
                : _acceptedSyns.first;
          }
        }

        final reduceMotion = (mediaQuery.disableAnimations) ||
            VowlMotion.lowAnimationModeOverride.value;
        if (reduceMotion && !_ttsFinished.value) {
          _ttsFinished.value = true;
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
              _bloomProgress,
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
                onHint: () {},
                child: quest == null
                    ? GameShimmerLoading(primaryColor: theme.primaryColor)
                    : RawScrollbar(
                        key: const Key('speak_synonym_scrollbar'),
                        controller: _scrollController,
                        thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                        radius: Radius.circular(8.r),
                        thickness: 4.w,
                        child: CustomScrollView(
                          key: const Key('speak_synonym_scroll_view'),
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
                                    SpeakSynonymHeader(
                                      key: const Key('speak_synonym_header'),
                                      primaryColor: theme.primaryColor,
                                      instruction: quest.instruction,
                                    ),
                                    SizedBox(height: 24.h),
                                    SpeakSynonymSentencePanel(
                                      key: const Key('speak_synonym_sentence_panel'),
                                      quest: quest,
                                      primaryColor: theme.primaryColor,
                                      isDark: isDark,
                                      onPlayTts: () {
                                        if (di
                                            .sl<AudioRecordingService>()
                                            .isRecording) {
                                          return;
                                        }
                                        soundService.playTts(
                                          (quest.textToSpeak ?? "").replaceAll(
                                            '*',
                                            '',
                                          ),
                                        );
                                      },
                                    ),
                                    if (hintUsed && quest.hint != null) ...[
                                      SizedBox(height: 16.h),
                                      Container(
                                        key: const Key('speak_synonym_hint_card'),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 14.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                          border: Border.all(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.lightbulb_outline,
                                              key: const Key('speak_synonym_hint_icon'),
                                              color: theme.primaryColor,
                                              size: 20.r,
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: Text(
                                                quest.hint!,
                                                key: const Key('speak_synonym_hint_text'),
                                                softWrap: true,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark
                                                      ? Colors.white.withValues(alpha: 0.88)
                                                      : const Color(0xFF334155),
                                                  height: 1.45,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 32.h),
                                  ],
                                ),
                              ),
                            ),
                            if (!isAnsweredNotifier.value)
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  20.w,
                                  0,
                                  20.w,
                                  120.h,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: AnimatedOpacity(
                                    opacity: _ttsFinished.value ? 1.0 : 0.4,
                                    duration: const Duration(milliseconds: 300),
                                    child: AbsorbPointer(
                                      absorbing: !_ttsFinished.value,
                                      child: SpeakToConfirmOverlay(
                                        key: const Key(
                                          'speak_synonym_speak_to_confirm_overlay',
                                        ),
                                        expectedText: expectedText,
                                        acceptedSynonyms: _acceptedSyns,
                                        primaryColor: theme.primaryColor,
                                        isPositioned: false,
                                        hideExpectedText: true,
                                        allowSkip: false,
                                        title: 'SPEAK A SYNONYM',
                                        subtitle:
                                            'Say your answer aloud to confirm',
                                        onConfirmed: () =>
                                            _submitVerbalEvaluation(true),
                                        onSkipped: () =>
                                            _submitVerbalEvaluation(false),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              SliverToBoxAdapter(
                                child: SizedBox(height: 120.h),
                              ),
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
