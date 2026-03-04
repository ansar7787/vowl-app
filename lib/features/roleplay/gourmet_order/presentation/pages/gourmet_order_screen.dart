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
import 'package:voxai_quest/core/presentation/widgets/roleplay/cinema_light.dart';
import 'package:voxai_quest/core/presentation/widgets/scale_button.dart';
import 'package:voxai_quest/core/presentation/widgets/shimmer_loading.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/features/roleplay/presentation/bloc/roleplay_bloc.dart';

class GourmetOrderScreen extends StatefulWidget {
  final int level;
  const GourmetOrderScreen({super.key, required this.level});

  @override
  State<GourmetOrderScreen> createState() => _GourmetOrderScreenState();
}

class _GourmetOrderScreenState extends State<GourmetOrderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _ttsService = di.sl<SpeechService>();
  final List<Map<String, dynamic>> _chatMessages = [];
  bool _isPlaying = false;
  bool _showConfetti = false;
  int? _selectedOptionIndex;

  @override
  void initState() {
    super.initState();
    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(
        gameType: GameSubtype.gourmetOrder,
        level: widget.level,
      ),
    );
  }

  void _playAudio(String text) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _hapticService.light();
    await _ttsService.speak(text);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _onOptionSelected(int index, String optionText) {
    if (_selectedOptionIndex != null) return;
    _hapticService.selection();
    setState(() {
      _selectedOptionIndex = index;
      _chatMessages.add({'text': optionText, 'isUser': true});
    });

    final state = context.read<RoleplayBloc>().state;
    if (state is RoleplayLoaded) {
      final isCorrect = index == 0;

      if (isCorrect) {
        _soundService.playCorrect();
        _hapticService.success();
      } else {
        _soundService.playWrong();
        _hapticService.error();
      }

      context.read<RoleplayBloc>().add(SubmitAnswer(isCorrect));
    }
  }

  void _useHint() {
    _hapticService.selection();
    context.read<RoleplayBloc>().add(RoleplayHintUsed());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      'roleplay',
      level: widget.level,
      isDark: isDark,
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: BlocConsumer<RoleplayBloc, RoleplayState>(
        listener: (context, state) {
          if (state is RoleplayGameComplete) {
            setState(() => _showConfetti = true);
            final isPremium =
                context.read<AuthBloc>().state.user?.isPremium ?? false;
            di.sl<AdService>().showInterstitialAd(
              isPremium: isPremium,
              onDismissed: () => GameDialogHelper.showCompletion(
          context,
          xp: state.xpEarned,
          coins: state.coinsEarned,
          title: 'Master Gourmand!',
          description:
              'You earned ${state.xpEarned} XP and ${state.coinsEarned} Coins. Tasty victory!',
        ),
            );
          } else if (state is RoleplayGameOver) {
            GameDialogHelper.showGameOver(
        context,
        title: 'Wrong Order',
        description: 'The kitchen got confused by your order. Try again!',
      );
          } else if (state is RoleplayLoaded &&
              state.lastAnswerCorrect == null) {
            _selectedOptionIndex = null;
            if (_chatMessages.isEmpty || !_chatMessages.last['isUser']) {
              _chatMessages.add({
                'text': state.currentQuest.instruction,
                'isUser': false,
              });
            }
          }
        },
        builder: (context, state) {
          if (state is RoleplayLoading || state is RoleplayInitial) {
            return const GameShimmerLoading();
          }
          if (state is RoleplayLoaded) {
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                CinemaLight(color: theme.primaryColor),
                _buildGameUI(context, state, isDark, theme),
              ],
            );
          }
          if (state is RoleplayError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<RoleplayBloc>().add(
                FetchRoleplayQuests(
                  gameType: GameSubtype.gourmetOrder,
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
    RoleplayLoaded state,
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
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final msg = _chatMessages[index];
                  return _buildChatBubble(
                    msg['text'],
                    msg['isUser'],
                    isDark,
                    theme.primaryColor,
                  );
                },
              ),
            ),
            if (state.lastAnswerCorrect == null)
              GlassTile(
                borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
                padding: EdgeInsets.fromLTRB(24.r, 32.r, 24.r, 48.r),
                borderColor: theme.primaryColor.withValues(alpha: 0.3),
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "WAITER WAITING...",
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: theme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ...List.generate(quest.options?.length ?? 0, (index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: ScaleButton(
                          onTap: () =>
                              _onOptionSelected(index, quest.options![index]),
                          child: GlassTile(
                            borderRadius: BorderRadius.circular(20.r),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 18.h,
                            ),
                            borderColor: theme.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            color: theme.primaryColor.withValues(alpha: 0.05),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.restaurant_rounded,
                                  color: theme.primaryColor,
                                  size: 20.r,
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Text(
                                    quest.options![index],
                                    style: GoogleFonts.outfit(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ).animate().slideY(
                begin: 1,
                duration: 600.ms,
                curve: Curves.easeOutCubic,
              ),
          ],
        ),
        if (state.lastAnswerCorrect != null)
          ModernGameResultOverlay(
            isCorrect: state.lastAnswerCorrect!,
            title: state.lastAnswerCorrect! ? "BON APPÉTIT!" : "ORDER MISTAKE!",
            subtitle:
                "Dining Tip: ${quest.explanation ?? "Politeness is key in restaurant communication."}",
            onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
            primaryColor: theme.primaryColor,
          ),
        if (_showConfetti) const GameConfetti(),
      ],
    );
  }

  Widget _buildChatBubble(
    String text,
    bool isUser,
    bool isDark,
    Color userColor,
  ) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GlassTile(
        borderRadius: BorderRadius.circular(20.r).copyWith(
          bottomRight: isUser ? Radius.zero : Radius.circular(20.r),
          bottomLeft: isUser ? Radius.circular(20.r) : Radius.zero,
        ),
        padding: EdgeInsets.all(16.r),
        color: isUser ? userColor.withValues(alpha: 0.8) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              ScaleButton(
                onTap: () => _playAudio(text),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 18.r,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ),
            Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: isUser
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: isUser ? 0.2 : -0.2);
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
