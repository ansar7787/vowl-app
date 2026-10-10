class SummarizeStoryFrameSlot {
  final int index;
  final String? sentence;

  const SummarizeStoryFrameSlot({required this.index, this.sentence});

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
