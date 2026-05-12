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

class _AntonymSearchScreenState extends State<AntonymSearchScreen>
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  // Polarity State
  bool _targetIsPositive = true; // True = Blue (+), False = Red (-)
  final Map<int, Offset> _shardOffsets = {};
  final Map<int, bool> _isFused = {};
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
    _isFused.clear();
    _targetIsPositive = math.Random().nextBool();
    for (int i = 0; i < count; i++) {
      _shardOffsets[i] = Offset.zero;
      _isFused[i] = false;
    }
  }

  void _onShardDragStart(int index) {
    if (_isAnswered || _isFused[index] == true) return;
    setState(() {
      _activeShardIndex = index;
    });
    _hapticService.light();
  }

  void _onShardDragUpdate(int index, DragUpdateDetails details) {
    if (_isAnswered || _activeShardIndex != index) return;
    setState(() {
      _shardOffsets[index] =
          (_shardOffsets[index] ?? Offset.zero) + details.delta;
    });

    // Proximity haptics to poles
    final currentPos = _getShardCurrentPosition(index);
    final topPolePos = _getPolePosition(true);
    final bottomPolePos = _getPolePosition(false);
    
    if (topPolePos == Offset.zero || bottomPolePos == Offset.zero) return;

    final topPoleDist = (currentPos - topPolePos).distance;
    final bottomPoleDist = (currentPos - bottomPolePos).distance;

    if (topPoleDist < 120.r || bottomPoleDist < 120.r) {
      _hapticService.selection();
    }
  }

  void _onShardDragEnd(int index, VocabularyQuest quest) {
    if (_isAnswered || _activeShardIndex != index) return;

    final currentPos = _getShardCurrentPosition(index);
    final topPoleDist = (currentPos - _getPolePosition(true)).distance;
    final bottomPoleDist = (currentPos - _getPolePosition(false)).distance;

    // Capture logic
    if (topPoleDist < 100.r) {
      _attemptFusion(index, true, quest);
    } else if (bottomPoleDist < 100.r) {
      _attemptFusion(index, false, quest);
    } else {
      // Snap back
      setState(() {
        _shardOffsets[index] = Offset.zero;
        _activeShardIndex = null;
      });
      _hapticService.light();
    }
  }

  void _attemptFusion(int index, bool isTopPole, VocabularyQuest quest) {
    final text = quest.options![index];
    final correct = quest.correctAnswer?.trim().toLowerCase() ?? "";
    final isCorrectText = text.trim().toLowerCase() == correct;

    // Logic: Drag to OPPOSITE pole
    // If target is Positive (+), drag to Bottom Pole (Negative -)
    // If target is Negative (-), drag to Top Pole (Positive +)
    final targetPoleIsOpposite = isTopPole != _targetIsPositive;

    if (isCorrectText && targetPoleIsOpposite) {
      _triggerSuccess(index);
    } else {
      _triggerFailure(index);
    }
  }

  void _triggerSuccess(int index) {
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

  void _triggerFailure(int index) {
    _hapticService.error();
    _soundService.playWrong();
    setState(() {
      _isAnswered = true;
      _isCorrect = false;
      _activeShardIndex = null;
      _shardOffsets[index] = Offset.zero;
    });
    context.read<VocabularyBloc>().add(SubmitAnswer(false));
  }

  Offset _getShardCurrentPosition(int index) {
    if (_lastConstraints == null) return Offset.zero;
    final initial = _getShardInitialPosition(index, (_lastQuest?.options?.length ?? 4), _lastConstraints!);
    return initial + (_shardOffsets[index] ?? Offset.zero);
  }

  Offset _getPolePosition(bool isTop) {
    if (_lastConstraints == null) return Offset.zero;
    final h = _lastConstraints!.maxHeight;
    // Pole Y is roughly top/bottom of the stack
    return Offset(0, isTop ? -h / 2 + 50.h : h / 2 - 50.h);
  }

  Offset _getShardInitialPosition(int index, int total, BoxConstraints constraints) {
    final safeWidth = constraints.maxWidth;
    final hDist = safeWidth / 2 - 80.w;
    final vStep = 80.h;
    final startY = -((total - 1) * vStep) / 2;
    
    final isLeft = index % 2 == 0;
    return Offset(isLeft ? -hDist : hDist, startY + (index * vStep));
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
            title: 'POLARITY MASTERED!',
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
          child: quest == null
              ? const SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    _lastConstraints = constraints;
                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Background Flux Field
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: MagneticFluxPainter(isDark ? Colors.white10 : Colors.black12),
                            ),
                          ),
                        ),

                        // The Poles
                        _buildPole(true),
                        _buildPole(false),

                        // Magnetic Chamber (Target Word)
                        _buildMagneticChamber(quest.word ?? "", _targetIsPositive ? const Color(0xFF00D2FF) : const Color(0xFFFF3D00)),

                        // Shards
                        ...List.generate(quest.options?.length ?? 0, (i) {
                          return _buildPolarityShard(i, quest.options![i], theme.primaryColor, isDark);
                        }),

                        // Electric Arcs (When dragging)
                        if (_activeShardIndex != null)
                          _buildElectricArc(),

                        Positioned(top: 100.h, child: _buildInstruction(_targetIsPositive ? const Color(0xFF00D2FF) : const Color(0xFFFF3D00))),
                      ],
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
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        "PULL ANTONYM TO OPPOSITE POLE",
        style: GoogleFonts.shareTechMono(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds);
  }

  Widget _buildPole(bool isTop) {
    final glowColor = isTop ? const Color(0xFF00D2FF) : const Color(0xFFFF3D00);
    
    return Positioned(
      top: isTop ? 10.h : null,
      bottom: isTop ? null : 10.h,
      child: Container(
        width: 250.w,
        height: 60.h,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: glowColor, width: 3),
          boxShadow: [
            BoxShadow(color: glowColor.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 5),
          ],
        ),
        child: Center(
          child: Text(
            isTop ? "POSITIVE POLE [+]" : "NEGATIVE POLE [-]",
            style: GoogleFonts.shareTechMono(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: glowColor,
              letterSpacing: 2,
            ),
          ),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds),
    );
  }

  Widget _buildMagneticChamber(String word, Color color) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color, width: 4),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 10),
          ],
        ),
        child: Text(
          word.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 22.sp,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 4,
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds);
  }

  Widget _buildPolarityShard(int index, String text, Color color, bool isDark) {
    final initial = _getShardInitialPosition(index, (_lastQuest?.options?.length ?? 4), _lastConstraints!);
    final offset = _shardOffsets[index] ?? Offset.zero;
    final isDragging = _activeShardIndex == index;
    final isFused = _isFused[index] ?? false;

    return Positioned(
      left: _lastConstraints!.maxWidth / 2 + initial.dx + offset.dx - 60.w,
      top: _lastConstraints!.maxHeight / 2 + initial.dy + offset.dy - 30.h,
      child: GestureDetector(
        onPanStart: (_) => _onShardDragStart(index),
        onPanUpdate: (d) => _onShardDragUpdate(index, d),
        onPanEnd: (_) => _onShardDragEnd(index, _lastQuest!),
        child: Opacity(
          opacity: isFused ? 0 : 1,
          child: Transform.scale(
            scale: isDragging ? 1.1 : 1.0,
            child: Container(
              width: 120.w,
              height: 60.h,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(color: isDragging ? color : color.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: (2 + index).seconds);
  }

  Widget _buildElectricArc() {
    if (_activeShardIndex == null || _lastConstraints == null) return const SizedBox();
    
    final shardPos = _getShardCurrentPosition(_activeShardIndex!);
    final topDist = (shardPos - _getPolePosition(true)).distance;
    final bottomDist = (shardPos - _getPolePosition(false)).distance;
    
    final targetPoleIsTop = topDist < bottomDist;
    final polePos = _getPolePosition(targetPoleIsTop);
    
    if (math.min(topDist, bottomDist) > 180.r) return const SizedBox();

    return RepaintBoundary(
      child: CustomPaint(
        painter: ElectricArcPainter(
          start: shardPos,
          end: polePos,
          color: targetPoleIsTop ? const Color(0xFF00D2FF) : const Color(0xFFFF3D00),
          screenSize: Size(_lastConstraints!.maxWidth, _lastConstraints!.maxHeight),
        ),
      ),
    );
  }
}

class MagneticFluxPainter extends CustomPainter {
  final Color color;
  MagneticFluxPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (int i = 1; i <= 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(centerX, centerY), width: i * 150.w, height: i * 180.h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ElectricArcPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  final Size screenSize;

  ElectricArcPainter({required this.start, required this.end, required this.color, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final random = math.Random();
    
    final absStart = Offset(screenSize.width / 2 + start.dx, screenSize.height / 2 + start.dy);
    final absEnd = Offset(screenSize.width / 2 + end.dx, screenSize.height / 2 + end.dy);
    
    path.moveTo(absStart.dx, absStart.dy);
    
    for (int i = 1; i <= 8; i++) {
      final t = i / 8;
      final point = Offset.lerp(absStart, absEnd, t)!;
      final offset = Offset(
        (random.nextDouble() - 0.5) * 30,
        (random.nextDouble() - 0.5) * 30,
      );
      path.lineTo(point.dx + offset.dx, point.dy + offset.dy);
    }
    
    canvas.drawPath(path, paint);
    
    // Outer Glow
    paint.strokeWidth = 6.0;
    paint.color = color.withValues(alpha: 0.2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
