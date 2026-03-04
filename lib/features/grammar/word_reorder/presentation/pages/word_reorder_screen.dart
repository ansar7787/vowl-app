import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voxai_quest/core/domain/entities/game_quest.dart';
import 'package:voxai_quest/core/presentation/pages/quest_unavailable_screen.dart';
import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/game_confetti.dart';
import 'package:voxai_quest/core/presentation/widgets/glass_tile.dart';
import 'package:voxai_quest/core/presentation/widgets/grammar/logic_circuit.dart';
import 'package:voxai_quest/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:voxai_quest/core/presentation/widgets/game_dialog_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/modern_game_result_overlay.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/features/grammar/presentation/bloc/grammar_bloc.dart';

class WordReorderScreen extends StatefulWidget {
  final int level;
  const WordReorderScreen({super.key, required this.level});

  @override
  State<WordReorderScreen> createState() => _WordReorderScreenState();
}

class _WordReorderScreenState extends State<WordReorderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final List<String> _selectedWords = [];
  List<String> _availableWords = [];
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(
        gameType: GameSubtype.wordReorder,
        level: widget.level,
      ),
    );
  }

  void _onWordTap(String word, bool isAvailable) {
    _hapticService.selection();
    setState(() {
      if (isAvailable) {
        _availableWords.remove(word);
        _selectedWords.add(word);
      } else {
        _selectedWords.remove(word);
        _availableWords.add(word);
      }
    });

    if (_availableWords.isEmpty) {
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    final state = context.read<GrammarBloc>().state;
    if (state is GrammarLoaded) {
      final userAnswer = _selectedWords.join(' ').toLowerCase();
      final correctAnswer = (state.currentQuest.correctSentence ?? "")
          .toLowerCase();

      final isCorrect = userAnswer == correctAnswer;

      if (isCorrect) {
        _soundService.playCorrect();
        _hapticService.success();
      } else {
        _soundService.playWrong();
        _hapticService.error();
      }
      context.read<GrammarBloc>().add(SubmitAnswer(isCorrect));
    }
  }

  void _useHint() {
    _hapticService.selection();
    context.read<GrammarBloc>().add(GrammarHintUsed());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: BlocConsumer<GrammarBloc, GrammarState>(
        listener: (context, state) {
          if (state is GrammarGameComplete) {
            final xp = state.xpEarned;
            final coins = state.coinsEarned;
            setState(() => _showConfetti = true);
            final isPremium =
                context.read<AuthBloc>().state.user?.isPremium ?? false;
            di.sl<AdService>().showInterstitialAd(
              isPremium: isPremium,
              onDismissed: () => GameDialogHelper.showCompletion(
                context,
                xp: xp,
                coins: coins,
                title: 'Word Order Master!',
                description: 'You earned $xp XP and $coins Coins!',
                enableDoubleUp: true,
              ),
            );
          } else if (state is GrammarGameOver) {
            GameDialogHelper.showGameOver(
              context,
              title: 'Syntax Faded',
              description: 'Practice more to master these word orders!',
              onRestore: () => context.read<GrammarBloc>().add(RestoreLife()),
            );
          } else if (state is GrammarLoaded) {
            if (state.lastAnswerCorrect == null) {
              _selectedWords.clear();
              _availableWords = List.from(state.currentQuest.options ?? []);
              _availableWords.shuffle();
            }
          }
        },
        builder: (context, state) {
          if (state is GrammarLoading || state is GrammarInitial) {
            return const GameShimmerLoading();
          }
          if (state is GrammarLoaded) {
            final theme = LevelThemeHelper.getTheme(
              'grammar',
              level: widget.level,
              isDark: isDark,
            );
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                LogicCircuit(color: theme.primaryColor),
                _buildGameUI(context, state, isDark, theme),
              ],
            );
          }
          if (state is GrammarError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<GrammarBloc>().add(
                FetchGrammarQuests(
                  gameType: GameSubtype.wordReorder,
                  level: widget.level,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGameUI(
    BuildContext context,
    GrammarLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final quest = state.currentQuest;
    final progress = (state.currentIndex + 1) / state.quests.length;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 10.h),
              child: Row(
                children: [
                  ScaleButton(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black12,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 24.r,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 14.h,
                        backgroundColor: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  _buildHintButton(state.hintUsed, theme.primaryColor),
                  SizedBox(width: 12.w),
                  _buildHeartCount(state.livesRemaining),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    Text(
                      theme.title,
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: theme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 30.h),
                    Text(
                      quest.instruction,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 40.h),

                    GlassTile(
                      width: double.infinity,
                      height: _selectedWords.isEmpty ? 140.h : null,
                      padding: EdgeInsets.all(24.r),
                      borderRadius: BorderRadius.circular(32.r),
                      borderColor: state.lastAnswerCorrect == false
                          ? const Color(0xFFF43F5E)
                          : theme.primaryColor.withValues(alpha: 0.3),
                      color: isDark
                          ? theme.primaryColor.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.5),
                      child: Stack(
                        children: [
                          if (_selectedWords.isEmpty)
                            Center(
                              child: Text(
                                "DRAG WORDS HERE",
                                style: GoogleFonts.outfit(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          Wrap(
                            spacing: 12.w,
                            runSpacing: 12.h,
                            children: _selectedWords
                                .map(
                                  (word) => _buildWordChip(
                                    word,
                                    false,
                                    isDark,
                                    theme,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

                    SizedBox(height: 40.h),

                    // Available Words Area
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 12.h,
                      alignment: WrapAlignment.center,
                      children: _availableWords
                          .map(
                            (word) => _buildWordChip(word, true, isDark, theme),
                          )
                          .toList(),
                    ),

                    const Spacer(),
                    SizedBox(height: 60.h),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (state.lastAnswerCorrect != null)
          ModernGameResultOverlay(
            isCorrect: state.lastAnswerCorrect!,
            title: state.lastAnswerCorrect!
                ? "SYNTAX SUPREME!"
                : "CHECK THE ORDER!",
            subtitle: "Correct: ${quest.correctSentence ?? ""}",
            onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
            primaryColor: theme.primaryColor,
          ),
        if (_showConfetti) const GameConfetti(),
      ],
    );
  }

  Widget _buildWordChip(
    String word,
    bool isAvailable,
    bool isDark,
    ThemeResult theme,
  ) {
    return ScaleButton(
      onTap: () => _onWordTap(word, isAvailable),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isAvailable
              ? (isDark
                    ? theme.primaryColor.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.8))
              : theme.primaryColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isAvailable
                ? theme.primaryColor.withValues(alpha: 0.4)
                : Colors.white24,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isAvailable ? theme.primaryColor : Colors.black)
                  .withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          word,
          style: GoogleFonts.outfit(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: isAvailable
                ? (isDark ? Colors.white : theme.primaryColor)
                : Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ).animate().scale(duration: 200.ms),
    );
  }

  Widget _buildHeartCount(int lives) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 20.r),
          SizedBox(width: 6.w),
          Text(
            "$lives",
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: Colors.pinkAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintButton(bool used, Color primaryColor) {
    return ScaleButton(
      onTap: used ? null : _useHint,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: used
              ? Colors.grey.withValues(alpha: 0.1)
              : primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: used
                ? Colors.grey.withValues(alpha: 0.3)
                : primaryColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              used ? Icons.lightbulb_outline_rounded : Icons.lightbulb_rounded,
              color: used ? Colors.grey : primaryColor,
              size: 20.r,
            ),
            SizedBox(width: 6.w),
            Text(
              "HINT",
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: used ? Colors.grey : primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
