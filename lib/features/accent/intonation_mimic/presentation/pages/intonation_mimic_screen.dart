import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/domain/entities/game_quest.dart' as entities;
import 'package:voxai_quest/core/presentation/pages/quest_unavailable_screen.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/accent/harmonic_waves.dart';
import 'package:voxai_quest/core/presentation/widgets/game_confetti.dart';
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:voxai_quest/core/presentation/widgets/games/victory_screen.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/features/accent/domain/entities/accent_quest.dart';
import 'package:voxai_quest/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:voxai_quest/core/presentation/widgets/game_dialog_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';

import '../widgets/im_awareness_section.dart';
import '../widgets/im_feedback_card.dart';
import '../widgets/im_option_button.dart';
import '../widgets/im_sound_card.dart';
import '../widgets/im_top_bar.dart';

// ─── IPA Dictionary (covers all 200 levels) ────────────────────────────────
const _ipaMap = <String, String>{
  'THINK': '/θɪŋk/',
  'THIS': '/ðɪs/',
  'THREE': '/θriː/',
  'THAT': '/ðæt/',
  'THROUGH': '/θruː/',
  'THEM': '/ðɛm/',
  'THROW': '/θroʊ/',
  'THEN': '/ðɛn/',
  'THANK': '/θæŋk/',
  'THOSE': '/ðoʊz/',
  'SHIP': '/ʃɪp/',
  'CHIP': '/tʃɪp/',
  'JOB': '/dʒɒb/',
  'VISION': '/ˈvɪʒən/',
  'RING': '/rɪŋ/',
  'STRENGTH': '/strɛŋθ/',
  'SPLASH': '/splæʃ/',
  'SCRIPT': '/skrɪpt/',
  'KNIGHT': '/naɪt/',
  'WRITE': '/raɪt/',
  'LISTEN': '/ˈlɪsən/',
  'CASTLE': '/ˈkɑːsəl/',
  'COMB': '/koʊm/',
  'DOUBT': '/daʊt/',
  'PSALM': '/sɑːm/',
  'GNAW': '/nɔː/',
  'HOUR': '/aʊər/',
  'WRAP': '/ræp/',
  'ISLAND': '/ˈaɪlənd/',
  'SUBTLE': '/ˈsʌtəl/',
};

// ─── Pronunciation Tips (contextual, based on option types) ────────────────
const _pronunciationTips = <String, String>{
  'THINK': '🦷 Tongue between teeth, blow air gently',
  'THIS': '🦷 Tongue between teeth, voice vibrates',
  'THREE': '🦷 Tongue between teeth, no vibration',
  'THAT': '🦷 Tongue between teeth, voice vibrates',
  'THROUGH': '🦷 Air flows between tongue and teeth',
  'THEM': '🦷 Tongue touches teeth, throat vibrates',
  'THROW': '🦷 Air passes over tongue tip',
  'THEN': '🦷 Tongue between teeth, feel the buzz',
  'THANK': '🦷 Breathe out between tongue and teeth',
  'THOSE': '🦷 Tongue touches upper teeth, voiced',
  'SHIP': '🗣 Round lips, push air through wide tongue',
  'CHIP': '🗣 Tongue hits roof, then releases air with "sh"',
  'JOB': '🗣 Tongue hits roof, voiced "ch" sound',
  'VISION': '🗣 Like "sh" but with voice vibrating',
  'RING': '🗣 Back of tongue touches soft palate',
  'STRENGTH': '🗣 Three consonants: s-t-r blend together',
  'SPLASH': '🗣 Three consonants: s-p-l flow into each other',
  'SCRIPT': '🗣 Three consonants: s-k-r start the word',
  'KNIGHT': '🔇 The K is written but completely silent',
  'WRITE': '🔇 The W is written but never pronounced',
  'LISTEN': '🔇 The T hides silently in the middle',
  'CASTLE': '🔇 The T is silent between s and l',
  'COMB': '🔇 The B at the end is never spoken',
  'DOUBT': '🔇 The B is silent, just say "dowt"',
  'PSALM': '🔇 The P is completely silent',
  'GNAW': '🔇 The G before N is always silent',
  'HOUR': '🔇 The H is silent, starts with "ow"',
  'WRAP': '🔇 The W before R is always silent',
  'ISLAND': '🔇 The S is silent, say "eye-lund"',
  'SUBTLE': '🔇 The B hides silently between u and t',
};

