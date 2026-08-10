import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_audio_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_background_renderer.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_header.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_dialogs.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/animated_kids_asset.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/hint_utility.dart' as import_hint;
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

class KidsGameBaseScreen extends StatefulWidget {
  final String title;
  final String gameType;
  final int level;
  final Color primaryColor;
  final List<Color> backgroundColors;
  final String? painterName;
  final String? shaderName;
  final Widget Function(
    BuildContext context,
    KidsLoaded state,
    VoidCallback onHintTap,
  )
  buildGameUI;

  const KidsGameBaseScreen({
    super.key,
    required this.title,
    required this.gameType,
    required this.level,
    required this.primaryColor,
    required this.backgroundColors,
    required this.buildGameUI,
    this.painterName,
    this.shaderName,
  });

  @override
  State<KidsGameBaseScreen> createState() => KidsGameBaseScreenState();
}

class KidsGameBaseScreenState extends State<KidsGameBaseScreen> {
  bool _showBriefing = true;
  String? _hintText;
  bool _completionDialogShown = false;
  KidsLoaded? _lastLoadedState;
  bool _hasSpokenNudge = false;
  int _lastLives = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _completionDialogShown = false;
          _showBriefing = widget.level == 1;
        });
        context.read<KidsBloc>().add(
          FetchKidsQuests(widget.gameType, widget.level),
        );
      }
    });
  }

  @override
  void dispose() {
    di.sl<KidsAudioService>().stopBgm();
    di.sl<KidsTTSService>().stop();
    super.dispose();
  }

  Future<void> _speakInstruction(String instruction) async {
    try {
      final tts = di.sl<KidsTTSService>();
      if (await tts.isNarrationEnabled()) await tts.speak(instruction);
    } catch (e) {
      debugPrint("KIDS_TTS_ERROR: \$e");
    }
  }

  Future<void> speakHint(String hint) async {
    try {
      final isGeneric = import_hint.HintUtility.isGenericHint(hint);
      final displayHint = isGeneric
          ? "Pro Tip: Look closely at the pictures and tap!"
          : hint;

      setState(() => _hintText = displayHint);
      await di.sl<KidsTTSService>().speak(displayHint);
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _hintText = null);
      });
    } catch (e) {
      debugPrint("KIDS_HINT_TTS_ERROR: \$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KidsBloc, KidsState>(
      listener: (context, state) {
        final audio = di.sl<KidsAudioService>();
        if (state is KidsGameComplete) {
          if (!_completionDialogShown) {
            _completionDialogShown = true;
            audio.playLevelCompleteSFX();
            KidsGameDialogs.showCompletionDialog(
              context: context,
              state: state,
              primaryColor: widget.primaryColor,
            );
          }
        } else if (state is KidsGameOver) {
          KidsGameDialogs.showGameOverDialog(
            context: context,
            primaryColor: widget.primaryColor,
          );
        } else if (state is KidsLoaded) {
          if (state.lastAnswerCorrect == true) {
            audio.playSuccessSFX();
            final explanation = state.currentQuest.explanation;
            if (explanation != null && explanation.isNotEmpty) {
              _speakInstruction(explanation);
            }
          } else if (state.lastAnswerCorrect == false) {
            audio.playFailureSFX();
          }
          if (state.lastAnswerCorrect == null && !state.hintUsed) {
            _speakInstruction(state.currentQuest.instruction);
          }
          if (state.lastAnswerCorrect == null &&
              state.hintUsed &&
              _hintText == null) {
            speakHint(state.currentQuest.hint);
          }

          // Lifeline Nudge Logic for Kids
          final justDroppedToLastLife =
              _lastLives == 2 && state.livesRemaining == 1;
          if (justDroppedToLastLife && !_hasSpokenNudge) {
            _hasSpokenNudge = true;
            final nudgeMsg = context.tr(
              'games.kids_nudge',
              fallback: 'Let\'s go!',
            );
            Future.delayed(const Duration(milliseconds: 1200), () async {
              if (mounted) {
                final tts = di.sl<KidsTTSService>();
                if (await tts.isNarrationEnabled()) {
                  await tts.speak(nudgeMsg);
                }
                di.sl<HapticService>().warning();
              }
            });
          }
          _lastLives = state.livesRemaining;
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await KidsGameDialogs.showExitConfirmation(
              context: context,
              primaryColor: widget.primaryColor,
            );
            if (shouldPop && context.mounted) context.pop();
          },
          child: Scaffold(
            backgroundColor: widget.primaryColor,
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                KidsBackgroundRenderer(
                  painterName: "KidsWorldBackground",
                  shaderName: widget.shaderName ?? "",
                  primaryColor: widget.primaryColor,
                  gameType: widget.gameType,
                ),
                SafeArea(
                  child: Column(
                    children: [
                      KidsGameHeader(
                        title: widget.title,
                        level: widget.level,
                        primaryColor: widget.primaryColor,
                        state: state,
                        onInfoTap: () => setState(() => _showBriefing = true),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            _buildBody(context, state),
                            if (state is KidsLoaded)
                              _buildDynamicMascot(context, state)
                            else if ((state is KidsGameComplete ||
                                    state is KidsGameOver) &&
                                _lastLoadedState != null)
                              _buildDynamicMascot(context, _lastLoadedState!),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showBriefing)
                  Builder(
                    builder: (context) {
                      // Get briefing using the gameType (category) as the fallback title
                      final briefing = GameInstructionService.getBriefing(
                        context,
                        null,
                        widget.gameType,
                        level: widget.level,
                      );
                      return QuestBriefingOverlay(
                        title: briefing.title,
                        objective: briefing.objective,
                        rules: briefing.rules,
                        actionText: briefing.actionText,
                        tip: briefing.tip,
                        icon: briefing.icon,
                        primaryColor: widget.primaryColor,
                        onStart: () => setState(() => _showBriefing = false),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, KidsState state) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (state is KidsLoading) {
      return const SafeArea(child: GameShimmerLoading());
    }
    if (state is KidsLoaded) {
      _lastLoadedState = state;
    }

    final displayState = (state is KidsLoaded) ? state : _lastLoadedState;

    if (displayState != null &&
        (state is KidsLoaded ||
            state is KidsGameComplete ||
            state is KidsGameOver)) {
      return Stack(
        children: [
          widget.buildGameUI(
            context,
            displayState,
            () => speakHint(displayState.currentQuest.hint),
          ),
          if (state is KidsLoaded && state.lastAnswerCorrect != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GameFeedbackCard(
                isCorrect: state.lastAnswerCorrect,
                isFinalFailure: state.isFinalFailure,
                livesRemaining: state.livesRemaining,
                isDark: isDark,
                primaryColor: widget.primaryColor,
                explanation: state.lastAnswerCorrect == true
                    ? state.currentQuest.explanation
                    : null,
                onContinue: () {
                  di.sl<KidsTTSService>().stop();
                  if (state.lastAnswerCorrect == true ||
                      state.isFinalFailure ||
                      state.livesRemaining <= 0) {
                    context.read<KidsBloc>().add(NextKidsQuestion());
                  } else {
                    context.read<KidsBloc>().add(ClearKidsFeedback());
                  }
                },
              ),
            ),
        ],
      );
    }
    if (state is KidsError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const AnimatedKidsAsset(
                  emoji: '\u{1F388}',
                  size: 120,
                  animation: KidsAssetAnimation.hover,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              SizedBox(height: 32.h),
              Text(
                context.tr('games.kids_error_title', fallback: 'Oops!'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ).animate().fadeIn().slideY(begin: 0.2),
              SizedBox(height: 12.h),
              Text(
                context.tr(
                  'games.kids_error_body',
                  fallback: 'Something went wrong.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 200.ms),
              SizedBox(height: 48.h),
              ScaleButton(
                    onTap: () => context.read<KidsBloc>().add(
                      FetchKidsQuests(widget.gameType, widget.level),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 40.w,
                        vertical: 16.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 3.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            offset: Offset(0, 5.h),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: widget.primaryColor,
                            size: 24.r,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            context
                                .tr('games.try_again', fallback: 'Try Again')
                                .toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                              color: widget.primaryColor,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDynamicMascot(BuildContext context, KidsLoaded state) {
    bool isComplete = false;
    bool isGameOver = false;
    bool isAnswered = state.lastAnswerCorrect != null;
    bool? isCorrect = state.lastAnswerCorrect;
    int lives = state.livesRemaining;

    final mascotState = MascotMessageHelper.getMascotState(
      isComplete: isComplete,
      isGameOver: isGameOver,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String displayMessage = "";
        if (_hintText != null) {
          displayMessage = _hintText!;
        } else if (state.lastAnswerCorrect == null) {
          displayMessage = state.currentQuest.instruction;

          // The data layer now safely ensures the target letter is never printed
          // directly in the instruction, eliminating the need for regex dash replacement.
        } else if (state.lastAnswerCorrect == true) {
          displayMessage =
              state.currentQuest.funFact ??
              state.currentQuest.explanation ??
              "Great job!";
        } else {
          displayMessage = "";
        }

        return Positioned(
          left: 16.w,
          top: 10.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VowlMascot(
                isKidsMode: true,
                size: 60.r,
                state: mascotState,
                useFloatingAnimation: true,
              ),
              if (displayMessage.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 12.w, top: 10.h),
                  child: _buildSpeechBubble(context, displayMessage),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeechBubble(BuildContext context, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      constraints: BoxConstraints(maxWidth: 240.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4.r),
          topRight: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
          bottomLeft: Radius.circular(20.r),
        ),
        border: Border.all(color: Colors.grey.shade300, width: 3.w),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, offset: Offset(0, 5.h)),
        ],
      ),
      child: KidsFittedText(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
          height: 1.2,
        ),
        maxLines: 6,
      ),
    ).animate().scale(
      begin: Offset.zero,
      duration: 400.ms,
      curve: Curves.easeOutBack,
    );
  }
}
