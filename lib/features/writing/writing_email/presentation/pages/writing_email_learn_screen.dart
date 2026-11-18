import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Learn Phase screen for Writing Email ("Email Anatomy & Etiquette Blueprint").
///
/// Teaches learners the universal four-part architecture:
/// Subject Line → Salutation → Message Body → Valediction, and how tone shifts across formality levels.
class WritingEmailLearnScreen extends StatefulWidget {
  final int level;

  const WritingEmailLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<WritingEmailLearnScreen> createState() =>
      _WritingEmailLearnScreenState();
}

class _WritingEmailLearnScreenState extends State<WritingEmailLearnScreen> {
  int _cardIndex = 0;
  late List<Map<String, dynamic>> _cards;

  @override
  void initState() {
    super.initState();
    _cards = _fallbackCards;
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/writing/writingEmail_learn_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelCards = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_L(\d+)_').firstMatch(id);
        if (match != null) {
          return int.parse(match.group(1)!) == widget.level;
        }
        return false;
      }).toList();

      if (mounted && levelCards.isNotEmpty) {
        setState(() {
          _cards = levelCards;
        });
      }
    } catch (_) {
      // Retain fallback cards on asset failure
    }
  }

  List<Map<String, dynamic>> get _fallbackCards => [
        {
          'id': 'WRT_WRITINGEMAIL_LEARN_FALLBACK_1',
          'instruction': 'ARRANGE THE EMAIL PARTS INTO THE CORRECT ORDER',
          'prompt':
              'You want to thank your friend Meera for lending you her science notes before the test. Build the email.',
          'formalityLevel': 'Informal',
          'emailComponents': [
            {
              'section': '1. Subject Line',
              'content': 'Subject: Thanks for the science notes',
              'guidance':
                  'Acts as the parcel label; states the specific purpose clearly before the recipient opens the message.',
            },
            {
              'section': '2. Greeting / Salutation',
              'content': 'Hi Meera,',
              'guidance':
                  'Use casual salutations like "Hi [Name]," for friends, peers, or familiar family members.',
            },
            {
              'section': '3. Message Body',
              'content':
                  'Thank you for lending me your notes. They made revising so much easier!',
              'guidance':
                  'Conveys the primary purpose, context, and any solution or next steps directly and concisely.',
            },
            {
              'section': '4. Sign-off / Valediction',
              'content': 'See you tomorrow,\nPriya',
              'guidance':
                  'Conclude with warm, casual valedictions like "See you soon," or "Best," followed by your first name.',
            },
          ],
          'modelEmail':
              'Subject: Thanks for the science notes\n\nHi Meera,\n\nThank you for lending me your notes. They made revising so much easier!\n\nSee you tomorrow,\nPriya',
          'techniqueTip':
              'An effective email always respects the recipient\'s relationship through consistent formality and places the subject line first so the recipient knows what to expect.',
          'explanation':
              'Most emails follow the same frame: subject line, greeting, message, sign-off. Readers see the subject first, so it comes first. The friendly tone (Hi, See you tomorrow) fits because Meera is a friend, not a teacher.',
        },
      ];

  void _onNext() {
    if (_cardIndex < _cards.length - 1) {
      setState(() {
        _cardIndex++;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'writingEmail',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=writing&gameType=writingEmail&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = _cards[_cardIndex];

    final prompt = card['prompt'] as String? ?? '';
    final instruction = card['instruction'] as String? ?? '';
    final formalityLevel = card['formalityLevel'] as String? ?? 'Informal';
    final modelEmail = card['modelEmail'] as String? ?? '';
    final explanation = card['explanation'] as String? ?? '';
    final techniqueTip = card['techniqueTip'] as String? ?? '';

    final emailComponents = (card['emailComponents'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final isLast = _cardIndex >= _cards.length - 1;

    return LearnPhaseScaffold(
      title: 'Email Anatomy & Etiquette',
      gameType: 'writingEmail',
      level: widget.level,
      actionLabel: isLast ? 'Start Guided Practice' : 'Next Email Card',
      onComplete: _onNext,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pacing & Formality Badge
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'EMAIL BLUEPRINT ${_cardIndex + 1} OF ${_cards.length}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: formalityLevel.toLowerCase().contains('formal')
                        ? AppColors.amber500.withValues(alpha: 0.15)
                        : AppColors.emerald500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '$formalityLevel Tone',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: formalityLevel.toLowerCase().contains('formal')
                          ? AppColors.amber500
                          : AppColors.emerald500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Prompt Scenario Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.mail_outline_rounded,
                        color: AppColors.indigo500,
                        size: 22.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'EMAIL SCENARIO & OBJECTIVE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    prompt,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.slate100 : AppColors.slate800,
                      height: 1.45,
                    ),
                  ),
                  if (instruction.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 15.sp,
                          color: AppColors.amber500,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            instruction,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              color: isDark
                                  ? AppColors.slate400
                                  : AppColors.slate600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Four-Part Email Anatomy Breakdown
            Text(
              'FOUR-PART EMAIL ARCHITECTURE:',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10.h),

            ...emailComponents.map((comp) {
              final section = comp['section'] as String? ?? '';
              final content = comp['content'] as String? ?? '';
              final guidance = comp['guidance'] as String? ?? '';

              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.indigo500.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo500,
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      content,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.slate100
                            : AppColors.slate800,
                        height: 1.35,
                      ),
                    ),
                    if (guidance.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        guidance,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5.sp,
                          color: isDark
                              ? AppColors.slate400
                              : AppColors.slate600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            // Complete Model Email Card
            Container(
              margin: EdgeInsets.only(top: 6.h, bottom: 14.h),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.mark_email_read_rounded,
                        color: AppColors.emerald500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'ASSEMBLED MODEL EMAIL',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emerald500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    modelEmail,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.slate100
                          : AppColors.slate800,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            // Technique Tip Card
            if (techniqueTip.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.indigo500.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: AppColors.indigo500,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ETIQUETTE RULE',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.indigo500,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            techniqueTip,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              color: isDark
                                  ? AppColors.slate300
                                  : AppColors.slate700,
                              height: 1.35,
                            ),
                          ),
                          if (explanation.isNotEmpty) ...[
                            SizedBox(height: 6.h),
                            Text(
                              explanation,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? AppColors.slate400
                                    : AppColors.slate500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
