import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';

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
    
    // Check which targeted keywords are present in the typed text
    int matchedCount = 0;
    for (var kw in targetKeywords) {
      if (text.contains(kw.toLowerCase())) {
        matchedCount++;
      }
    }
    
    bool isMinLengthMet = _wordCount >= 10; // Encourage at least 10 words
    bool isKeywordsMet = matchedCount >= 2; // Require at least 2 of the 3 targeted booster terms

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
      
      // Let them edit if not final failure
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
                  _buildInstruction(theme.primaryColor),
                  SizedBox(height: 24.h),
                  
                  _buildQuillPrompt(quest.prompt ?? "", theme.primaryColor, isDark),
                  SizedBox(height: 24.h),
                  
                  _buildBoosterTokens(targetKeywords, theme.primaryColor, isDark),
                  SizedBox(height: 24.h),
                  
                  _buildInkwell(theme.primaryColor, isDark),
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
                            style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)
                          )
                        ),
                      ),
                    ),
                  
                  if (_isAnswered) ...[
                    SizedBox(height: 30.h),
                    _buildCorrectResult(quest, theme.primaryColor, isDark),
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

  Widget _buildInstruction(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: primaryColor.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_edu_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("DRIP YOUR THOUGHTS INTO THE WELL", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildQuillPrompt(String prompt, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Stack(
        children: [
          const TechPatternOverlay(opacity: 0.05),
          Column(
            children: [
              Icon(Icons.auto_stories_rounded, color: color, size: 32.r).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5),
              SizedBox(height: 16.h),
              Text(
                prompt, 
                style: GoogleFonts.spectral(fontSize: 18.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87, height: 1.6), 
                textAlign: TextAlign.center
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoosterTokens(List<String> keywords, Color color, bool isDark) {
    final text = _answerController.text.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "BOOSTER KEYWORDS REQUIRED (USE AT LEAST 2)",
          style: GoogleFonts.shareTechMono(fontSize: 10.sp, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12.w, runSpacing: 8.h,
          alignment: WrapAlignment.center,
          children: keywords.map((k) {
            final bool isUsed = text.contains(k.toLowerCase());
            final displayColor = isUsed ? Colors.greenAccent : (isDark ? Colors.white24 : Colors.black26);
            
            return AnimatedContainer(
              duration: 300.milliseconds,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isUsed ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: displayColor, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUsed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 14.r,
                    color: isUsed ? Colors.greenAccent : (isDark ? Colors.white30 : Colors.black38),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    k.toUpperCase(),
                    style: GoogleFonts.shareTechMono(
                      color: isUsed ? Colors.greenAccent : (isDark ? Colors.white60 : Colors.black54),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInkwell(Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12, width: 3),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: -5)
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _answerController,
            maxLines: 5,
            enabled: !_isAnswered,
            style: GoogleFonts.spectral(
              fontSize: 16.sp, 
              color: isDark ? Colors.white : Colors.black87, 
              height: 1.5,
              fontWeight: FontWeight.bold
            ),
            decoration: InputDecoration(
              hintText: "Let the ink flow...",
              hintStyle: GoogleFonts.spectral(color: isDark ? Colors.white30 : Colors.black38),
              border: InputBorder.none,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ink volume:",
                style: GoogleFonts.shareTechMono(fontSize: 10.sp, color: color, fontWeight: FontWeight.bold)
              ),
              Text(
                "$_wordCount words",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp, 
                  color: _wordCount >= 10 ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold
                )
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Stack(
            children: [
              Container(width: double.infinity, height: 6.h, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(3.r))),
              AnimatedContainer(
                duration: 300.milliseconds,
                width: MediaQuery.of(context).size.width * _inkLevel * 0.7,
                height: 6.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.5)]),
                  borderRadius: BorderRadius.circular(3.r),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(target: _inkLevel).shimmer(duration: 2.seconds);
  }

  Widget _buildCorrectResult(dynamic quest, Color primaryColor, bool isDark) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: displayColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: displayColor, size: 36.r),
          SizedBox(height: 10.h),
          Text(
            correct ? "CORRECT!" : "INCORRECT",
            style: GoogleFonts.outfit(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: displayColor,
              letterSpacing: 2,
            ),
          ),
          if (quest.sampleAnswer != null) ...[
            SizedBox(height: 16.h),
            Text(
              "SAMPLE ANSWER",
              style: GoogleFonts.shareTechMono(fontSize: 10.sp, color: primaryColor, fontWeight: FontWeight.bold)
            ),
            SizedBox(height: 6.h),
            Text(
              quest.sampleAnswer!,
              textAlign: TextAlign.center,
              style: GoogleFonts.spectral(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
          if (quest.explanation != null) ...[
            SizedBox(height: 16.h),
            Text(
              quest.explanation!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
