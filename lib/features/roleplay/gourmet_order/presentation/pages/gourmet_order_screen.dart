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
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_instruction.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_banquet_header.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_table_setting.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_plate_tray.dart';
import 'package:vowl/features/roleplay/gourmet_order/presentation/widgets/gourmet_order_explanation_card.dart';

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

class _GourmetOrderScreenState extends State<GourmetOrderScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  late AnimationController _steamController;
  late AnimationController _pulseController;
  
  int _lastProcessedIndex = -1;
  final List<String> _selectedItems = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

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

    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _steamController.dispose();
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

  void _onItemTapped(String item) {
    if (_isAnswered) return;
    _hapticService.selection();
    _soundService.playHint(); // Play synth note
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  void _clearItems() {
    if (_isAnswered) return;
    _hapticService.selection();
    setState(() {
      _selectedItems.clear();
    });
  }

  void _submitAnswer(String correctAnswer) {
    if (_isAnswered || _selectedItems.isEmpty) return;
    
    final targets = correctAnswer.split(',').map((e) => e.trim().toLowerCase()).toList();
    final current = _selectedItems.map((e) => e.trim().toLowerCase()).toList();
    
    bool isCorrect = targets.length == current.length && targets.every((t) => current.contains(t));

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
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
              _selectedItems.clear();
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
            title: 'CULINARY EXPERT!',
            enableDoubleUp: true,
          );
        } else if (state is RoleplayGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()),
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
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Column(
                    children: [
                      GourmetOrderInstruction(primaryColor: theme.primaryColor),
                      SizedBox(height: 16.h),
                      GourmetOrderBanquetHeader(
                        prompt: quest.prompt ?? "",
                        color: theme.primaryColor,
                        isDark: isDark,
                      ),
                      SizedBox(height: 24.h),

                      // Floating Cloche Platter
                      GourmetOrderTableSetting(
                        color: theme.primaryColor,
                        isDark: isDark,
                        isAnswered: _isAnswered,
                        isCorrect: _isCorrect,
                        selectedItems: _selectedItems,
                        steamAnimation: _steamController,
                        onItemTapped: _onItemTapped,
                        onHapticFeedback: _hapticService.selection,
                      ),
                      SizedBox(height: 24.h),

                      // Tray of plate choices
                      GourmetOrderPlateTray(
                        options: options,
                        color: theme.primaryColor,
                        isDark: isDark,
                        isAnswered: _isAnswered,
                        isCorrect: _isCorrect,
                        selectedItems: _selectedItems,
                        onItemTapped: _onItemTapped,
                        onDragStarted: () {
                          _hapticService.selection();
                          _soundService.playHint(); // Play synth note
                        },
                      ),
                      SizedBox(height: 28.h),

                      // Trigger Action Buttons
                      if (!_isAnswered && _selectedItems.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaleButton(
                              onTap: _clearItems,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(30.r),
                                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.refresh_rounded, color: theme.primaryColor, size: 18.r),
                                    SizedBox(width: 6.w),
                                    Text(
                                      "CLEAR PLATTER",
                                      style: TextStyle(fontFamily: 'Outfit', 
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            ScaleButton(
                              onTap: () => _submitAnswer(quest.correctAnswer ?? ""),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30.r),
                                  gradient: LinearGradient(
                                    colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(alpha: 0.35),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 18.r),
                                    SizedBox(width: 6.w),
                                    Text(
                                      "SERVE PLATTER",
                                      style: TextStyle(fontFamily: 'Outfit', 
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 300.ms),

                      // Explanations cards post-selection
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: GourmetOrderExplanationCard(
                          quest: quest,
                          isDark: isDark,
                          isCorrect: _isCorrect,
                        ),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 80.h),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
