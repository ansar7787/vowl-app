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

class _PhrasalVerbsScreenState extends State<PhrasalVerbsScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  String? _selectedOption;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  late AnimationController _vaultController;

  @override
  void initState() {
    super.initState();
    _vaultController = AnimationController(vsync: this, duration: 1.seconds);
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _vaultController.dispose();
    super.dispose();
  }

  void _submitChoice(String selected, String correct) async {
    if (_isAnswered) return;

    setState(() => _selectedOption = selected);
    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _vaultController.forward(from: 0);
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          if (state.currentIndex != _lastProcessedIndex ||
              (_isAnswered && state.lastAnswerCorrect == null)) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedOption = null;
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
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

        if (state is VocabularyLoading ||
            (state is! VocabularyGameComplete &&
                state is! VocabularyLoaded &&
                state is! VocabularyError)) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;
        final isFinalFailure = (state is VocabularyLoaded)
            ? state.isFinalFailure
            : false;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () =>
              context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          useScrolling: false,
          disablePadding: true,
          child: quest == null
              ? const SizedBox()
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    // Edge-to-edge transparent grid background!
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GridPainter(
                          theme.primaryColor.withValues(
                            alpha: isDark ? 0.05 : 0.03,
                          ),
                        ),
                      ),
                    ),

                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          SizedBox(height: 40.h), // Re-added top spacing!
                          _buildVaultStatus(theme.primaryColor, isDark),
                          SizedBox(height: 20.h),

                          // LCD Display
                          _buildLcdDisplay(
                            quest.hint?.replaceFirst("DEFINITION: ", "") ??
                                "ANALYZING VAULT...",
                            theme.primaryColor,
                            isDark,
                          ),

                          SizedBox(height: 30.h),

                          // The Central Vault Handle
                          _buildVaultHandle(
                            quest.word ?? "VERB",
                            theme.primaryColor,
                            isDark,
                          ),

                          SizedBox(height: 30.h),

                          // Key Options (Particles)
                          _buildParticleKeys(
                            quest.options ?? [],
                            quest.correctAnswer ?? "",
                            theme.primaryColor,
                            isDark,
                            isFinalFailure,
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildVaultStatus(Color color, bool isDark) {
    return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.vpn_key_rounded, size: 16.r, color: color),
              SizedBox(width: 10.w),
              Text(
                "VAULT SECURITY: L-${widget.level}",
                style: GoogleFonts.shareTechMono(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 3.seconds);
  }

  Widget _buildLcdDisplay(String text, Color color, bool isDark) {
    return Container(
      width: 0.9.sw,
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radar_rounded, size: 12.sp, color: color),
                  SizedBox(width: 8.w),
                  Text(
                    "DECRYPTING TARGET",
                    style: GoogleFonts.shareTechMono(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(duration: 1.seconds),
          SizedBox(height: 10.h),
          Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultHandle(String verb, Color color, bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // The Outer Rotating Vault Gear
        AnimatedBuilder(
          animation: _vaultController,
          builder: (context, child) {
            final unlockRotation = _vaultController.value * math.pi * 2.0;
            return Transform.rotate(
              angle: unlockRotation,
              child: Container(
                width: 150.r,
                height: 150.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF151E2E) : Colors.white,
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: List.generate(8, (i) {
                    return Transform.rotate(
                      angle: i * math.pi / 4,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 10.r,
                          height: 15.r,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 25.seconds),
            );
          },
        ),

        // The Stationary Verb Core
        Container(
          width: 90.r,
          height: 90.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.black : Colors.white,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black54 : Colors.grey.shade300,
                blurRadius: 10,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              verb.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticleKeys(
    List<String> options,
    String correct,
    Color color,
    bool isDark,
    bool isFinalFailure,
  ) {
    return Wrap(
      spacing: 15.w,
      runSpacing: 15.h,
      alignment: WrapAlignment.center,
      children: options.asMap().entries.map((entry) {
        int index = entry.key;
        String o = entry.value;

        final isSelected = _selectedOption == o;
        final showCorrect =
            (_isAnswered && _isCorrect == true && o == correct) ||
            (_isAnswered && isFinalFailure && o == correct);
        final isWrong = _isAnswered && isSelected && _isCorrect == false;

        Color cardBg = isDark ? color.withValues(alpha: 0.1) : Colors.white;
        Color cardBorder = color.withValues(alpha: 0.3);
        Color textColor = isDark ? Colors.white : Colors.black87;

        if (showCorrect) {
          cardBg = Colors.green;
          cardBorder = Colors.greenAccent;
          textColor = Colors.white;
        } else if (isWrong) {
          cardBg = Colors.red;
          cardBorder = Colors.redAccent;
          textColor = Colors.white;
        } else if (isSelected) {
          cardBg = color;
          cardBorder = color;
          textColor = Colors.white;
        }

        Widget keyCard = ScaleButton(
          onTap: () => _submitChoice(o, correct),
          child: Container(
            width: 150.w, // Increased!
            padding: EdgeInsets.symmetric(vertical: 20.h), // Increased!
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: cardBorder, width: 2),
              boxShadow: [
                BoxShadow(
                  color: showCorrect
                      ? Colors.green.withValues(alpha: 0.5)
                      : (isWrong
                            ? Colors.red.withValues(alpha: 0.5)
                            : color.withValues(alpha: 0.1)),
                  blurRadius: showCorrect || isSelected ? 15 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                o.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        );

        if (showCorrect) {
          keyCard = keyCard.animate().scale(
            end: const Offset(1.1, 1.1),
            duration: 300.ms,
            curve: Curves.easeOutBack,
          );
        } else if (isWrong) {
          keyCard = keyCard.animate().shakeX(amount: 5, duration: 400.ms);
        }

        return keyCard
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: -3,
              end: 3,
              duration: (1200 + (index * 200)).ms,
              curve: Curves.easeInOut,
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
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
