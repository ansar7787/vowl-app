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

class AntonymSearchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AntonymSearchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.antonymSearch,
  });
  @override
  State<AntonymSearchScreen> createState() => _AntonymSearchScreenState();
}

class _AntonymSearchScreenState extends State<AntonymSearchScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;
  bool _targetIsPositive = true;

  final Map<int, Offset> _shardOffsets = {};
  final Map<int, bool> _isFused = {};
  int? _activeShardIndex;
  BoxConstraints? _lastConstraints;

  @override
  void initState() {
    super.initState();
    _targetIsPositive = math.Random().nextBool();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetColor = _targetIsPositive
        ? const Color(0xFF00E5FF)
        : const Color(0xFFFF4D00);

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
              _targetIsPositive = math.Random().nextBool();
              _isFused.clear();
              _shardOffsets.clear();
              _activeShardIndex = null;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'POLARITY MASTER!',
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

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          isFinalFailure: state is VocabularyLoaded
              ? state.isFinalFailure
              : false,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () =>
              context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          useScrolling: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _lastConstraints = constraints;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Magnetic Flux Background
                  Positioned.fill(
                    child: CustomPaint(painter: FluxGridPainter(isDark)),
                  ),

                  _buildPulsar(true), // Top [+]
                  _buildPulsar(false), // Bottom [-]

                  Center(
                    child: _buildNebulaCore(
                      quest?.word ?? "",
                      targetColor,
                      isDark,
                    ),
                  ),

                  ...List.generate(
                    quest?.options?.length ?? 0,
                    (i) => _buildOptionShard(
                      i,
                      quest!.options![i],
                      theme.primaryColor,
                      isDark,
                    ),
                  ),

                  if (_activeShardIndex != null)
                    _buildPlasmaThunder(targetColor),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPulsar(bool isTop) {
    final color = isTop ? const Color(0xFF00E5FF) : const Color(0xFFFF4D00);
    final isActive = isTop != _targetIsPositive;

    return Positioned(
          top: isTop ? 10.h : null,
          bottom: isTop ? null : 10.h,
          left: 20.w,
          right: 20.w,
          child: Container(
            height: 80.h,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: color.withValues(alpha: isActive ? 1.0 : 0.2),
                width: isActive ? 3 : 1,
              ),
              boxShadow: [
                if (isActive)
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 25,
                  ),
              ],
            ),
            child: Center(
              child: Text(
                isTop ? "POSITIVE PULSAR [+]" : "NEGATIVE PULSAR [-]",
                style: GoogleFonts.shareTechMono(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: color.withValues(alpha: isActive ? 1.0 : 0.3),
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 4.seconds);
  }

  Widget _buildNebulaCore(String word, Color color, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "DRAG TO OPPOSITE",
          style: GoogleFonts.shareTechMono(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1,
          ),
        ).animate().fadeIn(),
        SizedBox(height: 15.h),
        Container(
              width: 140.r,
              height: 140.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.black : Colors.white,
                border: Border.all(
                  color: color.withValues(alpha: 0.8),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                        child: CustomPaint(painter: CorePainter(color)),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .rotate(duration: 12.seconds),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _targetIsPositive ? "[+]" : "[-]",
                        style: GoogleFonts.shareTechMono(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: FittedBox(
                          child: Text(
                            word.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.04, 1.04),
              duration: 2.seconds,
            ),
      ],
    );
  }

  Offset _getInitialPosition(int index) {
    if (_lastConstraints == null) return Offset.zero;
    final w = _lastConstraints!.maxWidth;
    final isLeft = index % 2 == 0;
    final int total = _lastQuest?.options?.length ?? 4;
    final int halfTotal = (total / 2).ceil();
    final bool isBottomHalf = index >= halfTotal;

    // Vertical: Absolute points from top
    double yPos;
    if (total <= 4) {
      // 2 at top, 2 at bottom
      yPos = isBottomHalf ? 530.h : 175.h;
    } else {
      // Standard grid for 6 or 8 cards
      if (index < 2) {
        yPos = 110.h;
      } else if (index < 4) {
        yPos = 210.h;
      } else if (index < 6) {
        yPos = 520.h;
      } else {
        yPos = 620.h;
      }
    }

    return Offset(isLeft ? (w * 0.25) : (w * 0.75), yPos);
  }

  Widget _buildOptionShard(int index, String text, Color color, bool isDark) {
    final initial = _getInitialPosition(index);
    final offset = _shardOffsets[index] ?? Offset.zero;
    final isDragging = _activeShardIndex == index;
    final isFused = _isFused[index] ?? false;

    return Positioned(
      left: initial.dx + offset.dx - 70.w,
      top: initial.dy + offset.dy - 35.h,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => _onShardStart(index),
        onPanUpdate: (d) => _onShardUpdate(index, d),
        onPanEnd: (_) => _onShardEnd(index),
        child:
            Container(
                  width: 140.w,
                  height: 70.h,
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF1E293B) : Colors.white)
                        .withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isDragging ? color : color.withValues(alpha: 0.2),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: BackdropFilter(
                      filter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.05),
                        BlendMode.darken,
                      ),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(10.r),
                          child: FittedBox(
                            child: Text(
                              text.toUpperCase(),
                              style: GoogleFonts.shareTechMono(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .animate(target: isFused ? 1 : 0)
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(0, 0),
                  duration: 400.ms,
                  curve: Curves.easeInBack,
                )
                .fadeOut()
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -3, end: 3, duration: (2 + index * 0.4).seconds),
      ),
    );
  }

  void _onShardStart(int index) {
    if (_isAnswered || _isFused[index] == true) return;
    setState(() => _activeShardIndex = index);
    _hapticService.light();
  }

  void _onShardUpdate(int index, DragUpdateDetails details) {
    if (_activeShardIndex != index) return;
    setState(
      () => _shardOffsets[index] =
          (_shardOffsets[index] ?? Offset.zero) + details.delta,
    );
    final initial = _getInitialPosition(index);
    final currentY = initial.dy + (_shardOffsets[index]?.dy ?? 0);
    if (currentY < 120.h || currentY > 680.h) _hapticService.selection();
  }

  void _onShardEnd(int index) {
    if (_activeShardIndex != index || _lastConstraints == null) return;
    final initial = _getInitialPosition(index);
    final offset = _shardOffsets[index] ?? Offset.zero;
    final currentY = initial.dy + offset.dy;

    // Use actual constraints for reliable detection
    final maxHeight = _lastConstraints!.maxHeight;
    final bool nearTop = currentY < 130.h;
    final bool nearBottom = currentY > (maxHeight - 130.h);

    if (nearTop || nearBottom) {
      final bool toPositive = nearTop;
      final bool isOpposite =
          (toPositive && !_targetIsPositive) ||
          (!toPositive && _targetIsPositive);
      final bool isAntonym =
          _lastQuest!.options![index].trim().toLowerCase() ==
          _lastQuest!.correctAnswer?.trim().toLowerCase();

      if (isAntonym && isOpposite) {
        _onSuccess(index);
      } else {
        _onFailure(index);
      }
    } else {
      setState(() {
        _shardOffsets[index] = Offset.zero;
        _activeShardIndex = null;
      });
    }
  }

  void _onSuccess(int index) {
    _hapticService.success();
    _soundService.playCorrect();
    setState(() {
      _isFused[index] = true;
      _isAnswered = true;
      _isCorrect = true;
      _activeShardIndex = null;
    });
    context.read<VocabularyBloc>().add(SubmitAnswer(true));
  }

  void _onFailure(int index) {
    _hapticService.error();
    _soundService.playWrong();
    setState(() {
      _shardOffsets[index] = Offset.zero;
      _isAnswered = true;
      _isCorrect = false;
      _activeShardIndex = null;
    });
    context.read<VocabularyBloc>().add(SubmitAnswer(false));
  }

  Widget _buildPlasmaThunder(Color color) {
    if (_activeShardIndex == null || _lastConstraints == null) {
      return const SizedBox();
    }
    final initial = _getInitialPosition(_activeShardIndex!);
    final offset = _shardOffsets[_activeShardIndex!] ?? Offset.zero;
    final current = initial + offset;
    final bool toTop = current.dy < 380.h;
    final targetY = toTop ? 90.h : (_lastConstraints!.maxHeight - 90.h);

    return IgnorePointer(
      child: CustomPaint(
        painter: PlasmaArcPainter(
          current,
          Offset(_lastConstraints!.maxWidth / 2, targetY),
          toTop ? const Color(0xFF00E5FF) : const Color(0xFFFF4D00),
        ),
      ),
    );
  }
}

class FluxGridPainter extends CustomPainter {
  final bool isDark;
  FluxGridPainter(this.isDark);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 40.w) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40.w) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CorePainter extends CustomPainter {
  final Color color;
  CorePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 10; i++) {
      canvas.drawCircle(center, (i + 1) * 7.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PlasmaArcPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  PlasmaArcPainter(this.start, this.end, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(start.dx, start.dy);
    final random = math.Random();
    final dist = (end - start).distance;
    final segments = (dist / 20).clamp(5, 15).toInt();
    for (int i = 1; i <= segments; i++) {
      final double t = i / segments;
      final p = Offset.lerp(start, end, t)!;
      if (i < segments) {
        path.lineTo(
          p.dx + (random.nextDouble() * 30 - 15),
          p.dy + (random.nextDouble() * 30 - 15),
        );
      } else {
        path.lineTo(end.dx, end.dy);
      }
    }
    canvas.drawPath(path, paint);
    paint.strokeWidth = 12;
    paint.color = color.withValues(alpha: 0.2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
