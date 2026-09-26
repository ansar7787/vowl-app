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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/grammar/modals_selection/presentation/widgets/modals_selection_instruction.dart';
import 'package:vowl/features/grammar/modals_selection/presentation/widgets/modals_rotary_dial.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

class ModalsSelectionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ModalsSelectionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.modalsSelection,
  });

  @override
  State<ModalsSelectionScreen> createState() => _ModalsSelectionScreenState();
}

class _ModalsSelectionScreenState extends State<ModalsSelectionScreen>
    with
        GameScreenMixin<ModalsSelectionScreen>,
        GrammarGameScreenMixin<ModalsSelectionScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<int> _selectedIndex = ValueNotifier(0);
  final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _selectedIndex.dispose();
    _pendingJigsaw.dispose();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initGrammarGame();
  }

  void _submitAnswer(int correctIndex) {
    if (isAnsweredNotifier.value || _pendingJigsaw.value) return;

    bool isCorrect = _selectedIndex.value == correctIndex;

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      _pendingJigsaw.value = true;

      // Auto-scroll to show the second stage (TypeToConfirm Jigsaw) at the bottom
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
    _pendingJigsaw.value = false;
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

  List<InlineSpan> _buildSentenceWithBlank(
    String template,
    String? selected,
    Color primaryColor,
    bool isDark,
  ) {
    final parts = template.split(RegExp(r'_{3,}'));
    List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < parts.length - 1) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child:
                Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected != null
                                ? primaryColor
                                : (isDark ? Colors.white38 : Colors.black38),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        selected ?? "      ",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    )
                    .animate(target: selected != null ? 1 : 0)
                    .shimmer(duration: 2.seconds),
          ),
        );
      }
    }
    return spans;
  }

  Widget _buildGrammarRule(String rule, Color primaryColor) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline, color: primaryColor, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                "GRAMMAR RULE",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            rule,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              color: primaryColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildContextCard(
    GrammarQuest quest,
    List<String> options,
    Color primaryColor,
    bool isDark,
  ) {
    return ListenableBuilder(
      listenable: _selectedIndex,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(22.r),
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20.sp,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.5,
              ),
              children: _buildSentenceWithBlank(
                quest.question ?? "___ sentence.",
                options[_selectedIndex.value],
                primaryColor,
                isDark,
              ),
            ),
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildSubmitButton(GrammarQuest quest, Color primaryColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: ScaleButton(
        onTap: () => _submitAnswer(quest.correctAnswerIndex ?? 0),
        child: Container(
          width: double.infinity,
          height: 65.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              "LOCK CONFIGURATION",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void onQuestionReset() {
    _selectedIndex.value = 0;

    _pendingJigsaw.value = false;
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
        final options = quest?.options ?? ["CAN", "COULD", "MUST", "SHOULD"];

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
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
              useScrolling: false, // Using our own CustomScrollView
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<GrammarBloc>().add(const GrammarHintUsed()),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : Stack(
                      children: [
                        RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          crossAxisMargin: 2,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.symmetric(vertical: 20.h),
                                sliver: SliverList(
                                  delegate: SliverChildListDelegate([
                                    ModalsSelectionInstruction(
                                      primaryColor: theme.primaryColor,
                                    ),
                                    SizedBox(height: 24.h),

                                    if (quest.grammarRule != null) ...[
                                      _buildGrammarRule(
                                        quest.grammarRule!,
                                        theme.primaryColor,
                                      ),
                                      SizedBox(height: 24.h),
                                    ],

                                    _buildContextCard(
                                      quest,
                                      options,
                                      theme.primaryColor,
                                      isDark,
                                    ),

                                    SizedBox(height: 32.h),

                                    Center(
                                      child: ModalsRotaryDial(
                                        options: options,
                                        isAnsweredNotifier: isAnsweredNotifier,
                                        pendingJigsawNotifier: _pendingJigsaw,
                                        selectedIndexNotifier: _selectedIndex,
                                        correctAnswerIndex:
                                            quest.correctAnswerIndex ?? 0,
                                        isDark: isDark,
                                        primaryColor: theme.primaryColor,
                                      ),
                                    ),

                                    SizedBox(height: 32.h),

                                    ListenableBuilder(
                                      listenable: Listenable.merge([
                                        isAnsweredNotifier,
                                        _pendingJigsaw,
                                      ]),
                                      builder: (context, _) {
                                        if (!isAnsweredNotifier.value &&
                                            !_pendingJigsaw.value) {
                                          return _buildSubmitButton(
                                            quest,
                                            theme.primaryColor,
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ]),
                                ),
                              ),
                              ListenableBuilder(
                                listenable: Listenable.merge([
                                  _pendingJigsaw,
                                  isAnsweredNotifier,
                                ]),
                                builder: (context, _) {
                                  if (_pendingJigsaw.value &&
                                      !isAnsweredNotifier.value) {
                                    final sentence =
                                        quest.sentence ?? quest.question ?? "";
                                    String fullSentence = sentence;
                                    if (sentence.contains(RegExp(r'_{3,}'))) {
                                      fullSentence = sentence.replaceFirst(
                                        RegExp(r'_{3,}'),
                                        options[_selectedIndex.value],
                                      );
                                    }
                                    final cleanTargetSentence = fullSentence
                                        .replaceAll(RegExp(r'\s+'), ' ')
                                        .trim();

                                    if (cleanTargetSentence.isNotEmpty) {
                                      return SliverToBoxAdapter(
                                        child: TypeToConfirmOverlay(
                                          expectedText: cleanTargetSentence,
                                          primaryColor: theme.primaryColor,
                                          onConfirmed: () =>
                                              _submitFinalAnswer(true),
                                          onSkipped: () =>
                                              _submitFinalAnswer(false),
                                          isPositioned: false,
                                          displayText:
                                              "Type the full sentence to lock it in",
                                        ),
                                      );
                                    }
                                  }
                                  return const SliverToBoxAdapter(
                                    child: SizedBox.shrink(),
                                  );
                                },
                              ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).viewInsets.bottom >
                                          0
                                      ? MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom +
                                            40.h
                                      : 60.h,
                                ),
                              ),
                            ],
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
