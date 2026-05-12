import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class IdiomsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const IdiomsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.idioms,
  });

  @override
  State<IdiomsScreen> createState() => _IdiomsScreenState();
}

class _IdiomsScreenState extends State<IdiomsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
  }

  void _submitAnswer(String selected, String correct) {
    if (_isAnswered) return;
    setState(() {
      _selectedOption = selected;
      _isAnswered = true;
    });

    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();
    
    Future.delayed(600.ms, () {
      if (!mounted) return;
      if (isCorrect) {
        _hapticService.success();
        _soundService.playCorrect();
        setState(() => _isCorrect = true);
        context.read<VocabularyBloc>().add(SubmitAnswer(true));
      } else {
        _hapticService.error();
        _soundService.playWrong();
        setState(() => _isCorrect = false);
        context.read<VocabularyBloc>().add(SubmitAnswer(false));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          if (state.currentIndex != _lastProcessedIndex || (_isAnswered && state.lastAnswerCorrect == null)) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedOption = null;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'EMOJI EXPERT!',
            enableDoubleUp: true,
          );
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;
        if (quest == null && state is! VocabularyGameComplete) return const GameShimmerLoading();

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          child: quest == null ? const SizedBox() : _buildChatInterface(quest, theme.primaryColor),
        );
      },
    );
  }

  Widget _buildChatInterface(VocabularyQuest quest, Color color) {
    return Column(
      children: [
        // Mission Header
        Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
          margin: EdgeInsets.only(bottom: 10.h),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.1))),
          ),
          child: Row(
            children: [
              Container(
                width: 8.r, height: 8.r,
                decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
              SizedBox(width: 10.w),
              Text("DECRYPTION CHANNEL ACTIVE", 
                style: GoogleFonts.shareTechMono(fontSize: 10.sp, color: color.withValues(alpha: 0.7), letterSpacing: 2)
              ),
              const Spacer(),
              Icon(Icons.security_rounded, size: 14.r, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            reverse: false, // Normal chat flow
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            children: [
              _buildSystemMessage("INCOMING TRANSMISSION...", color),
              SizedBox(height: 20.h),
              
              // Stranger/Mission Control Message
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 16.r,
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(Icons.hub_rounded, size: 16.r, color: color),
                  ),
                  SizedBox(width: 8.w),
                  _buildStrangerMessage(quest.topicEmoji ?? "❓", color),
                ],
              ),

              if (_selectedOption != null) ...[
                SizedBox(height: 24.h),
                // User Message
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildUserMessage(_selectedOption!, color, _isCorrect),
                    SizedBox(width: 8.w),
                    CircleAvatar(
                      radius: 16.r,
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.person_rounded, size: 16.r, color: Colors.white70),
                    ),
                  ],
                ),
              ],

              if (_isAnswered && _isCorrect == false) ...[
                SizedBox(height: 15.h),
                _buildSystemMessage("DECRYPTION FAILED. RE-EVALUATE SEQUENCE.", Colors.redAccent),
              ],
            ],
          ),
        ),
        
        _buildOptions(quest.options ?? [], quest.correctAnswer ?? "", color),
        SizedBox(height: 30.h),
      ],
    );
  }

  Widget _buildSystemMessage(String text, Color color) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Text(
          text,
          style: GoogleFonts.shareTechMono(fontSize: 9.sp, color: color, letterSpacing: 1.5, fontWeight: FontWeight.bold),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildStrangerMessage(String emojis, Color color) {
    return Container(
      constraints: BoxConstraints(maxWidth: 0.7.sw),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: -5)
        ],
      ),
      child: Text(
        emojis,
        style: TextStyle(fontSize: 42.sp),
      ),
    ).animate().slideX(begin: -0.1, duration: 500.ms, curve: Curves.easeOutCubic).fadeIn();
  }

  Widget _buildUserMessage(String text, Color color, bool? isCorrect) {
    final bgColor = isCorrect == true ? Colors.green : (isCorrect == false ? Colors.red : color);
    return Container(
      constraints: BoxConstraints(maxWidth: 0.7.sw),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
          bottomLeft: Radius.circular(24.r),
        ),
        border: Border.all(color: bgColor, width: 1.5),
        boxShadow: [
          BoxShadow(color: bgColor.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: -2)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text.toUpperCase(),
              style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
            ),
          ),
          if (isCorrect != null) ...[
            SizedBox(width: 10.w),
            Icon(
              isCorrect ? Icons.verified_rounded : Icons.gpp_bad_rounded,
              color: isCorrect ? Colors.greenAccent : Colors.redAccent,
              size: 18.r,
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          ],
        ],
      ),
    ).animate().slideX(begin: 0.1, duration: 500.ms, curve: Curves.easeOutCubic).fadeIn();
  }

  Widget _buildOptions(List<String> options, String correct, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        alignment: WrapAlignment.center,
        children: options.map((o) {
          final isSelected = _selectedOption == o;
          return ScaleButton(
            onTap: () => _submitAnswer(o, correct),
            child: AnimatedContainer(
              duration: 300.ms,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(30.r), // Capsule style
                border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.2), width: 1.5),
                boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15)] : [],
              ),
              child: Text(
                o.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3, curve: Curves.easeOutCubic);
  }
}
