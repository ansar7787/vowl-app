import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/widgets/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ClauseConnectorScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ClauseConnectorScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.clauseConnector,
  });

  @override
  State<ClauseConnectorScreen> createState() => _ClauseConnectorScreenState();
}

class _ClauseConnectorScreenState extends State<ClauseConnectorScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  String? _draggingConnector;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<GrammarBloc>().add(FetchGrammarQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onSnap(String connector, int correctIndex, List<String> options) {
    if (_isAnswered) return;

    bool isCorrect = connector == options[correctIndex];

    if (isCorrect) {
      _hapticService.heavy();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; _draggingConnector = connector; });
      context.read<GrammarBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false;
      });
      context.read<GrammarBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listener: (context, state) {
        if (state is GrammarLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _draggingConnector = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is GrammarGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'BRIDGE BUILDER!', enableDoubleUp: true);
        } else if (state is GrammarGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<GrammarBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final parts = (quest?.question ?? "Clause A ____ Clause B").split(' ____ ');
        final clauseA = parts[0];
        final clauseB = parts.length > 1 ? parts[1] : "...";
        final options = quest?.options ?? [];
        
        return GrammarBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
          showConfetti: _showConfetti,
          onContinue: () => context.read<GrammarBloc>().add(NextQuestion()),
          onHint: () => context.read<GrammarBloc>().add(GrammarHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 20.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 32.h),
              _buildIndustrialCoupler(clauseA, clauseB, theme.primaryColor, isDark),
              SizedBox(height: 60.h),
              if (!_isAnswered) 
                _buildConnectorPalette(options, quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
              SizedBox(height: 40.h),
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
          Icon(Icons.settings_input_component_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("SNAP THE COUPLER INTO PLACE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildIndustrialCoupler(String a, String b, Color primaryColor, bool isDark) {
    return Column(
      children: [
        _buildMetalPlate(a, primaryColor, isDark, isTop: true),
        Container(
          height: 100.h, width: 200.w,
          margin: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 2.r),
          ),
          child: Center(
            child: _isAnswered 
              ? _buildConnector(_draggingConnector ?? "", primaryColor, isDark).animate().scale(duration: 400.ms, curve: Curves.easeOutBack)
              : Text("INSERT COUPLER", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor.withValues(alpha: 0.4), letterSpacing: 2)),
          ),
        ),
        _buildMetalPlate(b, primaryColor, isDark, isTop: false),
      ],
    ).animate(target: _isAnswered ? 1 : 0).shimmer(duration: 1.seconds, color: Colors.white10);
  }

  Widget _buildMetalPlate(String text, Color primaryColor, bool isDark, {required bool isTop}) {
    return Container(
      padding: EdgeInsets.all(24.r),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[200],
        borderRadius: BorderRadius.vertical(
          top: isTop ? Radius.circular(24.r) : Radius.zero,
          bottom: !isTop ? Radius.circular(24.r) : Radius.zero,
        ),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 3.r),
      ),
      child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
    );
  }

  Widget _buildConnectorPalette(List<String> options, int correctIndex, Color primaryColor, bool isDark) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16.w, runSpacing: 16.h,
      children: options.map((opt) => Draggable<String>(
        data: opt,
        feedback: Material(color: Colors.transparent, child: _buildConnector(opt, primaryColor, isDark, isDragging: true)),
        childWhenDragging: Opacity(opacity: 0.3, child: _buildConnector(opt, primaryColor, isDark)),
        onDragCompleted: () {},
        onDragEnd: (details) {
          // Check if dropped in the center area
                final dropY = details.offset.dy;
          if (dropY > 200.h && dropY < 500.h) {
            _onSnap(opt, correctIndex, options);
          }
        },
        child: _buildConnector(opt, primaryColor, isDark),
      )).toList(),
    );
  }

  Widget _buildConnector(String text, Color primaryColor, bool isDark, {bool isDragging = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: isDragging ? 20 : 5, offset: Offset(0, isDragging ? 10 : 2)),
          BoxShadow(color: Colors.white24, blurRadius: 2, offset: const Offset(0, -2)),
        ],
      ),
      child: Text(text.toUpperCase(), style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
    );
  }
}

