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

/// Interactive Learn Phase screen for Travel Desk ("Travel Protocol & Transit Navigator").
///
/// Teaches international travel protocols, airport customs, boarding pass routing,
/// baggage through-checking, transit visa rules, and polite desk agent phrasing.
class TravelDeskLearnScreen extends StatefulWidget {
  final int level;

  const TravelDeskLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<TravelDeskLearnScreen> createState() => _TravelDeskLearnScreenState();
}

class _TravelDeskLearnScreenState extends State<TravelDeskLearnScreen> {
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
        'assets/curriculum/roleplay/travelDesk_learn_${startLevel}_$endLevel.json';

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
      gameType: 'travelDesk',
      level: widget.level,
      phase: 'learn',
    );

    try {
      context.pushReplacement(
        '/practice?category=roleplay&gameType=travelDesk&level=${widget.level}',
      );
    } catch (_) {}
  }

  static final List<Map<String, dynamic>> _fallbackQuests = [
    {
      'id': 'td_learn_l1_q1',
      'level': 1,
      'travelContext': 'AIRPORT CHECK-IN & BAGGAGE ROUTING',
      'concept': 'Through-Check Baggage & Fast-Track Transit',
      'prepTerm': 'Through-check, Interline Agreement, Transit Concourse, Expedited Security',
      'protocolRule':
          'Always confirm whether bags are checked to final destination or require customs retrieval at transit hub.',
      'travelerPrompt':
          'My connection in Frankfurt departs in 45 minutes from Concourse B. Can my bags be checked straight through to Berlin?',
      'optimalDeskResponse':
          'Certainly! I have checked your luggage straight through to Berlin Brandenburg. Here are both boarding passes. Please proceed directly to Concourse B Gate 14 via the expedited transit lane.',
      'pronunciationGuide': 'THROO-chek / KAHN-korss / eks-peh-DY-ted',
      'keyTakeaway':
          'Verifying baggage destination tags and boarding deadlines prevents missed flights and misplaced luggage.',
      'travelDocument': 'Baggage Claim Stub & Boarding Pass',
    },
    {
      'id': 'td_learn_l1_q2',
      'level': 1,
      'travelContext': 'BORDER CONTROL & CUSTOMS DECLARATION',
      'concept': 'Agricultural Declarations & Biosecurity Protocol',
      'prepTerm':
          'Biosecurity, Sanitary Certificate, Quarantine, Non-declarable vs Declarable',
      'protocolRule':
          'All agricultural products, seeds, and fresh meats must be formally declared to avoid severe customs fines.',
      'travelerPrompt':
          'I am traveling with vacuum-packed cured ham and artisanal cheeses gifted by family. Do I need to declare these at customs?',
      'optimalDeskResponse':
          'Yes, all cured meats and dairy products must be declared on your customs declaration card upon arrival. The biosecurity inspector will examine them to ensure they comply with import regulations.',
      'pronunciationGuide':
          'BY-oh-seh-kyoor-ih-tee / DEK-luh-RAY-shun / ar-TIZ-uh-nul',
      'keyTakeaway':
          'Full transparency on customs declarations prevents heavy fines and biosecurity confiscation.',
      'travelDocument': 'Customs Declaration Card',
    },
    {
      'id': 'td_learn_l1_q3',
      'level': 1,
      'travelContext': 'PASSPORT CONTROL & TRANSIT VISAS',
      'concept': 'Layover Exits, Shore Passes & Passport Validity',
      'prepTerm':
          'Shore Pass, Bilateral Waiver, Transit Zone, 6-Month Expiration Rule',
      'protocolRule':
          'Passports must hold minimum 6 months validity; layover shore passes require confirmed onward boarding passes within 72 hours.',
      'travelerPrompt':
          'We have an 8-hour layover in Tokyo Narita before our Sydney flight. Can we exit the airport to visit the town without a pre-arranged visa?',
      'optimalDeskResponse':
          'Passengers holding eligible passports may request a temporary Shore Pass at Japanese immigration, provided your onward ticket departs within 72 hours and your passport has at least six months of validity.',
      'pronunciationGuide': 'SHOR pass / by-LAT-er-ul / VUH-lid-ih-tee',
      'keyTakeaway':
          'Shore passes allow short excursion access during international layovers under strict onward ticket validation.',
      'travelDocument': 'Biometric Passport & Onward Ticket',
    },
  ];

  void _playAudio(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final current = _quests[_currentIndex.clamp(0, _quests.length - 1)];
    final travelContext =
        current['travelContext'] as String? ?? 'TRANSIT PROTOCOL';
    final concept = current['concept'] as String? ?? '';
    final prepTerm = current['prepTerm'] as String? ?? '';
    final protocolRule = current['protocolRule'] as String? ?? '';
    final travelerPrompt = current['travelerPrompt'] as String? ?? '';
    final optimalDeskResponse =
        current['optimalDeskResponse'] as String? ?? '';
    final pronunciationGuide =
        current['pronunciationGuide'] as String? ?? '';
    final keyTakeaway = current['keyTakeaway'] as String? ?? '';
    final travelDocument =
        current['travelDocument'] as String? ?? 'Travel Documents';

    return LearnPhaseScaffold(
      title: 'Travel Desk',
      gameType: 'travelDesk',
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
            // Traveler Inquiry Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.cyan400.withValues(alpha: 0.4),
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
                          color: AppColors.cyan400.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flight_takeoff_rounded,
                              size: 14.sp,
                              color: AppColors.cyan400,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'TRAVELER INQUIRY',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.cyan400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        constraints: BoxConstraints(maxWidth: 200.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slate800,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          travelContext,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blue300,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '"$travelerPrompt"',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate100,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.slate800.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: AppColors.cyan400.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.badge_rounded,
                          size: 13.sp,
                          color: AppColors.cyan400,
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            'DOCUMENT: $travelDocument',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: AppColors.blue300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Protocol Knowledge Section
            Text(
              'TRANSIT & CUSTOMS PROTOCOL',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppColors.slate100.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 8.h),

            // Concept & Rule Card
            _buildProtocolPillar(
              icon: Icons.gavel_rounded,
              title: concept.isNotEmpty ? concept : 'Border & Transit Rule',
              description: protocolRule,
              accentColor: AppColors.cyan400,
            ),
            SizedBox(height: 10.h),

            // Terminology Card
            _buildProtocolPillar(
              icon: Icons.menu_book_rounded,
              title: 'TRANSIT TERMINOLOGY',
              description: prepTerm,
              accentColor: AppColors.emerald400,
            ),
            SizedBox(height: 16.h),

            // Calibrated Desk Response Card
            Container(
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
                          color: AppColors.emerald500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 14.sp,
                              color: AppColors.emerald400,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'OPTIMAL DESK RESPONSE',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.emerald400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('learn_audio_button'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.emerald400,
                          size: 20.sp,
                        ),
                        onPressed: () => _playAudio(optimalDeskResponse),
                        tooltip: 'Listen to optimal response',
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    optimalDeskResponse,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.slate100,
                      height: 1.45,
                    ),
                  ),
                  if (pronunciationGuide.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate800,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.record_voice_over_rounded,
                            size: 14.sp,
                            color: AppColors.slate100.withValues(alpha: 0.7),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              'KEY PHONETICS: $pronunciationGuide',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontFamily: 'monospace',
                                color: AppColors.slate100.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Key Takeaway Card
            if (keyTakeaway.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.slate800.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.slate700,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16.sp,
                      color: AppColors.amber400,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        keyTakeaway,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.slate100.withValues(alpha: 0.85),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolPillar({
    required IconData icon,
    required String title,
    required String description,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: accentColor),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              description,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.slate100.withValues(alpha: 0.9),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
