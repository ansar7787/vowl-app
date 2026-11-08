import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// 1 vs 1 duel hero. Same layered-SVG system as the onboarding illustrations:
/// 360×320 stage, full-stage layers (`assets/illustrations/duel_<layer>.svg`),
/// only transformed – never repositioned.
///
/// Pass REAL avatars (e.g. `NetworkImage(user.photoUrl)` or `CachedNetworkImageProvider`).
/// Falls back to the Vowly head for "me" and a neutral person icon (or Vowly head for AI) for the opponent.
/// Set [searching] while matchmaking: the opponent slot shows a pulsing "?" with ripples.
/// Set [isOpponentAi] to true when matched against computer/AI so it uses the Vowly mascot head/logo.
class DuelIllustration extends StatefulWidget {
  const DuelIllustration({
    super.key,
    this.meAvatar,
    this.opponentAvatar,
    this.searching = false,
    this.isOpponentAi = false,
    this.opponentFallback,
  });

  final ImageProvider? meAvatar;
  final ImageProvider? opponentAvatar;
  final bool searching;
  final bool isOpponentAi;
  final Widget? opponentFallback;

  @override
  State<DuelIllustration> createState() => _DuelIllustrationState();
}

const double _w = 360, _h = 320;
const String _dir = 'assets/illustrations/duel_';
const String _defaultMe = 'assets/images/vowly_head.webp';
const Offset _meCenter = Offset(80, 148), _oppCenter = Offset(280, 148);

double _seg(
  Animation<double> a,
  double b,
  double e, [
  Curve c = Curves.easeOutCubic,
]) => c.transform(((a.value - b) / (e - b)).clamp(0.0, 1.0));

double _wave(Animation<double> a, [double cycles = 1]) =>
    math.sin(a.value * cycles * 2 * math.pi);

Widget _fade(double o, Widget c) =>
    Opacity(opacity: o.clamp(0.0, 1.0), child: c);

Widget _shift(double dx, double dy, Widget c) =>
    Transform.translate(offset: Offset(dx, dy), child: c);

Alignment _al(double x, double y) =>
    Alignment(x / (_w / 2) - 1, y / (_h / 2) - 1);

class _Layer extends StatelessWidget {
  const _Layer(this.name);
  final String name;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    '$_dir$name.svg',
    width: _w,
    height: _h,
    fit: BoxFit.contain,
  );
}

