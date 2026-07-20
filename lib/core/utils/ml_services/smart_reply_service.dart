import 'package:google_mlkit_smart_reply/google_mlkit_smart_reply.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Service for generating AI smart replies in Roleplay / Dialogue games.
/// 
/// Runs 100% on-device using Google ML Kit Smart Reply.
/// Maintains a short conversation history to provide contextual suggestions.
class SmartReplyService {
  final SmartReply _smartReply;

  SmartReplyService() : _smartReply = SmartReply();

  /// Adds a message to the conversation context.
  /// 
  /// [isLocalUser] should be true if the message was said by the app user,
  /// and false if it was said by the NPC (the app/game character).
  void addMessage(String text, {required bool isLocalUser}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (isLocalUser) {
      _smartReply.addMessageToConversationFromLocalUser(text, timestamp);
    } else {
      _smartReply.addMessageToConversationFromRemoteUser(text, timestamp, 'npc_user');
    }
  }

  /// Gets a list of smart reply suggestions based on the current conversation history.
  /// 
  /// Returns up to 3 suggested responses. If the model cannot confidently suggest
  /// replies, it returns an empty list.
  Future<List<String>> getSuggestions() async {
    try {
      final SmartReplySuggestionResult result = await _smartReply.suggestReplies();
      
      if (result.status == SmartReplySuggestionResultStatus.success) {
        return result.suggestions;
      } else {
        di.sl<AppLogger>().debug('SmartReplyService: No suggestions available (status: ${result.status.name})');
        return [];
      }
    } catch (e) {
      di.sl<AppLogger>().error('SmartReplyService: Failed to get suggestions', error: e);
      return [];
    }
  }

  /// Clears the conversation history. Call this when starting a new Roleplay game.
  void clearConversation() {
    _smartReply.clearConversation();
  }

  /// Releases resources used by the ML model.
  void dispose() {
    _smartReply.close();
  }
}
