import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/ml_services/digital_ink_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/utils/kids_game_helper.dart';

class KidsCategoryGrid extends StatefulWidget {
  final bool isDark;

  const KidsCategoryGrid({super.key, required this.isDark});

  @override
  State<KidsCategoryGrid> createState() => _KidsCategoryGridState();
}

class _KidsCategoryGridState extends State<KidsCategoryGrid> {
  bool _isCheckingModel = true;
  bool _isModelDownloaded = false;

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    final service = di.sl<DigitalInkService>();
    final isDownloaded = await service.isModelDownloaded();
    if (mounted) {
      setState(() {
        _isModelDownloaded = isDownloaded;
        _isCheckingModel = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20.h,
          crossAxisSpacing: 20.w,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildListDelegate(
          KidsGameHelper.allGames.map((game) {
            if (game.gameType == 'handwriting') {
              return _buildCategoryCard(
                context,
                () async {
                  if (!_isModelDownloaded) {
                    final networkInfo = di.sl<NetworkInfo>();
                    final isConnected = await networkInfo.isConnected;
                    if (!isConnected && context.mounted) {
                      CustomSnackBar.show(
                        context: context,
                        message:
                            'Internet connection required to download smart pen model.',
                        type: CustomSnackBarType.warning,
                      );
                      return;
                    }
                  }

                  final service = di.sl<DigitalInkService>();
                  bool isDownloaded = await service.isModelDownloaded();

                  if (!isDownloaded && context.mounted) {
                    final success = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          _DownloadModelDialog(primaryColor: game.color),
                    );

                    if (success != true) {
                      if (context.mounted) {
                        CustomSnackBar.show(
                          context: context,
                          message: 'Failed to download handwriting model.',
                          type: CustomSnackBarType.error,
                        );
                      }
                      return;
                    }

                    setState(() {
                      _isModelDownloaded = true;
                    });
                  }

                  if (context.mounted) {
                    context.push(
                      '/kids/map/handwriting',
                      extra: {
                        'title': game.fullTitle,
                        'primaryColor': game.color,
                      },
                    );
                  }
                },
                game.gridTitle,
                _isCheckingModel
                    ? 'Checking...'
                    : (!_isModelDownloaded
                          ? 'Download Required'
                          : game.subtitle),
                game.color,
                game.icon,
                trailing: _isCheckingModel
                    ? Icon(Icons.sync_rounded, color: game.color, size: 24.sp)
                          .animate(onPlay: (c) => c.repeat())
                          .rotate(duration: 1.5.seconds)
                    : (!_isModelDownloaded
                          ? Icon(
                                  Icons.cloud_download_rounded,
                                  color: game.color,
                                  size: 28.sp,
                                )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scaleXY(
                                  begin: 1.0,
                                  end: 1.15,
                                  duration: 1.seconds,
                                )
                          : null),
              );
            }

            return _buildCategoryCard(
              context,
              () => context.push(
                '/kids/map/${game.gameType}',
                extra: {'title': game.fullTitle, 'primaryColor': game.color},
              ),
              game.gridTitle,
              game.subtitle,
              game.color,
              game.icon,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    VoidCallback onTap,
    String title,
    String subtitle,
    Color color,
    IconData icon, {
    Widget? trailing,
  }) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(32.r),
          border: Border.all(color: color, width: 3.w),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.6),
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(icon, color: color, size: 32.sp),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: AutoSizeText(
                        title,
                        maxLines: 2,
                        minFontSize: 12,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: widget.isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                          height: 1.1,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[SizedBox(width: 4.w), trailing],
                  ],
                ),
                AutoSizeText(
                  subtitle,
                  maxLines: 1,
                  minFontSize: 8,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark ? Colors.white60 : Colors.black45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadModelDialog extends StatefulWidget {
  final Color primaryColor;
  const _DownloadModelDialog({required this.primaryColor});

  @override
  State<_DownloadModelDialog> createState() => _DownloadModelDialogState();
}

class _DownloadModelDialogState extends State<_DownloadModelDialog> {
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startMockProgress();
    _downloadModel();
  }

  void _startMockProgress() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_progress < 0.85) {
          _progress += 0.02; // Fast up to 85%
        } else if (_progress < 0.95) {
          _progress += 0.005; // Slow crawl to 95%
        }
      });
    });
  }

  Future<void> _downloadModel() async {
    final service = di.sl<DigitalInkService>();
    final success = await service.downloadModel();
    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.r)),
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                  Icons.cloud_download_rounded,
                  size: 80.r,
                  color: widget.primaryColor,
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -5, end: 5, duration: 1.seconds),
            SizedBox(height: 24.h),
            Text(
              "Downloading Smart Pen...",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              "This only happens once!",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 32.h),
            Container(
              width: double.infinity,
              height: 20.h,
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 250.w * _progress,
                    height: 20.h,
                    decoration: BoxDecoration(
                      color: widget.primaryColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "${(_progress * 100).toInt()}%",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
