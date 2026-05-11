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

class EssayDraftingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const EssayDraftingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.essayDrafting,
  });

  @override
  State<EssayDraftingScreen> createState() => _EssayDraftingScreenState();
}

class _EssayDraftingScreenState extends State<EssayDraftingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final Map<String, String?> _blueprintSlots = {};
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  double _traceProgress = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onSlot(String slotKey, String data) {
    if (_isAnswered) return;
    _hapticService.success();
    setState(() => _blueprintSlots[slotKey] = data);
  }

  void _onTrace(double delta) {
    if (_isAnswered || _blueprintSlots.values.any((v) => v == null)) return;
    setState(() {
      _traceProgress = (_traceProgress + delta / 300).clamp(0.0, 1.0);
    });
    if (_traceProgress >= 1.0) _submitAnswer();
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
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _blueprintSlots.clear();
              for (var point in (state.currentQuest.requiredPoints ?? [])) {
                _blueprintSlots[point] = null;
              }
              _traceProgress = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'ESSAY ARCHITECT!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is WritingLoaded) ? state.currentQuest : null;
        final modules = ["STRONG THESIS", "DATA ANALYSIS", "COUNTER ARGUMENT", "FINAL SYNTHESIS", "RELEVANT HOOK"];

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
              _buildTopicBanner(quest.essayTopic ?? "", theme.primaryColor, isDark),
              Expanded(
                child: _buildBlueprintGrid(theme.primaryColor),
              ),
              _buildModuleStream(modules, theme.primaryColor),
              SizedBox(height: 32.h),
              if (_blueprintSlots.values.every((v) => v != null) && !_isAnswered)
                _buildCircuitTrace(theme.primaryColor),
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
          Icon(Icons.architecture_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("CONSTRUCT THE STRUCTURAL BLUEPRINT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTopicBanner(String topic, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        image: DecorationImage(image: const NetworkImage('https://www.transparenttextures.com/patterns/graphy.png'), opacity: 0.1, repeat: ImageRepeat.repeat),
      ),
      child: Text(topic, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
    );
  }

  Widget _buildBlueprintGrid(Color color) {
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      children: _blueprintSlots.keys.map((k) => DragTarget<String>(
        onAcceptWithDetails: (details) => _onSlot(k, details.data),
        builder: (context, candidateData, rejectedData) {
          bool hasData = _blueprintSlots[k] != null;
          return Container(
            margin: EdgeInsets.only(bottom: 24.h),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: hasData ? color.withValues(alpha: 0.1) : Colors.black45,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: candidateData.isNotEmpty ? Colors.white : color.withValues(alpha: 0.2), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k, style: GoogleFonts.shareTechMono(color: color.withValues(alpha: 0.5), fontSize: 10.sp, letterSpacing: 1)),
                SizedBox(height: 8.h),
                Text(_blueprintSlots[k] ?? "DROP LOGIC MODULE HERE", style: GoogleFonts.outfit(color: hasData ? Colors.white : Colors.white24, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      )).toList(),
    );
  }

  Widget _buildModuleStream(List<String> items, Color color) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((i) => Draggable<String>(
          data: i,
          feedback: Material(color: Colors.transparent, child: Container(padding: EdgeInsets.all(12.r), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8.r), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20)]), child: Text(i, style: GoogleFonts.shareTechMono(color: Colors.white)))),
          child: Container(margin: EdgeInsets.only(right: 12.w), padding: EdgeInsets.all(12.r), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8.r), border: Border.all(color: color.withValues(alpha: 0.3))), child: Text(i, style: GoogleFonts.shareTechMono(color: color, fontSize: 10.sp))),
        )).toList(),
      ),
    );
  }

  Widget _buildCircuitTrace(Color color) {
    return GestureDetector(
      onPanUpdate: (details) => _onTrace(details.delta.dx + details.delta.dy),
      child: Column(
        children: [
          Container(
            width: double.infinity, height: 60.h,
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color, width: 2)),
            child: Stack(
              children: [
                Align(alignment: Alignment.centerLeft, child: Container(width: MediaQuery.of(context).size.width * _traceProgress, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30.r)))),
                Center(child: Text("TRACE CIRCUIT TO SOLIDIFY LOGIC", style: GoogleFonts.shareTechMono(color: _traceProgress > 0.5 ? Colors.black : color, fontWeight: FontWeight.bold, fontSize: 10.sp))),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().moveY(begin: 20, end: 0);
  }
}
