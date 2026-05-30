import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_base_layout.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_instruction.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_quill_prompt.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_booster_tokens.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_inkwell.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_explanation_card.dart';

class ShortAnswerScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ShortAnswerScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.shortAnswerWriting,
  });

  @override
  State<ShortAnswerScreen> createState() => _ShortAnswerScreenState();
}

class _ShortAnswerScreenState extends State<ShortAnswerScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _answerController = TextEditingController();
  
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int _attempts = 0;
  int? _lastLives;
  double _inkLevel = 0.0;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
    _answerController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _answerController.text.trim();
    final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    setState(() {
      _wordCount = words;
      _inkLevel = (text.length / 75).clamp(0.0, 1.0);
    });
  }

  void _submitAnswer(List<String> targetKeywords) {
    if (_isAnswered || _answerController.text.trim().isEmpty) return;
    
    final text = _answerController.text.trim().toLowerCase();
    
    int matchedCount = 0;
    for (var kw in targetKeywords) {
      if (text.contains(kw.toLowerCase())) {
        matchedCount++;
      }
    }
    
    bool isMinLengthMet = _wordCount >= 10; 
    bool isKeywordsMet = matchedCount >= 2; 

    if (isMinLengthMet && isKeywordsMet) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = true; 
      });
      context.read<WritingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _attempts++;
        if (_attempts >= 2) {
          _isAnswered = true; 
          _isCorrect = false;
        }
      });
      context.read<WritingBloc>().add(SubmitAnswer(false));
      
      if (_attempts < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              !isMinLengthMet 
                ? "Your response is too short! Try to expand your ideas." 
                : "Make sure to include at least 2 of the highlighted booster keywords!",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listener: (context, state) {
        if (state is WritingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _answerController.clear();
              _attempts = 0;
              _inkLevel = 0.0;
              _wordCount = 0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'CREATIVE AUTHOR!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final WritingQuest? quest = (state is WritingLoaded) ? state.currentQuest as WritingQuest? : null;
        
        final targetKeywords = quest?.options ?? ["bacteria", "sulfide", "chemosynthesis"];

        return WritingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          isFinalFailure: _attempts >= 2,
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: quest == null ? const SizedBox() : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  ShortAnswerInstruction(primaryColor: theme.primaryColor),
                  SizedBox(height: 24.h),
                  
                  ShortAnswerQuillPrompt(
                    prompt: quest.prompt ?? "",
                    color: theme.primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: 24.h),
                  
                  ShortAnswerBoosterTokens(
                    keywords: targetKeywords,
                    text: _answerController.text,
                    color: theme.primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: 24.h),
                  
                  ShortAnswerInkwell(
                    controller: _answerController,
                    isAnswered: _isAnswered,
                    wordCount: _wordCount,
                    inkLevel: _inkLevel,
                    color: theme.primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: 36.h),
                  
                  if (!_isAnswered)
                    ScaleButton(
                      onTap: () => _submitAnswer(targetKeywords),
                      child: Container(
                        width: double.infinity, height: 60.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r), 
                          color: _wordCount >= 10 ? theme.primaryColor : Colors.grey, 
                          boxShadow: [
                            if (_wordCount >= 10) 
                              BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 15)
                          ]
                        ),
                        child: Center(
                          child: Text(
                            "SEAL WITH WAX", 
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp, 
                              fontWeight: FontWeight.w900, 
                              color: Colors.white, 
                              letterSpacing: 2
                            )
                          )
                        ),
                      ),
                    ),
                  
                  if (_isAnswered) ...[
                    SizedBox(height: 30.h),
                    ShortAnswerExplanationCard(
                      quest: quest,
                      isCorrect: _isCorrect == true,
                      primaryColor: theme.primaryColor,
                      isDark: isDark,
                    ),
                  ],
                  SizedBox(height: 60.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
