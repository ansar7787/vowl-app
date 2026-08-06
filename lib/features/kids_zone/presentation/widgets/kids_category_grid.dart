import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/ml_services/digital_ink_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

class KidsCategoryGrid extends StatelessWidget {
  final bool isDark;

  const KidsCategoryGrid({super.key, required this.isDark});

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
              final service = di.sl<DigitalInkService>();
              bool isDownloaded = await service.isModelDownloaded();

              if (!isDownloaded && context.mounted) {
                final success = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const _DownloadModelDialog(
                    primaryColor: Color(0xFFF43F5E),
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
              }

              if (context.mounted) {
                context.push(
                  '/kids/map/handwriting',
                  extra: {
                    'title': 'Handwriting',
                    'primaryColor': const Color(0xFFF43F5E),
                  },
                );
              }
            },
            'Write & Learn',
            'Handwriting Fun',
            const Color(0xFFF43F5E), // Rose
            Icons.edit_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/alphabet',
              extra: {
                'title': 'Alphabet',
                'primaryColor': const Color(0xFFF43F5E),
              },
            ),
            'ABC',
            'Letters & Phonics',
            const Color(0xFFF43F5E),
            Icons.abc_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/numbers',
              extra: {
                'title': 'Numbers',
                'primaryColor': const Color(0xFF0EA5E9),
              },
            ),
            '123',
            'Numbers & Math',
            const Color(0xFF0EA5E9),
            Icons.pin_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/colors',
              extra: {
                'title': 'Colors',
                'primaryColor': const Color(0xFFF59E0B),
              },
            ),
            'Colors',
            'Rainbow Fun',
            const Color(0xFFF59E0B),
            Icons.palette_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/shapes',
              extra: {
                'title': 'Shapes',
                'primaryColor': const Color(0xFF10B981),
              },
            ),
            'Shapes',
            'Geometry Fun',
            const Color(0xFF10B981),
            Icons.category_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/animals',
              extra: {
                'title': 'Animals',
                'primaryColor': const Color(0xFF8B5CF6),
              },
            ),
            'Animals',
            'Farm & Wild',
            const Color(0xFF8B5CF6),
            Icons.pets_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/fruits',
              extra: {
                'title': 'Fruits',
                'primaryColor': const Color(0xFFEC4899),
              },
            ),
            'Fruits',
            'Healthy Eating',
            const Color(0xFFEC4899),
            Icons.apple_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/family',
              extra: {
                'title': 'Family',
                'primaryColor': const Color(0xFFEC4899),
              },
            ),
            'Family',
            'Love & Home',
            const Color(0xFFEC4899),
            Icons.people_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/school',
              extra: {
                'title': 'School',
                'primaryColor': const Color(0xFFF59E0B),
              },
            ),
            'School',
            'Let\'s Learn',
            const Color(0xFFF59E0B),
            Icons.school_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/verbs',
              extra: {
                'title': 'Verbs',
                'primaryColor': const Color(0xFF8B5CF6),
              },
            ),
            'Verbs',
            'Action Words',
            const Color(0xFF8B5CF6),
            Icons.run_circle_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/routine',
              extra: {
                'title': 'Routine',
                'primaryColor': const Color(0xFFF97316),
              },
            ),
            'Routine',
            'My Day',
            const Color(0xFFF97316),
            Icons.schedule_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/emotions',
              extra: {
                'title': 'Emotions',
                'primaryColor': const Color(0xFF06B6D4),
              },
            ),
            'Emotions',
            'Feelings',
            const Color(0xFF06B6D4),
            Icons.mood_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/prepositions',
              extra: {
                'title': 'Prepositions',
                'primaryColor': const Color(0xFF64748B),
              },
            ),
            'Positions',
            'Where is it?',
            const Color(0xFF64748B),
            Icons.place_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/phonics',
              extra: {
                'title': 'Phonics',
                'primaryColor': const Color(0xFFFFCC00),
              },
            ),
            'Phonics',
            'Sound Out',
            const Color(0xFFFFCC00),
            Icons.record_voice_over_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/time',
              extra: {'title': 'Time', 'primaryColor': const Color(0xFF333333)},
            ),
            'Time',
            'Tick Tock',
            const Color(0xFF333333),
            Icons.watch_later_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/opposites',
              extra: {
                'title': 'Opposites',
                'primaryColor': const Color(0xFF94A3B8),
              },
            ),
            'Opposites',
            'Flip It',
            const Color(0xFF94A3B8),
            Icons.swap_horiz_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/day_night',
              extra: {
                'title': 'Day/Night',
                'primaryColor': const Color(0xFF1E293B),
              },
            ),
            'Day & Night',
            'Sun & Moon',
            const Color(0xFF1E293B),
            Icons.brightness_4_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/nature',
              extra: {
                'title': 'Nature',
                'primaryColor': const Color(0xFF16A34A),
              },
            ),
            'Nature',
            'Outdoors',
            const Color(0xFF16A34A),
            Icons.forest_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/home',
              extra: {'title': 'Home', 'primaryColor': const Color(0xFFD946EF)},
            ),
            'Home',
            'Rooms & Items',
            const Color(0xFFD946EF),
            Icons.home_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/food',
              extra: {'title': 'Food', 'primaryColor': const Color(0xFFFB923C)},
            ),
            'Food',
            'Yummy!',
            const Color(0xFFFB923C),
            Icons.restaurant_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/transport',
              extra: {
                'title': 'Transport',
                'primaryColor': const Color(0xFF6366F1),
              },
            ),
            'Transport',
            'Vroom Vroom',
            const Color(0xFF6366F1),
            Icons.directions_car_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/body_parts',
              extra: {
                'title': 'Body Parts',
                'primaryColor': const Color(0xFFF43F5E),
              },
            ),
            'Body',
            'My Body',
            const Color(0xFFF43F5E),
            Icons.accessibility_new_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/clothing',
              extra: {
                'title': 'Clothing',
                'primaryColor': const Color(0xFF8B5CF6),
              },
            ),
            'Clothing',
            'Dress Up',
            const Color(0xFF8B5CF6),
            Icons.checkroom_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/weather',
              extra: {
                'title': 'Weather',
                'primaryColor': const Color(0xFF38BDF8),
              },
            ),
            'Weather',
            'Sun & Rain',
            const Color(0xFF38BDF8),
            Icons.cloud_rounded,
          ),
          _buildCategoryCard(
            context,
            () => context.push(
              '/kids/map/professions',
              extra: {
                'title': 'Professions',
                'primaryColor': const Color(0xFF6366F1),
              },
            ),
            'Professions',
            'When I Grow Up',
            const Color(0xFF6366F1),
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
    IconData icon,
  ) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black45,
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
