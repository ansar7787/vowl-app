import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/ml_monetization_controller.dart';
import 'package:vowl/core/utils/ml_services/image_labeling_service.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PhotoVocabularyScreen extends StatefulWidget {
  const PhotoVocabularyScreen({super.key});

  @override
  State<PhotoVocabularyScreen> createState() => _PhotoVocabularyScreenState();
}

class _PhotoVocabularyScreenState extends State<PhotoVocabularyScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;
  List<ImageLabel>? _labels;
  bool _isProcessing = false;
  
  final Map<int, String> _translations = {};
  final Map<int, bool> _isTranslating = {};

  Future<void> _pickAndLabelImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    if (!mounted) return;

    // Trigger Monetization Gate before processing
    MlMonetizationController.attemptFeature(
      context,
      featureIcon: Icons.camera_alt_rounded,
      featureTitle: context.tr('vocabulary.photo_vocab_title', fallback: 'Photo Vocabulary'),
      featureSubtitle: context.tr('vocabulary.photo_vocab_desc', fallback: 'Discover words from the world around you!'),
      adButtonLabel: context.tr('vocabulary.photo_vocab_ad', fallback: 'Watch Ad to Analyze'),
      onSuccess: () => _processImage(image.path),
    );
  }

  Future<void> _processImage(String path) async {
    setState(() {
      _imagePath = path;
      _isProcessing = true;
      _labels = null;
      _translations.clear();
      _isTranslating.clear();
    });

    final labels = await di.sl<ImageLabelingService>().labelImage(path);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _labels = labels;
      });
    }
  }

  Future<void> _translateLabel(int index, String text) async {
    setState(() {
      _isTranslating[index] = true;
    });

    try {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to translate.')),
        );
      }
    }
  }

  void _playPronunciation(String text) {
    di.sl<SoundService>().playTts(text, speed: 0.8, locale: 'en-US');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTeal = const Color(0xFF14B8A6);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_rounded, color: primaryTeal, size: 24.r),
            SizedBox(width: 8.w),
            Text(
              context.tr('vocabulary.photo_vocab_title', fallback: 'Photo Vocabulary'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Image Preview Area
          Container(
            height: 250.h,
            width: double.infinity,
            margin: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: primaryTeal.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22.r),
              child: _imagePath != null
                  ? Image.file(
                      File(_imagePath!),
                      fit: BoxFit.cover,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.imagePlus, size: 48.r, color: isDark ? Colors.white24 : Colors.black26),
                        SizedBox(height: 16.h),
                        Text(
                          context.tr('vocabulary.photo_prompt', fallback: 'Select an image to find objects'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Expanded(
                  child: ScaleButton(
                    onTap: () => _pickAndLabelImage(ImageSource.camera),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryTeal, const Color(0xFF0EA5E9)],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: primaryTeal.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.camera, color: Colors.white, size: 20.r),
                          SizedBox(width: 8.w),
                          Text(
                            context.tr('common.camera', fallback: 'Camera'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ScaleButton(
                    onTap: () => _pickAndLabelImage(ImageSource.gallery),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.image, color: isDark ? Colors.white : Colors.black87, size: 20.r),
                          SizedBox(width: 8.w),
                          Text(
                            context.tr('common.gallery', fallback: 'Gallery'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Results Area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32.r),
                  topRight: Radius.circular(32.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: _isProcessing
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: primaryTeal),
                          SizedBox(height: 16.h),
                          Text(
                            context.tr('vocabulary.analyzing', fallback: 'Analyzing objects...'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _labels == null
                      ? Center(
                          child: Text(
                            context.tr('vocabulary.no_objects', fallback: 'No objects analyzed yet.'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(24.r),
                          itemCount: _labels!.length,
                          separatorBuilder: (context, index) => SizedBox(height: 16.h),
                          itemBuilder: (context, index) {
                            final label = _labels![index];
                            final translatedText = _translations[index];
                            final isTranslating = _isTranslating[index] ?? false;

                            return Container(
                              padding: EdgeInsets.all(16.r),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black26 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              label.label,
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                              decoration: BoxDecoration(
                                                color: primaryTeal.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8.r),
                                              ),
                                              child: Text(
                                                '${(label.confidence * 100).toStringAsFixed(0)}%',
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w900,
                                                  color: primaryTeal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (translatedText != null) ...[
                                          SizedBox(height: 8.h),
                                          Text(
                                            translatedText,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 15.sp,
                                              color: primaryTeal,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ).animate().fadeIn().slideY(begin: 0.2),
                                        ] else if (isTranslating) ...[
                                          SizedBox(height: 12.h),
                                          SizedBox(
                                            height: 2.h,
                                            width: 50.w,
                                            child: const LinearProgressIndicator(),
                                          ),
                                        ] else ...[
                                          SizedBox(height: 8.h),
                                          ScaleButton(
                                            onTap: () => _translateLabel(index, label.label),
                                            child: Text(
                                              context.tr('translation.translate', fallback: 'Translate'),
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade600,
                                              ),
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                  ScaleButton(
                                    onTap: () => _playPronunciation(label.label),
                                    child: Container(
                                      padding: EdgeInsets.all(12.r),
                                      decoration: BoxDecoration(
                                        color: primaryTeal.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.volume_up_rounded,
                                        color: primaryTeal,
                                        size: 20.r,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
