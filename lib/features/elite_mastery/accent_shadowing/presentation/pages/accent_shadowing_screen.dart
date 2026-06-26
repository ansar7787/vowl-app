import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/text_similarity_helper.dart';
import '../../../presentation/bloc/elite_mastery_bloc.dart';
import '../../../presentation/layout/elite_base_layout.dart';
import '../../../presentation/widgets/elite_hint_card.dart';
import '../widgets/accent_shadowing_target_panel.dart';
import '../widgets/accent_shadowing_mic_trigger.dart';
import 'package:vowl/core/utils/locale_service.dart';

class AccentShadowingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AccentShadowingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.accentShadowing,
  });

  @override
  State<AccentShadowingScreen> createState() => _AccentShadowingScreenState();
}

class _AccentShadowingScreenState extends State<AccentShadowingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _speechService = di.sl<SpeechService>();
  bool _showConfetti = false;
  bool _isListening = false;
  String _lastWords = "";
  bool _isAnswered = false;
  bool? _isCorrect;
  int _attempts = 0;
  bool _isProcessing = false;
  Set<int> _matchedIndices = {};
  String? _lastQuestId;

  @override
  void initState() {
    super.initState();
    context.read<EliteMasteryBloc>().add(
      FetchEliteMasteryQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    // FIX: if the player navigates away mid-recording, the speech engine
    // previously kept listening with no owner — leaking an active
    // microphone session (battery drain, a lingering OS mic indicator) and
    // risking `setState()` being invoked after this State is disposed once
    // a result/done callback eventually fired.
    if (_isListening) {
      _speechService.stop();
    }
    super.dispose();
  }

  Future<void> _toggleListening(String targetText) async {
    if (_isAnswered) return;
    if (_isListening) {
      setState(() {
        _isListening = false;
        _isProcessing = true;
      });
      await _speechService.stop();
      _checkResult(_lastWords, targetText);
    } else {
      final available = await _speechService.initializeStt();
      if (available) {
        setState(() {
          _isListening = true;
          _isProcessing = false;
          _lastWords = "";
        });
        _speechService.listen(
          onResult: (text) {
            if (mounted) {
              setState(() {
                _lastWords = text;
                _matchedIndices = TextSimilarityHelper.getMatchedIndices(
                  text,
                  targetText,
                );
              });

              // Auto-Catch: Wait 1 second before finishing to feel more natural
              final targetWords = targetText
                  .split(RegExp(r'\s+'))
                  .where((w) => w.isNotEmpty)
                  .toList();
              if (_matchedIndices.length >= targetWords.length &&
                  targetWords.isNotEmpty) {
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted && _isListening) {
                    _toggleListening(targetText);
                  }
                });
              }
            }
          },
          onDone: () {
            if (mounted && _isListening && !_isProcessing) {
              setState(() {
                _isListening = false;
                _isProcessing = true;
              });
              _checkResult(_lastWords, targetText);
            }
          },
        );
        _hapticService.selection();
      } else {
        // FIX: previously, if the microphone permission was denied or
        // speech recognition was unavailable on the device, tapping the mic
        // button silently did nothing — a dead-end button with zero
        // affordance for what went wrong. Surface it explicitly instead.
        if (!mounted) return;
        _hapticService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('games.mic_unavailable')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _checkResult(String spoken, String target) {
    if (_isAnswered) return;

    // Ultra-lenient threshold for difficult accent games (tongue twisters)
    // Lenient threshold for difficult accent games, balanced with length safety
    bool isCorrect = TextSimilarityHelper.isMatch(
      spoken,
      target,
      threshold: 0.70,
    );

    _attempts++;

    if (isCorrect) {
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(true));
    } else {
      setState(() {
        _isCorrect = false;
        _isAnswered = true;
      });
      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(false));
    }

    // Reset processing lock after check
    setState(() => _isProcessing = false);
  }

  void _tutorPass() {
    GameDialogHelper.showHonestyNudge(context);
    setState(() {
      _isAnswered = true;
      _isCorrect = true;
      _matchedIndices = Set.from(Iterable.generate(100)); // Highlight all
    });
    context.read<EliteMasteryBloc>().add(EliteTutorPass());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
    final theme = LevelThemeHelper.getTheme(
      widget.gameType.name,
      level: widget.level,
      isDark: isDark,
      isMidnight: isMidnight,
    );

    return BlocConsumer<EliteMasteryBloc, EliteMasteryState>(
      listener: (context, state) {
        if (state is EliteMasteryGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            this.context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr('games.accent_legend_title'),
            enableDoubleUp: true,
          );
        } else if (state is EliteMasteryLoaded) {
          final quest = state.currentQuest;
          if (_lastQuestId != quest.id) {
            setState(() {
              _lastQuestId = quest.id;
              _isAnswered = false;
              _isCorrect = null;
              _attempts = 0;
              _lastWords = "";
              _matchedIndices = {};
            });
          } else if (state.lastAnswerCorrect == null) {
            setState(() {
              _isAnswered = false;
              _isCorrect = null;
              _lastWords = "";
              _matchedIndices = {};
            });
          } else if (state.lastAnswerCorrect == false) {
            setState(() {
              _isCorrect = false;
              // If it's a final failure (either 2 strikes or out of lives), lock screen
              if (state.isFinalFailure || state.livesRemaining <= 0) {
                _isAnswered = true;
              }
            });
          }
          // FIX: `lastAnswerCorrect == true` intentionally needs no handling
          // here. Both a genuine correct answer (`_checkResult`) and a Tutor
          // Pass override (`_tutorPass`) already set `_isAnswered`/`_isCorrect`
          // locally *before* dispatching their event. The previous version
          // additionally reset those flags whenever `livesRemaining` ticked
          // up versus the last-seen value — which is exactly what both
          // `EliteTutorPass` and the ad-funded `AddLifeFromAd` do as a
          // deliberate side effect. That meant using "I spoke correctly!"
          // (mid-quest, or from the Game Over dialog) silently wiped the
          // feedback card back to the mic-trigger UI a moment after it
          // appeared, while the BLoC's `lastAnswerCorrect` stayed locked at
          // `true` — so re-recording produced no further effect and there
          // was no way to reach the Continue button. Deriving the reset
          // purely from `lastAnswerCorrect == null` (covers `RetryEliteQuestion`,
          // `RestoreEliteLife`, and `AddLifeFromAd` from Game Over, all of
          // which already emit with `lastAnswerCorrect` unset) avoids that
          // false trigger entirely.
        } else if (state is EliteMasteryGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () =>
                context.read<EliteMasteryBloc>().add(RestoreEliteLife()),
            onTutorPass: _tutorPass,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is EliteMasteryLoaded) ? state.currentQuest : null;

        return EliteBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          state: state,
          isCorrect: _isCorrect,
          isFinalFailure: (state is EliteMasteryLoaded)
              ? (state.isFinalFailure || state.livesRemaining <= 0)
              : false,
          showConfetti: _showConfetti,
          title: context.tr('games.accent_shadowing_title'),
          subtitle:
              quest?.instruction ??
              context.tr('games.accent_shadowing_subtitle'),
          onContinue: () {
            setState(() {
              _isAnswered = false;
              _isCorrect = null;
              _lastWords = "";
            });
            context.read<EliteMasteryBloc>().add(NextEliteQuestion());
          },
          onHint: () {
            final bloc = context.read<EliteMasteryBloc>();
            final s = bloc.state;
            if (s is EliteMasteryLoaded) {
              if (s.currentQuest.hint != null &&
                  s.currentQuest.hint!.isNotEmpty) {
                if (!s.isHintUsed) bloc.add(MarkEliteHintUsed());
                bloc.add(ShowEliteHint());
              } else {
                GameDialogHelper.showHintAdDialog(
                  context,
                  onHintEarned: () {
                    bloc.add(ShowEliteHint());
                  },
                );
              }
            }
          },
          child: _buildBody(context, state, isDark, theme),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    EliteMasteryState state,
    bool isDark,
    ThemeResult theme,
  ) {
    // `EliteMasteryLoading` and `EliteMasteryError` are both handled
    // centrally by `EliteBaseLayout`: it renders its own shimmer/error UI
    // directly inside its Stack and never includes this `child` slot for
    // either state, so no local UI is built (or ever shown) for them here.
    if (state is EliteMasteryLoaded) {
      return _buildGameUI(context, state, isDark, theme);
    }
    if (state is EliteMasteryGameOver) {
      // Keep UI visible behind the dialog but dim it
      return Opacity(
        opacity: 0.5,
        child: AbsorbPointer(
          child: _buildGameUI(
            context,
            EliteMasteryLoaded(
              quests: state.quests,
              currentIndex: state.currentIndex,
              livesRemaining: 0,
            ),
            isDark,
            theme,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildGameUI(
    BuildContext context,
    EliteMasteryLoaded state,
    bool isDark,
    ThemeResult theme,
  ) {
    final quest = state.currentQuest;
    final targetText = quest.text ?? quest.textToSpeak;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 580;

        return Column(
          children: [
            AccentShadowingTargetPanel(
              text: targetText ?? context.tr('games.target_text_fallback'),
              matchedIndices: _matchedIndices,
              isDark: isDark,
              primaryColor: theme.primaryColor,
              isAnswered: _isAnswered,
              isCorrect: _isCorrect,
              attempts: _attempts,
              onListenTap: () => _speechService.speak(targetText ?? ""),
            ),
            if (state.isHintVisible) ...[
              SizedBox(height: isCompact ? 12.h : 20.h),
              EliteHintCard(
                hintText: quest.hint,
                isVisible: true,
                onShowHint: () {},
                primaryColor: theme.primaryColor,
              ),
            ],
            SizedBox(height: isCompact ? 16.h : 30.h),
            if (_lastWords.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: isCompact ? 8.h : 12.h,
                ),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Text(
                  _lastWords,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: isCompact ? 14.sp : 16.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(),
            SizedBox(height: isCompact ? 20.h : 40.h),
            AccentShadowingMicTrigger(
              isListening: _isListening,
              onTap: () => _toggleListening(targetText ?? ""),
              onTutorPass: _tutorPass,
              primaryColor: theme.primaryColor,
              attempts: _attempts,
              isAnswered: _isAnswered,
            ),
          ],
        );
      },
    );
  }
}
