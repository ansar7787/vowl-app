import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Buddy head, used ONLY as the profile avatar on slide 4.
const String kVowlyHead = 'assets/images/vowly_head.webp';

/// Every illustration is authored on a 360×320 stage. Each slide is a stack of
/// full-stage SVG layers (`assets/illustrations/onb_<slide>_<layer>.svg`), so a
/// layer can be floated / faded / scaled without any coordinate bookkeeping.
const double kStageW = 360, kStageH = 320;
const String _dir = 'assets/illustrations/onb_';

// ── helpers ────────────────────────────────────────────────────────────────

/// Eased 0‥1 progress of [a] between [begin] and [end].
double _seg(
  Animation<double> a,
  double begin,
  double end, [
  Curve curve = Curves.easeOutCubic,
]) {
  final t = ((a.value - begin) / (end - begin)).clamp(0.0, 1.0);
  return curve.transform(t);
}

/// Seamlessly looping sine (integer [cycles] → no seam at the loop point).
double _wave(Animation<double> a, [double cycles = 1]) =>
    math.sin(a.value * cycles * 2 * math.pi);

class _Layer extends StatelessWidget {
  const _Layer(this.scene, this.name);
  final String scene, name;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    '$_dir${scene}_$name.svg',
    width: kStageW,
    height: kStageH,
    fit: BoxFit.contain,
  );
}

/// A static layer.
Widget _still(String scene, String name) =>
    Positioned.fill(child: _Layer(scene, name));

/// An animated layer: the SVG widget is built once (as [AnimatedBuilder.child]);
/// only the cheap transform/opacity wrapper rebuilds per frame.
Widget _fx(
  Listenable anim,
  String scene,
  String name,
  Widget Function(Widget child) wrap,
) => Positioned.fill(
  child: AnimatedBuilder(
    animation: anim,
    child: _Layer(scene, name),
    builder: (context, child) => wrap(child!),
  ),
);

Widget _fade(double o, Widget c) =>
    Opacity(opacity: o.clamp(0.0, 1.0), child: c);
Widget _shift(double dx, double dy, Widget c) =>
    Transform.translate(offset: Offset(dx, dy), child: c);
Widget _scaleAt(double px, double py, double s, Widget c) => Transform.scale(
  scale: s,
  alignment: Alignment(px / (kStageW / 2) - 1, py / (kStageH / 2) - 1),
  child: c,
);
Widget _rotateAt(double px, double py, double a, Widget c) => Transform.rotate(
  angle: a,
  alignment: Alignment(px / (kStageW / 2) - 1, py / (kStageH / 2) - 1),
  child: c,
);

// ── public widget ──────────────────────────────────────────────────────────

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.index,
    required this.entrance,
    required this.ambient,
  });

  final int index;

  /// 0→1 once when the slide becomes active (accents appear).
  final Animation<double> entrance;

  /// 0→1 looping forever (gentle floating / pulsing). Shared by all slides.
  final Animation<double> ambient;

  static const labels = [
    'Illustration: a microphone with sound waves, speech bubbles and a word-puzzle tile',
    'Illustration: a phone camera scanning a plant, next to an open book and a vocabulary card',
    'Illustration: an open sticker album with a medal, gift, hat and sunglasses rewards',
    'Illustration: a progress dashboard with a bar chart, progress ring and a globe',
  ];

  @override
  Widget build(BuildContext context) {
    final scene = switch (index) {
      0 => _SpeechScene(entrance: entrance, ambient: ambient),
      1 => _ScanScene(entrance: entrance, ambient: ambient),
      2 => _RewardsScene(entrance: entrance, ambient: ambient),
      _ => _ProgressScene(entrance: entrance, ambient: ambient),
    };
    return Semantics(
      image: true,
      label: labels[index],
      excludeSemantics: true,
      child: FittedBox(
        child: SizedBox(
          width: kStageW,
          height: kStageH,
          child: RepaintBoundary(child: scene),
        ),
      ),
    );
  }
}

