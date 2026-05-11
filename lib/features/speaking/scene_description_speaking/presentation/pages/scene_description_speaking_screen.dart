import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SceneDescriptionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SceneDescriptionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.sceneDescriptionSpeaking,
  });

  @override
  State<SceneDescriptionScreen> createState() => _SceneDescriptionScreenState();
}

class _SceneDescriptionScreenState extends State<SceneDescriptionScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final Set<int> _inspectedHotspots = {};
  int _activeHotspot = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onHotspotTap(int index) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _activeHotspot = index;
    });
  }

  void _onMicTap() {
    if (_isAnswered || _activeHotspot == -1) return;
    _hapticService.selection();
    setState(() => _isListening = !_isListening);
    if (!_isListening) {
      setState(() {
        _inspectedHotspots.add(_activeHotspot);
        _activeHotspot = -1;
      });
      // If all spots are done, submit
      if (_inspectedHotspots.length >= 3) {
        _submitAnswer();
      }
    }
  }

  void _submitAnswer() {
    _hapticService.success();
    _soundService.playCorrect();
    setState(() { _isAnswered = true; _isCorrect = true; });
    context.read<SpeakingBloc>().add(SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isListening = false;
              _inspectedHotspots.clear();
              _activeHotspot = -1;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'VISUAL NARRATOR!', enableDoubleUp: true);
        } else if (state is SpeakingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<SpeakingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;
        
        return SpeakingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<SpeakingBloc>().add(NextQuestion()),
          onHint: () => context.read<SpeakingBloc>().add(SpeakingHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 32.h),
              _buildSceneWithHotspots(quest.sceneText ?? "THE SCENE", theme.primaryColor, isDark),
              const Spacer(),
              _buildMicControl(theme.primaryColor, isDark),
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
          Icon(Icons.gps_fixed_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("TAP HOTSPOTS AND DESCRIBE THEM", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSceneWithHotspots(String text, Color primaryColor, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GlassTile(
          padding: EdgeInsets.zero, borderRadius: BorderRadius.circular(24.r),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.r),
                    child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 18.sp, color: isDark ? Colors.white70 : Colors.black87)),
                  ),
                ),
                // Hotspots
                ...List.generate(3, (i) {
                  return _buildHotspot(i, primaryColor);
                }),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildHotspot(int index, Color primaryColor) {
    final isInspected = _inspectedHotspots.contains(index);
    final isActive = _activeHotspot == index;
    
    // Position logic (simplified for layout)
    final positions = [Alignment.topLeft, Alignment.topRight, Alignment.bottomCenter];
    
    return Align(
      alignment: positions[index],
      child: GestureDetector(
        onTap: () => _onHotspotTap(index),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Container(
            width: 40.r, height: 40.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isInspected ? Colors.greenAccent : (isActive ? primaryColor : primaryColor.withValues(alpha: 0.2)),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Icon(isInspected ? Icons.check_rounded : (isActive ? Icons.search_rounded : Icons.add_rounded), color: Colors.white, size: 20.r),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1.seconds),
        ),
      ),
    );
  }

  Widget _buildMicControl(Color primaryColor, bool isDark) {
    final canRecord = _activeHotspot != -1;
    return Column(
      children: [
        ScaleButton(
          onTap: canRecord ? _onMicTap : null,
          child: Container(
            width: 90.r, height: 90.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: canRecord ? (_isListening ? Colors.redAccent : primaryColor) : Colors.grey.withValues(alpha: 0.1),
              boxShadow: _isListening ? [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.4), blurRadius: 20)] : [],
            ),
            child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 40.r),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          _activeHotspot == -1 ? "TAP A HOTSPOT TO INSPECT" : (_isListening ? "RECORDING..." : "TAP TO DESCRIBE FEATURE"),
          style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w900, color: canRecord ? primaryColor : Colors.grey, letterSpacing: 1.5)
        ),
      ],
    );
  }
}
