import 'package:vowl/core/theme/app_colors.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/translation/presentation/bloc/translation_bloc.dart';

class LanguageManagerSheet extends StatelessWidget {
  final bool isDark;

  const LanguageManagerSheet({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Center(
              child: Container(
                width: 44.w,
                height: 4.5.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.slate300,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            'translation.downloaded_packs',
                            fallback: 'Downloaded Language Packs',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          context.tr(
                            'translation.manage_packs_desc',
                            fallback:
                                'Manage offline language files. Each pack uses about 30MB.',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: context.tr('common.close', fallback: 'Close'),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20.r),
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate100,
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
                ],
              ),
            ),
            SizedBox(height: 14.h),
          Expanded(
            child: BlocBuilder<TranslationBloc, TranslationState>(
              builder: (context, state) {
                if (state.downloadedLanguages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(18.r),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : AppColors.slate100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.cloud_download_outlined,
                              size: 38.r,
                              color: isDark ? Colors.white38 : AppColors.slate400,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            context.tr(
                              'translation.no_packs_downloaded',
                              fallback: 'No language packs downloaded yet.',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            context.tr(
                              'translation.download_from_selector_hint',
                              fallback:
                                  'Select any language in the translation bar to download it for offline use.',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w400,
                              color: isDark ? Colors.white54 : AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 32.h),
                  physics: const BouncingScrollPhysics(),
                  itemCount: state.downloadedLanguages.length,
                  itemBuilder: (context, index) {
                    final lang = state.downloadedLanguages[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: GlassTile(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: AppColors.emerald500.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.offline_pin_rounded,
                                color: AppColors.emerald500,
                                size: 20.r,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AutoSizeText(
                                    lang,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.slate900,
                                    ),
                                    maxLines: 1,
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    context.tr(
                                      'translation.pack_size_desc',
                                      fallback: 'Offline pack (~30MB)',
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white54 : AppColors.slate400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              constraints: BoxConstraints(minWidth: 48.r, minHeight: 48.r),
                              tooltip: 'Delete $lang pack',
                              onPressed: () {
                                _confirmDelete(context, lang, isDark);
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.red500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  void _confirmDelete(BuildContext context, String lang, bool isDark) {
    di.sl<HapticService>().warning();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Text(
          context.tr(
            'translation.delete_pack_title',
            args: [lang],
            fallback: 'Delete $lang?',
          ),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          context.tr(
            'translation.delete_pack_desc',
            args: [lang],
            fallback:
                'This will free up ~30MB of offline storage space. You can redownload this pack anytime.',
          ),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            color: isDark ? Colors.white70 : AppColors.slate600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              di.sl<HapticService>().light();
              Navigator.pop(ctx);
            },
            child: Text(
              context.tr('common.cancel', fallback: 'CANCEL'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : AppColors.slate500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              di.sl<HapticService>().selection();
              context.read<TranslationBloc>().add(
                TranslationModelDeleted(lang),
              );
              Navigator.pop(ctx);
            },
            child: Text(
              context.tr('common.delete', fallback: 'Delete'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                color: AppColors.red500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
