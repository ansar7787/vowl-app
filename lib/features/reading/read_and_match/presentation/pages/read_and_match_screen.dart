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
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/read_and_match/presentation/widgets/read_and_match_instruction.dart';
import 'package:vowl/features/reading/read_and_match/presentation/widgets/read_and_match_terminal.dart';
import 'package:vowl/features/reading/read_and_match/presentation/widgets/laser_bridge_painter.dart';
import 'package:vowl/features/reading/read_and_match/presentation/widgets/read_and_match_result.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

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

  final ValueNotifier<String?> _activeKey = ValueNotifier(null);
  final ValueNotifier<Map<String, String>> _matches = ValueNotifier({});
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;
  final ValueNotifier<bool> _pendingSubmission = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _activeKey.dispose();
    _matches.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _pendingSubmission.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  final List<Color> _matchColors = [
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.tealAccent,
    Colors.pinkAccent,
    Colors.cyanAccent,
    Colors.amberAccent,
    Colors.lightGreenAccent,
    Colors.indigoAccent,
  ];

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
    if (_isAnswered.value) return;
    _hapticService.selection();
    final Map<String, String> currentMatches = Map.from(_matches.value);
    if (currentMatches.containsKey(key)) {
      currentMatches.remove(key);
    }
    _matches.value = currentMatches;
    _activeKey.value = key;
  }

  void _onValueTap(String value, List<Map<String, String>> pairs) {
    if (_isAnswered.value || _activeKey.value == null) return;

    _hapticService.success();
    final Map<String, String> currentMatches = Map.from(_matches.value);
    currentMatches.removeWhere((k, v) => v == value);
    currentMatches[_activeKey.value!] = value;
    _matches.value = currentMatches;
    _activeKey.value = null;

    if (_matches.value.length == pairs.length) {
      _pendingSubmission.value = true;
    }
  }

  void _submitFinalAnswer(
    bool nailedSpeaking,
    List<Map<String, String>> pairs,
  ) {
    _pendingSubmission.value = false;

    if (!nailedSpeaking) {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _matches.value = {};
          _isAnswered.value = false;
          _isCorrect.value = null;
        }
      });
      return;
    }

    _submitAnswer(pairs);
  }

  void _submitAnswer(List<Map<String, String>> pairs) {
    bool isCorrect = true;
    for (var pair in pairs) {
      if (_matches.value[pair['key']] != pair['value']) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _isAnswered.value = true;
      _isCorrect.value = true;
      context.read<ReadingBloc>().add(const ReadingSpeakConfirmed(5));
      context.read<ReadingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _matches.value = {};
          _isAnswered.value = false;
          _isCorrect.value = null;
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
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _matches.value = {};
            _activeKey.value = null;
            _pendingSubmission.value = false;
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr('reading_games.relationship_master', fallback: 'RELATIONSHIP MASTER!'),
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
        
        final Map<String, Color> colorMap = {};
        for (int i = 0; i < pairs.length; i++) {
          colorMap[pairs[i]['key']!] = _matchColors[i % _matchColors.length];
        }

        Color getColorForKey(String k) {
          return colorMap[k] ?? theme.primaryColor;
        }

        Color getColorForValue(String v) {
          // If matched, use the key's color. Otherwise primary
          if (_matches.value.containsValue(v)) {
            final key = _matches.value.entries.firstWhere((e) => e.value == v).key;
            return colorMap[key] ?? theme.primaryColor;
          }
          return theme.primaryColor;
        }

        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _matches, _activeKey, _pendingSubmission]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
          onContinue: () =>
              context.read<ReadingBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<ReadingBloc>().add(const ReadingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    LayoutBuilder(
                  builder: (context, constraints) {
                    return RawScrollbar(
                      controller: _scrollController,
                      thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                      radius: Radius.circular(8.r),
                      thickness: 4.w,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            sliver: SliverToBoxAdapter(
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
                                                        color: getColorForKey(k),
                                                        isDark: isDark,
                                                        isMatched: _matches.value
                                                            .containsKey(k),
                                                        isActive: _activeKey.value == k,
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
                                                        color: getColorForValue(v),
                                                        isDark: isDark,
                                                        isMatched: _matches.value
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
                                              matches: _matches.value,
                                              activeKey: _activeKey.value,
                                              getCenter: _getCenterOf,
                                              getKey: _getKeyFor,
                                              color: theme.primaryColor,
                                              colorMap: colorMap,
                                            ),
                                            size: Size.infinite,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: (_pendingSubmission.value && !_isAnswered.value) ? 380.h : 60.h),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (_pendingSubmission.value && !_isAnswered.value)
                  SpeakToConfirmOverlay(
                    expectedText:
                        quest.textToSpeak ??
                        quest.correctAnswer ??
                        "Confirm",
                    primaryColor: theme.primaryColor,
                    onConfirmed: () => _submitFinalAnswer(true, pairs),
                    onSkipped: () => _submitFinalAnswer(false, pairs),
                    allowSkip: true,
                    isPositioned: true,
                  ),
                if (_isAnswered.value)
                  Positioned(
                    bottom: 50.h,
                    left: 20.w,
                    right: 20.w,
                    child: ReadAndMatchResult(
                      quest: quest,
                      isCorrect: _isCorrect.value == true,
                      isDark: isDark,
                    ),
                  ),
              ],
            ),
          );
          },
        );
      },
    );
  }
}
