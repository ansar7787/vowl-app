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

class OpinionWritingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const OpinionWritingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.opinionWriting,
  });

  @override
  State<OpinionWritingScreen> createState() => _OpinionWritingScreenState();
}

class _OpinionWritingScreenState extends State<OpinionWritingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final List<String> _leftPanArgs = [];
  final List<String> _rightPanArgs = [];
  
  double _scaleRotation = 0.0;
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

  void _onDropArg(String arg, bool isLeft) {
    if (_isAnswered) return;
    
    _hapticService.success();
    setState(() {
      // Remove from opposite pan if dragged from there
      _leftPanArgs.remove(arg);
      _rightPanArgs.remove(arg);

      if (isLeft) {
        _leftPanArgs.add(arg);
      } else {
        _rightPanArgs.add(arg);
      }
      
      // Calculate imbalance: diff between pans affects rotation
      double diff = (_leftPanArgs.length - _rightPanArgs.length).toDouble();
      _scaleRotation = (diff * 0.1).clamp(-0.3, 0.3);
    });
  }

  void _removeArg(String arg, bool isLeft) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      if (isLeft) {
        _leftPanArgs.remove(arg);
      } else {
        _rightPanArgs.remove(arg);
      }
      
      double diff = (_leftPanArgs.length - _rightPanArgs.length).toDouble();
      _scaleRotation = (diff * 0.1).clamp(-0.3, 0.3);
    });
  }

  void _submitAnswer() {
    final WritingQuest? quest = (context.read<WritingBloc>().state as WritingLoaded).currentQuest as WritingQuest?;
    if (quest == null || _isAnswered) return;
    
    final options = quest.options ?? [];
    final correctProsIndices = quest.correctOrder ?? [0, 1];
    
    final correctPros = correctProsIndices.map((idx) => options[idx]).toSet();
    final correctCons = options.where((opt) => !correctPros.contains(opt)).toSet();

    // Verify left pan contains Pros and right contains Cons
    bool isLeftCorrect = _leftPanArgs.length == 2 && _leftPanArgs.every((arg) => correctPros.contains(arg));
    bool isRightCorrect = _rightPanArgs.length == 2 && _rightPanArgs.every((arg) => correctCons.contains(arg));

    if (isLeftCorrect && isRightCorrect) {
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
            _leftPanArgs.clear();
            _rightPanArgs.clear();
            _scaleRotation = 0.0;
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
              _leftPanArgs.clear();
              _rightPanArgs.clear();
              _scaleRotation = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'LOGIC MASTER!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final WritingQuest? quest = (state is WritingLoaded) ? state.currentQuest as WritingQuest? : null;
        
        final options = quest?.options ?? [];
        final totalPlaced = _leftPanArgs.length + _rightPanArgs.length;

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
                  
                  _buildThesisCard(quest.prompt ?? "", theme.primaryColor, isDark),
                  SizedBox(height: 24.h),
                  
                  _buildScaleInterface(theme.primaryColor, isDark),
                  SizedBox(height: 32.h),
                  
                  _buildArgumentStones(options, theme.primaryColor, isDark),
                  SizedBox(height: 36.h),
                  
                  if (!_isAnswered)
                    ScaleButton(
                      onTap: totalPlaced == 4 ? _submitAnswer : null,
                      child: Container(
                        width: double.infinity, height: 60.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r), 
                          color: totalPlaced == 4 ? theme.primaryColor : Colors.grey, 
                          boxShadow: [
                            if (totalPlaced == 4) 
                              BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 15)
                          ]
                        ),
                        child: Center(
                          child: Text(
                            "BALANCE THE TRUTH", 
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
          Icon(Icons.balance_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("WEIGH YOUR ARGUMENTS ON THE SCALE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildThesisCard(String text, Color color, bool isDark) {
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
          Text(
            text, 
            textAlign: TextAlign.center, 
            style: GoogleFonts.outfit(
              fontSize: 16.sp, 
              fontWeight: FontWeight.w800, 
              color: isDark ? Colors.white : Colors.black87,
              height: 1.4
            )
          ),
        ],
      ),
    );
  }

  Widget _buildScaleInterface(Color color, bool isDark) {
    return SizedBox(
      height: 250.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Pivot Base
          Positioned(
            bottom: 0,
            child: Container(
              width: 12.w, height: 160.h, 
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.5), color],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter
                ), 
                borderRadius: BorderRadius.vertical(top: Radius.circular(6.r))
              )
            )
          ),
          // The Beam
          AnimatedRotation(
            duration: 600.milliseconds, curve: Curves.elasticOut,
            turns: _scaleRotation / (2 * 3.14159),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280.w, height: 10.h,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5.r), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20)]),
                ),
                Positioned(
                  left: 0,
                  child: _buildPan(true, color, isDark),
                ),
                Positioned(
                  right: 0,
                  child: _buildPan(false, color, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPan(bool isLeft, Color color, bool isDark) {
    final args = isLeft ? _leftPanArgs : _rightPanArgs;
    
    return DragTarget<String>(
      onAcceptWithDetails: (details) => _onDropArg(details.data, isLeft),
      builder: (context, candidateData, rejectedData) {
        final highlight = candidateData.isNotEmpty;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rope chains holding the pan
            Container(width: 2.w, height: 40.h, color: color.withValues(alpha: 0.4)),
            Container(
              width: 125.w, 
              constraints: BoxConstraints(minHeight: 100.h),
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: isDark ? Colors.black87 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: highlight ? Colors.greenAccent : color.withValues(alpha: args.isNotEmpty ? 0.8 : 0.2), 
                  width: 2
                ),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: isDark ? 0.3 : 0.08), blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isLeft ? "PROS" : "CONS",
                    style: GoogleFonts.shareTechMono(
                      color: isLeft ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold
                    )
                  ),
                  Divider(color: color.withValues(alpha: 0.15), height: 8.h),
                  if (args.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Text(
                        "Drag argument here",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.shareTechMono(
                          color: isDark ? Colors.white24 : Colors.black26,
                          fontSize: 9.sp
                        )
                      ),
                    ),
                  Wrap(
                    spacing: 4.w, runSpacing: 4.h,
                    children: args.map((a) => GestureDetector(
                      onTap: () => _removeArg(a, isLeft),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1), 
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: color.withValues(alpha: 0.3))
                        ),
                        child: Text(
                          a,
                          style: GoogleFonts.shareTechMono(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ).animate().scale().fadeIn(),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildArgumentStones(List<String> options, Color color, bool isDark) {
    // Only display options that are not currently slotted on either pan
    final placed = _leftPanArgs.toSet()..addAll(_rightPanArgs);
    final availableOptions = options.where((o) => !placed.contains(o)).toList();

    return Container(
      constraints: BoxConstraints(minHeight: 80.h),
      child: Wrap(
        spacing: 10.w, runSpacing: 10.h,
        alignment: WrapAlignment.center,
        children: availableOptions.map((o) => Draggable<String>(
          data: o,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: 140.w,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: color, 
                borderRadius: BorderRadius.circular(16.r), 
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20)]
              ),
              child: Text(
                o, 
                style: GoogleFonts.shareTechMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.sp)
              )
            )
          ),
          child: Container(
            width: 140.w,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isDark ? Colors.black87 : Colors.white, 
              borderRadius: BorderRadius.circular(16.r), 
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: isDark ? 0.35 : 0.15), blurRadius: 6)
              ],
            ),
            child: Text(
              o, 
              textAlign: TextAlign.center,
              style: GoogleFonts.shareTechMono(
                color: isDark ? Colors.white70 : Colors.black87, 
                fontWeight: FontWeight.bold, 
                fontSize: 9.sp
              )
            ),
          ),
        )).toList(),
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
