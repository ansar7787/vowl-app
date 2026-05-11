import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/widgets/reading_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReadAndMatchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ReadAndMatchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.readAndMatch,
  });

  @override
  State<ReadAndMatchScreen> createState() => _ReadAndMatchScreenState();
}

class _ReadAndMatchScreenState extends State<ReadAndMatchScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  Offset? _dragStart;
  Offset? _dragCurrent;
  String? _activeKey;
  final Map<String, String> _matches = {};
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(FetchReadingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onTerminalDragStart(String key, Offset position) {
    if (_isAnswered || _matches.containsKey(key)) return;
    setState(() {
      _activeKey = key;
      _dragStart = position;
      _dragCurrent = position;
      _hapticService.selection();
    });
  }

  void _onTerminalDragUpdate(Offset delta) {
    if (_isAnswered || _activeKey == null) return;
    setState(() {
      _dragCurrent = (_dragCurrent ?? Offset.zero) + delta;
      _hapticService.selection();
    });
  }

  void _onTerminalDragEnd(String value, List<Map<String, String>> pairs) {
    if (_isAnswered || _activeKey == null) return;
    
    _hapticService.success();
    setState(() {
      _matches[_activeKey!] = value;
      _activeKey = null;
      _dragStart = null;
      _dragCurrent = null;
    });

    if (_matches.length == pairs.length) {
      _submitAnswer(pairs);
    }
  }

  void _submitAnswer(List<Map<String, String>> pairs) {
    bool isCorrect = true;
    for (var pair in pairs) {
      if (_matches[pair['key']] != pair['value']) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<ReadingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<ReadingBloc>().add(SubmitAnswer(false));
      Future.delayed(1.seconds, () => setState(() => _matches.clear()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _matches.clear();
              _activeKey = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'RELATIONSHIP MASTER!', enableDoubleUp: true);
        } else if (state is ReadingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ReadingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is ReadingLoaded) ? state.currentQuest : null;
        final pairs = quest?.pairs ?? [];
        final keys = pairs.map((p) => p['key']!).toList();
        final values = pairs.map((p) => p['value']!).toList();
        
        return ReadingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
          onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: 16.h),
                  _buildInstruction(theme.primaryColor),
                  SizedBox(height: 48.h),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: keys.map((k) => _buildTerminal(k, true, theme.primaryColor)).toList())),
                        SizedBox(width: 60.w),
                        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: values.map((v) => _buildTerminal(v, false, theme.primaryColor, pairs: pairs)).toList())),
                      ],
                    ),
                  ),
                ],
              ),
              if (_dragStart != null && _dragCurrent != null)
                CustomPaint(
                  painter: LaserPainter(start: _dragStart!, end: _dragCurrent!, color: theme.primaryColor),
                  size: Size.infinite,
                ),
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
          Icon(Icons.bolt_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("BRIDGE THE SEMANTIC GAP WITH LASERS", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTerminal(String text, bool isSource, Color color, {List<Map<String, String>>? pairs}) {
    bool isMatched = isSource ? _matches.containsKey(text) : _matches.containsValue(text);
    bool isActive = isSource && _activeKey == text;
    
    return DragTarget<String>(
      onAcceptWithDetails: (details) => isSource ? null : _onTerminalDragEnd(text, pairs!),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onPanStart: (details) => isSource ? _onTerminalDragStart(text, details.globalPosition) : null,
          onPanUpdate: (details) => isSource ? _onTerminalDragUpdate(details.delta) : null,
          child: AnimatedContainer(
            duration: 300.milliseconds,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isMatched ? color.withValues(alpha: 0.2) : (isActive ? color.withValues(alpha: 0.4) : Colors.white10),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: isMatched || isActive ? color : Colors.white24, width: 2),
              boxShadow: [if (isMatched || isActive) BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15)],
            ),
            child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.shareTechMono(fontSize: 14.sp, color: isMatched || isActive ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

class LaserPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  LaserPainter({required this.start, required this.end, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 4..strokeCap = StrokeCap.round;
    final glow = Paint()..color = color.withValues(alpha: 0.3)..strokeWidth = 12..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawLine(start, end, glow);
    canvas.drawLine(start, end, paint);
    canvas.drawCircle(end, 6.r, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

