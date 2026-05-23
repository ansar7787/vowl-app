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
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';

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
  
  final GlobalKey _canvasKey = GlobalKey();
  final Map<String, GlobalKey> _terminalKeys = {};
  
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

  GlobalKey _getKeyFor(String text) {
    return _terminalKeys.putIfAbsent(text, () => GlobalKey());
  }

  Offset? _getCenterOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final parentBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || parentBox == null) return null;
    
    final localPos = parentBox.globalToLocal(box.localToGlobal(Offset.zero));
    return Offset(
      localPos.dx + box.size.width / 2,
      localPos.dy + box.size.height / 2,
    );
  }

  void _onKeyTap(String key) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      if (_matches.containsKey(key)) {
        _matches.remove(key);
      }
      _activeKey = key;
    });
  }

  void _onValueTap(String value, List<Map<String, String>> pairs) {
    if (_isAnswered || _activeKey == null) return;
    
    _hapticService.success();
    setState(() {
      // Remove any existing match containing this value
      _matches.removeWhere((k, v) => v == value);
      
      _matches[_activeKey!] = value;
      _activeKey = null;
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
      Future.delayed(1500.milliseconds, () {
        if (mounted) {
          setState(() {
            _matches.clear();
            _isAnswered = false;
            _isCorrect = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
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
        final ReadingQuest? quest = (state is ReadingLoaded) ? state.currentQuest as ReadingQuest? : null;
        final pairs = quest?.pairs ?? [];
        
        // Shuffle lists but keep state-consistent orders if needed
        final keys = pairs.map((p) => p['key']!).toList();
        final values = pairs.map((p) => p['value']!).toList();
        
        return ReadingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
          onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
          child: quest == null ? const SizedBox() : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  _buildInstruction(theme.primaryColor),
                  SizedBox(height: 32.h),
                  
                  // Interactive Canvas Stack
                  SizedBox(
                    key: _canvasKey,
                    height: 420.h,
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            // Left Keys Column
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: keys.map((k) => _buildTerminal(k, true, theme.primaryColor, isDark)).toList(),
                              ),
                            ),
                            SizedBox(width: 40.w),
                            // Right Values Column
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: values.map((v) => _buildTerminal(v, false, theme.primaryColor, isDark, pairs: pairs)).toList(),
                              ),
                            ),
                          ],
                        ),
                        
                        // Render Glowing Lasers dynamically using key positions!
                        IgnorePointer(
                          child: CustomPaint(
                            painter: LaserBridgePainter(
                              matches: _matches,
                              activeKey: _activeKey,
                              getCenter: _getCenterOf,
                              getKey: _getKeyFor,
                              color: theme.primaryColor,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (_isAnswered) ...[
                    SizedBox(height: 30.h),
                    _buildCorrectResult(quest, theme.primaryColor, isDark),
                  ],
                  SizedBox(height: 50.h),
                ],
              ),
            ),
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
          Text("TAP A CONCEPT ON LEFT, THEN ITS DEFINITION ON RIGHT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTerminal(String text, bool isSource, Color color, bool isDark, {List<Map<String, String>>? pairs}) {
    bool isMatched = isSource ? _matches.containsKey(text) : _matches.containsValue(text);
    bool isActive = isSource && _activeKey == text;
    
    return GestureDetector(
      key: _getKeyFor(text),
      onTap: () => isSource ? _onKeyTap(text) : _onValueTap(text, pairs!),
      child: AnimatedContainer(
        duration: 300.milliseconds,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isMatched 
              ? color.withValues(alpha: isDark ? 0.15 : 0.08) 
              : (isActive ? color.withValues(alpha: isDark ? 0.3 : 0.15) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04))),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isMatched || isActive ? color : (isDark ? Colors.white10 : Colors.black12), 
            width: 2
          ),
          boxShadow: [
            if (isMatched || isActive) 
              BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        child: Text(
          text.contains("]") ? text.split("]").last.trim() : text, 
          textAlign: TextAlign.center, 
          style: GoogleFonts.shareTechMono(
            fontSize: 13.sp, 
            color: isMatched || isActive 
                ? (isDark ? Colors.white : color) 
                : (isDark ? Colors.white70 : Colors.black87), 
            fontWeight: FontWeight.bold
          )
        ),
      ),
    );
  }

  Widget _buildCorrectResult(ReadingQuest quest, Color primaryColor, bool isDark) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: displayColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: displayColor, size: 36.r),
          SizedBox(height: 10.h),
          Text(
            correct ? "CORRECT!" : "INCORRECT",
            style: GoogleFonts.outfit(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: displayColor,
              letterSpacing: 2,
            ),
          ),
          if (quest.explanation != null) ...[
            SizedBox(height: 10.h),
            Text(
              quest.explanation!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}

class LaserBridgePainter extends CustomPainter {
  final Map<String, String> matches;
  final String? activeKey;
  final Offset? Function(GlobalKey) getCenter;
  final GlobalKey Function(String) getKey;
  final Color color;

  LaserBridgePainter({
    required this.matches,
    required this.activeKey,
    required this.getCenter,
    required this.getKey,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final glow = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Draw lines for established matches
    matches.forEach((k, v) {
      final keyCenter = getCenter(getKey(k));
      final valCenter = getCenter(getKey(v));

      if (keyCenter != null && valCenter != null) {
        canvas.drawLine(keyCenter, valCenter, glow);
        canvas.drawLine(keyCenter, valCenter, paint);
        canvas.drawCircle(keyCenter, 5, paint);
        canvas.drawCircle(valCenter, 5, paint);
      }
    });
  }

  @override
  bool shouldRepaint(LaserBridgePainter oldDelegate) => true;
}
