import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/text_similarity_helper.dart';
import '../../../presentation/bloc/elite_mastery_bloc.dart';
import '../../../presentation/widgets/elite_base_layout.dart';
import '../../../presentation/widgets/elite_hint_card.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

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
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<EliteMasteryBloc>().add(
          FetchEliteMasteryQuests(
            gameType: widget.gameType,
            level: widget.level,
          ),
    );
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
                _matchedIndices = TextSimilarityHelper.getMatchedIndices(text, targetText);
              });
              
              // Auto-Catch: Wait 1 second before finishing to feel more natural
              final targetWords = targetText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
              if (_matchedIndices.length >= targetWords.length && targetWords.isNotEmpty) {
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
      }
    }
  }

  void _checkResult(String spoken, String target) {
    if (_isAnswered) return;
    
    // Ultra-lenient threshold for difficult accent games (tongue twisters)
    // Lenient threshold for difficult accent games, balanced with length safety
    bool isCorrect = TextSimilarityHelper.isMatch(spoken, target, threshold: 0.70);

    _attempts++;
    
    if (isCorrect) {
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<EliteMasteryBloc>().add(SubmitEliteAnswer(true));
    } else {
      final isFinalFailure = _attempts >= 2;
      setState(() {
        _isCorrect = false;
        if (isFinalFailure) {
          _isAnswered = true;
        } else {
          // Strike 1: Allow retry without feedback card
          _isAnswered = false;
          _lastWords = "";
        }
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
    final theme = LevelThemeHelper.getTheme(widget.gameType.name, level: widget.level, isDark: isDark, isMidnight: isMidnight);

    return BlocConsumer<EliteMasteryBloc, EliteMasteryState>(
      listener: (context, state) {
        if (state is EliteMasteryGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            this.context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'ACCENT LEGEND!',
            enableDoubleUp: true,
          );
        } else if (state is EliteMasteryLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          
          if (state.lastAnswerCorrect == null || livesChanged) {
            setState(() {
              _isAnswered = false;
              _isCorrect = null;
              _attempts = 0;
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
          _lastLives = state.livesRemaining;
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
          isFinalFailure: (state is EliteMasteryLoaded) ? (state.isFinalFailure || state.livesRemaining <= 0) : false,
          showConfetti: _showConfetti,
          title: "ACCENT SHADOWING",
          subtitle: quest?.instruction ?? "Speak clearly to match the accent",
          onContinue: () {
            setState(() {
              _isAnswered = false;
              _isCorrect = null;
              _attempts = 0;
              _lastWords = "";
            });
            context.read<EliteMasteryBloc>().add(NextEliteQuestion());
          },
          onHint: () {
            final bloc = context.read<EliteMasteryBloc>();
            final s = bloc.state;
            if (s is EliteMasteryLoaded) {
              if (s.currentQuest.hint != null && s.currentQuest.hint!.isNotEmpty) {
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
    if (state is EliteMasteryLoading) {
      return const GameShimmerLoading();
    }
    if (state is EliteMasteryError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 48.r,
            ),
            SizedBox(height: 16.h),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24.h),
            ScaleButton(
              onTap: () => context.read<EliteMasteryBloc>().add(
                    FetchEliteMasteryQuests(
                      gameType: widget.gameType,
                      level: widget.level,
                    ),
                  ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  "RETRY",
                  style: GoogleFonts.outfit(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
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

  Widget _buildGameUI(BuildContext context, EliteMasteryLoaded state, bool isDark, ThemeResult theme) {
    final quest = state.currentQuest;

    return Column(
      children: [
        GlassTile(
          borderRadius: BorderRadius.circular(32.r),
          padding: EdgeInsets.all(32.r),
          border: (_isAnswered || (_isCorrect == false && _attempts > 0)) ? Border.all(
            color: _isCorrect == true ? Colors.greenAccent : Colors.redAccent,
            width: 2,
          ) : null,
          child: Column(
            children: [
              Icon(Icons.record_voice_over_rounded, color: isDark ? theme.primaryColor : const Color(0xFF0F172A), size: 32.r),
              SizedBox(height: 20.h),
              _buildTargetWords(quest.text ?? quest.textToSpeak ?? "??", isDark, theme.primaryColor),
            ],
          ),
        ),
        if (state.isHintVisible) ...[
          SizedBox(height: 20.h),
          EliteHintCard(
            hintText: quest.hint,
            isVisible: true,
            onShowHint: () {},
            primaryColor: theme.primaryColor,
          ),
        ],
        SizedBox(height: 30.h),
        if (_lastWords.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15.r)),
            child: Text(_lastWords, style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w600, color: theme.primaryColor), textAlign: TextAlign.center),
          ).animate().fadeIn(),
        SizedBox(height: 40.h),
        if (!_isAnswered)
          ScaleButton(
            onTap: () => _toggleListening(quest.text ?? quest.textToSpeak ?? ""),
            child: Container(
              width: 100.r, height: 100.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? Colors.red : theme.primaryColor,
                boxShadow: [BoxShadow(color: (_isListening ? Colors.red : theme.primaryColor).withValues(alpha: 0.4), blurRadius: 30, spreadRadius: _isListening ? 10 : 0)],
              ),
              child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 48.r),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
           .scale(begin: const Offset(1, 1), end: _isListening ? const Offset(1.1, 1.1) : const Offset(1, 1), duration: 800.ms),
        if (!_isAnswered && _attempts > 0 && !_isListening)
          Padding(
            padding: EdgeInsets.only(top: 20.h),
            child: ScaleButton(
              onTap: _tutorPass,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.amber, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 18.r),
                    SizedBox(width: 8.w),
                    Text("I SPOKE CORRECTLY!", style: GoogleFonts.outfit(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 12.sp)),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn().shake(),
      ],
    );
  }

  Widget _buildTargetWords(String text, bool isDark, Color primaryColor) {
    final words = text.split(RegExp(r'\s+'));
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.w,
      runSpacing: 8.h,
      children: List.generate(words.length, (index) {
        final isMatched = _matchedIndices.contains(index);
        return Text(
          words[index],
          style: GoogleFonts.outfit(
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            color: isMatched 
              ? Colors.greenAccent 
              : (isDark ? Colors.white : const Color(0xFF1E293B)),
            height: 1.4,
            decoration: isMatched ? TextDecoration.none : null,
          ),
        ).animate(target: isMatched ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 200.ms);
      }),
    );
  }
}
