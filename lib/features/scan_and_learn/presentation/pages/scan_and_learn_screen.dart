import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/ml_monetization_controller.dart';
import 'package:vowl/core/utils/ml_services/text_recognition_service.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ScanAndLearnScreen extends StatefulWidget {
  const ScanAndLearnScreen({super.key});

  @override
  State<ScanAndLearnScreen> createState() => _ScanAndLearnScreenState();
}

class _ScanAndLearnScreenState extends State<ScanAndLearnScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;
  RecognizedText? _recognizedText;
  bool _isProcessing = false;
  
  // Track translations for blocks. Map of block index to translated text.
  final Map<int, String> _translations = {};
  final Map<int, bool> _isTranslating = {};

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
      _translations.clear();
      _isTranslating.clear();
    });

    final recognized = await di.sl<TextRecognitionService>().recognizeFromFile(path);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _recognizedText = recognized;
      });
    }
  }

  Future<void> _translateBlock(int index, String text) async {
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
          SnackBar(content: Text('Failed to translate.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryIndigo = const Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1B) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.document_scanner_rounded, color: primaryIndigo, size: 24.r),
            SizedBox(width: 8.w),
            Text(
              context.tr('translation.scan_learn_title', fallback: 'Scan & Learn'),
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
                color: primaryIndigo.withValues(alpha: 0.2),
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
                          context.tr('translation.scan_prompt', fallback: 'Select an image to extract text'),
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
                    onTap: () => _pickAndScanImage(ImageSource.camera),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryIndigo, const Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: primaryIndigo.withValues(alpha: 0.3),
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
                    onTap: () => _pickAndScanImage(ImageSource.gallery),
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
                color: isDark ? const Color(0xFF151522) : Colors.white,
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
                          const CircularProgressIndicator(color: Color(0xFF6366F1)),
                          SizedBox(height: 16.h),
                          Text(
                            context.tr('translation.extracting', fallback: 'Extracting Text...'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _recognizedText == null
                      ? Center(
                          child: Text(
                            context.tr('translation.no_results', fallback: 'No text extracted yet.'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(24.r),
                          itemCount: _recognizedText!.blocks.length,
                          separatorBuilder: (context, index) => SizedBox(height: 16.h),
                          itemBuilder: (context, index) {
                            final block = _recognizedText!.blocks[index];
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    block.text,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  if (translatedText != null) ...[
                                    SizedBox(height: 12.h),
                                    Container(
                                      padding: EdgeInsets.all(12.r),
                                      decoration: BoxDecoration(
                                        color: primaryIndigo.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.g_translate_rounded, color: primaryIndigo, size: 16.r),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: Text(
                                              translatedText,
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 15.sp,
                                                color: primaryIndigo,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).animate().fadeIn().slideY(begin: 0.2),
                                  ] else if (isTranslating) ...[
                                    SizedBox(height: 12.h),
                                    const LinearProgressIndicator(),
                                  ] else ...[
                                    SizedBox(height: 12.h),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ScaleButton(
                                        onTap: () => _translateBlock(index, block.text),
                                        child: Text(
                                          context.tr('translation.translate', fallback: 'Translate'),
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: primaryIndigo,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]
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
