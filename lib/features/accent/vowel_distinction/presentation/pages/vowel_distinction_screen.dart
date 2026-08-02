import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_instruction.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_prompt_card.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_pulse_speaker.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_spectral_slider.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class VowelDistinctionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const VowelDistinctionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.vowelDistinction,
  });

  @override
  State<VowelDistinctionScreen> createState() => _VowelDistinctionScreenState();
}

class _VowelDistinctionScreenState extends State<VowelDistinctionScreen> {
  final ScrollController _scrollController = ScrollController();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  double _sliderValue = 0.5;
  int? _selectedIndex;

  final _audioRecorder = di.sl<AudioRecordingService>();
  bool _phase1Passed = false;
  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isPlaying = false;
  String? _recordingPath;

  Timer? _mismatchResetTimer;
  Timer? _autoplayTimer;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    if (_isRecording) {
      _audioRecorder.stopRecording();
    }
    _mismatchResetTimer?.cancel();
    _autoplayTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
  }

  Future<void> _startRecording() async {
    if (_isAnswered || _isPlaying) return;
    
    final hasPermission = await _audioRecorder.hasPermission();
    if (hasPermission) {
      _hapticService.selection();
      final started = await _audioRecorder.startRecording();
      if (started && mounted) {
        setState(() {
          _isRecording = true;
          _hasRecorded = false;
          _recordingPath = null;
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    _hapticService.selection();
    final path = await _audioRecorder.stopRecording();
    
    if (mounted) {
      setState(() {
        _isRecording = false;
        if (path != null) {
          _recordingPath = path;
          _hasRecorded = true;
        }
      });
      if (_hasRecorded) {
        _playComparison();
      }
    }
  }

  Future<void> _playComparison() async {
    // Assuming the quest context provides the textToSpeak via state
    final state = context.read<AccentBloc>().state;
    AccentQuest? quest;
    if (state is AccentLoaded) quest = state.currentQuest as AccentQuest?;
    
    if (_isPlaying || _recordingPath == null || quest?.textToSpeak == null) return;
    
    setState(() => _isPlaying = true);
    
    // Play Native
    await _soundService.playTts(quest!.textToSpeak!);
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // Play User
    if (mounted) {
      await _soundService.playFile(_recordingPath!);
      await Future.delayed(const Duration(milliseconds: 1200));
    }
    
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  void _submitPhase2Evaluation(bool nailedIt) {
    if (_isAnswered) return;
    
    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      _scrollToBottom();
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _scrollToBottom();
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  void _onSliderUpdate(double value, int correct) {
    if (_isAnswered || _phase1Passed) return;
    setState(() => _sliderValue = value);

    // Auto-lock when reaching ends
    if (value < 0.1) {
      _submitChoice(0, correct);
    } else if (value > 0.9) {
      _submitChoice(1, correct);
    }
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered || _phase1Passed) return;
    setState(() {
      _selectedIndex = index;
      _sliderValue = index == 0 ? 0.0 : 1.0;
    });

    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _phase1Passed = true;
      });
      _scrollToBottom();
      // Do NOT submit yet. Wait for Phase 2.
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      _scrollToBottom();
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
          final livesChanged = _lastLives != null && state.livesRemaining > _lastLives!;
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _sliderValue = 0.5;
              _selectedIndex = null;
              _phase1Passed = false;
              _isRecording = false;
              _hasRecorded = false;
              _isPlaying = false;
              _recordingPath = null;
            });
            // Proactively auto-play sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null && quest.textToSpeak != null) {
              _autoplayTimer?.cancel();
              _autoplayTimer = Timer(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _soundService.playTts(quest.textToSpeak!);
                }
              });
            }
          }
          _lastLives = state.livesRemaining;
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'PHONEME PRO!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : null;
        final options = quest?.options ?? ["A", "B"];
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: AccentBaseLayout(
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,
            onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
            onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
            child: quest == null
                ? const SizedBox()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = constraints.maxHeight;
                      final maxWidth = constraints.maxWidth;
                      final bool isCompact = maxHeight < 580;

                      final double estimatedContentHeight =
                          24.h +
                          (isCompact ? 90.h : 120.h) +
                          100.h +
                          (isCompact ? 130.h : 172.h) +
                          (_isAnswered ? 180.h : 0);
                      final remainingHeight =
                          maxHeight - estimatedContentHeight;

                      final double gapUnit = remainingHeight > 0
                          ? remainingHeight / 8
                          : 0;
                      final double gapTop = remainingHeight > 0
                          ? (gapUnit * 1).clamp(8.0, 24.0)
                          : 8.0;
                      final double gapInstruction = remainingHeight > 0
                          ? (gapUnit * 1).clamp(8.0, 24.0)
                          : 8.0;
                      final double gapPrompt = remainingHeight > 0
                          ? (gapUnit * 1.5).clamp(12.0, 32.0)
                          : 12.0;
                      final double gapSpeaker = remainingHeight > 0
                          ? (gapUnit * 2).clamp(16.0, 48.0)
                          : 16.0;
                      
                      final double gapBottom = remainingHeight > 0
                          ? (gapUnit * 1).clamp(12.0, 40.0)
                          : 12.0;

                      return SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: maxHeight),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapTop),
                                    isCompact
                                        ? SizedBox(
                                            height: 32.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width: maxWidth - 48.w,
                                                child:
                                                    VowelDistinctionInstruction(
                                                      color: theme.primaryColor,
                                                      instruction: _phase1Passed 
                                                        ? "Great job! Now record yourself saying the word."
                                                        : context.tr('games.vowel_distinction_instruction', fallback: 'Match the vowel sound'),
                                                    ),
                                              ),
                                            ),
                                          )
                                        : VowelDistinctionInstruction(
                                            color: theme.primaryColor,
                                            instruction: _phase1Passed 
                                              ? "Great job! Now record yourself saying the word."
                                              : context.tr('games.vowel_distinction_instruction', fallback: 'Match the vowel sound'),
                                          ),
                                    SizedBox(height: gapInstruction),

                                    isCompact
                                        ? SizedBox(
                                            height: 90.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width: maxWidth - 48.w,
                                                child:
                                                    VowelDistinctionPromptCard(
                                                      word: quest.word ?? "",
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                    ),
                                              ),
                                            ),
                                          )
                                        : VowelDistinctionPromptCard(
                                            word: quest.word ?? "",
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                          ),
                                    SizedBox(height: gapPrompt),

                                    VowelDistinctionPulseSpeaker(
                                      text: quest.textToSpeak ?? "",
                                      color: theme.primaryColor,
                                      onPlayTts: _playTts,
                                    ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapSpeaker),
                                    isCompact
                                        ? SizedBox(
                                            height: 110.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width: maxWidth - 48.w,
                                                child: VowelDistinctionSpectralSlider(
                                                  options: options,
                                                  correctIndex:
                                                      quest
                                                          .correctAnswerIndex ??
                                                      0,
                                                  color: theme.primaryColor,
                                                  isDark: isDark,
                                                  isAnswered: _isAnswered || _phase1Passed,
                                                  selectedIndex: _selectedIndex,
                                                  sliderValue: _sliderValue,
                                                  onSubmitChoice: _submitChoice,
                                                  onSliderUpdate:
                                                      _onSliderUpdate,
                                                ),
                                              ),
                                            ),
                                          )
                                        : VowelDistinctionSpectralSlider(
                                            options: options,
                                            correctIndex:
                                                quest.correctAnswerIndex ?? 0,
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            isAnswered: _isAnswered || _phase1Passed,
                                            selectedIndex: _selectedIndex,
                                            sliderValue: _sliderValue,
                                            onSubmitChoice: _submitChoice,
                                            onSliderUpdate: _onSliderUpdate,
                                          ),
                                    SizedBox(height: gapBottom),
                                    if (_phase1Passed)
                                      _buildPhase2Panel(theme.primaryColor, isCompact),
                                    SizedBox(height: _isAnswered ? 180.h : 0),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildPhase2Panel(Color primaryColor, bool isCompact) {
    return Column(
      children: [
        Divider(color: primaryColor.withValues(alpha: 0.2), thickness: 2),
        SizedBox(height: 8.h),
        Text(
          "PHASE 2: SPEAKING",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: primaryColor,
          ),
        ),
        SizedBox(height: 16.h),
        if (!_hasRecorded) ...[
          GestureDetector(
            onTap: () {
              if (_isRecording) {
                _stopRecording();
              } else {
                _startRecording();
              }
            },
            child: Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : primaryColor).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: _isRecording ? 8 : 0,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 40.r,
              ),
            ).animate(target: _isRecording ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
          ),
          SizedBox(height: 10.h),
          Text(
            _isRecording ? "Listening... Tap to stop" : "Tap to Record",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: _isRecording ? Colors.red : Colors.grey[600],
            ),
          ).animate(target: _isRecording ? 1 : 0).fade(),
        ] else if (_isPlaying) ...[
          const CircularProgressIndicator(),
          SizedBox(height: 10.h),
          Text(
            "Playing comparison...",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEvalButton(
                title: "Needs Work",
                icon: LucideIcons.x,
                color: Colors.red,
                onTap: () => _submitPhase2Evaluation(false),
              ),
              GestureDetector(
                onTap: _playComparison,
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withValues(alpha: 0.1),
                  ),
                  child: Icon(LucideIcons.play, color: primaryColor, size: 24.sp),
                ),
              ),
              _buildEvalButton(
                title: "Nailed It",
                icon: LucideIcons.check,
                color: Colors.green,
                onTap: () => _submitPhase2Evaluation(true),
              ),
            ],
          ),
          if (!isCompact) ...[
            SizedBox(height: 10.h),
            Text(
              "Be honest! Did you match the native speaker?",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ],
    ).animate().slideY(begin: 0.2).fadeIn();
  }

  Widget _buildEvalButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}




