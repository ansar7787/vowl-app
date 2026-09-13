import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';

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
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<double> _bloomProgress = ValueNotifier(0.0);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;

  final ValueNotifier<bool> _ttsFinished = ValueNotifier(false);
  Timer? _ttsTimer;

  final ScrollController _scrollController = ScrollController();

  List<String> _acceptedSyns = [];
  SpeakingQuest? _currentQuest;

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _bloomProgress.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _scrollController.dispose();
    _ttsFinished.dispose();
    _ttsTimer?.cancel();
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

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      final String cleanSentence = quest.textToSpeak!.replaceAll('*', '');
      _soundService.playTts(cleanSentence);
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;
    _bloomProgress.value = nailedIt ? 1.0 : 0.0;

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();

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

  void _extractTargetWord(String text, List<String> synonyms) {
    _acceptedSyns = synonyms;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);
    final mediaQuery = MediaQuery.of(context);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (!state.answerStatus.isAnswered && _isAnswered.value)) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _bloomProgress.value = 0.0;
            _ttsFinished.value = false;
            _ttsTimer?.cancel();
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
            _ttsTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) {
                _ttsFinished.value = true;
                _scrollToBottom();
              }
            });
          } else if (state.answerStatus == AnswerStatus.incorrect) {
            _isCorrect.value = false;
            _isAnswered.value = true; // Always show feedback card on incorrect
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr(
              'speaking_games.lexical_pivot',
              fallback: 'LEXICAL PIVOT COMPLETE!',
            ),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;
        final hintUsed = (state is SpeakingLoaded) ? state.hintUsed : false;

        if (quest != null) {
          _currentQuest = quest;
          _extractTargetWord(
            quest.textToSpeak ?? "",
            quest.acceptedSynonyms ?? [],
          );
        }

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _isAnswered,
              _isCorrect,
              _showConfetti,
              _bloomProgress,
              _ttsFinished,
            ]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: _isAnswered.value,
                isCorrect: _isCorrect.value,
                showConfetti: _showConfetti.value,
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
                                    SpeakSynonymHeader(
                                      primaryColor: theme.primaryColor,
                                      instruction:
                                          "Say a different word with the same meaning",
                                    ),
                                    SizedBox(height: 24.h),
                                    SpeakSynonymSentencePanel(
                                      quest: quest,
                                      primaryColor: theme.primaryColor,
                                      isDark: isDark,
                                      onPlayTts: () {
                                        if (di
                                            .sl<AudioRecordingService>()
                                            .isRecording) {
                                          return;
                                        }
                                        _soundService.playTts(
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
                                        padding: EdgeInsets.all(16.r),
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
                                              color: theme.primaryColor,
                                              size: 20.r,
                                            ),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: Text(
                                                quest.hint!,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 14.sp,
                                                  color: isDark
                                                      ? Colors.white70
                                                      : Colors.black87,
                                                  height: 1.4,
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
                            if (!_isAnswered.value)
                              SliverPadding(
                                padding: EdgeInsets.only(bottom: 120.h),
                                sliver: SliverToBoxAdapter(
                                  child: AnimatedOpacity(
                                    opacity: _ttsFinished.value ? 1.0 : 0.4,
                                    duration: const Duration(milliseconds: 300),
                                    child: AbsorbPointer(
                                      absorbing: !_ttsFinished.value,
                                      child: SpeakToConfirmOverlay(
                                        expectedText: _acceptedSyns.join(', '),
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
