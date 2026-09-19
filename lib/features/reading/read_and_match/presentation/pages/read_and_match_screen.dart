import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/mixins/reading_game_screen_mixin.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/read_and_match/presentation/widgets/read_and_match_instruction.dart';
import 'package:vowl/features/reading/read_and_match/presentation/widgets/read_and_match_terminal.dart';
import 'package:vowl/features/reading/read_and_match/presentation/widgets/laser_bridge_painter.dart';
import 'package:vowl/features/reading/read_and_match/presentation/widgets/read_and_match_result.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

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

class _ReadAndMatchScreenState extends State<ReadAndMatchScreen>
    with ReadingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final GlobalKey _canvasKey = GlobalKey();
  final Map<String, GlobalKey> _terminalKeys = {};

  final ValueNotifier<String?> _activeKey = ValueNotifier(null);
  final ValueNotifier<Map<String, String>> _matches = ValueNotifier({});
  final ValueNotifier<bool> _pendingSubmission = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _activeKey.dispose();
    _matches.dispose();
    _pendingSubmission.dispose();
    _scrollController.dispose();
    disposeReadingGame();
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
    isAnsweredNotifier.addListener(() {
      if (isAnsweredNotifier.value && mounted && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    initReadingGame();
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
    if (isAnsweredNotifier.value) return;
    hapticService.selection();
    final Map<String, String> currentMatches = Map.from(_matches.value);
    if (currentMatches.containsKey(key)) {
      currentMatches.remove(key);
    }
    _matches.value = currentMatches;
    _activeKey.value = key;
  }

  void _onValueTap(String value, List<Map<String, String>> pairs) {
    if (isAnsweredNotifier.value || _activeKey.value == null) return;

    hapticService.success();
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
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _matches.value = {};
          isAnsweredNotifier.value = false;
          isCorrectNotifier.value = null;
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
      hapticService.success();
      soundService.playCorrect();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = true;
      context.read<ReadingBloc>().add(const ReadingSpeakConfirmed(5));
      context.read<ReadingBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _matches.value = {};
          isAnsweredNotifier.value = false;
          isCorrectNotifier.value = null;
        }
      });
    }
  }

  @override
  void onQuestionReset() {
    _activeKey.value = null;

    _matches.value = {};

    _pendingSubmission.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ReadingBloc, ReadingState>(
      listenWhen: readingListenWhen,
      listener: onReadingStateChanged,
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
            final key = _matches.value.entries
                .firstWhere((e) => e.value == v)
                .key;
            return colorMap[key] ?? theme.primaryColor;
          }
          return theme.primaryColor;
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _matches,
            _activeKey,
            _pendingSubmission,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () =>
                  context.read<ReadingBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<ReadingBloc>().add(const ReadingHintUsed()),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : Stack(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return RawScrollbar(
                              controller: _scrollController,
                              thumbColor: theme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverPadding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                    ),
                                    sliver: SliverToBoxAdapter(
                                      child: Column(
                                        children: [
                                          SizedBox(height: 16.h),
                                          ReadAndMatchInstruction(
                                            primaryColor: theme.primaryColor,
                                            instruction:
                                                InstructionHelper.getInstruction(
                                                  quest,
                                                ),
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
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: keys
                                                            .map(
                                                              (
                                                                k,
                                                              ) => ReadAndMatchTerminal(
                                                                text: k,
                                                                isSource: true,
                                                                color:
                                                                    getColorForKey(
                                                                      k,
                                                                    ),
                                                                isDark: isDark,
                                                                isMatched: _matches
                                                                    .value
                                                                    .containsKey(
                                                                      k,
                                                                    ),
                                                                isActive:
                                                                    _activeKey
                                                                        .value ==
                                                                    k,
                                                                onTap: () =>
                                                                    _onKeyTap(
                                                                      k,
                                                                    ),
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
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: values
                                                            .map(
                                                              (
                                                                v,
                                                              ) => ReadAndMatchTerminal(
                                                                text: v,
                                                                isSource: false,
                                                                color:
                                                                    getColorForValue(
                                                                      v,
                                                                    ),
                                                                isDark: isDark,
                                                                isMatched: _matches
                                                                    .value
                                                                    .containsValue(
                                                                      v,
                                                                    ),
                                                                isActive: false,
                                                                onTap: () =>
                                                                    _onValueTap(
                                                                      v,
                                                                      pairs,
                                                                    ),
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
                                                      activeKey:
                                                          _activeKey.value,
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
                                    child: SizedBox(
                                      height:
                                          (_pendingSubmission.value &&
                                              !isAnsweredNotifier.value)
                                          ? 380.h
                                          : 60.h,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (_pendingSubmission.value &&
                            !isAnsweredNotifier.value)
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
                        if (isAnsweredNotifier.value)
                          Positioned(
                            bottom: 50.h,
                            left: 20.w,
                            right: 20.w,
                            child: ReadAndMatchResult(
                              quest: quest,
                              isCorrect: isCorrectNotifier.value == true,
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
