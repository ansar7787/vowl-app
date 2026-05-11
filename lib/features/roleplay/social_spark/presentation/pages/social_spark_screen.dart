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

class SocialSparkScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SocialSparkScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.socialSpark,
  });

  @override
  State<SocialSparkScreen> createState() => _SocialSparkScreenState();
}

class _SocialSparkScreenState extends State<SocialSparkScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  int _lastProcessedIndex = -1;
  final List<String> _currentOrder = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onStarTap(String word) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      if (_currentOrder.contains(word)) {
        _currentOrder.remove(word);
      } else {
        _currentOrder.add(word);
      }
    });
  }

  void _submitAnswer(String correctAnswer) {
    if (_isAnswered || _currentOrder.isEmpty) return;
    
    final result = _currentOrder.join(' ');
    bool isCorrect = result.trim().toLowerCase() == correctAnswer.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
      });
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
              _currentOrder.clear();
            });
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'CONVERSATION STARTER!', enableDoubleUp: true);
        } else if (state is RoleplayGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final words = quest?.shuffledWords ?? [];

        return RoleplayBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
          onHint: () => context.read<RoleplayBloc>().add(RoleplayHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildGalaxyField(theme.primaryColor),
              _buildConnectionMonitor(_currentOrder.join(' '), theme.primaryColor, isDark),
              _buildStarMap(words, theme.primaryColor, isDark),
              if (!_isAnswered && _currentOrder.isNotEmpty) _buildSparkButton(theme.primaryColor, quest.correctAnswer ?? ""),
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
        child: Text("CONNECT THE CONVERSATION STARS IN SEQUENCE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildGalaxyField(Color color) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: [color.withValues(alpha: 0.1), Colors.transparent]),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 5.seconds, color: color.withValues(alpha: 0.1)),
    );
  }

  Widget _buildConnectionMonitor(String text, Color color, bool isDark) {
    return Positioned(
      top: 60.h,
      child: Container(
        width: 0.85.sw,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.1))),
        child: Column(
          children: [
            Text("CONSTELLATION STATUS", style: GoogleFonts.shareTechMono(fontSize: 10.sp, color: color, letterSpacing: 2)),
            SizedBox(height: 24.h),
            Text(text.isEmpty ? "WAITING FOR INPUT..." : text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildStarMap(List<String> words, Color color, bool isDark) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20.w,
        runSpacing: 20.h,
        children: words.map((w) => _buildConversationStar(w, color, isDark)).toList(),
      ),
    );
  }

  Widget _buildConversationStar(String text, Color color, bool isDark) {
    bool isSelected = _currentOrder.contains(text);
    int orderIndex = _currentOrder.indexOf(text) + 1;
    return ScaleButton(
      onTap: () => _onStarTap(text),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(30.r),
          color: isSelected ? color : color.withValues(alpha: 0.05),
          border: Border.all(color: isSelected ? Colors.white : color, width: 2),
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 15)] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) Text("$orderIndex. ", style: GoogleFonts.shareTechMono(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold)),
            Text(text, style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : color)),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: (2 + text.length % 3).seconds, curve: Curves.easeInOut);
  }

  Widget _buildSparkButton(Color color, String correctAnswer) {
    return Positioned(
      bottom: 60.h,
      child: ScaleButton(
        onTap: () => _submitAnswer(correctAnswer),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 15.h),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.r), gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)])),
          child: Text("IGNITE SPARK", style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
        ),
      ),
    );
  }
}

