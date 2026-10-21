import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
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
    with
        TickerProviderStateMixin,
        GameScreenMixin<ReadAndMatchScreen>,
        ReadingGameScreenMixin<ReadAndMatchScreen> {
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
  final ScrollController _scrollController = ScrollController();

  String? _currentQuestId;
  List<String> _shuffledKeys = [];
  List<String> _shuffledValues = [];
  final Map<String, int> _colorIndexMap = {};

  late final AnimationController _laserController;

  static const List<Color> _lightMatchColors = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF0D9488), // Teal
    Color(0xFFD97706), // Amber / Warm Orange
    Color(0xFFE11D48), // Rose
    Color(0xFF7C3AED), // Violet
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF16A34A), // Emerald
    Color(0xFFC026D3), // Fuchsia
  ];

  static const List<Color> _darkMatchColors = [
    Color(0xFF818CF8), // Luminous Indigo
    Color(0xFF2DD4BF), // Luminous Teal
    Color(0xFFFBBF24), // Luminous Amber
    Color(0xFFFB7185), // Luminous Rose
    Color(0xFFA78BFA), // Luminous Violet
    Color(0xFF38BDF8), // Luminous Sky Blue
    Color(0xFF4ADE80), // Luminous Emerald
    Color(0xFFE879F9), // Luminous Fuchsia
  ];

  @override
  void dispose() {
    _activeKey.dispose();
    _matches.dispose();
    _scrollController.dispose();
    _laserController.dispose();
    disposeReadingGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    initReadingGame();
  }

  GlobalKey _getKeyFor(String text) {
    return _terminalKeys.putIfAbsent(text, () => GlobalKey());
  }

  Rect? _getRectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final parentBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || parentBox == null) return null;

    final localPos = parentBox.globalToLocal(box.localToGlobal(Offset.zero));
    return Rect.fromLTWH(
      localPos.dx,
      localPos.dy,
      box.size.width,
      box.size.height,
    );
  }

  void _onKeyTap(String key) {
    if (isAnsweredNotifier.value) return;
    hapticService.selection();
    final Map<String, String> currentMatches = Map.from(_matches.value);

    if (currentMatches.containsKey(key)) {
      currentMatches.remove(key);
      _matches.value = currentMatches;
      _activeKey.value = key;
    } else {
      if (_activeKey.value == key) {
        _activeKey.value = null;
      } else {
        _activeKey.value = key;
      }
    }
  }

  void _onValueTap(
    String value,
    List<Map<String, String>> pairs,
    ReadingQuest quest,
  ) {
    if (isAnsweredNotifier.value) return;

    final Map<String, String> currentMatches = Map.from(_matches.value);

    if (_activeKey.value == null) {
      if (currentMatches.containsValue(value)) {
        hapticService.selection();
        final orphanedKey = currentMatches.entries
            .firstWhere((e) => e.value == value)
            .key;
        currentMatches.remove(orphanedKey);
        _matches.value = currentMatches;
        _activeKey.value = orphanedKey;
      }
      return;
    }

    hapticService.success();
    currentMatches.removeWhere((k, v) => v == value);
    currentMatches[_activeKey.value!] = value;
    _matches.value = currentMatches;
    _activeKey.value = null;

    _laserController.forward(from: 0.0);

    if (_matches.value.length == pairs.length) {
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
        context.read<ReadingBloc>().add(const SubmitAnswer(true));
      } else {
        submitWrongAnswer(quest: quest, userAnswer: 'Mismatched pairs');
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _matches.value = {};
            isAnsweredNotifier.value = false;
            isCorrectNotifier.value = null;
          }
        });
      }
    }
  }

  @override
  void onQuestionReset() {
    _activeKey.value = null;
    _matches.value = {};
    _terminalKeys.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);
    final matchColors = isDark ? _darkMatchColors : _lightMatchColors;

    return BlocConsumer<ReadingBloc, ReadingState>(
      listenWhen: readingListenWhen,
      listener: onReadingStateChanged,
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;
        final pairs = quest?.pairs ?? [];

        if (quest != null && quest.id != _currentQuestId) {
          _currentQuestId = quest.id;
          _shuffledKeys = pairs.map((p) => p['key']!).toList()..shuffle();
          _shuffledValues = pairs.map((p) => p['value']!).toList()..shuffle();

          _colorIndexMap.clear();
          for (int i = 0; i < pairs.length; i++) {
            _colorIndexMap[pairs[i]['key']!] = i % matchColors.length;
          }
        }

        final keys = _shuffledKeys.isEmpty
            ? pairs.map((p) => p['key']!).toList()
            : _shuffledKeys;
        final values = _shuffledValues.isEmpty
            ? pairs.map((p) => p['value']!).toList()
            : _shuffledValues;

        Color getColorForKey(String k) {
          final idx = _colorIndexMap[k];
          return idx != null ? matchColors[idx] : theme.primaryColor;
        }

        Color getColorForValue(String v) {
          if (_matches.value.containsValue(v)) {
            final key = _matches.value.entries
                .firstWhere((e) => e.value == v)
                .key;
            final idx = _colorIndexMap[key];
            return idx != null ? matchColors[idx] : theme.primaryColor;
          }
          return theme.primaryColor;
        }

        final Map<String, Color> activeColorMap = {
          for (final entry in _colorIndexMap.entries)
            entry.key: matchColors[entry.value % matchColors.length],
        };

        // Determine column flex based on whether keys contain long text/sentences
        final bool hasLongKeys = keys.any((k) {
          final clean = k.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
          return clean.length > 25;
        });
        final int leftFlex = hasLongKeys ? 1 : 4;
        final int rightFlex = hasLongKeys ? 1 : 5;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _matches,
            _activeKey,
            _laserController,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
              useScrolling: false,
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () =>
                  context.read<ReadingBloc>().add(const NextQuestion()),
              onHint: () {},
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : RawScrollbar(
                      controller: _scrollController,
                      thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                      radius: Radius.circular(8.r),
                      thickness: 4.w,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: 12.h),
                                  ReadAndMatchInstruction(
                                    primaryColor: theme.primaryColor,
                                    instruction:
                                        InstructionHelper.getInstruction(quest),
                                  ),
                                  SizedBox(height: 20.h),

                                  // Interactive Canvas
                                  SizedBox(
                                    key: _canvasKey,
                                    child: CustomPaint(
                                      painter: LaserBridgePainter(
                                        matches: _matches.value,
                                        activeKey: _activeKey.value,
                                        getRect: _getRectOf,
                                        getKey: _getKeyFor,
                                        color: theme.primaryColor,
                                        colorMap: activeColorMap,
                                        animationValue: _laserController.value,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Left Keys Column
                                          Expanded(
                                            flex: leftFlex,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: keys
                                                  .map(
                                                    (k) => Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 6.h,
                                                          ),
                                                      child: ReadAndMatchTerminal(
                                                        key: _getKeyFor(k),
                                                        text: k,
                                                        isSource: true,
                                                        color: getColorForKey(
                                                          k,
                                                        ),
                                                        isDark: isDark,
                                                        isMatched: _matches
                                                            .value
                                                            .containsKey(k),
                                                        isActive:
                                                            _activeKey.value ==
                                                            k,
                                                        shouldPulse:
                                                            _activeKey.value ==
                                                                null &&
                                                            !_matches.value
                                                                .containsKey(k),
                                                        onTap: () =>
                                                            _onKeyTap(k),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ),
                                          SizedBox(width: 20.w),
                                          // Right Values Column
                                          Expanded(
                                            flex: rightFlex,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: values
                                                  .map(
                                                    (v) => Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 6.h,
                                                          ),
                                                      child: ReadAndMatchTerminal(
                                                        key: _getKeyFor(v),
                                                        text: v,
                                                        isSource: false,
                                                        color: getColorForValue(
                                                          v,
                                                        ),
                                                        isDark: isDark,
                                                        isMatched: _matches
                                                            .value
                                                            .containsValue(v),
                                                        isActive: false,
                                                        shouldPulse:
                                                            _activeKey.value !=
                                                                null &&
                                                            !_matches.value
                                                                .containsValue(
                                                                  v,
                                                                ),
                                                        onTap: () =>
                                                            _onValueTap(
                                                              v,
                                                              pairs,
                                                              quest,
                                                            ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: SizedBox(
                              height:
                                  MediaQuery.of(context).viewInsets.bottom > 0
                                  ? MediaQuery.of(context).viewInsets.bottom +
                                        40.h
                                  : 100.h,
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}
