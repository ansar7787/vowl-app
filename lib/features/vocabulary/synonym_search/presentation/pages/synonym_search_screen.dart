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

class _SynonymSearchScreenState extends State<SynonymSearchScreen> with TickerProviderStateMixin {
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
  Offset? _dragStart;
  int? _activeShardIndex;
  BoxConstraints? _lastConstraints;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
  }

  void _initShards(int count) {
    _shardOffsets.clear();
    _isWarping.clear();
    for (int i = 0; i < count; i++) {
      _shardOffsets[i] = Offset.zero;
      _isWarping[i] = false;
    }
  }

  void _onShardDragStart(int index, DragStartDetails details) {
    if (_isAnswered || _isWarping[index] == true) return;
    setState(() {
      _activeShardIndex = index;
      _dragStart = details.globalPosition;
    });
    _hapticService.light();
  }

  void _onShardDragUpdate(int index, DragUpdateDetails details) {
    if (_isAnswered || _activeShardIndex != index) return;
    setState(() {
      _shardOffsets[index] = (_shardOffsets[index] ?? Offset.zero) + details.delta;
    });
  }

  void _onShardDragEnd(int index, VocabularyQuest quest) {
    if (_isAnswered || _activeShardIndex != index) return;
    
    final currentOffset = _shardOffsets[index] ?? Offset.zero;
    final options = quest.options ?? [];
    final selectedText = options[index];
    
    // Check if dragged into the central Warp Gate
    // The gate is at Center (0,0) relative to shards starting position
    // We calculate the distance of the shard's final position from the gate center
    final shardInitialPos = _getShardInitialPosition(index, options.length, _lastConstraints!);
    final currentPos = shardInitialPos + currentOffset;
    
    if (currentPos.distance < 80.r) {
      _warpShard(index, selectedText, quest);
    } else {
      // Snap back
      setState(() {
        _shardOffsets[index] = Offset.zero;
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

  Offset _getShardInitialPosition(int index, int total, BoxConstraints constraints) {
    final screenSize = MediaQuery.of(context).size;
    final double safeWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : screenSize.width;
    final double safeHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : (screenSize.height * 0.6);

    double hDist = (safeWidth - 120.w) / 2;
    double vDist = (safeHeight - 180.h) / 2;
    
    hDist = hDist.clamp(90.w, 150.w);
    vDist = vDist.clamp(110.h, 170.h);

    switch (index) {
      case 0: return Offset(-hDist, -vDist); // Top Left
      case 1: return Offset(hDist, -vDist);  // Top Right
      case 2: return Offset(-hDist, vDist);  // Bottom Left
      case 3: return Offset(hDist, vDist);   // Bottom Right
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
          if (state.currentIndex != _lastProcessedIndex || (state.lastAnswerCorrect == null && _isAnswered)) {
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
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;
        if (quest == null && state is! VocabularyGameComplete) return const GameShimmerLoading();

        return VocabularyBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          isFinalFailure: (state is VocabularyLoaded) ? state.isFinalFailure : false,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () {
            final options = quest?.options ?? [];
            final correct = quest?.correctAnswer?.toLowerCase() ?? "";
            for (int i = 0; i < options.length; i++) {
              if (options[i].toLowerCase() == correct) {
                setState(() => _shardOffsets[i] = _getShardInitialPosition(i, options.length, _lastConstraints!) * -0.4);
                Future.delayed(1.seconds, () {
                  if (mounted && !_isAnswered) setState(() => _shardOffsets[i] = Offset.zero);
                });
                break;
              }
            }
          },
          child: quest == null ? const SizedBox() : LayoutBuilder(
            builder: (context, constraints) {
              _lastConstraints = constraints;
              final screenSize = MediaQuery.of(context).size;
              final double safeWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : screenSize.width;
              final double safeHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : (screenSize.height * 0.6);

              return SizedBox(
                width: safeWidth,
                height: safeHeight,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _buildWarpGate(quest.word ?? "", theme.primaryColor, isDark),
                    ...List.generate(quest.options?.length ?? 0, (i) => _buildWordShard(i, quest.options![i], theme.primaryColor, isDark, quest.options!.length, constraints, quest)),
                    Positioned(top: 20.h, child: _buildInstruction(theme.primaryColor)),
                  ],
                ),
              );
            }
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Icon(Icons.vortex_rounded, size: 14.r, color: color),
          SizedBox(width: 8.w),
          Text("WARP THE SYNONYM INTO THE GATE", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -1, end: 0);
  }

  Widget _buildWarpGate(String word, Color color, bool isDark) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 180.r, height: 180.r,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withValues(alpha: 0.3), Colors.transparent])),
          ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds, curve: Curves.easeInOut).fadeOut(),

          // The Gate Ring
          Container(
            width: 130.r, height: 130.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2)],
            ),
            child: Center(
              child: Text(word.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),

          // Orbiting Particles
          ...List.generate(3, (i) => _buildOrbitalParticle(i, color)),
        ],
      ),
    );
  }

  Widget _buildOrbitalParticle(int index, Color color) {
    return RotationTransition(
      turns: AlwaysStoppedAnimation(index * 0.33),
      child: Container(
        width: 150.r, height: 150.r,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 6.r, height: 6.r,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 10)]),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).rotate(duration: (2 + index).seconds);
  }

  Widget _buildWordShard(int index, String text, Color color, bool isDark, int total, BoxConstraints constraints, VocabularyQuest quest) {
    final initialPos = _getShardInitialPosition(index, total, constraints);
    final offset = _shardOffsets[index] ?? Offset.zero;
    final isWarping = _isWarping[index] ?? false;
    final isActive = _activeShardIndex == index;

    final screenSize = MediaQuery.of(context).size;
    final double safeWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : screenSize.width;
    final double safeHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : (screenSize.height * 0.6);

    return Positioned(
      left: safeWidth / 2 + initialPos.dx + offset.dx - 45.w,
      top: safeHeight / 2 + initialPos.dy + offset.dy - 35.h,
      child: GestureDetector(
        onPanStart: (d) => _onShardDragStart(index, d),
        onPanUpdate: (d) => _onShardDragUpdate(index, d),
        onPanEnd: (d) => _onShardDragEnd(index, quest),
        child: TweenAnimationBuilder<double>(
          duration: 300.ms,
          tween: Tween(begin: 1.0, end: isWarping ? 0.0 : (isActive ? 1.1 : 1.0)),
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: isWarping ? 0.0 : 1.0,
              child: child,
            ),
          ),
          child: Container(
            width: 90.w, height: 70.h,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: isActive ? color : color.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: isActive ? 0.4 : 0.1), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Tech Pattern
                Opacity(
                  opacity: 0.1,
                  child: CustomPaint(
                    size: Size(90.w, 70.h),
                    painter: TechPatternPainter(color),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Text(
                    text.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.shareTechMono(
                      fontSize: 11.sp,
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: (2 + index % 3).seconds, curve: Curves.easeInOut);
  }
}

class TechPatternPainter extends CustomPainter {
  final Color color;
  TechPatternPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.2), Offset(size.width, size.height * 0.8), paint);
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.8, size.height), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

