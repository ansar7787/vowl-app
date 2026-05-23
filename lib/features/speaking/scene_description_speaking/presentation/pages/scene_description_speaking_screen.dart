import 'dart:async';
import 'dart:math' as math;
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

// Highly premium Radar Ripple Custom Painter to display pulsing sonar beacons for scene exploration
class RadarBeaconPainter extends CustomPainter {
  final double progress;
  final bool isActive;
  final bool isCompleted;
  final Color primaryColor;

  RadarBeaconPainter({
    required this.progress,
    required this.isActive,
    required this.isCompleted,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2;

    if (isCompleted) {
      // Completed solid static emerald green glow
      final Paint solidPaint = Paint()
        ..color = Colors.greenAccent
        ..style = PaintingStyle.fill;
      final Paint glowPaint = Paint()
        ..color = Colors.greenAccent.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.r);

      canvas.drawCircle(center, maxRadius * 0.4, glowPaint);
      canvas.drawCircle(center, maxRadius * 0.35, solidPaint);
      return;
    }

    if (isActive) {
      // Rapid active glowing expansion ripples
      final Paint ripplePaint = Paint()
        ..color = primaryColor.withValues(alpha: 1.0 - progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.w;

      final Paint corePaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, maxRadius * progress, ripplePaint);
      canvas.drawCircle(center, maxRadius * 0.4, corePaint);
    } else {
      // Gentle floating sleeping beacons
      final Paint sleepPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.2 + (0.3 * math.sin(progress * math.pi * 2)))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, maxRadius * 0.45, sleepPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RadarBeaconPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isActive != isActive ||
        oldDelegate.isCompleted != isCompleted;
  }
}

class SceneDescriptionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const SceneDescriptionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.sceneDescriptionSpeaking,
  });

  @override
  State<SceneDescriptionScreen> createState() => _SceneDescriptionScreenState();
}

