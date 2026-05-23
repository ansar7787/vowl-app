import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
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

// Visual vortex and pull energy connector custom painter
class VortexPainter extends CustomPainter {
  final double animationTime;
  final Offset? pullCenter;
  final Offset? optionPos;
  final Color themeColor;

  VortexPainter({
    required this.animationTime,
    this.pullCenter,
    this.optionPos,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    // 1. Draw glowing vortex rings
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.w
      ..color = themeColor.withValues(alpha: 0.25);

    canvas.drawCircle(center, radius - 20.w, ringPaint);
    canvas.drawCircle(center, radius - 40.w, ringPaint);

    // 2. Draw spinning particles inside vortex
    final Paint particlesPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final int numPoints = 8;
    for (int i = 0; i < numPoints; i++) {
      final double angle = (i * 2 * math.pi / numPoints) + (animationTime * 2 * math.pi);
      final double distance = 30.w + math.sin(animationTime * 2 * math.pi + i) * 10.w;
      final Offset particlePos = center + Offset(math.cos(angle) * distance, math.sin(angle) * distance);
      canvas.drawCircle(particlePos, 3.r, particlesPaint);
    }

    // 3. Draw energy pull beam
    if (pullCenter != null && optionPos != null) {
      final Paint beamPaint = Paint()
        ..color = themeColor
        ..strokeWidth = 3.w
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      final Paint corePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.w
        ..style = PaintingStyle.stroke;

      canvas.drawLine(pullCenter!, optionPos!, beamPaint);
      canvas.drawLine(pullCenter!, optionPos!, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant VortexPainter oldDelegate) {
    return oldDelegate.animationTime != animationTime ||
        oldDelegate.pullCenter != pullCenter ||
        oldDelegate.optionPos != optionPos ||
        oldDelegate.themeColor != themeColor;
  }
}

class SpeakMissingWordScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SpeakMissingWordScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speakMissingWord,
  });

  @override
  State<SpeakMissingWordScreen> createState() => _SpeakMissingWordScreenState();
}

