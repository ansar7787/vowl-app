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
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ShortAnswerScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ShortAnswerScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.shortAnswerWriting,
  });

  @override
  State<ShortAnswerScreen> createState() => _ShortAnswerScreenState();
}

class _ShortAnswerScreenState extends State<ShortAnswerScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _controller = TextEditingController();
  
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _submitAnswer() {
    if (_isAnswered || _controller.text.isEmpty) return;
    
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
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _controller.clear();
            });
          }
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'FLUENCY MASTER!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is WritingLoaded) ? state.currentQuest : null;
        
        return WritingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: quest == null ? const SizedBox() : SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 16.h),
                Text(quest.instruction.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w800, color: theme.primaryColor, letterSpacing: 2)),
                SizedBox(height: 48.h),
                _buildPromptCard(quest.prompt ?? "", theme.primaryColor, isDark),
                SizedBox(height: 48.h),
                _buildAnswerBox(theme.primaryColor, isDark),
                SizedBox(height: 60.h),
                if (!_isAnswered)
                  ScaleButton(
                    onTap: _submitAnswer,
                    child: Container(
                      width: double.infinity, height: 60.h,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), color: theme.primaryColor),
                      child: Center(child: Text("VOICE YOUR ANSWER", style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromptCard(String text, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(32.r), borderRadius: BorderRadius.circular(24.r),
      color: primaryColor.withValues(alpha: 0.1),
      child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
    );
  }

  Widget _buildAnswerBox(Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.all(20.r), borderRadius: BorderRadius.circular(20.r),
      child: TextField(
        controller: _controller,
        maxLines: 4,
        enabled: !_isAnswered,
        style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: "YOUR RESPONSE...",
          hintStyle: GoogleFonts.outfit(fontSize: 14.sp, color: Colors.grey.withValues(alpha: 0.4)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
