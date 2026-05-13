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

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;
  int? _activeSuffixIndex;
  int? _hoveringSuffixIndex;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitMorph(String suffix, String root, String correct, int index) {
    if (_isAnswered) return;

    setState(() {
      _activeSuffixIndex = index;
      _hoveringSuffixIndex = null;
    });

    // We compare the final formed word with the correct answer from JSON
    final target = correct.trim().toLowerCase();

    bool isCorrect = false;
    String cleanS = suffix.replaceAll('-', '').trim().toLowerCase();
    if (target.endsWith(cleanS) || target.contains(cleanS)) {
      isCorrect = true;
    }

    if (isCorrect) {
      _soundService.playCorrect();
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
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = state.lastAnswerCorrect == null;

          if (isNewQuestion || isRetry) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _showConfetti = false;
              _activeSuffixIndex = null;
              _hoveringSuffixIndex = null;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          final xp = state.xpEarned;
          final coins = state.coinsEarned;
          setState(() => _showConfetti = true);
          if (!context.mounted) return;
          GameDialogHelper.showCompletion(
            context,
            xp: xp,
            coins: coins,
            title: 'WORD ARCHITECT!',
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
        final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);

        if (state is VocabularyLoading || (state is! VocabularyGameComplete && state is! VocabularyLoaded && state is! VocabularyError)) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;


        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;
        final options = quest?.options ?? [];
        final root = quest?.rootWord ?? quest?.word ?? "";

        // Sync with bloc state
        final loadedState = (state is VocabularyLoaded) ? state : null;
        _isAnswered = loadedState?.lastAnswerCorrect != null;
        _isCorrect = loadedState?.lastAnswerCorrect;


        // Use hovering suffix if dragging, otherwise use active selection
        final displaySuffixIndex = _hoveringSuffixIndex ?? _activeSuffixIndex;
        final activeSuffix = (displaySuffixIndex != null && options.isNotEmpty && displaySuffixIndex < options.length)
            ? options[displaySuffixIndex]
            : null;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          useScrolling: false,
          onHint: () {
            // Find correct suffix index
            final correct = quest?.correctAnswer ?? "";
            final options = quest?.options ?? [];
            int? correctIdx;
            for (int i = 0; i < options.length; i++) {
              final cleanS = options[i].replaceAll('-', '').trim().toLowerCase();
              if (correct.toLowerCase().endsWith(cleanS) || correct.toLowerCase().contains(cleanS)) {
                correctIdx = i;
                break;
              }
            }
            if (correctIdx != null) {
              setState(() => _hoveringSuffixIndex = correctIdx);
              // Auto-reset after a short delay if they don't drag
              Future.delayed(2.seconds, () {
                if (mounted && !_isAnswered) {
                  setState(() => _hoveringSuffixIndex = null);
                }
              });
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 25.h),
              _buildReactionCore(
                quest,
                root,
                activeSuffix,
                theme.primaryColor,
                isDark,
              ),
              SizedBox(height: 30.h),
              _buildInjectionRails(
                options,
                root,
                quest?.correctAnswer ?? "",
                theme.primaryColor,
                isDark,
              ),
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
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        "SLIDE FUEL CELLS INTO THE REACTION CORE",
        style: GoogleFonts.outfit(
          fontSize: 9.sp,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildReactionCore(
    GameQuest? quest,
    String root,
    String? suffix,
    Color color,
    bool isDark,
  ) {
    return SizedBox(
      height: 180.h,
      width: 1.sw,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Energy Field Glow - RepaintBoundary for optimization
          RepaintBoundary(
            child:
                Container(
                      width: 200.r,
                      height: 200.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.15),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.2, 1.2),
                      duration: 2.seconds,
                    ),
          ),

          // Hexagonal Chamber
          RepaintBoundary(
                child: Container(
                  width: 240.w,
                  height: 140.h,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30.r),
                    child: Stack(
                      children: [
                        // Dynamic Liquid/Energy Background
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  color.withValues(alpha: 0.05),
                                  color.withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Word Text with Shimmer
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                (_isAnswered
                                        ? (quest?.correctAnswer ?? "")
                                        : root)
                                    .toUpperCase(),
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  letterSpacing: 4,
                                ),
                              ).animate().fadeIn().shimmer(duration: 2.seconds),
                              if (suffix != null && !_isAnswered) ...[
                                SizedBox(height: 8.h),
                                Icon(
                                  Icons.add_rounded,
                                  color: color,
                                  size: 20.r,
                                ),
                                Text(
                                  suffix.toUpperCase(),
                                  style: GoogleFonts.shareTechMono(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    letterSpacing: 2,
                                  ),
                                ).animate().slideY(begin: 0.5, end: 0),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: -5,
                end: 5,
                duration: 3.seconds,
                curve: Curves.easeInOutQuad,
              ),

          // Particle Orbits - Optimized with RepaintBoundary
          ...List.generate(3, (index) {
            return RepaintBoundary(child: _buildEnergyOrbit(index, color));
          }),
        ],
      ),
    );
  }

  Widget _buildEnergyOrbit(int index, Color color) {
    final duration = (2 + index).seconds;
    return Container(
      width: (260 + (index * 20)).w,
      height: (160 + (index * 20)).h,
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        borderRadius: BorderRadius.circular(100.r),
      ),
    ).animate(onPlay: (c) => c.repeat()).rotate(duration: duration);
  }

  Widget _buildInjectionRails(
    List<String> options,
    String root,
    String correct,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: options.asMap().entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: SizedBox(
              width: 1.sw,
              height: 60.h,
              child: MorphInjectionRail(
                index: entry.key,
                suffix: entry.value,
                color: color,
                isDark: isDark,
                isBlocked: _isAnswered,
                onMorph: (suffix) {
                  _submitMorph(suffix, root, correct, entry.key);
                },
                onHover: (index) {
                  if (!_isAnswered) {
                    setState(() => _hoveringSuffixIndex = index);
                  }
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class MorphInjectionRail extends StatefulWidget {
  final int index;
  final String suffix;
  final Color color;
  final bool isDark;
  final bool isBlocked;
  final Function(String) onMorph;
  final Function(int?) onHover;

  const MorphInjectionRail({
    super.key,
    required this.index,
    required this.suffix,
    required this.color,
    required this.isDark,
    required this.isBlocked,
    required this.onMorph,
    required this.onHover,
  });

  @override
  State<MorphInjectionRail> createState() => _MorphInjectionRailState();
}

class _MorphInjectionRailState extends State<MorphInjectionRail> {
  final ValueNotifier<double> _progress = ValueNotifier(0.0);
  bool _isFusing = false;

  @override
  void didUpdateWidget(MorphInjectionRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBlocked != oldWidget.isBlocked && !widget.isBlocked) {
      _progress.value = 0.0;
      _isFusing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final railWidth = constraints.maxWidth > 0
            ? constraints.maxWidth
            : 1.sw - 48.w;
        final handleWidth = 110.w;
        final maxSlide = railWidth - handleWidth;

        return Container(
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.25),
              width: 2,
            ),
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: Stack(
              children: [
                // Rail Path - RepaintBoundary for static content
                const RepaintBoundary(child: _RailPathIndicators()),

                // Dynamic Energy Glow - Positioned with ValueListenable
                ValueListenableBuilder<double>(
                  valueListenable: _progress,
                  builder: (context, value, _) {
                    return Positioned(
                      left: (value * maxSlide) - 20.w,
                      child: RepaintBoundary(
                        child: Container(
                          width: handleWidth + 40.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                widget.color.withValues(alpha: 0.2),
                                widget.color.withValues(alpha: 0.0),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // The Handle - Optimized interaction
                ValueListenableBuilder<double>(
                  valueListenable: _progress,
                  builder: (context, value, _) {
                    return Positioned(
                      left: value * maxSlide,
                      child: GestureDetector(
                        onTap: () {
                          if (widget.isBlocked || _isFusing) return;
                          _progress.value = 1.0;
                          _isFusing = true;
                          widget.onMorph(widget.suffix);
                        },
                        onHorizontalDragUpdate: (details) {
                          if (widget.isBlocked || _isFusing) return;
                          _progress.value =
                              (_progress.value + details.delta.dx / maxSlide)
                                  .clamp(0.0, 1.0);

                          if (_progress.value > 0.2) {
                            widget.onHover(widget.index);
                          } else {
                            widget.onHover(null);
                          }

                          if (_progress.value >= 0.95 && !_isFusing) {
                            _isFusing = true;
                            widget.onMorph(widget.suffix);
                          }
                        },
                        onHorizontalDragEnd: (_) {
                          widget.onHover(null);
                          if (!_isFusing) {
                            _progress.value = 0.0;
                          }
                        },
                        child: RepaintBoundary(
                          child: _HandleDecoration(
                            color: widget.color,
                            suffix: widget.suffix,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RailPathIndicators extends StatelessWidget {
  const _RailPathIndicators();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.drag_handle_rounded, color: Colors.black12, size: 20),
            Icon(Icons.chevron_right_rounded, color: Colors.black12, size: 20),
            Icon(Icons.chevron_right_rounded, color: Colors.black12, size: 20),
            Icon(Icons.chevron_right_rounded, color: Colors.black12, size: 20),
            Icon(Icons.bolt_rounded, color: Colors.black12, size: 22),
          ],
        ),
      ),
    );
  }
}

class _HandleDecoration extends StatelessWidget {
  final Color color;
  final String suffix;
  const _HandleDecoration({required this.color, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110.w,
      height: 60.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.drag_indicator_rounded,
              color: Colors.white70,
              size: 18,
            ),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                suffix.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  const GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double i = 0; i <= size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
