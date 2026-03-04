import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:voxai_quest/core/domain/entities/game_quest.dart';
import 'package:voxai_quest/core/presentation/pages/quest_unavailable_screen.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/accent/harmonic_waves.dart';
import 'package:voxai_quest/core/presentation/widgets/game_confetti.dart';
import 'package:voxai_quest/core/presentation/widgets/game_dialog_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/presentation/widgets/games/victory_screen.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/features/accent/domain/entities/accent_quest.dart';
import 'package:voxai_quest/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:voxai_quest/features/accent/minimal_pairs/presentation/widgets/mp_top_bar.dart';
import 'package:voxai_quest/features/accent/minimal_pairs/presentation/widgets/mp_listen_button.dart';
import 'package:voxai_quest/features/accent/minimal_pairs/presentation/widgets/mp_word_card.dart';
import 'package:voxai_quest/features/accent/minimal_pairs/presentation/widgets/mp_game_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  MinimalPairsScreen — Premium Accent Training UI
// ═══════════════════════════════════════════════════════════════════════════

class MinimalPairsScreen extends StatefulWidget {
  final int level;
  const MinimalPairsScreen({super.key, required this.level});

  @override
  State<MinimalPairsScreen> createState() => _MinimalPairsScreenState();
}

class _MinimalPairsScreenState extends State<MinimalPairsScreen>
    with SingleTickerProviderStateMixin {
  // ── Services ──
  final _haptic = di.sl<HapticService>();
  final _sound = di.sl<SoundService>();
  final _tts = di.sl<SpeechService>();

  // ── Game state ──
  int? _selectedIndex;
  final List<int> _eliminated = [];
  List<String> _shuffledWords = [];
  bool _isPlaying = false;
  bool _showConfetti = false;
  bool _showFeedback = false;
  bool _showRepeat = false;
  bool _lastWasCorrect = false;
  final _random = Random();

  // ── Controllers ──
  late final AnimationController _pulse;
  AccentLoaded? _lastState;

  // ── Constants ──
  static const _darkBg = Color(0xFF020617);
  static const _lightBg = Color(0xFFF8FAFC);
  static final _phonemeRegex = RegExp(r'/[^/]+/');
  static final _subTextStyle = GoogleFonts.outfit(
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
  );
  static final _questionStyle = GoogleFonts.outfit(fontWeight: FontWeight.w600);

  // ═══════════════════════════════════════════════════════════════════════
  //  Lifecycle
  // ═══════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    context.read<AccentBloc>().add(
      FetchAccentQuests(
        gameType: GameSubtype.minimalPairs,
        level: widget.level,
      ),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Helpers
  // ═══════════════════════════════════════════════════════════════════════

  String _extractPhoneme(String? question) {
    if (question == null) return '';
    final matches = _phonemeRegex.allMatches(question);
    if (matches.isEmpty) return '';
    return matches.map((m) => m.group(0)!).join(' vs ');
  }

  String _resolveCorrectWord(AccentQuest quest) {
    return quest.options?[quest.correctAnswerIndex ?? 0] ??
        quest.word ??
        quest.textToSpeak ??
        'Word';
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Actions
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _playAudio(String text) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _haptic.light();
    await _tts.speak(text);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _onWordSelected(int index, String tappedWord) {
    if (_selectedIndex != null || _eliminated.contains(index)) return;

    final state = context.read<AccentBloc>().state;
    if (state is! AccentLoaded) return;

    final correct = _resolveCorrectWord(state.currentQuest);
    final isCorrect =
        correct.trim().toLowerCase() == tappedWord.trim().toLowerCase();

    setState(() {
      _selectedIndex = index;
      _lastWasCorrect = isCorrect;
      _showFeedback = true;
      _showRepeat = false;
    });

    context.read<AccentBloc>().add(SubmitAnswer(isCorrect));

    if (isCorrect) {
      _sound.playCorrect();
      _haptic.success();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _showRepeat = true);
      });
      final bloc = context.read<AccentBloc>();
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        _resetRound();
        bloc.add(NextQuestion());
      });
    } else {
      _sound.playWrong();
      _haptic.error();
    }
  }

  void _resetRound() {
    setState(() {
      _eliminated.clear();
      _selectedIndex = null;
      _showFeedback = false;
      _showRepeat = false;
      _shuffledWords = []; // Force re-shuffle for next question
    });
  }

  /// Shuffles word positions so correct answer isn't always on the left.
  void _shuffleOptions(List<String> words) {
    _shuffledWords = List<String>.from(words);
    // Fisher-Yates shuffle
    for (int i = _shuffledWords.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = _shuffledWords[i];
      _shuffledWords[i] = _shuffledWords[j];
      _shuffledWords[j] = tmp;
    }
  }

  void _useHint(AccentLoaded state, List<String> words, String target) {
    if (state.hintUsed) {
      _haptic.error();
      return;
    }
    _haptic.selection();
    _sound.playHint();

    final t = target.trim().toLowerCase();
    setState(() {
      for (int i = 0; i < words.length; i++) {
        if (words[i].trim().toLowerCase() != t && !_eliminated.contains(i)) {
          _eliminated.add(i);
        }
      }
    });
    context.read<AccentBloc>().add(AccentHintUsed());
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  BLoC Listener
  // ═══════════════════════════════════════════════════════════════════════

  void _onBlocState(BuildContext context, AccentState state) {
    if (state is AccentGameComplete) {
      setState(() => _showConfetti = true);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VictoryScreen(
            xp: state.xpEarned,
            coins: state.coinsEarned,
            category: 'accent',
            gameType: 'minimalPairs',
            level: widget.level,
            title: 'PHONETIC PRO!',
            description:
                'Your sharp ears distinguished those tricky sounds perfectly!',
          ),
        ),
      );
    } else if (state is AccentGameOver) {
      GameDialogHelper.showGameOver(
        context,
        title: 'Frequency Lost',
        description: 'Your listening skills need a quick recharge. Try again!',
        onRestore: () => context.read<AccentBloc>().add(RestoreLife()),
      );
    } else if (state is AccentLoaded) {
      // Verification: Only process if state matches current game and level
      if (state.gameType == GameSubtype.minimalPairs &&
          state.level == widget.level) {
        if (_lastState?.currentQuest != state.currentQuest) {
          _resetRound();
          final words =
              state.currentQuest.options ??
              [_resolveCorrectWord(state.currentQuest), 'Alternative'];
          _shuffleOptions(words);
        }
        _lastState = state;
        if (state.lastAnswerCorrect == false) {
          final bloc = context.read<AccentBloc>();
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (!mounted || state.livesRemaining <= 0) return;
            _resetRound();
            bloc.add(RestoreLife());
          });
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Build
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      'accent',
      level: widget.level,
      isDark: isDark,
    );

    return Scaffold(
      backgroundColor: isDark ? _darkBg : _lightBg,
      body: BlocConsumer<AccentBloc, AccentState>(
        listener: _onBlocState,
        builder: (context, state) {
          final bool isStale =
              state is AccentLoaded &&
              (state.gameType != GameSubtype.minimalPairs ||
                  state.level != widget.level);

          if (state is AccentLoading ||
              (state is AccentInitial && _lastState == null) ||
              isStale) {
            return const GameShimmerLoading();
          }
          if (state is AccentError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<AccentBloc>().add(
                FetchAccentQuests(
                  gameType: GameSubtype.minimalPairs,
                  level: widget.level,
                ),
              ),
            );
          }

          if (state is AccentLoaded || state is AccentGameComplete) {
            final display = state is AccentLoaded
                ? state
                : (state as AccentGameComplete).lastState;

            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                HarmonicWaves(color: theme.primaryColor, height: 100),
                _buildGameUI(display, isDark, theme),
                if (_showConfetti) const GameConfetti(),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Game UI — Composes extracted widgets
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildGameUI(AccentLoaded state, bool isDark, ThemeResult theme) {
    final quest = state.currentQuest;
    final progress = (state.currentIndex + 1) / state.quests.length;
    final correct = _resolveCorrectWord(quest);
    final rawWords = quest.options ?? [correct, 'Alternative'];
    // Use shuffled words if available, otherwise shuffle now (first load)
    if (_shuffledWords.isEmpty) _shuffleOptions(rawWords);
    final words = _shuffledWords;
    final phoneme = _extractPhoneme(quest.question);

    return Column(
      children: [
        MpTopBar(
          isDark: isDark,
          theme: theme,
          progress: progress,
          state: state,
          words: words,
          correctWord: correct,
          onClose: () => context.pop(),
          onHint: _useHint,
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  MpFocusBadge(
                    phoneme: phoneme,
                    isDark: isDark,
                    primaryColor: theme.primaryColor,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    quest.question ?? quest.instruction,
                    textAlign: TextAlign.center,
                    style: _questionStyle.copyWith(
                      fontSize: 20.sp,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 28.h),
                  MpListenButton(
                    isPlaying: _isPlaying,
                    pulseController: _pulse,
                    onTap: () => _playAudio(correct),
                  ),
                  SizedBox(height: 28.h),
                  Row(
                    children: [
                      Expanded(
                        child: MpWordCard(
                          word: words[0],
                          index: 0,
                          correctWord: correct,
                          selectedIndex: _selectedIndex,
                          eliminated: _eliminated,
                          isDark: isDark,
                          theme: theme,
                          onTap: _onWordSelected,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: MpWordCard(
                          word: words[1],
                          index: 1,
                          correctWord: correct,
                          selectedIndex: _selectedIndex,
                          eliminated: _eliminated,
                          isDark: isDark,
                          theme: theme,
                          onTap: _onWordSelected,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Train your ear.',
                    style: _subTextStyle.copyWith(
                      fontSize: 13.sp,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  if (_showFeedback)
                    MpFeedbackPanel(
                      isCorrect: _lastWasCorrect,
                      hint: quest.hint ?? '',
                      isDark: isDark,
                    ),
                  if (_showRepeat)
                    MpRepeatButton(onTap: () => _playAudio(correct)),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
