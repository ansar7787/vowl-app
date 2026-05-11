import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

import 'package:flutter_animate/flutter_animate.dart';

class IntonationMimicScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const IntonationMimicScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.intonationMimic,
  });

  @override
  State<IntonationMimicScreen> createState() => _IntonationMimicScreenState();
}

class _IntonationMimicScreenState extends State<IntonationMimicScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  bool _isRecording = false;
  double _cartPosition = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onMicTap() {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() => _isRecording = !_isRecording);
    if (!_isRecording) {
      _submitAnswer();
    }
  }

  void _submitAnswer() {
    _hapticService.success();
    _soundService.playCorrect();
    setState(() { _isAnswered = true; _isCorrect = true; });
    context.read<AccentBloc>().add(SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isRecording = false;
              _cartPosition = 0.0;
            });
          }
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'CONTOUR MASTER!', enableDoubleUp: true);
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<AccentBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is AccentLoaded) ? state.currentQuest : null;
        final contour = quest?.intonationMap ?? [1, 2, 1, 0, 1];

        return AccentBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
          onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildSentenceDisplay(quest.textToSpeak ?? "", theme.primaryColor, isDark),
              _buildRollercoasterTrack(contour, theme.primaryColor, isDark),
              _buildControlCenter(theme.primaryColor, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Positioned(
      top: 20.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Text("STAY ON THE TRACK TO MATCH THE PITCH", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildSentenceDisplay(String text, Color color, bool isDark) {
    return Positioned(
      top: 80.h,
      child: Column(
        children: [
          ScaleButton(
            onTap: () => _soundService.playTts(text),
            child: Icon(Icons.waves_rounded, color: color, size: 40.r),
          ),
          SizedBox(height: 12.h),
          Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 22.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildRollercoasterTrack(List<int> contour, Color color, bool isDark) {
    return Positioned(
      top: 220.h,
      child: SizedBox(
        width: 1.sw, height: 200.h,
        child: Stack(
          children: [
            // Rails
            Center(
              child: CustomPaint(
                size: Size(0.8.sw, 100.h),
                painter: _TrackPainter(contour, color.withValues(alpha: 0.3)),
              ),
            ),
            // Progress Glow
            if (_isRecording)
              Center(
                child: CustomPaint(
                  size: Size(0.8.sw, 100.h),
                  painter: _TrackPainter(contour, color, progress: _cartPosition),
                ),
              ),
            // Cart
            _buildCart(contour, color),
          ],
        ),
      ),
    );
  }

  Widget _buildCart(List<int> contour, Color color) {
    return Positioned(
      left: 0.1.sw + (_cartPosition * 0.8.sw) - 20.w,
      bottom: _getYForPosition(_cartPosition, contour) * 100.h + 30.h,
      child: Icon(Icons.navigation_rounded, color: color, size: 40.r)
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: -2, end: 2, duration: 500.ms),
    );
  }

  double _getYForPosition(double pos, List<int> contour) {
    if (contour.isEmpty) return 0.5;
    int idx = (pos * (contour.length - 1)).floor();
    double subPos = (pos * (contour.length - 1)) - idx;
    if (idx >= contour.length - 1) return contour.last / 2.0;
    return (contour[idx] + (contour[idx+1] - contour[idx]) * subPos) / 2.0;
  }

  Widget _buildControlCenter(Color color, bool isDark) {
    return Positioned(
      bottom: 60.h,
      child: Column(
        children: [
          ScaleButton(
            onTap: _onMicTap,
            child: Container(
              width: 100.r, height: 100.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? color : color.withValues(alpha: 0.1),
                border: Border.all(color: color, width: 3),
                boxShadow: _isRecording ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5)] : [],
              ),
              child: Icon(_isRecording ? Icons.mic_rounded : Icons.mic_none_rounded, color: _isRecording ? Colors.white : color, size: 48.r),
            ),
          ),
          SizedBox(height: 20.h),
          Text(_isRecording ? "MIMICKING..." : "TAP TO RIDE", style: GoogleFonts.shareTechMono(fontSize: 14.sp, fontWeight: FontWeight.bold, color: color, letterSpacing: 2)),
        ],
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  final List<int> contour;
  final Color color;
  final double progress;
  _TrackPainter(this.contour, this.color, {this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    if (contour.isEmpty) return;

    double dx = size.width / (contour.length - 1);
    path.moveTo(0, size.height - (contour[0] / 2.0 * size.height));

    for (int i = 1; i < contour.length; i++) {
      if (i / (contour.length - 1) > progress) break;
      path.lineTo(i * dx, size.height - (contour[i] / 2.0 * size.height));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
