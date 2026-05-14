import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  
  Offset? _spotlightPos;
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
              _spotlightPos = null; // Reset to center for next quest
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
          useScrolling: false,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              const Spacer(flex: 1),
              _buildInstruction(theme.primaryColor),
              const Spacer(flex: 2),
              _buildAudioEmitter(quest.textToSpeak ?? "", theme.primaryColor),
              const Spacer(flex: 2),
              _buildTargetPrompt(quest.targetDetail ?? "Detail", theme.primaryColor),
              const Spacer(flex: 2),
              Expanded(
                flex: 12,
                child: _buildDarkField(quest.options ?? [], quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
              ),
              const Spacer(flex: 1),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: primaryColor.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flashlight_on_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              _isAnswered ? "EVIDENCE SECURED" : "DRAG TO SEARCH THE SHADOWS", 
              style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 0.5),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
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
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Icon(Icons.graphic_eq_rounded, color: color, size: 48.r),
      ),
    );
  }

  Widget _buildTargetPrompt(String detail, Color color) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h), borderRadius: BorderRadius.circular(30.r),
      child: Text(_isAnswered ? "TARGET: ${detail.toUpperCase()}" : "SCAN FOR AUDITORY TARGET", style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
    );
  }

  Widget _buildDarkField(List<String> options, int correct, Color color, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Initialize position to center on first build
        _spotlightPos ??= Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        
        final currentPos = _spotlightPos!;

        return Stack(
          children: [
            // The Shadow Layer (Captures Drags Everywhere)
            GestureDetector(
              onPanUpdate: (details) {
                double nextX = (currentPos.dx + details.delta.dx).clamp(40.r, constraints.maxWidth - 40.r);
                double nextY = (currentPos.dy + details.delta.dy).clamp(40.r, constraints.maxHeight - 40.r);
                _onSearch(Offset(nextX, nextY));
              },
              child: Container(
                width: double.infinity, height: constraints.maxHeight,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24.r), border: Border.all(color: color.withValues(alpha: 0.1))),
              ),
            ),
            
            // Hidden Options
            ...List.generate(options.length, (index) {
              double tileW = (constraints.maxWidth - 48.w) / 2;
              double tileH = 80.h;
              
              double x = (index % 2 == 0) ? 16.w : (constraints.maxWidth / 2 + 8.w);
              double y = (index < 2) ? 40.h : (constraints.maxHeight - 120.h);
              
              double dist = (currentPos - Offset(x + tileW / 2, y + tileH / 2)).distance;
              bool isLit = dist < 80.r;
              
              return Positioned(
                left: x, top: y,
                child: GestureDetector(
                  onTap: () => _submitAnswer(index, correct),
                  child: Builder(builder: (context) {
                    bool isSelected = _selectedIndex == index;
                    bool isCorrect = _isAnswered && index == correct && _selectedIndex == index;
                    bool isWrong = _isAnswered && isSelected && _isCorrect == false;
                    Color tileColor = isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : Colors.white);
                    
                    return Opacity(
                      opacity: isLit || isCorrect || isWrong ? 1.0 : 0.05,
                      child: AnimatedContainer(
                        duration: 300.ms,
                        width: tileW, height: tileH,
                        decoration: BoxDecoration(
                          color: (isLit || isCorrect || isWrong) ? tileColor.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: (isLit || isCorrect || isWrong) ? tileColor.withValues(alpha: 0.4) : Colors.transparent, width: (isCorrect || isWrong) ? 2 : 1),
                        ),
                        child: Center(
                          child: FittedBox(
                            child: Padding(
                              padding: EdgeInsets.all(8.r),
                              child: Text(options[index], textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w700, color: tileColor)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
            
            Positioned(
              left: currentPos.dx - 40.r,
              top: currentPos.dy - 40.r,
              child: IgnorePointer(
                child: Container(
                  width: 80.r, height: 80.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent, // Ensures it doesn't block but looks solid
                    border: Border.all(color: Colors.yellowAccent, width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.yellowAccent.withValues(alpha: 0.4), blurRadius: 40, spreadRadius: 10),
                      BoxShadow(color: Colors.yellowAccent.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.flash_on_rounded, color: Colors.yellowAccent, size: 24.r)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 1000.ms),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

