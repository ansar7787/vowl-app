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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';

class SummarizeStoryWritingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SummarizeStoryWritingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.summarizeStoryWriting,
  });

  @override
  State<SummarizeStoryWritingScreen> createState() => _SummarizeStoryWritingScreenState();
}

class _DescribeFrameSlot {
  final int index;
  String? sentence;
  _DescribeFrameSlot({required this.index});
}

class _SummarizeStoryWritingScreenState extends State<SummarizeStoryWritingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final List<_DescribeFrameSlot> _slots = [
    _DescribeFrameSlot(index: 0),
    _DescribeFrameSlot(index: 1),
    _DescribeFrameSlot(index: 2),
  ];
  
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  double _crankProgress = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onDropFrame(int slotIdx, String sentence) {
    if (_isAnswered) return;
    _hapticService.success();
    setState(() {
      _slots[slotIdx].sentence = sentence;
    });
  }

  void _removeFrame(int slotIdx) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _slots[slotIdx].sentence = null;
      _crankProgress = 0.0;
    });
  }

  void _onCrank(double delta) {
    if (_isAnswered) return;
    
    // Require all 3 slots filled to crank
    final isSlotsFilled = _slots.every((s) => s.sentence != null);
    if (!isSlotsFilled) return;

    setState(() {
      _crankProgress = (_crankProgress + delta.abs() / 450).clamp(0.0, 1.0);
    });
    
    if (_crankProgress % 0.15 < 0.02) {
      _hapticService.selection();
    }

    if (_crankProgress >= 1.0) {
      _submitAnswer();
    }
  }

  void _submitAnswer() {
    if (_isAnswered) return;
    
    final WritingQuest? quest = (context.read<WritingBloc>().state as WritingLoaded).currentQuest as WritingQuest?;
    if (quest == null) return;
    
    final options = quest.options ?? [];
    final correctIndices = quest.correctOrder ?? [0, 1, 2];
    
    // Check if the sentences dropped in slots match correct order index strings
    bool isAllCorrect = true;
    for (int i = 0; i < 3; i++) {
      final slotSentence = _slots[i].sentence;
      final targetIdx = correctIndices[i];
      final targetSentence = options[targetIdx];
      
      if (slotSentence != targetSentence) {
        isAllCorrect = false;
        break;
      }
    }

    if (isAllCorrect) {
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
            _crankProgress = 0.0;
            for (var slot in _slots) {
              slot.sentence = null;
            }
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
              _crankProgress = 0.0;
              for (var slot in _slots) {
                slot.sentence = null;
              }
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'DIGEST MASTER!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final WritingQuest? quest = (state is WritingLoaded) ? state.currentQuest as WritingQuest? : null;
        
        final options = quest?.options ?? [];
        final isSlotsFilled = _slots.every((s) => s.sentence != null);

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
                  
                  _buildStoryManuscript(quest.story ?? "", theme.primaryColor, isDark),
                  SizedBox(height: 24.h),
                  
                  _buildFilmStrip(_slots, theme.primaryColor, isDark),
                  SizedBox(height: 24.h),
                  
                  _buildFrameVault(options, theme.primaryColor, isDark),
                  SizedBox(height: 32.h),
                  
                  if (isSlotsFilled && !_isAnswered)
                    _buildProjectorCrank(theme.primaryColor, isDark),
                  
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
          Icon(Icons.videocam_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("SEQUENCE THE KEY FRAMES TO PROJECT THE TRUTH", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildStoryManuscript(String story, Color color, bool isDark) {
    return Container(
      constraints: BoxConstraints(maxHeight: 180.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Stack(
        children: [
          const TechPatternOverlay(opacity: 0.05),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Text(
              story, 
              textAlign: TextAlign.center, 
              style: GoogleFonts.fredoka(
                fontSize: 16.sp, 
                color: isDark ? Colors.white70 : Colors.black87, 
                height: 1.5,
                fontWeight: FontWeight.bold
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilmStrip(List<_DescribeFrameSlot> slots, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.black, 
        border: Border.symmetric(
          horizontal: BorderSide(color: color.withValues(alpha: 0.3), width: 4)
        )
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, 
            children: List.generate(8, (i) => Container(
              width: 8.w, height: 8.h, 
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle)
            ))
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: slots.map((slot) => DragTarget<String>(
              onAcceptWithDetails: (details) => _onDropFrame(slot.index, details.data),
              builder: (context, candidateData, rejectedData) {
                final text = slot.sentence;
                return GestureDetector(
                  onTap: () => _removeFrame(slot.index),
                  child: Container(
                    width: 100.w, height: 90.h,
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: text != null ? color.withValues(alpha: 0.15) : Colors.white10,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: text != null ? color : (candidateData.isNotEmpty ? color.withValues(alpha: 0.5) : Colors.white24),
                        width: 2
                      ),
                    ),
                    child: Center(
                      child: Text(
                        text ?? "[SLOT ${slot.index + 1}]",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.shareTechMono(
                          color: text != null ? Colors.white : Colors.white30,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold
                        )
                      )
                    ),
                  ).animate(target: text != null ? 1 : 0).scale().fadeIn(),
                );
              },
            )).toList(),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, 
            children: List.generate(8, (i) => Container(
              width: 8.w, height: 8.h, 
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle)
            ))
          ),
        ],
      ),
    );
  }

  Widget _buildFrameVault(List<String> options, Color color, bool isDark) {
    // Only display options that are not currently slotted
    final slottedSentences = _slots.map((s) => s.sentence).toSet();
    final availableOptions = options.filter((o) => !slottedSentences.contains(o)).toList();

    return Container(
      constraints: BoxConstraints(minHeight: 60.h),
      child: Wrap(
        spacing: 10.w, runSpacing: 10.h,
        alignment: WrapAlignment.center,
        children: availableOptions.map((o) => Draggable<String>(
          data: o,
          feedback: Material(
            color: Colors.transparent, 
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h), 
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20.r)), 
              child: Text(
                o, 
                style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold)
              )
            )
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h), 
            decoration: BoxDecoration(
              color: isDark ? Colors.black87 : Colors.white, 
              borderRadius: BorderRadius.circular(20.r), 
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: isDark ? 0.35 : 0.15), blurRadius: 6)
              ],
            ), 
            child: Text(
              o, 
              textAlign: TextAlign.center,
              style: GoogleFonts.shareTechMono(
                color: isDark ? Colors.white : Colors.black87, 
                fontSize: 10.sp,
                fontWeight: FontWeight.bold
              )
            )
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildProjectorCrank(Color color, bool isDark) {
    return GestureDetector(
      onPanUpdate: (details) => _onCrank(details.delta.dx + details.delta.dy),
      child: Column(
        children: [
          Container(
            width: 80.r, height: 80.r,
            decoration: BoxDecoration(
              color: isDark ? Colors.black87 : Colors.white, 
              shape: BoxShape.circle, 
              border: Border.all(color: color, width: 3), 
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20)]
            ),
            child: Transform.rotate(
              angle: _crankProgress * 10, 
              child: Icon(Icons.settings_backup_restore_rounded, color: color, size: 36.r)
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "SPIN TO PROJECT SUMMARY", 
            style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)
          ),
          SizedBox(height: 8.h),
          Container(
            width: 120.w, height: 5.h, 
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2.r)), 
            child: Align(
              alignment: Alignment.centerLeft, 
              child: SizedBox(
                width: 120.w * _crankProgress, 
                child: ColoredBox(color: color)
              )
            )
          ),
        ],
      ),
    ).animate().fadeIn().scale();
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
extension _ListFilter<E> on Iterable<E> {
  Iterable<E> filter(bool Function(E element) test) => where(test);
}
