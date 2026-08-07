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
import 'package:vowl/features/kids_zone/kids_routes.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
        delegate: SliverChildListDelegate([
          _buildCategoryCard(
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
                  builder: (context) => _DownloadModelDialog(
                    primaryColor: KidsRoutes.getKidsGameColor('handwriting'),
                  ),
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
                    'title': 'Handwriting',
                    'primaryColor': KidsRoutes.getKidsGameColor('handwriting'),
                  },
                );
              }
            },
            'Write & Learn',
            _isCheckingModel
                ? 'Checking...'
                : (!_isModelDownloaded
                      ? 'Download Required'
                      : 'Handwriting Fun'),
            KidsRoutes.getKidsGameColor('handwriting'),
            Icons.edit_rounded,
            trailing: _isCheckingModel
                ? SizedBox(
                    width: 24.sp,
                    height: 24.sp,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KidsRoutes.getKidsGameColor('handwriting'),
                    ),
                  )
                : (!_isModelDownloaded
                      ? Icon(
                          Icons.lock_outline_rounded,
                          color: KidsRoutes.getKidsGameColor('handwriting'),
                          size: 28.sp,
                        )
                      : null),
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/alphabet',
              extra: {
                'title': 'Alphabet',
                'primaryColor': KidsRoutes.getKidsGameColor('alphabet'),
              },
            ),
            'ABC',
            'Letters & Phonics',
            KidsRoutes.getKidsGameColor('alphabet'),
            Icons.abc_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/numbers',
              extra: {
                'title': 'Numbers',
                'primaryColor': KidsRoutes.getKidsGameColor('numbers'),
              },
            ),
            '123',
            'Numbers & Math',
            KidsRoutes.getKidsGameColor('numbers'),
            Icons.pin_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/colors',
              extra: {
                'title': 'Colors',
                'primaryColor': KidsRoutes.getKidsGameColor('colors'),
              },
            ),
            'Colors',
            'Rainbow Fun',
            KidsRoutes.getKidsGameColor('colors'),
            Icons.palette_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/shapes',
              extra: {
                'title': 'Shapes',
                'primaryColor': KidsRoutes.getKidsGameColor('shapes'),
              },
            ),
            'Shapes',
            'Geometry Fun',
            KidsRoutes.getKidsGameColor('shapes'),
            Icons.category_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/animals',
              extra: {
                'title': 'Animals',
                'primaryColor': KidsRoutes.getKidsGameColor('animals'),
              },
            ),
            'Animals',
            'Farm & Wild',
            KidsRoutes.getKidsGameColor('animals'),
            Icons.pets_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/fruits',
              extra: {
                'title': 'Fruits',
                'primaryColor': KidsRoutes.getKidsGameColor('fruits'),
              },
            ),
            'Fruits',
            'Healthy Eating',
            KidsRoutes.getKidsGameColor('fruits'),
            Icons.apple_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/family',
              extra: {
                'title': 'Family',
                'primaryColor': KidsRoutes.getKidsGameColor('family'),
              },
            ),
            'Family',
            'Love & Home',
            KidsRoutes.getKidsGameColor('family'),
            Icons.people_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/school',
              extra: {
                'title': 'School',
                'primaryColor': KidsRoutes.getKidsGameColor('school'),
              },
            ),
            'School',
            'Let\'s Learn',
            KidsRoutes.getKidsGameColor('school'),
            Icons.school_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/verbs',
              extra: {
                'title': 'Verbs',
                'primaryColor': KidsRoutes.getKidsGameColor('verbs'),
              },
            ),
            'Verbs',
            'Action Words',
            KidsRoutes.getKidsGameColor('verbs'),
            Icons.run_circle_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/routine',
              extra: {
                'title': 'Routine',
                'primaryColor': KidsRoutes.getKidsGameColor('routine'),
              },
            ),
            'Routine',
            'My Day',
            KidsRoutes.getKidsGameColor('routine'),
            Icons.schedule_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/emotions',
              extra: {
                'title': 'Emotions',
                'primaryColor': KidsRoutes.getKidsGameColor('emotions'),
              },
            ),
            'Emotions',
            'Feelings',
            KidsRoutes.getKidsGameColor('emotions'),
            Icons.mood_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/prepositions',
              extra: {
                'title': 'Prepositions',
                'primaryColor': KidsRoutes.getKidsGameColor('prepositions'),
              },
            ),
            'Positions',
            'Where is it?',
            KidsRoutes.getKidsGameColor('prepositions'),
            Icons.place_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/phonics',
              extra: {
                'title': 'Phonics',
                'primaryColor': KidsRoutes.getKidsGameColor('phonics'),
              },
            ),
            'Phonics',
            'Sound Out',
            KidsRoutes.getKidsGameColor('phonics'),
            Icons.record_voice_over_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/time',
              extra: {
                'title': 'Time',
                'primaryColor': KidsRoutes.getKidsGameColor('time'),
              },
            ),
            'Time',
            'Tick Tock',
            KidsRoutes.getKidsGameColor('time'),
            Icons.watch_later_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/opposites',
              extra: {
                'title': 'Opposites',
                'primaryColor': KidsRoutes.getKidsGameColor('opposites'),
              },
            ),
            'Opposites',
            'Flip It',
            KidsRoutes.getKidsGameColor('opposites'),
            Icons.swap_horiz_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/day_night',
              extra: {
                'title': 'Day/Night',
                'primaryColor': KidsRoutes.getKidsGameColor('day_night'),
              },
            ),
            'Day & Night',
            'Sun & Moon',
            KidsRoutes.getKidsGameColor('day_night'),
            Icons.brightness_4_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/nature',
              extra: {
                'title': 'Nature',
                'primaryColor': KidsRoutes.getKidsGameColor('nature'),
              },
            ),
            'Nature',
            'Outdoors',
            KidsRoutes.getKidsGameColor('nature'),
            Icons.forest_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/home',
              extra: {
                'title': 'Home',
                'primaryColor': KidsRoutes.getKidsGameColor('home'),
              },
            ),
            'Home',
            'Rooms & Items',
            KidsRoutes.getKidsGameColor('home'),
            Icons.home_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/food',
              extra: {
                'title': 'Food',
                'primaryColor': KidsRoutes.getKidsGameColor('food'),
              },
            ),
            'Food',
            'Yummy!',
            KidsRoutes.getKidsGameColor('food'),
            Icons.restaurant_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/transport',
              extra: {
                'title': 'Transport',
                'primaryColor': KidsRoutes.getKidsGameColor('transport'),
              },
            ),
            'Transport',
            'Vroom Vroom',
            KidsRoutes.getKidsGameColor('transport'),
            Icons.directions_car_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/body_parts',
              extra: {
                'title': 'Body Parts',
                'primaryColor': KidsRoutes.getKidsGameColor('body_parts'),
              },
            ),
            'Body',
            'My Body',
            KidsRoutes.getKidsGameColor('body_parts'),
            Icons.accessibility_new_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/clothing',
              extra: {
                'title': 'Clothing',
                'primaryColor': KidsRoutes.getKidsGameColor('clothing'),
              },
            ),
            'Clothing',
            'Dress Up',
            KidsRoutes.getKidsGameColor('clothing'),
            Icons.checkroom_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/weather',
              extra: {
                'title': 'Weather',
                'primaryColor': KidsRoutes.getKidsGameColor('weather'),
              },
            ),
            'Weather',
            'Sun & Rain',
            KidsRoutes.getKidsGameColor('weather'),
            Icons.cloud_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/professions',
              extra: {
                'title': 'Professions',
                'primaryColor': KidsRoutes.getKidsGameColor('professions'),
              },
            ),
            'Professions',
            'When I Grow Up',
            KidsRoutes.getKidsGameColor('professions'),
            Icons.work_rounded,
          ),
        ]),
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
