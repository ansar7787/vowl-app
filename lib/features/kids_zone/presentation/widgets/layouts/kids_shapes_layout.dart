import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

/// Parsed metadata for an option card in the Shapes game.
/// Pairs the English shape vocabulary with its geometric symbol and 2D/3D taxonomy.
class ShapeOptionData {
  /// The raw unparsed text of the option.
  final String raw;

  /// The cleaned shape name or title.
  final String title;

  /// The geometric symbol or emoji representing the shape.
  final String shapeSymbol;

  /// Whether the shape is a three-dimensional solid.
  final bool is3D;

  /// Creates a [ShapeOptionData] instance.
  const ShapeOptionData({
    required this.raw,
    required this.title,
    required this.shapeSymbol,
    this.is3D = false,
  });

  static const Map<String, ({String symbol, bool is3D})> _shapeRegistry = {
    'circle': (symbol: '●', is3D: false),
    'square': (symbol: '■', is3D: false),
    'triangle': (symbol: '▲', is3D: false),
    'rectangle': (symbol: '▬', is3D: false),
    'diamond': (symbol: '◆', is3D: false),
    'oval': (symbol: '⬭', is3D: false),
    'star': (symbol: '★', is3D: false),
    'heart': (symbol: '♥', is3D: false),
    'pentagon': (symbol: '⬟', is3D: false),
    'hexagon': (symbol: '⬢', is3D: false),
    'octagon': (symbol: '🛑', is3D: false),
    'crescent': (symbol: '🌙', is3D: false),
    'sphere': (symbol: '⚽', is3D: true),
    'cube': (symbol: '🎲', is3D: true),
    'cone': (symbol: '🍦', is3D: true),
    'cylinder': (symbol: '🥫', is3D: true),
    'pyramid': (symbol: '🔺', is3D: true),
    'rectangular prism': (symbol: '📦', is3D: true),
  };

  /// Parses raw option [text] into a structured [ShapeOptionData] instance.
  factory ShapeOptionData.parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return ShapeOptionData(raw: text, title: text, shapeSymbol: '📐');
    }

    final lower = trimmed.toLowerCase();
    final match = _shapeRegistry[lower];
    if (match != null) {
      return ShapeOptionData(
        raw: text,
        title: trimmed,
        shapeSymbol: match.symbol,
        is3D: match.is3D,
      );
    }

    // Partial prefix/substring match if option has modifier or plural
    for (final entry in _shapeRegistry.entries) {
      if (lower.contains(entry.key)) {
        return ShapeOptionData(
          raw: text,
          title: trimmed,
          shapeSymbol: entry.value.symbol,
          is3D: entry.value.is3D,
        );
      }
    }

    return ShapeOptionData(raw: text, title: trimmed, shapeSymbol: '📐');
  }
}

/// Helper mapping curriculum subtypes into clear, child-friendly learning badges.
class ShapeSubtypeHelper {
  const ShapeSubtypeHelper._();

  /// Resolves the human-readable label and emoji icon for a given curriculum [subtype].
  static ({String label, String icon}) resolve(String? subtype) {
    if (subtype == null || subtype.isEmpty) {
      return (label: 'Shapes', icon: '📐');
    }
    switch (subtype.toLowerCase()) {
      case 'basic_2d_shapes':
        return (label: '2D Shapes', icon: '📐');
      case 'shape_comparison':
        return (label: 'Matching Shapes', icon: '🔍');
      case 'intro_3d_shapes':
        return (label: '3D Shapes', icon: '🧱');
      case '2d_vs_3d_properties':
        return (label: 'Flat & Solid Shapes', icon: '📦');
      case 'shape_composition':
        return (label: 'Building Shapes', icon: '🧩');
      case 'symmetry_and_patterns':
        return (label: 'Patterns', icon: '✨');
      case 'advanced_shape_reasoning':
        return (label: 'Shape Challenge', icon: '⭐');
      case 'expanded_2d_shapes':
        return (label: 'More 2D Shapes', icon: '📏');
      case 'sides_and_corners':
        return (label: 'Sides & Corners', icon: '📐');
      case 'more_sides_and_curves':
        return (label: 'Sides & Curves', icon: '🌀');
      default:
        return (label: 'Shapes', icon: '📐');
    }
  }
}

