import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_instruction.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_prompt_card.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_writing_area.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_constellation_map.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_explanation_card.dart';

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
    _hapticService.selection();
    
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
    
    int matchedCount = 0;
    for (var kw in availableKeywords) {
      if (composedText.contains(kw.toLowerCase())) {
        matchedCount++;
      }
    }
    
    bool isMinWordsMet = _wordCount >= minWords;
    bool isKeywordsMet = matchedCount >= 2; 
    
    if (isMinWordsMet && isKeywordsMet) {
      setState(() { 
        _isAnswered = true; 
        _isCorrect = true; 
      });
      context.read<WritingBloc>().add(SubmitAnswer(true));
    } else {
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false; 
      });
      context.read<WritingBloc>().add(SubmitAnswer(false));
      
      Future.delayed(const Duration(milliseconds: 1500), () {
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
        final WritingQuest? quest = (state is WritingLoaded) ? state.currentQuest : null;
        
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
                  DescribeSituationInstruction(primaryColor: theme.primaryColor),
                  SizedBox(height: 24.h),
                  
                  DescribeSituationPromptCard(
                    prompt: quest.situation ?? "",
                    color: theme.primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: 24.h),
                  
                  DescribeSituationWritingArea(
                    textController: _textController,
                    minWords: minWords,
                    wordCount: _wordCount,
                    usedKeywords: _usedKeywords,
                    color: theme.primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: 24.h),
                  
                  DescribeSituationConstellationMap(
                    emojis: emojis,
                    keywords: rawKeywords,
                    color: theme.primaryColor,
                    isDark: isDark,
                    expandedEmojiIndex: _expandedEmojiIndex,
                    onEmojiTap: _onEmojiTap,
                    onInjectKeyword: _injectKeyword,
                  ),
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
                            style: TextStyle(fontFamily: 'Outfit', fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)
                          )
                        ),
                      ),
                    ),
                  
                  if (_isAnswered) ...[
                    SizedBox(height: 30.h),
                    DescribeSituationExplanationCard(
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
