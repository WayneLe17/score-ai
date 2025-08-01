import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:score_ai_app/features/chat/data/chat_repository.dart';

final chatControllerProvider = Provider.autoDispose<ChatController>((ref) {
  return ChatController(ref.watch(chatRepositoryProvider));
});

class ChatController {
  final ChatRepository _chatRepository;

  ChatController(this._chatRepository);

  Future<String> getExplanation({
    required String jobId,
    required Map<String, dynamic> question,
    required List<Map<String, dynamic>> chatHistory,
  }) {
    return _chatRepository.getExplanation(
      jobId: jobId,
      question: question,
      chatHistory: chatHistory,
    );
  }
}
