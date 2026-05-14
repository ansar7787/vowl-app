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
              SizedBox(height: 10.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 20.h),
              
              // Optimized: Magnetic Energy Port (The Diamond Standard)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHolographicPlate(clauseA, theme.primaryColor, isDark),
                      SizedBox(height: 16.h),
                      _buildMagneticPort(quest, options, theme.primaryColor, isDark),
                      SizedBox(height: 16.h),
                      _buildHolographicPlate(clauseB, theme.primaryColor, isDark).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
              ),

              if (!_isAnswered) 
                _buildConnectorPalette(options, theme.primaryColor, isDark),
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
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_input_component_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "SNAP THE LINGUISTIC COUPLER", 
            style: GoogleFonts.outfit(
              fontSize: 10.sp, 
              fontWeight: FontWeight.w900, 
              color: primaryColor, 
              letterSpacing: 1.5
            )
          ),
        ],
      ),
    );
  }

  Widget _buildMagneticPort(GameQuest? quest, List<String> options, Color primaryColor, bool isDark) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => !_isAnswered,
      onAcceptWithDetails: (details) => _onSnap(details.data, quest?.correctAnswerIndex ?? 0, options),
      builder: (context, candidateData, rejectedData) {
        final isHighlight = candidateData.isNotEmpty;
        final portColor = _isAnswered 
            ? (_isCorrect == true ? Colors.greenAccent : Colors.redAccent) 
            : (isHighlight ? primaryColor : primaryColor.withValues(alpha: 0.3));

        return Container(
          width: 220.w, 
          height: 80.h,
          decoration: BoxDecoration(
            color: portColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: portColor.withValues(alpha: 0.4), 
              width: 2,
              style: _isAnswered ? BorderStyle.none : BorderStyle.solid
            ),
            boxShadow: [
              if (isHighlight || _isAnswered)
                BoxShadow(color: portColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)
            ],
          ),
          child: Center(
            child: _isAnswered 
              ? _buildConnector(_draggingConnector ?? "ERROR", primaryColor, isDark)
                  .animate().scale(duration: 400.ms, curve: Curves.elasticOut)
              : Text(
                  isHighlight ? "RELEASE TO SNAP" : "ENERGY PORT", 
                  style: GoogleFonts.outfit(
                    fontSize: 10.sp, 
                    fontWeight: FontWeight.w900, 
                    color: portColor.withValues(alpha: 0.6), 
                    letterSpacing: 2
                  )
                ),
          ),
        );
      },
    );
  }

  Widget _buildHolographicPlate(String text, Color primaryColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Text(
        text.trim(), 
        textAlign: TextAlign.center, 
        style: GoogleFonts.fredoka(
          fontSize: 18.sp, 
          color: isDark ? Colors.white : Colors.black87,
          height: 1.4,
          fontWeight: FontWeight.w500
        )
      ),
    );
  }

  Widget _buildConnectorPalette(List<String> options, Color primaryColor, bool isDark) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16.w, 
      runSpacing: 16.h,
      children: options.map((opt) => Draggable<String>(
        data: opt,
        feedback: Material(color: Colors.transparent, child: _buildConnector(opt, primaryColor, isDark, isDragging: true)),
        childWhenDragging: Opacity(opacity: 0.2, child: _buildConnector(opt, primaryColor, isDark)),
        child: _buildConnector(opt, primaryColor, isDark),
      )).toList(),
    );
  }

  Widget _buildConnector(String text, Color primaryColor, bool isDark, {bool isDragging = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          if (isDragging) 
            BoxShadow(color: primaryColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)
        ],
      ),
      child: Text(
        text.toUpperCase(), 
        style: GoogleFonts.outfit(
          fontSize: 15.sp, 
          fontWeight: FontWeight.w900, 
          color: isDark ? Colors.white : Colors.black87, 
          letterSpacing: 1.5
        )
      ),
    );
  }
}

