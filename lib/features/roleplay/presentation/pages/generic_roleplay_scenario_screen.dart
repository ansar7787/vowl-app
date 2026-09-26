import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/mixins/roleplay_game_screen_mixin.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/constants/roleplay_constants.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/features/roleplay/presentation/widgets/chat_message.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_character_card.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_chat_messages_list.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_options_section.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

/// Generic screen for multiple-choice Roleplay quests.
///
/// Responsibilities:
///  - Reads [AuthBloc] **once** via `context.select` to extract the mascot ID,
///    then passes it into [RoleplayBaseLayout] â€” no cross-feature coupling below.
///  - Orchestrates local UI state (selected index, attempts, chat messages).
///  - Delegates sound / haptic feedback to [RoleplayBloc].
class GenericRoleplayScenarioScreen extends StatefulWidget {
  const GenericRoleplayScenarioScreen({
    super.key,
    required this.level,
    required this.gameType,
    required this.title,
    required this.icon,
  });

  final int level;
  final GameSubtype gameType;
  final String title;
  final IconData icon;

  @override
  State<GenericRoleplayScenarioScreen> createState() =>
      _GenericRoleplayScenarioScreenState();
}

class _GenericRoleplayScenarioScreenState
    extends State<GenericRoleplayScenarioScreen>
    with
        GameScreenMixin<GenericRoleplayScenarioScreen>,
        RoleplayGameScreenMixin<GenericRoleplayScenarioScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  // â”€â”€ Services â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _ttsService = di.sl<SpeechService>();
  final _chatScrollController = ScrollController();

  // â”€â”€ Local UI state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<bool> _isProcessing = ValueNotifier(false);

  /// Number of wrong taps for the current quest (resets per quest).
  final ValueNotifier<int> _attempts = ValueNotifier(0);

  /// Tracks the last rendered quest index to detect advancement.

  /// Null until the first [RoleplayLoaded] state arrives, avoiding a
  /// false-positive life-restore detection on first render.

  /// Prevents completion / game-over dialogs from showing twice.

  final ValueNotifier<List<ChatMessage>> _chatMessages = ValueNotifier([]);

  // â”€â”€ Lifecycle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  void initState() {
    super.initState();
    initRoleplayGame();
  }

  @override
  void dispose() {
    _chatScrollController.dispose();
    _ttsService.stop();
    _selectedIndex.dispose();
    _isProcessing.dispose();
    _attempts.dispose();
    _chatMessages.dispose();
    disposeRoleplayGame();
    super.dispose();
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // â”€â”€ Answer selection â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //
  // Sound and haptic feedback for the *result* are owned exclusively by
  // [RoleplayBloc._onSubmitAnswer]. Only a light tap haptic fires here.

  void _onOptionSelected(int index, int correctIndex, String text) async {
    if (isAnsweredNotifier.value ||
        _selectedIndex.value != null ||
        _isProcessing.value) {
      return;
    }

    hapticService.light(); // immediate tap affordance only

    _isProcessing.value = true;
    _selectedIndex.value = index;
    final currentChats = List<ChatMessage>.from(_chatMessages.value);
    currentChats.add(ChatMessage.user(text));
    _chatMessages.value = currentChats;
    _scrollToBottom();

    final isCorrect = index == correctIndex;

    if (isCorrect) {
      await Future.delayed(kRoleplayCorrectAnswerDelay);
      if (!mounted) return;
      isFirstStagePassedNotifier.value = true;
      _isProcessing.value = false;
      _scrollToBottom();
    } else {
      _attempts.value++;
      await Future.delayed(kRoleplayWrongAnswerDelay);
      if (!mounted) return;

      if (_attempts.value >= kRoleplayMaxWrongAttempts) {
        isAnsweredNotifier.value = true;
        _isProcessing.value = false;
      } else {
        _selectedIndex.value = null;
        _isProcessing.value = false;
      }
      context.read<RoleplayBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isFirstStagePassedNotifier.value = false;

    if (nailedIt) {
      hapticService.success();
      context.read<RoleplayBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      context.read<RoleplayBloc>().add(const SubmitAnswer(false));
    }
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  void onQuestionReset() {
    _selectedIndex.value = null;

    _isProcessing.value = false;

    _attempts.value = 0;

    _chatMessages.value = [];
  }

  @override
  Widget build(BuildContext context) {
    // context.select rebuilds only when the mascot ID field changes â€”
    // not on every auth state emission.
    final mascotId = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.vowlMascot ?? kRoleplayDefaultMascotId,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listenWhen: roleplayListenWhen,
      listener: onRoleplayStateChanged,
      builder: (context, state) {
        if (state is! RoleplayLoaded) {
          return const Scaffold(body: GameShimmerLoading());
        }

        final quest = state.currentQuest;
        final options = quest.options ?? const [];
        final correctIndex = quest.correctAnswerIndex ?? 0;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            _selectedIndex,
            _isProcessing,
            isFirstStagePassedNotifier,
            _attempts,
            _chatMessages,
            showConfettiNotifier,
          ]),
          builder: (context, _) {
            return RoleplayBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              mascotId: mascotId,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: _selectedIndex.value == correctIndex,
              isFinalFailure: _attempts.value >= kRoleplayMaxWrongAttempts,
              showConfetti: showConfettiNotifier.value,
              onContinue: () =>
                  context.read<RoleplayBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<RoleplayBloc>().add(const RoleplayHintUsed()),
              useScrolling: false,
              child: CustomScrollView(
                controller: _chatScrollController,
                physics: (!isFirstStagePassedNotifier.value)
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: IgnorePointer(
                      ignoring: isFirstStagePassedNotifier.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RoleplayCharacterCard(
                            roleName: quest.roleName ?? 'Professional Advisor',
                            icon: widget.icon,
                            primaryColor: theme.primaryColor,
                          ),
                          SizedBox(height: 32.h),
                          RoleplayChatMessagesList(
                            messages: _chatMessages.value,
                            isProcessing: _isProcessing.value,
                            hint: state.hintUsed ? quest.hint : null,
                            primaryColor: theme.primaryColor,
                            isDark: isDark,
                            scrollController: _chatScrollController,
                          ),
                          if (!isAnsweredNotifier.value &&
                              !isFirstStagePassedNotifier.value) ...[
                            SizedBox(height: 32.h),
                            RoleplayOptionsSection(
                              options: options,
                              correctIndex: correctIndex,
                              primaryColor: theme.primaryColor,
                              isDark: isDark,
                              onOptionSelected: _onOptionSelected,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (isFirstStagePassedNotifier.value &&
                      !isAnsweredNotifier.value &&
                      _selectedIndex.value != null)
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          SpeakToConfirmOverlay(
                            expectedText: options[_selectedIndex.value!],
                            primaryColor: theme.primaryColor,
                            isPositioned: false,
                            onConfirmed: () {
                              context.read<RoleplayBloc>().add(
                                const RoleplaySpeakConfirmed(5),
                              );
                              _submitVerbalEvaluation(true);
                            },
                            onSkipped: () => _submitVerbalEvaluation(false),
                          ),
                          SizedBox(height: 60.h),
                        ],
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom > 0
                          ? MediaQuery.of(context).viewInsets.bottom + 40.h
                          : 120.h,
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
