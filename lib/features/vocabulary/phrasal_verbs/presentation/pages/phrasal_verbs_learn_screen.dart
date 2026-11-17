import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Interactive Learn Phase screen for Phrasal Verbs: "Phrasal Anatomy & Particle Vault".
///
/// Dissects base verbs and their combining particles (e.g., WAKE + UP) to demystify
/// idiomatic English meanings, literal vs. figurative distinctions, and native speaker nuances.
class PhrasalVerbsLearnScreen extends StatefulWidget {
  final int level;

  const PhrasalVerbsLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<PhrasalVerbsLearnScreen> createState() =>
      _PhrasalVerbsLearnScreenState();
}

class _PhrasalVerbsLearnScreenState extends State<PhrasalVerbsLearnScreen> {
  List<PhasedQuest> _quests = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLearnQuests();
  }

  Future<void> _loadLearnQuests() async {
    try {
      final batchIndex = ((widget.level - 1) ~/ 10) + 1;
      final startLevel = (batchIndex - 1) * 10 + 1;
      final endLevel = batchIndex * 10;
      final path =
          'assets/curriculum/vocabulary/phrasalVerbs_learn_${startLevel}_$endLevel.json';
      final jsonStr = await rootBundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);

      final levelQuests =
          batch.quests.where((q) => q.level == widget.level).toList();

      if (mounted) {
        setState(() {
          _quests = levelQuests.isNotEmpty ? levelQuests : batch.quests;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quests = [
            PhasedQuest(
              id: 'FALLBACK_PV_L${widget.level}_1',
              level: widget.level,
              conceptTitle: 'Phrasal Anatomy: WAKE UP',
              word: 'WAKE UP',
              definition:
                  "'Wake up' means to stop sleeping and become conscious. It's different from 'get up,' which means to physically leave the bed.",
              example:
                  'My alarm rang at six, but I didn\'t wake UP until the second alarm at seven.',
              nativeTip:
                  'This is about becoming conscious after sleep, not getting out of bed yet.',
              visualAnchor: '🗝️ WAKE + UP ➔ WAKE UP',
              rawExtra: const {
                'verb': 'WAKE',
                'particle': 'UP',
                'literalVsFigurative':
                    'This is a literal physical process: your brain moves from sleep to alertness.',
                'particleInsight':
                    'The particle UP combines with the verb WAKE to specialize or transform its action.',
              },
            ),
          ];
          _isLoading = false;
        });
      }
    }
  }

  void _speak(String text) {
    if (di.sl.isRegistered<TtsService>()) {
      di.sl<TtsService>().speak(text);
    }
  }

  void _nextVerb() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishLearnPhase();
    }
  }

  void _finishLearnPhase() {
    final target =
        '/practice?category=vocabulary&gameType=phrasalVerbs&level=${widget.level}';
    context.pushReplacement(target);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);
    final primaryColor = theme.primaryColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.slate950 : AppColors.slate50,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    final currentQuest = _quests[_currentIndex];
    final fullWord = currentQuest.word ?? 'VERB';
    final wordParts = fullWord.split(' ');
    final verb = (currentQuest.rawExtra['verb'] as String?) ?? wordParts.first;
    final particle = (currentQuest.rawExtra['particle'] as String?) ??
        (wordParts.length > 1 ? wordParts.sublist(1).join(' ') : '');
    final literalVsFig =
        (currentQuest.rawExtra['literalVsFigurative'] as String?) ??
            'Standard idiomatic phrasal verb construction.';
    final particleInsight =
        (currentQuest.rawExtra['particleInsight'] as String?) ??
            "The particle '$particle' completes the verb.";

    return LearnPhaseScaffold(
      title: 'Phrasal Anatomy',
      gameType: 'phrasalVerbs',
      level: widget.level,
      onComplete: _finishLearnPhase,
      child: Column(
        children: [
          // Step Counter Card
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.key_rounded, size: 14.sp, color: primaryColor),
                      SizedBox(width: 6.w),
                      Text(
                        'Verb ${_currentIndex + 1} of ${_quests.length}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _speak(fullWord),
                  icon: Icon(
                    Icons.volume_up_rounded,
                    size: 18.sp,
                    color: primaryColor,
                  ),
                  label: Text(
                    'Pronounce',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Scrollable Pedagogical Card
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Phrasal Formula Equation Banner
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                          primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'PHRASAL COMBINATION',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildFormulaPart(verb, 'VERB', primaryColor, isDark),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                child: Text(
                                  '+',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              _buildFormulaPart(
                                  particle, 'PARTICLE', AppColors.amber500, isDark),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                child: Text(
                                  '=',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              _buildFormulaResult(fullWord, isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // 2. Meaning & Definition Card
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate900 : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isDark ? AppColors.slate800 : AppColors.slate200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_stories_rounded,
                                size: 18.sp, color: primaryColor),
                            SizedBox(width: 8.w),
                            Text(
                              'CORE MEANING',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          currentQuest.definition ?? '',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // 3. Example Context Sentence Card
                  if (currentQuest.example != null &&
                      currentQuest.example!.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slate900 : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDark ? AppColors.slate800 : AppColors.slate200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.format_quote_rounded,
                                  size: 18.sp, color: AppColors.emerald500),
                              SizedBox(width: 8.w),
                              Text(
                                'AUTHENTIC USAGE',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: AppColors.emerald500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '"${currentQuest.example}"',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : AppColors.slate900,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 12.h),

                  // 4. Literal vs Figurative Analysis Card
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate900 : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isDark ? AppColors.slate800 : AppColors.slate200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.compare_arrows_rounded,
                                size: 18.sp, color: AppColors.blue500),
                            SizedBox(width: 8.w),
                            Text(
                              'LITERAL VS FIGURATIVE',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: AppColors.blue500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          literalVsFig,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            height: 1.4,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.85)
                                : AppColors.slate700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // 5. Particle Insight & Native Tip Box
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.amber500.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.amber500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_rounded,
                                size: 18.sp, color: AppColors.amber500),
                            SizedBox(width: 8.w),
                            Text(
                              'NATIVE SPEAKER PRO-TIP',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: AppColors.amber500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          currentQuest.nativeTip ?? particleInsight,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            height: 1.4,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : AppColors.slate900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate900 : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _nextVerb,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentIndex < _quests.length - 1
                              ? 'Got It! Next Phrasal Verb'
                              : 'Enter Practice Gym ➔',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          _currentIndex < _quests.length - 1
                              ? Icons.arrow_forward_rounded
                              : Icons.fitness_center_rounded,
                          size: 20.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaPart(
      String text, String subtitle, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaResult(String phrasalVerb, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? AppColors.slate800 : AppColors.slate200,
        ),
      ),
      child: Column(
        children: [
          Text(
            phrasalVerb,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'COMBINED',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