// ─── Awareness prompts based on question type ──────────────────────────────
String _getAwarenessPrompt(List<String> options) {
  final joined = options.join(' ').toLowerCase();
  if (joined.contains('voiced') || joined.contains('unvoiced')) {
    return '🤚 Touch your throat\nDoes it vibrate?';
  }
  if (joined.contains('sh') || joined.contains('ch') || joined.contains('zh')) {
    return '👄 Shape your mouth\nFeel how the air flows';
  }
  if (joined.contains('str') ||
      joined.contains('spl') ||
      joined.contains('scr')) {
    return '🗣 Say it slowly\nCount the starting sounds';
  }
  if (options.every((o) => o.length <= 2)) {
    return '👂 Listen carefully\nWhich letter is hiding?';
  }
  return '👂 Listen and feel\nHow is this sound made?';
}

class IntonationMimicScreen extends StatefulWidget {
  final int level;
  const IntonationMimicScreen({super.key, required this.level});

  @override
  State<IntonationMimicScreen> createState() => _IntonationMimicScreenState();
}

class _IntonationMimicScreenState extends State<IntonationMimicScreen> {
  final _speechService = di.sl<SpeechService>();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  bool _isPlaying = false;
  bool _showConfetti = false;
  bool _slowMode = false;
  int _listensRemaining = 3;

  int? _selectedOptionIndex;
  bool _hasAnswered = false;
  bool _showFeedback = false;
  bool _isCorrectAnswer = false;

