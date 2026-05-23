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

class CorrectionWritingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const CorrectionWritingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.correctionWriting,
  });

  @override
  State<CorrectionWritingScreen> createState() => _CorrectionWritingScreenState();
}

class _CorrectionWritingScreenState extends State<CorrectionWritingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  String? _selectedCorrection;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onSelectCorrection(String choice) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _selectedCorrection = choice;
    });
  }

  void _submitAnswer() {
    final WritingQuest? quest = (context.read<WritingBloc>().state as WritingLoaded).currentQuest as WritingQuest?;
    if (quest == null || _isAnswered || _selectedCorrection == null) return;
    
    final bool correct = _selectedCorrection == quest.correctAnswer;

    if (correct) {
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
      
      Future.delayed(1.5.seconds, () {
        if (mounted) {
          setState(() {
            _isAnswered = false;
            _isCorrect = null;
            _selectedCorrection = null;
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
              _selectedCorrection = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SYNTAX AUDITOR!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final WritingQuest? quest = (state is WritingLoaded) ? state.currentQuest as WritingQuest? : null;
        
        final options = quest?.options ?? [];

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
                  
                  _buildSentenceCard(quest.passage ?? "", theme.primaryColor, isDark),
                  SizedBox(height: 32.h),
                  
                  _buildCorrectionVault(options, theme.primaryColor, isDark),
                  SizedBox(height: 36.h),
                  
                  if (!_isAnswered)
                    ScaleButton(
                      onTap: _selectedCorrection != null ? _submitAnswer : null,
                      child: Container(
                        width: double.infinity, height: 60.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r), 
                          color: _selectedCorrection != null ? theme.primaryColor : Colors.grey, 
                          boxShadow: [
                            if (_selectedCorrection != null) 
                              BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 15)
                          ]
                        ),
                        child: Center(
                          child: Text(
                            "AUDIT SYNTAX", 
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
          Text("IDENTIFY AND REPLACE THE ERRORED SYNTAX PHRASE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSentenceCard(String passage, Color color, bool isDark) {
    // Parse sentence containing square brackets e.g. "Each of the [are ready] for Mariana"
    final startIdx = passage.indexOf('[');
    final endIdx = passage.indexOf(']');
    
    if (startIdx == -1 || endIdx == -1) {
      return Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Text(
          passage,
          style: GoogleFonts.spectral(
            fontSize: 16.sp,
            color: isDark ? Colors.white : Colors.black87,
            height: 1.6,
          ),
        ),
      );
    }
    
    final preText = passage.substring(0, startIdx);
    final errorText = passage.substring(startIdx + 1, endIdx);
    final postText = passage.substring(endIdx + 1);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 2),
      ),
      child: Stack(
        children: [
          const TechPatternOverlay(opacity: 0.05),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.spectral(
                fontSize: 16.sp,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.6,
                fontWeight: FontWeight.w500
              ),
              children: [
                TextSpan(text: preText),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: AnimatedContainer(
                    duration: 300.milliseconds,
                    margin: EdgeInsets.symmetric(horizontal: 8.w),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: _selectedCorrection != null 
                        ? Colors.greenAccent.withValues(alpha: 0.1) 
                        : Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _selectedCorrection != null ? Colors.greenAccent : Colors.redAccent,
                        width: 2,
                        style: _selectedCorrection != null ? BorderStyle.solid : BorderStyle.none
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCorrection ?? errorText.toUpperCase(),
                          style: GoogleFonts.shareTechMono(
                            fontSize: 14.sp,
                            color: _selectedCorrection != null ? Colors.greenAccent : Colors.redAccent,
                            fontWeight: FontWeight.bold
                          )
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          _selectedCorrection != null ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                          size: 14.r,
                          color: _selectedCorrection != null ? Colors.greenAccent : Colors.redAccent,
                        )
                      ],
                    ),
                  ),
                ),
                TextSpan(text: postText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionVault(List<String> options, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "AVAILABLE SYNTACTIC CORRECTIONS",
          style: GoogleFonts.shareTechMono(fontSize: 10.sp, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)
        ),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 12.w, runSpacing: 12.h,
          alignment: WrapAlignment.center,
          children: options.map((opt) {
            final bool isSelected = _selectedCorrection == opt;
            final displayColor = isSelected ? color : (isDark ? Colors.white24 : Colors.black26);

            return GestureDetector(
              onTap: () => _onSelectCorrection(opt),
              child: AnimatedContainer(
                duration: 200.milliseconds,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : (isDark ? Colors.black45 : Colors.white),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: displayColor, width: 2),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: isSelected ? 0.35 : 0.08), blurRadius: 8)
                  ],
                ),
                child: Text(
                  opt,
                  style: GoogleFonts.shareTechMono(
                    color: isSelected ? color : (isDark ? Colors.white70 : Colors.black87),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
