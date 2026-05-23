import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter/foundation.dart';

class SentenceCorrectionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SentenceCorrectionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.sentenceCorrection,
  });

  @override
  State<SentenceCorrectionScreen> createState() => _SentenceCorrectionScreenState();
}

class _SentenceCorrectionScreenState extends State<SentenceCorrectionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  int? _selectedWordIndex;
  String? _selectedOption;
  List<String>? _shuffledOptions;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(FetchGrammarQuests(gameType: widget.gameType, level: widget.level));
  }

  List<int> _getCorrectIndices(List<String> words, GrammarQuest quest) {
    if (quest.incorrectPart == null) return [0];

    final cleanTarget = quest.incorrectPart!.toLowerCase().replaceAll('"', '').trim();
    final targetWords = cleanTarget.split(' ').where((w) => w.isNotEmpty).toList();

    if (targetWords.isEmpty) return [0];

    final cleanSentenceWords = words.map((w) => w.toLowerCase().replaceAll(RegExp(r'[^\w]'), '')).toList();
    final cleanTargetWords = targetWords.map((w) => w.replaceAll(RegExp(r'[^\w]'), '')).toList();

    List<int> matchingIndices = [];

    // contiguous search match
    for (int i = 0; i <= cleanSentenceWords.length - cleanTargetWords.length; i++) {
      bool match = true;
      for (int j = 0; j < cleanTargetWords.length; j++) {
        if (!cleanSentenceWords[i + j].contains(cleanTargetWords[j]) && 
            !cleanTargetWords[j].contains(cleanSentenceWords[i + j])) {
          match = false;
          break;
        }
      }
      if (match) {
        for (int j = 0; j < cleanTargetWords.length; j++) {
          matchingIndices.add(i + j);
        }
        break;
      }
    }

    if (matchingIndices.isEmpty) {
      for (int i = 0; i < cleanSentenceWords.length; i++) {
        for (var targetW in cleanTargetWords) {
          if (cleanSentenceWords[i] == targetW || 
              (cleanSentenceWords[i].isNotEmpty && targetW.contains(cleanSentenceWords[i]))) {
            matchingIndices.add(i);
          }
        }
      }
    }

    if (matchingIndices.isEmpty) {
      final fallbackIdx = words.indexWhere((w) {
        final cleanW = w.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        return cleanW.contains(cleanTargetWords.first) || cleanTargetWords.first.contains(cleanW);
      });
      if (fallbackIdx != -1) {
        matchingIndices.add(fallbackIdx);
      } else {
        matchingIndices.add(0);
      }
    }

    return matchingIndices;
  }

  void _onWordTap(int index) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _selectedWordIndex = index;
      _selectedOption = null; // reset option select on different word tap
    });
  }

  void _confirmRepair(List<int> correctIndices, GrammarQuest quest, List<String> words) {
    if (_selectedWordIndex == null || _selectedOption == null) return;

    bool isWordCorrect = correctIndices.contains(_selectedWordIndex);
    
    // Dual validation: check value or fallback to original options index mapping
    int chosenIndex = quest.options?.indexOf(_selectedOption!) ?? -1;
    bool isOptionCorrect = (_selectedOption == quest.correctAnswer) || 
                          (chosenIndex == quest.correctAnswerIndex);
                          
    bool overallCorrect = isWordCorrect && isOptionCorrect;

    // ⚡ PRODUCION DIAGNOSTICS LOGGING
    if (kDebugMode) {
      print("=== SYNTAX REPAIR DIAGNOSTICS ===");
      print("Sentence: ${quest.sentence}");
      print("Words split list: $words");
      print("Tapped Word Index: $_selectedWordIndex (Word: ${words[_selectedWordIndex!]})");
      print("Target Error Indices calculated: $correctIndices");
      print("Is Word Target Correct? $isWordCorrect");
      print("Tapped Option: '$_selectedOption'");
      print("Correct Answer: '${quest.correctAnswer}'");
      print("Options List: ${quest.options}");
      print("Correct Answer Index: ${quest.correctAnswerIndex}");
      print("Is Option Correct? $isOptionCorrect");
      print("Overall Resolution Correct? $overallCorrect");
      print("================================");
    }

    if (overallCorrect) {
      _hapticService.heavy();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedWordIndex = null;
              _selectedOption = null;
              _shuffledOptions = null;
            });
          } else if (state.lastAnswerCorrect == null && _isAnswered) {
            // TRY AGAIN trigger: Reset diagnostics and option selection locks
            setState(() {
              _isAnswered = false;
              _isCorrect = null;
              _selectedWordIndex = null;
              _selectedOption = null;
              _shuffledOptions = List.from(state.currentQuest.options ?? [])..shuffle();
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SYNTAX SURGEON!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final rawSentence = quest?.sentence ?? "";
        final cleanSentence = rawSentence.replaceAll('"', '').replaceAll('Fix:', '').trim();
        final words = cleanSentence.split(' ').where((w) => w.isNotEmpty).toList();

        if (quest != null && _shuffledOptions == null) {
          _shuffledOptions = List<String>.from(quest.options ?? []);
          _shuffledOptions!.shuffle();
        }

        final List<int> correctIndices = quest == null ? [] : _getCorrectIndices(words, quest);

        return GrammarBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect, 
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          useScrolling: true,
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 10.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 12.h),
              Text(
                "Tap the incorrect word to diagnose, then choose the repair option.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              SizedBox(height: 16.h),
              
              // Optimized: Kinetic Diagnostic Context Card (The Diamond Standard)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(32.r),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: theme.primaryColor.withValues(alpha: 0.05), blurRadius: 40, spreadRadius: 5)
                    ],
                  ),
                  child: _buildZapperGrid(words, correctIndices, theme.primaryColor, isDark),
                ),
              ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),

              SizedBox(height: 20.h),
              _buildDiagnosticStatus(theme.primaryColor),
              
              // Options selection panel
              if (_selectedWordIndex != null) ...[
                SizedBox(height: 24.h),
                _buildOptionsPanel(theme.primaryColor, isDark, quest, words),
              ],
              
              if (_isAnswered && _isCorrect == false) ...[
                SizedBox(height: 24.h),
                _buildCorrectionFeed(quest.correctedPart ?? "", theme.primaryColor),
              ],
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.biotech_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "INITIATE LINGUISTIC SCAN", 
            style: GoogleFonts.outfit(
              fontSize: 10.sp, 
              fontWeight: FontWeight.w900, 
              color: primaryColor, 
              letterSpacing: 1.5
            )
          ),
        ],
      ),
    );
  }

  Widget _buildZapperGrid(List<String> words, List<int> correctIndices, Color primaryColor, bool isDark) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10.w,
      runSpacing: 16.h,
      children: List.generate(words.length, (i) => _buildDiagnosticWord(words[i], i, correctIndices, primaryColor, isDark)),
    );
  }

  Widget _buildDiagnosticWord(String text, int index, List<int> correctIndices, Color primaryColor, bool isDark) {
    final isSuspected = _selectedWordIndex == index;
    final isCorrectZap = _isAnswered && _isCorrect == true && correctIndices.contains(index);
    final isWrongZap = _isAnswered && _isCorrect == false && _selectedWordIndex == index;

    Color itemColor = Colors.transparent;
    Color borderColor = primaryColor.withValues(alpha: 0.1);
    double borderWidth = 1;
    Color textColor = isDark ? Colors.white : Colors.black87;
    List<BoxShadow> shadows = [];
    TextDecoration? textDecoration;

    if (isCorrectZap) {
      itemColor = Colors.greenAccent.withValues(alpha: 0.15);
      borderColor = Colors.greenAccent;
      borderWidth = 2;
      textColor = Colors.greenAccent;
      shadows = [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.3), blurRadius: 15)];
    } else if (isWrongZap) {
      itemColor = Colors.redAccent.withValues(alpha: 0.15);
      borderColor = Colors.redAccent;
      borderWidth = 2;
      textColor = Colors.redAccent;
      shadows = [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.3), blurRadius: 15)];
      textDecoration = TextDecoration.lineThrough;
    } else if (isSuspected) {
      itemColor = Colors.orangeAccent.withValues(alpha: 0.15);
      borderColor = Colors.orangeAccent;
      borderWidth = 2;
      textColor = Colors.orangeAccent;
      shadows = [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.3), blurRadius: 10)];
    }

    return ScaleButton(
      onTap: () => _onWordTap(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: itemColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadows,
        ),
        child: Text(
          text, 
          style: GoogleFonts.fredoka(
            fontSize: 22.sp, 
            fontWeight: isCorrectZap || isWrongZap || isSuspected ? FontWeight.bold : FontWeight.normal,
            color: textColor,
            decoration: textDecoration,
          ),
        ),
      ),
    ).animate(target: isSuspected ? 1 : 0)
     .shimmer(duration: 400.ms, color: isCorrectZap ? Colors.greenAccent : (isWrongZap ? Colors.redAccent : Colors.orangeAccent))
     .shake(duration: 300.ms, hz: isWrongZap ? 10 : 0)
     .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 200.ms, curve: Curves.easeOutBack);
  }

  Widget _buildDiagnosticStatus(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10.r, height: 10.r,
          decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(begin: const Offset(1, 1), end: const Offset(1.8, 1.8), duration: 1.seconds)
         .shimmer(color: primaryColor),
        SizedBox(width: 14.w),
        Text(
          "SCANNER ARMED: SEEKING GLITCHES", 
          style: GoogleFonts.outfit(
            fontSize: 10.sp, 
            fontWeight: FontWeight.w900, 
            color: primaryColor, 
            letterSpacing: 2
          )
        ),
      ],
    );
  }

  Widget _buildOptionsPanel(Color primaryColor, bool isDark, GrammarQuest quest, List<String> words) {
    final isOptionSelected = _selectedOption != null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(22.r),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: primaryColor.withValues(alpha: 0.15), width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              "GLITCH IDENTIFIED: CHOOSE THE CORRECTION",
              style: GoogleFonts.outfit(
                fontSize: 11.sp,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 20.h),
            
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              alignment: WrapAlignment.center,
              children: (_shuffledOptions ?? []).map((option) {
                final isThisSelected = _selectedOption == option;
                
                return ScaleButton(
                  onTap: _isAnswered ? null : () {
                    _hapticService.selection();
                    setState(() {
                      _selectedOption = option;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isThisSelected
                          ? primaryColor.withValues(alpha: 0.15)
                          : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: isThisSelected ? primaryColor : primaryColor.withValues(alpha: 0.1),
                        width: isThisSelected ? 2 : 1,
                      ),
                      boxShadow: isThisSelected
                          ? [BoxShadow(color: primaryColor.withValues(alpha: 0.2), blurRadius: 10)]
                          : [],
                    ),
                    child: Text(
                      option,
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isThisSelected
                            ? primaryColor
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            SizedBox(height: 28.h),
            
            if (!_isAnswered)
              ScaleButton(
                onTap: !isOptionSelected
                    ? null
                    : () => _confirmRepair(_getCorrectIndices(words, quest), quest, words),
                child: Container(
                  width: double.infinity,
                  height: 58.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    gradient: LinearGradient(
                      colors: !isOptionSelected
                          ? [Colors.grey.withValues(alpha: 0.3), Colors.grey.withValues(alpha: 0.4)]
                          : [primaryColor, primaryColor.withValues(alpha: 0.8)],
                    ),
                    boxShadow: !isOptionSelected
                        ? []
                        : [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Center(
                    child: Text(
                      "EXECUTE REPAIR",
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: !isOptionSelected
                            ? (isDark ? Colors.white30 : Colors.black26)
                            : Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCorrectionFeed(String correction, Color primaryColor) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            "GLITCH RESOLUTION", 
            style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 1.5)
          ),
          SizedBox(height: 8.h),
          Text(
            "Correction: $correction", 
            style: GoogleFonts.fredoka(fontSize: 18.sp, color: Colors.redAccent, fontWeight: FontWeight.w600)
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}
