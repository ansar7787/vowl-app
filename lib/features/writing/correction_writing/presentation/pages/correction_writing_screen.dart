import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_instruction.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_sentence_card.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_vault.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_explanation_card.dart';

class CorrectionWritingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const CorrectionWritingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.correctionWriting,
  });

  @override
  State<CorrectionWritingScreen> createState() => _CorrectionWritingScreenState();
}

class _CorrectionWritingScreenState extends State<CorrectionWritingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  String? _selectedCorrection;
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

  void _onSelectCorrection(String choice) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _selectedCorrection = choice;
    });
  }

  void _submitAnswer() {
    final WritingQuest? quest = (context.read<WritingBloc>().state as WritingLoaded).currentQuest as WritingQuest?;
    if (quest == null || _isAnswered || _selectedCorrection == null) return;
    
    final bool correct = _selectedCorrection == quest.correctAnswer;

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = true; 
      });
      context.read<WritingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false; 
      });
      context.read<WritingBloc>().add(SubmitAnswer(false));
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isAnswered = false;
            _isCorrect = null;
            _selectedCorrection = null;
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
              _selectedCorrection = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'SYNTAX AUDITOR!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final WritingQuest? quest = (state is WritingLoaded) ? state.currentQuest as WritingQuest? : null;
        
        final options = quest?.options ?? [];

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
                  CorrectionWritingInstruction(primaryColor: theme.primaryColor),
                  SizedBox(height: 24.h),
                  
                  CorrectionWritingSentenceCard(
                    passage: quest.passage ?? "",
                    selectedCorrection: _selectedCorrection,
                    color: theme.primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: 32.h),
                  
                  CorrectionWritingVault(
                    options: options,
                    selectedCorrection: _selectedCorrection,
                    color: theme.primaryColor,
                    isDark: isDark,
                    onSelectCorrection: _onSelectCorrection,
                  ),
                  SizedBox(height: 36.h),
                  
                  if (!_isAnswered)
                    ScaleButton(
                      onTap: _selectedCorrection != null ? _submitAnswer : null,
                      child: Container(
                        width: double.infinity, height: 60.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r), 
                          color: _selectedCorrection != null ? theme.primaryColor : Colors.grey, 
                          boxShadow: [
                            if (_selectedCorrection != null) 
                              BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 15)
                          ]
                        ),
                        child: Center(
                          child: Text(
                            "AUDIT SYNTAX", 
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp, 
                              fontWeight: FontWeight.w900, 
                              color: Colors.white, 
                              letterSpacing: 2
                            )
                          )
                        ),
                      ),
                    ),
                  
                  if (_isAnswered) ...[
                    SizedBox(height: 30.h),
                    CorrectionWritingExplanationCard(
                      quest: quest,
                      isCorrect: _isCorrect == true,
                      primaryColor: theme.primaryColor,
                      isDark: isDark,
                    ),
                  ],
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
