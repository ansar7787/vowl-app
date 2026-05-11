import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

/// Factory that maps `visual_config.painter_type` strings to actual
/// animated background widgets for quest screens.
class VisualConfigBackground extends StatelessWidget {
  final VisualConfig config;

  const VisualConfigBackground({super.key, required this.config});

  Color get _primaryColor {
    try {
      return Color(int.parse(config.primaryColor));
    } catch (_) {
      return const Color(0xFF03A9F4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: _buildPainter(),
    );
  }

  Widget _buildPainter() {
    switch (config.painterType) {
      case 'FrequencyLockSync':
        return _FrequencyLockWidget(color: _primaryColor, intensity: config.pulseIntensity);
      case 'DataLogSync':
        return _DataLogWidget(color: _primaryColor, intensity: config.pulseIntensity);
      case 'NeuralNegotiationSync':
        return _NeuralNetworkWidget(color: _primaryColor, intensity: config.pulseIntensity);
      case 'ArchiveDecryptSync':
        return _ArchiveDecryptWidget(color: _primaryColor, intensity: config.pulseIntensity);
      case 'CouncilHallSync':
        return _CouncilHallWidget(color: _primaryColor, intensity: config.pulseIntensity);
      case 'PurgeGridSync':
        return _PurgeGridWidget(color: _primaryColor, intensity: config.pulseIntensity);
      case 'VocabNexusSync':
        return _VocabNexusWidget(color: _primaryColor, intensity: config.pulseIntensity);
      case 'BlueprintGridSync':
        return _BlueprintGridWidget(color: _primaryColor, intensity: config.pulseIntensity);
      case 'SonarScanSync':
        return _SonarScanWidget(color: _primaryColor, intensity: config.pulseIntensity);
      case 'MechanicalLinkSync':
        return _MechanicalLinkWidget(color: _primaryColor, intensity: config.pulseIntensity);
      case 'MagneticFieldSync':
        return _MagneticFieldWidget(color: _primaryColor, intensity: config.pulseIntensity);
      case 'SemanticAuraSync':
        return _SemanticAuraWidget(color: _primaryColor, intensity: config.pulseIntensity);
      case 'ValidatorMatrixSync':
        return _ValidatorMatrixWidget(color: _primaryColor, intensity: config.pulseIntensity);
      default:
        return _DataLogWidget(color: _primaryColor, intensity: config.pulseIntensity);
    }
  }
}

// ============================================================
// 1. FrequencyLockSync — Oscillating sine waves (Accent category)
// ============================================================
class _FrequencyLockWidget extends StatefulWidget {
  final Color color;
  final double intensity;
  const _FrequencyLockWidget({required this.color, required this.intensity});

