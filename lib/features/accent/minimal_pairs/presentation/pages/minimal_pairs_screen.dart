import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_instruction.dart';
// Removed unused MinimalPairsPromptCard import
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_speaker_core.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_drone_option.dart';
import 'package:vowl/features/elite_mastery/accent_shadowing/presentation/widgets/accent_shadowing_mic_trigger.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/text_similarity_helper.dart';
import 'package:vowl/features/accent/presentation/constants/accent_game_constants.dart';

class MinimalPairsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const MinimalPairsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.minimalPairs,
  });

  @override
  State<MinimalPairsScreen> createState() => _MinimalPairsScreenState();
}

class _MinimalPairsScreenState extends State<MinimalPairsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int _lastLives = AccentGameConstants.maxLives;
  AccentQuest? _lastQuest;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int? _selectedDroneIndex;
  
  final _speechService = di.sl<SpeechService>();
  bool _isListening = false;
  String _lastWords = "";

  String? _shuffledQuestId;
  List<Map<String, String>> _currentOptions = [];
  int _currentCorrectIndex = 0;

  void _ensureOptionsShuffled(AccentQuest quest) {
    if (_shuffledQuestId == quest.id) return;
    
    _shuffledQuestId = quest.id;
    
    final originalOptions = [
      {'word': quest.word1 ?? '', 'ipa': quest.ipa1 ?? ''},
      {'word': quest.word2 ?? '', 'ipa': quest.ipa2 ?? ''},
    ];
    
    final correctAnswerStr = quest.correctAnswer;
        
    _currentOptions = List.from(originalOptions)..shuffle();
    if (correctAnswerStr != null) {
        _currentCorrectIndex = _currentOptions.indexWhere((opt) => opt['word'] == correctAnswerStr);
    } else {
        _currentCorrectIndex = _currentOptions.indexWhere((opt) => opt['word'] == originalOptions[quest.correctAnswerIndex ?? 0]['word']);
    }
    if (_currentCorrectIndex == -1) _currentCorrectIndex = 0;
  }

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    if (_isListening) {
      _speechService.stop();
    }
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isAnswered) return;
    if (_isListening) {
      setState(() {
        _isListening = false;
      });
      await _speechService.stop();
    } else {
      final available = await _speechService.initializeStt();
      if (available) {
        setState(() {
          _isListening = true;
          _lastWords = "";
        });
        _speechService.listen(
          pauseFor: const Duration(milliseconds: 1500), // Snappy 1.5s stop
          listenMode: ListenMode.confirmation, // Better for short commands
          onResult: (candidates, isFinal) {
            if (candidates.isEmpty) return;
            final text = candidates.first;
            if (mounted) {
              setState(() {
                _lastWords = text;
              });
              
              int bestIndex = -1;
              double bestScore = 0.0;
              
              // Evaluate ALL candidates to find the best match
              for (String candidate in candidates) {
                final String lowerCand = candidate.toLowerCase().trim();
                final List<String> candWords = lowerCand.split(RegExp(r'\s+'));
                
                for (int i = 0; i < _currentOptions.length; i++) {
                  final String optWord = _currentOptions[i]['word']!.toLowerCase().trim();
                  
                  if (lowerCand == optWord || candWords.contains(optWord)) {
                    bestIndex = i;
                    bestScore = 1.0;
                    break;
                  }
                  
                  final double score = TextSimilarityHelper.levenshteinSimilarity(lowerCand, optWord);
                  if (score > bestScore) {
                    bestScore = score;
                    bestIndex = i;
                  }
                }
                if (bestScore == 1.0) break;
              }
              
              // Progression Guarantee Logic:
              if (bestScore == 1.0) {
                // Perfect match: Instant shoot
                _speechService.stop();
                setState(() => _isListening = false);
                _onShoot(bestIndex, _currentCorrectIndex);
              } else if (isFinal) {
                // User stopped speaking. Game MUST progress.
                _speechService.stop();
                setState(() => _isListening = false);
                
                int finalIndex = bestIndex;
                // If they mumbled completely random gibberish (score < 0.3), force a wrong answer.
                if (finalIndex == -1 || bestScore < 0.3) {
                  finalIndex = _currentCorrectIndex == 0 ? 1 : 0;
                }
                _onShoot(finalIndex, _currentCorrectIndex);
              }
            }
          },
          onDone: () {
            if (mounted && _isListening) {
              setState(() {
                _isListening = false;
              });
            }
          },
        );
        _hapticService.selection();
      }
    }
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
  }

  void _onShoot(int index, int correctIndex) {
    if (_isAnswered) return;

    // GUARANTEE: Instantly kill the mic to prevent double-triggers from late STT callbacks!
    if (_isListening) {
      _speechService.stop();
      setState(() {
        _isListening = false;
      });
    }

    final bool correct = index == correctIndex;
    setState(() {
      _selectedDroneIndex = index;
    });

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          _lastQuest = state.currentQuest as AccentQuest?;
          final livesChanged = (state.livesRemaining > _lastLives);
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedDroneIndex = null;
              _isListening = false;
              _lastWords = "";
            });
            // Proactively auto-play phonetic sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null && quest.textToSpeak != null) {
              Future.delayed(500.milliseconds, () {
                if (mounted) {
                  _soundService.playTts(quest.textToSpeak!);
                }
              });
            }
          }
          _lastLives = state.livesRemaining;
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'PHONETIC EXPERT!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : _lastQuest;
            
        if (quest != null && !_isAnswered) {
          _ensureOptionsShuffled(quest);
        }
        
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: AccentBaseLayout(
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,
            onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
            onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
            child: quest == null
                ? const SizedBox()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = constraints.maxHeight;
                      final maxWidth = constraints.maxWidth;
                      final bool isCompact = maxHeight < 580;

                      final double estimatedContentHeight =
                          24.h +
                          (isCompact ? 90.h : 120.h) +
                          100.h +
                          (isCompact ? 130.h : 172.h) +
                          (_isAnswered ? (isCompact ? 110.h : 160.h) : 0);
                      final remainingHeight =
                          maxHeight - estimatedContentHeight;

                      final double gapUnit = remainingHeight > 0
                          ? remainingHeight / 8
                          : 0;
                      final double gapTop = remainingHeight > 0
                          ? (gapUnit * 1).clamp(8.0, 24.0)
                          : 8.0;

                      final double gapSpeaker = remainingHeight > 0
                          ? (gapUnit * 2).clamp(16.0, 48.0)
                          : 16.0;

                      final double gapBottom = remainingHeight > 0
                          ? (gapUnit * 1).clamp(12.0, 40.0)
                          : 12.0;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: maxHeight),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapTop),
                                    MinimalPairsInstruction(
                                      color: theme.primaryColor,
                                      instruction: context.tr('games.minimal_pairs_instruction', fallback: quest.instruction),
                                    ),
                                  ],
                                ),
                                MinimalPairsSpeakerCore(
                                  text: quest.textToSpeak ?? "",
                                  color: theme.primaryColor,
                                  onPlayTts: _playTts,
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapSpeaker),
                                    isCompact
                                        ? SizedBox(
                                            height: 110.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width: maxWidth - 48.w,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    MinimalPairsDroneOption(
                                                      index: 0,
                                                      word: _currentOptions.isNotEmpty ? _currentOptions[0]['word']! : quest.word1 ?? "",
                                                      ipa: _currentOptions.isNotEmpty ? _currentOptions[0]['ipa']! : quest.ipa1 ?? "",
                                                      correctIndex: _currentOptions.isNotEmpty ? _currentCorrectIndex : quest.correctAnswerIndex ?? 0,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      isAnswered: _isAnswered,
                                                      selectedDroneIndex:
                                                          _selectedDroneIndex,
                                                      onShoot: _onShoot,
                                                    ),
                                                    MinimalPairsDroneOption(
                                                      index: 1,
                                                      word: _currentOptions.isNotEmpty ? _currentOptions[1]['word']! : quest.word2 ?? "",
                                                      ipa: _currentOptions.isNotEmpty ? _currentOptions[1]['ipa']! : quest.ipa2 ?? "",
                                                      correctIndex: _currentOptions.isNotEmpty ? _currentCorrectIndex : quest.correctAnswerIndex ?? 0,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      isAnswered: _isAnswered,
                                                      selectedDroneIndex:
                                                          _selectedDroneIndex,
                                                      onShoot: _onShoot,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              MinimalPairsDroneOption(
                                                index: 0,
                                                word: _currentOptions.isNotEmpty ? _currentOptions[0]['word']! : quest.word1 ?? "",
                                                ipa: _currentOptions.isNotEmpty ? _currentOptions[0]['ipa']! : quest.ipa1 ?? "",
                                                correctIndex: _currentOptions.isNotEmpty ? _currentCorrectIndex : quest.correctAnswerIndex ?? 0,
                                                color: theme.primaryColor,
                                                isDark: isDark,
                                                isAnswered: _isAnswered,
                                                selectedDroneIndex:
                                                    _selectedDroneIndex,
                                                onShoot: _onShoot,
                                              ),
                                              MinimalPairsDroneOption(
                                                index: 1,
                                                word: _currentOptions.isNotEmpty ? _currentOptions[1]['word']! : quest.word2 ?? "",
                                                ipa: _currentOptions.isNotEmpty ? _currentOptions[1]['ipa']! : quest.ipa2 ?? "",
                                                correctIndex: _currentOptions.isNotEmpty ? _currentCorrectIndex : quest.correctAnswerIndex ?? 0,
                                                color: theme.primaryColor,
                                                isDark: isDark,
                                                isAnswered: _isAnswered,
                                                selectedDroneIndex:
                                                    _selectedDroneIndex,
                                                onShoot: _onShoot,
                                              ),
                                            ],
                                          ),
                                          
                                    SizedBox(height: isCompact ? 16.h : 24.h),
                                    if (_lastWords.isNotEmpty)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(15.r),
                                        ),
                                        child: Text(
                                          _lastWords,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ).animate().fadeIn(),
                                    SizedBox(height: isCompact ? 16.h : 24.h),
                                    AccentShadowingMicTrigger(
                                      isListening: _isListening,
                                      onTap: _toggleListening,
                                      primaryColor: theme.primaryColor,
                                      attempts: 0,
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
