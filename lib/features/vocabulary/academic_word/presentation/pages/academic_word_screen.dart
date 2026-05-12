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

class AcademicWordScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AcademicWordScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.academicWord,
  });

  @override
  State<AcademicWordScreen> createState() => _AcademicWordScreenState();
}

class _AcademicWordScreenState extends State<AcademicWordScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  // Thesis Thrust State
  Offset _dragOffset = Offset.zero;
  int? _activeShardIndex;
  final GlobalKey _slotKey = GlobalKey();
  BoxConstraints? _lastConstraints;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onShardDragStart(int index) {
    if (_isAnswered) return;
    setState(() => _activeShardIndex = index);
    _hapticService.light();
  }

  void _onShardDragUpdate(int index, DragUpdateDetails details) {
    if (_isAnswered || _activeShardIndex != index) return;
    setState(() => _dragOffset += details.delta);
    
    // Proximity haptics to the central slot
    if (_isNearSlot()) {
      _hapticService.selection();
    }
  }

  bool _isNearSlot() {
    if (_activeShardIndex == null || _lastConstraints == null) return false;
    final currentPos = _getShardCurrentPosition(_activeShardIndex!);
    return currentPos.distance < 100.r; // Proximity to center
  }

  void _onShardDragEnd(int index, VocabularyQuest quest) {
    if (_isAnswered || _activeShardIndex != index) return;

    if (_isNearSlot()) {
      _attemptThrust(index, quest);
    } else {
      setState(() {
        _dragOffset = Offset.zero;
        _activeShardIndex = null;
      });
      _hapticService.light();
    }
  }

  void _attemptThrust(int index, VocabularyQuest quest) {
    final selected = quest.options![index].trim().toLowerCase();
    final correct = quest.correctAnswer?.trim().toLowerCase() ?? "";

    if (selected == correct) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
        _activeShardIndex = null;
      });
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _activeShardIndex = null;
        _dragOffset = Offset.zero;
      });
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  Offset _getShardCurrentPosition(int index) {
    final initial = _getShardInitialPosition(index, (_lastQuest?.options?.length ?? 4));
    return initial + _dragOffset;
  }

  Offset _getShardInitialPosition(int index, int total) {
    final vStep = 80.h;
    final startY = 200.h; // Bottom tray start
    final isLeft = index % 2 == 0;
    return Offset(isLeft ? -100.w : 100.w, startY + (index ~/ 2) * vStep);
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
              _dragOffset = Offset.zero;
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
            title: 'THESIS COMPLETE!',
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
          child: quest == null ? const SizedBox() : LayoutBuilder(
            builder: (context, constraints) {
              _lastConstraints = constraints;
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Reactor Grid
                  Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: ReactorGridPainter(theme.primaryColor.withValues(alpha: 0.1))))),
                  
                  // Thesis Passage
                  _buildThesisPaper(quest.passage ?? "", theme.primaryColor, isDark),

                  // Floating Shards
                  ...List.generate(quest.options?.length ?? 0, (i) {
                    return _buildAcademicShard(i, quest.options![i], theme.primaryColor, isDark);
                  }),

                  // Thrust Instruction
                  Positioned(top: 20.h, child: _buildInstruction(theme.primaryColor)),
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
        "THRUST WORD INTO THE THESIS",
        style: GoogleFonts.shareTechMono(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds);
  }

  Widget _buildThesisPaper(String passage, Color color, bool isDark) {
    final parts = passage.split('[TARGET]');
    
    return Container(
      width: 320.w,
      padding: EdgeInsets.all(25.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(2.r), // Sharp scholarly edges
        boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 20, offset: const Offset(5, 5)),
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 40),
        ],
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.crimsonPro(
            fontSize: 20.sp,
            height: 1.6,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          children: [
            TextSpan(text: parts[0]),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                key: _slotKey,
                width: 140.w,
                height: 35.h,
                margin: EdgeInsets.symmetric(horizontal: 8.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  border: Border(bottom: BorderSide(color: color, width: 2)),
                ),
                child: Center(
                  child: _isAnswered && _isCorrect == true
                    ? Text(
                        _lastQuest?.correctAnswer?.toUpperCase() ?? "",
                        style: GoogleFonts.shareTechMono(color: color, fontWeight: FontWeight.bold, fontSize: 16.sp),
                      ).animate().fadeIn().scale()
                    : Text(
                        "RUNES_PENDING",
                        style: GoogleFonts.shareTechMono(color: color.withValues(alpha: 0.3), fontSize: 10.sp),
                      ).animate(onPlay: (c) => c.repeat()).shimmer(),
                ),
              ),
            ),
            if (parts.length > 1) TextSpan(text: parts[1]),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 1.seconds).slideY(begin: -0.1, end: 0);
  }

  Widget _buildAcademicShard(int index, String text, Color color, bool isDark) {
    final initial = _getShardInitialPosition(index, (_lastQuest?.options?.length ?? 4));
    final isDragging = _activeShardIndex == index;
    final offset = isDragging ? _dragOffset : Offset.zero;
    
    return Positioned(
      left: (_lastConstraints!.maxWidth / 2) + initial.dx + offset.dx - 60.w,
      top: (_lastConstraints!.maxHeight / 2) + initial.dy + offset.dy - 30.h,
      child: GestureDetector(
        onPanStart: (_) => _onShardDragStart(index),
        onPanUpdate: (d) => _onShardDragUpdate(index, d),
        onPanEnd: (_) => _onShardDragEnd(index, _lastQuest!),
        child: Container(
          width: 120.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : Colors.white,
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: isDragging ? color : color.withValues(alpha: 0.4), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
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
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: (2 + index).seconds);
  }
}

class ReactorGridPainter extends CustomPainter {
  final Color color;
  ReactorGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 0.5;
    const step = 40.0;
    
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