  @override
  State<_FrequencyLockWidget> createState() => _FrequencyLockWidgetState();
}

class _FrequencyLockWidgetState extends State<_FrequencyLockWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (4000 / widget.intensity).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _FrequencyLockPainter(
            color: widget.color,
            phase: _controller.value * 2 * pi,
            intensity: widget.intensity,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _FrequencyLockPainter extends CustomPainter {
  final Color color;
  final double phase;
  final double intensity;

  _FrequencyLockPainter({required this.color, required this.phase, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.06 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int w = 0; w < 3; w++) {
      final path = Path();
      final yCenter = size.height * (0.3 + w * 0.2);
      path.moveTo(0, yCenter);
      for (double x = 0; x <= size.width; x += 2) {
        final y = yCenter + sin((x / size.width * 4 * pi) + phase + w) * 20 * intensity;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FrequencyLockPainter old) => old.phase != phase;
}

// ============================================================
// 2. DataLogSync — Scrolling horizontal scan lines
// ============================================================
class _DataLogWidget extends StatefulWidget {
  final Color color;
  final double intensity;
  const _DataLogWidget({required this.color, required this.intensity});

  @override
  State<_DataLogWidget> createState() => _DataLogWidgetState();
}

class _DataLogWidgetState extends State<_DataLogWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _DataLogPainter(
            color: widget.color,
            offset: _controller.value,
            intensity: widget.intensity,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _DataLogPainter extends CustomPainter {
  final Color color;
  final double offset;
  final double intensity;

  _DataLogPainter({required this.color, required this.offset, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.04 * intensity)
      ..strokeWidth = 0.5;

    final spacing = 24.0;
    final totalLines = (size.height / spacing).ceil() + 1;

    for (int i = 0; i < totalLines; i++) {
      final y = (i * spacing + offset * spacing) % size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Scan line
    final scanY = offset * size.height;
    final scanPaint = Paint()
      ..color = color.withValues(alpha: 0.12 * intensity)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scanPaint);
  }

  @override
  bool shouldRepaint(covariant _DataLogPainter old) => old.offset != offset;
}

// ============================================================
// 3. NeuralNegotiationSync — Floating connected nodes
// ============================================================
class _NeuralNetworkWidget extends StatefulWidget {
  final Color color;
  final double intensity;
  const _NeuralNetworkWidget({required this.color, required this.intensity});

  @override
  State<_NeuralNetworkWidget> createState() => _NeuralNetworkWidgetState();
}

class _NeuralNetworkWidgetState extends State<_NeuralNetworkWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Node> _nodes = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    final rng = Random(42);
    for (int i = 0; i < 12; i++) {
      _nodes.add(_Node(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        dx: (rng.nextDouble() - 0.5) * 0.02,
        dy: (rng.nextDouble() - 0.5) * 0.02,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _NeuralNetworkPainter(
            color: widget.color,
            nodes: _nodes,
            t: _controller.value,
            intensity: widget.intensity,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Node {
  double x, y, dx, dy;
  _Node({required this.x, required this.y, required this.dx, required this.dy});
}

class _NeuralNetworkPainter extends CustomPainter {
  final Color color;
  final List<_Node> nodes;
  final double t;
  final double intensity;

  _NeuralNetworkPainter({
    required this.color,
    required this.nodes,
    required this.t,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = color.withValues(alpha: 0.15 * intensity);
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.05 * intensity)
      ..strokeWidth = 0.5;

    final positions = nodes.map((n) {
      final x = ((n.x + n.dx * t * 50) % 1.0) * size.width;
      final y = ((n.y + n.dy * t * 50) % 1.0) * size.height;
      return Offset(x, y);
    }).toList();

    // Draw connections
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final dist = (positions[i] - positions[j]).distance;
        if (dist < size.width * 0.3) {
          canvas.drawLine(positions[i], positions[j], linePaint);
        }
      }
    }

    // Draw nodes
    for (final pos in positions) {
      canvas.drawCircle(pos, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralNetworkPainter old) => old.t != t;
}

// ============================================================
// 4. ArchiveDecryptSync — Fading grid pattern
// ============================================================
class _ArchiveDecryptWidget extends StatefulWidget {
  final Color color;
  final double intensity;
  const _ArchiveDecryptWidget({required this.color, required this.intensity});

  @override
  State<_ArchiveDecryptWidget> createState() => _ArchiveDecryptWidgetState();
}

class _ArchiveDecryptWidgetState extends State<_ArchiveDecryptWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ArchiveDecryptPainter(
            color: widget.color,
            t: _controller.value,
            intensity: widget.intensity,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ArchiveDecryptPainter extends CustomPainter {
  final Color color;
  final double t;
  final double intensity;

  _ArchiveDecryptPainter({required this.color, required this.t, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.03 * intensity);
    final cellSize = 40.0;
    final cols = (size.width / cellSize).ceil();
    final rows = (size.height / cellSize).ceil();

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final phase = sin(t * 2 * pi + r * 0.3 + c * 0.5);
        if (phase > 0.3) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize + 1, r * cellSize + 1, cellSize - 2, cellSize - 2),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArchiveDecryptPainter old) => old.t != t;
}

// ============================================================
// 5. CouncilHallSync — Radial pulse glow
// ============================================================
class _CouncilHallWidget extends StatefulWidget {
  final Color color;
  final double intensity;
  const _CouncilHallWidget({required this.color, required this.intensity});

  @override
  State<_CouncilHallWidget> createState() => _CouncilHallWidgetState();
}

class _CouncilHallWidgetState extends State<_CouncilHallWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _CouncilHallPainter(
            color: widget.color,
            t: _controller.value,
            intensity: widget.intensity,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _CouncilHallPainter extends CustomPainter {
  final Color color;
  final double t;
  final double intensity;

  _CouncilHallPainter({required this.color, required this.t, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    final maxRadius = size.width * 0.6;

    for (int i = 0; i < 3; i++) {
      final phase = (t + i * 0.33) % 1.0;
      final radius = phase * maxRadius;
      final opacity = (1.0 - phase) * 0.08 * intensity;
      final paint = Paint()
        ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CouncilHallPainter old) => old.t != t;
}

// ============================================================
// 6. PurgeGridSync — Horizontal scan grid with red pulse
// ============================================================
class _PurgeGridWidget extends StatefulWidget {
  final Color color;
  final double intensity;
  const _PurgeGridWidget({required this.color, required this.intensity});

  @override
  State<_PurgeGridWidget> createState() => _PurgeGridWidgetState();
}

class _PurgeGridWidgetState extends State<_PurgeGridWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _PurgeGridPainter(
            color: widget.color,
            t: _controller.value,
            intensity: widget.intensity,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _PurgeGridPainter extends CustomPainter {
  final Color color;
  final double t;
  final double intensity;

  _PurgeGridPainter({required this.color, required this.t, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    // Vertical grid lines
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.03 * intensity)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Horizontal sweep
    final sweepY = t * size.height;
    final sweepHeight = 60.0 * intensity;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.08 * intensity),
        color.withValues(alpha: 0.0),
      ],
    );

    final rect = Rect.fromLTWH(0, sweepY - sweepHeight / 2, size.width, sweepHeight);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }
 
  @override
  bool shouldRepaint(covariant _PurgeGridPainter old) => old.t != t;
}

// ============================================================
// 7. VocabNexusSync — Molecular bonding / Circuit paths (Vocabulary category)
// ============================================================
class _VocabNexusWidget extends StatefulWidget {
  final Color color;
  final double intensity;
  const _VocabNexusWidget({required this.color, required this.intensity});

  @override
  State<_VocabNexusWidget> createState() => _VocabNexusWidgetState();
}

class _VocabNexusWidgetState extends State<_VocabNexusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _VocabNexusPainter(
              color: widget.color,
              t: _controller.value,
              intensity: widget.intensity,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _VocabNexusPainter extends CustomPainter {
  final Color color;
  final double t;
  final double intensity;

  _VocabNexusPainter({required this.color, required this.t, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final rng = Random(42);

    // Draw hex-grid connections
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + (t * 2 * pi * 0.1);
      final p1 = center + Offset(cos(angle) * 100, sin(angle) * 100);
      final p2 = center + Offset(cos(angle + pi / 4) * 150, sin(angle + pi / 4) * 150);
      
      canvas.drawLine(p1, p2, paint);
      
      // Pulsing nodes
      final pulse = (sin(t * 2 * pi + i) + 1) / 2;
      final nodePaint = Paint()..color = color.withValues(alpha: 0.1 * pulse * intensity);
      canvas.drawCircle(p1, 4 * pulse, nodePaint);
    }

    // Circuit paths
    final circuitPaint = Paint()
      ..color = color.withValues(alpha: 0.03 * intensity)
      ..strokeWidth = 0.5;
      
    for (int j = 0; j < 5; j++) {
      final startX = rng.nextDouble() * size.width;
      final startY = (t * size.height + j * 100) % size.height;
      canvas.drawLine(Offset(startX, startY), Offset(startX + 50, startY + 50), circuitPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VocabNexusPainter old) => old.t != t;
}

// ============================================================
// 8. BlueprintGridSync — drafting layout for Ink Analysis
// ============================================================
class _BlueprintGridWidget extends StatefulWidget {
  final Color color;
  final double intensity;
  const _BlueprintGridWidget({required this.color, required this.intensity});
  @override
  State<_BlueprintGridWidget> createState() => _BlueprintGridWidgetState();
}

class _BlueprintGridWidgetState extends State<_BlueprintGridWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _BlueprintGridPainter(color: widget.color, t: _controller.value, intensity: widget.intensity),
        size: Size.infinite,
      ),
    );
  }
}

class _BlueprintGridPainter extends CustomPainter {
  final Color color;
  final double t;
  final double intensity;
  _BlueprintGridPainter({required this.color, required this.t, required this.intensity});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.04 * intensity)..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final diagPaint = Paint()..color = color.withValues(alpha: 0.02 * intensity)..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), diagPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), diagPaint);
  }
  @override
  bool shouldRepaint(covariant _BlueprintGridPainter old) => old.t != t;
}

// ============================================================
// 9. SonarScanSync — expanding radial sonar rings for Radar
// ============================================================
class _SonarScanWidget extends StatefulWidget {
  final Color color;
  final double intensity;
  const _SonarScanWidget({required this.color, required this.intensity});
  @override
  State<_SonarScanWidget> createState() => _SonarScanWidgetState();
}

class _SonarScanWidgetState extends State<_SonarScanWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _SonarScanPainter(color: widget.color, t: _controller.value, intensity: widget.intensity),
        size: Size.infinite,
      ),
    );
  }
}