// ── Slide 1 · speech ───────────────────────────────────────────────────────

class _SpeechScene extends StatelessWidget {
  const _SpeechScene({required this.entrance, required this.ambient});
  final Animation<double> entrance, ambient;

  @override
  Widget build(BuildContext context) {
    final both = Listenable.merge([entrance, ambient]);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _still('speech', 'base'),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: both,
            builder: (context, _) => CustomPaint(
              painter: _RingsPainter(
                center: const Offset(180, 124),
                t: ambient.value,
                visible: _seg(entrance, .05, .4),
              ),
            ),
          ),
        ),
        _fx(both, 'speech', 'mic', (c) {
          final e = _seg(entrance, 0, .35);
          return _shift(0, _wave(ambient) * 4 + (1 - e) * 10, _fade(e, c));
        }),
        _fx(both, 'speech', 'bubbleA', (c) {
          final e = _seg(entrance, .1, .45, Curves.easeOutBack);
          return _fade(e, _scaleAt(106, 112, .6 + .4 * e, c));
        }),
        _fx(both, 'speech', 'bubbleB', (c) {
          final e = _seg(entrance, .18, .55, Curves.easeOutBack);
          return _fade(e, _scaleAt(254, 112, .6 + .4 * e, c));
        }),
        _fx(both, 'speech', 'puzzle', (c) {
          final e = _seg(entrance, .25, .65);
          return _fade(e, _shift(0, (1 - e) * 14 + _wave(ambient) * 3, c));
        }),
        _fx(both, 'speech', 'tile', (c) {
          final e = _seg(entrance, .3, .7);
          return _fade(e, _shift(0, (1 - e) * 14 - _wave(ambient) * 3, c));
        }),
      ],
    );
  }
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter({
    required this.center,
    required this.t,
    required this.visible,
  });
  final Offset center;
  final double t, visible;

  @override
  void paint(Canvas canvas, Size size) {
    if (visible <= 0) return;
    for (var i = 0; i < 3; i++) {
      final p = (t * 2 + i / 3) % 1.0; // 2 expansions per 6 s loop → no seam
      canvas.drawCircle(
        center,
        46 + p * 48,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(
            0xFF8B5CF6,
          ).withValues(alpha: (1 - p) * .5 * visible),
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter o) => o.t != t || o.visible != visible;
}

// ── Slide 2 · scan ─────────────────────────────────────────────────────────

class _ScanScene extends StatelessWidget {
  const _ScanScene({required this.entrance, required this.ambient});
  final Animation<double> entrance, ambient;

  static const _frame = Rect.fromLTWH(142, 74, 76, 152);

  @override
  Widget build(BuildContext context) {
    final both = Listenable.merge([entrance, ambient]);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _still('scan', 'base'),
        _fx(both, 'scan', 'phone', (c) => _shift(0, _wave(ambient) * 3, c)),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: both,
            builder: (context, _) => Transform.translate(
              offset: Offset(0, _wave(ambient) * 3), // rides with the phone
              child: CustomPaint(
                painter: _ScanPainter(
                  frame: _frame,
                  t: ambient.value,
                  visible: _seg(entrance, 0, .25),
                ),
              ),
            ),
          ),
        ),
        _fx(both, 'scan', 'book', (c) {
          final e = _seg(entrance, .1, .5);
          return _fade(e, _shift(-(1 - e) * 16, 0, c));
        }),
        _fx(both, 'scan', 'cardPlant', (c) {
          final e = _seg(entrance, .2, .6);
          return _fade(e, _shift(0, (1 - e) * 12 + _wave(ambient) * 2, c));
        }),
        _fx(both, 'scan', 'chipOffline', (c) {
          final e = _seg(entrance, .3, .65);
          return _fade(e, _shift(0, (1 - e) * 6, c));
        }),
        _fx(both, 'scan', 'chipLangs', (c) {
          final e = _seg(entrance, .38, .72);
          return _fade(e, _shift(0, (1 - e) * 6, c));
        }),
      ],
    );
  }
}

