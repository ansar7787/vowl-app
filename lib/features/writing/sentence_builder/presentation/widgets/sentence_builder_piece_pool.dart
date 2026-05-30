import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_jigsaw_piece.dart';

class SentenceBuilderPiecePool extends StatelessWidget {
  final List<String> pool;
  final List<String> assembledPieces;
  final Color color;
  final bool isDark;

  const SentenceBuilderPiecePool({
    super.key,
    required this.pool,
    required this.assembledPieces,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final available = pool.where((p) {
      int countInAssembled = assembledPieces.where((a) => a == p).length;
      int countInOriginal = pool.where((o) => o == p).length;
      return countInAssembled < countInOriginal;
    }).toList();

    return Wrap(
      spacing: 10.w, 
      runSpacing: 10.h, 
      alignment: WrapAlignment.center,
      children: available.map((p) => Draggable<String>(
        data: p,
        feedback: Material(
          color: Colors.transparent, 
          child: SentenceBuilderJigsawPiece(
            text: p, 
            isAssembled: false, 
            color: color, 
            isDark: isDark, 
            isDragging: true
          )
        ),
        childWhenDragging: Opacity(
          opacity: 0.3, 
          child: SentenceBuilderJigsawPiece(
            text: p, 
            isAssembled: false, 
            color: color, 
            isDark: isDark
          )
        ),
        child: SentenceBuilderJigsawPiece(
          text: p, 
          isAssembled: false, 
          color: color, 
          isDark: isDark
        ),
      )).toList(),
    );
  }
}
