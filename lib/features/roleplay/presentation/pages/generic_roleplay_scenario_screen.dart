import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/constants/roleplay_constants.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/features/roleplay/presentation/widgets/chat_message.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_character_card.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_chat_messages_list.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_options_section.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

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
    extends State<GenericRoleplayScenarioScreen> {
  // â”€â”€ Services â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _hapticService = di.sl<HapticService>();
  final _ttsService = di.sl<SpeechService>();
  final _chatScrollController = ScrollController();

  // â”€â”€ Local UI state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool> _isProcessing = ValueNotifier(false);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);

  /// Number of wrong taps for the current quest (resets per quest).
  final ValueNotifier<int> _attempts = ValueNotifier(0);

  /// Tracks the last rendered quest index to detect advancement.
  int _lastProcessedIndex = -1;

  /// Null until the first [RoleplayLoaded] state arrives, avoiding a
  /// false-positive life-restore detection on first render.
  int? _lastLives;

  /// Prevents completion / game-over dialogs from showing twice.
  bool _dialogShown = false;

  final ValueNotifier<List<ChatMessage>> _chatMessages = ValueNotifier([]);

  // â”€â”€ Lifecycle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  void initState() {
    super.initState();
    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _chatScrollController.dispose();
    _ttsService.stop();
    _showConfetti.dispose();
    _selectedIndex.dispose();
    _isAnswered.dispose();
    _isProcessing.dispose();
    _isFirstStagePassed.dispose();
    _attempts.dispose();
    _chatMessages.dispose();
    super.dispose();
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _playAudio(String text) async {
    await _ttsService.stop();
    _hapticService.light();
    await _ttsService.speak(text);
  }

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

  void _resetForNewQuest(RoleplayLoaded state) {
    _lastProcessedIndex = state.currentIndex;
    _isAnswered.value = false;
    _selectedIndex.value = null;
    _isFirstStagePassed.value = false;
    _attempts.value = 0;
    _chatMessages.value = [ChatMessage.system(state.currentQuest.instruction)];

    _playAudio(state.currentQuest.instruction);
    _scrollToBottom();
  }

  // â”€â”€ Answer selection â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //
  // Sound and haptic feedback for the *result* are owned exclusively by
  // [RoleplayBloc._onSubmitAnswer]. Only a light tap haptic fires here.

  void _onOptionSelected(int index, int correctIndex, String text) async {
    if (_isAnswered.value ||
        _selectedIndex.value != null ||
        _isProcessing.value) {
      return;
    }

    _hapticService.light(); // immediate tap affordance only

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
      _isFirstStagePassed.value = true;
      _isProcessing.value = false;
      _scrollToBottom();
    } else {
      _attempts.value++;
      await Future.delayed(kRoleplayWrongAnswerDelay);
      if (!mounted) return;

      if (_attempts.value >= kRoleplayMaxWrongAttempts) {
        _isAnswered.value = true;
        _isProcessing.value = false;
      } else {
        _selectedIndex.value = null;
        _isProcessing.value = false;
      }
      context.read<RoleplayBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isFirstStagePassed.value = false;

    if (nailedIt) {
      _hapticService.success();
      context.read<RoleplayBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      context.read<RoleplayBloc>().add(const SubmitAnswer(false));
    }
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
      listener: (context, state) {
        if (state is RoleplayLoaded) {
          final livesRestored =
              _lastLives != null && state.livesRemaining > _lastLives!;

          final shouldReset =
              state.currentIndex != _lastProcessedIndex ||
              livesRestored ||
              (!state.answerStatus.isAnswered && _isAnswered.value);

          if (shouldReset) {
            _dialogShown = false;
            _resetForNewQuest(state);
          }

          _lastLives = state.livesRemaining;
        } else if (state is RoleplayGameComplete && !_dialogShown) {
          _dialogShown = true;
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'ROLEPLAY MASTER!',
            enableDoubleUp: true,
          );
        } else if (state is RoleplayGameOver && !_dialogShown) {
          _dialogShown = true;
          GameDialogHelper.showGameOver(
            context,
            onRestore: () {
              _dialogShown = false;
              context.read<RoleplayBloc>().add(const RestoreLife());
            },
          );
        }
      },
      builder: (context, state) {
        if (state is! RoleplayLoaded) {
          return const Scaffold(body: GameShimmerLoading());
        }

        final quest = state.currentQuest;
        final options = quest.options ?? const [];
        final correctIndex = quest.correctAnswerIndex ?? 0;

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _selectedIndex,
            _isProcessing,
            _isFirstStagePassed,
            _attempts,
            _chatMessages,
            _showConfetti,
          ]),
          builder: (context, _) {
            return RoleplayBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              mascotId: mascotId,
              isAnswered: _isAnswered.value,
              isCorrect: _selectedIndex.value == correctIndex,
              isFinalFailure: _attempts.value >= kRoleplayMaxWrongAttempts,
              showConfetti: _showConfetti.value,
              onContinue: () =>
                  context.read<RoleplayBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<RoleplayBloc>().add(const RoleplayHintUsed()),
              useScrolling: false,
              child: CustomScrollView(
                controller: _chatScrollController,
                physics: (!_isFirstStagePassed.value)
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: IgnorePointer(
                      ignoring: _isFirstStagePassed.value,
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
                          if (!_isAnswered.value &&
                              !_isFirstStagePassed.value) ...[
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
                  if (_isFirstStagePassed.value &&
                      !_isAnswered.value &&
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
                      height: (_isFirstStagePassed.value && !_isAnswered.value)
                          ? 180.h
                          : 60.h,
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
