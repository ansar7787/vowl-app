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
import 'package:voxai_quest/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

class AcademicWordScreen extends StatefulWidget {
  final int level;
  const AcademicWordScreen({super.key, required this.level});

  @override
  State<AcademicWordScreen> createState() => _AcademicWordScreenState();
}

class _AcademicWordScreenState extends State<AcademicWordScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  bool _showConfetti = false;
  int? _selectedOptionIndex;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(
        gameType: GameSubtype.academicWord,
        level: widget.level,
      ),
    );
  }

  void _onOptionSelected(int index, bool isCorrect) {
    if (_selectedOptionIndex != null) return;
    setState(() => _selectedOptionIndex = index);

    _hapticService.selection();
    context.read<VocabularyBloc>().add(SubmitAnswer(isCorrect));
  }

  void _useHint() {
    _hapticService.selection();
    context.read<VocabularyBloc>().add(VocabularyHintUsed());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      'vocabulary',
      level: widget.level,
      isDark: isDark,
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: BlocConsumer<VocabularyBloc, VocabularyState>(
        listener: (context, state) {
          if (state is VocabularyGameComplete) {
            setState(() => _showConfetti = true);
            final isPremium =
                context.read<AuthBloc>().state.user?.isPremium ?? false;
            di.sl<AdService>().showInterstitialAd(
              isPremium: isPremium,
              onDismissed: () => GameDialogHelper.showCompletion(
          context,
          xp: state.xpEarned,
          coins: state.coinsEarned,
          title: 'Scholar Status!',
          description:
              'You earned ${state.xpEarned} XP and ${state.coinsEarned} Coins. Your academic vocabulary is growing!',
        ),
            );
          } else if (state is VocabularyGameOver) {
            GameDialogHelper.showGameOver(
        context,
        title: 'Try again!',
        description: 'Academic words can be complex. Keep practicing!',
      );
          } else if (state is VocabularyLoaded &&
              state.lastAnswerCorrect == null) {
            _selectedOptionIndex = null;
          }
        },
        builder: (context, state) {
          if (state is VocabularyLoading || state is VocabularyInitial) {
            return const GameShimmerLoading();
          }
          if (state is VocabularyLoaded) {
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                _buildGameUI(context, state, isDark, theme),
              ],
            );
          }
          if (state is VocabularyError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<VocabularyBloc>().add(
                FetchVocabularyQuests(
                  gameType: GameSubtype.academicWord,
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
    VocabularyLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final quest = state.currentQuest;
    final progress = (state.currentIndex + 1) / state.quests.length;

    return Column(
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
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "ACADEMIC VOCABULARY",
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: theme.primaryColor,
                    ),
                  ).animate().fadeIn().scale(),
                  SizedBox(height: 24.h),
                  GlassTile(
                    padding: EdgeInsets.all(32.r),
                    borderRadius: BorderRadius.circular(32.r),
                    borderColor: theme.primaryColor.withValues(alpha: 0.3),
                    child: Column(
                      children: [
                        Text(
                          "Choose the descriptor that fits best:",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          quest.word ?? "---",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        if (quest.sentence != null) ...[
                          SizedBox(height: 20.h),
                          Text(
                            quest.sentence!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp,
                              color: isDark ? Colors.white60 : Colors.black45,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().slideY(begin: 0.1),
                  SizedBox(height: 48.h),
                  ...List.generate(quest.options?.length ?? 0, (index) {
                    final option = quest.options![index];
                    final isCorrect = index == quest.correctAnswerIndex;
                    final isSelected = _selectedOptionIndex == index;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: ScaleButton(
                        onTap: () => _onOptionSelected(index, isCorrect),
                        child: GlassTile(
                          borderRadius: BorderRadius.circular(20.r),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 20.h,
                          ),
                          borderColor: isSelected
                              ? (isCorrect ? Colors.green : Colors.red)
                              : Colors.white10,
                          color: isSelected
                              ? (isCorrect
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.red.withValues(alpha: 0.2))
                              : theme.primaryColor.withValues(alpha: 0.05),
                          child: Center(
                            child: Text(
                              option,
                              style: GoogleFonts.outfit(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ),
        if (state.lastAnswerCorrect != null)
          ModernGameResultOverlay(
            isCorrect: state.lastAnswerCorrect!,
            title: state.lastAnswerCorrect! ? "EXCELLENT!" : "NOT QUITE!",
            subtitle:
                "Academic Tip: ${quest.explanation ?? "Academic words are common in formal writing and discussions."}",
            onContinue: () =>
                context.read<VocabularyBloc>().add(NextQuestion()),
            primaryColor: theme.primaryColor,
          ),
        if (_showConfetti) const GameConfetti(),
      ],
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
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: used
              ? Colors.grey.withValues(alpha: 0.1)
              : primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.lightbulb_rounded,
          color: used ? Colors.grey : primaryColor,
          size: 24.r,
        ),
      ),
    );
  }

  

  
}
