/// Value object modeling a sequential filmstrip summary slot.
class SummarizeStoryFrameSlot {
  /// The zero-based position index of this frame slot in the filmstrip sequence.
  final int index;

  /// The summary sentence currently assigned to this slot, or null if vacant.
  final String? sentence;

  /// Creates a [SummarizeStoryFrameSlot] instance.
  const SummarizeStoryFrameSlot({required this.index, this.sentence});

  /// Creates a copy of this slot with replaced fields.
  SummarizeStoryFrameSlot copyWith({
    int? index,
    String? sentence,
    bool clearSentence = false,
  }) {
    return SummarizeStoryFrameSlot(
      index: index ?? this.index,
      sentence: clearSentence ? null : (sentence ?? this.sentence),
    );
  }
}