/// Production-Grade Toy Construction Site Theme for Kids Shapes Game.
///
/// Features:
/// - Prominent Architectural Blueprint Crane with yellow/amber hazard arm, steel cable,
///   blueprint drafting grid, and corner pins.
/// - Unspoiled target area displaying the real-world object clue with animated hover feedback.
/// - Prominent, readable Clue Note Banner displaying [quest.instruction] with on-demand audio speech replay.
/// - Dual interaction: Seamless Drag-and-Drop AND high-accessibility Tap-to-Answer for all blocks.
/// - Tactile Toy Building Blocks with 3D studs, drop shadows, and geometric shape icon badges for ESL visual-word pairing.
/// - Audio scaffolding: Independent shape pronunciation buttons on every toy building block.
/// - Rich visual feedback: Correct block glows emerald with celebration snap; incorrect block glows soft rose red.
/// - Responsive layout engine adapting smoothly from 320dp small screens to large tablets with safety scroll.
///
/// Algorithmic Complexity:
/// - Time Complexity: O(N) where N is the number of options (3..4)
/// - Space Complexity: O(1) auxiliary space
class KidsShapesLayout extends StatefulWidget {
  /// The current game level or world index.
  final int level;

  /// The display title of the game.
  final String title;

  /// The primary theme color for accents and badges.
  final Color primaryColor;

  /// Creates a [KidsShapesLayout] widget.
  const KidsShapesLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsShapesLayout> createState() => _KidsShapesLayoutState();
}

class _KidsShapesLayoutState extends State<KidsShapesLayout> {
  String? _selectedOption;
  int _lastAnsweredQuestIndex = -1;

