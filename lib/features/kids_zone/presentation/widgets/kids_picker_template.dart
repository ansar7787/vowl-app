import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_image.dart';

class KidsPickerTemplate extends StatefulWidget {
  final String title;
  final String gameType;
  final int level;
  final Color primaryColor;
  final List<Color> backgroundColors;
  final IconData fallbackIcon;
  final String? centerTextOverride;
  final String? painterName;
  final String? shaderName;

  const KidsPickerTemplate({
    super.key,
    required this.title,
    required this.gameType,
    required this.level,
    required this.primaryColor,
    required this.backgroundColors,
    required this.fallbackIcon,
    this.centerTextOverride,
    this.painterName,
    this.shaderName,
  });

  @override
  State<KidsPickerTemplate> createState() => _KidsPickerTemplateState();
}

class _KidsPickerTemplateState extends State<KidsPickerTemplate> {
  bool _isOverTarget = false;

  @override
  Widget build(BuildContext context) {
    String effectivePainter = widget.painterName ?? "KidsWorldBackground";
    if (effectivePainter.isEmpty) effectivePainter = "KidsWorldBackground";

    return KidsGameBaseScreen(
      title: widget.title,
      gameType: widget.gameType,
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: widget.backgroundColors,
      painterName: effectivePainter,
      shaderName: widget.shaderName,
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 20.h),
            _buildInstruction(quest.instruction),
            
            Expanded(
              flex: 5,
              child: Center(
                child: _buildDragTarget(context, state, quest),
              ),
            ),

            Flexible(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.only(bottom: 30.h, left: 16.w, right: 16.w),
                child: Center(
                  child: _buildOptions(context, state, quest),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstruction(String instruction) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Text(
              instruction,
              style: GoogleFonts.fredoka(fontSize: 22.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B), height: 1.1),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildDragTarget(BuildContext context, KidsLoaded state, KidsQuest quest) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isOverTarget = true);
        return state.lastAnswerCorrect == null;
      },
      onLeave: (data) => setState(() => _isOverTarget = false),
      onAcceptWithDetails: (details) {
        setState(() => _isOverTarget = false);
        final option = details.data;
        final isCorrect = quest.correctAnswer == option;
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: 300.ms,
          transform: Matrix4.diagonal3Values(_isOverTarget ? 1.1 : 1.0, _isOverTarget ? 1.1 : 1.0, 1.0),
          child: _buildCentralVisual(quest, isHighlighted: _isOverTarget),
        );
      },
    );
  }

  Widget _buildCentralVisual(KidsQuest quest, {bool isHighlighted = false}) {
    final displayValue = widget.centerTextOverride ?? quest.question ?? "?";
    final isEmoji = _isEmoji(displayValue);
    final hasImage = quest.imageUrl != null && quest.imageUrl!.isNotEmpty;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Glow
        Container(
          width: 180.r, height: 180.r,
          decoration: BoxDecoration(
            color: widget.primaryColor.withValues(alpha: isHighlighted ? 0.4 : 0.2),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: widget.primaryColor.withValues(alpha: isHighlighted ? 0.5 : 0.3), blurRadius: isHighlighted ? 60 : 40, spreadRadius: isHighlighted ? 20 : 10),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds),

        // Glass Orb
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 180.r, height: 180.r,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7), 
                shape: BoxShape.circle,
                border: Border.all(color: widget.primaryColor.withValues(alpha: isHighlighted ? 0.5 : 0.1), width: isHighlighted ? 4 : 2),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.white.withValues(alpha: 0.3)]),
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(hasImage ? 30.r : 20.r),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: hasImage 
                      ? SizedBox(width: 120.r, height: 120.r, child: KidsImage(imageUrl: quest.imageUrl, fallbackIcon: widget.fallbackIcon, iconColor: widget.primaryColor.withValues(alpha: 0.5)))
                      : Text(
                          displayValue,
                          style: GoogleFonts.fredoka(fontSize: _getCentralFontSize(displayValue, isEmoji), fontWeight: FontWeight.w900, color: const Color(0xFF1E293B), letterSpacing: isEmoji ? 4 : 0, height: 1.0, shadows: [const Shadow(color: Colors.white, blurRadius: 10)]),
                          textAlign: TextAlign.center,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        if (isHighlighted)
          Positioned(
            bottom: 10.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(color: widget.primaryColor, borderRadius: BorderRadius.circular(12.r)),
              child: Text("DROP HERE!", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: Colors.white)),
            ).animate().fadeIn().scale(),
          ),
      ],
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -10, end: 10, duration: 3.seconds, curve: Curves.easeInOut);
  }

  Widget _buildOptions(BuildContext context, KidsLoaded state, KidsQuest quest) {
    final options = quest.options ?? [];
    
    return Wrap(
      spacing: 16.r, runSpacing: 16.r, alignment: WrapAlignment.center,
      children: List.generate(options.length, (index) {
        final option = options[index];
        final isCorrect = quest.correctAnswer == option;
        final isAnswered = state.lastAnswerCorrect != null;

        final optionWidget = _buildOptionCard(option, isAnswered);

        return Draggable<String>(
          data: option,
          maxSimultaneousDrags: isAnswered ? 0 : 1,
          feedback: Material(color: Colors.transparent, child: SizedBox(width: 140.w, child: _buildOptionCard(option, false, isFeedback: true))),
          childWhenDragging: Opacity(opacity: 0.3, child: optionWidget),
          child: ScaleButton(
            onTap: isAnswered ? null : () {
              context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
            },
            child: optionWidget,
          ),
        ).animate().scale(delay: (index * 120).ms, duration: 600.ms, curve: Curves.elasticOut).slideY(begin: 0.3, end: 0);
      }),
    );
  }

  Widget _buildOptionCard(String option, bool isAnswered, {bool isFeedback = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25.r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          constraints: BoxConstraints(minWidth: 110.w),
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(25.r),
            border: Border.all(color: widget.primaryColor.withValues(alpha: isFeedback ? 0.5 : 0.2), width: isFeedback ? 3 : 2),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              option,
              style: GoogleFonts.fredoka(fontSize: _getOptionFontSize(option), fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  double _getCentralFontSize(String text, bool isEmoji) {
    if (!isEmoji) return 110.sp;
    int count = text.runes.length;
    if (count <= 1) return 90.sp;
    if (count <= 2) return 65.sp;
    if (count <= 3) return 50.sp;
    if (count <= 5) return 40.sp;
    return 30.sp;
  }

  bool _isEmoji(String text) {
    if (text.isEmpty) return false;
    return text.runes.any((rune) => rune > 128);
  }

  double _getOptionFontSize(String text) {
    if (_isEmoji(text)) {
      int count = text.runes.length;
      if (count <= 1) return 40.sp;
      if (count <= 3) return 30.sp;
      return 24.sp;
    }
    if (text.length <= 2) return 32.sp;
    return 20.sp;
  }
}

