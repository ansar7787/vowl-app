import 'package:vowl/core/theme/app_colors.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/locale_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = info.version;
    });
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.slate900 : AppColors.slate50;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          const MeshGradientBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    40.h,
                    20.w,
                    MediaQuery.of(context).padding.bottom + 32.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.indigo500.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          size: 50.w,
                          color: AppColors.indigo500,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'Vowl',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'English Language Learning App',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Version $_appVersion',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          color: isDark ? Colors.white54 : Colors.black38,
                        ),
                      ),
                      SizedBox(height: 40.h),
                      _buildInfoTile(
                        context,
                        title: 'Developer',
                        subtitle: 'Ansar',
                        icon: Icons.person_rounded,
                        isDark: isDark,
                      ),
                      SizedBox(height: 16.h),
                      _buildInfoTile(
                        context,
                        title: 'Contact',
                        subtitle: 'support.vowl.app@gmail.com',
                        icon: Icons.email_rounded,
                        isDark: isDark,
                        onTap: () =>
                            _launchUrl('mailto:support.vowl.app@gmail.com'),
                      ),
                      SizedBox(height: 40.h),
                      _buildActionBtn(
                        context,
                        title: 'View Open Source Licenses',
                        icon: Icons.assignment_rounded,
                        isDark: isDark,
                        onTap: () {
                          showLicensePage(
                            context: context,
                            applicationName: 'Vowl',
                            applicationVersion: _appVersion,
                            applicationIcon: Icon(
                              Icons.school_rounded,
                              size: 50.w,
                              color: AppColors.indigo500,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16.h),
                      _buildActionBtn(
                        context,
                        title: 'Privacy Policy',
                        icon: Icons.policy_rounded,
                        isDark: isDark,
                        onTap: () => _launchUrl(
                          'https://ansar7787.github.io/vowl-legal/privacy.html',
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _buildActionBtn(
                        context,
                        title: 'Terms of Service',
                        icon: Icons.description_rounded,
                        isDark: isDark,
                        onTap: () => _launchUrl(
                          'https://ansar7787.github.io/vowl-legal/terms.html',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: (isDark ? AppColors.slate900 : AppColors.slate50).withValues(
              alpha: 0.7,
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16.r,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        onPressed: () => context.pop(),
      ),
      title: Text(
        context.tr('settings.about', fallback: 'About'),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 22.sp,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.indigo500, size: 20.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.slate500, size: 22.w),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white54 : Colors.black38,
              size: 24.w,
            ),
          ],
        ),
      ),
    );
  }
}
