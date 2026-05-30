import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_instruction.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_workbench.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_piece_pool.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_explanation_card.dart';

class SentenceBuilderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SentenceBuilderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.sentenceBuilder,
  });

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final List<String> _assembledPieces = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onSnap(String piece) {
    if (_isAnswered) return;
    _hapticService.success();
    setState(() => _assembledPieces.add(piece));
  }

  void _onRemovePiece(int index) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() => _assembledPieces.removeAt(index));
  }

  void _submitAnswer(String correct) {
    if (_isAnswered || _assembledPieces.isEmpty) return;
    
    String built = _assembledPieces.join(' ').trim().toLowerCase();
    String normalizedCorrect = correct.trim().toLowerCase();
    
    bool isCorrect = built == normalizedCorrect;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<WritingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<WritingBloc>().add(SubmitAnswer(false));
      Future.delayed(1.seconds, () {
        if (mounted) {
          setState(() {
            _assembledPieces.clear();
            _isAnswered = false;
            _isCorrect = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listener: (context, state) {
        if (state is WritingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _assembledPieces.clear();
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SYNTAX ARCHITECT!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is WritingLoaded) ? state.currentQuest : null;
        final pool = quest?.shuffledWords ?? [];
        
        return WritingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: quest == null ? const SizedBox() : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  SentenceBuilderInstruction(primaryColor: theme.primaryColor),
                  SizedBox(height: 32.h),
                  
                  SentenceBuilderWorkbench(
                    assembledPieces: _assembledPieces,
                    color: theme.primaryColor,
                    isDark: isDark,
                    onSnap: _onSnap,
                    onRemovePiece: _onRemovePiece,
                  ),
                  SizedBox(height: 32.h),
                  
                  SentenceBuilderPiecePool(
                    pool: pool,
                    assembledPieces: _assembledPieces,
                    color: theme.primaryColor,
                    isDark: isDark,
                  ),
                  
                  if (_isAnswered) ...[
                    SizedBox(height: 30.h),
                    SentenceBuilderExplanationCard(
                      quest: quest,
                      isCorrect: _isCorrect == true,
                      primaryColor: theme.primaryColor,
                      isDark: isDark,
                    ),
                  ],
                  
                  SizedBox(height: 40.h),
                  if (!_isAnswered)
                    ScaleButton(
                      onTap: () => _submitAnswer(quest.correctAnswer ?? ""),
                      child: Container(
                        width: double.infinity, height: 56.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r), 
                          color: theme.primaryColor, 
                          boxShadow: [
                            BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 15)
                          ]
                        ),
                        child: Center(
                          child: Text(
                            "POLISH SENTENCE", 
                            style: GoogleFonts.outfit(
                              fontSize: 14.sp, 
                              fontWeight: FontWeight.w900, 
                              color: Colors.white, 
                              letterSpacing: 2
                            )
                          )
                        ),
                      ),
                    ),
                  SizedBox(height: 60.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
