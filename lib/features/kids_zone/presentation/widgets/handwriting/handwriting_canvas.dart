import 'dart:math' as math;
import 'package:flutter/material.dart' hide Ink;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

import 'blackboard_guidelines_painter.dart';
import 'chalk_dust_fx.dart';
import 'chalk_signature_painter.dart';
import 'stroke_notifier.dart';
import 'stroke_order_guide_painter.dart';

export 'blackboard_guidelines_painter.dart';
export 'chalk_dust_fx.dart';
export 'chalk_signature_painter.dart';
export 'stroke_notifier.dart';
export 'stroke_order_guide_painter.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color chalkboardGreen = Color(0xFF1B3B2B);
  static const Color woodFrameDark = Color(0xFF5D2E0C);
  static const Color woodFrameLight = Color(0xFF8B4513);
  static const Color woodLedge = Color(0xFF6B3611);
}

/// Classroom Blackboard Slate Canvas Widget for digital ink handwriting.
class HandwritingCanvas extends StatefulWidget {
  final Function(Ink ink) onInkUpdated;
  final VoidCallback onClear;
  final ValueChanged<int>? onStrokeCountChanged;
  final Color canvasColor;
  final Color strokeColor;
  final Color borderColor;
  final double borderWidth;
  final bool showGuidelines;
  final String? ghostText;
  final bool initialShowGuide;

  const HandwritingCanvas({
    super.key,
    required this.onInkUpdated,
    required this.onClear,
    this.onStrokeCountChanged,
    this.canvasColor = _LocalPalette.chalkboardGreen,
    this.strokeColor = Colors.white,
    this.borderColor = _LocalPalette.woodFrameLight,
    this.borderWidth = 10.0,
    this.showGuidelines = true,
    this.ghostText,
    this.initialShowGuide = false,
  });

  @override
  State<HandwritingCanvas> createState() => HandwritingCanvasState();
}

