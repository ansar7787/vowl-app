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

class SentenceCorrectionScreen extends StatefulWidget {
  final int level;
  const SentenceCorrectionScreen({super.key, required this.level});

  @override
  State<SentenceCorrectionScreen> createState() =>
      _SentenceCorrectionScreenState();
}

class _SentenceCorrectionScreenState extends State<SentenceCorrectionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  int? _selectedOptionIndex;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(
        gameType: GameSubtype.sentenceCorrection,
        level: widget.level,
      ),
    );
  }

  void _onOptionSelected(int index) {
    if (_selectedOptionIndex != null) return;
    _hapticService.selection();
    setState(() => _selectedOptionIndex = index);

    final state = context.read<GrammarBloc>().state;
    if (state is GrammarLoaded) {
      final isCorrect = index == (state.currentQuest.correctAnswerIndex ?? 0);
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
                title: 'Syntax Repaired!',
                description: 'You earned $xp XP and $coins Coins!',
                enableDoubleUp: true,
              ),
            );
          } else if (state is GrammarGameOver) {
            GameDialogHelper.showGameOver(
              context,
              title: 'Grammar Depleted',
              description: 'Practice more to master these structures!',
              onRestore: () => context.read<GrammarBloc>().add(RestoreLife()),
            );
          } else if (state is GrammarLoaded &&
              state.lastAnswerCorrect == null) {
            _selectedOptionIndex = null;
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
                  gameType: GameSubtype.sentenceCorrection,
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
              child: SingleChildScrollView(
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
                    GlassTile(
                      padding: EdgeInsets.all(32.r),
                      borderRadius: BorderRadius.circular(32.r),
                      borderColor: const Color(
                        0xFFF43F5E,
                      ).withValues(alpha: 0.3),
                      color: isDark
                          ? const Color(0xFFF43F5E).withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.5),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF43F5E,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: const Color(
                                  0xFFF43F5E,
                                ).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              "FAULT DETECTED",
                              style: GoogleFonts.outfit(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: const Color(0xFFF43F5E),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            quest.question ??
                                "Find the error in this sentence...",
                            style: GoogleFonts.outfit(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                              height: 1.5,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
                    SizedBox(height: 40.h),
                    Text(
                      quest.instruction,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    SizedBox(height: 30.h),
                    ...List.generate(quest.options?.length ?? 0, (index) {
                      final isCorrect = index == quest.correctAnswerIndex;
                      final isSelected = _selectedOptionIndex == index;
                      return _buildOptionCard(
                        text: quest.options![index],
                        index: index,
                        isSelected: isSelected,
                        isCorrect: isCorrect,
                        showResult: _selectedOptionIndex != null,
                        isDark: isDark,
                        theme: theme,
                      );
                    }),
                    SizedBox(height: 40.h),
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
                ? "GRAMMAR GENIUS!"
                : "KEEP LEARNING!",
            subtitle: quest.explanation ?? "Grammar tip: Watch your tense!",
            onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
            primaryColor: theme.primaryColor,
          ),
        if (_showConfetti) const GameConfetti(),
      ],
    );
  }

  Widget _buildOptionCard({
    required String text,
    required int index,
    required bool isSelected,
    required bool isCorrect,
    required bool showResult,
    required bool isDark,
    required ThemeResult theme,
  }) {
    Color? cardColor;
    if (showResult) {
      if (isCorrect) {
        cardColor = const Color(0xFF10B981);
      } else if (isSelected) {
        cardColor = const Color(0xFFF43F5E);
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: ScaleButton(
        onTap: () => _onOptionSelected(index),
        child: GlassTile(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          borderRadius: BorderRadius.circular(20.r),
          color: cardColor?.withValues(alpha: 0.8),
          borderColor: (isSelected && showResult
              ? Colors.white.withValues(alpha: 0.5)
              : (isSelected
                    ? theme.primaryColor
                    : theme.primaryColor.withValues(alpha: 0.1))),
          child: Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isSelected
                          ? Colors.white24
                          : theme.primaryColor.withValues(alpha: 0.1),
                      isSelected
                          ? Colors.white10
                          : theme.primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white24
                        : theme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : theme.primaryColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 18.w),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.outfit(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.black87),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (showResult && isCorrect)
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 24.r,
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
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