  void _handleOptionSubmit(
    BuildContext context,
    KidsLoaded state,
    String option,
  ) {
    if (state.answerStatus.isAnswered) return;

    setState(() {
      _selectedOption = option;
      _lastAnsweredQuestIndex = state.currentIndex;
    });

    final quest = state.currentQuest;
    final isCorrect = (option == quest.correctAnswer);

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Submitting option "$option" for quest "${quest.id}" (correct: $isCorrect)',
        tag: 'KidsShapesLayout',
      );
    }

    if (!isCorrect) {
      final parsed = ShapeOptionData.parse(option);
      di.sl<KidsTTSService>().speak(parsed.title);
      di.sl<HapticService>().error();
    } else {
      di.sl<HapticService>().success();
    }

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _playOptionAudio(String text) {
    final parsed = ShapeOptionData.parse(text);
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Pronouncing option "$text" ("${parsed.title}")',
        tag: 'KidsShapesLayout',
      );
    }
    di.sl<KidsTTSService>().speak(parsed.title, force: true);
    di.sl<HapticService>().selection();
  }

  void _replayQuestionAudio(dynamic quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    if (instruction.isNotEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'Replaying clue audio for quest "${quest.id}"',
          tag: 'KidsShapesLayout',
        );
      }
      di.sl<KidsTTSService>().speak(instruction, force: true);
      di.sl<HapticService>().selection();
    }
  }

  String? _extractSubtype(dynamic quest) {
    if (quest == null) return null;
    try {
      if (quest.metadata != null && quest.metadata is Map) {
        final subtype = quest.metadata['subtype'];
        if (subtype is String && subtype.isNotEmpty) return subtype;
      }
    } catch (_) {}
    return null;
  }
  @override
  void dispose() {
    try {
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().stop();
      }
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: widget.title,
      gameType: 'shapes',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        // Reset selected option when active quest index changes
        if (state.currentIndex != _lastAnsweredQuestIndex) {
          _selectedOption = null;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final isCompactHeight = availableHeight < 680;
            final isUltraCompactHeight = availableHeight < 580;

            final craneArmWidth = (constraints.maxWidth * 0.48).clamp(140.0, 210.0).w;
            final blueprintWidth = (constraints.maxWidth * 0.92).clamp(280.0, 420.0).w;
            final blueprintHeight = isUltraCompactHeight
                ? 170.h
                : isCompactHeight
                    ? 195.h
                    : 220.h;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: availableHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(height: KidsGameBaseScreen.mascotClearanceHeight),

                      // Construction Crane Assembly holding Blueprint
                      _buildBlueprintCrane(
                        context: context,
                        state: state,
                        quest: quest,
                        armWidth: craneArmWidth,
                        paperWidth: blueprintWidth,
                        paperHeight: blueprintHeight,
                        isCompact: isCompactHeight,
                      ),

                      SizedBox(height: isCompactHeight ? 6.h : 10.h),

                      // Instruction Clue Banner
                      _buildClueBanner(context, state, quest),

                      SizedBox(height: isCompactHeight ? 6.h : 8.h),

                      // Construction Action Guidance
                      _buildActionGuidance(context, state),

                      SizedBox(height: isCompactHeight ? 8.h : 10.h),

                      // The Toy Building Blocks (Shape Options)
                      _buildToyBlocksRow(context, state, quest, isCompact: isCompactHeight),

                      SizedBox(height: 14.h),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the Crane arm, hanging cable, and architectural blueprint paper.
  Widget _buildBlueprintCrane({
    required BuildContext context,
    required KidsLoaded state,
    required dynamic quest,
    required double armWidth,
    required double paperWidth,
    required double paperHeight,
    required bool isCompact,
  }) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        if (state.answerStatus.isAnswered) return false;
        di.sl<HapticService>().selection();
        return true;
      },
      onAcceptWithDetails: (details) {
        _handleOptionSubmit(context, state, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final isAnswered = state.answerStatus.isAnswered;
        final isCorrectAnswer = isAnswered &&
            (_selectedOption == quest.correctAnswer ||
                state.answerStatus == AnswerStatus.correct);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Crane Girder Arm (Yellow & Dark Amber Construction Stripes)
            Container(
              height: 14.h,
              width: armWidth,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(color: const Color(0xFF78350F), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2.r),
                child: CustomPaint(painter: _HazardStripePainter()),
              ),
            ),

            // Crane Pulley & Cable
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ],
            ),
            Container(
              height: isCompact ? 16.h : 22.h,
              width: 3.w,
              decoration: BoxDecoration(
                color: const Color(0xFF4B5563),
                borderRadius: BorderRadius.circular(1.r),
              ),
            ),

            // Blueprint Paper Board
            ScaleButton(
              onTap: isAnswered ? null : () => _replayQuestionAudio(quest),
              child: Semantics(
                label: 'Blueprint drafting board. Tap to hear clue.',
                button: !isAnswered,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: paperWidth,
                  height: paperHeight,
                  decoration: BoxDecoration(
                    color: isHovering
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isCorrectAnswer
                          ? const Color(0xFF10B981)
                          : isHovering
                              ? const Color(0xFFFACC15)
                              : Colors.white.withValues(alpha: 0.85),
                      width: isHovering || isCorrectAnswer ? 3.5 : 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isHovering
                            ? const Color(0xFFFACC15).withValues(alpha: 0.35)
                            : isCorrectAnswer
                                ? const Color(0xFF10B981).withValues(alpha: 0.35)
                                : Colors.black.withValues(alpha: 0.3),
                        blurRadius: isHovering || isCorrectAnswer ? 16 : 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Drafting Grid Lines
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: CustomPaint(painter: _BlueprintGridPainter()),
                        ),
                      ),

                      // Blueprint Corner Drafting Pins
                      Positioned(top: 6.h, left: 6.w, child: _buildCornerPin()),
                      Positioned(top: 6.h, right: 6.w, child: _buildCornerPin()),
                      Positioned(bottom: 6.h, left: 6.w, child: _buildCornerPin()),
                      Positioned(bottom: 6.h, right: 6.w, child: _buildCornerPin()),

                      // Blueprint Content
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top Bar: Subtype Badge & Replay Speaker
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: _buildSubtypeBadge(_extractSubtype(quest)),
                                ),
                                SizedBox(width: 6.w),
                                ScaleButton(
                                  onTap: isAnswered ? null : () => _replayQuestionAudio(quest),
                                  child: Semantics(
                                    label: 'Replay clue audio',
                                    button: !isAnswered,
                                    child: Container(
                                      padding: EdgeInsets.all(5.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.25),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.volume_up_rounded,
                                        size: 13.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                          ),

                          // Target Center Silhouette / Object Display
                          Expanded(
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _buildTargetCenter(
                                  quest: quest,
                                  isHovering: isHovering,
                                  isCorrectAnswer: isCorrectAnswer,
                                  isCompact: isCompact,
                                ),
                              ),
                            ),
                          ),

                          // Bottom Blueprint Blueprint Stamp
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              isCorrectAnswer
                                  ? '✨ Nice Match! ✨'
                                  : isHovering
                                      ? 'Drop shape here'
                                      : 'Shape • Level ${state.level}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                                color: isCorrectAnswer
                                    ? const Color(0xFF34D399)
                                    : isHovering
                                        ? const Color(0xFFFDE047)
                                        : Colors.white.withValues(alpha: 0.85),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Blueprint corner metal pin / rivet.
  Widget _buildCornerPin() {
    return Container(
      width: 7.w,
      height: 7.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFCBD5E1),
        border: Border.all(color: const Color(0xFF64748B), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
    );
  }

  /// Playful subtype badge at top-left of the blueprint.
  Widget _buildSubtypeBadge(String? subtype) {
    final meta = ShapeSubtypeHelper.resolve(subtype);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(meta.icon, style: TextStyle(fontSize: 12.sp)),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              meta.label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Target area inside the blueprint showing the clue object emoji or revealed shape.
  Widget _buildTargetCenter({
    required dynamic quest,
    required bool isHovering,
    required bool isCorrectAnswer,
    required bool isCompact,
  }) {
    final emojiSize = isCompact ? 46.sp : 58.sp;
    final emojiText = quest.emoji as String?;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isHovering
            ? const Color(0xFFFACC15).withValues(alpha: 0.15)
            : isCorrectAnswer
                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isCorrectAnswer
              ? const Color(0xFF34D399)
              : isHovering
                  ? const Color(0xFFFDE047)
                  : Colors.white.withValues(alpha: 0.3),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (emojiText != null && emojiText.isNotEmpty)
            Text(
              emojiText,
              style: TextStyle(fontSize: emojiSize),
            ).animate(
              onPlay: (controller) => controller.repeat(reverse: true),
            ).scale(
              begin: const Offset(0.96, 0.96),
              end: const Offset(1.04, 1.04),
              duration: 1800.ms,
              curve: Curves.easeInOut,
            )
          else
            Text(
              '📐',
              style: TextStyle(fontSize: emojiSize),
            ),
          if (isCorrectAnswer) ...[
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF10B981),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 22.sp,
                color: Colors.white,
              ),
            ).animate().scale(curve: Curves.elasticOut, duration: 500.ms),
          ],
        ],
      ),
    );
  }

  /// Prominent, child-friendly Clue Banner showing the question riddle.
  Widget _buildClueBanner(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
  ) {
    final instruction = InstructionHelper.getInstruction(quest);

    return ScaleButton(
      key: const Key('kids_shapes_clue_banner'),
      onTap: state.answerStatus.isAnswered
          ? null
          : () => _replayQuestionAudio(quest),
      child: Semantics(
        label: 'Shape clue: $instruction. Tap to listen.',
        button: !state.answerStatus.isAnswered,
        child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Question Clue Icon
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: const Color(0xFFF59E0B),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text('📐', style: TextStyle(fontSize: 18.sp)),
              ),
            ),
            SizedBox(width: 12.w),

            // Instruction Clue Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SHAPE CLUE',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    instruction,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),

            // Tap-to-Speak Button
            Container(
              padding: EdgeInsets.all(7.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volume_up_rounded,
                size: 20.sp,
                color: const Color(0xFFD97706),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Clear, encouraging interaction prompt for children.
  Widget _buildActionGuidance(BuildContext context, KidsLoaded state) {
    return KidsFittedText(
      context.tr(
        'games.kids_shapes_drag',
        fallback: 'Tap or drag the matching shape block',
      ),
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.85)
            : const Color(0xFF4B5563),
      ),
      maxLines: 1,
      textAlign: TextAlign.center,
    );
  }

  /// Builds the row of colorful toy building blocks representing the shape options.
  Widget _buildToyBlocksRow(
    BuildContext context,
    KidsLoaded state,
    dynamic quest, {
    bool isCompact = false,
  }) {
    final options = quest.options as List<String>? ?? const [];
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(options.length, (index) {
          final option = options[index];
          final isCorrect = (quest.correctAnswer == option);

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: _buildToyBlock(
                context: context,
                state: state,
                option: option,
                isCorrect: isCorrect,
                index: index,
                isCompact: isCompact,
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Builds an individual Lego-style toy building block.
  Widget _buildToyBlock({
    required BuildContext context,
    required KidsLoaded state,
    required String option,
    required bool isCorrect,
    required int index,
    bool isCompact = false,
  }) {
    final parsed = ShapeOptionData.parse(option);

    // Primary toy construction block colors
    final brickPalettes = [
      (
        primary: const Color(0xFFEF4444), // Crimson Red
        stud: const Color(0xFFDC2626),
        shadow: const Color(0xFF991B1B),
      ),
      (
        primary: const Color(0xFF2563EB), // Blueprint Blue
        stud: const Color(0xFF1D4ED8),
        shadow: const Color(0xFF1E3A8A),
      ),
      (
        primary: const Color(0xFF10B981), // Emerald Green
        stud: const Color(0xFF059669),
        shadow: const Color(0xFF065F46),
      ),
      (
        primary: const Color(0xFFF59E0B), // Amber Gold
        stud: const Color(0xFFD97706),
        shadow: const Color(0xFF92400E),
      ),
    ];

    final palette = brickPalettes[index % brickPalettes.length];

    final isAnswered = state.answerStatus.isAnswered;
    final isSelected = (_selectedOption == option);

    Color brickColor = palette.primary;
    Color studColor = palette.stud;
    Color shadowColor = palette.shadow;
    Color borderColor = Colors.white.withValues(alpha: 0.25);

    if (isAnswered) {
      if (isSelected && isCorrect) {
        brickColor = const Color(0xFF10B981);
        studColor = const Color(0xFF059669);
        shadowColor = const Color(0xFF065F46);
        borderColor = Colors.white;
      } else if (isSelected && !isCorrect) {
        brickColor = const Color(0xFFF43F5E);
        studColor = const Color(0xFFE11D48);
        shadowColor = const Color(0xFF9F1239);
        borderColor = const Color(0xFFFECDD3);
      } else if (isCorrect) {
        // Highlight correct option if learner picked wrong
        brickColor = const Color(0xFF10B981);
        studColor = const Color(0xFF059669);
        shadowColor = const Color(0xFF065F46);
        borderColor = Colors.white;
      }
    }

    final blockWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Studs on top of the Lego block
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            2,
            (i) => _buildStud(studColor, shadowColor),
          ),
        ),

        // Main Block Body
        Container(
          constraints: BoxConstraints(
            minHeight: isCompact ? 76.h : 84.h,
          ),
          decoration: BoxDecoration(
            color: brickColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1.5),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.7),
                offset: Offset(0, 4.h),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                offset: Offset(0, 6.h),
                blurRadius: 6,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle top beveled highlight
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 4.h,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top Bar: Geometric Shape Symbol Badge + Audio Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Geometric Shape Icon Pill
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            parsed.shapeSymbol,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Option Pronunciation Button
                        ScaleButton(
                          onTap: () => _playOptionAudio(option),
                          child: Semantics(
                            label: 'Hear pronunciation for $option',
                            button: true,
                            child: Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.volume_up_rounded,
                                size: 13.sp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 6.h),

                    // Shape Vocabulary Title
                    Center(
                      child: Text(
                        parsed.title,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              offset: const Offset(0, 1),
                              blurRadius: 1.5,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // If already answered, render without dragging
    if (isAnswered) {
      return blockWidget;
    }

    // Interactive state: Both Tap-to-Answer and Drag-to-Blueprint
    return Draggable<String>(
      data: option,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.06,
          child: Opacity(
            opacity: 0.95,
            child: SizedBox(
              width: 95.w,
              child: blockWidget,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: blockWidget,
      ),
      child: Semantics(
        label: '$option shape block. Tap or drag to answer.',
        button: true,
        child: ScaleButton(
          key: Key('toy_block_$option'),
          onTap: () => _handleOptionSubmit(context, state, option),
          child: blockWidget,
        ),
      ),
    );
  }

  /// 3D Stud atop a toy block.
  Widget _buildStud(Color studColor, Color shadowColor) {
    return Container(
      height: 7.h,
      width: 18.w,
      decoration: BoxDecoration(
        color: studColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.5),
            offset: Offset(0, 1.5.h),
            blurRadius: 0,
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering architectural drafting grid lines.
class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final majorGridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const spacing = 18.0;

    // Vertical grid lines
    int countX = 0;
    for (double x = 0; x <= size.width; x += spacing) {
      final isMajor = (countX % 4 == 0);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? majorGridPaint : gridPaint,
      );
      countX++;
    }

    // Horizontal grid lines
    int countY = 0;
    for (double y = 0; y <= size.height; y += spacing) {
      final isMajor = (countY % 4 == 0);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMajor ? majorGridPaint : gridPaint,
      );
      countY++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter rendering construction yellow & dark hazard stripes.
class _HazardStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stripePaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.fill;

    const stripeWidth = 10.0;
    for (double x = -size.height; x < size.width + size.height; x += stripeWidth * 2) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + stripeWidth, size.height)
        ..lineTo(x + stripeWidth + size.height, 0)
        ..lineTo(x + size.height, 0)
        ..close();
      canvas.drawPath(path, stripePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
