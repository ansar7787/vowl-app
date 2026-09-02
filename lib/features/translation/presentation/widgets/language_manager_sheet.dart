import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/translation/presentation/bloc/translation_bloc.dart';

class LanguageManagerSheet extends StatelessWidget {
  final bool isDark;

  const LanguageManagerSheet({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            context.tr(
              'translation.downloaded_packs',
              fallback: 'Downloaded Language Packs',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              context.tr(
                'translation.manage_packs_desc',
                fallback:
                    'Manage your offline translation models. Each pack uses ~30MB of storage.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: BlocBuilder<TranslationBloc, TranslationState>(
              builder: (context, state) {
                if (state.downloadedLanguages.isEmpty) {
                  return Center(
                    child: Text(
                      context.tr(
                        'translation.no_packs_downloaded',
                        fallback: 'No language packs downloaded yet.',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF94A3B8),
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
                        padding: EdgeInsets.all(16.r),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: const Color(0xFF10B981),
                              size: 20.r,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: AutoSizeText(
                                lang,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                _confirmDelete(context, lang, isDark);
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFEF4444),
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
    );
  }

  void _confirmDelete(BuildContext context, String lang, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          context.tr(
            'translation.delete_pack_title',
            args: [lang],
            fallback: 'Delete $lang?',
          ),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          context.tr(
            'translation.delete_pack_desc',
            args: [lang],
            fallback:
                'This will free up storage space. You will need to redownload this pack to translate to $lang again.',
          ),
          style: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.tr('common.cancel', fallback: 'Cancel'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<TranslationBloc>().add(
                TranslationModelDeleted(lang),
              );
              Navigator.pop(ctx);
            },
            child: Text(
              context.tr('common.delete', fallback: 'Delete'),
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
