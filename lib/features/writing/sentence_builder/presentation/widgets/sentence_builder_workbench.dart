import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_jigsaw_piece.dart';

class SentenceBuilderWorkbench extends StatelessWidget {
  final List<String> assembledPieces;
  final Color color;
  final bool isDark;
  final ValueChanged<String> onSnap;
  final ValueChanged<int> onRemovePiece;

  const SentenceBuilderWorkbench({
    super.key,
    required this.assembledPieces,
    required this.color,
    required this.isDark,
    required this.onSnap,
    required this.onRemovePiece,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: assembledPieces.isEmpty
          ? 'Workbench — drag or tap word pieces here to build your sentence'
          : 'Workbench — assembled sentence: ${assembledPieces.join(' ')}. '
                'Tap a piece to remove it.',
      child: DragTarget<String>(
        onAcceptWithDetails: (details) => onSnap(details.data),
        builder: (context, candidateData, rejectedData) {
          final isHovered = candidateData.isNotEmpty;

          return AnimatedContainer(
            key: const Key('sentence_builder_workbench_target'),
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 110.h),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.05 : 0.08),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isHovered
                    ? color
                    : (isDark ? Colors.white12 : color.withValues(alpha: 0.18)),
                width: isHovered ? 2.0 : 1.5,
              ),
            ),
            child: assembledPieces.isEmpty
                ? _EmptyPlaceholder(color: color, isDark: isDark)
                : Wrap(
                    spacing: -10.w,
                    runSpacing: 10.h,
                    children: assembledPieces.asMap().entries.map((e) {
                      return Semantics(
                        label:
                            '${e.value}, position ${e.key + 1}. Tap to remove.',
                        button: true,
                        child: SentenceBuilderJigsawPiece(
                          key: Key('sentence_builder_assembled_piece_${e.value}_${e.key}'),
                          text: e.value,
                          isAssembled: true,
                          onTap: () => onRemovePiece(e.key),
                          color: color,
                          isDark: isDark,
                        ),
                      );
                    }).toList(),
                  ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state — shown when no pieces have been placed yet
// ---------------------------------------------------------------------------
class _EmptyPlaceholder extends StatelessWidget {
  final Color color;
  final bool isDark;

  const _EmptyPlaceholder({required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.extension_outlined,
              size: 28.r,
              color: isDark ? Colors.white24 : color.withValues(alpha: 0.35),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Drop pieces here',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: isDark ? Colors.white38 : color.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
