import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_jigsaw_piece.dart';

class SentenceBuilderPiecePool extends StatelessWidget {
  final List<String> pool;
  final List<String> assembledPieces;
  final Color color;
  final bool isDark;

  /// Called when a piece is tapped or dropped into the workbench.
  /// FIX: new required parameter — wire to screen's _onSnap for tap-to-add.
  final ValueChanged<String> onSnap;

  const SentenceBuilderPiecePool({
    super.key,
    required this.pool,
    required this.assembledPieces,
    required this.color,
    required this.isDark,
    required this.onSnap,
  });

  /// FIX: O(n) implementation replacing the O(n²) filter.
  ///
  /// Previous bug: pool=['the','the','cat'], assembledPieces=['the'] →
  ///   old code returned ['the','the','cat'] (both 'the' shown despite one used).
  ///   new code returns ['the','cat'] (only the remaining copy shown).
  List<String> _computeAvailable() {
    // Step 1 — O(n): count how many of each word are in the workbench.
    final assembledFreq = <String, int>{};
    for (final p in assembledPieces) {
      assembledFreq[p] = (assembledFreq[p] ?? 0) + 1;
    }

    // Step 2 — O(n): walk pool in order; for each slot check if the running
    // seen-count of that word still exceeds the assembled count.
    final seenFreq = <String, int>{};
    final available = <String>[];
    for (final p in pool) {
      seenFreq[p] = (seenFreq[p] ?? 0) + 1;
      if (seenFreq[p]! > (assembledFreq[p] ?? 0)) {
        available.add(p);
      }
    }
    return available;
  }

  @override
  Widget build(BuildContext context) {
    final available = _computeAvailable();

    return Semantics(
      label: 'Word piece pool. ${available.length} pieces available.',
      child: Wrap(
        spacing: 10.w,
        runSpacing: 10.h,
        alignment: WrapAlignment.center,
        children: available.map((p) {
          return Draggable<String>(
            data: p,
            feedback: Material(
              color: Colors.transparent,
              child: SentenceBuilderJigsawPiece(
                text: p,
                isAssembled: false,
                color: color,
                isDark: isDark,
                isDragging: true,
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: SentenceBuilderJigsawPiece(
                text: p,
                isAssembled: false,
                color: color,
                isDark: isDark,
              ),
            ),
            // FIX: onTap wired — tap-to-add now works alongside drag-to-add.
            // Accessibility users and users on devices with imprecise touch
            // can simply tap a piece to place it in the workbench.
            child: SentenceBuilderJigsawPiece(
              text: p,
              isAssembled: false,
              color: color,
              isDark: isDark,
              onTap: () => onSnap(p),
            ),
          );
        }).toList(),
      ),
    );
  }
}
