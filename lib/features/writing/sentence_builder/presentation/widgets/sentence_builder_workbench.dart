import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_jigsaw_piece.dart';

class SentenceBuilderWorkbench extends StatelessWidget {
  final List<String> assembledPieces;
  final Color color;
  final bool isDark;
  final ValueChanged<String> onSnap; // FIX: was Function(String)
  final ValueChanged<int> onRemovePiece; // FIX: was Function(int)

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
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 110.h),
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.05 : 0.08),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isHovered
                    ? color
                    : (isDark ? Colors.white10 : Colors.black12),
                width: isHovered ? 2.5 : 2,
              ),
            ),
            child: assembledPieces.isEmpty
                ? _EmptyPlaceholder(color: color, isDark: isDark)
                : Wrap(
                    spacing: -10.w,
                    runSpacing: 8.h,
                    children: assembledPieces.asMap().entries.map((e) {
                      return Semantics(
                        label:
                            '${e.value}, position ${e.key + 1}. Tap to remove.',
                        button: true,
                        child: SentenceBuilderJigsawPiece(
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
              color: isDark ? Colors.white24 : color.withValues(alpha: 0.3),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Drop pieces here',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white30 : color.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
