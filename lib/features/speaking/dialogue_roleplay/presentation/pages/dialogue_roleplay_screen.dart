import 'dart:async';
import 'package:flutter/material.dart';
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
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/ml_services/smart_reply_service.dart';
import 'package:vowl/core/utils/ml_monetization_controller.dart';
import 'package:vowl/core/utils/widgets/smart_reply_chip.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/speaking_self_evaluation_controls.dart';

import 'package:vowl/features/speaking/dialogue_roleplay/presentation/widgets/dialogue_roleplay_header.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/widgets/dialogue_roleplay_exchange_stage.dart';

class DialogueRoleplayScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const DialogueRoleplayScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.dialogueRoleplay,
  });

  @override
  State<DialogueRoleplayScreen> createState() => _DialogueRoleplayScreenState();
}

class _DialogueRoleplayScreenState extends State<DialogueRoleplayScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  late AnimationController _synapticController;
  double _timeVal = 0.0;

  List<String> _acceptedSynonyms = [];
  List<String> _smartReplies = [];
  String _chosenReply = "";

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
    );

    _synapticController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..addListener(() {
            setState(() {
              _timeVal = _synapticController.value;
            });
          });
    _synapticController.repeat();
  }

  @override
  void dispose() {
    _synapticController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(SpeakingQuest quest) async {
    if (quest.partnerDialogue != null) {
      _soundService.playTts(quest.partnerDialogue!);

      // Fetch AI Smart Replies based on the NPC's dialogue
      final smartReplyService = di.sl<SmartReplyService>();
      // smartReplyService.clearConversation();
      smartReplyService.addMessage(quest.partnerDialogue!, isLocalUser: false);

      final suggestions = await smartReplyService.getSuggestions();
      if (mounted) {
        setState(() {
          _smartReplies = suggestions
              .where(
                (s) => s.trim().length > 1 && RegExp(r'[a-zA-Z]').hasMatch(s),
              )
              .toList();
          final fallbackOptions = quest.smartReplies ?? quest.acceptedSynonyms;
          if (fallbackOptions != null) {
            final List<String> availableSynonyms = List.from(fallbackOptions)
              ..shuffle();

            for (var synonym in availableSynonyms) {
              if (_smartReplies.length >= 3) break;
              if (!_smartReplies.contains(synonym)) {
                _smartReplies.add(synonym);
              }
            }
          }
        });
      }
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();

      // Add a default or chosen message to history if correct
      final responseText = _chosenReply.isNotEmpty
          ? _chosenReply
          : (_acceptedSynonyms.isNotEmpty ? _acceptedSynonyms.first : "Yes");
      di.sl<SmartReplyService>().addMessage(responseText, isLocalUser: true);

      context.read<SpeakingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _tutorPass() {
    GameDialogHelper.showHonestyNudge(context);
    setState(() {
      _isAnswered = true;
      _isCorrect = true;
    });
    context.read<SpeakingBloc>().add(const SpeakingTutorPass());
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
              (!state.answerStatus.isAnswered && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _smartReplies = [];
              _chosenReply = "";
            });
            if (state.currentIndex == 0) {
              di.sl<SmartReplyService>().clearConversation();
            }
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          } else if (state.answerStatus == AnswerStatus.incorrect) {
            setState(() {
              _isCorrect = false;
              if (state.isFinalFailure || state.livesRemaining <= 0) {
                _isAnswered = true;
              } else {
                _isAnswered = false;
              }
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'DIALOGUE EXPERT!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        if (quest != null) {
          _acceptedSynonyms = quest.acceptedSynonyms ?? [];
        }

        final expectedText = _chosenReply.isNotEmpty
            ? _chosenReply
            : (_acceptedSynonyms.isNotEmpty ? _acceptedSynonyms.first : "");

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: SpeakingBaseLayout(
            onTutorPass: _tutorPass,
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,
            onContinue: () =>
                context.read<SpeakingBloc>().add(const NextQuestion()),
            onHint: () =>
                context.read<SpeakingBloc>().add(const SpeakingHintUsed()),
            child: quest == null
                ? const SizedBox()
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DialogueRoleplayHeader(
                                primaryColor: theme.primaryColor,
                                instruction: quest.instruction,
                              ),
                              SizedBox(height: 24.h),
                              DialogueRoleplayExchangeStage(
                                quest: quest,
                                primaryColor: theme.primaryColor,
                                isDark: isDark,
                                timeVal: _timeVal,
                                isAnswered: _isAnswered,
                                isCorrect: _isCorrect ?? false,
                              ),
                              if (_smartReplies.isNotEmpty && !_isAnswered) ...[
                                SizedBox(height: 16.h),
                                SizedBox(
                                  height: 44.h,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _smartReplies.length,
                                    itemBuilder: (context, index) {
                                      final reply = _smartReplies[index];
                                      final isPremium =
                                          context
                                              .read<AuthBloc>()
                                              .state
                                              .user
                                              ?.isPremium ??
                                          false;
                                      return SmartReplyChip(
                                        text: reply,
                                        isPremium: isPremium,
                                        onTap: () {
                                          MlMonetizationController.attemptFeature(
                                            context,
                                            featureIcon:
                                                Icons.auto_awesome_rounded,
                                            featureTitle: context.tr(
                                              'translation.smart_reply_title',
                                              fallback: 'AI Smart Reply',
                                            ),
                                            featureSubtitle: context.tr(
                                              'translation.smart_reply_desc',
                                              fallback:
                                                  'Get AI-powered conversation suggestions',
                                            ),
                                            adButtonLabel: context.tr(
                                              'translation.smart_reply_ad',
                                              fallback:
                                                  'Watch Ad (1 Suggestion)',
                                            ),
                                            onSuccess: () {
                                              setState(() {
                                                _chosenReply = reply;
                                              });
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!_isAnswered)
                                SpeakingSelfEvaluationControls(
                                  expectedText: expectedText,
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(true),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(false),
                                ),
                            ],
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
}
