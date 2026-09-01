import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// Themed section groupings for the category grid.
/// This transforms the flat wall of 25 cards into a scannable, grouped menu.
class _SectionDef {
  final String title;
  final String emoji;
  final Color color;
  final List<String> gameTypes;

  const _SectionDef(this.title, this.emoji, this.color, this.gameTypes);
}

const _kSections = [
  _SectionDef('Language', '📚', Color(0xFFF43F5E), [
    'handwriting', 'alphabet', 'phonics', 'verbs', 'opposites', 'prepositions',
  ]),
  _SectionDef('World', '🌍', Color(0xFF10B981), [
    'animals', 'nature', 'weather', 'day_night', 'transport',
  ]),
  _SectionDef('Life', '🏠', Color(0xFF8B5CF6), [
    'family', 'school', 'routine', 'emotions', 'food', 'home',
  ]),
  _SectionDef('Math & Logic', '🔢', Color(0xFF0EA5E9), [
    'numbers', 'colors', 'shapes', 'time',
  ]),
  _SectionDef('Skills', '⭐', Color(0xFFF59E0B), [
    'fruits', 'body_parts', 'clothing', 'professions',
  ]),
];

class KidsCategoryGrid extends StatefulWidget {
  final bool isDark;

  const KidsCategoryGrid({super.key, required this.isDark});

  @override
  State<KidsCategoryGrid> createState() => _KidsCategoryGridState();
}

class _KidsCategoryGridState extends State<KidsCategoryGrid> {
  final ValueNotifier<bool> _isCheckingModel = ValueNotifier(true);
  final ValueNotifier<bool> _isModelDownloaded = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  @override
  void dispose() {
    _isCheckingModel.dispose();
    _isModelDownloaded.dispose();
    super.dispose();
  }

  Future<void> _checkModelStatus() async {
    final service = di.sl<DigitalInkService>();
    final isDownloaded = await service.isModelDownloaded();
    if (mounted) {
      _isModelDownloaded.value = isDownloaded;
      _isCheckingModel.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use context.select to only rebuild when completedLevels changes
    final completedLevels = context.select<AuthBloc, Map<String, List<int>>>(
      (bloc) => bloc.state.user?.completedLevels ?? {},
    );

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, sectionIndex) {
          final section = _kSections[sectionIndex];
          final games = section.gameTypes
              .map((type) => KidsGameHelper.getMetadata(type))
              .where((g) => g.gameType != 'unknown')
              .toList();

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Padding(
                  padding: EdgeInsets.only(
                    top: sectionIndex == 0 ? 0 : 12.h,
                    bottom: 16.h,
                  ),
                  child: Row(
                    children: [
                      Text(section.emoji, style: TextStyle(fontSize: 20.sp)),
                      SizedBox(width: 10.w),
                      Text(
                        context.tr(
                          'kids_zone.section_${section.title.toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_')}',
                          fallback: section.title,
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: widget.isDark
                              ? Colors.white70
                              : const Color(0xFF475569),
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Container(
                          height: 2.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                section.color.withValues(alpha: 0.5),
                                section.color.withValues(alpha: 0.0),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (sectionIndex * 80).ms),

                // Grid of cards for this section
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20.h,
                    crossAxisSpacing: 20.w,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    final completed = completedLevels[game.gameType]?.length ?? 0;

                    if (game.gameType == 'handwriting') {
                      return ListenableBuilder(
                        listenable: Listenable.merge([_isCheckingModel, _isModelDownloaded]),
                        builder: (context, _) {
                          return _buildCategoryCard(
                            context,
                            () async {
                              if (!_isModelDownloaded.value) {
                                final networkInfo = di.sl<NetworkInfo>();
                                final isConnected = await networkInfo.isConnected;
                                if (!isConnected && context.mounted) {
                                  CustomSnackBar.show(
                                    context: context,
                                    message: context.tr('kids_zone.internet_required_smart_pen', fallback: 'Internet connection required to download smart pen model.'),
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
                                      message: context.tr('kids_zone.failed_download_smart_pen', fallback: 'Failed to download handwriting model.'),
                                      type: CustomSnackBarType.error,
                                    );
                                  }
                                  return;
                                }

                                _isModelDownloaded.value = true;
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
                            _isCheckingModel.value
                                ? context.tr('kids_zone.checking', fallback: 'Checking...')
                                : (!_isModelDownloaded.value
                                      ? context.tr('kids_zone.download_required', fallback: 'Download Required')
                                      : game.subtitle),
                            game.color,
                            game.icon,
                            completedCount: completed,
                            trailing: _isCheckingModel.value
                                ? Icon(Icons.sync_rounded, color: game.color, size: 24.sp)
                                      .animate(onPlay: (c) => c.repeat())
                                      .rotate(duration: 1.5.seconds)
                                : (!_isModelDownloaded.value
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
                        },
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
                      completedCount: completed,
                    );
                  },
                ),
                SizedBox(height: 8.h),
              ],
            ),
          );
        },
        childCount: _kSections.length,
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
    int completedCount = 0,
  }) {
    final progress = (completedCount / 200).clamp(0.0, 1.0);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(icon, color: color, size: 32.sp),
                ),
                // Per-category progress ring
                if (completedCount > 0)
                  SizedBox(
                    width: 36.r,
                    height: 36.r,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 36.r,
                          height: 36.r,
                          child: CustomPaint(
                            painter: _ProgressRingPainter(
                              progress: progress,
                              color: color,
                              trackColor: color.withValues(alpha: 0.15),
                              strokeWidth: 3.5.r,
                            ),
                          ),
                        ),
                        Text(
                          '$completedCount',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
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

/// Lightweight progress ring painter for per-category completion indicators.
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _DownloadModelDialog extends StatefulWidget {
  final Color primaryColor;
  const _DownloadModelDialog({required this.primaryColor});

  @override
  State<_DownloadModelDialog> createState() => _DownloadModelDialogState();
}

class _DownloadModelDialogState extends State<_DownloadModelDialog> {
  final ValueNotifier<double> _progress = ValueNotifier(0.0);
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
      if (_progress.value < 0.85) {
        _progress.value += 0.02; // Fast up to 85%
      } else if (_progress.value < 0.95) {
        _progress.value += 0.005; // Slow crawl to 95%
      }
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
    _progress.dispose();
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
              context.tr('kids_zone.downloading_smart_pen', fallback: "Downloading Smart Pen..."),
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
              context.tr('kids_zone.download_once_note', fallback: "This only happens once!"),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 32.h),
              ValueListenableBuilder<double>(
                valueListenable: _progress,
                builder: (context, progressValue, _) {
                  return Column(
                    children: [
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
                              width: 250.w * progressValue,
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
                        "${(progressValue * 100).toInt()}%",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: widget.primaryColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
