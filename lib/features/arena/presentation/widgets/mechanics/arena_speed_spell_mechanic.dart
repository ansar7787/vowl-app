import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';

/// Mechanic 7: Speed Spell 🏆
/// OTP-style individual letter fields with auto-advance, backspace → previous box,
/// and instant auto-submit when all blanks are filled.
class ArenaSpeedSpellMechanic extends StatefulWidget {
  final ArenaChallenge challenge;
  final ArenaDuelState state;
  final bool isDark;
  final bool isMidnight;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<String> onDraftChanged;
  final ValueChanged<String> onSubmitLetters;

  const ArenaSpeedSpellMechanic({
    super.key,
    required this.challenge,
    required this.state,
    required this.isDark,
    required this.isMidnight,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onDraftChanged,
    required this.onSubmitLetters,
  });

  @override
  State<ArenaSpeedSpellMechanic> createState() =>
      _ArenaSpeedSpellMechanicState();
}

class _ArenaSpeedSpellMechanicState extends State<ArenaSpeedSpellMechanic> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  final List<FocusNode> _listenerFocusNodes = [];
  bool _hasSubmittedLocally = false;

  @override
  void initState() {
    super.initState();
    _initBlankInputs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty && !widget.state.isAnswered) {
        _focusNodes.first.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ArenaSpeedSpellMechanic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge.id != widget.challenge.id) {
      _disposeBlankInputs();
      _hasSubmittedLocally = false;
      _initBlankInputs();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNodes.isNotEmpty && !widget.state.isAnswered) {
          _focusNodes.first.requestFocus();
        }
      });
    }
  }

  void _initBlankInputs() {
    final blankCount = widget.challenge.missingPositions?.length ?? 0;
    for (var i = 0; i < blankCount; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
      _listenerFocusNodes.add(FocusNode(skipTraversal: true));
    }
  }

  void _disposeBlankInputs() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final l in _listenerFocusNodes) {
      l.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
    _listenerFocusNodes.clear();
  }

  @override
  void dispose() {
    _disposeBlankInputs();
    super.dispose();
  }

  void _onBoxChanged(int blankIdx, String rawValue) {
    if (widget.state.isAnswered || _hasSubmittedLocally) return;

    final clean = rawValue.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
    if (clean.isEmpty) {
      _controllers[blankIdx].text = '';
      _notifyDraft();
      return;
    }

    // Handle multi-character input or fast paste across sequential blank boxes
    var cursor = blankIdx;
    for (var i = 0; i < clean.length && cursor < _controllers.length; i++) {
      final ch = clean[i];
      _controllers[cursor].value = TextEditingValue(
        text: ch,
        selection: const TextSelection.collapsed(offset: 1),
      );
      cursor++;
    }

    _notifyDraft();

    // Auto-advance focus to next empty blank
    if (cursor < _focusNodes.length) {
      _focusNodes[cursor].requestFocus();
    }

    _checkAutoSubmit();
  }

  void _handleKeyEvent(int blankIdx, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[blankIdx].text.isEmpty &&
        blankIdx > 0) {
      _controllers[blankIdx - 1].clear();
      _focusNodes[blankIdx - 1].requestFocus();
      _notifyDraft();
    }
  }

  void _notifyDraft() {
    final combined = _controllers.map((c) => c.text.trim()).join('');
    widget.onDraftChanged(combined);
  }

  void _checkAutoSubmit() {
    if (_hasSubmittedLocally || widget.state.isAnswered) return;
    if (_controllers.isEmpty) return;
    if (_controllers.every((c) => c.text.trim().length == 1)) {
      _hasSubmittedLocally = true;
      final filled = _controllers
          .map((c) => c.text.trim().toLowerCase())
          .join('');
      final expected = (widget.challenge.missingLetters ?? [])
          .join('')
          .toLowerCase();
      final isCorrect = filled == expected;

      if (isCorrect) {
        if (di.sl.isRegistered<HapticService>()) {
          di.sl<HapticService>().success();
        }
        if (di.sl.isRegistered<SoundService>()) {
          di.sl<SoundService>().playCorrect(
            comboStep: widget.state.currentQuestionIndex + 1,
          );
        }
      } else {
        if (di.sl.isRegistered<HapticService>()) {
          di.sl<HapticService>().error();
        }
        if (di.sl.isRegistered<SoundService>()) {
          di.sl<SoundService>().playWrong();
        }
      }

      widget.onSubmitLetters(filled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isMidnight
        ? AppColors.midnightSurface
        : (widget.isDark ? AppColors.slate800 : Colors.white);
    final answer = widget.challenge.correctAnswer;
    final missingPositions = widget.challenge.missingPositions ?? const <int>[];
    final isAnswered = widget.state.isAnswered;
    final isCorrect = widget.state.isCorrect == true;

    // Map word index -> blank box index
    final posToBlank = <int, int>{};
    for (var b = 0; b < missingPositions.length; b++) {
      posToBlank[missingPositions[b]] = b;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.cardSpacious),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: AppColors.amber500.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'FILL THE MISSING LETTERS',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.5.sp,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amber500,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  widget.challenge.prompt,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: widget.textPrimary,
                  ),
                ),
                SizedBox(height: 20.h),

                // Word Tiles + OTP Blank Boxes Row
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 5.w,
                  runSpacing: 8.h,
                  children: List.generate(answer.length, (charIdx) {
                    final blankIdx = posToBlank[charIdx];
                    if (blankIdx == null || blankIdx >= _controllers.length) {
                      return Container(
                        width: 30.w,
                        height: 42.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? AppColors.slate900
                              : AppColors.slate100,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: widget.borderColor),
                        ),
                        child: Text(
                          answer[charIdx].toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                            color: widget.textPrimary,
                          ),
                        ),
                      );
                    }

                    final boxBorderColor = isAnswered
                        ? (isCorrect ? AppColors.emerald500 : AppColors.rose500)
                        : AppColors.amber500;

                    return SizedBox(
                      width: 34.w,
                      height: 42.h,
                      child: KeyboardListener(
                        focusNode: _listenerFocusNodes[blankIdx],
                        onKeyEvent: (ev) => _handleKeyEvent(blankIdx, ev),
                        child: TextField(
                          controller: _controllers[blankIdx],
                          focusNode: _focusNodes[blankIdx],
                          enabled: !isAnswered,
                          autocorrect: false,
                          enableSuggestions: false,
                          textCapitalization: TextCapitalization.none,
                          textAlign: TextAlign.center,
                          maxLength: 2,
                          onChanged: (v) => _onBoxChanged(blankIdx, v),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                            color: boxBorderColor,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: AppColors.amber500.withValues(
                              alpha: 0.12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                color: boxBorderColor,
                                width: 1.6,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: BorderSide(
                                color: AppColors.amber500,
                                width: 1.6,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                              borderSide: const BorderSide(
                                color: AppColors.indigo500,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          if (isAnswered) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.slate900 : AppColors.slate100,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isCorrect ? AppColors.emerald500 : AppColors.rose500,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.lightbulb,
                        size: 15.sp,
                        color: AppColors.amber500,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Word: ${answer.toUpperCase()}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                          color: isCorrect
                              ? AppColors.emerald500
                              : AppColors.rose500,
                        ),
                      ),
                    ],
                  ),
                  if (widget.challenge.explanation.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      widget.challenge.explanation,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: widget.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
