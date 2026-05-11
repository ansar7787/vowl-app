import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';

class WordFormationScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const WordFormationScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.wordFormation,
  });

  @override
  State<WordFormationScreen> createState() => _WordFormationScreenState();
}

class _WordFormationScreenState extends State<WordFormationScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  double _sliderProgress = 0.0;
  int? _activeSuffixIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onSlideUpdate(int index, double delta, double maxWidth, String suffix, String root, String correct) {
    if (_isAnswered) return;
    setState(() {
      _activeSuffixIndex = index;
      _sliderProgress = (_sliderProgress + delta / maxWidth).clamp(0.0, 1.0);
    });

    if (_sliderProgress >= 0.95) {
      _hapticService.success();
      _submitMorph(suffix, root, correct);
    }
  }

  void _submitMorph(String suffix, String root, String correct) {
    if (_isAnswered) return;
    
    String cleanS = suffix.replaceAll('-', '').trim().toLowerCase();
    bool isCorrect = correct.trim().toLowerCase().endsWith(cleanS) || 
                    correct.trim().toLowerCase() == (root.trim() + cleanS).toLowerCase();
    
    if (isCorrect) {
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final livesChanged = state.livesRemaining > (_lastLives ?? 3);
          if (state.currentIndex != _lastProcessedIndex || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _sliderProgress = 0.0;
              _activeSuffixIndex = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'MORPHOLOGY MASTER!', enableDoubleUp: true);
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : null;
        final root = quest?.rootWord ?? "???";
        final options = quest?.options ?? [];
        final activeSuffix = _activeSuffixIndex != null ? options[_activeSuffixIndex!] : null;

        return VocabularyBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 40.h),
              _buildMorphChamber(root, activeSuffix, theme.primaryColor, isDark),
              const Spacer(),
              _buildMorphRail(options, root, quest.correctAnswer ?? "", theme.primaryColor, isDark),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text("SLIDE A SUFFIX TO THE MORPH CHAMBER", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
    );
  }

  Widget _buildMorphChamber(String root, String? suffix, Color color, bool isDark) {
    return Container(
      width: 250.r, height: 150.r,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: _sliderProgress * 0.5), blurRadius: 40)],
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(root.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
            if (suffix != null)
              Opacity(
                opacity: _sliderProgress,
                child: Text(suffix.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 24.sp, fontWeight: FontWeight.bold, color: color, letterSpacing: 2)),
              ).animate(target: _sliderProgress > 0.8 ? 1 : 0).shake(),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: 2.seconds);
  }

  Widget _buildMorphRail(List<String> options, String root, String correct, Color color, bool isDark) {
    return Column(
      children: options.asMap().entries.map((entry) {
        int idx = entry.key;
        String s = entry.value;
        bool isActive = _activeSuffixIndex == idx;

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h, left: 24.w, right: 24.w),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 50.h,
                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10.r)),
                child: Stack(
                  children: [
                    // Rail progress
                    if (isActive)
                      FractionallySizedBox(
                        widthFactor: _sliderProgress,
                        child: Container(decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10.r))),
                      ),
                    // Handle
                    Positioned(
                      left: isActive ? (constraints.maxWidth - 60.w) * _sliderProgress : 0,
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) => _onSlideUpdate(idx, details.delta.dx, constraints.maxWidth, s, root, correct),
                        onHorizontalDragEnd: (_) {
                           if (!_isAnswered) setState(() { _sliderProgress = 0.0; _activeSuffixIndex = null; });
                        },
                        child: Container(
                          width: 80.w, height: 50.h,
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8.r), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)]),
                          child: Center(child: Text(s.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.white))),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        );
      }).toList(),
    );
  }
}

