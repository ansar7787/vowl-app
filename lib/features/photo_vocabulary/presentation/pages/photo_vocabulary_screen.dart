import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/ml_monetization_controller.dart';
import 'package:vowl/core/utils/ml_services/image_labeling_service.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/features/photo_vocabulary/utils/photo_vocabulary_dictionary.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/photo_vocabulary/presentation/widgets/photo_bounty_target.dart';
import 'package:vowl/features/photo_vocabulary/presentation/widgets/photo_empty_state.dart';
import 'package:vowl/features/photo_vocabulary/presentation/widgets/photo_result_chip.dart';
import 'package:vowl/core/utils/widgets/language_selection_bottom_sheet.dart';
import 'package:vowl/core/utils/widgets/translation_download_dialog.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

class PhotoVocabularyScreen extends StatefulWidget {
  const PhotoVocabularyScreen({super.key});

  @override
  State<PhotoVocabularyScreen> createState() => _PhotoVocabularyScreenState();
}

class _PhotoVocabularyScreenState extends State<PhotoVocabularyScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  String? _imagePathVal;
  List<ImageLabel>? _labelsVal;
  bool _isProcessingVal = false;
  bool _hasErrorVal = false;

  Map<int, String> _translationsVal = {};
  Map<int, bool> _isTranslatingVal = {};

  List<String> _bountyOptions = [
    'Laptop',
    'Computer',
    'Mobile phone',
    'Coffee cup',
    'Mug',
    'Chair',
    'Table',
    'Shoe',
    'Glasses',
    'Pen',
    'Book',
    'Plant',
  ];
  String _currentBountyVal = '';
  bool _bountyFoundVal = false;
  bool _bountiesLoadedVal = false;
  int _dailyBountyCountVal = 0;
  static const int _dailyBountyLimit = 3;
  Set<String> _savedWords = {};

  void _updateState() {
    if (mounted) setState(() {});
  }

  late final AnimationController _scannerController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _currentBountyVal = _bountyOptions[Random().nextInt(_bountyOptions.length)];
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _loadBounties();
  }

  Future<void> _loadBounties() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/photo_bounties.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonString);
      if (jsonList.isNotEmpty) {
        _bountyOptions = jsonList.cast<String>();
      }
    } catch (_) {
      // Retain fallback options
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final lastDate = prefs.getString('photo_bounty_date') ?? '';
      if (lastDate == today) {
        _dailyBountyCountVal = prefs.getInt('photo_bounty_count') ?? 0;
      } else {
        _dailyBountyCountVal = 0;
        await prefs.setString('photo_bounty_date', today);
        await prefs.setInt('photo_bounty_count', 0);
      }
      final savedList = prefs.getStringList('photo_vocab_saved_words') ?? [];
      _savedWords = savedList.toSet();
    } catch (_) {}

    if (mounted) {
      _currentBountyVal =
          _bountyOptions[Random().nextInt(_bountyOptions.length)];
      _bountiesLoadedVal = true;
      _updateState();
    }
  }

  void _onShuffleBounty() {
    if (_bountyOptions.length <= 1) return;
    try {
      di.sl<HapticService>().selection();
      di.sl<SoundService>().playClick();
    } catch (_) {}

    final available = _bountyOptions
        .where((b) => b.toLowerCase() != _currentBountyVal.toLowerCase())
        .toList();
    if (available.isNotEmpty) {
      _currentBountyVal = available[Random().nextInt(available.length)];
      _updateState();
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _toggleSaveWord(String word) async {
    try {
      di.sl<HapticService>().selection();
      di.sl<SoundService>().playClick();
    } catch (_) {}

    final key = word.trim().toLowerCase();
    final willSave = !_savedWords.contains(key);

    if (willSave) {
      _savedWords.add(key);
    } else {
      _savedWords.remove(key);
    }
    _updateState();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('photo_vocab_saved_words', _savedWords.toList());
    } catch (_) {}

    if (mounted) {
      CustomSnackBar.show(
        context: context,
        message: willSave
            ? context.tr(
                'vocabulary.word_saved_to_notebook',
                args: [word],
                fallback: 'Added "$word" to your Vocab Notebook! ⭐',
              )
            : context.tr(
                'vocabulary.word_removed_from_notebook',
                args: [word],
                fallback: 'Removed "$word" from your Vocab Notebook',
              ),
        type: willSave
            ? CustomSnackBarType.success
            : CustomSnackBarType.info,
      );
    }
  }

  Future<void> _pickAndLabelImage(ImageSource source) async {
    XFile? image;
    try {
      image = await _picker.pickImage(source: source);
    } on PlatformException {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'vocabulary.camera_permission_error',
            fallback: 'Camera or photo permission denied. Please grant access in settings.',
          ),
          type: CustomSnackBarType.error,
        );
      }
      return;
    } catch (_) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'vocabulary.image_pick_error',
            fallback: 'Unable to select photo. Please try again.',
          ),
          type: CustomSnackBarType.error,
        );
      }
      return;
    }

    if (image == null) return;
    if (!mounted) return;

    // Trigger Monetization Gate before processing
    MlMonetizationController.attemptFeature(
      context,
      featureIcon: Icons.camera_alt_rounded,
      featureTitle: context.tr(
        'vocabulary.photo_vocab_title',
        fallback: 'Photo Vocabulary',
      ),
      featureSubtitle: context.tr(
        'vocabulary.photo_vocab_desc',
        fallback: 'Discover words from the world around you!',
      ),
      adButtonLabel: context.tr(
        'vocabulary.photo_vocab_ad',
        fallback: 'Watch Ad to Analyze',
      ),
      onSuccess: () => _processImage(image!.path),
    );
  }

  Future<void> _processImage(String path) async {
    _imagePathVal = path;
    _isProcessingVal = true;
    _labelsVal = null;
    _bountyFoundVal = false;
    _hasErrorVal = false;
    _translationsVal = {};
    _isTranslatingVal = {};
    _updateState();

    try {
      final allLabels = await di.sl<ImageLabelingService>().labelImage(path);
      // Filter out low-confidence guesses to prevent noisy false positives
      final confidentLabels = allLabels
          .where((l) => l.confidence >= 0.65)
          .toList();

      bool found = false;
      for (final l in confidentLabels) {
        if (PhotoVocabularyDictionary.isBountyMatch(_currentBountyVal, l.label)) {
          found = true;
          break;
        }
      }

      bool limitReached = false;

      if (found) {
        _bountyFoundVal = true;
        _confettiController.play();
        try {
          di.sl<HapticService>().heavy();
          di.sl<SoundService>().playCorrect();
        } catch (_) {}

        try {
          final prefs = await SharedPreferences.getInstance();
          final today = DateTime.now().toIso8601String().substring(0, 10);
          final lastDate = prefs.getString('photo_bounty_date') ?? '';
          int count = prefs.getInt('photo_bounty_count') ?? 0;

          if (lastDate != today) {
            count = 0;
            await prefs.setString('photo_bounty_date', today);
          }

          if (count < _dailyBountyLimit) {
            count++;
            _dailyBountyCountVal = count;
            await prefs.setInt('photo_bounty_count', count);
            int total = prefs.getInt('photo_total_bounties') ?? 0;
            total++;
            await prefs.setInt('photo_total_bounties', total);

            await di.sl<UpdateUserRewards>()(
              UpdateUserRewardsParams(
                xpIncrease: 5,
                coinIncrease: 10,
                level: total,
                gameType: 'PhotoVocabulary',
              ),
            );
          } else {
            limitReached = true;
            _dailyBountyCountVal = count;
          }
        } catch (_) {}
      }

      if (mounted) {
        _isProcessingVal = false;
        _labelsVal = confidentLabels;
        _updateState();

        if (found) {
          CustomSnackBar.show(
            context: context,
            message: limitReached
                ? context.tr(
                    'vocabulary.bounty_limit',
                    fallback: 'Bounty Found! (Daily limit of 3 reached)',
                  )
                : context.tr(
                    'vocabulary.bounty_found',
                    fallback: 'Bounty Found! +5 XP & 10 Coins!',
                  ),
            type: limitReached
                ? CustomSnackBarType.info
                : CustomSnackBarType.success,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        _isProcessingVal = false;
        _hasErrorVal = true;
        _updateState();
      }
      return;
    }
  }

  Future<void> _translateLabel(int index, String text) async {
    final isConfigured = await di
        .sl<TranslationService>()
        .isLanguageConfigured();

    if (!mounted) return;

    if (!isConfigured) {
      await LanguageSelectionBottomSheet.show(context);
      if (!mounted) return;
      final configuredNow = await di
          .sl<TranslationService>()
          .isLanguageConfigured();
      if (!mounted) return;
      if (!configuredNow) {
        return; // User closed sheet without selecting a language
      }
    }

    MlMonetizationController.attemptFeature(
      context,
      featureIcon: Icons.g_translate_rounded,
      featureTitle: context.tr(
        'vocabulary.translate_title',
        fallback: 'Translate Word',
      ),
      featureSubtitle: context.tr(
        'vocabulary.translate_desc',
        fallback: 'Instantly translate this word to your native language.',
      ),
      adButtonLabel: context.tr(
        'vocabulary.translate_ad',
        fallback: 'Watch Ad to Translate',
      ),
      onSuccess: () async {
        _isTranslatingVal[index] = true;
        _updateState();

        try {
          final isDownloaded = await di
              .sl<TranslationService>()
              .isTargetModelDownloaded();

          if (!isDownloaded) {
            if (mounted) {
              await TranslationDownloadDialog.show(context);
            }
            final isDownloadedNow = await di
                .sl<TranslationService>()
                .isTargetModelDownloaded();
            if (!isDownloadedNow) {
              if (mounted) {
                _isTranslatingVal[index] = false;
                _updateState();
              }
              return;
            }
          }

          final entry = PhotoVocabularyDictionary.getEntry(text);
          final textToTranslate = '$text\n\n${entry.example}';
          final translated = await di.sl<TranslationService>().translate(
            textToTranslate,
          );
          if (mounted) {
            _translationsVal[index] = translated;
            _isTranslatingVal[index] = false;
            _updateState();
          }
        } catch (e) {
          if (mounted) {
            _isTranslatingVal[index] = false;
            _updateState();
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

  void _playPronunciation(String text) {
    try {
      di.sl<SoundService>().playTts(text, speed: 0.45, locale: 'en-US');
    } catch (_) {}
  }

  void _resetForNewPhoto() {
    _imagePathVal = null;
    _labelsVal = null;
    _isProcessingVal = false;
    _hasErrorVal = false;
    _translationsVal = {};
    _isTranslatingVal = {};
    _bountyFoundVal = false;
    _currentBountyVal = _bountyOptions[Random().nextInt(_bountyOptions.length)];
    _updateState();
  }

  @override
  Widget build(BuildContext context) {
    if (!_bountiesLoadedVal) {
      return const Scaffold(
        body: SafeArea(
          child: GameShimmerLoading(primaryColor: AppColors.teal500),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _imagePathVal == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        GameDialogHelper.showExitConfirmation(
          context,
          title: context.tr(
            'vocabulary.quit_photo_title',
            fallback: 'QUIT EXPLORING?',
          ),
          description: context.tr(
            'vocabulary.quit_photo_desc',
            fallback:
                'Your current photo will be lost. Are you sure you want to quit?',
          ),
          onQuit: () => context.pop(),
        );
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Layer (Downsampled Image or Gradient)
            if (_imagePathVal != null)
              Image(
                image: ResizeImage(
                  FileImage(File(_imagePathVal!)),
                  width: 1080,
                ),
                fit: BoxFit.cover,
              )
            else
              const MeshGradientBackground(showLetters: false),

            // 2. Overlay for contrast
            if (_imagePathVal != null)
              Container(color: Colors.black.withValues(alpha: 0.55))
            else
              Container(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.3),
              ),

            // 3. Cinematic Laser Scanner (only when analyzing)
            if (_isProcessingVal) _buildLaserScanner(),

            // 4. Scrollable UI Layer
            Scrollbar(
              radius: Radius.circular(8.r),
              thickness: 4.w,
              interactive: true,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
              slivers: [
                _buildSliverAppBar(context, isDark),
                SliverToBoxAdapter(
                  child: PhotoBountyTarget(
                    currentBounty: _currentBountyVal,
                    bountyFound: _bountyFoundVal,
                    dailyCount: _dailyBountyCountVal,
                    dailyLimit: _dailyBountyLimit,
                    onShuffle: _onShuffleBounty,
                  ),
                ),
                if (_imagePathVal == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: PhotoEmptyState(onPickImage: _pickAndLabelImage),
                  )
                else ...[
                  if (!_isProcessingVal &&
                      !_hasErrorVal &&
                      _labelsVal != null &&
                      _labelsVal!.isNotEmpty)
                    _buildPhotoSummary(isDark),
                  _buildSliverResults(isDark),
                ],

                // Safe bottom padding for floating retake button
                SliverToBoxAdapter(child: SizedBox(height: 120.h)),
              ],
            ),
          ),

            // Confetti Celebration
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
                numberOfParticles: 50,
                gravity: 0.1,
              ),
            ),

            // Floating Retake Bar
            if (_imagePathVal != null && !_isProcessingVal)
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
      iconTheme: IconThemeData(
        color: _imagePathVal != null || isDark ? Colors.white : Colors.black87,
      ),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _imagePathVal != null || isDark
              ? Colors.white
              : Colors.black87,
        ),
        onPressed: () {
          if (_imagePathVal == null) {
            context.pop();
            return;
          }
          GameDialogHelper.showExitConfirmation(
            context,
            title: context.tr(
              'vocabulary.quit_photo_title',
              fallback: 'QUIT EXPLORING?',
            ),
            description: context.tr(
              'vocabulary.quit_photo_desc',
              fallback:
                  'Your current photo will be lost. Are you sure you want to quit?',
            ),
            onQuit: () => context.pop(),
          );
        },
      ),
      title: Text(
        context.tr(
          'vocabulary.photo_vocab_title',
          fallback: 'Photo Vocabulary',
        ),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 22.sp,
          fontWeight: FontWeight.w800,
          color: _imagePathVal != null || isDark
              ? Colors.white
              : Colors.black87,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_savedWords.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.amber.shade400.withValues(alpha: 0.15)
                      : Colors.amber.shade600.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark ? Colors.amber.shade400 : Colors.amber.shade600,
                    width: 1.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: isDark ? Colors.amber.shade300 : AppColors.amber500,
                      size: 14.r,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${_savedWords.length}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.amber.shade300 : AppColors.amber500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Summary header showing detected count after scan.
  Widget _buildPhotoSummary(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.scanLine,
                    size: 16.r,
                    color: AppColors.teal500,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    context.tr(
                      'vocabulary.photo_summary',
                      args: [_labelsVal!.length.toString()],
                      fallback: '${_labelsVal!.length} objects detected',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildSliverResults(bool isDark) {
    if (_isProcessingVal) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (_hasErrorVal) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
          child: Center(
            child: Container(
              padding: EdgeInsets.all(28.r),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    color: isDark
                        ? AppColors.gameIncorrect.withValues(alpha: 0.8)
                        : AppColors.gameIncorrect,
                    size: 46.r,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    context.tr(
                      'vocabulary.processing_error',
                      fallback: 'Something went wrong',
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 19.sp,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    context.tr(
                      'vocabulary.processing_error_desc',
                      fallback:
                          'We couldn\'t analyze this image. Try again with a clearer photo.',
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13.5.sp,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20.h),
                  ScaleButton(
                    onTap: () {
                      _imagePathVal = null;
                      _labelsVal = null;
                      _hasErrorVal = false;
                      _updateState();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 13.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.teal500,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.camera,
                            color: Colors.white,
                            size: 19.r,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            context.tr(
                              'vocabulary.try_again',
                              fallback: 'Try Again',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_labelsVal == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (_labelsVal!.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
          child: Center(
            child: Container(
              padding: EdgeInsets.all(28.r),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.searchX,
                    color: isDark ? Colors.white54 : Colors.black38,
                    size: 46.r,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    context.tr(
                      'vocabulary.no_objects',
                      fallback: 'No objects recognized',
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 19.sp,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 18.h),
                  _buildTip(
                    isDark,
                    icon: LucideIcons.sun,
                    text: context.tr(
                      'vocabulary.tip_lighting',
                      fallback: 'Try better lighting',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildTip(
                    isDark,
                    icon: LucideIcons.zoomIn,
                    text: context.tr(
                      'vocabulary.tip_closer',
                      fallback: 'Move closer to objects',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildTip(
                    isDark,
                    icon: LucideIcons.focus,
                    text: context.tr(
                      'vocabulary.tip_blur',
                      fallback: 'Avoid blurry photos',
                    ),
                  ),
                  SizedBox(height: 22.h),
                  ScaleButton(
                    onTap: () {
                      _imagePathVal = null;
                      _labelsVal = null;
                      _hasErrorVal = false;
                      _updateState();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 13.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.teal500,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.camera,
                            color: Colors.white,
                            size: 19.r,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            context.tr(
                              'vocabulary.try_again',
                              fallback: 'Try Again',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final label = _labelsVal![index];
          final isBounty = PhotoVocabularyDictionary.isBountyMatch(
            _currentBountyVal,
            label.label,
          );

          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: PhotoResultChip(
              label: label,
              index: index,
              isBountyTarget: isBounty,
              isSaved: _savedWords.contains(label.label.trim().toLowerCase()),
              translatedText: _translationsVal[index],
              isTranslating: _isTranslatingVal[index] ?? false,
              onTranslate: _translateLabel,
              onPlayPronunciation: _playPronunciation,
              onToggleSave: _toggleSaveWord,
            ),
          );
        }, childCount: _labelsVal!.length),
      ),
    );
  }

  Widget _buildTip(
    bool isDark, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15.r, color: isDark ? Colors.white38 : Colors.black38),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRetakeBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: ScaleButton(
          onTap: () {
            if (_translationsVal.isNotEmpty) {
              GameDialogHelper.showExitConfirmation(
                context,
                title: context.tr(
                  'vocabulary.retake_title',
                  fallback: 'RETAKE PHOTO?',
                ),
                description: context.tr(
                  'vocabulary.retake_desc',
                  fallback: 'Your current photo and translations will be cleared.',
                ),
                onQuit: () => _resetForNewPhoto(),
              );
            } else {
              _resetForNewPhoto();
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 17.h),
                decoration: BoxDecoration(
                  color: AppColors.teal500,
                  borderRadius: BorderRadius.circular(100.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal500.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.camera, color: Colors.white, size: 21.r),
                    SizedBox(width: 10.w),
                    Text(
                      context.tr(
                        'vocabulary.retake',
                        fallback: 'Take Another Photo',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.4);
  }

  Widget _buildLaserScanner() {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dark overlay while scanning for dramatic laser contrast
          Container(color: Colors.black.withValues(alpha: 0.45)),
          // HUD Reticle Corners with Confined Scanning Laser
          Center(
            child: Container(
              width: 270.w,
              height: 270.w,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.35),
                  width: 1.5.w,
                ),
                color: Colors.black.withValues(alpha: 0.2),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Moving Laser Line - CONFINED INSIDE RETICLE BOX
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _scannerController,
                      builder: (context, child) {
                        return Align(
                          alignment: Alignment(
                            0,
                            -1.0 + (_scannerController.value * 2.0),
                          ),
                          child: child,
                        );
                      },
                      child: Container(
                        height: 3.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.teal500.withValues(alpha: 0.0),
                              AppColors.teal500,
                              Colors.white,
                              AppColors.teal500,
                              AppColors.teal500.withValues(alpha: 0.0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal500,
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.8),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top Left Corner
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.teal500,
                            width: 3.5.w,
                          ),
                          left: BorderSide(
                            color: AppColors.teal500,
                            width: 3.5.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Top Right Corner
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.teal500,
                            width: 3.5.w,
                          ),
                          right: BorderSide(
                            color: AppColors.teal500,
                            width: 3.5.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom Left Corner
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.teal500,
                            width: 3.5.w,
                          ),
                          left: BorderSide(
                            color: AppColors.teal500,
                            width: 3.5.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom Right Corner
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.teal500,
                            width: 3.5.w,
                          ),
                          right: BorderSide(
                            color: AppColors.teal500,
                            width: 3.5.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Scanner Center HUD
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          color: const Color(0xFF14B8A6).withValues(alpha: 0.9),
                          size: 46.r,
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(
                          duration: 1.seconds,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16.h),
                        const _AnimatedScannerText(),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
              begin: 0.98,
              end: 1.02,
              duration: 1.seconds,
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedScannerText extends StatefulWidget {
  const _AnimatedScannerText();

  @override
  State<_AnimatedScannerText> createState() => _AnimatedScannerTextState();
}

class _AnimatedScannerTextState extends State<_AnimatedScannerText> {
  static const _steps = [
    'SEARCHING OBJECTS...',
    'RECOGNIZING ITEMS...',
    'PREPARING LESSON...',
  ];
  int _currentStep = 0;
  Timer? _cycleTimer;

  @override
  void initState() {
    super.initState();
    _cycleTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (mounted) {
        setState(() {
          _currentStep = (_currentStep + 1) % _steps.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Text(
        _steps[_currentStep],
        key: ValueKey(_currentStep),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 14.sp,
          color: AppColors.teal500,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}
