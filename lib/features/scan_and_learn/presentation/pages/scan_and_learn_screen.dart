import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/ml_monetization_controller.dart';
import 'package:vowl/core/utils/ml_services/text_recognition_service.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

import 'package:vowl/features/scan_and_learn/presentation/widgets/scan_bounty_target.dart';
import 'package:vowl/features/scan_and_learn/presentation/widgets/scan_empty_state.dart';
import 'package:vowl/features/scan_and_learn/presentation/widgets/scan_result_block.dart';
import 'package:vowl/core/utils/widgets/language_selection_bottom_sheet.dart';
import 'package:vowl/core/utils/widgets/translation_download_dialog.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';

class ScanAndLearnScreen extends StatefulWidget {
  const ScanAndLearnScreen({super.key});

  @override
  State<ScanAndLearnScreen> createState() => _ScanAndLearnScreenState();
}

class _ScanAndLearnScreenState extends State<ScanAndLearnScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;
  RecognizedText? _recognizedText;
  bool _isProcessing = false;
  
  final Map<int, String> _translations = {};
  final Map<int, bool> _isTranslating = {};

  List<String> _bountyOptions = [
    "Restaurant", "Exit", "Push", "Open", "Danger", "Stop", 
    "Welcome", "Toilet", "Police", "Hotel", "Bus", "Ticket"
  ];
  late String _currentBounty;
  bool _bountyFound = false;
  bool _bountiesLoaded = false;

  late final AnimationController _scannerController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _currentBounty = _bountyOptions[Random().nextInt(_bountyOptions.length)];
    _scannerController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    _loadBounties();
  }

  Future<void> _loadBounties() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/scan_bounties.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      if (jsonList.isNotEmpty) {
        _bountyOptions = jsonList.cast<String>();
      }
    } catch (e) {
      // Keep fallback
    }
    if (mounted) {
      setState(() {
        _currentBounty = _bountyOptions[Random().nextInt(_bountyOptions.length)];
        _bountiesLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _pickAndScanImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    if (!mounted) return;

    // Trigger Monetization Gate before processing
    MlMonetizationController.attemptFeature(
      context,
      featureIcon: Icons.document_scanner_rounded,
      featureTitle: context.tr('translation.scan_learn_title', fallback: 'Scan & Learn'),
      featureSubtitle: context.tr('translation.scan_learn_desc', fallback: 'Extract and translate text from images instantly.'),
      adButtonLabel: context.tr('translation.scan_learn_ad', fallback: 'Watch Ad to Scan'),
      onSuccess: () => _processImage(image.path),
    );
  }

  Future<void> _processImage(String path) async {
    setState(() {
      _imagePath = path;
      _isProcessing = true;
      _recognizedText = null;
      _bountyFound = false;
      _translations.clear();
      _isTranslating.clear();
    });

    final recognized = await di.sl<TextRecognitionService>().recognizeFromFile(path);

    bool found = false;
    if (recognized != null) {
      found = recognized.text.toLowerCase().contains(_currentBounty.toLowerCase());
    }

    bool limitReached = false;

    if (found) {
       _bountyFound = true;
       _confettiController.play();
       di.sl<HapticService>().heavy();
       di.sl<SoundService>().playCorrect();
       
       try {
         final prefs = await SharedPreferences.getInstance();
         final today = DateTime.now().toIso8601String().substring(0, 10);
         final lastDate = prefs.getString('scan_bounty_date') ?? '';
         int count = prefs.getInt('scan_bounty_count') ?? 0;

         if (lastDate != today) {
           count = 0;
           await prefs.setString('scan_bounty_date', today);
         }

         if (count < 3) {
           await prefs.setInt('scan_bounty_count', count + 1);
           int total = prefs.getInt('scan_total_bounties') ?? 0;
           total++;
           await prefs.setInt('scan_total_bounties', total);

           await di.sl<UpdateUserRewards>()(
             UpdateUserRewardsParams(
               xpIncrease: 5,
               coinIncrease: 5,
               level: total,
               gameType: 'ScanAndLearn',
             ),
           );
         } else {
           limitReached = true;
         }
       } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _recognizedText = recognized;
      });
      
      if (found) {
         CustomSnackBar.show(
           context: context,
           message: limitReached 
               ? context.tr('vocabulary.bounty_limit', fallback: 'Word Found! (Daily limit of 3 reached)')
               : context.tr('vocabulary.bounty_found', fallback: 'Word Found! +5 XP & 5 Coins!'),
           type: limitReached ? CustomSnackBarType.info : CustomSnackBarType.success,
         );
      }
    }
  }

  Future<void> _translateBlock(int index, String text) async {
    final isConfigured = await di.sl<TranslationService>().isLanguageConfigured();
    
    if (!mounted) return;

    if (!isConfigured) {
      await LanguageSelectionBottomSheet.show(context);
      if (!mounted) return;
      final configuredNow = await di.sl<TranslationService>().isLanguageConfigured();
      if (!configuredNow) return; // User closed sheet without selecting a language
    }

    MlMonetizationController.attemptFeature(
      context,
      featureIcon: Icons.g_translate_rounded,
      featureTitle: context.tr('vocabulary.translate_title', fallback: 'Translate Text'),
      featureSubtitle: context.tr('vocabulary.translate_desc', fallback: 'Instantly translate this text to your native language.'),
      adButtonLabel: context.tr('vocabulary.translate_ad', fallback: 'Watch Ad to Translate'),
      onSuccess: () async {
        setState(() {
          _isTranslating[index] = true;
        });

        try {
          final isDownloaded = await di.sl<TranslationService>().isTargetModelDownloaded();

          if (!isDownloaded) {
            if (mounted) {
              await TranslationDownloadDialog.show(context);
            }
            final isDownloadedNow = await di.sl<TranslationService>().isTargetModelDownloaded();
            if (!isDownloadedNow) {
              if (mounted) setState(() { _isTranslating[index] = false; });
              return;
            }
          }

          final translated = await di.sl<TranslationService>().translate(text);
          if (mounted) {
            setState(() {
              _translations[index] = translated;
              _isTranslating[index] = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isTranslating[index] = false;
            });
            CustomSnackBar.show(
              context: context,
              message: e.toString().replaceAll('Exception: ', ''),
              type: CustomSnackBarType.error,
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_bountiesLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        GameDialogHelper.showExitConfirmation(
          context,
          title: context.tr('translation.quit_scan_title', fallback: 'QUIT SCANNING?'),
          description: context.tr('translation.quit_scan_desc', fallback: 'Your scanned text will be lost. Are you sure you want to quit?'),
          onQuit: () => context.pop(),
        );
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Layer (Image or Gradient)
          if (_imagePath != null)
             Image.file(File(_imagePath!), fit: BoxFit.cover)
          else
             const MeshGradientBackground(showLetters: false),
             
          // 2. Dark Overlay for better contrast when image is present
          if (_imagePath != null)
             Container(color: Colors.black.withValues(alpha: 0.5))
          else
             Container(color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.3)),

          // 3. Cinematic Laser Scanner (only when processing)
          if (_isProcessing)
             _buildLaserScanner(),

          // 4. UI Layer
          CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildSliverAppBar(context, isDark),
              SliverToBoxAdapter(
                 child: ScanBountyTarget(currentBounty: _currentBounty, bountyFound: _bountyFound),
              ),
              if (_imagePath == null)
                 SliverFillRemaining(
                    hasScrollBody: false,
                    child: ScanEmptyState(onPickImage: _pickAndScanImage),
                 )
              else
                 _buildSliverResults(isDark),
              
              SliverToBoxAdapter(child: SizedBox(height: 120.h)),
            ],
          ),
          
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              numberOfParticles: 50,
              gravity: 0.1,
            ),
          ),
          
          if (_imagePath != null && !_isProcessing)
             Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildRetakeBar(),
             ),
        ],
      ),
     ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: kToolbarHeight + 10.h,
      iconTheme: IconThemeData(color: _imagePath != null || isDark ? Colors.white : Colors.black87),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.3),
              border: Border(bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))),
            ),
          ),
        ),
      ),
      leading: IconButton(
         icon: Icon(Icons.arrow_back_ios_new_rounded, color: _imagePath != null || isDark ? Colors.white : Colors.black87),
         onPressed: () {
           GameDialogHelper.showExitConfirmation(
             context,
             title: context.tr('translation.quit_scan_title', fallback: 'QUIT SCANNING?'),
             description: context.tr('translation.quit_scan_desc', fallback: 'Your scanned text will be lost. Are you sure you want to quit?'),
             onQuit: () => context.pop(),
           );
         },
      ),
      title: Text(
        context.tr('translation.scan_learn_title', fallback: 'Scan & Learn'),
        style: TextStyle(fontFamily: 'Outfit', fontSize: 22.sp, fontWeight: FontWeight.w900, color: _imagePath != null || isDark ? Colors.white : Colors.black87),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSliverResults(bool isDark) {
     if (_isProcessing || _recognizedText == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

     if (_recognizedText!.blocks.isEmpty) {
        return SliverToBoxAdapter(
           child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
              child: Center(
                 child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: BackdropFilter(
                       filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                       child: Container(
                          padding: EdgeInsets.all(32.r),
                          color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
                          child: Text(
                            context.tr('translation.no_results', fallback: 'No text extracted yet.'),
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18.sp, fontFamily: 'Outfit', fontWeight: FontWeight.w600),
                          ),
                       ),
                    ),
                 ),
              ),
           ),
        );
     }

     return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        sliver: SliverList(
           delegate: SliverChildBuilderDelegate(
              (context, index) {
                 return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: ScanResultBlock(
                      block: _recognizedText!.blocks[index],
                      index: index,
                      translatedText: _translations[index],
                      isTranslating: _isTranslating[index] ?? false,
                      onTranslate: _translateBlock,
                    ),
                 );
              },
              childCount: _recognizedText!.blocks.length,
           ),
        ),
     );
  }

  Widget _buildRetakeBar() {
     return Padding(
        padding: EdgeInsets.all(24.w),
        child: ScaleButton(
           onTap: () {
              setState(() {
                 _imagePath = null;
                 _recognizedText = null;
                 _currentBounty = _bountyOptions[Random().nextInt(_bountyOptions.length)];
                 _bountyFound = false;
              });
           },
           child: ClipRRect(
              borderRadius: BorderRadius.circular(100.r),
              child: BackdropFilter(
                 filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                 child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    decoration: BoxDecoration(
                       color: const Color(0xFF6366F1),
                       borderRadius: BorderRadius.circular(100.r),
                       boxShadow: [
                         BoxShadow(
                           color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                           blurRadius: 15,
                           offset: const Offset(0, 5),
                         )
                       ],
                    ),
                    child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                          Icon(LucideIcons.camera, color: Colors.white, size: 22.r),
                          SizedBox(width: 12.w),
                          Text(
                             context.tr('translation.retake', fallback: 'Scan Another Page'),
                             style: TextStyle(fontFamily: 'Outfit', fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                       ],
                    ),
                 ),
              ),
           ),
        ),
     ).animate().fadeIn().slideY(begin: 0.5);
  }

  Widget _buildLaserScanner() {
     return RepaintBoundary(
        child: AnimatedBuilder(
           animation: _scannerController,
           builder: (context, child) {
              return Align(
                 alignment: Alignment(0, -1.0 + (_scannerController.value * 2.0)),
                 child: child,
              );
           },
           child: Container(
              height: 6.h,
              width: double.infinity,
              decoration: BoxDecoration(
                 color: const Color(0xFF6366F1), // Indigo color to differentiate from Vocab (Teal)
                 boxShadow: [
                    BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.9), blurRadius: 15, spreadRadius: 3),
                    BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 8),
                 ],
              ),
           ),
        ),
     );
  }
}
