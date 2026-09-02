import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_instruction.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_topic_banner.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_hex_slot.dart';
import 'package:vowl/features/writing/essay_drafting/presentation/widgets/essay_drafting_data_stream.dart';
import 'package:vowl/core/presentation/game_mechanics/type_to_confirm_overlay.dart';

class EssayDraftingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const EssayDraftingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.essayDrafting,
  });

  @override
  State<EssayDraftingScreen> createState() => _EssayDraftingScreenState();
}

class _EssayDraftingScreenState extends State<EssayDraftingScreen> {
  final _hapticService = di.sl<HapticService>();

  final ValueNotifier<Map<String, String?>> _blueprintSlots = ValueNotifier({});
  WritingQuest? _lastQuest;
  final ValueNotifier<List<String>> _shuffledOptions = ValueNotifier([]);

  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _pendingSubmit = ValueNotifier(false);

  late final ScrollController _scrollController;

  @override
  void dispose() {
    _scrollController.dispose();
    _blueprintSlots.dispose();
    _shuffledOptions.dispose();
    _showConfetti.dispose();
    _pendingSubmit.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onSlot(String slotKey, String data, bool isAnswered) {
    if (isAnswered) return;

    _hapticService.success();
    final newSlots = Map<String, String?>.from(_blueprintSlots.value);
    newSlots.forEach((key, val) {
      if (val == data) {
        newSlots[key] = null;
      }
    });
    newSlots[slotKey] = data;
    _blueprintSlots.value = newSlots;
  }

  void _clearSlot(String slotKey, bool isAnswered) {
    if (isAnswered || _blueprintSlots.value[slotKey] == null) return;
    _hapticService.selection();
    final newSlots = Map<String, String?>.from(_blueprintSlots.value);
    newSlots[slotKey] = null;
    _blueprintSlots.value = newSlots;
  }

  void _submitAnswer(bool isAnswered) {
    if (isAnswered) return;
    _pendingSubmit.value = true;
  }

  void _submitFinalAnswer(bool nailedTyping) {
    _pendingSubmit.value = false;

    final state = context.read<WritingBloc>().state;
    if (state is! WritingLoaded) return;

    if (!nailedTyping) {
      _hapticService.error();
      context.read<WritingBloc>().add(const SubmitAnswer(false));
      return;
    }

    final quest = state.currentQuest;
    final points = quest.requiredPoints ?? [];
    final options = quest.options ?? [];
    final correctOrderIndices = quest.correctOrder ?? [0, 1, 2, 3];

    if (points.length != 4 ||
        options.length != 4 ||
        correctOrderIndices.length != 4) {
      return;
    }

    bool isSlot0Correct =
        _blueprintSlots.value[points[0]] == options[correctOrderIndices[0]];
    bool isSlot1Correct =
        _blueprintSlots.value[points[1]] == options[correctOrderIndices[1]];
    bool isSlot2Correct =
        _blueprintSlots.value[points[2]] == options[correctOrderIndices[2]];
    bool isSlot3Correct =
        _blueprintSlots.value[points[3]] == options[correctOrderIndices[3]];

    final isCorrect =
        isSlot0Correct && isSlot1Correct && isSlot2Correct && isSlot3Correct;

    context.read<WritingBloc>().add(SubmitAnswer(isCorrect));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listenWhen: (prev, curr) =>
          (curr is WritingGameComplete && prev is! WritingGameComplete) ||
          (curr is WritingLoaded && !curr.answerStatus.isAnswered),
      listener: (context, state) {
        if (state is WritingLoaded && !state.answerStatus.isAnswered) {
          final newSlots = <String, String?>{};
          final quest = state.currentQuest;
          for (var point in (quest.requiredPoints ?? [])) {
            newSlots[point] = null;
          }
          _blueprintSlots.value = newSlots;
          _pendingSubmit.value = false;
          _shuffledOptions.value = List<String>.from(quest.options ?? [])
            ..shuffle();
        }
        if (state is WritingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'ESSAY ARCHITECT!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        final WritingQuest? quest = isLoaded
            ? state.currentQuest as WritingQuest?
            : null;

        if (quest != null) {
          _lastQuest = quest;
        }

        final activeQuest = quest ?? _lastQuest;

        final options = activeQuest?.options ?? [];

        final bool isAnswered = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;
        final bool isFinalFailure = state.livesRemaining == 0;

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
          showConfetti: _showConfetti.value,
          useScrolling: false,
          onContinue: () =>
              context.read<WritingBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<WritingBloc>().add(const WritingHintUsed()),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _showConfetti,
              _blueprintSlots,
              _shuffledOptions,
              _pendingSubmit,
            ]),
            builder: (context, _) {
              final slotsFilled =
                  _blueprintSlots.value.values.every((v) => v != null) &&
                  _blueprintSlots.value.isNotEmpty;

              return activeQuest == null
                  ? const SizedBox()
                  : Stack(
                      children: [
                        RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                sliver: SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      SizedBox(height: 16.h),
                                      EssayDraftingInstruction(
                                        primaryColor: theme.primaryColor,
                                        instruction: activeQuest.instruction,
                                      ),
                                      SizedBox(height: 24.h),

                                      EssayDraftingTopicBanner(
                                        topic: activeQuest.essayTopic ?? "",
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                      ),
                                      SizedBox(height: 16.h),
                                      if (activeQuest.thesisStatement != null)
                                        Container(
                                          margin: EdgeInsets.only(bottom: 16.h),
                                          padding: EdgeInsets.all(12.r),
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            border: Border.all(
                                              color: theme.primaryColor
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.center_focus_strong,
                                                    color: theme.primaryColor,
                                                    size: 14.sp,
                                                  ),
                                                  SizedBox(width: 8.w),
                                                  Text(
                                                    "THESIS STATEMENT",
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 10.sp,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: theme.primaryColor,
                                                      letterSpacing: 1.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                activeQuest.thesisStatement!,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      SizedBox(height: 8.h),

                                      ..._blueprintSlots.value.keys.map(
                                        (k) => EssayDraftingHexSlot(
                                          slotKey: k,
                                          slotValue: _blueprintSlots.value[k],
                                          color: theme.primaryColor,
                                          isDark: isDark,
                                          onSlot: (key, data) =>
                                              _onSlot(key, data, isAnswered),
                                          onClearSlot: (key) =>
                                              _clearSlot(key, isAnswered),
                                        ),
                                      ),
                                      SizedBox(height: 24.h),

                                      EssayDraftingDataStream(
                                        items: _shuffledOptions.value.isNotEmpty
                                            ? _shuffledOptions.value
                                            : options,
                                        slots: _blueprintSlots.value,
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                      ),
                                      SizedBox(height: 16.h),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (!isAnswered)
                                        ScaleButton(
                                          onTap: slotsFilled
                                              ? () => _submitAnswer(isAnswered)
                                              : null,
                                          child: Container(
                                            width: double.infinity,
                                            height: 60.h,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                              color: slotsFilled
                                                  ? theme.primaryColor
                                                  : Colors.grey,
                                              boxShadow: [
                                                if (slotsFilled)
                                                  BoxShadow(
                                                    color: theme.primaryColor
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 15,
                                                  ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                "TRANSMIT BLUEPRINT",
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      SizedBox(
                                        height: !isAnswered ? 380.h : 160.h,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_pendingSubmit.value && !isAnswered)
                          TypeToConfirmOverlay(
                            expectedText:
                                _blueprintSlots.value.isNotEmpty &&
                                    _blueprintSlots.value.values.first != null
                                ? _blueprintSlots.value.values.first!
                                : "",
                            displayText:
                                "Type the first point to finalize the outline",
                            primaryColor: theme.primaryColor,
                            onConfirmed: () => _submitFinalAnswer(true),
                            onSkipped: () => _submitFinalAnswer(false),
                            allowSkip: true,
                          ),
                      ],
                    );
            },
          ),
        );
      },
    );
  }
}
