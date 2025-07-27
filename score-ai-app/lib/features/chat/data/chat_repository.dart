import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:score_ai_app/core/api/dio_client.dart';
import 'package:score_ai_app/features/auth/data/auth_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.watch(dioProvider),
  );
});

class ChatRepository {
  final Dio _dio;

  ChatRepository(this._dio);

  Future<String> getExplanation({
    required String jobId,
    required Map<String, dynamic> question,
    required List<Map<String, dynamic>> chatHistory,
  }) async {
    final url = '/chat/$jobId/explain';

    final response = await _dio.post(
      url,
      data: {
        'question': question,
        'chat_history': chatHistory,
      },
    );

    if (response.statusCode == 200) {
      return response.data['explanation'];
    } else {
      throw Exception('Failed to get explanation');
    }
  }
}
