import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/domain/entities/game_quest.dart';
import 'package:voxai_quest/core/presentation/pages/quest_unavailable_screen.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/accent/harmonic_waves.dart';
import 'package:voxai_quest/core/presentation/widgets/game_confetti.dart';
import 'package:voxai_quest/core/presentation/widgets/glass_tile.dart';
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:voxai_quest/core/presentation/widgets/game_dialog_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/games/victory_screen.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/features/accent/domain/entities/accent_quest.dart';
import 'package:voxai_quest/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:voxai_quest/core/presentation/widgets/games/premium_game_widgets.dart';
import 'package:voxai_quest/features/accent/dialect_drill/presentation/widgets/dialect_feedback_panel.dart';

class DialectDrillScreen extends StatefulWidget {
  final int level;
  const DialectDrillScreen({super.key, required this.level});

  @override
  State<DialectDrillScreen> createState() => _DialectDrillScreenState();
}

class _DialectDrillScreenState extends State<DialectDrillScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _ttsService = di.sl<SpeechService>();
  bool _isPlaying = false;
  bool _showConfetti = false;

  bool _hasSubmitted = false;
  int? _selectedOptionIndex;
  final Set<int> _eliminatedIndices = {};
  AccentLoaded? _lastLoadedState;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(
        gameType: GameSubtype.dialectDrill,
        level: widget.level,
      ),
    );
  }

  void _playAudio(String text, {String locale = "en-US"}) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _hapticService.light();

    await _ttsService.speak(text, rate: 0.5, locale: locale);

    if (mounted) setState(() => _isPlaying = false);
  }

  void _checkAnswer(int index, AccentQuest quest) {
    if (_hasSubmitted || _eliminatedIndices.contains(index)) return;

    setState(() {
      _selectedOptionIndex = index;
    });

    bool isCorrect = false;
    if (quest.correctAnswerIndex != null) {
      isCorrect = (index == quest.correctAnswerIndex);
    } else if (quest.correctAnswer != null && quest.options != null) {
      isCorrect = (quest.options![index] == quest.correctAnswer);
    } else {
      isCorrect = (index == 0); // Fallback
    }

    if (isCorrect) {
      setState(() => _hasSubmitted = true);
      _hapticService.success();
      _soundService.playCorrect();
      context.read<AccentBloc>().add(SubmitAnswer(true));

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) context.read<AccentBloc>().add(NextQuestion());
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() => _hasSubmitted = false);
      context.read<AccentBloc>().add(SubmitAnswer(false));
      // Reset selection highlight after a brief visual flash
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _selectedOptionIndex = null);
      });
    }
  }

  void _useHint(AccentLoaded state, AccentQuest quest) {
    if (state.hintUsed) {
      _hapticService.error();
      return;
    }
    _hapticService.selection();
    _soundService.playHint();

    final options = quest.options ?? ['American', 'British', 'Australian'];

    int? wrongOriginalIndex;
    for (int i = 0; i < options.length; i++) {
      bool isMatch = false;
      if (quest.correctAnswerIndex != null) {
        isMatch = (i == quest.correctAnswerIndex);
      } else if (quest.correctAnswer != null) {
        isMatch = (options[i] == quest.correctAnswer);
      } else {
        isMatch = (i == 0);
      }

      if (!isMatch && !_eliminatedIndices.contains(i)) {
        wrongOriginalIndex = i;
        break;
      }
    }

    if (wrongOriginalIndex != null) {
      setState(() => _eliminatedIndices.add(wrongOriginalIndex!));
    }
    context.read<AccentBloc>().add(AccentHintUsed());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      'accent',
      level: widget.level,
      isDark: isDark,
    );

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
                  gameType: 'dialectDrill',
                  level: widget.level,
                  title: 'GLOBAL SPEAKER!',
                  description:
                      'You mastered the regional dialects! Your pronunciation is world-class.',
                ),
              ),
            );
          } else if (state is AccentGameOver) {
            GameDialogHelper.showGameOver(
              context,
              title: 'Region Lost',
              description:
                  'The dialect was too foreign. Try to blend in again!',
              onRestore: () => context.read<AccentBloc>().add(RestoreLife()),
            );
          } else if (state is AccentLoaded) {
            // Verification: Only process if state matches current game and level
            if (state.gameType == GameSubtype.dialectDrill &&
                state.level == widget.level) {
              if (_lastLoadedState?.currentQuest != state.currentQuest) {
                _lastLoadedState = state;
                if (state.lastAnswerCorrect == null) {
                  setState(() {
                    _hasSubmitted = false;
                    _selectedOptionIndex = null;
                    _eliminatedIndices.clear();
                  });
                }
              }
            }
          }
        },
        builder: (context, state) {
          final bool isStale =
              state is AccentLoaded &&
              (state.gameType != GameSubtype.dialectDrill ||
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
                  gameType: GameSubtype.dialectDrill,
                  level: widget.level,
                ),
              ),
            );
          }

          if (state is AccentLoaded || state is AccentGameComplete) {
            final displayState = state is AccentLoaded
                ? state
                : (state as AccentGameComplete).lastState;
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                RepaintBoundary(
                  child: HarmonicWaves(color: theme.primaryColor, height: 100),
                ),
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

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              PremiumGameHeader(
                progress: progress,
                lives: state.livesRemaining,
                hintCount: state.hintUsed ? null : 1,
                onHint: () => _useHint(state, quest),
                onClose: () => context.pop(),
                isDark: isDark,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      Text(
                        "DIALECT DRILL",
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: theme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Which pronunciation?",
                        style: GoogleFonts.outfit(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                      if (quest.instruction.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Text(
                          quest.instruction,
                          style: GoogleFonts.outfit(
                            fontSize: 16.sp,
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      SizedBox(height: 40.h),

                      // Dialect Card
                      GlassTile(
                        padding: EdgeInsets.all(40.r),
                        borderRadius: BorderRadius.circular(40.r),
                        borderColor: theme.primaryColor.withValues(alpha: 0.3),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                "REGIONAL",
                                style: GoogleFonts.outfit(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: theme.primaryColor,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            SizedBox(height: 24.h),
                            // Standard Playback Button
                            ScaleButton(
                              onTap: () => _playAudio(quest.word ?? ""),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.w,
                                  vertical: 12.h,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.primaryColor.withValues(alpha: 0.9),
                                      theme.primaryColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isPlaying)
                                      const HarmonicWaves(
                                        color: Colors.white,
                                        height: 30,
                                        width: 40,
                                      ).animate().fadeIn()
                                    else
                                      Icon(
                                        Icons.volume_up_rounded,
                                        color: Colors.white,
                                        size: 24.r,
                                      ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      "LISTEN",
                                      style: GoogleFonts.outfit(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 24.h),
                            Text(
                              quest.word ?? "Tomato",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (quest.phonetic != null) ...[
                              SizedBox(height: 12.h),
                              Text(
                                "/ ${quest.phonetic} /",
                                style: GoogleFonts.outfit(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).scale(),

                      SizedBox(height: 48.h),

                      // Region Options
                      _buildRegionOptions(quest, isDark, theme),

                      if (_hasSubmitted && state.lastAnswerCorrect != null) ...[
                        SizedBox(height: 48.h),
                        DialectFeedbackPanel(
                          isCorrect: state.lastAnswerCorrect!,
                          word: quest.word ?? "Word",
                          britishPronunciation: _getOptionString(
                            quest.options,
                            "British",
                          ),
                          americanPronunciation: _getOptionString(
                            quest.options,
                            "American",
                          ),
                          hint: quest.hint ?? "Notice the accent variations.",
                          onPlayAudio: (text, locale) =>
                              _playAudio(text, locale: locale),
                          isDark: isDark,
                        ),
                      ],

                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showConfetti) const GameConfetti(),
        ],
      ),
    );
  }

  String _getOptionString(List<String>? options, String query) {
    if (options == null) return "Unknown";
    for (final opt in options) {
      if (opt.toLowerCase().contains(query.toLowerCase())) {
        return opt
            .replaceAll(RegExp(r'\(([^)]+)\)'), '')
            .trim(); // Remove the "(British)" text
      }
    }
    return options.first.replaceAll(RegExp(r'\(([^)]+)\)'), '').trim();
  }

  String _extractParenthesesText(String text) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(text);
    return match != null ? match.group(1) ?? 'Dialect' : 'Dialect';
  }

  Widget _buildRegionOptions(
    AccentQuest quest,
    bool isDark,
    ThemeResult theme,
  ) {
    final options = quest.options ?? ['American', 'British'];

    return Column(
      children: List.generate(options.length, (index) {
        final option = options[index];
        final isSelected = _selectedOptionIndex == index;

        bool isCorrect = false;
        if (_hasSubmitted) {
          if (quest.correctAnswerIndex != null) {
            isCorrect = index == quest.correctAnswerIndex;
          } else if (quest.correctAnswer != null) {
            isCorrect = options[index] == quest.correctAnswer;
          } else {
            isCorrect = index == 0;
          }
        }

        final isEliminated = _eliminatedIndices.contains(index);

        final bgColor = isEliminated
            ? (isDark ? Colors.white12 : Colors.black12)
            : _hasSubmitted
            ? (isCorrect
                  ? Colors.greenAccent
                  : (isSelected
                        ? Colors.redAccent
                        : (isDark ? Colors.white12 : Colors.black12)))
            : theme.primaryColor;

        String flagEmoji = '🌍';
        if (option.toLowerCase().contains('us') ||
            option.toLowerCase().contains('american') ||
            option.toLowerCase().contains('united states')) {
          flagEmoji = '🇺🇸';
        } else if (option.toLowerCase().contains('uk') ||
            option.toLowerCase().contains('british') ||
            option.toLowerCase().contains('britain')) {
          flagEmoji = '🇬🇧';
        } else if (option.toLowerCase().contains('aus') ||
            option.toLowerCase().contains('australian')) {
          flagEmoji = '🇦🇺';
        }

        final pronunciationText = option
            .replaceAll(RegExp(r'\([^)]*\)'), '')
            .trim();
        final dialectText = _extractParenthesesText(option);

        return Padding(
          padding: EdgeInsets.only(bottom: 24.h),
          child: ScaleButton(
            onTap: () => _checkAnswer(index, quest),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
              decoration: BoxDecoration(
                color: isEliminated
                    ? Colors.transparent
                    : isSelected
                    ? bgColor.withValues(alpha: 0.15)
                    : bgColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(
                  color: isEliminated
                      ? Colors.transparent
                      : isSelected || (isCorrect && _hasSubmitted)
                      ? bgColor
                      : bgColor.withValues(alpha: 0.3),
                  width: isSelected || (isCorrect && _hasSubmitted) ? 3 : 2,
                ),
                boxShadow: [
                  if (isSelected || (isCorrect && _hasSubmitted))
                    BoxShadow(
                      color: bgColor.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: isEliminated
                          ? Colors.transparent
                          : bgColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: ColorFiltered(
                      colorFilter: isEliminated
                          ? const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            )
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            ),
                      child: Text(flagEmoji, style: TextStyle(fontSize: 40.sp)),
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pronunciationText,
                          style: GoogleFonts.outfit(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: isEliminated
                                ? (isDark ? Colors.white24 : Colors.black26)
                                : (isSelected ||
                                          (isCorrect && _hasSubmitted)) &&
                                      isDark
                                ? Colors.white
                                : (isSelected ||
                                          (isCorrect && _hasSubmitted)) &&
                                      !isDark
                                ? Colors.black87
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          dialectText.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: isEliminated
                                ? (isDark ? Colors.white12 : Colors.black12)
                                : theme.primaryColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasSubmitted && isCorrect) ...[
                    SizedBox(width: 12.w),
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.greenAccent,
                      size: 32.r,
                    ).animate().scale().shake(),
                  ],
                  if (isSelected && !isCorrect) ...[
                    SizedBox(width: 12.w),
                    Icon(
                      Icons.cancel_rounded,
                      color: Colors.redAccent,
                      size: 32.r,
                    ).animate().scale().shake(),
                  ],
                ],
              ),
            ),
          ).animate(delay: (200 + index * 100).ms).slideY(begin: 0.2).fadeIn(),
        );
      }),
    );
  }
}
