import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/translation_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class TranslationDownloadDialog extends StatefulWidget {
  const TranslationDownloadDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const TranslationDownloadDialog(),
    );
  }

  @override
  State<TranslationDownloadDialog> createState() =>
      _TranslationDownloadDialogState();
}

class _TranslationDownloadDialogState extends State<TranslationDownloadDialog> {
  final ValueNotifier<int> _progress = ValueNotifier(0);
  Timer? _timer;
  final ValueNotifier<String?> _languageName = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _loadLanguageAndStart();
  }

  Future<void> _loadLanguageAndStart() async {
    final langName = await di
        .sl<TranslationService>()
        .getConfiguredLanguageName();
    if (mounted) {
      _languageName.value = langName ?? 'Language';
    }

    _startFakeProgress();

    try {
      // Ensure the model finishes downloading
      await di.sl<TranslationService>().ensureModelDownloaded();
      _timer?.cancel();
      if (mounted) {
        _progress.value = 100;
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _timer?.cancel();
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'translation.download_failed',
                fallback: 'Failed to download language model.',
              ),
            ),
            backgroundColor: const Color(0xFFF43F5E),
          ),
        );
      }
    }
  }

  void _startFakeProgress() {
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) return;
      if (_progress.value < 95) {
        if (_progress.value < 60) {
          _progress.value += 2;
        } else if (_progress.value < 85) {
          _progress.value += 1;
        } else {
          if (timer.tick % 4 == 0) _progress.value += 1;
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progress.dispose();
    _languageName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([_progress, _languageName]),
      builder: (context, _) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80.r,
                      height: 80.r,
                      child: CircularProgressIndicator(
                        value: _progress.value == 0
                            ? null
                            : _progress.value / 100,
                        strokeWidth: 6,
                        backgroundColor: isDark
                            ? Colors.white10
                            : Colors.black12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    Text(
                      '${_progress.value}%',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                Text(
                  context.tr(
                    'translation.downloading_model',
                    fallback: 'Downloading Model...',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  context
                      .tr(
                        'translation.downloading_desc',
                        fallback:
                            'Downloading offline AI model for {lang}. This only happens once.',
                      )
                      .replaceAll('{lang}', _languageName.value ?? ''),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
