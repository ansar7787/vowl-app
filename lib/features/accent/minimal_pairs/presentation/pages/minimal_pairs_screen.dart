import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vowl/core/utils/injection_container.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';

import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_base_layout.dart';
import 'package:vowl/features/accent/presentation/constants/accent_game_constants.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_instruction.dart';
import 'package:vowl/features/elite_mastery/accent_shadowing/presentation/widgets/accent_shadowing_mic_trigger.dart';

class MinimalPairsScreen extends StatefulWidget {
  final String gameType;
  final int level;

  const MinimalPairsScreen({
    super.key,
    required this.gameType,
    required this.level,
  });

  @override
  State<MinimalPairsScreen> createState() => _MinimalPairsScreenState();
}

class _MinimalPairsScreenState extends State<MinimalPairsScreen> {
  final _audioRecorder = sl<AudioRecordingService>();
  final _soundService = sl<SoundService>();
  final _hapticService = sl<HapticService>();

  AccentQuest? _lastQuest;
  int _lastProcessedIndex = -1;
  int _lastLives = 3;

  bool _isAnswered = false;
  bool? _isCorrect;

  List<Map<String, String>> _currentOptions = [];
  int _currentCorrectIndex = 0;

  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isPlaying = false;
  String? _recordingPath;

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
    super.dispose();
  }

  void _initializeOptions(AccentQuest quest) {
    if (quest.options == null || quest.options!.isEmpty) return;

    final List<Map<String, String>> originalOptions = [];
    if (quest.word1 != null) {
      originalOptions.add({'word': quest.word1!, 'ipa': quest.ipa1 ?? ''});
    }
    if (quest.word2 != null) {
      originalOptions.add({'word': quest.word2!, 'ipa': quest.ipa2 ?? ''});
    }

    final correctAnswerStr = quest.correctAnswer;
    _currentOptions = List.from(originalOptions)..shuffle();
    if (correctAnswerStr != null) {
        _currentCorrectIndex = _currentOptions.indexWhere((opt) => opt['word'] == correctAnswerStr);
    } else {
        _currentCorrectIndex = _currentOptions.indexWhere((opt) => opt['word'] == originalOptions[quest.correctAnswerIndex ?? 0]['word']);
    }
    if (_currentCorrectIndex == -1) _currentCorrectIndex = 0;
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
    if (_isPlaying || _recordingPath == null || _lastQuest?.textToSpeak == null) return;
    
    setState(() => _isPlaying = true);
    
    // Play Native
    await _soundService.playTts(_lastQuest!.textToSpeak!);
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

  void _submitEvaluation(bool nailedIt) {
    if (_isAnswered) return;
    
    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          _lastQuest = state.currentQuest as AccentQuest?;
          final livesChanged = (state.livesRemaining < _lastLives);
          _lastLives = state.livesRemaining;

          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isRecording = false;
              _hasRecorded = false;
              _isPlaying = false;
              _recordingPath = null;
            });
            if (_lastQuest != null) {
              _initializeOptions(_lastQuest!);
              if (_lastQuest!.textToSpeak != null) {
                Future.delayed(500.milliseconds, () {
                  if (mounted) {
                    _soundService.playTts(_lastQuest!.textToSpeak!);
                  }
                });
              }
            }
          }
        }
      },
      builder: (context, state) {
        if (state is AccentLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (state is AccentLoaded) {
          final quest = state.currentQuest as AccentQuest;
          final targetWord = _currentOptions[_currentCorrectIndex]['word'] ?? '';
          final targetIpa = _currentOptions[_currentCorrectIndex]['ipa'] ?? '';

          return AccentBaseLayout(
            gameType: widget.gameType,
            level: widget.level,
            state: state,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            quest: quest,
            onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
            child: Column(
              children: [
                SizedBox(height: 20.h),
                MinimalPairsInstruction(
                  instruction: "Listen to the native speaker, then hold the mic to record your own pronunciation of the target word.",
                ),
                SizedBox(height: 40.h),
                
                // Target Word Display
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Target Word",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        targetWord,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 48.sp,
                          fontWeight: FontWeight.w800,
                          color: theme.primaryColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (targetIpa.isNotEmpty) ...[
                        SizedBox(height: 5.h),
                        Text(
                          targetIpa,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w500,
                            color: theme.primaryColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),

                SizedBox(height: 40.h),

                // Interaction Area
                if (!_hasRecorded) ...[
                  GestureDetector(
                    onTapDown: (_) => _startRecording(),
                    onTapUp: (_) => _stopRecording(),
                    onTapCancel: () => _stopRecording(),
                    child: AccentShadowingMicTrigger(
                      isListening: _isRecording,
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Text(
                    _isRecording ? "Listening... Release to stop" : "Hold to Record",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: _isRecording ? AccentGameColors.wrongRed : Colors.grey[600],
                    ),
                  ).animate(target: _isRecording ? 1 : 0).fade(),
                ] else ...[
                  // Playback and Self-Evaluation UI
                  if (_isPlaying) ...[
                    const CircularProgressIndicator(),
                    SizedBox(height: 15.h),
                    Text(
                      "Playing comparison...",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildEvalButton(
                          title: "Needs Work",
                          icon: LucideIcons.x,
                          color: AccentGameColors.wrongRed,
                          onTap: () => _submitEvaluation(false),
                        ),
                        GestureDetector(
                          onTap: _playComparison,
                          child: Container(
                            padding: EdgeInsets.all(15.r),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primaryColor.withValues(alpha: 0.1),
                            ),
                            child: Icon(LucideIcons.play, color: theme.primaryColor, size: 28.sp),
                          ),
                        ),
                        _buildEvalButton(
                          title: "Nailed It",
                          icon: LucideIcons.check,
                          color: AccentGameColors.correctGreen,
                          onTap: () => _submitEvaluation(true),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                    SizedBox(height: 15.h),
                    Text(
                      "Be honest! Did you match the native speaker?",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ]
                ],
                const Spacer(),
              ],
            ),
          );
        } else if (state is AccentError) {
          return Scaffold(body: Center(child: Text(state.message)));
        }
        return const SizedBox.shrink();
      },
    );
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
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.sp),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
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
