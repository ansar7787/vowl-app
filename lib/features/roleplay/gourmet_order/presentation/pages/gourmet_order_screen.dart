import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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

// Holographic hot steam wave painter rising from serving platter
class SteamWavesPainter extends CustomPainter {
  final double animationValue;
  final Color themeColor;

  SteamWavesPainter({
    required this.animationValue,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = themeColor.withValues(alpha: 0.15 * (1.0 - animationValue))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;

    // Draw three elegant wavy steam columns rising upward
    for (int col = 0; col < 3; col++) {
      final double startX = (width * 0.25) + (col * width * 0.25);
      final Path path = Path();
      
      path.moveTo(startX, height);

      for (double y = height; y > 0; y -= 10) {
        // Calculate undulating horizontal offsets
        double progress = (height - y) / height;
        double wavePhase = (progress * 2 * math.pi) - (animationValue * 2 * math.pi);
        double xOffset = math.sin(wavePhase) * 6.r * (1.0 - progress);
        
        path.lineTo(startX + xOffset, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SteamWavesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.themeColor != themeColor;
  }
}

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

  bool _isHoveringPlatter = false;

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
              _isHoveringPlatter = false;
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
                      _buildHeaderInstruction(theme.primaryColor),
                      SizedBox(height: 16.h),
                      _buildBanquetHeader(quest.prompt ?? "", theme.primaryColor, isDark),
                      SizedBox(height: 24.h),

                      // Floating Cloche Platter
                      _buildTableSetting(theme.primaryColor, isDark),
                      SizedBox(height: 24.h),

                      // Tray of plate choices
                      _buildPlateTray(options, theme.primaryColor, isDark),
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
                                      style: GoogleFonts.outfit(
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
                                      style: GoogleFonts.outfit(
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
                        secondChild: _buildExplanationCard(quest, isDark),
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

  Widget _buildHeaderInstruction(Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(
            "STELLAR KITCHEN DESK",
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 2.5,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          "Drag or tap gourmet food plates to load the serving platter",
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildBanquetHeader(String prompt, Color color, bool isDark) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.room_service_rounded, color: color, size: 24.r),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 1.5.seconds,
                curve: Curves.easeInOut,
              ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CLIENT ORDER TICKET SPECIFICATION:",
                  style: GoogleFonts.shareTechMono(
                    fontSize: 10.sp,
                    color: color,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  "\"$prompt\"",
                  style: GoogleFonts.fredoka(
                    fontSize: 17.sp,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.35,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSetting(Color color, bool isDark) {
    Color ringColor = color;
    if (_isAnswered) {
      ringColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (data) => !_isAnswered,
      onAcceptWithDetails: (details) {
        _onItemTapped(details.data);
        setState(() => _isHoveringPlatter = false);
      },
      onMove: (details) {
        if (!_isHoveringPlatter) {
          _hapticService.selection();
          setState(() => _isHoveringPlatter = true);
        }
      },
      onLeave: (data) {
        setState(() => _isHoveringPlatter = false);
      },
      builder: (context, candidateData, rejectedData) {
        final bool isActiveGlow = _isHoveringPlatter || _selectedItems.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 210.r,
          height: 210.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
            border: Border.all(
              color: ringColor.withValues(alpha: isActiveGlow ? 0.75 : 0.2),
              width: isActiveGlow ? 4.5 : 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: ringColor.withValues(alpha: isActiveGlow ? 0.22 : 0.04),
                blurRadius: isActiveGlow ? 20 : 10,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glowing steam custom wave painter
              if (_selectedItems.isNotEmpty)
                Positioned.fill(
                  child: ClipOval(
                    child: AnimatedBuilder(
                      animation: _steamController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: SteamWavesPainter(
                            animationValue: _steamController.value,
                            themeColor: ringColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Cloche cover icon/platter details
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isAnswered
                        ? ((_isCorrect ?? false) ? Icons.done_all_rounded : Icons.close_rounded)
                        : Icons.room_service_outlined,
                    color: ringColor.withValues(alpha: isActiveGlow ? 0.9 : 0.25),
                    size: 72.r,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _isAnswered
                        ? ((_isCorrect ?? false) ? "SERVED PERFECTLY" : "WRONG DISHES")
                        : "SERVING PLATTER",
                    style: GoogleFonts.shareTechMono(
                      fontSize: 10.sp,
                      color: ringColor.withValues(alpha: isActiveGlow ? 0.9 : 0.35),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (_selectedItems.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: ringColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        "${_selectedItems.length} PLATES LOADED",
                        style: GoogleFonts.outfit(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                          color: ringColor,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ).animate(
          onPlay: (c) => c.repeat(reverse: true),
        ).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.03, 1.03),
          duration: 2.2.seconds,
          curve: Curves.easeInOut,
        );
      },
    );
  }

  Widget _buildPlateTray(List<String> options, Color color, bool isDark) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "BANQUET PLATE TRAY",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: color,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.kitchen_rounded, color: color.withValues(alpha: 0.5), size: 16.r),
            ],
          ),
          SizedBox(height: 18.h),

          // Scrollable Plate drawer containing Draggables
          SizedBox(
            height: 110.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: options.length,
              itemBuilder: (context, i) => _buildDraggablePlate(options[i], color, isDark),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildDraggablePlate(String item, Color color, bool isDark) {
    final bool isSelected = _selectedItems.contains(item);

    Color plateColor = color;
    if (_isAnswered && isSelected) {
      plateColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    }

    return Padding(
      padding: EdgeInsets.only(right: 14.w),
      child: Draggable<String>(
        data: item,
        onDragStarted: () {
          _hapticService.selection();
          _soundService.playHint(); // Play synth note
        },
        feedback: _buildPlateCore(item, plateColor, isSelected, isDark, isDraggingFeedback: true),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildPlateCore(item, plateColor, isSelected, isDark, isDraggingFeedback: false),
        ),
        child: InkWell(
          onTap: () => _onItemTapped(item),
          borderRadius: BorderRadius.circular(100.r),
          child: _buildPlateCore(item, plateColor, isSelected, isDark, isDraggingFeedback: false),
        ),
      ),
    );
  }

  Widget _buildPlateCore(String item, Color color, bool isSelected, bool isDark, {required bool isDraggingFeedback}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 100.r,
        height: 100.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? color : (isDark ? const Color(0xFF131326) : Colors.white),
          border: Border.all(
            color: isSelected ? Colors.white : color.withValues(alpha: 0.4),
            width: isSelected ? 3.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? color : Colors.black).withValues(alpha: isDraggingFeedback ? 0.45 : 0.08),
              blurRadius: isDraggingFeedback ? 15 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(10.r),
              child: Text(
                item.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 4.h,
                right: 4.w,
                child: Container(
                  padding: EdgeInsets.all(2.r),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, color: color, size: 10.r),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard(RoleplayQuest quest, bool isDark) {
    final Color cardColor = (_isCorrect ?? false) ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131326) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.15),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                (_isCorrect ?? false) ? Icons.verified_rounded : Icons.info_rounded,
                color: cardColor,
                size: 24.r,
              ),
              SizedBox(width: 8.w),
              Text(
                (_isCorrect ?? false) ? "Culinary Fulfill Perfect!" : "Culinary Recipe Mismatch!",
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            quest.explanation ?? "Identifying the ingredients ordered by travelers reinforces vocabulary recall and contextual spelling logic.",
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.35,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}
