import 'dart:math' as math;
import 'package:flutter/material.dart';

class KidsBackgroundRenderer extends StatefulWidget {
  final String painterName;
  final String shaderName;
  final Color primaryColor;
  final String gameType;

  const KidsBackgroundRenderer({
    super.key,
    required this.painterName,
    required this.shaderName,
    required this.primaryColor,
    required this.gameType,
  });

  @override
  State<KidsBackgroundRenderer> createState() => _KidsBackgroundRendererState();
}

class _KidsBackgroundRendererState extends State<KidsBackgroundRenderer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_Particle> _particles = [];
  bool _isDark = false;
  late _BackgroundThemeConfig _config;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // A single controller drives all background animations, replacing 20+ individual controllers.
    // Extremely performant for low-end devices.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_initialized || isDark != _isDark) {
      _isDark = isDark;
      _config = _resolveThemeConfig(isDark);
      _generateParticles();
      _initialized = true;
    }
  }

  @override
  void didUpdateWidget(KidsBackgroundRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.painterName != widget.painterName ||
        oldWidget.gameType != widget.gameType) {
      _config = _resolveThemeConfig(_isDark);
      _generateParticles();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateParticles() {
    final random = math.Random(widget.gameType.hashCode ^ widget.painterName.hashCode);
    _particles = List.generate(_config.particleCount, (i) {
      final isEmoji = _config.emojis != null && _config.emojis!.isNotEmpty;
      final isIcon = _config.icon != null;
      
      TextPainter? textPainter;
      
      if (isEmoji) {
        final emoji = _config.emojis![random.nextInt(_config.emojis!.length)];
        textPainter = TextPainter(
          text: TextSpan(text: emoji, style: TextStyle(fontSize: 20 + random.nextDouble() * 20)),
          textDirection: TextDirection.ltr,
        )..layout();
      } else if (isIcon) {
        textPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(_config.icon!.codePoint),
            style: TextStyle(
              fontSize: 20 + random.nextDouble() * 20,
              fontFamily: _config.icon!.fontFamily,
              package: _config.icon!.fontPackage,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
      }

      return _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        // Gentle drift speeds
        speedX: (random.nextDouble() - 0.5) * 0.05,
        speedY: (random.nextDouble() - 0.5) * 0.05 + _config.baseSpeedY,
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.5,
        size: 10 + random.nextDouble() * 30,
        textPainter: textPainter,
        isBubble: _config.isBubble,
        isCrispShape: _config.drawCrispShapes,
        shapeType: random.nextInt(4),
      );
    });
  }

  _BackgroundThemeConfig _resolveThemeConfig(bool isDark) {
    switch (widget.painterName) {
      case 'SunnyMeadow':
        return _BackgroundThemeConfig(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [const Color(0xFF87CEEB), const Color(0xFFE0F7FA)],
          ),
          emojis: const ['☀️', '☁️', '🌸', '🦋'],
          particleCount: 15,
        );
      case 'OceanWave':
        return _BackgroundThemeConfig(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
          ),
          isBubble: true,
          baseSpeedY: -0.1, // Bubbles float up faster
          particleCount: 20,
        );
      case 'CandyCloud':
        return _BackgroundThemeConfig(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF831843), const Color(0xFF500724)]
                : [const Color(0xFFFFC0CB), const Color(0xFFF8BBD0)],
          ),
          emojis: const ['🍭', '🍬', '☁️', '🍦'],
          particleCount: 15,
        );
      case 'ForestFriend':
        return _BackgroundThemeConfig(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF064E3B), const Color(0xFF022C22)]
                : [const Color(0xFF388E3C), const Color(0xFFC8E6C9)],
          ),
          icon: Icons.eco_rounded,
          particleCount: 20,
        );
      case 'StarryNight':
        return _BackgroundThemeConfig(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                : [const Color(0xFF1A237E), const Color(0xFF3949AB)],
          ),
          icon: Icons.star_rounded,
          particleCount: 25,
        );
      case 'KidsWorldBackground':
      case 'AlphabetGarden':
      case 'NumbersNebula':
      case 'NatureNook':
      default:
        // Clean, Soft "Sky/Cloud" Kids Aesthetic (Perfect for White Cards)
        return _BackgroundThemeConfig(
          isDark: isDark,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [const Color(0xFF1E3A8A), const Color(0xFF172554)] // Deep playful Navy
                : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)], // Very soft Sky Blue
          ),
          drawPlayfulBlobs: true,
          drawCrispShapes: true,
          particleCount: 15, // Re-enabled particles but as crisp hollow shapes
        );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _config.gradient,
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ParticleBackgroundPainter(
            animation: _controller,
            particles: _particles,
            config: _config,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _BackgroundThemeConfig {
  final bool isDark;
  final Gradient? gradient;
  final bool drawPlayfulBlobs;
  final bool drawCrispShapes;
  final List<String>? emojis;
  final IconData? icon;
  final bool isBubble;
  final double baseSpeedY;
  final int particleCount;

  _BackgroundThemeConfig({
    this.isDark = false,
    this.gradient,
    this.drawPlayfulBlobs = false,
    this.drawCrispShapes = false,
    this.emojis,
    this.icon,
    this.isBubble = false,
    this.baseSpeedY = 0.0,
    this.particleCount = 12,
  });
}

class _Particle {
  final double x;
  final double y;
  final double speedX;
  final double speedY;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final TextPainter? textPainter;
  final bool isBubble;
  final bool isCrispShape;
  final int shapeType;

  _Particle({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    this.textPainter,
    this.isBubble = false,
    this.isCrispShape = false,
    this.shapeType = 0,
  });
}

class _ParticleBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_Particle> particles;
  final _BackgroundThemeConfig config;

  _ParticleBackgroundPainter({
    required this.animation,
    required this.particles,
    required this.config,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final time = animation.value * 120.0; // 120 seconds cycle

    if (config.drawPlayfulBlobs) {
      _drawPlayfulBlobs(canvas, size, time);
    }

    for (final p in particles) {
      // Calculate current normalized position with wrap-around
      double cx = (p.x + p.speedX * time) % 1.0;
      if (cx < 0) cx += 1.0;
      
      double cy = (p.y + p.speedY * time) % 1.0;
      if (cy < 0) cy += 1.0;

      final currentRotation = p.rotation + p.rotationSpeed * time;

      // Map to screen coordinates
      final dx = cx * size.width;
      final dy = cy * size.height;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(currentRotation);

      // Subtle pulsating alpha based on time and particle identity
      final alpha = 0.3 + 0.2 * math.sin(time * 2 + p.x * 10);

      if (p.textPainter != null) {
        // We cannot easily change alpha of pre-laid out TextPainter containing emojis,
        // but Emojis as background elements are fine fully opaque if small, 
        // or we can just render them.
        p.textPainter!.paint(
          canvas,
          Offset(-p.textPainter!.width / 2, -p.textPainter!.height / 2),
        );
      } else if (p.isCrispShape) {
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.white.withValues(alpha: alpha * 0.7); // Crisp white outlines
        
        if (p.shapeType == 0) {
           canvas.drawCircle(Offset.zero, p.size / 2, paint);
        } else if (p.shapeType == 1) {
           canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size), paint);
        } else if (p.shapeType == 2) {
           final path = Path()
             ..moveTo(0, -p.size/2)
             ..lineTo(p.size/2, p.size/2)
             ..lineTo(-p.size/2, p.size/2)
             ..close();
           canvas.drawPath(path, paint);
        } else {
           canvas.drawLine(Offset(0, -p.size/2), Offset(0, p.size/2), paint);
           canvas.drawLine(Offset(-p.size/2, 0), Offset(p.size/2, 0), paint);
        }
      } else if (p.isBubble) {
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.white.withValues(alpha: alpha);
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }
      canvas.restore();
    }
  }

  void _drawPlayfulBlobs(Canvas canvas, Size size, double time) {
    // Slow orbit using time (which goes from 0 to 120)
    final orbit1 = time * math.pi * 2 / 60; // 60s period
    final orbit2 = time * math.pi * 2 / 45; // 45s period
    final orbit3 = time * math.pi * 2 / 80; // 80s period
    
    final paint1 = Paint()
      ..color = (config.isDark ? const Color(0xFF3B82F6) : Colors.white).withValues(alpha: config.isDark ? 0.15 : 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    final pos1 = Offset(
      size.width * 0.5 + math.cos(orbit1) * size.width * 0.3,
      size.height * 0.5 + math.sin(orbit1) * size.height * 0.2,
    );
    canvas.drawCircle(pos1, size.width * 0.5, paint1);

    final paint2 = Paint()
      ..color = (config.isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7DD3FC)).withValues(alpha: config.isDark ? 0.15 : 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    final pos2 = Offset(
      size.width * 0.5 + math.sin(orbit2) * size.width * 0.4,
      size.height * 0.5 + math.cos(orbit2) * size.height * 0.3,
    );
    canvas.drawCircle(pos2, size.width * 0.6, paint2);
    
    final paint3 = Paint()
      ..color = (config.isDark ? const Color(0xFF0EA5E9) : Colors.white).withValues(alpha: config.isDark ? 0.15 : 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);
    final pos3 = Offset(
      size.width * 0.5 + math.cos(orbit3) * size.width * 0.25,
      size.height * 0.5 + math.sin(orbit3) * size.height * 0.4,
    );
    canvas.drawCircle(pos3, size.width * 0.4, paint3);
  }

  @override
  bool shouldRepaint(covariant _ParticleBackgroundPainter oldDelegate) => true;
}
