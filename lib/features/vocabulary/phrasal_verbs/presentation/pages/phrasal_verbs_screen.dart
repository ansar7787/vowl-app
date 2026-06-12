import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_painters.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_lcd.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_vault_handle.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_option_key.dart';

class PhrasalVerbsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PhrasalVerbsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.phrasalVerbs,
  });

  @override
  State<PhrasalVerbsScreen> createState() => _PhrasalVerbsScreenState();
}

class _PhrasalVerbsScreenState extends State<PhrasalVerbsScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  String? _selectedOption;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  late AnimationController _vaultController;

  @override
  void initState() {
    super.initState();
    _vaultController = AnimationController(vsync: this, duration: 1.seconds);
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _vaultController.dispose();
    super.dispose();
  }

  void _submitChoice(String selected, String correct) async {
    if (_isAnswered) return;

    setState(() => _selectedOption = selected);
    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _vaultController.forward(from: 0);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;

          if (isNewQuestion || isRetry) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedOption = null;
              _vaultController.reset();
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'VAULT CRACKED!',
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
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

        if (state is VocabularyLoading ||
            (state is! VocabularyGameComplete &&
                state is! VocabularyLoaded &&
                state is! VocabularyError)) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;
        final isFinalFailure = (state is VocabularyLoaded)
            ? state.isFinalFailure
            : false;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () =>
              context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          useScrolling: false,
          disablePadding: true,
          child: quest == null
              ? const SizedBox()
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    // Edge-to-edge transparent grid background!
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GridPainter(
                          theme.primaryColor.withValues(
                            alpha: isDark ? 0.05 : 0.03,
                          ),
                        ),
                      ),
                    ),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final maxHeight = constraints.maxHeight;
                        final isCompact = maxHeight < 580;

                        final double estimatedContentHeight =
                            (isCompact ? 30.h : 40.h) +
                            (isCompact ? 70.h : 90.h) +
                            (isCompact ? 110.h : 160.h) +
                            (isCompact ? 90.h : 130.h) +
                            20.h;
                        final remainingHeight =
                            maxHeight - estimatedContentHeight;

                        final double gapUnit = remainingHeight > 0
                            ? remainingHeight / 6
                            : 0;
                        final double gapTop = remainingHeight > 0
                            ? (gapUnit * 1).clamp(6.0, 24.0)
                            : 6.0;
                        final double gapMiddle = remainingHeight > 0
                            ? (gapUnit * 1.5).clamp(10.0, 30.0)
                            : 10.0;
                        final double gapBottom = remainingHeight > 0
                            ? (gapUnit * 2).clamp(12.0, 40.0)
                            : 12.0;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: gapTop),
                                isCompact
                                    ? SizedBox(
                                        height: 30.h,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: _buildVaultStatus(
                                            theme.primaryColor,
                                            isDark,
                                          ),
                                        ),
                                      )
                                    : _buildVaultStatus(
                                        theme.primaryColor,
                                        isDark,
                                      ),
                                SizedBox(height: gapMiddle),

                                // LCD Display
                                isCompact
                                    ? SizedBox(
                                        height: 70.h,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: SizedBox(
                                            width: constraints.maxWidth - 40.w,
                                            child: PhrasalVerbsLcd(
                                              text:
                                                  quest.hint?.replaceFirst(
                                                    "DEFINITION: ",
                                                    "",
                                                  ) ??
                                                  "ANALYZING VAULT...",
                                              color: theme.primaryColor,
                                              isDark: isDark,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20.w,
                                        ),
                                        child: PhrasalVerbsLcd(
                                          text:
                                              quest.hint?.replaceFirst(
                                                "DEFINITION: ",
                                                "",
                                              ) ??
                                              "ANALYZING VAULT...",
                                          color: theme.primaryColor,
                                          isDark: isDark,
                                        ),
                                      ),
                              ],
                            ),

                            // The Central Vault Handle
                            isCompact
                                ? SizedBox(
                                    height: 110.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: PhrasalVerbsVaultHandle(
                                        verb: quest.word ?? "VERB",
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                        vaultController: _vaultController,
                                      ),
                                    ),
                                  )
                                : PhrasalVerbsVaultHandle(
                                    verb: quest.word ?? "VERB",
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                    vaultController: _vaultController,
                                  ),

                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: gapMiddle),
                                // Key Options (Particles)
                                isCompact
                                    ? SizedBox(
                                        height: 90.h,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: SizedBox(
                                            width: constraints.maxWidth,
                                            child: _buildOptionsWrap(
                                              quest,
                                              theme.primaryColor,
                                              isDark,
                                              isFinalFailure,
                                              isCompact,
                                            ),
                                          ),
                                        ),
                                      )
                                    : _buildOptionsWrap(
                                        quest,
                                        theme.primaryColor,
                                        isDark,
                                        isFinalFailure,
                                        isCompact,
                                      ),
                                SizedBox(height: gapBottom),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildVaultStatus(Color color, bool isDark) {
    return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.vpn_key_rounded, size: 16.r, color: color),
              SizedBox(width: 10.w),
              Text(
                "VAULT SECURITY: L-${widget.level}",
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 3.seconds);
  }

  Widget _buildOptionsWrap(
    VocabularyQuest quest,
    Color color,
    bool isDark,
    bool isFinalFailure,
    bool isCompact,
  ) {
    return Wrap(
      spacing: 15.w,
      runSpacing: isCompact ? 10.h : 15.h,
      alignment: WrapAlignment.center,
      children: (quest.options ?? []).asMap().entries.map((entry) {
        return PhrasalVerbsOptionKey(
          text: entry.value,
          correct: quest.correctAnswer ?? "",
          color: color,
          isDark: isDark,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          selectedOption: _selectedOption,
          isFinalFailure: isFinalFailure,
          index: entry.key,
          onTap: () => _submitChoice(entry.value, quest.correctAnswer ?? ""),
        );
      }).toList(),
    );
  }
}
