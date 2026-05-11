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

class TravelDeskScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const TravelDeskScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.travelDesk,
  });

  @override
  State<TravelDeskScreen> createState() => _TravelDeskScreenState();
}

class _TravelDeskScreenState extends State<TravelDeskScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  int _lastProcessedIndex = -1;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  Offset _stampOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onStampUpdate(DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _stampOffset += details.delta;
    });
    _hapticService.selection();
  }

  void _onStampEnd(int correctIndex) {
    if (_isAnswered) return;
    
    // Check if stamp is over a page
    int? detectedIndex;
    if (_stampOffset.dy > 100.h) {
      if (_stampOffset.dx < -50.w) {
        detectedIndex = 0;
      } else if (_stampOffset.dx > 50.w) {
        detectedIndex = 1;
      } else {
        detectedIndex = 2;
      }
    }

    if (detectedIndex != null) {
      _submitStamp(detectedIndex, correctIndex);
    } else {
      setState(() {
        _stampOffset = Offset.zero;
      });
    }
  }

  void _submitStamp(int index, int correct) {
    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
      _isCorrect = index == correct;
    });

    if (_isCorrect!) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
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
              _stampOffset = Offset.zero;
            });
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'GLOBAL TRAVELER!', enableDoubleUp: true);
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
              _buildCustomsHeader(quest.prompt ?? "", theme.primaryColor, isDark),
              _buildPassportPages(options, theme.primaryColor, isDark),
              if (!_isAnswered) _buildMechanicalStamp(theme.primaryColor, quest.correctAnswerIndex ?? 0),
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
        child: Text("SLAM THE STAMP ONTO THE CORRECT PASSPORT PAGE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildCustomsHeader(String prompt, Color color, bool isDark) {
    return Positioned(
      top: 60.h,
      child: Column(
        children: [
          Icon(Icons.flight_takeoff_rounded, color: color, size: 40.r),
          SizedBox(height: 12.h),
          Container(
            width: 0.85.sw,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.1))),
            child: Text(prompt, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white70 : Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildPassportPages(List<String> options, Color color, bool isDark) {
    return Positioned(
      bottom: 40.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(options.length, (i) => _buildPage(i, options[i], color, isDark)),
      ),
    );
  }

  Widget _buildPage(int index, String text, Color color, bool isDark) {
    bool isSelected = _selectedIndex == index;
    return Container(
      width: 110.w, height: 160.h,
      margin: EdgeInsets.symmetric(horizontal: 5.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.1), width: isSelected ? 3 : 1),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              children: [
                Icon(Icons.public_rounded, color: color.withValues(alpha: 0.2), size: 30.r),
                SizedBox(height: 12.h),
                Text(text.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.shareTechMono(fontSize: 12.sp, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (isSelected) Center(
            child: Icon(_isCorrect! ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded, color: _isCorrect! ? Colors.green : Colors.red, size: 60.r),
          ),
        ],
      ),
    );
  }

  Widget _buildMechanicalStamp(Color color, int correctIndex) {
    return Positioned(
      top: 0.5.sh - 100.h,
      child: GestureDetector(
        onPanUpdate: _onStampUpdate,
        onPanEnd: (_) => _onStampEnd(correctIndex),
        child: Transform.translate(
          offset: _stampOffset,
          child: Column(
            children: [
              Container(
                width: 60.r, height: 100.r,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10.r),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color, color.withValues(alpha: 0.7)]),
                  boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Icon(Icons.approval_rounded, color: Colors.white, size: 32.r),
              ),
              Container(width: 80.w, height: 10.h, decoration: BoxDecoration(color: color.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(5.r))),
            ],
          ),
        ),
      ),
    );
  }
}

