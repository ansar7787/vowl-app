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
import 'package:voxai_quest/core/presentation/widgets/speaking/sonic_mic_button.dart';
import 'package:voxai_quest/core/utils/ad_service.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/injection_container.dart' as di;
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/core/utils/speech_service.dart';
import 'package:voxai_quest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:voxai_quest/features/speaking/presentation/bloc/speaking_bloc.dart';

class DialogueRoleplayScreen extends StatefulWidget {
  final int level;
  const DialogueRoleplayScreen({super.key, required this.level});

  @override
  State<DialogueRoleplayScreen> createState() => _DialogueRoleplayScreenState();
}

class _DialogueRoleplayScreenState extends State<DialogueRoleplayScreen> {
  final _speechService = di.sl<SpeechService>();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  bool _isListening = false;
  String _recognizedText = '';
  bool _hasAnalyzed = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _speechService.initializeStt();
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(
        gameType: GameSubtype.dialogueRoleplay,
        level: widget.level,
      ),
    );
  }

  void _startListening() {
    _hapticService.success();
    setState(() {
      _isListening = true;
      _recognizedText = '';
      _hasAnalyzed = false;
    });

    _speechService.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result;
        });
      },
      onDone: () {
        if (mounted) {
          setState(() => _isListening = false);
          _analyzeSpeech();
        }
      },
    );
  }

  void _stopListening() async {
    _hapticService.light();
    await _speechService.stop();
    setState(() => _isListening = false);
    _analyzeSpeech();
  }

  void _analyzeSpeech() {
    if (_hasAnalyzed || _recognizedText.isEmpty) return;
    _hasAnalyzed = true;

    final state = context.read<SpeakingBloc>().state;
    if (state is! SpeakingLoaded) return;

    final targetText = (state.currentQuest.correctAnswer ?? "")
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '');
    final utteredText = _recognizedText.toLowerCase().replaceAll(
      RegExp(r'[^\w\s]'),
      '',
    );

    bool isCorrect =
        utteredText == targetText ||
        utteredText.contains(targetText) ||
        (targetText.contains(utteredText) &&
            utteredText.length > targetText.length * 0.7);

    context.read<SpeakingBloc>().add(SubmitAnswer(isCorrect));
  }

  void _useHint() {
    _hapticService.selection();
    context.read<SpeakingBloc>().add(SpeakingHintUsed());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(
      'speaking',
      level: widget.level,
      isDark: isDark,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<SpeakingBloc, SpeakingState>(
        listener: (context, state) {
          if (state is SpeakingGameComplete) {
            setState(() => _showConfetti = true);
            final isPremium =
                context.read<AuthBloc>().state.user?.isPremium ?? false;
            di.sl<AdService>().showInterstitialAd(
              isPremium: isPremium,
              onDismissed: () => GameDialogHelper.showCompletion(
          context,
          xp: state.xpEarned,
          coins: state.coinsEarned,
          title: 'Social Pro!',
          description:
              'You earned ${state.xpEarned} XP and ${state.coinsEarned} Coins for your conversational skills!',
        ),
            );
          } else if (state is SpeakingGameOver) {
            GameDialogHelper.showGameOver(
        context,
        title: 'Conversation Faded',
        description: 'The social connection was lost. Recharge and try again!',
      );
          }
        },
        builder: (context, state) {
          if (state is SpeakingLoading || state is SpeakingInitial) {
            return const GameShimmerLoading();
          }
          if (state is SpeakingLoaded) {
            return Stack(
              children: [
                MeshGradientBackground(colors: theme.backgroundColors),
                _buildGameUI(context, state, isDark, theme),
              ],
            );
          }
          if (state is SpeakingError) {
            return QuestUnavailableScreen(
              message: state.message,
              onRetry: () => context.read<SpeakingBloc>().add(
                FetchSpeakingQuests(
                  gameType: GameSubtype.dialogueRoleplay,
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
    SpeakingLoaded state,
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
                            : Colors.black12,
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
                      "CHAT CHALLENGE",
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: theme.primaryColor,
                      ),
                    ),
                    Text(
                      "Socialize with style",
                      style: GoogleFonts.outfit(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                    SizedBox(height: 30.h),

                    // Chat Interface
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(32.r),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildChatBubble(
                              text:
                                  quest.situationText ??
                                  "Hello! How are you today?",
                              isUser: false,
                              isDark: isDark,
                              primaryColor: theme.primaryColor,
                            ).animate().fadeIn().slideX(begin: -0.1),
                            SizedBox(height: 24.h),
                            if (state.lastAnswerCorrect != null ||
                                _isListening ||
                                _recognizedText.isNotEmpty)
                              _buildChatBubble(
                                text: _recognizedText.isEmpty
                                    ? "..."
                                    : _recognizedText,
                                isUser: true,
                                isDark: isDark,
                                status: state.lastAnswerCorrect,
                                primaryColor: theme.primaryColor,
                              ).animate().fadeIn().slideX(begin: 0.1),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),
                    if (state.lastAnswerCorrect == null)
                      SonicMicButton(
                        isListening: _isListening,
                        onStart: _startListening,
                        onStop: _stopListening,
                        primaryColor: theme.primaryColor,
                      ),
                    SizedBox(height: 16.h),
                    Text(
                      _isListening ? "RECORDING..." : "PRESS & HOLD TO REPLY",
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white38 : Colors.black38,
                        letterSpacing: 1,
                      ),
                    ),
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
                ? "CONVERSATION MASTER!"
                : "TRY ANOTHER WAY!",
            subtitle: state.lastAnswerCorrect!
                ? null
                : "Try: \"${quest.correctAnswer}\"",
            onContinue: () => context.read<SpeakingBloc>().add(NextQuestion()),
            primaryColor: theme.primaryColor,
          ),
        if (_showConfetti) const GameConfetti(),
      ],
    );
  }

  Widget _buildChatBubble({
    required String text,
    required bool isUser,
    required bool isDark,
    required Color primaryColor,
    bool? status,
  }) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GlassTile(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
          bottomLeft: isUser ? Radius.circular(20.r) : Radius.zero,
          bottomRight: isUser ? Radius.zero : Radius.circular(20.r),
        ),
        padding: EdgeInsets.all(20.r),
        color: isUser
            ? (status == true
                  ? Colors.green.withValues(alpha: 0.15)
                  : status == false
                  ? Colors.red.withValues(alpha: 0.15)
                  : primaryColor.withValues(alpha: 0.15))
            : null,
        borderColor: isUser
            ? (status == true
                  ? Colors.green
                  : status == false
                  ? Colors.red
                  : primaryColor)
            : null,
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
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
      child: GlassTile(
        borderRadius: BorderRadius.circular(50.r),
        padding: EdgeInsets.all(8.r),
        color: used
            ? Colors.grey.withValues(alpha: 0.1)
            : primaryColor.withValues(alpha: 0.1),
        borderColor: used
            ? Colors.grey.withValues(alpha: 0.3)
            : primaryColor.withValues(alpha: 0.5),
        child: Icon(
          Icons.lightbulb_rounded,
          color: used ? Colors.grey : primaryColor,
          size: 24.r,
        ),
      ),
    );
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  

  
}
