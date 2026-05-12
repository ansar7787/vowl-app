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

class CollocationsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const CollocationsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.collocations,
  });

  @override
  State<CollocationsScreen> createState() => _CollocationsScreenState();
}

class _CollocationsScreenState extends State<CollocationsScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  // Pair Pop State
  int? _selectedLeftIndex;
  int? _selectedRightIndex;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onLeftTap(int index) {
    if (_isAnswered || _isProcessing) return;
    _hapticService.light();
    setState(() {
      _selectedLeftIndex = index;
    });
  }

  void _onRightTap(int index, String selected, String correct) async {
    if (_isAnswered || _isProcessing || _selectedLeftIndex == null) return;
    
    setState(() {
      _selectedRightIndex = index;
      _isProcessing = true;
    });

    bool isMatch = selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isMatch) {
      _hapticService.success();
      _soundService.playCorrect();
      await Future.delayed(500.ms);
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
        _isProcessing = false;
      });
      if (!mounted) return;
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      await Future.delayed(500.ms);
      setState(() {
        _selectedLeftIndex = null;
        _selectedRightIndex = null;
        _isProcessing = false;
      });
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
              _selectedLeftIndex = null;
              _selectedRightIndex = null;
              _isProcessing = false;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'PAIR MASTER!',
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
              // Chamber Background
              Positioned.fill(child: CustomPaint(painter: EnergyChamberPainter(theme.primaryColor.withValues(alpha: 0.1)))),

              Column(
                children: [
                  SizedBox(height: 30.h),
                  _buildInstruction(theme.primaryColor),
                  const Spacer(),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left Column (Anchor Word)
                        Column(
                          children: [
                            _buildEnergyBubble(
                              0, 
                              quest.word ?? "", 
                              true, 
                              theme.primaryColor, 
                              isDark,
                              () => _onLeftTap(0)
                            ),
                          ],
                        ),

                        // Right Column (Options)
                        Column(
                          children: List.generate(quest.options?.length ?? 0, (i) {
                            return _buildEnergyBubble(
                              i, 
                              quest.options![i], 
                              false, 
                              theme.primaryColor, 
                              isDark,
                              () => _onRightTap(i, quest.options![i], quest.correctAnswer ?? "")
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  _buildStatusText(theme.primaryColor),
                  SizedBox(height: 40.h),
                ],
              ),
            ],
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
        "FUSE THE COLLOCATION PAIR",
        style: GoogleFonts.shareTechMono(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds);
  }

  Widget _buildStatusText(Color color) {
    if (_selectedLeftIndex != null && _selectedRightIndex == null) {
      return Text(
        "AWAITING PARTNER...",
        style: GoogleFonts.shareTechMono(fontSize: 14.sp, color: color, fontWeight: FontWeight.bold, letterSpacing: 3),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn();
    }
    return const SizedBox();
  }

  Widget _buildEnergyBubble(int index, String text, bool isLeft, Color color, bool isDark, VoidCallback onTap) {
    bool isSelected = isLeft ? (_selectedLeftIndex == index) : (_selectedRightIndex == index);
    bool isPopped = _isAnswered && _isCorrect == true && (isLeft || (index == _selectedRightIndex));
    
    Color bubbleColor = isLeft ? const Color(0xFF00D2FF) : const Color(0xFFAD00FF);
    if (isSelected) bubbleColor = Colors.white;

    return Opacity(
      opacity: isPopped ? 0 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 140.w,
          height: 140.w,
          margin: EdgeInsets.symmetric(vertical: 15.h),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                bubbleColor.withValues(alpha: 0.4),
                bubbleColor.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(color: bubbleColor.withValues(alpha: isSelected ? 1 : 0.4), width: isSelected ? 4 : 2),
            boxShadow: [
              BoxShadow(color: bubbleColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(10.r),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.shareTechMono(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? bubbleColor : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -10, end: 10, duration: (2 + index).seconds)
     .scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: (3 + index).seconds);
  }
}

class EnergyChamberPainter extends CustomPainter {
  final Color color;
  EnergyChamberPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.0..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 100.r + (i * 50), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