  List<int> _shuffledIndices = [];
  AccentLoaded? _lastLoadedState;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(
        gameType: entities.GameSubtype.intonationMimic,
        level: widget.level,
      ),
    );
  }

  void _shuffleOptions(int optionCount) {
    _shuffledIndices = List.generate(optionCount, (i) => i)..shuffle(Random());
  }

  void _playAudio(String text) async {
    if (_isPlaying || _listensRemaining <= 0) return;
    setState(() {
      _isPlaying = true;
      _listensRemaining--;
    });
    _hapticService.light();

    if (_slowMode) {
      await _speechService.speak(text, rate: 0.3);
    } else {
      await _speechService.speak(text);
    }
    if (mounted) setState(() => _isPlaying = false);
  }

  void _onOptionSelected(int originalIndex, AccentQuest quest) {
    if (_hasAnswered) return;
    _hapticService.selection();

    final isCorrect = originalIndex == quest.correctAnswerIndex;

    setState(() {
      _selectedOptionIndex = originalIndex;
      _hasAnswered = true;
      _isCorrectAnswer = isCorrect;
    });

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
    } else {
      _hapticService.error();
      _soundService.playWrong();
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _showFeedback = true);
      }
    });

    context.read<AccentBloc>().add(SubmitAnswer(isCorrect));
  }

  void _nextQuestion() {
    context.read<AccentBloc>().add(NextQuestion());
  }

  void _useHint(AccentLoaded state, AccentQuest quest) {
    if (state.hintUsed || _hasAnswered) {
      _hapticService.error();
      return;
    }
    _hapticService.selection();
    _soundService.playHint();

    if (quest.hint != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '💡 ${quest.hint}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    context.read<AccentBloc>().add(AccentHintUsed());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF020617)
          : const Color(0xFFF8FAFC),
      body: BlocConsumer<AccentBloc, AccentState>(
        listener: (context, state) {
          if (state is AccentGameComplete) {
            setState(() => _showConfetti = true);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VictoryScreen(
                  xp: state.xpEarned,
                  coins: state.coinsEarned,
                  category: 'accent',
                  gameType: 'intonationMimic',
                  level: widget.level,
                  title: 'SOUND MASTER!',
                  description:
                      'Your mastery of pronunciation is reaching new heights! Keep up the great work.',
                ),
              ),
            );
          } else if (state is AccentGameOver) {
            GameDialogHelper.showGameOver(
              context,
              title: 'Keep Practicing!',
              description:
                  'Sound awareness takes time. Try again to train your ear!',
              onRestore: () => context.read<AccentBloc>().add(RestoreLife()),
            );
          } else if (state is AccentLoaded) {
            // Verification: Only process if state matches current game and level
            if (state.gameType == entities.GameSubtype.intonationMimic &&
                state.level == widget.level) {
              _lastLoadedState = state;
              if (state.lastAnswerCorrect == null) {
                setState(() {
                  _selectedOptionIndex = null;
                  _hasAnswered = false;
                  _showFeedback = false;
                  _isCorrectAnswer = false;
                  _listensRemaining = 3;
                  _slowMode = false;
                });
                _shuffleOptions(state.currentQuest.options?.length ?? 2);
              }
            }
          }
        },
        builder: (context, state) {
          final bool isStale =
              state is AccentLoaded &&
              (state.gameType != entities.GameSubtype.intonationMimic ||
                  state.level != widget.level);

          if (state is AccentLoading ||
              (state is AccentInitial && _lastLoadedState == null) ||
              isStale) {
            return const GameShimmerLoading();
          }

          if (state is AccentError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<AccentBloc>().add(
                FetchAccentQuests(
                  gameType: entities.GameSubtype.intonationMimic,
                  level: widget.level,
                ),
              ),
            );
          }

          if (state is AccentLoaded || state is AccentGameComplete) {
            final displayState = state is AccentLoaded
                ? state
                : (state as AccentGameComplete).lastState;
            final theme = LevelThemeHelper.getTheme(
              'accent',
              level: widget.level,
              isDark: isDark,
            );
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                HarmonicWaves(color: theme.primaryColor, height: 100),
                _buildGameUI(context, displayState, isDark, theme),
                if (_showConfetti) const GameConfetti(),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGameUI(
    BuildContext context,
    AccentLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final quest = state.currentQuest;
    final progress = (state.currentIndex + 1) / state.quests.length;
    final word = (quest.word ?? '').toUpperCase();
    final ipa = _ipaMap[word];
    final tip = _pronunciationTips[word];
    final options = quest.options ?? [];
    final awarenessPrompt = _getAwarenessPrompt(options);

    if (_shuffledIndices.isEmpty && options.isNotEmpty) {
      _shuffleOptions(options.length);
    }

    return SafeArea(
      child: Column(
        children: [
          ImTopBar(
            progress: progress,
            livesRemaining: state.livesRemaining,
            hintUsed: state.hintUsed,
            hasAnswered: _hasAnswered,
            primaryColor: theme.primaryColor,
            quest: quest,
            onHintTap: () => _useHint(state, quest),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  Animate(
                    effects: const [FadeEffect()],
                    child: Text(
                      "SOUND AWARENESS",
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ImSoundCard(
                    word: word,
                    ipa: ipa,
                    tip: tip,
                    theme: theme,
                    isPlaying: _isPlaying,
                    listensRemaining: _listensRemaining,
                    slowMode: _slowMode,
                    hasAnswered: _hasAnswered,
                    isCorrectAnswer: _isCorrectAnswer,
                    onPlayAudio: () => _playAudio(quest.word ?? ''),
                    onSlowModeToggle: () =>
                        setState(() => _slowMode = !_slowMode),
                  ),
                  SizedBox(height: 28.h),
                  if (!_hasAnswered)
                    ImAwarenessSection(prompt: awarenessPrompt, theme: theme),
                  if (!_hasAnswered) SizedBox(height: 28.h),
                  if (!_hasAnswered)
                    Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: Text(
                        "CHOOSE YOUR ANSWER",
                        style: GoogleFonts.outfit(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ),
                  ...List.generate(_shuffledIndices.length, (displayIdx) {
                    final originalIdx = _shuffledIndices[displayIdx];
                    if (originalIdx >= options.length) {
                      return const SizedBox.shrink();
                    }
                    final option = options[originalIdx];
                    return ImOptionButton(
                      option: option,
                      isSelected: _selectedOptionIndex == originalIdx,
                      isCorrect: originalIdx == quest.correctAnswerIndex,
                      showResult: _hasAnswered,
                      theme: theme,
                      onTap: () => _onOptionSelected(originalIdx, quest),
                    );
                  }),
                  if (_showFeedback)
                    ImFeedbackCard(
                      quest: quest,
                      word: word,
                      ipa: ipa,
                      tip: tip,
                      theme: theme,
                      isCorrect: _isCorrectAnswer,
                    ),
                  if (_showFeedback) ...[
                    SizedBox(height: 24.h),
                    ScaleButton(
                      onTap: _nextQuestion,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor,
                              theme.primaryColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "CONTINUE",
                            style: GoogleFonts.outfit(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
