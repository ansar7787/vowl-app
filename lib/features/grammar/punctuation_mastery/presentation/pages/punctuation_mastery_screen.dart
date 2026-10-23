import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/punctuation_mastery/presentation/widgets/punctuation_mastery_instruction.dart';
import 'package:vowl/features/grammar/punctuation_mastery/presentation/widgets/punctuation_sticker_sheet.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

/// Screen presenting the punctuation mastery grammar exercise.
class PunctuationMasteryScreen extends StatefulWidget {
  /// The level number of the current session.
  final int level;

  /// The game subtype for tracking and analytics.
  final GameSubtype gameType;

  /// Creates a [PunctuationMasteryScreen] widget.
  const PunctuationMasteryScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.punctuationMastery,
  });

  @override
  State<PunctuationMasteryScreen> createState() =>
      _PunctuationMasteryScreenState();
}

class _PunctuationMasteryScreenState extends State<PunctuationMasteryScreen>
    with
        GameScreenMixin<PunctuationMasteryScreen>,
        GrammarGameScreenMixin<PunctuationMasteryScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  // 2N slots (prefix and suffix per word) to ensure proper typographical wrapping
  final ValueNotifier<Map<int, List<String>>> _prefixStickers = ValueNotifier(
    {},
  );
  final ValueNotifier<Map<int, List<String>>> _suffixStickers = ValueNotifier(
    {},
  );

  final ValueNotifier<bool> _pendingTyping = ValueNotifier(false);
  final ValueNotifier<String?> _assembledSentence = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _prefixStickers.dispose();
    _suffixStickers.dispose();
    _pendingTyping.dispose();
    _assembledSentence.dispose();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initGrammarGame();
  }

  List<String> _getRequiredMarks(GameQuest? quest) {
    if (quest == null) return [".", ",", "!", "?", ";", ":"];

    final expected = quest.correctAnswer ?? "";
    final Set<String> marks = {".", ",", "!", "?", "'", '"'};

    if (expected.contains("...")) marks.add("...");
    if (expected.contains("—")) marks.add("—");

    final puncs = expected.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '').split('');
    for (final p in puncs) {
      if (p != '.' && p != '-') marks.add(p);
      if (p == '-') marks.add('-');
    }

    return marks.toList()..sort();
  }

  void _onStick(int index, String mark, bool isPrefix) {
    final blocState = context.read<GrammarBloc>().state;
    if (blocState is GrammarLoaded && blocState.answerStatus.isAnswered) return;
    if (isAnsweredNotifier.value || _pendingTyping.value) return;
    hapticService.selection();
    final notifier = isPrefix ? _prefixStickers : _suffixStickers;
    final currentList = notifier.value[index] ?? [];
    notifier.value = Map.from(notifier.value)..[index] = [...currentList, mark];
  }

  void _onRemoveStick(int index, bool isPrefix) {
    final blocState = context.read<GrammarBloc>().state;
    if (blocState is GrammarLoaded && blocState.answerStatus.isAnswered) return;
    if (isAnsweredNotifier.value || _pendingTyping.value) return;
    hapticService.selection();
    final notifier = isPrefix ? _prefixStickers : _suffixStickers;
    final currentList = List<String>.from(notifier.value[index] ?? []);
    if (currentList.isNotEmpty) {
      currentList.removeLast();
      if (currentList.isEmpty) {
        notifier.value = Map.from(notifier.value)..remove(index);
      } else {
        notifier.value = Map.from(notifier.value)..[index] = currentList;
      }
    }
  }

  String _normalizeApostrophes(String s) {
    String res = s;
    while (RegExp(r"([a-z])'([a-z])").hasMatch(res)) {
      res = res.replaceAllMapped(
        RegExp(r"([a-z])'([a-z])"),
        (m) => "${m.group(1)}${m.group(2)}'",
      );
    }
    return res;
  }

  void _submitAnswer(GameQuest quest) {
    final blocState = context.read<GrammarBloc>().state;
    if (blocState is GrammarLoaded && blocState.answerStatus.isAnswered) return;
    if (isAnsweredNotifier.value || _pendingTyping.value) return;

    final words = (quest.sentence ?? "").split(" ");
    final StringBuffer resultBuffer = StringBuffer();

    // Construct user string including prefix and suffix slots
    for (int i = 0; i < words.length; i++) {
      if (_prefixStickers.value.containsKey(i)) {
        resultBuffer.write(_prefixStickers.value[i]!.join(""));
      }
      resultBuffer.write(words[i]);
      if (_suffixStickers.value.containsKey(i)) {
        resultBuffer.write(_suffixStickers.value[i]!.join(""));
      }
    }

    String uStr = resultBuffer.toString().replaceAll(" ", "").toLowerCase();
    String eStr = (quest.correctAnswer ?? "").replaceAll(" ", "").toLowerCase();

    bool isCorrect = _normalizeApostrophes(uStr) == _normalizeApostrophes(eStr);

    // To present the sentence elegantly to the user after they submit
    final StringBuffer displayResultBuffer = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      if (_prefixStickers.value.containsKey(i)) {
        displayResultBuffer.write(_prefixStickers.value[i]!.join(""));
      }
      displayResultBuffer.write(words[i]);
      if (_suffixStickers.value.containsKey(i)) {
        displayResultBuffer.write(_suffixStickers.value[i]!.join(""));
      }
      if (i < words.length - 1) displayResultBuffer.write(" ");
    }

    final displayResult = displayResultBuffer.toString();

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      _assembledSentence.value = displayResult;
      _pendingTyping.value = true;
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      _assembledSentence.value = displayResult;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
    _pendingTyping.value = false;
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = correct;

    if (correct) {
      hapticService.success();
      soundService.playCorrect();
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _prefixStickers.value = {};
    _suffixStickers.value = {};
    _pendingTyping.value = false;
    _assembledSentence.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listenWhen: grammarListenWhen,
      listener: onGrammarStateChanged,
      builder: (context, state) {
        final quest = (state is GrammarLoaded)
            ? state.currentQuest as GrammarQuest?
            : null;

        final marks = _getRequiredMarks(quest);

        String cleanTargetSentence = "";
        if (quest != null) {
          final sentence = quest.correctAnswer ?? quest.sentence ?? "";
          if (sentence.isNotEmpty) {
            cleanTargetSentence = sentence
                .replaceAll('[', '')
                .replaceAll(']', '');
          } else if (_assembledSentence.value != null) {
            cleanTargetSentence = _assembledSentence.value!;
          }
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _prefixStickers,
            _suffixStickers,
            _pendingTyping,
            _assembledSentence,
          ]),
          builder: (context, _) {
            return GrammarBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: showConfettiNotifier.value,
              useScrolling: false,
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () {},
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            RawScrollbar(
                              controller: _scrollController,
                              thumbColor: theme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              crossAxisMargin: 2,
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverFillRemaining(
                                    hasScrollBody: true,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              final maxHeight = MediaQuery.of(
                                                context,
                                              ).size.height;
                                              final isCompact = maxHeight < 700;
                                              final isGameAnswered =
                                                  isAnsweredNotifier.value ||
                                                  (state is GrammarLoaded &&
                                                      state
                                                          .answerStatus
                                                          .isAnswered);

                                              return Column(
                                                children: [
                                                  SizedBox(
                                                    height: isCompact
                                                        ? 4.h
                                                        : 8.h,
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 20.w,
                                                        ),
                                                    child:
                                                        PunctuationMasteryInstruction(
                                                          primaryColor: theme
                                                              .primaryColor,
                                                          instruction:
                                                              quest.instruction,
                                                        ),
                                                  ),
                                                  SizedBox(
                                                    height: isCompact
                                                        ? 4.h
                                                        : 8.h,
                                                  ),

                                                  if (quest.grammarRule !=
                                                      null) ...[
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 20.w,
                                                          ),
                                                      child: Container(
                                                        key: const ValueKey(
                                                          'grammar_rule_box',
                                                        ),
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 16.w,
                                                              vertical: 6.h,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: theme
                                                              .primaryColor
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                14.r,
                                                              ),
                                                          border: Border.all(
                                                            color: theme
                                                                .primaryColor
                                                                .withValues(
                                                                  alpha: 0.25,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            Text(
                                                              "RULE: ${quest.grammarRule!.toUpperCase()}",
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              softWrap: true,
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Outfit',
                                                                fontSize:
                                                                    12.sp,
                                                                color: theme
                                                                    .primaryColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                letterSpacing:
                                                                    0.5,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height: 2.h,
                                                            ),
                                                            Text(
                                                              "Tap to remove misplaced stickers",
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              softWrap: true,
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Outfit',
                                                                fontSize:
                                                                    10.5.sp,
                                                                color: theme
                                                                    .primaryColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.85,
                                                                    ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ).animate().fadeIn(
                                                      duration: 400.ms,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 4.h
                                                          : 8.h,
                                                    ),
                                                  ],

                                                  // Context Card with Sticker Slots
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 20.w,
                                                        ),
                                                    child: Container(
                                                      key: const ValueKey(
                                                        'punctuation_context_card',
                                                      ),
                                                      width: double.infinity,
                                                      padding: EdgeInsets.all(
                                                        isCompact
                                                            ? 12.r
                                                            : 16.r,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.05,
                                                                )
                                                            : Colors.black
                                                                .withValues(
                                                                  alpha: 0.03,
                                                                ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              isCompact
                                                                  ? 16.r
                                                                  : 20.r,
                                                            ),
                                                        border: Border.all(
                                                          color: theme
                                                              .primaryColor
                                                              .withValues(
                                                                alpha: 0.18,
                                                              ),
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      child:
                                                          _buildStickerSentence(
                                                            quest.sentence ??
                                                                "Missing sentence.",
                                                            theme.primaryColor,
                                                            isDark,
                                                            isCompact,
                                                          ),
                                                    ),
                                                  )
                                                  .animate()
                                                  .fadeIn(duration: 400.ms)
                                                  .slideY(
                                                    begin: 0.1,
                                                    end: 0,
                                                  ),

                                                  // Space between Context Card and Sticker Sheet / Type Confirm
                                                  SizedBox(
                                                    height: isCompact
                                                        ? 8.h
                                                        : 14.h,
                                                  ),

                                                  // Sticker Sheet
                                                  if (!isGameAnswered &&
                                                      !_pendingTyping.value)
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 20.w,
                                                          ),
                                                      child:
                                                          PunctuationStickerSheet(
                                                            marks: marks,
                                                            primaryColor: theme
                                                                .primaryColor,
                                                          ),
                                                    ),

                                                  // Type to Confirm Overlay
                                                  if (_pendingTyping.value &&
                                                      !isGameAnswered &&
                                                      cleanTargetSentence
                                                          .isNotEmpty)
                                                    Expanded(
                                                      child:
                                                          SingleChildScrollView(
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        20.w,
                                                                  ),
                                                              child:
                                                                  TypeToConfirmOverlay(
                                                                    expectedText:
                                                                        cleanTargetSentence,
                                                                    primaryColor:
                                                                        theme
                                                                            .primaryColor,
                                                                    onConfirmed:
                                                                        () =>
                                                                            _submitFinalAnswer(
                                                                              true,
                                                                            ),
                                                                    onSkipped:
                                                                        () =>
                                                                            _submitFinalAnswer(
                                                                              false,
                                                                            ),
                                                                    isPositioned:
                                                                        false,
                                                                  ),
                                                            ),
                                                          ),
                                                    ),

                                                  if (!_pendingTyping.value)
                                                    const Spacer(),

                                                  // Submit Button
                                                  if (!isGameAnswered &&
                                                      !_pendingTyping.value)
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 20.w,
                                                          ),
                                                      child: ScaleButton(
                                                        key: const ValueKey(
                                                          'punctuation_check_answer_button',
                                                        ),
                                                        onTap: () =>
                                                            _submitAnswer(
                                                              quest,
                                                            ),
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          height: isCompact
                                                              ? 46.h
                                                              : 50.h,
                                                          decoration:
                                                              BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      isCompact
                                                                          ? 14.r
                                                                          : 16.r,
                                                                    ),
                                                                gradient:
                                                                    LinearGradient(
                                                                      colors: [
                                                                        theme
                                                                            .primaryColor,
                                                                        theme
                                                                            .primaryColor
                                                                            .withValues(
                                                                              alpha:
                                                                                  0.85,
                                                                            ),
                                                                      ],
                                                                    ),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: theme
                                                                        .primaryColor
                                                                        .withValues(
                                                                          alpha:
                                                                              0.35,
                                                                        ),
                                                                    blurRadius:
                                                                        16,
                                                                    offset:
                                                                        const Offset(
                                                                          0,
                                                                          6,
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                          child: Center(
                                                            child: Text(
                                                              "CHECK ANSWER",
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Outfit',
                                                                fontSize:
                                                                    isCompact
                                                                    ? 13.sp
                                                                    : 14.5.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Colors
                                                                    .white,
                                                                letterSpacing:
                                                                    1.0,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                  SizedBox(
                                                    height: isCompact
                                                        ? 6.h
                                                        : 12.h,
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(
                                                context,
                                              ).viewInsets.bottom >
                                              0
                                          ? MediaQuery.of(
                                                  context,
                                                ).viewInsets.bottom +
                                                40.h
                                          : 20.h,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildStickerSentence(
    String sentence,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final words = sentence.split(" ");
    final double wordFontSize = isCompact ? 15.sp : 17.5.sp;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: isCompact ? 6.h : 10.h,
      children: List.generate(words.length, (index) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSlot(index, primaryColor, isCompact, isPrefix: true),
            Text(
              words[index],
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: wordFontSize,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            _buildSlot(index, primaryColor, isCompact, isPrefix: false),
          ],
        );
      }),
    );
  }

  Widget _buildSlot(
    int slotIndex,
    Color primaryColor,
    bool isCompact, {
    required bool isPrefix,
  }) {
    final double slotSize = isCompact ? 24.r : 28.r;
    final double markFontSize = isCompact ? 14.sp : 17.sp;
    final notifier = isPrefix ? _prefixStickers : _suffixStickers;
    final marks = notifier.value[slotIndex] ?? [];

    return DragTarget<String>(
      key: ValueKey(
        '${isPrefix ? "punctuation_prefix_slot" : "punctuation_suffix_slot"}_$slotIndex',
      ),
      onAcceptWithDetails: (details) =>
          _onStick(slotIndex, details.data, isPrefix),
      builder: (context, candidateData, rejectedData) {
        final isHighlight = candidateData.isNotEmpty;
        final hasMarks = marks.isNotEmpty;

        final double expandedWidth = (marks.length * markFontSize * 0.75 + 10.w)
            .clamp(slotSize, double.infinity);

        return GestureDetector(
          onTap: hasMarks ? () => _onRemoveStick(slotIndex, isPrefix) : null,
          child: Container(
            width: hasMarks || isHighlight
                ? expandedWidth + 4.w
                : (isCompact ? 12.w : 16.w),
            height: isCompact ? 30.h : 38.h,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: 200.ms,
              width: hasMarks || isHighlight ? expandedWidth : 3.w,
              height: hasMarks || isHighlight ? slotSize : 14.h,
              decoration: BoxDecoration(
                color: hasMarks
                    ? primaryColor
                    : (isHighlight
                          ? primaryColor.withValues(alpha: 0.25)
                          : Colors.transparent),
                borderRadius: BorderRadius.circular(slotSize / 2),
                border: Border.all(
                  color: isHighlight || hasMarks
                      ? primaryColor
                      : Colors.transparent,
                  width: isHighlight ? 2 : 1.5,
                  style: hasMarks
                      ? BorderStyle.none
                      : BorderStyle.solid,
                ),
                boxShadow: [
                  if (hasMarks)
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Center(
                child: hasMarks
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: marks
                            .map(
                              (m) => Text(
                                m,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: markFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            )
                            .toList(),
                      )
                    : (isHighlight
                          ? Icon(
                              Icons.add,
                              color: primaryColor,
                              size: isCompact ? 12.r : 16.r,
                            )
                          : null),
              ),
            ),
          ),
        );
      },
    );
  }
}
