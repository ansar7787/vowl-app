import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';

import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class TranslationDownloadSheet extends StatefulWidget {
  /// The future that represents the actual download task.
  final Future<void> downloadTask;

  const TranslationDownloadSheet({super.key, required this.downloadTask});

  static Future<void> show(BuildContext context, Future<void> task) async {
    await TtsSpeakerButtonWidget.stopAll();
    if (!context.mounted) return;

    if (di.sl.isRegistered<NetworkInfo>()) {
      final isOnline = await di.sl<NetworkInfo>().isConnected;
      if (!isOnline) {
        if (context.mounted) {
          CustomSnackBar.show(
            context: context,
            message: context.tr(
              'translation.network_required',
              fallback:
                  'Internet connection required to download offline packs.',
            ),
            type: CustomSnackBarType.error,
          );
        }
        return;
      }
    }

    if (!context.mounted) return;

    return showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TranslationDownloadSheet(downloadTask: task),
    );
  }

  @override
  State<TranslationDownloadSheet> createState() =>
      _TranslationDownloadSheetState();
}

class _TranslationDownloadSheetState extends State<TranslationDownloadSheet> {
  final ValueNotifier<double> _progress = ValueNotifier(0.0);
  Timer? _timer;
  final ValueNotifier<bool> _isFinished = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _startSimulatedProgress();
    _listenToActualTask();
  }

  void _startSimulatedProgress() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _isFinished.value) return;

      if (_progress.value < 0.6) {
        _progress.value += 0.02; // Fast phase
      } else if (_progress.value < 0.85) {
        _progress.value += 0.01; // Medium phase
      } else if (_progress.value < 0.96) {
        _progress.value += 0.002; // Crawl phase
      }
    });
  }

  Future<void> _listenToActualTask() async {
    try {
      await widget.downloadTask;
      if (mounted) {
        _progress.value = 1.0;
        _isFinished.value = true;
        _timer?.cancel();

        // Wait a tiny bit to let user see 100% and success state
        Future.delayed(const Duration(milliseconds: 450), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (_) {
      _timer?.cancel();
      if (mounted) {
        Navigator.of(context).pop();
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'translation.download_failed',
            fallback: 'Failed to download language model.',
          ),
          type: CustomSnackBarType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progress.dispose();
    _isFinished.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    return ListenableBuilder(
      listenable: Listenable.merge([_progress, _isFinished]),
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(32.r),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate900 : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Container(
                width: 44.w,
                height: 4.5.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.slate300,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Semantics(
                  button: true,
                  label: context.tr('common.close', fallback: 'Close'),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _timer?.cancel();
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.slate100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18.r,
                          color: isDark ? Colors.white60 : AppColors.slate600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: _isFinished.value
                    ? Icon(
                        LucideIcons.checkCircle2,
                        color: tokens.gameCorrect,
                        size: 40.r,
                      ).animate().scale(curve: Curves.elasticOut)
                    : Icon(
                            Icons.cloud_download_rounded,
                            color: Colors.blueAccent,
                            size: 40.r,
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.1, 1.1),
                          ),
              ),
              SizedBox(height: 24.h),
              Text(
                _isFinished.value
                    ? context.tr(
                        'translation.model_optimized',
                        fallback: 'Model Optimized!',
                      )
                    : (_progress.value >= 0.95
                        ? context.tr(
                            'translation.finalizing_model',
                            fallback: 'Finalizing offline pack...',
                          )
                        : context.tr(
                            'translation.initializing_engine',
                            fallback: 'Initializing AI Engine...',
                          )),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ).animate(target: _isFinished.value ? 1 : 0).fade().slideY(),
              SizedBox(height: 12.h),
              Text(
                _isFinished.value
                    ? context.tr(
                        'translation.ready_forever',
                        fallback: 'On-device translation ready forever.',
                      )
                    : (_progress.value >= 0.95
                        ? context.tr(
                            'translation.installing_model_desc',
                            fallback:
                                'Installing on-device neural translator. Almost ready...',
                          )
                        : context.tr(
                            'translation.download_desc',
                            fallback:
                                'Downloading offline AI language model. This happens only once!',
                          )),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              SizedBox(height: 32.h),

              // Progress Bar
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 12.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 12.h,
                          width: constraints.maxWidth * _progress.value,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.cyanAccent, Colors.blueAccent],
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                    '${(_progress.value * 100).toInt()}%',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w900,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [Colors.cyanAccent, Colors.blueAccent],
                        ).createShader(const Rect.fromLTWH(0, 0, 100, 40)),
                    ),
                  )
                  .animate(key: ValueKey(_progress.value))
                  .scale(
                    duration: 100.ms,
                    begin: const Offset(1.05, 1.05),
                    end: const Offset(1, 1),
                  ),
              SizedBox(height: 16.h),
            ],
          ),
        ).animate().slideY(
          begin: 1,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: 500.ms,
        );
      },
    );
  }
}
