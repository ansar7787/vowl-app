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

class GourmetOrderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const GourmetOrderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.gourmetOrder,
  });

  @override
  State<GourmetOrderScreen> createState() => _GourmetOrderScreenState();
}

class _GourmetOrderScreenState extends State<GourmetOrderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  int _lastProcessedIndex = -1;
  final List<String> _selectedItems = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  Offset _dragPosition = Offset.zero;
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onPlateDragUpdate(DragUpdateDetails details, int index) {
    if (_isAnswered) return;
    setState(() {
      _draggingIndex = index;
      _dragPosition += details.delta;
    });
    _hapticService.selection();
  }

  void _onPlateDragEnd(String item, String correctAnswer) {
    if (_isAnswered) return;
    
    // Check if dropped in center "Target Zone"
    if (_dragPosition.dy < -200.h) {
       _onItemTap(item);
    }
    
    setState(() {
      _dragPosition = Offset.zero;
      _draggingIndex = null;
    });
  }

  void _onItemTap(String item) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  void _submitAnswer(String correctAnswer) {
    if (_isAnswered || _selectedItems.isEmpty) return;
    
    final targets = correctAnswer.split(',').map((e) => e.trim().toLowerCase()).toList();
    final current = _selectedItems.map((e) => e.trim().toLowerCase()).toList();
    
    bool isCorrect = targets.length == current.length && targets.every((t) => current.contains(t));

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
              _selectedItems.clear();
            });
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'CULINARY EXPERT!', enableDoubleUp: true);
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
              _buildBanquetHeader(quest.prompt ?? "", theme.primaryColor, isDark),
              _buildTableSetting(theme.primaryColor),
              _buildPlateTray(options, quest.correctAnswer ?? "", theme.primaryColor, isDark),
              if (!_isAnswered && _selectedItems.isNotEmpty) _buildServeButton(theme.primaryColor, quest.correctAnswer ?? ""),
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
        child: Text("DRAG THE PLATES TO THE CENTER TO FULFILL THE ORDER", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildBanquetHeader(String prompt, Color color, bool isDark) {
    return Positioned(
      top: 60.h,
      child: Container(
        width: 0.85.sw,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withValues(alpha: 0.1))),
        child: Text(prompt, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white70 : Colors.black87, fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _buildTableSetting(Color color) {
    return Center(
      child: Container(
        width: 200.r, height: 200.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.05),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 4, style: BorderStyle.solid),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.restaurant_rounded, color: color.withValues(alpha: 0.2), size: 100.r),
            if (_selectedItems.isNotEmpty)
              Text("${_selectedItems.length}", style: GoogleFonts.outfit(fontSize: 40.sp, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05)),
    );
  }

  Widget _buildPlateTray(List<String> options, String correct, Color color, bool isDark) {
    return Positioned(
      bottom: 60.h,
      child: SizedBox(
        width: 1.sw, height: 120.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          itemCount: options.length,
          itemBuilder: (context, i) => _buildPlate(i, options[i], correct, color, isDark),
        ),
      ),
    );
  }

  Widget _buildPlate(int index, String text, String correct, Color color, bool isDark) {
    bool isDragging = _draggingIndex == index;
    bool isSelected = _selectedItems.contains(text);
    return Padding(
      padding: EdgeInsets.only(right: 16.w),
      child: GestureDetector(
        onPanUpdate: (d) => _onPlateDragUpdate(d, index),
        onPanEnd: (_) => _onPlateDragEnd(text, correct),
        child: Transform.translate(
          offset: isDragging ? _dragPosition : Offset.zero,
          child: Container(
            width: 100.r, height: 100.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? color : (isDark ? Colors.white10 : Colors.white),
              border: Border.all(color: color, width: 2),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(8.r),
                child: Text(text.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : color)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServeButton(Color color, String correctAnswer) {
    return Positioned(
      bottom: 200.h,
      child: ScaleButton(
        onTap: () => _submitAnswer(correctAnswer),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.r), gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)])),
          child: Text("SERVE NOW", style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
        ),
      ),
    );
  }
}