class HandwritingCanvasState extends State<HandwritingCanvas>
    with TickerProviderStateMixin {
  final StrokeNotifier _notifier = StrokeNotifier();
  bool _showGuide = false;

  // Chalk Dust Particle FX
  late AnimationController _dustController;
  List<ChalkParticle> _dustParticles = [];

  // Animated Stroke Order Guide
  late AnimationController _demoController;
  bool _isDemoActive = false;

  @override
  void initState() {
    super.initState();
    _showGuide = widget.initialShowGuide;
    _notifier.addListener(_handleStrokeChange);

    // Dust animation: 700ms puff that fades and drifts
    _dustController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Demo animation: 1800ms stroke trajectory simulation
    _demoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _demoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isDemoActive = false;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant HandwritingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ghostText != oldWidget.ghostText) {
      if (_demoController.isAnimating) {
        _demoController.stop();
        _isDemoActive = false;
      }
    }
  }

  @override
  void dispose() {
    _notifier.removeListener(_handleStrokeChange);
    _notifier.dispose();
    _dustController.dispose();
    _demoController.dispose();
    super.dispose();
  }

  void _handleStrokeChange() {
    widget.onStrokeCountChanged?.call(_notifier.strokeCount);
  }

  void clearCanvas() {
    _triggerChalkDustEffect();
    _notifier.clear();
    widget.onClear();
  }

  /// Triggers playful chalk dust particle puff effect
  void _triggerChalkDustEffect() {
    final rand = math.Random();
    _dustParticles = List.generate(30, (index) {
      final angle = rand.nextDouble() * 2 * math.pi;
      final speed = 25.0 + rand.nextDouble() * 70.0;
      return ChalkParticle(
        x: 0.25 + rand.nextDouble() * 0.5,
        y: 0.45 + rand.nextDouble() * 0.4,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 22.0, // Slight upward drift
        radius: 2.5 + rand.nextDouble() * 5.0,
        alpha: 0.55 + rand.nextDouble() * 0.45,
      );
    });
    _dustController.forward(from: 0.0);
  }

  /// Triggers animated stroke order demonstration
  void playStrokeDemo() {
    di.sl<HapticService>().selection();
    setState(() {
      _isDemoActive = true;
      _showGuide = true; // Ensure guide is visible alongside demo
    });
    _demoController.forward(from: 0.0);
  }

  void undoStroke() {
    if (_notifier.hasStrokes) {
      di.sl<HapticService>().light();
      _notifier.undoStroke();
      widget.onInkUpdated(_notifier.ink);
    }
  }

  void toggleGuide() {
    setState(() {
      _showGuide = !_showGuide;
      if (!_showGuide && _demoController.isAnimating) {
        _demoController.stop();
        _isDemoActive = false;
      }
    });
    di.sl<HapticService>().selection();
  }

  bool get hasStrokes => _notifier.hasStrokes;
  int get strokeCount => _notifier.strokeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _LocalPalette.woodFrameLight,
            _LocalPalette.woodFrameDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(widget.borderWidth),
      child: Column(
        children: [
          // Slate Canvas Area
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Chalkboard Surface with Guidelines & Ghost Guide
                  Positioned.fill(
                    child: Container(
                      color: widget.canvasColor,
                      child: CustomPaint(
                        painter: BlackboardGuidelinesPainter(
                          showGuidelines: widget.showGuidelines,
                          ghostText: _showGuide ? widget.ghostText : null,
                        ),
                      ),
                    ),
                  ),

                  // Animated Stroke Order Trajectory Guide Overlay
                  if (_isDemoActive && widget.ghostText != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _demoController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: StrokeOrderGuidePainter(
                                target: widget.ghostText!,
                                progress: _demoController.value,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Gesture Layer and Active Chalk Paint
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        // User begins drawing; pause demo guide if active so it doesn't obstruct
                        if (_isDemoActive) {
                          setState(() {
                            _isDemoActive = false;
                          });
                          _demoController.stop();
                        }
                        _notifier.startStroke(details.localPosition);
                      },
                      onPanUpdate: (details) {
                        _notifier.appendPoint(details.localPosition);
                      },
                      onPanEnd: (details) {
                        _notifier.endStroke();
                        widget.onInkUpdated(_notifier.ink);
                      },
                      child: ListenableBuilder(
                        listenable: _notifier,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: ChalkSignaturePainter(
                              _notifier.strokes,
                              widget.strokeColor,
                              _notifier.revision,
                            ),
                            size: Size.infinite,
                          );
                        },
                      ),
                    ),
                  ),

                  // Playful Chalk Dust Particle FX Overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _dustController,
                        builder: (context, _) {
                          if (!_dustController.isAnimating &&
                              _dustController.value == 0.0) {
                            return const SizedBox.shrink();
                          }
                          return CustomPaint(
                            painter: ChalkDustPainter(
                              particles: _dustParticles,
                              progress: _dustController.value,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Classroom Slate Chalk Ledge / Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _LocalPalette.woodLedge,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: ListenableBuilder(
              listenable: _notifier,
              builder: (context, _) {
                final hasStrokes = _notifier.hasStrokes;

                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Tools (Trace & Demo)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Guide / Trace toggle button (if ghostText provided)
                          if (widget.ghostText != null &&
                              widget.ghostText!.trim().isNotEmpty) ...[
                            Semantics(
                              button: true,
                              label: _showGuide
                                  ? 'Hide tracing guide'
                                  : 'Show tracing guide',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: toggleGuide,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _showGuide
                                          ? Colors.amber.withValues(alpha: 0.25)
                                          : Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _showGuide
                                            ? Colors.amber.withValues(alpha: 0.6)
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.sparkles,
                                          size: 13,
                                          color: _showGuide
                                              ? Colors.amber
                                              : Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Trace',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _showGuide
                                                ? Colors.amber
                                                : Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Animated Stroke Order Demo Button
                            const SizedBox(width: 6),
                            Semantics(
                              button: true,
                              label: 'Watch how to draw this stroke or letter',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: playStrokeDemo,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isDemoActive
                                          ? Colors.lightBlue.withValues(
                                              alpha: 0.28,
                                            )
                                          : Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _isDemoActive
                                            ? Colors.lightBlue.withValues(
                                                alpha: 0.7,
                                              )
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isDemoActive
                                              ? LucideIcons.playCircle
                                              : LucideIcons.play,
                                          size: 13,
                                          color: _isDemoActive
                                              ? Colors.lightBlueAccent
                                              : Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Demo',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _isDemoActive
                                                ? Colors.lightBlueAccent
                                                : Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(width: 12),

                      // Right Actions (Undo & Clear)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Undo (Eraser) button
                          Semantics(
                            button: true,
                            label: 'Undo last stroke',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: hasStrokes ? undoStroke : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.undo2,
                                        size: 15,
                                        color: hasStrokes
                                            ? Colors.amber
                                            : Colors.white.withValues(
                                                alpha: 0.25,
                                              ),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Undo',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: hasStrokes
                                              ? Colors.white
                                              : Colors.white.withValues(
                                                  alpha: 0.25,
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 4),

                          // Clear (Duster) button with dust puff FX
                          Semantics(
                            button: true,
                            label: 'Clear chalkboard with chalk dust',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: hasStrokes
                                    ? () {
                                        di.sl<HapticService>().selection();
                                        clearCanvas();
                                      }
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.trash2,
                                        size: 15,
                                        color: hasStrokes
                                            ? AppColors.gameIncorrect
                                            : Colors.white.withValues(
                                                alpha: 0.25,
                                              ),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Clear',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: hasStrokes
                                              ? Colors.white
                                              : Colors.white.withValues(
                                                  alpha: 0.25,
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

