import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SentenceBuilderKeyboardInput extends StatefulWidget {
  final TextEditingController controller;
  final Color color;
  final bool isDark;

  const SentenceBuilderKeyboardInput({
    super.key,
    required this.controller,
    required this.color,
    required this.isDark,
  });

  @override
  State<SentenceBuilderKeyboardInput> createState() =>
      _SentenceBuilderKeyboardInputState();
}

class _SentenceBuilderKeyboardInputState
    extends State<SentenceBuilderKeyboardInput> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: widget.color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onTap: () {
          if (_focusNode.hasFocus) {
            SystemChannels.textInput.invokeMethod('TextInput.show');
          }
        },
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16.sp,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        maxLines: 3,
        minLines: 1,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Type the complete sentence here...",
          hintStyle: TextStyle(
            fontFamily: 'Outfit',
            color: widget.isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ),
    );
  }
}