class _DuelIllustrationState extends State<DuelIllustration>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!MediaQuery.disableAnimationsOf(context) && !_ambient.isAnimating) {
        _ambient.repeat();
      }
    } else {
      _ambient.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ambient.stop();
      _entrance.value = 1;
    } else {
      if (!_entrance.isAnimating && _entrance.value == 0) _entrance.forward();
      if (!_ambient.isAnimating) _ambient.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Widget _avatar(ImageProvider? p, Widget fallback) => p == null
      ? fallback
      : Image(
          image: p,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallback,
        );

  /// A player card = SVG layer + live avatar, moved together.
  Widget _card(
    Listenable both,
    String layer,
    double fromDx,
    double begin,
    double end,
    Offset c,
    Widget avatar,
  ) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: both,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: _Layer(layer)),
            Positioned(
              left: c.dx - 27,
              top: c.dy - 27,
              width: 54,
              height: 54,
              child: ClipOval(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: avatar,
                ),
              ),
            ),
          ],
        ),
        builder: (context, child) {
          final e = _seg(_entrance, begin, end, Curves.easeOutBack);
          return _fade(e, _shift(fromDx * (1 - e), 0, child!));
        },
      ),
    );
  }

  Widget _fx(Listenable a, String name, Widget Function(Widget) wrap) =>
      Positioned.fill(
        child: AnimatedBuilder(
          animation: a,
          child: _Layer(name),
          builder: (_, c) => wrap(c!),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final both = Listenable.merge([_entrance, _ambient]);
    final Widget defaultOpponentFallback =
        widget.opponentFallback ??
        (widget.isOpponentAi
            ? Image.asset(_defaultMe, fit: BoxFit.cover)
            : const ColoredBox(
                color: AppColors.indigo50,
                child: Icon(
                  Icons.person_rounded,
                  size: 36,
                  color: AppColors.indigo400,
                ),
              ));
    final searchingGlyph = AnimatedBuilder(
      animation: _ambient,
      builder: (context, _) => ColoredBox(
        color: AppColors.indigo50,
        child: Center(
          child: Opacity(
            opacity: .55 + .45 * (.5 + .5 * _wave(_ambient, 2)),
            child: const Text(
              '?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.indigo600,
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      image: true,
      excludeSemantics: true,
      label: widget.searching
          ? 'Illustration: you and an opponent slot searching, ready for a 1 vs 1 word duel'
          : widget.isOpponentAi
          ? 'Illustration: you facing off against the Vowl AI in a 1 vs 1 word duel with a trophy'
          : 'Illustration: two players facing off in a 1 vs 1 word duel with a trophy',
      child: FittedBox(
        child: SizedBox(
          width: _w,
          height: _h,
          child: RepaintBoundary(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(child: _Layer('base')),
                if (widget.searching)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _ambient,
                      builder: (context, _) => CustomPaint(
                        painter: _PulsePainter(
                          center: _oppCenter,
                          t: _ambient.value,
                        ),
                      ),
                    ),
                  ),
                _card(
                  both,
                  'cardA',
                  -60,
                  0,
                  .5,
                  _meCenter,
                  _avatar(
                    widget.meAvatar,
                    Image.asset(_defaultMe, fit: BoxFit.cover),
                  ),
                ),
                _card(
                  both,
                  'cardB',
                  60,
                  .1,
                  .6,
                  _oppCenter,
                  widget.searching
                      ? searchingGlyph
                      : _avatar(widget.opponentAvatar, defaultOpponentFallback),
                ),
                _fx(both, 'trophy', (c) {
                  final e = _seg(_entrance, .55, .9);
                  return _fade(
                    e,
                    _shift(0, (1 - e) * 16 + _wave(_ambient) * 2, c),
                  );
                }),
                _fx(both, 'vs', (c) {
                  final e = _seg(_entrance, .4, .75, Curves.easeOutBack);
                  return _fade(
                    e,
                    Transform.scale(
                      scale: (.3 + .7 * e) * (1 + .04 * _wave(_ambient)),
                      alignment: _al(180, 144),
                      child: Transform.rotate(
                        angle: _wave(_ambient) * .03,
                        alignment: _al(180, 144),
                        child: c,
                      ),
                    ),
                  );
                }),
                _fx(both, 'bubbleA', (c) {
                  final e = _seg(_entrance, .7, 1, Curves.easeOutBack);
                  return _fade(
                    e,
                    Transform.scale(
                      scale: .6 + .4 * e,
                      alignment: _al(104, 106),
                      child: c,
                    ),
                  );
                }),
                _fx(both, 'bubbleB', (c) {
                  final e = _seg(_entrance, .8, 1, Curves.easeOutBack);
                  return _fade(
                    e,
                    Transform.scale(
                      scale: .6 + .4 * e,
                      alignment: _al(256, 106),
                      child: c,
                    ),
                  );
                }),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: both,
                    child: const _Layer('timer'),
                    builder: (context, child) {
                      final e = _seg(_entrance, .6, .9);
                      return _fade(
                        e,
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            child!,
                            CustomPaint(
                              size: const Size(_w, _h),
                              painter: _CountdownPainter(
                                center: const Offset(156, 56),
                                t: _ambient.value,
                              ),
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
        ),
      ),
    );
  }
}

/// Ripples around the opponent slot while matchmaking.
class _PulsePainter extends CustomPainter {
  const _PulsePainter({required this.center, required this.t});
  final Offset center;
  final double t;

  static final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final p = (t * 2 + i / 3) % 1.0;
      canvas.drawCircle(
        center,
        36 + p * 34,
        _paint..color = AppColors.violet500.withValues(alpha: (1 - p) * .5),
      );
    }
  }

  @override
  bool shouldRepaint(_PulsePainter oldDelegate) => oldDelegate.t != t;
}

/// Amber countdown arc around the stopwatch icon (2 cycles per 6 s loop).
class _CountdownPainter extends CustomPainter {
  const _CountdownPainter({required this.center, required this.t});
  final Offset center;
  final double t;

  static final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..color = AppColors.amber500;

  @override
  void paint(Canvas canvas, Size size) {
    final sweep = 2 * math.pi * (1 - (t * 2) % 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 15.5),
      -math.pi / 2,
      sweep,
      false,
      _paint,
    );
  }

  @override
  bool shouldRepaint(_CountdownPainter oldDelegate) => oldDelegate.t != t;
}
