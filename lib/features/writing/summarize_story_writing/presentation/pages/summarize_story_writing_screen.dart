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

class _SummarizeStoryWritingScreenState extends State<SummarizeStoryWritingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final List<String> _summaryFrames = [];
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

  void _onDropFrame(String frame) {
    if (_isAnswered) return;
    _hapticService.success();
    setState(() => _summaryFrames.add(frame));
  }

  void _onCrank(double delta) {
    if (_isAnswered || _summaryFrames.length < 3) return;
    setState(() {
      _crankProgress = (_crankProgress + delta / 500).clamp(0.0, 1.0);
    });
    if (_crankProgress >= 1.0) _submitAnswer();
  }

  void _submitAnswer() {
    if (_isAnswered) return;
    _hapticService.success();
    _soundService.playCorrect();
    setState(() { _isAnswered = true; _isCorrect = true; });
    context.read<WritingBloc>().add(SubmitAnswer(true));
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
              _summaryFrames.clear();
              _crankProgress = 0.0;
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
        final quest = (state is WritingLoaded) ? state.currentQuest : null;
        final options = ["THE BRAVE HERO", "DARKEST NIGHT", "A HIDDEN TRUTH", "TRIUMPHANT END", "LOST JOURNEY"];

        return WritingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 24.h),
              _buildStoryManuscript(quest.story ?? "", theme.primaryColor, isDark),
              const Spacer(),
              _buildFilmStrip(_summaryFrames, theme.primaryColor),
              SizedBox(height: 32.h),
              _buildFrameVault(options, theme.primaryColor),
              SizedBox(height: 32.h),
              if (_summaryFrames.length >= 3 && !_isAnswered)
                _buildProjectorCrank(theme.primaryColor),
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
      constraints: BoxConstraints(maxHeight: 200.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        image: DecorationImage(image: const NetworkImage('https://www.transparenttextures.com/patterns/cream-paper.png'), opacity: 0.05, repeat: ImageRepeat.repeat),
      ),
      child: SingleChildScrollView(child: Text(story, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 16.sp, color: isDark ? Colors.white70 : Colors.black87, height: 1.5))),
    );
  }

  Widget _buildFilmStrip(List<String> frames, Color color) {
    return Container(
      height: 100.h, width: double.infinity,
      decoration: BoxDecoration(color: Colors.black, border: Border.symmetric(horizontal: BorderSide(color: color.withValues(alpha: 0.3), width: 4))),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(10, (i) => Container(width: 10.w, height: 10.h, decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle)))),
          DragTarget<String>(
            onAcceptWithDetails: (details) => _onDropFrame(details.data),
            builder: (context, candidateData, rejectedData) {
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: frames.length + 1,
                itemBuilder: (context, i) {
                  if (i == frames.length) return Container(width: 120.w, margin: EdgeInsets.all(10.r), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8.r), border: Border.all(color: color.withValues(alpha: 0.2), style: BorderStyle.none)));
                  return Container(
                    width: 120.w, margin: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r), border: Border.all(color: color)),
                    child: Center(child: Text(frames[i], textAlign: TextAlign.center, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 10.sp))),
                  ).animate().scale().fadeIn();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFrameVault(List<String> options, Color color) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((o) => Draggable<String>(
          data: o,
          feedback: Material(color: Colors.transparent, child: Container(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20.r)), child: Text(o, style: GoogleFonts.shareTechMono(color: Colors.white)))),
          child: Container(margin: EdgeInsets.only(right: 12.w), padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.3))), child: Text(o, style: GoogleFonts.shareTechMono(color: color, fontSize: 10.sp))),
        )).toList(),
      ),
    );
  }

  Widget _buildProjectorCrank(Color color) {
    return GestureDetector(
      onPanUpdate: (details) => _onCrank(details.delta.dx + details.delta.dy),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: 200.h),
            decoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle, border: Border.all(color: color, width: 3), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20)]),
            child: Transform.rotate(angle: _crankProgress * 10, child: Icon(Icons.settings_backup_restore_rounded, color: color, size: 40.r)),
          ),
          SizedBox(height: 12.h),
          Text("CRANK TO PROJECT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
          SizedBox(height: 8.h),
          Container(width: 100.w, height: 4.h, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2.r)), child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: 100.w * _crankProgress, child: ColoredBox(color: color)))),
        ],
      ),
    ).animate().fadeIn().scale();
  }
}
