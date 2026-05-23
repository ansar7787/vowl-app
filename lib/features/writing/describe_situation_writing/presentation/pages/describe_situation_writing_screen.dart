import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';

class DescribeSituationScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DescribeSituationScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.describeSituationWriting,
  });

  @override
  State<DescribeSituationScreen> createState() => _DescribeSituationScreenState();
}

class _DescribeSituationScreenState extends State<DescribeSituationScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _textController = TextEditingController();
  
  final List<String> _usedKeywords = [];
  int? _expandedEmojiIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text.trim();
    final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    setState(() {
      _wordCount = words;
    });
  }

  void _onEmojiTap(int index) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() => _expandedEmojiIndex = (_expandedEmojiIndex == index ? null : index));
  }

  void _injectKeyword(String keyword) {
    if (_isAnswered) return;
    _hapticService.success();
    
    final text = _textController.text;
    final selection = _textController.selection;
    
    String newText;
    int newCursorPosition;
    
    if (selection.isValid) {
      newText = text.replaceRange(selection.start, selection.end, keyword);
      newCursorPosition = selection.start + keyword.length;
    } else {
      newText = text.isEmpty ? keyword : "$text $keyword";
      newCursorPosition = newText.length;
    }
    
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(offset: newCursorPosition);
    
    setState(() {
      if (!_usedKeywords.contains(keyword)) {
        _usedKeywords.add(keyword);
      }
      _expandedEmojiIndex = null;
    });
  }

  void _submitAnswer(int minWords, List<String> availableKeywords) {
    if (_isAnswered) return;
    
    final composedText = _textController.text.trim().toLowerCase();
    
    // Validate keywords present in text
    int matchedCount = 0;
    for (var kw in availableKeywords) {
      if (composedText.contains(kw.toLowerCase())) {
        matchedCount++;
      }
    }
    
    bool isMinWordsMet = _wordCount >= minWords;
    bool isKeywordsMet = matchedCount >= 2; // Require at least 2 keywords inside the story
    
    if (isMinWordsMet && isKeywordsMet) {
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
        _isAnswered = true; 
        _isCorrect = false; 
      });
      context.read<WritingBloc>().add(SubmitAnswer(false));
      
      // Let them retry
      Future.delayed(1.5.seconds, () {
        if (mounted) {
          setState(() {
            _isAnswered = false;
            _isCorrect = null;
          });
        }
      });
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
              _usedKeywords.clear();
              _textController.clear();
              _expandedEmojiIndex = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'CREATIVE GENIUS!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final WritingQuest? quest = (state is WritingLoaded) ? state.currentQuest as WritingQuest? : null;
        
        final emojis = quest?.emojis ?? ["🌋", "💧", "🔬", "🐠"];
        final rawKeywords = quest?.keywords ?? {
          "0": ["VENTING", "MAGMA", "PLUME"],
          "1": ["OCEANIC", "THERMAL", "PRESSURE"],
          "2": ["MINERAL", "CHEMICAL", "HYDROUS"],
          "3": ["CREATURE", "BENTHIC", "ABYSSAL"]
        };
        
        final allKeywordPool = rawKeywords.values.expand((element) => element).toList();
        final minWords = quest?.minWords ?? 15;

        return WritingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
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
                  
                  _buildPromptCard(quest.situation ?? "", theme.primaryColor, isDark),
                  SizedBox(height: 24.h),
                  
                  _buildWritingArea(minWords, theme.primaryColor, isDark),
                  SizedBox(height: 24.h),
                  
                  _buildConstellationMap(emojis, rawKeywords, theme.primaryColor, isDark),
                  SizedBox(height: 30.h),
                  
                  if (!_isAnswered)
                    ScaleButton(
                      onTap: () => _submitAnswer(minWords, allKeywordPool),
                      child: Container(
                        width: double.infinity, height: 60.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r), 
                          color: _wordCount >= minWords ? theme.primaryColor : Colors.grey, 
                          boxShadow: [
                            if (_wordCount >= minWords) 
                              BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 15)
                          ]
                        ),
                        child: Center(
                          child: Text(
                            "SEAL NARRATIVE", 
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
          Icon(Icons.auto_fix_high_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("EXPAND EMOJIS TO INJECT NARRATIVE KEYWORDS", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPromptCard(String prompt, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Stack(
        children: [
          const TechPatternOverlay(opacity: 0.05),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SITUATION PROMPT",
                style: GoogleFonts.shareTechMono(fontSize: 11.sp, color: color, fontWeight: FontWeight.bold, letterSpacing: 1.5)
              ),
              SizedBox(height: 8.h),
              Text(
                prompt,
                style: GoogleFonts.fredoka(fontSize: 16.sp, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold, height: 1.4)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWritingArea(int minWords, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12, width: 2),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            maxLines: 4,
            style: GoogleFonts.shareTechMono(color: isDark ? Colors.white : Colors.black87, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: "Type description here... (Tap floating emoji cells to inject keyword boosters directly!)",
              hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white30 : Colors.black38, fontSize: 12.sp),
              border: InputBorder.none,
            ),
          ),
          const Divider(color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Booster words used: ${_usedKeywords.length}",
                style: GoogleFonts.shareTechMono(fontSize: 10.sp, color: color, fontWeight: FontWeight.bold)
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _wordCount >= minWords ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  "$_wordCount / $minWords words",
                  style: GoogleFonts.shareTechMono(
                    fontSize: 10.sp, 
                    color: _wordCount >= minWords ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold
                  )
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConstellationMap(List<String> emojis, Map<String, List<String>> keywords, Color color, bool isDark) {
    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.03 : 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Stack(
        children: List.generate(emojis.length, (index) {
          final isExpanded = _expandedEmojiIndex == index;
          
          final double leftPos = 20.w + (index * 70.w);
          final double topPos = (index % 2 == 0) ? 25.h : 95.h;

          return Positioned(
            left: leftPos,
            top: topPos,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _onEmojiTap(index),
                  child: Container(
                    width: 50.r, height: 50.r,
                    decoration: BoxDecoration(
                      color: isExpanded ? color : (isDark ? Colors.white10 : Colors.black12),
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (isExpanded) 
                          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 15)
                      ],
                    ),
                    child: Center(
                      child: Text(emojis[index], style: TextStyle(fontSize: 22.sp))
                    ),
                  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                ),
                if (isExpanded) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black87 : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: color),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (keywords[index.toString()] ?? []).map((k) => TextButton(
                        onPressed: () => _injectKeyword(k),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        ),
                        child: Text(
                          k, 
                          style: GoogleFonts.shareTechMono(color: isDark ? Colors.white : Colors.black87, fontSize: 11.sp, fontWeight: FontWeight.bold)
                        ),
                      )).toList(),
                    ),
                  ).animate().scale(alignment: Alignment.centerLeft).fadeIn(),
                ],
              ],
            ),
          );
        }),
      ),
    );
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
          if (quest.explanation != null) ...[
            SizedBox(height: 10.h),
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
