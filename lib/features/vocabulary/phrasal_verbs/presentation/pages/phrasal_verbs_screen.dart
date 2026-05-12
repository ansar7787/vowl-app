import 'dart:math' as math;
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
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class PhrasalVerbsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PhrasalVerbsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.phrasalVerbs,
  });

  @override
  State<PhrasalVerbsScreen> createState() => _PhrasalVerbsScreenState();
}

class _PhrasalVerbsScreenState extends State<PhrasalVerbsScreen> with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  late AnimationController _vaultController;

  @override
  void initState() {
    super.initState();
    _vaultController = AnimationController(vsync: this, duration: 1.seconds);
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _vaultController.dispose();
    super.dispose();
  }

  void _submitChoice(String selected, String correct) async {
    if (_isAnswered) return;
    
    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();
    
    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _vaultController.forward(from: 0);
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
          if (state.currentIndex != _lastProcessedIndex || (_isAnswered && state.lastAnswerCorrect == null)) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _vaultController.reset();
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'VAULT CRACKED!',
            enableDoubleUp: true,
          );
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;
        if (quest == null && state is! VocabularyGameComplete) return const GameShimmerLoading();

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              // Industrial Background
              Positioned.fill(child: _buildVaultBackground(theme.primaryColor)),

              Column(
                children: [
                  SizedBox(height: 20.h),
                  _buildVaultStatus(theme.primaryColor),
                  SizedBox(height: 30.h),
                  
                  // LCD Display
                  _buildLcdDisplay(quest.hint?.replaceFirst("DEFINITION: ", "") ?? "ANALYZING VAULT...", theme.primaryColor),
                  
                  const Spacer(),
                  
                  // The Central Vault Handle
                  _buildVaultHandle(quest.word ?? "VERB", theme.primaryColor),
                  
                  const Spacer(),

                  // Key Options (Particles)
                  _buildParticleKeys(quest.options ?? [], quest.correctAnswer ?? "", theme.primaryColor, isDark),
                  SizedBox(height: 40.h),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVaultBackground(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black,
            color.withValues(alpha: 0.1),
            Colors.black,
          ],
        ),
      ),
      child: CustomPaint(painter: GridPainter(color.withValues(alpha: 0.05))),
    );
  }

  Widget _buildVaultStatus(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.security_rounded, size: 16.r, color: color),
        SizedBox(width: 10.w),
        Text(
          "SECURITY CLEARANCE: LEVEL ${widget.level}",
          style: GoogleFonts.shareTechMono(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 2,
          ),
        ),
      ],
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds);
  }

  Widget _buildLcdDisplay(String text, Color color) {
    return Container(
      width: 0.85.sw,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          Text(
            "OBJECTIVE: IDENTIFY PARTICLE",
            style: GoogleFonts.shareTechMono(fontSize: 10.sp, color: color.withValues(alpha: 0.6)),
          ),
          SizedBox(height: 10.h),
          Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultHandle(String verb, Color color) {
    return AnimatedBuilder(
      animation: _vaultController,
      builder: (context, child) {
        final rotation = _vaultController.value * math.pi * 0.5;
        return Transform.rotate(
          angle: rotation,
          child: Container(
            width: 180.r,
            height: 180.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E293B),
              border: Border.all(color: color, width: 8),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 10),
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Inner Spokes
                ...List.generate(3, (i) {
                  return Transform.rotate(
                    angle: i * math.pi / 1.5,
                    child: Container(width: 160.r, height: 20.r, color: color.withValues(alpha: 0.2)),
                  );
                }),
                // The Verb
                Container(
                  padding: EdgeInsets.all(15.r),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF334155)),
                  child: Text(
                    verb.toUpperCase(),
                    style: GoogleFonts.shareTechMono(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticleKeys(List<String> options, String correct, Color color, bool isDark) {
    return Wrap(
      spacing: 20.w,
      runSpacing: 20.h,
      alignment: WrapAlignment.center,
      children: options.map((o) {
        final isSelected = _isAnswered && o == correct;
        final isWrong = _isAnswered && _isCorrect == false && o != correct;

        return ScaleButton(
          onTap: () => _submitChoice(o, correct),
          child: Container(
            width: 80.r,
            height: 80.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected 
                  ? Colors.green.withValues(alpha: 0.2) 
                  : (isWrong ? Colors.red.withValues(alpha: 0.2) : Colors.black),
              border: Border.all(
                color: isSelected ? Colors.green : (isWrong ? Colors.red : color.withValues(alpha: 0.4)),
                width: 3,
              ),
              boxShadow: [
                if (isSelected) BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 20),
                BoxShadow(color: Colors.black26, blurRadius: 5, offset: const Offset(3, 3)),
              ],
            ),
            child: Center(
              child: Text(
                o.toUpperCase(),
                style: GoogleFonts.shareTechMono(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.green : (isWrong ? Colors.red : color),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
