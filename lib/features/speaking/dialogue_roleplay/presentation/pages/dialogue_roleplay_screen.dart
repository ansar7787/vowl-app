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
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/text_similarity_helper.dart';
import 'package:vowl/core/utils/ml_services/smart_reply_service.dart';
import 'package:vowl/core/utils/ml_monetization_controller.dart';
import 'package:vowl/core/utils/widgets/smart_reply_chip.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:vowl/features/speaking/dialogue_roleplay/presentation/widgets/dialogue_roleplay_header.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/widgets/dialogue_roleplay_exchange_stage.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/widgets/dialogue_roleplay_telemetry_card.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/widgets/dialogue_roleplay_mic_trigger.dart';

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
  final _speechService = di.sl<SpeechService>();

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;
  int _attempts = 0;

  late AnimationController _synapticController;
  double _timeVal = 0.0;
  String _spokenText = "";
  List<String> _acceptedSynonyms = [];
  List<String> _smartReplies = [];

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
      smartReplyService.clearConversation();
      smartReplyService.addMessage(quest.partnerDialogue!, isLocalUser: false);
      
      final suggestions = await smartReplyService.getSuggestions();
      if (mounted) {
        setState(() {
          _smartReplies = suggestions;
        });
      }
    }
  }

  void _startSpeechListening() async {
    if (_isAnswered) return;
    _hapticService.selection();

    setState(() {
      _isListening = true;
      _spokenText = "Awaiting verbal speech input...";
    });

    _speechService.listen(
      onResult: (text) {
        setState(() {
          _spokenText = text;
        });
      },
      onDone: () {
        if (mounted) setState(() => _isListening = false);
      },
    );
  }

  void _stopSpeechListening() async {
    await _speechService.stop();

    setState(() {
      _isListening = false;
    });

    _verifyResponseSpoken();
  }

  void _verifyResponseSpoken() {
    if (_spokenText.isEmpty || _spokenText.startsWith("Awaiting")) {
      setState(() {
        _spokenText = "No vocal signals transcribed.";
      });
      _hapticService.error();
      return;
    }

    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );
    bool matchFound = false;

    for (var sub in _acceptedSynonyms) {
      final String cleanSub = sub.trim().toLowerCase().replaceAll(
        RegExp(r'[^\w\s]'),
        '',
      );
      if (cleanSpeech.contains(cleanSub) ||
          TextSimilarityHelper.isMatch(
            cleanSpeech,
            cleanSub,
            threshold: 0.70,
          )) {
        matchFound = true;
        break;
      }
    }

    setState(() {
      _attempts++;
      _isAnswered = true;
      _isCorrect = matchFound;
    });

    if (matchFound) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<SpeakingBloc>().add(SubmitAnswer(false));
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
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _attempts = 0;
              _isListening = false;
              _spokenText = "";
              _smartReplies = [];
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          } else if (state.lastAnswerCorrect == false) {
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
            onContinue: () => context.read<SpeakingBloc>().add(NextQuestion()),
            onHint: () => context.read<SpeakingBloc>().add(SpeakingHintUsed()),
            child: quest == null
                ? const SizedBox()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = constraints.maxHeight;
                      final bool isCompact = maxHeight < 580;

                      final double estimatedContentHeight =
                          24.h +
                          (isCompact ? 90.h : 120.h) +
                          (isCompact ? 80.h : 110.h) +
                          (isCompact ? 100.h : 140.h) +
                          (isCompact ? 60.h : 80.h);
                      final remainingHeight =
                          maxHeight - estimatedContentHeight;

                      final double gapUnit = remainingHeight > 0
                          ? remainingHeight / 8
                          : 0;
                      final double gapTop = remainingHeight > 0
                          ? (gapUnit * 1).clamp(6.0, 16.0)
                          : 6.0;
                      final double gapInstruction = remainingHeight > 0
                          ? (gapUnit * 1).clamp(8.0, 16.0)
                          : 8.0;
                      final double gapStage = remainingHeight > 0
                          ? (gapUnit * 1.5).clamp(10.0, 24.0)
                          : 10.0;
                      final double gapTelemetry = remainingHeight > 0
                          ? (gapUnit * 1.5).clamp(10.0, 24.0)
                          : 10.0;
                      final double gapMic = remainingHeight > 0
                          ? (gapUnit * 2).clamp(12.0, 30.0)
                          : 12.0;
                      final double gapBottom = remainingHeight > 0
                          ? (gapUnit * 1).clamp(12.0, 40.0)
                          : 12.0;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: maxHeight),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapTop),
                                    isCompact
                                        ? SizedBox(
                                            height: 32.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: DialogueRoleplayHeader(
                                                primaryColor:
                                                    theme.primaryColor,
                                                instruction: quest.instruction,
                                              ),
                                            ),
                                          )
                                        : DialogueRoleplayHeader(
                                            primaryColor: theme.primaryColor,
                                            instruction: quest.instruction,
                                          ),
                                    SizedBox(height: gapInstruction),

                                    isCompact
                                        ? SizedBox(
                                            height: 120.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width:
                                                    constraints.maxWidth - 16.w,
                                                child:
                                                    DialogueRoleplayExchangeStage(
                                                      quest: quest,
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      isDark: isDark,
                                                      timeVal: _timeVal,
                                                      isAnswered: _isAnswered,
                                                      isCorrect:
                                                          _isCorrect ?? false,
                                                    ),
                                              ),
                                            ),
                                          )
                                        : DialogueRoleplayExchangeStage(
                                            quest: quest,
                                            primaryColor: theme.primaryColor,
                                            isDark: isDark,
                                            timeVal: _timeVal,
                                            isAnswered: _isAnswered,
                                            isCorrect: _isCorrect ?? false,
                                          ),
                                    SizedBox(height: gapStage),

                                    if (_spokenText.isNotEmpty)
                                      isCompact
                                          ? SizedBox(
                                              height: 70.h,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: SizedBox(
                                                  width:
                                                      constraints.maxWidth -
                                                      16.w,
                                                  child:
                                                      DialogueRoleplayTelemetryCard(
                                                        spokenText: _spokenText,
                                                        isDark: isDark,
                                                      ),
                                                ),
                                              ),
                                            )
                                          : DialogueRoleplayTelemetryCard(
                                              spokenText: _spokenText,
                                              isDark: isDark,
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
                                            final isPremium = context.read<AuthBloc>().state.user?.isPremium ?? false;
                                            return SmartReplyChip(
                                              text: reply,
                                              isPremium: isPremium,
                                              onTap: () {
                                                MlMonetizationController.attemptFeature(
                                                  context,
                                                  featureIcon: Icons.auto_awesome_rounded,
                                                  featureTitle: context.tr('translation.smart_reply_title', fallback: 'AI Smart Reply'),
                                                  featureSubtitle: context.tr('translation.smart_reply_desc', fallback: 'Get AI-powered conversation suggestions'),
                                                  adButtonLabel: context.tr('translation.smart_reply_ad', fallback: 'Watch Ad (1 Suggestion)'),
                                                  onSuccess: () {
                                                    setState(() {
                                                      _acceptedSynonyms.add(reply);
                                                      _spokenText = reply; // Display as hint for them to speak
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
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapTelemetry),
                                    SizedBox(height: gapMic),

                                    if (!_isAnswered)
                                      isCompact
                                          ? SizedBox(
                                              height: 70.h,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child:
                                                    DialogueRoleplayMicTrigger(
                                                      isListening: _isListening,
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      onLongPressStart:
                                                          _startSpeechListening,
                                                      onLongPressEnd:
                                                          _stopSpeechListening,
                                                      attempts: _attempts,
                                                      isAnswered: _isAnswered,
                                                      
                                                    ),
                                              ),
                                            )
                                          : DialogueRoleplayMicTrigger(
                                              isListening: _isListening,
                                              primaryColor: theme.primaryColor,
                                              onLongPressStart:
                                                  _startSpeechListening,
                                              onLongPressEnd:
                                                  _stopSpeechListening,
                                              attempts: _attempts,
                                              isAnswered: _isAnswered,
                                              
                                            ),
                                    SizedBox(height: gapBottom),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}