class _SonarScanPainter extends CustomPainter {
  final Color color;
  final double t;
  final double intensity;
  _SonarScanPainter({required this.color, required this.t, required this.intensity});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width;
    for (int i = 0; i < 4; i++) {
      final phase = (t + i * 0.25) % 1.0;
      final paint = Paint()
        ..color = color.withValues(alpha: (1.0 - phase) * 0.1 * intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, phase * maxRadius, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _SonarScanPainter old) => old.t != t;
}

// ============================================================
// 10. MechanicalLinkSync — Gears and rivets for Chain
// ============================================================
class _MechanicalLinkWidget extends StatefulWidget {
  final Color color;
  final double intensity;
  const _MechanicalLinkWidget({required this.color, required this.intensity});
  @override
  State<_MechanicalLinkWidget> createState() => _MechanicalLinkWidgetState();
}

class _MechanicalLinkWidgetState extends State<_MechanicalLinkWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _MechanicalLinkPainter(color: widget.color, t: _controller.value, intensity: widget.intensity),
        size: Size.infinite,
      ),
    );
  }
}

class _MechanicalLinkPainter extends CustomPainter {
  final Color color;
  final double t;
  final double intensity;
  _MechanicalLinkPainter({required this.color, required this.t, required this.intensity});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.05 * intensity)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final center = Offset(size.width * 0.9, size.height * 0.1);
    final radius = 80.0;
    canvas.drawCircle(center, radius, paint);
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + (t * 2 * pi);
      canvas.drawLine(center + Offset(cos(angle) * radius, sin(angle) * radius), center + Offset(cos(angle) * (radius + 20), sin(angle) * (radius + 20)), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _MechanicalLinkPainter old) => old.t != t;
}