class _SpeakMissingWordScreenState extends State<SpeakMissingWordScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  late AnimationController _vortexController;

  int _lastProcessedIndex = -1;
  int? _lastLives;

  // Option states
  List<String> _dynamicOptions = [];
  String? _selectedWord;
  double _pullForce = 0.0;
  bool _isListening = false;
  bool _isWordPlaced = false;

  // Speech states
  String _spokenText = "";
  bool _isSpeechActive = false;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _vortexController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _vortexController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      _soundService.playTts(quest.textToSpeak!);
    }
  }

  // Generates robust unique options including the correct missing word plus relevant vocabulary terms
  void _generateDynamicOptions(String correctWord) {
    final List<String> distractors = [
      "satellite", "reactor", "circuit", "database",
      "system", "portal", "shield", "drone", "module"
    ];

    distractors.remove(correctWord.toLowerCase());
    distractors.shuffle(math.Random(widget.level));

    _dynamicOptions = [
      correctWord.toLowerCase(),
      distractors[0],
      distractors[1],
    ];

    _dynamicOptions.shuffle(math.Random(widget.level));
  }

  // Dynamic sentence blanks formatter replacing target nouns with [ ____ ]
  String _formatBlankSentence(String text, String missingWord) {
    final String cleanText = text;
    final List<String> nouns = [
      missingWord.toLowerCase(),
      "circuit", "database", "satellite", "shield",
      "reactor", "module", "engine", "network", "laser",
      "drone", "system", "portal", "archive", "data"
    ];

    for (var noun in nouns) {
      final int index = cleanText.toLowerCase().indexOf(noun);
      if (index != -1) {
        // Return string with a high-fidelity visual blank segment
        return cleanText.replaceRange(index, index + noun.length, " [ ______ ] ");
      }
    }

    return cleanText.replaceAll(missingWord, " [ ______ ] ");
  }

  void _onPullStart(String word) {
    if (_isAnswered || _isWordPlaced) return;
    _hapticService.selection();
    setState(() {
      _selectedWord = word;
      _isListening = true;
    });
  }

  void _onPullEnd() {
    if (_isAnswered || _isWordPlaced) return;
    setState(() {
      _isListening = false;
    });
    if (_pullForce >= 1.0) {
      _hapticService.success();
      _soundService.playClick(); // Play locked chime hum
      setState(() {
        _isWordPlaced = true;
      });
    } else {
      setState(() {
        _pullForce = 0.0;
        _selectedWord = null;
      });
    }
  }

  void _startSpeechListening() async {
    if (_isAnswered || !_isWordPlaced) return;
    _hapticService.selection();

    setState(() {
      _isSpeechActive = true;
      _spokenText = "Voice capturing initiated...";
    });

    _speechService.listen(
      onResult: (text) {
        setState(() {
          _spokenText = text;
        });
      },
      onDone: () {
        if (mounted) setState(() => _isSpeechActive = false);
      },
    );
  }

  void _stopSpeechListening(String correctAnswer) async {
    await _speechService.stop();
    setState(() => _isSpeechActive = false);
    _verifySpeech(correctAnswer);
  }

  void _verifySpeech(String expected) {
    if (_spokenText.isEmpty || _spokenText.startsWith("Voice capturing")) {
      setState(() {
        _spokenText = "No speech input recorded.";
      });
      return;
    }

    // 1. Check if the user selected the correct word
    final bool wordIsCorrect = _selectedWord?.toLowerCase() == expected.toLowerCase();

    // 2. Check if user read the completed sentence correctly
    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final String cleanExpected = expected.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    final List<String> speechWords = cleanSpeech.split(' ');
    final List<String> expectedWords = cleanExpected.split(' ');

    int matches = 0;
    for (var word in speechWords) {
      if (expectedWords.contains(word)) {
        matches++;
      }
    }

    final double similarity = expectedWords.isNotEmpty ? matches / expectedWords.length : 0.0;
    final bool speechIsCorrect = similarity >= 0.70;

    final bool isCorrect = wordIsCorrect && speechIsCorrect;

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
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

    if (_isListening && _pullForce < 1.0) {
      Future.delayed(16.ms, () {
        if (mounted && _isListening) {
          setState(() {
            _pullForce = (_pullForce + 0.045).clamp(0.0, 1.0);
            _hapticService.selection();
          });
        }
      });
    }

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
              _pullForce = 0.0;
              _selectedWord = null;
              _isWordPlaced = false;
              _spokenText = "";
              _generateDynamicOptions(state.currentQuest.missingWord ?? "drone");
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
            title: 'VERBAL VORTEX DRIVER!',
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

        // Dynamic formatting of base sentence blanks
        final String rawSentence = quest?.textToSpeak ?? "The robot operates the system safely.";
        final String missingWord = quest?.missingWord ?? "robot";
        
        final String initialBlankSentence = _formatBlankSentence(rawSentence, missingWord);
        final String completedSentence = rawSentence;

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
                      _buildHeaderInstruction(theme.primaryColor),
                      SizedBox(height: 16.h),

                      // Blank telex sentence slate
                      _buildVortexSentence(
                        _isWordPlaced ? completedSentence : initialBlankSentence,
                        _isWordPlaced ? (_selectedWord ?? "") : "",
                        theme.primaryColor,
                        isDark,
                      ),
                      SizedBox(height: 20.h),

                      // Magnet options area
                      if (!_isWordPlaced)
                        _buildMagnetArena(theme.primaryColor, isDark),

                      // Voice telemetry output card
                      if (_isWordPlaced) ...[
                        _buildTelemetryCard(isDark),
                        SizedBox(height: 30.h),
                        
                        if (!_isAnswered)
                          _buildTactileMic(completedSentence, theme.primaryColor),
                      ],

                      // Explanations cards
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: _buildExplanationCard(quest, isDark),
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

  Widget _buildHeaderInstruction(Color primaryColor) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 12.r, color: primaryColor),
              SizedBox(width: 8.w),
              Text(
                _isWordPlaced ? "READ THE COMPLETED SENTENCE" : "PULL CORRECT WORD INTO VORTEX",
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          _isWordPlaced
              ? "Option aligned! Hold the recording lens and speak the full sentence aloud!"
              : "Examine the sentence layout and hold-pull the fitting vocabulary magnetic card!",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildVortexSentence(String text, String insertedWord, Color primaryColor, bool isDark) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 28.h),
      borderRadius: BorderRadius.circular(32.r),
      child: Column(
        children: [
          Text(
            "VOCAL SENTENCE CONSTRUCTOR",
            style: GoogleFonts.shareTechMono(
              fontSize: 10.sp,
              color: primaryColor,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 20.sp,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.45,
            ),
          ),
          if (insertedWord.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
              ),
              child: Text(
                "LOCKED OPTION: ${insertedWord.toUpperCase()}",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMagnetArena(Color primaryColor, bool isDark) {
    final double arenaHeight = 240.h;
    final double radius = 100.w;
    
    final double pullRatio = _pullForce;
    
    // Vortex Center Position relative to the arena Stack
    final Offset localCenter = Offset(0.5.sw - 16.w, arenaHeight / 2);

    return SizedBox(
      height: arenaHeight,
      width: 1.sw,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Spinning cybernetic vortex custom painter background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _vortexController,
              builder: (context, child) {
                // Approximate coordinate mapping for energy beam lines
                Offset? optionOffset;
                if (_selectedWord != null) {
                  final int index = _dynamicOptions.indexOf(_selectedWord!);
                  if (index != -1) {
                    final double angle = (index * 2 * math.pi / _dynamicOptions.length) - math.pi / 2;
                    final double currentDist = radius * (1.0 - pullRatio);
                    optionOffset = localCenter + Offset(math.cos(angle) * currentDist, math.sin(angle) * currentDist);
                  }
                }

                return CustomPaint(
                  painter: VortexPainter(
                    animationTime: _vortexController.value,
                    themeColor: primaryColor,
                    pullCenter: _selectedWord != null ? localCenter : null,
                    optionPos: optionOffset,
                  ),
                );
              },
            ),
          ),

          // 2. Center vortex black hole icon
          Container(
            width: 80.r,
            height: 80.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade900,
              border: Border.all(color: primaryColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Icon(
              Icons.blur_circular_rounded,
              color: Colors.white70,
              size: 40.r,
            ),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 4.seconds),

          // 3. Polar positioned floating options
          ..._dynamicOptions.asMap().entries.map((e) {
            final int index = e.key;
            final String word = e.value;

            final double angle = (index * 2 * math.pi / _dynamicOptions.length) - math.pi / 2;
            final bool isPulled = _selectedWord == word;
            
            final double currentDist = isPulled ? radius * (1.0 - pullRatio) : radius;
            
            final double xOffset = math.cos(angle) * currentDist;
            final double yOffset = math.sin(angle) * currentDist;

            return Transform.translate(
              offset: Offset(xOffset, yOffset),
              child: GestureDetector(
                onLongPressStart: (_) => _onPullStart(word),
                onLongPressEnd: (_) => _onPullEnd(),
                child: ScaleButton(
                  onTap: () {},
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isPulled
                          ? primaryColor.withValues(alpha: 0.25)
                          : (isDark ? const Color(0xFF0F0F1B) : Colors.white),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isPulled ? primaryColor : primaryColor.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      word.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: isPulled ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            ).animate(target: isPulled ? 0.0 : 1.0).scale(begin: const Offset(0.9, 0.9), end: const Offset(1,1));
          }),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(bool isDark) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "VOCAL DECRYPTION OUTPUT",
            style: GoogleFonts.shareTechMono(
              fontSize: 9.sp,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _spokenText.isEmpty ? "Hold record lens and speak full completed sentence..." : _spokenText,
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontStyle: _spokenText.isEmpty ? FontStyle.normal : FontStyle.italic,
              color: _spokenText.isEmpty
                  ? (isDark ? Colors.white30 : Colors.black38)
                  : (isDark ? Colors.white70 : Colors.black87),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTactileMic(String completedSentence, Color primaryColor) {
    return Column(
      children: [
        GestureDetector(
          onLongPressStart: (_) => _startSpeechListening(),
          onLongPressEnd: (_) => _stopSpeechListening(completedSentence),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isSpeechActive)
                ...List.generate(
                  3,
                  (i) => Container(
                    width: 90.r + (i * 24.r),
                    height: 90.r + (i * 24.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                    ),
                  ).animate(onPlay: (c) => c.repeat()).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.3, 1.3),
                        duration: 1.seconds,
                      ).fadeOut(),
                ),
              ScaleButton(
                onTap: () {},
                child: Container(
                  width: 80.r,
                  height: 80.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isSpeechActive
                          ? [primaryColor, primaryColor.withValues(alpha: 0.7)]
                          : [Colors.grey.shade800, Colors.grey.shade900],
                    ),
                    boxShadow: _isSpeechActive
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 18,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    _isSpeechActive ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 32.r,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          _isSpeechActive ? "RELEASE LENS TO PROCESS SENTENCE" : "HOLD LENS TO RECORD FULL COMPLETED SENTENCE",
          textAlign: TextAlign.center,
          style: GoogleFonts.shareTechMono(
            fontSize: 9.sp,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationCard(GameQuest quest, bool isDark) {
    final Color cardColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.orangeAccent;

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
                (_isCorrect ?? false) ? "Alignment Successful!" : "Alignment Failure!",
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
            quest.explanation ?? "Correlating target blank options with spoken phrase structures reinforces robust memory synapses.",
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
}
