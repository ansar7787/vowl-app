import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_jigsaw_piece.dart';

class SentenceBuilderWorkbench extends StatelessWidget {
  final List<String> assembledPieces;
  final Color color;
  final bool isDark;
  final Function(String) onSnap;
  final Function(int) onRemovePiece;

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
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onSnap(details.data),
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 110.h),
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.05 : 0.08),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: candidateData.isNotEmpty 
                  ? color 
                  : (isDark ? Colors.white10 : Colors.black12), 
              width: 2
            ),
          ),
          child: Wrap(
            spacing: 8.w, runSpacing: 8.h,
            children: assembledPieces.asMap().entries.map((e) => 
              SentenceBuilderJigsawPiece(
                text: e.value, 
                isAssembled: true, 
                onTap: () => onRemovePiece(e.key), 
                color: color, 
                isDark: isDark
              )
            ).toList(),
          ),
        );
      },
    );
  }
}
