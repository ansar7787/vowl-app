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

class DetailSpotlightScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DetailSpotlightScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.detailSpotlight,
  });

  @override
  State<DetailSpotlightScreen> createState() => _DetailSpotlightScreenState();
}

class _DetailSpotlightScreenState extends State<DetailSpotlightScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  Offset _spotlightPos = const Offset(200, 300);
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

  void _onSearch(Offset position) {
    if (_isAnswered) return;
    setState(() {
      _spotlightPos = position;
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
              _spotlightPos = const Offset(200, 300);
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SPECIFIC PULSER!', enableDoubleUp: true);
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
              SizedBox(height: 32.h),
              _buildAudioEmitter(quest.textToSpeak ?? "", theme.primaryColor),
              SizedBox(height: 32.h),
              _buildTargetPrompt(quest.targetDetail ?? "Detail", theme.primaryColor),
              SizedBox(height: 32.h),
              _buildDarkField(quest.options ?? [], quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
              const Spacer(),
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
          Icon(Icons.flashlight_on_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("SEARCH THE SHADOWS FOR AUDITORY EVIDENCE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildAudioEmitter(String tts, Color color) {
    return ScaleButton(
      onTap: () {
        _soundService.playTts(tts);
        _hapticService.selection();
      },
      child: Container(
        width: 80.r, height: 80.r,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.yellowAccent.withValues(alpha: 0.1), border: Border.all(color: Colors.yellowAccent.withValues(alpha: 0.4))),
        child: Icon(Icons.spatial_audio_off_rounded, color: Colors.yellowAccent, size: 32.r),
      ),
    );
  }

  Widget _buildTargetPrompt(String detail, Color color) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h), borderRadius: BorderRadius.circular(30.r),
      child: Text("LOCATE: ${detail.toUpperCase()}", style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
    );
  }

  Widget _buildDarkField(List<String> options, int correct, Color color, bool isDark) {
    return SizedBox(
      height: 400.h, width: double.infinity,
      child: Stack(
        children: [
          // The Shadow Layer
          Container(
            width: double.infinity, height: 400.h,
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20.r)),
          ),
          
          // Hidden Options
          ...List.generate(options.length, (index) {
            double x = (index % 2 == 0) ? 40.w : 200.w;
            double y = (index < 2) ? 40.h : 180.h;
            double dist = (_spotlightPos - Offset(x + 60.w, y + 40.h)).distance;
            bool isLit = dist < 80.r;
            
            return Positioned(
              left: x, top: y,
              child: GestureDetector(
                onTap: () => _submitAnswer(index, correct),
                child: Builder(builder: (context) {
                  bool isSelected = _selectedIndex == index;
                  bool isCorrect = _isAnswered && index == correct && _isCorrect == true;
                  bool isWrong = _isAnswered && isSelected && _isCorrect == false;
                  Color tileColor = isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : Colors.white);
                  
                  return Opacity(
                    opacity: isLit || isCorrect || isWrong ? 1.0 : 0.05,
                    child: Container(
                      width: 120.w, height: 80.h,
                      decoration: BoxDecoration(
                        color: (isLit || isCorrect || isWrong) ? tileColor.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(15.r),
                        border: Border.all(color: (isLit || isCorrect || isWrong) ? tileColor.withValues(alpha: 0.3) : Colors.transparent),
                      ),
                      child: Center(child: Text(options[index], textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w600, color: tileColor))),
                    ),
                  );
                }),
              ),
            );
          }),
          
          // The Spotlight Handle
          Positioned(
            left: _spotlightPos.dx - 40.r,
            top: _spotlightPos.dy - 40.r,
            child: GestureDetector(
              onPanUpdate: (details) => _onSearch(_spotlightPos + details.delta),
              child: Container(
                width: 80.r, height: 80.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.yellowAccent, width: 2),
                  boxShadow: [BoxShadow(color: Colors.yellowAccent.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 10)],
                ),
                child: Icon(Icons.search_rounded, color: Colors.yellowAccent, size: 24.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

