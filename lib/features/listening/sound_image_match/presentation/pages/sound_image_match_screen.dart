import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_event.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/widgets/sound_image_match_instruction.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/widgets/sound_image_match_emitter.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/widgets/sound_image_match_scanner_field.dart';
import 'package:vowl/core/presentation/widgets/speak_to_confirm_overlay.dart';

class SoundImageMatchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SoundImageMatchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.soundImageMatch,
  });

  @override
  State<SoundImageMatchScreen> createState() => _SoundImageMatchScreenState();
}

class _SoundImageMatchScreenState extends State<SoundImageMatchScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  Offset _lensPosition = const Offset(150, 150);
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  int? _selectedIndex;
  int? _pendingSelectedIndex;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onScan(Offset position) {
    if (_isAnswered) return;
    setState(() {
      _lensPosition = position;
      _hapticService.selection();
    });
  }

  void _submitFinalAnswer(bool nailedSpeaking, int correct) {
    if (_isAnswered || _pendingSelectedIndex == null) return;

    if (!nailedSpeaking) {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _selectedIndex = _pendingSelectedIndex;
      });
      context.read<ListeningBloc>().add(SubmitAnswer(false));
      return;
    }

    bool isCorrect = _pendingSelectedIndex == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
        _selectedIndex = _pendingSelectedIndex;
      });
      context.read<ListeningBloc>().add(const ListeningSpeakConfirmed(5));
      context.read<ListeningBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _selectedIndex = _pendingSelectedIndex;
      });
      context.read<ListeningBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: (context, state) {
        if (state is ListeningLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'THEMATIC LINKER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;

        return ListeningBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          useScrolling: false,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Stack(
                    children: [
                      CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: 6.h),
                                  SoundImageMatchInstruction(
                                    color: theme.primaryColor,
                                    instruction: quest.instruction,
                                  ),
                                  SizedBox(height: 24.h),
                                  SoundImageMatchEmitter(
                                    onTap: () {
                                      _soundService.playTts(
                                        quest.textToSpeak ?? "",
                                      );
                                      _hapticService.selection();
                                    },
                                    color: theme.primaryColor,
                                    emoji: quest.emoji,
                                    isCorrectState: _isCorrect,
                                  ),
                                  SizedBox(height: 32.h),
                                ],
                              ),
                            ),
                          ),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 16.h,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    height: 350.h,
                                    child: SoundImageMatchScannerField(
                                      options: quest.options ?? [],
                                      correctAnswerIndex:
                                          quest.correctAnswerIndex ?? 0,
                                      color: theme.primaryColor,
                                      isAnswered: _isAnswered,
                                      isCorrectState: _isCorrect,
                                      selectedIndex: _selectedIndex,
                                      lensPosition: _lensPosition,
                                      onScan: _onScan,
                                      onSelect: (index) {
                                        if (_isAnswered ||
                                            _pendingSelectedIndex != null) {
                                          return;
                                        }
                                        setState(() {
                                          _pendingSelectedIndex = index;
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 100.h), // Spacing for SpeakToConfirmOverlay
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_pendingSelectedIndex != null && !_isAnswered)
                        SpeakToConfirmOverlay(
                          expectedText:
                              quest.options![_pendingSelectedIndex!],
                          primaryColor: theme.primaryColor,
                          onConfirmed: () => _submitFinalAnswer(
                            true,
                            quest.correctAnswerIndex ?? 0,
                          ),
                          onSkipped: () => _submitFinalAnswer(
                            false,
                            quest.correctAnswerIndex ?? 0,
                          ),
                          allowSkip: true,
                        ),
                    ],
                  ),
        );
      },
    );
  }
}
