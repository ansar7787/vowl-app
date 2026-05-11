import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_feedback_overlay.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_audio_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_background_renderer.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_header.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_dialogs.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/animated_kids_asset.dart';
import 'package:vowl/core/utils/haptic_service.dart';

class KidsGameBaseScreen extends StatefulWidget {
  final String title;
  final String gameType;
  final int level;
  final Color primaryColor;
  final List<Color> backgroundColors;
  final String? painterName;
  final String? shaderName;
  final Widget Function(BuildContext context, KidsLoaded state, VoidCallback onHintTap) buildGameUI;

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
  String? _hintText;
  bool _completionDialogShown = false;
  bool _hasSpokenNudge = false;
  int _lastLives = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _completionDialogShown = false);
        context.read<KidsBloc>().add(FetchKidsQuests(widget.gameType, widget.level));
      }
    });
  }

  @override
  void dispose() {
    di.sl<KidsAudioService>().stopBgm();
    super.dispose();
  }

  Future<void> _speakInstruction(String instruction) async {
    try {
      final tts = di.sl<KidsTTSService>();
      if (await tts.isNarrationEnabled()) await tts.speak(instruction);
    } catch (e) { debugPrint("KIDS_TTS_ERROR: $e"); }
  }

  Future<void> speakHint(String hint) async {
    try {
      setState(() => _hintText = hint);
      await di.sl<KidsTTSService>().speak(hint);
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _hintText = null);
      });
    } catch (e) { debugPrint("KIDS_HINT_TTS_ERROR: $e"); }
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
            KidsGameDialogs.showCompletionDialog(context: context, state: state, primaryColor: widget.primaryColor);
          }
        } else if (state is KidsGameOver) {
          audio.playFailureSFX();
          KidsGameDialogs.showGameOverDialog(context: context, primaryColor: widget.primaryColor);
        } else if (state is KidsLoaded) {
          if (state.lastAnswerCorrect == true) {
            audio.playSuccessSFX();
            speakHint("That's right! ${state.currentQuest.hint}");
            final bloc = context.read<KidsBloc>();
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted && context.mounted && bloc.state == state) bloc.add(NextKidsQuestion());
            });
          } else if (state.lastAnswerCorrect == false) {
            audio.playFailureSFX();
            final bloc = context.read<KidsBloc>();
            final isFinalFailure = state.isFinalFailure || state.livesRemaining <= 0;
            
            Future.delayed(Duration(milliseconds: isFinalFailure ? 2500 : 2000), () {
              if (mounted && context.mounted && bloc.state == state) {
                if (isFinalFailure) {
                  bloc.add(NextKidsQuestion());
                } else {
                  bloc.add(ClearKidsFeedback());
                }
              }
            });
          }
          if (state.lastAnswerCorrect == null && !state.hintUsed) _speakInstruction(state.currentQuest.instruction);
          if (state.lastAnswerCorrect == null && state.hintUsed && _hintText == null) speakHint(state.currentQuest.hint);

          // Lifeline Nudge Logic for Kids
          final justDroppedToLastLife = _lastLives == 2 && state.livesRemaining == 1;
          if (justDroppedToLastLife && !_hasSpokenNudge) {
            _hasSpokenNudge = true;
            Future.delayed(const Duration(milliseconds: 1200), () async {
              if (mounted) {
                final tts = di.sl<KidsTTSService>();
                if (await tts.isNarrationEnabled()) {
                  await tts.speak(
                    "Owww hint consume save your life",
                  );
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
                KidsBackgroundRenderer(painterName: "KidsWorldBackground", shaderName: widget.shaderName ?? "", primaryColor: widget.primaryColor, gameType: widget.gameType),
                SafeArea(
                  child: Column(
                    children: [
                      KidsGameHeader(title: widget.title, level: widget.level, primaryColor: widget.primaryColor, state: state, hintText: _hintText),
                      Expanded(child: _buildBody(context, state)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, KidsState state) {
    if (state is KidsLoading) return const Center(child: CircularProgressIndicator());
    if (state is KidsLoaded) {
      return Stack(
        children: [
          widget.buildGameUI(context, state, () => speakHint(state.currentQuest.hint)),
          if (state.lastAnswerCorrect == true)
            Positioned(
              bottom: 30.h,
              right: 25.w,
              child: ScaleButton(
                onTap: () => context.read<KidsBloc>().add(NextKidsQuestion()),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [widget.primaryColor, widget.primaryColor.withValues(alpha: 0.8)]),
                    borderRadius: BorderRadius.circular(30.r),
                    boxShadow: [BoxShadow(color: widget.primaryColor.withValues(alpha: 0.3), blurRadius: 15)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text("NEXT", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14.sp, letterSpacing: 1)),
                    SizedBox(width: 8.w),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20.sp),
                  ]),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1), duration: 800.ms).animate().fadeIn(delay: 1.seconds),
            ),
          if (state.lastAnswerCorrect != null)
            KidsFeedbackOverlay(
              isCorrect: state.lastAnswerCorrect!,
              attempts: state.attempts,
              onTap: () {
                if (state.lastAnswerCorrect!) { context.read<KidsBloc>().add(NextKidsQuestion()); } 
                else { 
                  if (state.isFinalFailure || state.livesRemaining <= 0) {
                    context.read<KidsBloc>().add(NextKidsQuestion());
                  } else {
                    context.read<KidsBloc>().add(ClearKidsFeedback());
                  }
                }
              },
            ),
        ],
      );
    }
    if (state is KidsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AnimatedKidsAsset(emoji: '\u{1F388}', size: 150, animation: KidsAssetAnimation.hover),
            SizedBox(height: 20.h),
            Text("NICE TRY!", style: GoogleFonts.poppins(fontSize: 24.sp, fontWeight: FontWeight.w900, color: widget.primaryColor)),
            SizedBox(height: 10.h),
            Text("This level is taking a nap. \nCheck back soon! \u{1F388}", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
