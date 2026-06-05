import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_instruction.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_prompt_card.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_hex_slot.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_data_stream.dart';
import 'package:vowl/features/writing/writing_email/presentation/widgets/writing_email_explanation_card.dart';

class WritingEmailScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const WritingEmailScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.writingEmail,
  });

  @override
  State<WritingEmailScreen> createState() => _WritingEmailScreenState();
}

class _WritingEmailScreenState extends State<WritingEmailScreen> {
  final _hapticService = di.sl<HapticService>();
  
  final Map<String, String?> _slots = {
    'SUBJECT': null,
    'SALUTATION': null,
    'BODY': null,
    'SIGN-OFF': null,
  };
  
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

  void _onSlot(String slotKey, String data) {
    if (_isAnswered) return;
    
    _hapticService.success();
    setState(() {
      _slots.forEach((key, val) {
        if (val == data) {
          _slots[key] = null;
        }
      });
      _slots[slotKey] = data;
    });
  }

  void _clearSlot(String slotKey) {
    if (_isAnswered || _slots[slotKey] == null) return;
    _hapticService.selection();
    setState(() {
      _slots[slotKey] = null;
    });
  }

  void _submitAnswer() {
    final state = context.read<WritingBloc>().state;
    if (state is! WritingLoaded || _isAnswered) return;
    
    final WritingQuest? quest = state.currentQuest as WritingQuest?;
    if (quest == null) return;
    
    final options = quest.options ?? [];
    final correctOrderIndices = quest.correctOrder ?? [0, 1, 2, 3];
    
    bool isSubjectCorrect = _slots['SUBJECT'] == options[correctOrderIndices[0]];
    bool isSalutationCorrect = _slots['SALUTATION'] == options[correctOrderIndices[1]];
    bool isBodyCorrect = _slots['BODY'] == options[correctOrderIndices[2]];
    bool isSignOffCorrect = _slots['SIGN-OFF'] == options[correctOrderIndices[3]];

    if (isSubjectCorrect && isSalutationCorrect && isBodyCorrect && isSignOffCorrect) {
      setState(() { 
        _isAnswered = true; 
        _isCorrect = true; 
      });
      context.read<WritingBloc>().add(SubmitAnswer(true));
    } else {
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
            _slots.updateAll((k, v) => null);
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
              _slots.updateAll((k, v) => null);
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'CORRESPONDENCE ACE!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final WritingQuest? quest = (state is WritingLoaded) ? state.currentQuest as WritingQuest? : null;
        
        final options = quest?.options ?? [];
        final slotsFilled = _slots.values.every((v) => v != null);

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
                  WritingEmailInstruction(primaryColor: theme.primaryColor),
                  SizedBox(height: 24.h),
                  
                  WritingEmailPromptCard(
                    text: quest.prompt ?? "",
                    color: theme.primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: 24.h),
                  
                  ..._slots.keys.map((k) => WritingEmailHexSlot(
                    slotKey: k,
                    slotValue: _slots[k],
                    color: theme.primaryColor,
                    isDark: isDark,
                    onSlot: _onSlot,
                    onClearSlot: _clearSlot,
                  )),
                  SizedBox(height: 24.h),
                  
                  WritingEmailDataStream(
                    items: options,
                    slots: _slots,
                    color: theme.primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: 32.h),
                  
                  if (!_isAnswered)
                    ScaleButton(
                      onTap: slotsFilled ? _submitAnswer : null,
                      child: Container(
                        width: double.infinity, height: 60.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r), 
                          color: slotsFilled ? theme.primaryColor : Colors.grey, 
                          boxShadow: [
                            if (slotsFilled) 
                              BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 15)
                          ]
                        ),
                        child: Center(
                          child: Text(
                            "TRANSMIT DISPATCH", 
                            style: TextStyle(fontFamily: 'Outfit', 
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
                    WritingEmailExplanationCard(
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
