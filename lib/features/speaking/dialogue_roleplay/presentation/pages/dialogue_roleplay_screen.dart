import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

// Highly aesthetic Synaptic link custom painter displaying fluid particle flow along connection nodes
class SynapticLinkPainter extends CustomPainter {
  final double time;
  final bool isConnected;
  final Color themeColor;

  SynapticLinkPainter({
    required this.time,
    required this.isConnected,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = isConnected
          ? Colors.greenAccent.withValues(alpha: 0.3)
          : themeColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.r;

    final Paint glowPaint = Paint()
      ..color = isConnected ? Colors.greenAccent : themeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.r
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.r);

    final Path path = Path();
    path.moveTo(size.width / 2, 0);

    // Double Bezier curving flow representing dynamic synaptic transmission
    path.cubicTo(
      size.width / 2 - 30.w,
      size.height * 0.3,
      size.width / 2 + 30.w,
      size.height * 0.7,
      size.width / 2,
      size.height,
    );

    canvas.drawPath(path, linePaint);
    if (isConnected) {
      canvas.drawPath(path, glowPaint);
    }

    // Floating electrical nodes/particles along the bezier path
    final pathMetrics = path.computeMetrics();
    for (var metric in pathMetrics) {
      final double progress = (time * 0.8) % 1.0;
      final tangent = metric.getTangentForOffset(metric.length * progress);
      if (tangent != null) {
        final Paint particlePaint = Paint()
          ..color = isConnected ? Colors.greenAccent : Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawCircle(tangent.position, 4.r, particlePaint);
        canvas.drawCircle(
          tangent.position,
          8.r,
          Paint()
            ..color = (isConnected ? Colors.greenAccent : themeColor).withValues(alpha: 0.4)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.r),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SynapticLinkPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.isConnected != isConnected;
  }
}

class DialogueRoleplayScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const DialogueRoleplayScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.dialogueRoleplay,
  });

  @override
  State<DialogueRoleplayScreen> createState() => _DialogueRoleplayScreenState();
}

