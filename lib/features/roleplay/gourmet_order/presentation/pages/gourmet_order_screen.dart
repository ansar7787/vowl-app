import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_instruction.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_banquet_header.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_table_setting.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_plate_tray.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

class GourmetOrderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const GourmetOrderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.gourmetOrder,
  });

  @override
  State<GourmetOrderScreen> createState() => _GourmetOrderScreenState();
}

class _GourmetOrderScreenState extends State<GourmetOrderScreen>
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late AnimationController _steamController;
  late AnimationController _pulseController;

  int _lastProcessedIndex = -1;
  final ValueNotifier<List<String>> _selectedItems = ValueNotifier([]);
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _steamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
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
    _steamController.dispose();
    _pulseController.dispose();
    _selectedItems.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _isFirstStagePassed.dispose();
    _scrollController.dispose();
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

  void _onItemTapped(String item) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _hapticService.selection();
    _soundService.playHint(); // Play synth note
    final current = List<String>.from(_selectedItems.value);
    if (current.contains(item)) {
      current.remove(item);
    } else {
      current.add(item);
    }
    _selectedItems.value = current;
  }

  void _clearItems() {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _hapticService.selection();
    _selectedItems.value = [];
  }

  void _submitAnswer(String correctAnswer) {
    if (_isAnswered.value ||
        _isFirstStagePassed.value ||
        _selectedItems.value.isEmpty) {
      return;
    }

    final targets = correctAnswer
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .toList();
    final current = _selectedItems.value
        .map((e) => e.trim().toLowerCase())
        .toList();

    bool isCorrect =
        targets.length == current.length &&
        targets.every((t) => current.contains(t));

    if (isCorrect) {
      _hapticService.selection();
      _isFirstStagePassed.value = true;
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;

    if (nailedIt) {
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
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _selectedItems.value = [];
            _isFirstStagePassed.value = false;
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is RoleplayGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'CULINARY EXPERT!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];
        final prices = quest?.menuPrices ?? [];

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _selectedItems,
            _isFirstStagePassed,
          ]),
          builder: (context, _) {
            return RoleplayBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  _isAnswered.value &&
                  (_isCorrect.value != null || !_isFirstStagePassed.value),
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
              onContinue: () =>
                  context.read<RoleplayBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<RoleplayBloc>().add(RoleplayHintUsed()),
              useScrolling: false,
              child: quest == null
                  ? const SizedBox()
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
                              child: CustomScrollView(
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final isCompact =
                                                  constraints.maxHeight < 580;
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                  vertical: isCompact
                                                      ? 5.h
                                                      : 10.h,
                                                ),
                                                child: Column(
                                                  children: [
                                                    GourmetOrderInstruction(
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      instruction:
                                                          quest.instruction,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 10.h
                                                          : 16.h,
                                                    ),
                                                    GourmetOrderBanquetHeader(
                                                      prompt:
                                                          quest.prompt ?? "",
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 16.h
                                                          : 24.h,
                                                    ),

                                                    // Floating Cloche Platter
                                                    GourmetOrderTableSetting(
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      isAnswered:
                                                          _isAnswered.value &&
                                                          (_isCorrect.value != null || !_isFirstStagePassed.value),
                                                      isCorrect:
                                                          _isCorrect.value,
                                                      selectedItems:
                                                          _selectedItems.value,
                                                      steamAnimation:
                                                          _steamController,
                                                      onItemTapped:
                                                          _onItemTapped,
                                                      onHapticFeedback:
                                                          _hapticService
                                                              .selection,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 16.h
                                                          : 24.h,
                                                    ),

                                                    // Tray of plate choices
                                                    GourmetOrderPlateTray(
                                                      options: options,
                                                      prices: prices,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      isAnswered:
                                                          _isAnswered.value &&
                                                          (_isCorrect.value != null || !_isFirstStagePassed.value),
                                                      isCorrect:
                                                          _isCorrect.value,
                                                      selectedItems:
                                                          _selectedItems.value,
                                                      onItemTapped:
                                                          _onItemTapped,
                                                      onDragStarted: () {
                                                        _hapticService
                                                            .selection();
                                                        _soundService
                                                            .playHint(); // Play synth note
                                                      },
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 20.h
                                                          : 28.h,
                                                    ),

                                                    // Trigger Action Buttons
                                                    if (!_isAnswered.value &&
                                                        _selectedItems
                                                            .value
                                                            .isNotEmpty)
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          ScaleButton(
                                                            onTap: _clearItems,
                                                            child: Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        isCompact
                                                                        ? 16.w
                                                                        : 24.w,
                                                                    vertical:
                                                                        isCompact
                                                                        ? 10.h
                                                                        : 12.h,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: theme
                                                                    .primaryColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      30.r,
                                                                    ),
                                                                border: Border.all(
                                                                  color: theme
                                                                      .primaryColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.3,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .refresh_rounded,
                                                                    color: theme
                                                                        .primaryColor,
                                                                    size:
                                                                        isCompact
                                                                        ? 16.r
                                                                        : 18.r,
                                                                  ),
                                                                  SizedBox(
                                                                    width: 6.w,
                                                                  ),
                                                                  Text(
                                                                    "CLEAR PLATTER",
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Outfit',
                                                                      fontSize:
                                                                          isCompact
                                                                          ? 10.sp
                                                                          : 12.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: theme
                                                                          .primaryColor,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: isCompact
                                                                ? 10.w
                                                                : 16.w,
                                                          ),
                                                          ScaleButton(
                                                            onTap: () =>
                                                                _submitAnswer(
                                                                  quest.correctAnswer ??
                                                                      "",
                                                                ),
                                                            child: Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        isCompact
                                                                        ? 20.w
                                                                        : 32.w,
                                                                    vertical:
                                                                        isCompact
                                                                        ? 10.h
                                                                        : 12.h,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      30.r,
                                                                    ),
                                                                gradient: LinearGradient(
                                                                  colors: [
                                                                    theme
                                                                        .primaryColor,
                                                                    theme
                                                                        .primaryColor
                                                                        .withValues(
                                                                          alpha:
                                                                              0.8,
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
                                                                        isCompact
                                                                        ? 10
                                                                        : 15,
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .restaurant_menu_rounded,
                                                                    color: Colors
                                                                        .white,
                                                                    size:
                                                                        isCompact
                                                                        ? 16.r
                                                                        : 18.r,
                                                                  ),
                                                                  SizedBox(
                                                                    width: 6.w,
                                                                  ),
                                                                  Text(
                                                                    "SERVE PLATTER",
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Outfit',
                                                                      fontSize:
                                                                          isCompact
                                                                          ? 10.sp
                                                                          : 12.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .white,
                                                                      letterSpacing:
                                                                          1.5,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ).animate().fadeIn(
                                                        duration: 300.ms,
                                                      ),

                                                    // Explanations cards post-selection
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 20.h
                                                          : 40.h,
                                                    ),
                                                  ],
                                                ),
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
                                          (_isFirstStagePassed.value &&
                                              !_isAnswered.value)
                                          ? 380.h
                                          : 60.h,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isFirstStagePassed.value && !_isAnswered.value)
                              SpeakToConfirmOverlay(
                                expectedText:
                                    quest.correctAnswer ??
                                    _selectedItems.value.join(', '),
                                primaryColor: theme.primaryColor,
                                isPositioned: true,
                                onConfirmed: () {
                                  context.read<RoleplayBloc>().add(
                                    const RoleplaySpeakConfirmed(5),
                                  );
                                  _submitVerbalEvaluation(true);
                                },
                                onSkipped: () => _submitVerbalEvaluation(false),
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
}
