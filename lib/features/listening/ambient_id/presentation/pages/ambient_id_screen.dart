import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/widgets/listening_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'dart:math';

class AmbientIdScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AmbientIdScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.ambientId,
  });

  @override
  State<AmbientIdScreen> createState() => _AmbientIdScreenState();
}

class _AmbientIdScreenState extends State<AmbientIdScreen> with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  late AnimationController _radarController;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    context.read<ListeningBloc>().add(FetchListeningQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _submitAnswer(int index, int correct) {
    if (_isAnswered) return;
    setState(() => _selectedIndex = index);
    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<ListeningBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<ListeningBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: (context, state) {
        if (state is ListeningLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'CONTEXT ANCHOR!', enableDoubleUp: true);
        } else if (state is ListeningGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ListeningBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;
        
        return ListeningBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          useScrolling: true,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 20.h),
              _buildSonarField(quest.options ?? [], quest.correctAnswerIndex ?? 0, theme.primaryColor),
              SizedBox(height: 20.h),
              _buildEmitterNode(quest.textToSpeak ?? "", theme.primaryColor),
              SizedBox(height: 30.h),
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
          Icon(Icons.radar_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("ANCHOR THE AUDITORY CONTEXT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSonarField(List<String> options, int correct, Color color) {
    return SizedBox(
      height: 380.h, width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar Sweep Animation
          AnimatedBuilder(
            animation: _radarController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _radarController.value * 6.28,
                child: Container(
                  width: 380.r, height: 380.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [color.withValues(alpha: 0.2), Colors.transparent],
                      stops: const [0.1, 0.25],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Spatial Rings
          ...List.generate(3, (i) => Container(
            width: (i + 1) * 120.r, height: (i + 1) * 120.r,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.1))),
          )),
          
          // Location Hubs
          ...List.generate(options.length, (index) {
            double angle = (index * 6.28 / options.length) - 1.57;
            double dist = 135.r;
            return Transform.translate(
              offset: Offset(dist * cos(angle), dist * sin(angle)),
              child: _buildLocationHub(index, options[index], correct, color),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLocationHub(int index, String text, int correct, Color color) {
    bool isSelected = _selectedIndex == index;
    // Loophole fix: Don't reveal correct answer early if they failed
    bool isCorrect = _isAnswered && index == correct && _isCorrect == true;
    bool isWrong = _isAnswered && isSelected && _isCorrect == false;
    

    return ScaleButton(
      onTap: () => _submitAnswer(index, correct),
      child: Container(
        width: 90.r, height: 90.r,
        decoration: BoxDecoration(
          color: isCorrect 
              ? Colors.greenAccent 
              : (isWrong ? Colors.redAccent : (isSelected ? color : const Color(0xFF1E1E24))),
          shape: BoxShape.circle,
          border: Border.all(
            color: isCorrect || isWrong || isSelected 
                ? Colors.white.withValues(alpha: 0.5) 
                : color.withValues(alpha: 0.3), 
            width: 2,
          ),
          boxShadow: [
            if (isSelected || isCorrect || isWrong) 
              BoxShadow(
                color: (isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : color)).withValues(alpha: 0.4), 
                blurRadius: 15, 
                spreadRadius: 2,
              ),
            // Permanent subtle base shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getLocationIcon(text), color: Colors.white, size: 22.r),
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: FittedBox(
                  child: Text(
                    text.toUpperCase(), 
                    textAlign: TextAlign.center, 
                    style: GoogleFonts.shareTechMono(fontSize: 8.sp, fontWeight: FontWeight.w900, color: Colors.white)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmitterNode(String tts, Color color) {
    return ScaleButton(
      onTap: () {
        _soundService.playTts(tts);
        _hapticService.selection();
      },
      child: Container(
        padding: EdgeInsets.all(28.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle, 
          color: color, 
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 25),
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(0, 4), blurRadius: 10),
          ],
        ),
        child: Icon(Icons.settings_input_antenna_rounded, size: 52.r, color: Colors.white),
      ),
    );
  }

  IconData _getLocationIcon(String loc) {
    final l = loc.toLowerCase();
    if (l.contains('forest')) return Icons.forest_rounded;
    if (l.contains('cyber') || l.contains('city')) return Icons.location_city_rounded;
    if (l.contains('space')) return Icons.rocket_launch_rounded;
    if (l.contains('ocean') || l.contains('deep')) return Icons.waves_rounded;
    if (l.contains('base') || l.contains('military')) return Icons.security_rounded;
    if (l.contains('lab')) return Icons.science_rounded;
    if (l.contains('temple')) return Icons.temple_hindu_rounded;
    if (l.contains('vault')) return Icons.lock_rounded;
    if (l.contains('station')) return Icons.settings_input_antenna_rounded;
    if (l.contains('airport')) return Icons.local_airport_rounded;
    if (l.contains('train')) return Icons.train_rounded;
    if (l.contains('library')) return Icons.local_library_rounded;
    if (l.contains('mall')) return Icons.local_mall_rounded;
    if (l.contains('restaurant')) return Icons.restaurant_rounded;
    if (l.contains('park')) return Icons.park_rounded;
    return Icons.place_rounded;
  }
}

