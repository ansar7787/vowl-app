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

class SentenceBuilderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SentenceBuilderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.sentenceBuilder,
  });

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final List<String> _assembledPieces = [];
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

  void _onSnap(String piece) {
    if (_isAnswered) return;
    _hapticService.success();
    setState(() => _assembledPieces.add(piece));
  }

  void _onRemovePiece(int index) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() => _assembledPieces.removeAt(index));
  }

  void _submitAnswer(String correct) {
    if (_isAnswered || _assembledPieces.isEmpty) return;
    
    String built = _assembledPieces.join(' ').trim().toLowerCase();
    String normalizedCorrect = correct.trim().toLowerCase();
    
    bool isCorrect = built == normalizedCorrect;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<WritingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<WritingBloc>().add(SubmitAnswer(false));
      Future.delayed(1.seconds, () {
        if (mounted) {
          setState(() {
            _assembledPieces.clear();
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
              _assembledPieces.clear();
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SYNTAX ARCHITECT!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is WritingLoaded) ? state.currentQuest : null;
        final pool = quest?.shuffledWords ?? [];
        
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
                  
                  _buildWorkbench(theme.primaryColor, isDark),
                  SizedBox(height: 32.h),
                  
                  _buildPiecePool(pool, theme.primaryColor, isDark),
                  
                  if (_isAnswered) ...[
                    SizedBox(height: 30.h),
                    _buildCorrectResult(quest, theme.primaryColor, isDark),
                  ],
                  
                  SizedBox(height: 40.h),
                  if (!_isAnswered)
                    ScaleButton(
                      onTap: () => _submitAnswer(quest.correctAnswer ?? ""),
                      child: Container(
                        width: double.infinity, height: 56.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r), 
                          color: theme.primaryColor, 
                          boxShadow: [
                            BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 15)
                          ]
                        ),
                        child: Center(
                          child: Text(
                            "POLISH SENTENCE", 
                            style: GoogleFonts.outfit(
                              fontSize: 14.sp, 
                              fontWeight: FontWeight.w900, 
                              color: Colors.white, 
                              letterSpacing: 2
                            )
                          )
                        ),
                      ),
                    ),
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
          Icon(Icons.carpenter_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("ASSEMBLE THE JIGSAW OF LOGIC", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildWorkbench(Color color, bool isDark) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => _onSnap(details.data),
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 110.h),
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.05 : 0.08),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: candidateData.isNotEmpty ? color : (isDark ? Colors.white10 : Colors.black12), width: 2),
          ),
          child: Wrap(
            spacing: 8.w, runSpacing: 8.h,
            children: _assembledPieces.asMap().entries.map((e) => _buildJigsawPiece(e.value, true, () => _onRemovePiece(e.key), color, isDark)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPiecePool(List<String> pool, Color color, bool isDark) {
    final available = pool.where((p) {
      int countInAssembled = _assembledPieces.where((a) => a == p).length;
      int countInOriginal = pool.where((o) => o == p).length;
      return countInAssembled < countInOriginal;
    }).toList();

    return Wrap(
      spacing: 10.w, runSpacing: 10.h, alignment: WrapAlignment.center,
      children: available.map((p) => Draggable<String>(
        data: p,
        feedback: Material(color: Colors.transparent, child: _buildJigsawPiece(p, false, null, color, isDark, isDragging: true)),
        childWhenDragging: Opacity(opacity: 0.3, child: _buildJigsawPiece(p, false, null, color, isDark)),
        child: _buildJigsawPiece(p, false, null, color, isDark),
      )).toList(),
    );
  }

  Widget _buildJigsawPiece(String text, bool isAssembled, VoidCallback? onTap, Color color, bool isDark, {bool isDragging = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isAssembled 
              ? color.withValues(alpha: 0.25) 
              : (isDark ? Colors.black45 : Colors.white),
          border: Border.all(
            color: isAssembled 
                ? color 
                : (isDark ? Colors.white24 : Colors.black12), 
            width: 2
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8.r),
            bottomLeft: Radius.circular(8.r),
            topRight: Radius.circular(20.r),
            bottomRight: Radius.circular(20.r),
          ),
          boxShadow: [
            if (isDragging || isAssembled) 
              BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text, 
              style: GoogleFonts.outfit(
                fontSize: 14.sp, 
                fontWeight: FontWeight.bold, 
                color: isDark ? Colors.white : Colors.black87
              )
            ),
            if (!isAssembled) ...[
              SizedBox(width: 8.w),
              Icon(
                Icons.extension_rounded, 
                size: 14.r, 
                color: isDark ? Colors.white24 : Colors.black26
              ),
            ],
          ],
        ),
      ),
    ).animate(target: isAssembled ? 1 : 0).shimmer(duration: 1.seconds);
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
