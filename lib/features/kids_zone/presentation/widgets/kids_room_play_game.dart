import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'dart:math';

class KidsRoomPlayGame extends StatefulWidget {
  final VoidCallback onComplete;

  const KidsRoomPlayGame({
    super.key,
    required this.onComplete,
  });

  @override
  State<KidsRoomPlayGame> createState() => _KidsRoomPlayGameState();
}

class _KidsRoomPlayGameState extends State<KidsRoomPlayGame> {
  final List<_Bubble> _bubbles = [];
  int _score = 0;
  int _timeLeft = 10;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _score = 0;
      _timeLeft = 10;
      _bubbles.clear();
    });
    
    // Game loop
    _gameTick();
    _spawnTick();
  }

  void _gameTick() {
    if (!mounted || !_isPlaying) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _isPlaying = false;
          _endGame();
        }
      });
      if (_timeLeft > 0) _gameTick();
    });
  }

  void _spawnTick() {
    if (!mounted || !_isPlaying) return;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (_bubbles.length < 5) {
        setState(() {
          _bubbles.add(_Bubble(
            id: DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString(),
            x: 0.1 + Random().nextDouble() * 0.8, // 10% to 90% of screen width
            y: 0.2 + Random().nextDouble() * 0.6, // 20% to 80% of screen height
            size: 40 + Random().nextDouble() * 40, // 40 to 80 size
            color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
          ));
        });
      }
      if (_isPlaying) _spawnTick();
    });
  }

  void _popBubble(String id) {
    if (!_isPlaying) return;
    final index = _bubbles.indexWhere((b) => b.id == id);
    if (index != -1) {
      setState(() {
        _bubbles.removeAt(index);
        _score++;
      });
      di.sl<SoundService>().playClick(); // Or a pop sound if we had one
    }
  }

  void _endGame() {
    di.sl<SoundService>().playCorrect();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: Stack(
        children: [
          // Bubbles
          ..._bubbles.map((bubble) {
            return Positioned(
              left: MediaQuery.of(context).size.width * bubble.x,
              top: MediaQuery.of(context).size.height * bubble.y,
              child: ScaleButton(
                onTap: () => _popBubble(bubble.id),
                child: Container(
                  width: bubble.size.r,
                  height: bubble.size.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        bubble.color.withValues(alpha: 0.4),
                        bubble.color.withValues(alpha: 0.8),
                      ],
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: bubble.color.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  ),
                  child: Center(
                    child: Container(
                      width: bubble.size.r * 0.3,
                      height: bubble.size.r * 0.3,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.topRight,
                    ),
                  ),
                ),
              ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
            );
          }),

          // UI Layer
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Time
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: Colors.blue, width: 3.w),
                    ),
                    child: Text(
                      "⏱️ $_timeLeft",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  // Score
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: Colors.green, width: 3.w),
                    ),
                    child: Text(
                      "🫧 $_score",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!_isPlaying && _timeLeft <= 0)
            Center(
              child: Container(
                padding: EdgeInsets.all(40.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40.r),
                  border: Border.all(color: Colors.amber, width: 4.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "TIME'S UP!",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      "You popped $_score bubbles! 🫧",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            )
        ],
      ),
    );
  }
}

class _Bubble {
  final String id;
  final double x;
  final double y;
  final double size;
  final Color color;

  _Bubble({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.color,
  });
}