class _ScanPainter extends CustomPainter {
  const _ScanPainter({
    required this.frame,
    required this.t,
    required this.visible,
  });
  final Rect frame;
  final double t, visible;

  @override
  void paint(Canvas canvas, Size size) {
    if (visible <= 0) return;

    // Brackets converge and relax.
    final r = frame.inflate(7 * (.5 + .5 * math.cos(t * 2 * math.pi)));
    const len = 18.0;
    final path = Path()
      ..moveTo(r.left, r.top + len)
      ..lineTo(r.left, r.top)
      ..lineTo(r.left + len, r.top)
      ..moveTo(r.right - len, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.top + len)
      ..moveTo(r.right, r.bottom - len)
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.right - len, r.bottom)
      ..moveTo(r.left + len, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..lineTo(r.left, r.bottom - len);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF4F46E5).withValues(alpha: visible),
    );

    // Scan line (ping-pong, 2 passes per loop).
    final p = (t * 2) % 1.0;
    final e = Curves.easeInOut.transform(p < .5 ? p * 2 : 2 - p * 2);
    final y = frame.top + 6 + (frame.height - 12) * e;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(frame.deflate(2), const Radius.circular(10)),
    );
    final beam = Rect.fromLTRB(frame.left, y - 20, frame.right, y + 20);
    canvas.drawRect(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x006366F1),
            const Color(0xFF6366F1).withValues(alpha: .32 * visible),
            const Color(0x006366F1),
          ],
        ).createShader(beam),
    );
    canvas.drawLine(
      Offset(frame.left + 6, y),
      Offset(frame.right - 6, y),
      Paint()
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF6366F1).withValues(alpha: visible),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScanPainter o) => o.t != t || o.visible != visible;
}

// ── Slide 3 · rewards ──────────────────────────────────────────────────────

class _RewardsScene extends StatelessWidget {
  const _RewardsScene({required this.entrance, required this.ambient});
  final Animation<double> entrance, ambient;

  static const _confetti = [
    (x: 70.0, y: 46.0, c: Color(0xFFF59E0B), r: .5),
    (x: 250.0, y: 44.0, c: Color(0xFF6366F1), r: -.4),
    (x: 40.0, y: 150.0, c: Color(0xFFFBBF24), r: .9),
    (x: 222.0, y: 30.0, c: Color(0xFF8B5CF6), r: .2),
    (x: 334.0, y: 160.0, c: Color(0xFFF59E0B), r: -.8),
  ];

