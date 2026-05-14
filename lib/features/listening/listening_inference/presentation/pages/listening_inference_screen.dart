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
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ListeningInferenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ListeningInferenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.listeningInference,
  });

  @override
  State<ListeningInferenceScreen> createState() => _ListeningInferenceScreenState();
}

class _ListeningInferenceScreenState extends State<ListeningInferenceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _dialAngle = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(FetchListeningQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onRotate(double delta) {
    if (_isAnswered) return;
    setState(() {
      _dialAngle += delta / 200;
      _hapticService.selection();
    });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              _dialAngle = 0.0;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SUBTEXT RADAR!', enableDoubleUp: true);
        } else if (state is ListeningGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ListeningBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;
        
        return ListeningBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 40.h),
              _buildDecoderCore(quest.textToSpeak ?? "", theme.primaryColor),
              const Spacer(),
              _buildCryptexField(quest.options ?? [], quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
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
          Icon(Icons.vpn_key_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("ALIGN THE CRYPTEX TO DECODE SUBTEXT", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildDecoderCore(String tts, Color color) {
    return ScaleButton(
      onTap: () {
        _soundService.playTts(tts);
        _hapticService.selection();
      },
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyanAccent.withValues(alpha: 0.1), border: Border.all(color: Colors.cyanAccent, width: 2)),
        child: Icon(Icons.radar_rounded, size: 56.r, color: Colors.cyanAccent),
      ),
    );
  }

  Widget _buildCryptexField(List<String> options, int correct, Color color, bool isDark) {
    return SizedBox(
      height: 420.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Rotating Cypher
          GestureDetector(
            onPanUpdate: (details) => _onRotate(details.delta.dx + details.delta.dy),
            child: Transform.rotate(
              angle: _dialAngle,
              child: Container(
                width: 320.r, height: 320.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10, width: 40.r),
                ),
                child: Stack(
                  children: List.generate(options.length, (i) {
                    double angle = (i * 6.28 / options.length);
                    return Transform.rotate(
                      angle: angle,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Icon(Icons.auto_fix_normal_rounded, color: Colors.white24, size: 24.r),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          
          // The Decrypted Options
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(options.length, (index) {
              bool isSelected = _selectedIndex == index;
              bool isCorrect = _isAnswered && index == correct && _isCorrect == true;
              bool isWrong = _isAnswered && isSelected && _isCorrect == false;
              Color tileColor = isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : (isSelected ? Colors.white : Colors.white70));

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: ScaleButton(
                  onTap: () => _submitAnswer(index, correct),
                  child: GlassTile(
                    padding: EdgeInsets.all(16.r), borderRadius: BorderRadius.circular(15.r),
                    color: tileColor.withValues(alpha: 0.1),
                    child: Text(options[index], style: GoogleFonts.outfit(fontSize: 12.sp, color: isSelected ? Colors.white : Colors.white70)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

