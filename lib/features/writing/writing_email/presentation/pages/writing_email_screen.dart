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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';

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
  final _soundService = di.sl<SoundService>();
  
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
      // If the data was already placed in a different slot, clear that slot
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
    final WritingQuest? quest = (context.read<WritingBloc>().state as WritingLoaded).currentQuest as WritingQuest?;
    if (quest == null || _isAnswered) return;
    
    final options = quest.options ?? [];
    final correctOrderIndices = quest.correctOrder ?? [0, 1, 2, 3];
    
    // Validate slots contain the correct index value matching the keys
    bool isSubjectCorrect = _slots['SUBJECT'] == options[correctOrderIndices[0]];
    bool isSalutationCorrect = _slots['SALUTATION'] == options[correctOrderIndices[1]];
    bool isBodyCorrect = _slots['BODY'] == options[correctOrderIndices[2]];
    bool isSignOffCorrect = _slots['SIGN-OFF'] == options[correctOrderIndices[3]];

    if (isSubjectCorrect && isSalutationCorrect && isBodyCorrect && isSignOffCorrect) {
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
      
      Future.delayed(1.5.seconds, () {
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
                  _buildInstruction(theme.primaryColor),
                  SizedBox(height: 24.h),
                  
                  _buildPromptCard(quest.prompt ?? "", theme.primaryColor, isDark),
                  SizedBox(height: 24.h),
                  
                  ..._slots.keys.map((k) => _buildHexSlot(k, theme.primaryColor, isDark)),
                  SizedBox(height: 24.h),
                  
                  _buildDataStream(options, theme.primaryColor, isDark),
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
                            style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)
                          )
                        ),
                      ),
                    ),
                  
                  if (_isAnswered) ...[
                    SizedBox(height: 30.h),
                    _buildCorrectResult(quest, theme.primaryColor, isDark),
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

  Widget _buildInstruction(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: primaryColor.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.terminal_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("SEQUENCE THE DATA PACKETS INTO THE NEURAL SLOTS", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPromptCard(String text, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Stack(
        children: [
          const TechPatternOverlay(opacity: 0.05),
          Text(
            text, 
            textAlign: TextAlign.center, 
            style: GoogleFonts.outfit(
              fontSize: 15.sp, 
              fontWeight: FontWeight.w800, 
              color: isDark ? Colors.white : Colors.black87,
              height: 1.4
            )
          ),
        ],
      ),
    );
  }

  Widget _buildHexSlot(String key, Color color, bool isDark) {
    bool hasData = _slots[key] != null;

    return DragTarget<String>(
      onAcceptWithDetails: (details) => _onSlot(key, details.data),
      builder: (context, candidateData, rejectedData) {
        final highlight = candidateData.isNotEmpty;
        
        return GestureDetector(
          onTap: () => _clearSlot(key),
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.black45 : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: highlight ? Colors.greenAccent : (hasData ? color : color.withValues(alpha: 0.2)), 
                width: 2
              ),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: isDark ? 0.25 : 0.08), blurRadius: 8)
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r)
                  ),
                  child: Text(
                    key, 
                    style: GoogleFonts.shareTechMono(
                      color: color, 
                      fontSize: 9.sp, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    _slots[key] ?? "--- PULL NEURAL SEGMENT HERE ---", 
                    style: GoogleFonts.shareTechMono(
                      color: hasData 
                        ? (isDark ? Colors.white70 : Colors.black87) 
                        : (isDark ? Colors.white24 : Colors.black26),
                      fontSize: 11.sp,
                      fontWeight: hasData ? FontWeight.bold : FontWeight.normal
                    )
                  )
                ),
                if (hasData)
                  Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18.r)
                    .animate().scale().fadeIn(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataStream(List<String> items, Color color, bool isDark) {
    // Hide items that are already slotted in any of the slots
    final placed = _slots.values.toSet();
    final availableItems = items.where((i) => !placed.contains(i)).toList();

    return Container(
      constraints: BoxConstraints(minHeight: 80.h),
      child: Wrap(
        spacing: 12.w, runSpacing: 12.h,
        alignment: WrapAlignment.center,
        children: availableItems.map((i) => Draggable<String>(
          data: i,
          feedback: Material(
            color: Colors.transparent, 
            child: Container(
              width: 260.w,
              padding: EdgeInsets.all(12.r), 
              decoration: BoxDecoration(
                color: color, 
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20)
                ]
              ), 
              child: Text(
                i, 
                style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold)
              )
            )
          ),
          child: Container(
            width: 140.w,
            padding: EdgeInsets.all(12.r), 
            decoration: BoxDecoration(
              color: isDark ? Colors.black87 : Colors.white, 
              borderRadius: BorderRadius.circular(16.r), 
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: isDark ? 0.35 : 0.15), blurRadius: 6)
              ],
            ), 
            child: Text(
              i, 
              textAlign: TextAlign.center,
              style: GoogleFonts.shareTechMono(
                color: isDark ? Colors.white70 : Colors.black87, 
                fontSize: 9.sp, 
                fontWeight: FontWeight.bold
              )
            )
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCorrectResult(dynamic quest, Color primaryColor, bool isDark) {
    final bool correct = _isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: displayColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: displayColor, size: 36.r),
          SizedBox(height: 10.h),
          Text(
            correct ? "CORRECT!" : "INCORRECT",
            style: GoogleFonts.outfit(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: displayColor,
              letterSpacing: 2,
            ),
          ),
          if (quest.explanation != null) ...[
            SizedBox(height: 10.h),
            Text(
              quest.explanation!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