class _SceneDescriptionScreenState extends State<SceneDescriptionScreen> with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  final Set<int> _inspectedHotspots = {};
  int _activeHotspot = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;

  // Shimmer controller for active radar beacons
  late AnimationController _radarController;
  String _spokenText = "";
  List<String> _hotspotLabels = [];
  List<String> _hotspotPrompts = [];
  List<List<String>> _hotspotKeywords = [];
  String _sceneTitle = "Scene Visualizer";

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(SpeakingQuest quest) {
    // Speak scene title or prompt
    if (quest.sceneText != null) {
      final parts = quest.sceneText!.split('|');
      _soundService.playTts(parts[0]);
    }
  }

  void _onHotspotTap(int index) {
    if (_isAnswered || _inspectedHotspots.contains(index)) return;
    _hapticService.selection();
    _soundService.playTts(_hotspotLabels[index]);
    setState(() {
      _activeHotspot = index;
      _spokenText = "";
    });
  }

  void _startSpeechListening() async {
    if (_isAnswered || _activeHotspot == -1) return;
    _hapticService.selection();

    setState(() {
      _isListening = true;
      _spokenText = "Calibrating vocal description synthesizer...";
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

    _verifyDescriptionSpoken();
  }

  void _verifyDescriptionSpoken() {
    if (_spokenText.isEmpty || _spokenText.startsWith("Calibrating")) {
      setState(() {
        _spokenText = "No acoustic details detected.";
      });
      _hapticService.error();
      return;
    }

    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final List<String> keywords = _hotspotKeywords[_activeHotspot];

    // Semantic evaluation: does the transcribed speech contain ANY of the target keywords?
    bool matchFound = false;

    for (var key in keywords) {
      if (cleanSpeech.contains(key.trim().toLowerCase())) {
        matchFound = true;
        break;
      }
    }

    if (matchFound) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _inspectedHotspots.add(_activeHotspot);
        _spokenText = "DECODED SUCCESSFULLY! '${_hotspotLabels[_activeHotspot]}' visual verified.";
        _activeHotspot = -1; // Reset active hotspot to invite next exploration
      });

      // If all 3 hotspots are fully inspected, complete the quest!
      if (_inspectedHotspots.length >= 3) {
        setState(() {
          _isAnswered = true;
          _isCorrect = true;
        });
        context.read<SpeakingBloc>().add(SubmitAnswer(true));
      }
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _spokenText = "Detail mismatch. Focus your description and use key terms: ${keywords.join(', ')}.";
      });
    }
  }

  void _parseQuestData(SpeakingQuest quest) {
    _hotspotLabels = quest.options ?? ["Object A", "Object B", "Object C"];
    
    // Parse scene text structure: "Scene Name|Prompt 1|Prompt 2|Prompt 3"
    final String text = quest.sceneText ?? "Visual Space Cabin|Describe features.|Describe features.|Describe features.";
    final List<String> parts = text.split('|');
    _sceneTitle = parts[0];
    
    _hotspotPrompts = [];
    for (int i = 1; i <= 3; i++) {
      _hotspotPrompts.add(parts.length > i ? parts[i] : "Describe this scenic component.");
    }

    // Parse accepted synonyms list containing comma-separated lists
    _hotspotKeywords = [];
    final List<String> list = quest.acceptedSynonyms ?? ["feature", "object", "item"];
    for (int i = 0; i < 3; i++) {
      final String keywordsString = list.length > i ? list[i] : "feature,item";
      _hotspotKeywords.add(keywordsString.split(','));
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
              _inspectedHotspots.clear();
              _activeHotspot = -1;
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
            title: 'VISUAL MASTERPIECE!',
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
          _parseQuestData(quest);
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

                      // Panoramic Scenic Radar Map
                      _buildScenicRadarMap(theme.primaryColor, isDark),
                      SizedBox(height: 20.h),

                      // Sub-Hotspot active Prompt block
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _activeHotspot != -1
                            ? _buildActivePromptCard(theme.primaryColor, isDark)
                            : _buildExplorerGuideCard(isDark),
                      ),
                      SizedBox(height: 20.h),

                      // Decoded acoustic telemetry Console
                      if (_spokenText.isNotEmpty) ...[
                        _buildDecodedTelemetryCard(isDark),
                        SizedBox(height: 20.h),
                      ],

                      // Explanatory Details
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: _buildExplanationCard(quest, isDark),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 30.h),

                      // Description Mic Button
                      if (!_isAnswered)
                        _buildDescriptionMicTrigger(theme.primaryColor, isDark),
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
          Icon(Icons.gps_fixed_rounded, size: 14.r, color: Colors.cyanAccent),
          SizedBox(width: 8.w),
          Text(
            "SCENIC SONAR BEACON MAP",
            style: GoogleFonts.shareTechMono(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenicRadarMap(Color primaryColor, bool isDark) {
    return Container(
      width: 1.sw,
      height: 230.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131326) : Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15.r,
          )
        ],
      ),
      child: Stack(
        children: [
          // Background atmospheric visualizer waves
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return CustomPaint(
                  painter: RadarBeaconPainter(
                    progress: _radarController.value,
                    isActive: false,
                    isCompleted: false,
                    primaryColor: primaryColor,
                  ),
                );
              },
            ),
          ),

          // Central Scene Title
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_size_select_large_rounded, color: primaryColor, size: 36.r),
                  SizedBox(height: 8.h),
                  Text(
                    _sceneTitle.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "${_inspectedHotspots.length} OF 3 FEATURES STABILIZED",
                    style: GoogleFonts.shareTechMono(
                      fontSize: 10.sp,
                      color: _inspectedHotspots.length == 3 ? Colors.greenAccent : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3 Dynamic Sonar Hotspots in top-left, top-right, bottom-center
          _buildPulsingBeacon(0, Alignment.topLeft, primaryColor),
          _buildPulsingBeacon(1, Alignment.topRight, primaryColor),
          _buildPulsingBeacon(2, Alignment.bottomCenter, primaryColor),
        ],
      ),
    );
  }

  Widget _buildPulsingBeacon(int index, Alignment alignment, Color primaryColor) {
    final isInspected = _inspectedHotspots.contains(index);
    final isActive = _activeHotspot == index;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.all(22.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _onHotspotTap(index),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      return SizedBox(
                        width: 52.r,
                        height: 52.r,
                        child: CustomPaint(
                          painter: RadarBeaconPainter(
                            progress: _radarController.value,
                            isActive: isActive,
                            isCompleted: isInspected,
                            primaryColor: primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
                  // Icon indicator
                  Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isInspected
                          ? Colors.greenAccent
                          : (isActive ? primaryColor : Colors.black26),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Icon(
                      isInspected
                          ? Icons.check_rounded
                          : (isActive ? Icons.spatial_tracking_rounded : Icons.radar_rounded),
                      color: Colors.white,
                      size: 14.r,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              _hotspotLabels[index].toUpperCase(),
              style: GoogleFonts.shareTechMono(
                fontSize: 8.sp,
                color: isInspected
                    ? Colors.greenAccent
                    : (isActive ? primaryColor : Colors.grey),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePromptCard(Color primaryColor, bool isDark) {
    return Container(
      key: ValueKey("active_prompt_$_activeHotspot"),
      width: 1.sw,
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1A) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.spatial_audio_off_rounded, color: primaryColor, size: 14.r),
              SizedBox(width: 8.w),
              Text(
                "DESCRIBE COMPONENT",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: primaryColor,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            _hotspotPrompts[_activeHotspot],
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 15.sp,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplorerGuideCard(bool isDark) {
    return Container(
      key: const ValueKey("explorer_guide"),
      width: 1.sw,
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131326) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.grey, size: 16.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              "TAP ANY OF THE PULSING SONAR HOTSPOTS ON THE SCENE CARD ABOVE TO INSPECT AND RECORD YOUR DESCRIPTION.",
              style: GoogleFonts.shareTechMono(
                fontSize: 9.sp,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecodedTelemetryCard(bool isDark) {
    final bool isSuccess = _spokenText.startsWith("DECODED SUCCESSFULLY!");

    return GlassTile(
      padding: EdgeInsets.all(18.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.verified_user_rounded : Icons.sensors_rounded,
                color: isSuccess ? Colors.greenAccent : Colors.cyanAccent,
                size: 16.r,
              ),
              SizedBox(width: 8.w),
              Text(
                "DECODED SPEECH ANALYSIS",
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
              color: isSuccess
                  ? Colors.greenAccent
                  : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
              height: 1.35,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildExplanationCard(SpeakingQuest quest, bool isDark) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131326) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Colors.greenAccent.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withValues(alpha: 0.15),
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
                Icons.verified_rounded,
                color: Colors.greenAccent,
                size: 24.r,
              ),
              SizedBox(width: 8.w),
              Text(
                "All Features Decoded!",
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
            quest.explanation ?? "Detailed visual description tests the extreme boundaries of native structural vocabulary and situational syntax.",
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

  Widget _buildDescriptionMicTrigger(Color primaryColor, bool isDark) {
    final bool canRecord = _activeHotspot != -1;

    return GestureDetector(
      onLongPressStart: (_) => canRecord ? _startSpeechListening() : null,
      onLongPressEnd: (_) => canRecord ? _stopSpeechListening() : null,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Rippling concentric audio paths
              if (_isListening)
                ...List.generate(4, (i) {
                  return Container(
                    width: 76.r + (i * 24.r),
                    height: 76.r + (i * 24.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.15),
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
                    color: canRecord
                        ? (_isListening
                            ? Colors.redAccent.withValues(alpha: 0.35)
                            : primaryColor.withValues(alpha: 0.15))
                        : Colors.grey.withValues(alpha: 0.1),
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
                      colors: canRecord
                          ? (_isListening
                              ? [Colors.red[900]!, Colors.redAccent]
                              : [const Color(0xFF1F1C2C), const Color(0xFF928DAB)])
                          : [Colors.grey[800]!, Colors.grey[900]!],
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.45),
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
            !canRecord
                ? "TAP PULSING RADAR BEACON TO UNLOCK MIC"
                : (_isListening
                    ? "RELEASE MICROPHONE TO ANALYZE DESCRIPTION"
                    : "HOLD MICROPHONE TO DESCRIBE SELECTION"),
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