// ============================================================
// 11. MagneticFieldSync — Flux lines for Bubbles
// ============================================================
class _MagneticFieldWidget extends StatefulWidget {
  final Color color;
  final double intensity;
  const _MagneticFieldWidget({required this.color, required this.intensity});
  @override
  State<_MagneticFieldWidget> createState() => _MagneticFieldWidgetState();
}

class _MagneticFieldWidgetState extends State<_MagneticFieldWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _MagneticFieldPainter(color: widget.color, t: _controller.value, intensity: widget.intensity),
        size: Size.infinite,
      ),
    );
  }
}

class _MagneticFieldPainter extends CustomPainter {
  final Color color;
  final double t;
  final double intensity;
  _MagneticFieldPainter({required this.color, required this.t, required this.intensity});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.06 * intensity)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    for (int i = 0; i < 5; i++) {
      final path = Path();
      final yStart = size.height * (0.2 + i * 0.15);
      path.moveTo(0, yStart);
      path.quadraticBezierTo(size.width / 2, yStart + sin(t * 2 * pi + i) * 50, size.width, yStart);
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _MagneticFieldPainter old) => old.t != t;
}

// ============================================================
// 12. SemanticAuraSync — Glowing nebula for Echo
// ============================================================
class _SemanticAuraWidget extends StatefulWidget {
  final Color color;
  final double intensity;
  const _SemanticAuraWidget({required this.color, required this.intensity});
  @override
  State<_SemanticAuraWidget> createState() => _SemanticAuraWidgetState();
}

class _SemanticAuraWidgetState extends State<_SemanticAuraWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _SemanticAuraPainter(color: widget.color, t: _controller.value, intensity: widget.intensity),
        size: Size.infinite,
      ),
    );
  }
}

class _SemanticAuraPainter extends CustomPainter {
  final Color color;
  final double t;
  final double intensity;
  _SemanticAuraPainter({required this.color, required this.t, required this.intensity});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.5 + t * 0.2,
      colors: [color.withValues(alpha: 0.1 * intensity), Colors.transparent],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }
  @override
  bool shouldRepaint(covariant _SemanticAuraPainter old) => old.t != t;
}

// ============================================================
// 13. ValidatorMatrixSync — Terminal grid for Slot
// ============================================================
class _ValidatorMatrixWidget extends StatefulWidget {
  final Color color;
  final double intensity;
  const _ValidatorMatrixWidget({required this.color, required this.intensity});
  @override
  State<_ValidatorMatrixWidget> createState() => _ValidatorMatrixWidgetState();
}

class _ValidatorMatrixWidgetState extends State<_ValidatorMatrixWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _ValidatorMatrixPainter(color: widget.color, t: _controller.value, intensity: widget.intensity),
        size: Size.infinite,
      ),
    );
  }
}

class _ValidatorMatrixPainter extends CustomPainter {
  final Color color;
  final double t;
  final double intensity;
  _ValidatorMatrixPainter({required this.color, required this.t, required this.intensity});
  @override
  void paint(Canvas canvas, Size size) {
    for (double y = 0; y < size.height; y += 30) {
      final alpha = (sin(t * 2 * pi + y) + 1) / 2 * 0.05 * intensity;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), Paint()..color = color.withValues(alpha: alpha)..strokeWidth = 0.5);
    }
  }
  @override
  bool shouldRepaint(covariant _ValidatorMatrixPainter old) => old.t != t;
}
