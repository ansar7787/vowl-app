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

class FixTheSentenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const FixTheSentenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.fixTheSentence,
  });

  @override
  State<FixTheSentenceScreen> createState() => _FixTheSentenceScreenState();
}

class _FixTheSentenceScreenState extends State<FixTheSentenceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final List<Offset> _erasePoints = [];
  bool _isWiped = false;
  String? _selectedOption;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  int _erasedAmount = 0;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onErase(Offset localPosition) {
    if (_isAnswered || _isWiped) return;
    setState(() {
      _erasePoints.add(localPosition);
      _erasedAmount++;
      if (_erasedAmount % 6 == 0) _hapticService.selection();
    });
    
    if (_erasedAmount > 35) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() => _isWiped = true);
    }
  }

  void _selectReplacement(String selected, String correct) {
    if (_isAnswered) return;
    
    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = true; 
        _selectedOption = selected; 
      });
      context.read<WritingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false; 
        _selectedOption = selected;
      });
      context.read<WritingBloc>().add(SubmitAnswer(false));
      Future.delayed(1.seconds, () {
        if (mounted) {
          setState(() {
            _isAnswered = false;
            _isCorrect = null;
            _selectedOption = null;
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
              _isWiped = false;
              _selectedOption = null;
              _erasePoints.clear();
              _erasedAmount = 0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SYNTAX SURGEON!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final WritingQuest? quest = (state is WritingLoaded) ? state.currentQuest as WritingQuest? : null;
        
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
                  SizedBox(height: 32.h),
                  
                  _buildDigitalBlackboard(
                    quest.passage ?? "", 
                    quest.missingWord ?? "", 
                    _selectedOption,
                    theme.primaryColor, 
                    isDark
                  ),
                  SizedBox(height: 32.h),
                  
                  if (_isWiped && !_isAnswered) ...[
                    _buildWipedAlert(theme.primaryColor),
                    SizedBox(height: 20.h),
                    _buildCorrectionOptions(quest.options ?? [], quest.correctAnswer ?? "", theme.primaryColor, isDark),
                  ],
                  
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
          Icon(Icons.auto_fix_normal_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(_isWiped ? "SELECT THE CORRECT REPLACEMENT WORD" : "SCRUB AWAY THE LOGICAL DECAY", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildDigitalBlackboard(String fullText, String targetWord, String? selectedReplacement, Color color, bool isDark) {
    final parts = fullText.split(targetWord);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const TechPatternOverlay(opacity: 0.05),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white70 : Colors.black87, height: 1.5),
                children: [
                  if (parts.isNotEmpty) TextSpan(text: parts[0]),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _isWiped 
                        ? Container(
                            margin: EdgeInsets.symmetric(horizontal: 8.w),
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: selectedReplacement != null 
                                  ? Colors.greenAccent.withValues(alpha: 0.25)
                                  : (isDark ? Colors.white12 : Colors.black12),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: selectedReplacement != null ? Colors.greenAccent : (isDark ? Colors.white30 : Colors.black26), width: 2),
                            ),
                            child: Text(
                              selectedReplacement?.toUpperCase() ?? "____",
                              style: GoogleFonts.shareTechMono(
                                fontSize: 13.sp, 
                                fontWeight: FontWeight.w900,
                                color: selectedReplacement != null 
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : (isDark ? Colors.white30 : Colors.black38)
                              )
                            ),
                          )
                        : GestureDetector(
                            onPanUpdate: (details) => _onErase(details.localPosition),
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 8.w),
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(color: color, width: 2),
                              ),
                              child: Stack(
                                children: [
                                  Text(
                                    targetWord.toUpperCase(),
                                    style: GoogleFonts.shareTechMono(fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.redAccent)
                                  ),
                                  if (_erasePoints.isNotEmpty)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: ScratchOverlayPainter(points: _erasePoints),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  if (parts.length > 1) TextSpan(text: parts[1]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWipedAlert(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 16.r),
          SizedBox(width: 8.w),
          Text(
            "DECAY WIPED! CHOOSE REPLACEMENT CELL",
            style: GoogleFonts.shareTechMono(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.greenAccent)
          ),
        ],
      ),
    ).animate().shimmer(duration: 1.5.seconds);
  }

  Widget _buildCorrectionOptions(List<String> options, String correct, Color color, bool isDark) {
    return Wrap(
      spacing: 12.w, runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: options.map((o) {
        return ScaleButton(
          onTap: () => _selectReplacement(o, correct),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? Colors.black87 : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: isDark ? 0.35 : 0.15), blurRadius: 8)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 14.r, color: color),
                SizedBox(width: 8.w),
                Text(
                  o.toUpperCase(),
                  style: GoogleFonts.shareTechMono(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
                ),
              ],
            ),
          ),
        );
      }).toList(),
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

class ScratchOverlayPainter extends CustomPainter {
  final List<Offset> points;
  ScratchOverlayPainter({required this.points});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.85)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (var p in points) {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
