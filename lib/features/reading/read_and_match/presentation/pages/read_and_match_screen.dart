import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/read_and_match/presentation/widgets/read_and_match_instruction.dart';
import 'package:vowl/features/reading/read_and_match/presentation/widgets/read_and_match_terminal.dart';
import 'package:vowl/features/reading/read_and_match/presentation/widgets/laser_bridge_painter.dart';
import 'package:vowl/features/reading/read_and_match/presentation/widgets/read_and_match_result.dart';
import 'package:vowl/core/presentation/widgets/speak_to_confirm_overlay.dart';

class ReadAndMatchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ReadAndMatchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.readAndMatch,
  });

  @override
  State<ReadAndMatchScreen> createState() => _ReadAndMatchScreenState();
}

class _ReadAndMatchScreenState extends State<ReadAndMatchScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final GlobalKey _canvasKey = GlobalKey();
  final Map<String, GlobalKey> _terminalKeys = {};

  String? _activeKey;
  final Map<String, String> _matches = {};
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _pendingSubmission = false;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  GlobalKey _getKeyFor(String text) {
    return _terminalKeys.putIfAbsent(text, () => GlobalKey());
  }

  Offset? _getCenterOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final parentBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || parentBox == null) return null;

    final localPos = parentBox.globalToLocal(box.localToGlobal(Offset.zero));
    return Offset(
      localPos.dx + box.size.width / 2,
      localPos.dy + box.size.height / 2,
    );
  }

  void _onKeyTap(String key) {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      if (_matches.containsKey(key)) {
        _matches.remove(key);
      }
      _activeKey = key;
    });
  }

  void _onValueTap(String value, List<Map<String, String>> pairs) {
    if (_isAnswered || _activeKey == null) return;

    _hapticService.success();
    setState(() {
      // Remove any existing match containing this value
      _matches.removeWhere((k, v) => v == value);

      _matches[_activeKey!] = value;
      _activeKey = null;
    });

    if (_matches.length == pairs.length) {
      setState(() {
        _pendingSubmission = true;
      });
    }
  }

  void _submitFinalAnswer(
    bool nailedSpeaking,
    List<Map<String, String>> pairs,
  ) {
    setState(() {
      _pendingSubmission = false;
    });

    if (!nailedSpeaking) {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _matches.clear();
            _isAnswered = false;
            _isCorrect = null;
          });
        }
      });
      return;
    }

    _submitAnswer(pairs);
  }

  void _submitAnswer(List<Map<String, String>> pairs) {
    bool isCorrect = true;
    for (var pair in pairs) {
      if (_matches[pair['key']] != pair['value']) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<ReadingBloc>().add(const ReadingSpeakConfirmed(5));
      context.read<ReadingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _matches.clear();
            _isAnswered = false;
            _isCorrect = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _matches.clear();
              _activeKey = null;
              _pendingSubmission = false;
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'RELATIONSHIP MASTER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;
        final pairs = quest?.pairs ?? [];

        // Shuffle lists but keep state-consistent orders if needed
        final keys = pairs.map((p) => p['key']!).toList();
        final values = pairs.map((p) => p['value']!).toList();

        return ReadingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () =>
              context.read<ReadingBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<ReadingBloc>().add(const ReadingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          children: [
                            SizedBox(height: 16.h),
                            ReadAndMatchInstruction(
                              primaryColor: theme.primaryColor,
                              instruction: quest.instruction,
                            ),
                            SizedBox(height: 32.h),

                            // Interactive Canvas Stack
                            SizedBox(
                              key: _canvasKey,
                              height: 420.h,
                              child: Stack(
                                children: [
                                  Row(
                                    children: [
                                      // Left Keys Column
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: keys
                                              .map(
                                                (k) => ReadAndMatchTerminal(
                                                  text: k,
                                                  isSource: true,
                                                  color: theme.primaryColor,
                                                  isDark: isDark,
                                                  isMatched: _matches
                                                      .containsKey(k),
                                                  isActive: _activeKey == k,
                                                  onTap: () => _onKeyTap(k),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                      SizedBox(width: 40.w),
                                      // Right Values Column
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: values
                                              .map(
                                                (v) => ReadAndMatchTerminal(
                                                  text: v,
                                                  isSource: false,
                                                  color: theme.primaryColor,
                                                  isDark: isDark,
                                                  isMatched: _matches
                                                      .containsValue(v),
                                                  isActive: false,
                                                  onTap: () =>
                                                      _onValueTap(v, pairs),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Render Glowing Lasers dynamically using key positions!
                                  IgnorePointer(
                                    child: CustomPaint(
                                      painter: LaserBridgePainter(
                                        matches: _matches,
                                        activeKey: _activeKey,
                                        getCenter: _getCenterOf,
                                        getKey: _getKeyFor,
                                        color: theme.primaryColor,
                                      ),
                                      size: Size.infinite,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (_isAnswered) ...[
                              SizedBox(height: 30.h),
                              ReadAndMatchResult(
                                quest: quest,
                                isCorrect: _isCorrect == true,
                                isDark: isDark,
                              ),
                            ],
                            SizedBox(height: 50.h),
                          ],
                        ),
                      ),
                    ),
                    if (_pendingSubmission && !_isAnswered)
                      SpeakToConfirmOverlay(
                        expectedText:
                            quest.textToSpeak ??
                            quest.correctAnswer ??
                            "Confirm",
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true, pairs),
                        onSkipped: () => _submitFinalAnswer(false, pairs),
                        allowSkip: true,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
