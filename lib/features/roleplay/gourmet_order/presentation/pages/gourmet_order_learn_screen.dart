import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Learn Phase screen for Gourmet Order ("Dining Etiquette & Dietary Modifiers").
///
/// Instructs learners on professional restaurant communication, culinary preparation
/// vocabulary, dietary restrictions, polite substitution phrasing, and billing etiquette.
class GourmetOrderLearnScreen extends StatefulWidget {
  final int level;

  const GourmetOrderLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<GourmetOrderLearnScreen> createState() =>
      _GourmetOrderLearnScreenState();
}

class _GourmetOrderLearnScreenState extends State<GourmetOrderLearnScreen> {
  int _currentIndex = 0;
  late List<Map<String, dynamic>> _quests;

  @override
  void initState() {
    super.initState();
    _quests = _fallbackQuests;
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/roleplay/gourmetOrder_learn_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_l(\d+)_', caseSensitive: false).firstMatch(id);
        if (match != null) {
          return int.parse(match.group(1)!) == widget.level;
        }
        return false;
      }).toList();

      if (levelQuests.isNotEmpty && mounted) {
        setState(() {
          _quests = levelQuests;
        });
      }
    } catch (_) {
      // Fallback quests maintain continuity during testing or missing assets.
    }
  }

  void _onNext() {
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().light();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playClick();
      }
    } catch (_) {}

    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _markCompleteAndNavigate();
    }
  }

  void _markCompleteAndNavigate() {
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().success();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playCorrect();
      }
    } catch (_) {}

    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'gourmetOrder',
      level: widget.level,
      phase: 'learn',
    );

    try {
      context.pushReplacement(
        '/practice?category=roleplay&gameType=gourmetOrder&level=${widget.level}',
      );
    } catch (_) {}
  }

  static final List<Map<String, dynamic>> _fallbackQuests = [
    {
      'id': 'go_learn_l1_q1',
      'level': 1,
      'diningContext': 'CASUAL BISTRO & DRINKS',
      'concept': 'Opening Orders & Table Water Protocol',
      'prepTerm': 'Tap vs. Sparkling Water / Draft vs. Bottled',
      'etiquetteTip':
          'Specify water and beverage choices promptly using courteous modals ("May we start with...", "Could we get...").',
      'waiterPrompt':
          'Good evening, welcome to the Bistro! Can I start you off with something to drink while you look over the menu?',
      'optimalOrderStatement':
          'Good evening! Could we please start with a bottle of sparkling water with lime, and two draft lagers?',
      'pronunciationGuide': 'SPARK-ling WAH-ter / draf-t LAH-ger',
      'keyTakeaway':
          'Polite requests frame the entire service interaction smoothly.',
    },
    {
      'id': 'go_learn_l1_q2',
      'level': 1,
      'diningContext': 'FINE DINING & SOMMELIER',
      'concept': 'Wine Pairing & Vintage Inquiries',
      'prepTerm': 'Tannins, Acidity, Vintage, Full-bodied vs. Crisp',
      'etiquetteTip':
          'Seek sommelier recommendations by describing flavor notes you enjoy rather than guessing blindly.',
      'waiterPrompt':
          'Would you care for wine pairings tonight, or should I recommend a vintage for your braised beef cheek?',
      'optimalOrderStatement':
          'We would love a recommendation. We generally prefer full-bodied reds with low acidity and subtle oak notes.',
      'pronunciationGuide': 'SOH-mel-yay / VIN-tij / TAH-ninz',
      'keyTakeaway':
          'Specifying preferences (body, acidity, tannin) empowers the sommelier to suggest the ideal match.',
    },
    {
      'id': 'go_learn_l1_q3',
      'level': 1,
      'diningContext': 'DIETARY RESTRICTIONS & ALLERGIES',
      'concept': 'Clear Allergy Disclosures & Cross-Contamination',
      'prepTerm': 'Gluten-sensitive, Celiac-safe, Nut-free, Dedicated Cookware',
      'etiquetteTip':
          'State severe allergies explicitly at the beginning of the meal so the kitchen can use sanitized surfaces.',
      'waiterPrompt':
          'Before taking your orders, does anyone at the table have dietary restrictions or food allergies we should note?',
      'optimalOrderStatement':
          'Yes, thank you for checking. I have a severe peanut allergy. Could you please confirm if this sauce has any nut paste or traces?',
      'pronunciationGuide': 'SEE-lee-ak / AL-er-jee / cross-con-tam-i-NAY-shun',
      'keyTakeaway':
          'Clear, polite statements about allergies protect your health and allow the culinary team to sanitize prep stations.',
    },
  ];

  Widget _buildDiningPillarCard({
    required IconData icon,
    required String title,
    required String content,
    required Color accentColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              size: 18.sp,
              color: accentColor,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: accentColor,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.slate100,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _quests[_currentIndex.clamp(0, _quests.length - 1)];
    final diningContext =
        current['diningContext'] as String? ?? 'DINING SETTING';
    final concept = current['concept'] as String? ?? '';
    final prepTerm = current['prepTerm'] as String? ?? '';
    final etiquetteTip = current['etiquetteTip'] as String? ?? '';
    final waiterPrompt = current['waiterPrompt'] as String? ?? '';
    final optimalOrderStatement =
        current['optimalOrderStatement'] as String? ?? '';
    final pronunciationGuide = current['pronunciationGuide'] as String? ?? '';
    final keyTakeaway = current['keyTakeaway'] as String? ?? '';

    return LearnPhaseScaffold(
      title: 'Gourmet Order',
      gameType: 'gourmetOrder',
      level: widget.level,
      actionLabel: _currentIndex == _quests.length - 1
          ? 'START PRACTICE'
          : 'NEXT SCENARIO',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Server / Waiter Prompt Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restaurant_rounded,
                              size: 14.sp,
                              color: AppColors.amber500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'SERVER INQUIRY',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.amber500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slate800,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          diningContext,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '"$waiterPrompt"',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate100,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Dining Knowledge Section
            Text(
              'DINING PROTOCOL BREAKDOWN',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppColors.slate100.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 10.h),

            _buildDiningPillarCard(
              icon: Icons.menu_book_rounded,
              title: 'CULINARY CONCEPT',
              content: '$concept\n($prepTerm)',
              accentColor: AppColors.indigo500,
            ),
            _buildDiningPillarCard(
              icon: Icons.record_voice_over_rounded,
              title: 'ETIQUETTE & SPECIAL REQUESTS',
              content: etiquetteTip,
              accentColor: AppColors.amber500,
            ),
            _buildDiningPillarCard(
              icon: Icons.volume_up_rounded,
              title: 'PRONUNCIATION & PACING',
              content: pronunciationGuide,
              accentColor: AppColors.emerald500,
            ),
            SizedBox(height: 8.h),

            // Model Patron Order Card
            Container(
              key: const Key('gourmet_learn_optimal_card'),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emerald500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 14.sp,
                              color: AppColors.emerald500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'OPTIMAL STATEMENT',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.emerald500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        key: const Key('gourmet_learn_audio_btn'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.emerald500,
                          size: 20.sp,
                        ),
                        onPressed: () {
                          try {
                            if (di.sl.isRegistered<HapticService>()) {
                              di.sl<HapticService>().selection();
                            }
                            if (di.sl.isRegistered<SoundService>()) {
                              di.sl<SoundService>().playCorrect();
                            }
                          } catch (_) {}
                        },
                        tooltip: 'Listen to pronunciation',
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '"$optimalOrderStatement"',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.slate100,
                      fontStyle: FontStyle.italic,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Service Strategy Card
            Container(
              key: const Key('gourmet_learn_strategy_card'),
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate950,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.slate800,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    size: 18.sp,
                    color: AppColors.amber400,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SERVICE STRATEGY',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.amber400,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          keyTakeaway,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.slate300,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
