import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

class GenericRoleplayScenarioScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  final String title;
  final IconData icon;

  const GenericRoleplayScenarioScreen({
    super.key,
    required this.level,
    required this.gameType,
    required this.title,
    required this.icon,
  });

  @override
  State<GenericRoleplayScenarioScreen> createState() => _GenericRoleplayScenarioScreenState();
}

class _GenericRoleplayScenarioScreenState extends State<GenericRoleplayScenarioScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _ttsService = di.sl<SpeechService>();

  bool _isPlaying = false;
  bool _showConfetti = false;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool _isProcessing = false; // New processing state for chat flow
  int _lastProcessedIndex = -1;

  @override
  void dispose() {
    _ttsService.stop(); // Stop any active speech immediately
    super.dispose();
  }
  int? _lastLives;
  int _attempts = 0;
  final List<Map<String, dynamic>> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  void _playAudio(String text) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    _hapticService.light();
    await _ttsService.speak(text);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _onOptionSelected(int index, int correctIndex, String text) async {
    if (_isAnswered || _selectedIndex != null || _isProcessing) return;
    
    final isCorrect = index == correctIndex;
    setState(() {
      _isProcessing = true;
      _selectedIndex = index;
      _chatMessages.add({'text': text, 'isUser': true});
    });

    if (isCorrect) {
      _soundService.playCorrect();
      _hapticService.success();
      
      // Add "Thinking" delay for the character response
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        setState(() { 
          _isAnswered = true; 
          _isProcessing = false;
        });
        context.read<RoleplayBloc>().add(SubmitAnswer(true));
      }
    } else {
      _soundService.playWrong();
      _hapticService.error();
      _attempts++;
      
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        if (_attempts >= 2) {
          setState(() { 
            _isAnswered = true; 
            _isProcessing = false;
          });
        } else {
          setState(() {
            _selectedIndex = null; // Allow retry
            _isProcessing = false;
          });
        }
        context.read<RoleplayBloc>().add(SubmitAnswer(false));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listener: (context, state) {
        if (state is RoleplayLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _selectedIndex = null;
              _attempts = 0;
              _chatMessages.clear();
              _chatMessages.add({'text': state.currentQuest.instruction, 'isUser': false});
            });
            _playAudio(state.currentQuest.instruction);
          }
          _lastLives = state.livesRemaining;
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'ROLEPLAY MASTER!', enableDoubleUp: true);
        } else if (state is RoleplayGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final roleplayState = (state is RoleplayLoaded) ? state : null;
        if (roleplayState == null) return const Scaffold(body: GameShimmerLoading());

        final quest = roleplayState.currentQuest;
        final options = quest.options ?? [];
        final correctIndex = quest.correctAnswerIndex ?? 0;

        return RoleplayBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _selectedIndex == correctIndex, 
          isFinalFailure: _attempts >= 2,
          showConfetti: _showConfetti,
          title: widget.title, subtitle: quest.scene ?? "Choose the best response",
          onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
          onHint: () => context.read<RoleplayBloc>().add(RoleplayHintUsed()),
          child: Column(
            children: [
              GlassTile(
                padding: EdgeInsets.all(24.r), borderRadius: BorderRadius.circular(32.r),
                color: theme.primaryColor.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(widget.icon, color: theme.primaryColor, size: 32.r),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(child: Text(quest.roleName ?? "Professional Advisor", style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w900, color: theme.primaryColor))),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              
              Column(
                children: List.generate(_chatMessages.length, (index) {
                  final msg = _chatMessages[index];
                  return _buildChatBubble(msg['text'], msg['isUser'], isDark, theme.primaryColor);
                }),
              ),
              if (_isProcessing)
                _buildChatBubble("...", false, isDark, theme.primaryColor).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.seconds),
              
              if (roleplayState.hintUsed && quest.hint != null)
                _buildChatBubble("HINT: ${quest.hint}", false, isDark, Colors.amber.withValues(alpha: 0.8)),

              if (!_isAnswered) ...[
                SizedBox(height: 32.h),
                Text("CHOOSE YOUR RESPONSE", style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w900, color: theme.primaryColor.withValues(alpha: 0.6), letterSpacing: 2)),
                SizedBox(height: 16.h),
                Column(
                  children: List.generate(options.length, (index) {
                    final option = options[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: ScaleButton(
                        onTap: () => _onOptionSelected(index, correctIndex, option),
                        child: GlassTile(
                          padding: EdgeInsets.all(20.r), borderRadius: BorderRadius.circular(24.r),
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                          borderColor: theme.primaryColor.withValues(alpha: 0.1),
                          child: Row(
                            children: [
                              Container(
                                width: 32.r, height: 32.r,
                                decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: Center(child: Text("${index + 1}", style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w900, color: theme.primaryColor))),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(child: Text(option, style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)))),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatBubble(String text, bool isUser, bool isDark, Color color) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: Container(
          padding: EdgeInsets.all(14.r),
          constraints: BoxConstraints(maxWidth: 0.75.sw),
          decoration: BoxDecoration(
            color: isUser ? color : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(20.r).copyWith(
              bottomLeft: isUser ? Radius.circular(20.r) : Radius.zero,
              bottomRight: isUser ? Radius.zero : Radius.circular(20.r),
            ),
          ),
          child: Text(text, style: GoogleFonts.outfit(fontSize: 15.sp, fontWeight: FontWeight.w500, color: isUser ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)))),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: isUser ? 0.05 : -0.05);
  }
}

