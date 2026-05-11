import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class JobInterviewScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const JobInterviewScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.jobInterview,
  });

  @override
  State<JobInterviewScreen> createState() => _JobInterviewScreenState();
}

class _JobInterviewScreenState extends State<JobInterviewScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  int _lastProcessedIndex = -1;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  double _mercuryLevel = 0.3;

  @override
  void initState() {
    super.initState();
    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onStoneFlick(int index, int correctIndex) {
    if (_isAnswered) return;
    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
      _isCorrect = index == correctIndex;
    });

    if (_isCorrect!) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() => _mercuryLevel = (_mercuryLevel + 0.2).clamp(0.0, 1.0));
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() => _mercuryLevel = (_mercuryLevel - 0.1).clamp(0.0, 1.0));
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listener: (context, state) {
        if (state is RoleplayLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
            });
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'HIRED!', enableDoubleUp: true);
        } else if (state is RoleplayGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];

        return RoleplayBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
          onHint: () => context.read<RoleplayBloc>().add(RoleplayHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildMercuryBar(theme.primaryColor),
              _buildQuestionDisplay(quest.interviewerQuestion ?? "", theme.primaryColor, isDark),
              _buildResponseArea(options, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Positioned(
      top: 10.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Text("FLICK THE RESPONSE STONE INTO THE MERCURY COLUMN", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildMercuryBar(Color color) {
    return Positioned(
      left: 20.w,
      top: 100.h,
      bottom: 200.h,
      child: Container(
        width: 30.w,
        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(15.r), border: Border.all(color: color.withValues(alpha: 0.1))),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AnimatedContainer(
              duration: 1.seconds,
              curve: Curves.elasticOut,
              width: 30.w,
              height: 400.h * _mercuryLevel,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color, color.withValues(alpha: 0.6)]),
                borderRadius: BorderRadius.circular(15.r),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionDisplay(String text, Color color, bool isDark) {
    return Positioned(
      top: 100.h,
      right: 20.w,
      left: 70.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_center_rounded, color: color, size: 24.r),
              SizedBox(width: 8.w),
              Text("CHIEF EXECUTIVE", style: GoogleFonts.shareTechMono(fontSize: 12.sp, color: color, letterSpacing: 1)),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.1))),
            child: Text(text, style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseArea(List<String> options, int correctIndex, Color color, bool isDark) {
    return Positioned(
      bottom: 40.h,
      left: 20.w,
      right: 20.w,
      child: Column(
        children: List.generate(options.length, (i) => _buildStone(i, options[i], correctIndex, color, isDark)),
      ),
    );
  }

  Widget _buildStone(int index, String text, int correctIndex, Color color, bool isDark) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ScaleButton(
        onTap: () => _onStoneFlick(index, correctIndex),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.diamond_rounded, color: isSelected ? Colors.white : color, size: 20.r),
              SizedBox(width: 12.w),
              Expanded(child: Text(text, style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)))),
            ],
          ),
        ),
      ),
    );
  }
}