class _DialogueRoleplayScreenState extends State<DialogueRoleplayScreen> with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;

  late AnimationController _synapticController;
  double _timeVal = 0.0;
  String _spokenText = "";
  List<String> _acceptedSynonyms = [];

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));

    _synapticController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        setState(() {
          _timeVal = _synapticController.value;
        });
      });
    _synapticController.repeat();
  }

  @override
  void dispose() {
    _synapticController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(SpeakingQuest quest) {
    if (quest.partnerDialogue != null) {
      _soundService.playTts(quest.partnerDialogue!);
    }
  }

  void _startSpeechListening() async {
    if (_isAnswered) return;
    _hapticService.selection();

    setState(() {
      _isListening = true;
      _spokenText = "Awaiting verbal speech input...";
    });

    _speechService.listen(
      onResult: (text) {
        setState(() {
          _spokenText = text;
        });
      },
      onDone: () {
        if (mounted) setState(() => _isListening = false);
      },
    );
  }

  void _stopSpeechListening() async {
    await _speechService.stop();

    setState(() {
      _isListening = false;
    });

    _verifyResponseSpoken();
  }

  void _verifyResponseSpoken() {
    if (_spokenText.isEmpty || _spokenText.startsWith("Awaiting")) {
      setState(() {
        _spokenText = "No vocal signals transcribed.";
      });
      _hapticService.error();
      return;
    }

    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    // Semantic evaluation against accepted dialog synonyms
    bool matchFound = false;

    for (var sub in _acceptedSynonyms) {
      final String cleanSub = sub.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
      if (cleanSpeech.contains(cleanSub)) {
        matchFound = true;
        break;
      }
    }

    setState(() {
      _isAnswered = true;
      _isCorrect = matchFound;
    });

    if (matchFound) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<SpeakingBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isListening = false;
              _spokenText = "";
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'DIALOGUE EXPERT!',
            enableDoubleUp: true,
          );
        } else if (state is SpeakingGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<SpeakingBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        if (quest != null) {
          _acceptedSynonyms = quest.acceptedSynonyms ?? [];
        }

        return SpeakingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<SpeakingBloc>().add(NextQuestion()),
          onHint: () => context.read<SpeakingBloc>().add(SpeakingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Column(
                    children: [
                      _buildHeaderPill(theme.primaryColor),
                      SizedBox(height: 16.h),

                      // Interactive Dialogue Exchange Stage
                      _buildRoleplayExchangeStage(quest, theme.primaryColor, isDark),
                      SizedBox(height: 20.h),

                      // Decoded Telemetry screen
                      if (_spokenText.isNotEmpty) ...[
                        _buildSpeechTelemetryCard(isDark),
                        SizedBox(height: 20.h),
                      ],

                      // Explanation details
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: _buildExplanationCard(quest, isDark),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 30.h),

                      // Dialog Microphone Trigger
                      if (!_isAnswered)
                        _buildDialogueMicTrigger(theme.primaryColor, isDark),
                      SizedBox(height: 50.h),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeaderPill(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.record_voice_over_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 8.w),
          Text(
            "SYNAPTIC DIALOGUE EXCHANGE",
            style: GoogleFonts.shareTechMono(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleplayExchangeStage(SpeakingQuest quest, Color primaryColor, bool isDark) {
    final bool isCompleted = _isAnswered && (_isCorrect ?? false);

    return Column(
      children: [
        // AI Partner Speech Card
        _buildBubbleCard(
          title: "ROLEPLAY PARTNER",
          content: quest.partnerDialogue ?? "Dialogue statement.",
          avatarIcon: Icons.support_agent_rounded,
          color: primaryColor,
          isUser: false,
          isDark: isDark,
        ),

        // Curving dynamic particle wire connection
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: SizedBox(
            height: 60.h,
            width: double.infinity,
            child: CustomPaint(
              painter: SynapticLinkPainter(
                time: _timeVal,
                isConnected: isCompleted,
                themeColor: primaryColor,
              ),
            ),
          ),
        ),

        // User Spoken Target Card
        _buildBubbleCard(
          title: "YOUR RESPONSE OBLIGATION",
          content: quest.sampleAnswer ?? "Expected response.",
          avatarIcon: Icons.face_rounded,
          color: Colors.greenAccent,
          isUser: true,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildBubbleCard({
    required String title,
    required String content,
    required IconData avatarIcon,
    required Color color,
    required bool isUser,
    required bool isDark,
  }) {
    final bool highlight = isUser && _isAnswered && (_isCorrect ?? false);
    final Color borderCol = highlight
        ? Colors.greenAccent
        : (isUser ? color.withValues(alpha: 0.4) : color.withValues(alpha: 0.6));

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131326) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderCol, width: highlight ? 2 : 1),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.25),
                  blurRadius: 15.r,
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8.r,
                )
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: highlight ? Colors.greenAccent.withValues(alpha: 0.1) : color.withValues(alpha: 0.1),
            child: Icon(avatarIcon, color: highlight ? Colors.greenAccent : color, size: 20.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 9.sp,
                        color: highlight ? Colors.greenAccent : color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (!isUser)
                      ScaleButton(
                        onTap: () => _soundService.playTts(content),
                        child: Icon(Icons.volume_up_rounded, color: color, size: 16.r),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  content,
                  style: GoogleFonts.fredoka(
                    fontSize: 14.sp,
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechTelemetryCard(bool isDark) {
    final bool hasInput = _spokenText != "Awaiting verbal speech input..." && _spokenText != "No vocal signals transcribed.";

    return GlassTile(
      padding: EdgeInsets.all(18.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                hasInput ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: Colors.cyanAccent,
                size: 16.r,
              ),
              SizedBox(width: 8.w),
              Text(
                "DECODED DIALOGUE ANALYSIS",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            _spokenText,
            style: GoogleFonts.fredoka(
              fontSize: 14.sp,
              color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildExplanationCard(SpeakingQuest quest, bool isDark) {
    final Color cardColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131326) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.15),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                (_isCorrect ?? false) ? Icons.verified_rounded : Icons.info_rounded,
                color: cardColor,
                size: 24.r,
              ),
              SizedBox(width: 8.w),
              Text(
                (_isCorrect ?? false) ? "Roleplay Response Authenticated" : "Dialogue Synapse Failed",
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            quest.explanation ?? "Polite conversational exchanges prepare you for real-world speech dynamics.",
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.35,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildDialogueMicTrigger(Color primaryColor, bool isDark) {
    return GestureDetector(
      onLongPressStart: (_) => _startSpeechListening(),
      onLongPressEnd: (_) => _stopSpeechListening(),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Rippling acoustic circular waves
              if (_isListening)
                ...List.generate(4, (i) {
                  return Container(
                    width: 76.r + (i * 24.r),
                    height: 76.r + (i * 24.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        width: 1.5.r,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.15, 1.15), duration: 800.ms, curve: Curves.easeOut)
                  .fadeOut();
                }),

              // Boundary Ring
              Container(
                width: 96.r,
                height: 96.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: _isListening
                        ? Colors.greenAccent.withValues(alpha: 0.35)
                        : primaryColor.withValues(alpha: 0.15),
                    width: 4.r,
                  ),
                ),
              ).animate(target: _isListening ? 1 : 0).scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.18, 1.18),
                    duration: 1.seconds,
                    curve: Curves.easeInOut,
                  ),

              // Interactive Mic Core
              ScaleButton(
                onTap: () {},
                child: Container(
                  width: 76.r,
                  height: 76.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isListening
                          ? [Colors.teal[900]!, Colors.greenAccent]
                          : [const Color(0xFF1F1C2C), const Color(0xFF928DAB)],
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.45),
                              blurRadius: 25.r,
                              spreadRadius: 2.r,
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10.r,
                            )
                          ],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 32.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            _isListening
                ? "RELEASE MICROPHONE TO TRANSMIT DIALOGUE"
                : "HOLD MICROPHONE TO REPLY TO ROLEPLAY PARTNER",
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(
              fontSize: 9.sp,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