  @override
  Widget build(BuildContext context) {
    final both = Listenable.merge([entrance, ambient]);

    Widget item(String name, int i, double sign) => _fx(both, 'rewards', name, (
      c,
    ) {
      final e = _seg(entrance, .12 + i * .08, .5 + i * .08, Curves.easeOutBack);
      return _fade(e, _shift(0, (1 - e) * 14 + _wave(ambient) * 3 * sign, c));
    });

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _still('rewards', 'base'),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: both,
            builder: (context, _) {
              final fall = _seg(entrance, 0, .75, Curves.easeOutQuad);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final c in _confetti)
                    Positioned(
                      left: c.x,
                      top: c.y + 26 * fall,
                      child: Opacity(
                        opacity: math.sin(math.pi * fall).clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: c.r + fall * 1.5,
                          child: Container(
                            width: 10,
                            height: 5,
                            decoration: BoxDecoration(
                              color: c.c,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        // Album: one bounce on entry, then a barely-there hover.
        _fx(both, 'rewards', 'album', (c) {
          final pop = _seg(entrance, 0, .4, Curves.easeOutBack);
          final hop = math.sin(math.pi * _seg(entrance, 0, .45, Curves.linear));
          return _fade(
            pop,
            _scaleAt(
              180,
              150,
              .88 + .12 * pop,
              _shift(0, -12 * hop + _wave(ambient) * 2, c),
            ),
          );
        }),
        item('hat', 0, 1),
        item('glasses', 1, -1),
        item('gift', 2, 1),
        _fx(both, 'rewards', 'medal', (c) {
          final e = _seg(entrance, .35, .72, Curves.easeOutBack);
          return _fade(
            e,
            _scaleAt(65, 246, (.8 + .2 * e) * (1 + .04 * _wave(ambient)), c),
          );
        }),
      ],
    );
  }
}

// ── Slide 4 · progress ─────────────────────────────────────────────────────

class _ProgressScene extends StatelessWidget {
  const _ProgressScene({required this.entrance, required this.ambient});
  final Animation<double> entrance, ambient;

  @override
  Widget build(BuildContext context) {
    final both = Listenable.merge([entrance, ambient]);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _still('progress', 'base'),
        _fx(both, 'progress', 'card', (c) {
          final e = _seg(entrance, 0, .35);
          return _fade(e, _shift(0, (1 - e) * 14, c));
        }),
        // Buddy head as the profile avatar (the only place the buddy appears).
        Positioned(
          left: 33,
          top: 77,
          width: 30,
          height: 30,
          child: AnimatedBuilder(
            animation: entrance,
            child: ClipOval(
              child: Image.asset(
                kVowlyHead,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            builder: (context, child) => _fade(_seg(entrance, 0, .25), child!),
          ),
        ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: entrance,
            builder: (context, _) =>
                CustomPaint(painter: _ChartPainter(entrance: entrance.value)),
          ),
        ),
        // Globe: gentle float + tiny tilt.
        _fx(both, 'progress', 'globe', (c) {
          final e = _seg(entrance, 0, .35);
          return _fade(
            e,
            _shift(
              0,
              _wave(ambient) * 4,
              _rotateAt(292, 78, _wave(ambient) * .05, c),
            ),
          );
        }),
        for (var i = 0; i < 3; i++)
          _fx(entrance, 'progress', 'chip${i + 1}', (c) {
            final e = _seg(entrance, .2 + i * .08, .52 + i * .08);
            return _fade(e, _shift(0, (1 - e) * 6, c));
          }),
        _fx(
          entrance,
          'progress',
          'waves',
          (c) => _fade(_seg(entrance, .25, .65), c),
        ),
      ],
    );
  }
}

/// Bars (with 3D tops) + ring. Decorative sample shapes – no numbers shown.
class _ChartPainter extends CustomPainter {
  const _ChartPainter({required this.entrance});
  final double entrance;

  static const _targets = [.38, .56, .50, .92];

  double _p(double begin, double end, [Curve c = Curves.easeOutCubic]) =>
      c.transform(((entrance - begin) / (end - begin)).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    const baseline = 204.0, left = 52.0, step = 23.0, barW = 15.0, maxH = 66.0;
    for (var i = 0; i < _targets.length; i++) {
      final h = maxH * _targets[i] * _p(.06 + i * .08, .48 + i * .08);
      if (h <= 0) continue;
      final hero = i == _targets.length - 1;
      final x = left + i * step, y = baseline - h;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, h),
          const Radius.circular(4),
        ),
        Paint()
          ..color = hero ? const Color(0xFF6366F1) : const Color(0xFFC7D2FE),
      );
      canvas.drawPath(
        Path()
          ..moveTo(x, y + 3)
          ..lineTo(x + 5, y - 3)
          ..lineTo(x + 20, y - 3)
          ..lineTo(x + 15, y + 3)
          ..close(),
        Paint()
          ..color = hero ? const Color(0xFF4F46E5) : const Color(0xFFA5B4FC),
      );
    }

    const c = Offset(186, 160);
    const r = 24.0;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE0E7FF);
    canvas.drawCircle(c, r, track);
    final sweep = 2 * math.pi * .72 * _p(.15, .62);
    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        sweep,
        false,
        track..color = const Color(0xFF6366F1),
      );
    }
  }

  @override
  bool shouldRepaint(_ChartPainter o) => o.entrance != entrance;
}
