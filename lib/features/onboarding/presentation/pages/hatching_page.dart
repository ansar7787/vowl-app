import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart';
import 'package:flutter_tts/flutter_tts.dart';

class HatchingPage extends StatefulWidget {
  final String userName;
  const HatchingPage({super.key, required this.userName});

  @override
  State<HatchingPage> createState() => _HatchingPageState();
}

class _HatchingPageState extends State<HatchingPage> {
  int _stage = 0; // 0: Egg, 1: Cracking, 2: Hatched, 3: Introduction
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.2); // Slightly higher pitch for Owly
    await _tts.setSpeechRate(0.5);
  }

  void _onTapEgg() {
    if (_stage == 0) {
      sl<HapticService>().selection();
      setState(() => _stage = 1);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          sl<HapticService>().success();
          setState(() => _stage = 2);
          _speakIntroduction();
        }
      });
    } else if (_stage == 2) {
      setState(() => _stage = 3);
    }
  }

  Future<void> _speakIntroduction() async {
    final message = "Hoot hoot! I am Owly. I have been waiting for a brave traveler like you, ${widget.userName}, to help me unlock the secrets of English. Let's begin our quest!";
    await _tts.speak(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const MeshGradientBackground(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTitle(),
                  SizedBox(height: 60.h),
                  _buildMascotStage(),
                  SizedBox(height: 40.h),
                  _buildStatusText(),
                  const Spacer(),
                  if (_stage >= 2) _buildGetStartedButton(),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    String title = "A Discovery...";
    if (_stage >= 2) title = "Welcome, ${widget.userName}!";
    
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 32.sp,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF2563EB),
      ),
    ).animate(key: ValueKey(_stage)).fadeIn().scale();
  }

  Widget _buildMascotStage() {
    return GestureDetector(
      onTap: _onTapEgg,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_stage < 2)
            _buildEgg()
          else
            const VowlMascot(
              state: VowlMascotState.happy,
              size: 200,
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }

  Widget _buildEgg() {
    return Container(
      width: 180.r,
      height: 240.r,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.all(Radius.elliptical(90.r, 120.r)),
        border: Border.all(color: Colors.white38, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: 48.r,
        ),
      ),
    )
        .animate(
          onPlay: (c) => c.repeat(reverse: true),
        )
        .shimmer(duration: 2000.ms)
        .moveY(begin: -10, end: 10, duration: 2000.ms, curve: Curves.easeInOut)
        .shake(
          hz: _stage == 1 ? 10 : 0,
          duration: 1500.ms,
        );
  }

  Widget _buildStatusText() {
    String text = "Tap the egg to begin your adventure";
    if (_stage == 1) text = "Something is happening...";
    if (_stage >= 2) text = "You hatched a Vowl companion!";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.blueGrey,
        ),
      ),
    ).animate(key: ValueKey(_stage)).fadeIn();
  }

  Widget _buildGetStartedButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: ElevatedButton(
        onPressed: () => context.go('/'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 60.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
        child: Text(
          "Enter the World of Vowl",
          style: GoogleFonts.outfit(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 2.seconds).slideY(begin: 0.2, end: 0);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
