import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/widgets/travel_desk_instruction.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/widgets/travel_desk_customs_terminal.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/widgets/travel_desk_passport_book.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/widgets/travel_desk_stamp_station.dart';
import 'package:vowl/features/roleplay/travel_desk/presentation/widgets/travel_desk_explanation_card.dart';

class TravelDeskScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const TravelDeskScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.travelDesk,
  });

  @override
  State<TravelDeskScreen> createState() => _TravelDeskScreenState();
}

class _TravelDeskScreenState extends State<TravelDeskScreen>
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late AnimationController _rippleController;
  late AnimationController _pulseController;

  int _lastProcessedIndex = -1;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  // Custom drag feedback coordinates
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.instruction);
    if (quest.prompt != null) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _soundService.playTts(quest.prompt!);
      });
    }
  }

  void _submitStamp(int index, int correctIndex) {
    if (_isAnswered) return;

    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
      _isCorrect = index == correctIndex;
    });

    _rippleController.forward(from: 0.0);

    if (index == correctIndex) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listener: (context, state) {
        if (state is RoleplayLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
              _hoveredIndex = null;
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'GLOBAL TRAVELER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];

        return RoleplayBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
          onHint: () => context.read<RoleplayBloc>().add(RoleplayHintUsed()),
          child: quest == null
              ? const SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxHeight < 580;
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: isCompact ? 5.h : 10.h,
                      ),
                      child: Column(
                        children: [
                          TravelDeskInstruction(
                            primaryColor: theme.primaryColor,
                            instruction: quest.instruction,
                          ),
                          SizedBox(height: isCompact ? 10.h : 16.h),
                          TravelDeskCustomsTerminal(
                            prompt: quest.prompt ?? "",
                            color: theme.primaryColor,
                            isDark: isDark,
                          ),
                          SizedBox(height: isCompact ? 16.h : 24.h),

                          // Biometric Passport Book
                          TravelDeskPassportBook(
                            options: options,
                            color: theme.primaryColor,
                            correctIndex: quest.correctAnswerIndex ?? 0,
                            isDark: isDark,
                            selectedIndex: _selectedIndex,
                            hoveredIndex: _hoveredIndex,
                            isAnswered: _isAnswered,
                            isCorrect: _isCorrect,
                            rippleAnimation: _rippleController,
                            onSubmitStamp: _submitStamp,
                            onHoverChanged: (index) {
                              _hapticService.selection();
                              setState(() => _hoveredIndex = index);
                            },
                            onHoverEnded: () {
                              setState(() => _hoveredIndex = null);
                            },
                            onDragStarted: () {},
                          ),
                          SizedBox(height: isCompact ? 20.h : 32.h),

                          // Stamp slammed terminal console
                          if (!_isAnswered)
                            TravelDeskStampStation(
                              color: theme.primaryColor,
                              isDark: isDark,
                              onDragStarted: () {
                                _hapticService.selection();
                                _soundService.playHint();
                              },
                              onDragEnded: () {
                                setState(() => _hoveredIndex = null);
                              },
                            )
                          else
                            TravelDeskExplanationCard(
                              quest: quest,
                              isDark: isDark,
                              isCorrect: _isCorrect,
                            ),

                          SizedBox(height: isCompact ? 40.h : 80.h),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
