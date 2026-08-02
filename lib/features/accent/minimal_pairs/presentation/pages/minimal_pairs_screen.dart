import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_instruction.dart';
// Removed unused MinimalPairsPromptCard import
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_speaker_core.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_drone_option.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/features/accent/presentation/constants/accent_game_constants.dart';

class MinimalPairsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const MinimalPairsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.minimalPairs,
  });

  @override
  State<MinimalPairsScreen> createState() => _MinimalPairsScreenState();
}

class _MinimalPairsScreenState extends State<MinimalPairsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int _lastLives = AccentGameConstants.maxLives;
  AccentQuest? _lastQuest;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int? _selectedDroneIndex;
  
  final _audioRecorder = di.sl<AudioRecordingService>();

  bool _phase1Passed = false;
  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isPlaying = false;
  String? _recordingPath;

  String? _shuffledQuestId;
  List<Map<String, String>> _currentOptions = [];
  int _currentCorrectIndex = 0;

  void _ensureOptionsShuffled(AccentQuest quest) {
    if (_shuffledQuestId == quest.id) return;
    
    _shuffledQuestId = quest.id;
    
    final originalOptions = [
      {'word': quest.word1 ?? '', 'ipa': quest.ipa1 ?? ''},
      {'word': quest.word2 ?? '', 'ipa': quest.ipa2 ?? ''},
    ];
    
    final correctAnswerStr = quest.correctAnswer;
        
    _currentOptions = List.from(originalOptions)..shuffle();
    if (correctAnswerStr != null) {
        _currentCorrectIndex = _currentOptions.indexWhere((opt) => opt['word'] == correctAnswerStr);
    } else {
        _currentCorrectIndex = _currentOptions.indexWhere((opt) => opt['word'] == originalOptions[quest.correctAnswerIndex ?? 0]['word']);
    }
    if (_currentCorrectIndex == -1) _currentCorrectIndex = 0;
  }

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

  void _submitPhase2Evaluation(bool nailedIt) {
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

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
  }

  void _onShoot(int index, int correctIndex) {
    if (_isAnswered || _phase1Passed) return;

    final bool correct = index == correctIndex;
    setState(() {
      _selectedDroneIndex = index;
    });

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _phase1Passed = true;
      });
      // Do NOT submit yet! Wait for Phase 2.
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
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
          _lastQuest = state.currentQuest as AccentQuest?;
          final livesChanged = (state.livesRemaining > _lastLives);
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedDroneIndex = null;
              _phase1Passed = false;
              _isRecording = false;
              _hasRecorded = false;
              _isPlaying = false;
              _recordingPath = null;
            });
            // Proactively auto-play phonetic sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null && quest.textToSpeak != null) {
              Future.delayed(500.milliseconds, () {
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
            title: 'PHONETIC EXPERT!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : _lastQuest;
            
        if (quest != null && !_isAnswered) {
          _ensureOptionsShuffled(quest);
        }
        
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
                          (_isAnswered ? (isCompact ? 110.h : 160.h) : 0);
                      final remainingHeight =
                          maxHeight - estimatedContentHeight;

                      final double gapUnit = remainingHeight > 0
                          ? remainingHeight / 8
                          : 0;
                      final double gapTop = remainingHeight > 0
                          ? (gapUnit * 1).clamp(8.0, 24.0)
                          : 8.0;

                      final double gapSpeaker = remainingHeight > 0
                          ? (gapUnit * 2).clamp(16.0, 48.0)
                          : 16.0;

                      final double gapBottom = remainingHeight > 0
                          ? (gapUnit * 1).clamp(12.0, 40.0)
                          : 12.0;

                      return SingleChildScrollView(
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
                                    MinimalPairsInstruction(
                                      color: theme.primaryColor,
                                      instruction: _phase1Passed 
                                        ? "Great job! Now record yourself saying the word to evaluate your accent."
                                        : context.tr('games.minimal_pairs_instruction', fallback: quest.instruction),
                                    ),
                                  ],
                                ),
                                MinimalPairsSpeakerCore(
                                  text: quest.textToSpeak ?? "",
                                  color: theme.primaryColor,
                                  onPlayTts: _playTts,
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
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    MinimalPairsDroneOption(
                                                      index: 0,
                                                      word: _currentOptions.isNotEmpty ? _currentOptions[0]['word']! : quest.word1 ?? "",
                                                      ipa: _currentOptions.isNotEmpty ? _currentOptions[0]['ipa']! : quest.ipa1 ?? "",
                                                      correctIndex: _currentOptions.isNotEmpty ? _currentCorrectIndex : quest.correctAnswerIndex ?? 0,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      isAnswered: _isAnswered,
                                                      selectedDroneIndex:
                                                          _selectedDroneIndex,
                                                      onShoot: _onShoot,
                                                    ),
                                                    MinimalPairsDroneOption(
                                                      index: 1,
                                                      word: _currentOptions.isNotEmpty ? _currentOptions[1]['word']! : quest.word2 ?? "",
                                                      ipa: _currentOptions.isNotEmpty ? _currentOptions[1]['ipa']! : quest.ipa2 ?? "",
                                                      correctIndex: _currentOptions.isNotEmpty ? _currentCorrectIndex : quest.correctAnswerIndex ?? 0,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                isAnswered: _isAnswered || _phase1Passed,
                                                      selectedDroneIndex:
                                                          _selectedDroneIndex,
                                                      onShoot: _onShoot,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              MinimalPairsDroneOption(
                                                index: 0,
                                                word: _currentOptions.isNotEmpty ? _currentOptions[0]['word']! : quest.word1 ?? "",
                                                ipa: _currentOptions.isNotEmpty ? _currentOptions[0]['ipa']! : quest.ipa1 ?? "",
                                                correctIndex: _currentOptions.isNotEmpty ? _currentCorrectIndex : quest.correctAnswerIndex ?? 0,
                                                color: theme.primaryColor,
                                                isDark: isDark,
                                                isAnswered: _isAnswered,
                                                selectedDroneIndex:
                                                    _selectedDroneIndex,
                                                onShoot: _onShoot,
                                              ),
                                              MinimalPairsDroneOption(
                                                index: 1,
                                                word: _currentOptions.isNotEmpty ? _currentOptions[1]['word']! : quest.word2 ?? "",
                                                ipa: _currentOptions.isNotEmpty ? _currentOptions[1]['ipa']! : quest.ipa2 ?? "",
                                                correctIndex: _currentOptions.isNotEmpty ? _currentCorrectIndex : quest.correctAnswerIndex ?? 0,
                                                color: theme.primaryColor,
                                                isDark: isDark,
                                                isAnswered: _isAnswered || _phase1Passed,
                                                selectedDroneIndex:
                                                    _selectedDroneIndex,
                                                onShoot: _onShoot,
                                              ),
                                            ],
                                          ),
                                          
                                    SizedBox(height: isCompact ? 16.h : 24.h),
                                    if (_phase1Passed)
                                      _buildPhase2Panel(theme.primaryColor, isCompact),
                                    SizedBox(height: gapBottom),
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
