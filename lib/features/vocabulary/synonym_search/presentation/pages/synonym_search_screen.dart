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

class SynonymSearchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SynonymSearchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.synonymSearch,
  });

  @override
  State<SynonymSearchScreen> createState() => _SynonymSearchScreenState();
}

class _SynonymSearchScreenState extends State<SynonymSearchScreen>
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  // Warp Interaction State
  final Map<int, Offset> _shardOffsets = {};
  final Map<int, bool> _isWarping = {};
  final Map<int, List<Offset>> _shardTrails = {};
  int? _activeShardIndex;
  BoxConstraints? _lastConstraints;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _initShards(int count) {
    _shardOffsets.clear();
    _isWarping.clear();
    _shardTrails.clear();
    for (int i = 0; i < count; i++) {
      _shardOffsets[i] = Offset.zero;
      _isWarping[i] = false;
      _shardTrails[i] = [];
    }
  }

  void _onShardDragStart(int index, DragStartDetails details) {
    if (_isAnswered || _isWarping[index] == true) return;
    setState(() {
      _activeShardIndex = index;
      _shardTrails[index] = [];
    });
    _hapticService.light();
  }

  void _onShardDragUpdate(int index, DragUpdateDetails details) {
    if (_isAnswered || _activeShardIndex != index) return;
    setState(() {
      _shardOffsets[index] =
          (_shardOffsets[index] ?? Offset.zero) + details.delta;

      // Update trail
      final trail = _shardTrails[index] ?? [];
      trail.add(_shardOffsets[index]!);
      if (trail.length > 10) trail.removeAt(0);
      _shardTrails[index] = trail;
    });

    // Check for "near gate" haptic feedback
    final currentOffset = _shardOffsets[index] ?? Offset.zero;
    final shardInitialPos = _getShardInitialPosition(
      index,
      (_lastQuest?.options?.length ?? 4),
      _lastConstraints!,
    );
    final currentPos = shardInitialPos + currentOffset;
    if (currentPos.distance < 120.r && currentPos.distance > 100.r) {
      _hapticService.selection();
    }
  }

  void _onShardDragEnd(int index, VocabularyQuest quest) {
    if (_isAnswered || _activeShardIndex != index) return;

    final currentOffset = _shardOffsets[index] ?? Offset.zero;
    final options = quest.options ?? [];
    final selectedText = options[index];

    final shardInitialPos = _getShardInitialPosition(
      index,
      options.length,
      _lastConstraints!,
    );
    final currentPos = shardInitialPos + currentOffset;

    if (currentPos.distance < 100.r) {
      _warpShard(index, selectedText, quest);
    } else {
      // Snap back
      setState(() {
        _shardOffsets[index] = Offset.zero;
        _shardTrails[index] = [];
        _activeShardIndex = null;
      });
      _hapticService.light();
    }
  }

  void _warpShard(int index, String text, VocabularyQuest quest) {
    setState(() {
      _isWarping[index] = true;
      _activeShardIndex = null;
    });

    final correct = quest.correctAnswer?.trim().toLowerCase() ?? "";
    final isCorrect = text.trim().toLowerCase() == correct;

    if (isCorrect) {
      _hapticService.success();
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

  Offset _getShardInitialPosition(
    int index,
    int total,
    BoxConstraints constraints,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final double safeWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : screenSize.width;
    final double safeHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : (screenSize.height * 0.6);

    double hDist = (safeWidth - 100.w) / 2;
    double vDist = (safeHeight - 120.h) / 2;

    hDist = hDist.clamp(90.w, 130.w);
    vDist = vDist.clamp(120.h, 140.h);

    switch (index) {
      case 0:
        return Offset(-hDist, -vDist); // Top Left (Perfect)
      case 1:
        return Offset(hDist, -vDist); // Top Right (Perfect)
      case 2:
        return Offset(-hDist, vDist + 90.h); // Bottom Left (Increased Space)
      case 3:
        return Offset(hDist, vDist + 90.h); // Bottom Right (Increased Space)
      default:
        double angle = (index * (2 * math.pi / total)) - (math.pi / 2);
        return Offset(math.cos(angle) * hDist, math.sin(angle) * vDist);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          if (state.currentIndex != _lastProcessedIndex ||
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _initShards(state.currentQuest.options?.length ?? 0);
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'WORD WARP COMPLETE!',
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
        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;
        if (quest == null && state is! VocabularyGameComplete) {
          return const GameShimmerLoading();
        }

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: (state is VocabularyLoaded)
              ? state.isFinalFailure
              : false,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () {
            final options = quest?.options ?? [];
            final correct = quest?.correctAnswer?.toLowerCase() ?? "";
            for (int i = 0; i < options.length; i++) {
              if (options[i].toLowerCase() == correct) {
                // Pulse the correct shard
                setState(
                  () => _shardOffsets[i] =
                      _getShardInitialPosition(
                        i,
                        options.length,
                        _lastConstraints!,
                      ) *
                      -0.2,
                );
                Future.delayed(1.seconds, () {
                  if (mounted && !_isAnswered) {
                    setState(() => _shardOffsets[i] = Offset.zero);
                  }
                });
                break;
              }
            }
          },
          child: quest == null
              ? const SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    _lastConstraints = constraints;
                    final screenSize = MediaQuery.of(context).size;
                    final double safeWidth = constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : screenSize.width;
                    final double safeHeight = constraints.maxHeight.isFinite
                        ? constraints.maxHeight
                        : (screenSize.height * 0.6);

                    return SizedBox(
                      width: safeWidth,
                      height: safeHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Cosmic Grid Background
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: CosmicGridPainter(
                                  theme.primaryColor.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                          ),

                          _buildWarpGate(
                            quest.word ?? "",
                            theme.primaryColor,
                            isDark,
                          ),

                          // Optimized Shard Trails (Drawn on main stack)
                          ...List.generate(quest.options?.length ?? 0, (i) {
                            if (_activeShardIndex == i &&
                                _shardTrails[i] != null) {
                              final initialPos = _getShardInitialPosition(
                                i,
                                quest.options!.length,
                                constraints,
                              );
                              // Convert relative trail points to absolute screen points
                              final absoluteTrail = _shardTrails[i]!
                                  .map(
                                    (offset) => Offset(
                                      constraints.maxWidth / 2 +
                                          initialPos.dx +
                                          offset.dx,
                                      constraints.maxHeight / 2 +
                                          initialPos.dy +
                                          offset.dy,
                                    ),
                                  )
                                  .toList();

                              return Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: TrailPainter(
                                      absoluteTrail,
                                      theme.primaryColor,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),

                          ...List.generate(quest.options?.length ?? 0, (i) {
                            return _buildWordShard(
                              i,
                              quest.options![i],
                              theme.primaryColor,
                              isDark,
                              quest.options!.length,
                              constraints,
                              quest,
                            );
                          }),

                          Positioned(
                            top: 10.h,
                            child: _buildInstruction(theme.primaryColor),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cyclone_rounded, size: 16.r, color: color),
              SizedBox(width: 10.w),
              Text(
                "WARP THE SYNONYM SHARD",
                style: GoogleFonts.shareTechMono(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: 3.seconds,
          color: Colors.white.withValues(alpha: 0.3),
        )
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 2.seconds,
          curve: Curves.easeInOut,
        );
  }

  Widget _buildWarpGate(String word, Color color, bool isDark) {
    return RepaintBoundary(
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Nebula
            Container(
                  width: 220.r,
                  height: 220.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.3, 1.3),
                  duration: 3.seconds,
                  curve: Curves.easeInOut,
                )
                .fadeOut(),

            // The Portal Core
            Container(
                  width: 180.r,
                  height: 180.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.8),
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 80,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Swirling Vortex Effect
                        Positioned.fill(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: VortexPainter(color),
                                ),
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .rotate(duration: 10.seconds),

                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(25.r),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                word.toUpperCase(),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: GoogleFonts.outfit(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 12,
                                    ),
                                    Shadow(color: color, blurRadius: 25),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.05, 1.05),
                  duration: 2.seconds,
                ),

            // Orbital Shards (Visual Decor)
            ...List.generate(4, (i) => _buildOrbitalParticle(i, color)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbitalParticle(int index, Color color) {
    final duration = (3 + index).seconds;
    return RotationTransition(
      turns: AlwaysStoppedAnimation(index * 0.25),
      child: SizedBox(
        width: 170.r,
        height: 170.r,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 8.r,
            height: 8.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color, blurRadius: 15, spreadRadius: 2),
              ],
            ),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).rotate(duration: duration);
  }

  Widget _buildWordShard(
    int index,
    String text,
    Color color,
    bool isDark,
    int total,
    BoxConstraints constraints,
    VocabularyQuest quest,
  ) {
    final initialPos = _getShardInitialPosition(index, total, constraints);
    final offset = _shardOffsets[index] ?? Offset.zero;
    final isWarping = _isWarping[index] ?? false;
    final isActive = _activeShardIndex == index;

    final screenSize = MediaQuery.of(context).size;
    final double safeWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : screenSize.width;
    final double safeHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : (screenSize.height * 0.6);

    return Stack(
      children: [
        // The Shard Body
        Positioned(
              left: safeWidth / 2 + initialPos.dx + offset.dx - 45.w,
              top: safeHeight / 2 + initialPos.dy + offset.dy - 35.h,
              child: GestureDetector(
                onPanStart: (d) => _onShardDragStart(index, d),
                onPanUpdate: (d) => _onShardDragUpdate(index, d),
                onPanEnd: (d) => _onShardDragEnd(index, quest),
                child: TweenAnimationBuilder<double>(
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                  tween: Tween(
                    begin: 1.0,
                    end: isWarping ? 0.0 : (isActive ? 1.15 : 1.0),
                  ),
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: isWarping ? 0.0 : 1.0,
                      child: child,
                    ),
                  ),
                  child: Container(
                    width: 90.w,
                    height: 70.h,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: isActive ? color : color.withValues(alpha: 0.4),
                        width: isActive ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: isActive ? 0.5 : 0.15),
                          blurRadius: isActive ? 25 : 15,
                          spreadRadius: isActive ? 2 : 0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Tech Glow Pattern (Optimized)
                        Opacity(
                          opacity: 0.15,
                          child: RepaintBoundary(
                            child: CustomPaint(
                              size: Size(90.w, 70.h),
                              painter: TechPatternPainter(color),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.r),
                          child: Text(
                            text.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.shareTechMono(
                              fontSize: 12.sp,
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: -8,
              end: 8,
              duration: (2 + index * 0.5).seconds,
              curve: Curves.easeInOut,
            )
            .rotate(
              begin: -0.02,
              end: 0.02,
              duration: (3 + index).seconds,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}

class CosmicGridPainter extends CustomPainter {
  final Color color;
  CosmicGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrailPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  TrailPainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    // Draw glowing points for the trail
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < points.length; i++) {
      final double progress = i / points.length;
      dotPaint.color = color.withValues(alpha: progress * 0.4);
      canvas.drawCircle(points[i], (2 + progress * 3).r, dotPaint);
    }
  }

  @override
  bool shouldRepaint(TrailPainter oldDelegate) => true;
}

class VortexPainter extends CustomPainter {
  final Color color;
  VortexPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 5; i++) {
      double radius = (i + 1) * 15.0;
      canvas.drawCircle(center, radius, paint);
      // Add spiral segments
      double angle = i * math.pi / 2;
      canvas.drawLine(
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        center +
            Offset(
              math.cos(angle + 0.5) * (radius + 10),
              math.sin(angle + 0.5) * (radius + 10),
            ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TechPatternPainter extends CustomPainter {
  final Color color;
  TechPatternPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height * 0.2),
      Offset(size.width * 0.3, size.height * 0.2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.8),
      Offset(size.width, size.height * 0.8),
      paint,
    );
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 3, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
