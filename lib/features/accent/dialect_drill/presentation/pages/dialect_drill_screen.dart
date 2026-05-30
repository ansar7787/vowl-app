import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/widgets/dialect_feedback_panel.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/widgets/dialect_drill_instruction.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/widgets/dialect_drill_hologram_console.dart';
import 'package:vowl/features/accent/dialect_drill/presentation/widgets/dialect_drill_status_telemetry.dart';

class DialectDrillScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DialectDrillScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.dialectDrill,
  });

  @override
  State<DialectDrillScreen> createState() => _DialectDrillScreenState();
}

class _DialectDrillScreenState extends State<DialectDrillScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _triggerAutoPlay(AccentQuest quest) {
    final instruction = quest.instruction;
    final String targetLocale = instruction.contains("British") ? "en-GB" : "en-US";
    _soundService.playTts(quest.word ?? "", locale: targetLocale);
  }

  void _submitAnswer(int index, int correct, double maxWidth) {
    if (_isAnswered) return;
    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
            });
            Future.delayed(const Duration(milliseconds: 350), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'DIALECT EXPERT!',
            enableDoubleUp: true,
          );
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<AccentBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is AccentLoaded) ? state.currentQuest as AccentQuest? : null;

        String brPr = "";
        String amPr = "";
        if (quest != null && quest.options != null) {
          for (var opt in quest.options!) {
            if (opt.contains('(British)')) {
              brPr = opt.replaceAll(' (British)', '');
            } else if (opt.contains('(American)')) {
              amPr = opt.replaceAll(' (American)', '');
            }
          }
        }

        return AccentBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
          onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
          child: quest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Column(
                    children: [
                      DialectDrillInstruction(
                        instruction: quest.instruction,
                        accentColor: theme.primaryColor,
                      ),
                      SizedBox(height: 16.h),
                      DialectDrillHologramConsole(
                        quest: quest,
                        color: theme.primaryColor,
                        isDark: isDark,
                        isAnswered: _isAnswered,
                        isCorrect: _isCorrect,
                        onPlayTargetAudio: () => _triggerAutoPlay(quest),
                        onSubmitAnswer: _submitAnswer,
                      ),
                      SizedBox(height: 20.h),
                      
                      AnimatedCrossFade(
                        firstChild: DialectDrillStatusTelemetry(
                          color: theme.primaryColor,
                          isDark: isDark,
                        ),
                        secondChild: DialectFeedbackPanel(
                          isCorrect: _isCorrect ?? false,
                          word: quest.word ?? "",
                          britishPronunciation: brPr.isEmpty ? (quest.word ?? "") : brPr,
                          americanPronunciation: amPr.isEmpty ? (quest.word ?? "") : amPr,
                          hint: quest.hint ?? "Dialect variants represent rich cultural history.",
                          isDark: isDark,
                          isMidnight: false,
                          onPlayAudio: (text, locale) {
                            _soundService.playTts(text, locale: locale);
                          },
                        ),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 80.h),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
