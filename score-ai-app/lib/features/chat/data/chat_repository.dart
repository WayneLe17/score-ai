import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:score_ai_app/core/api/dio_client.dart';
import 'package:score_ai_app/features/auth/data/auth_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.watch(dioProvider),
    ref.watch(authRepositoryProvider),
  );
});

class ChatRepository {
  final Dio _dio;
  final AuthRepository _authRepository;

  ChatRepository(this._dio, this._authRepository);

  Stream<String> getExplanationStream({
    required String jobId,
    required Map<String, dynamic> question,
    required List<Map<String, dynamic>> chatHistory,
  }) async* {
    final url = '${_dio.options.baseUrl}/chat/$jobId/explain';
    final token = await _authRepository.currentUser?.getIdToken();
    final client = http.Client();
    final request = http.Request(
      'POST',
      Uri.parse(url),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Content-Type'] = 'application/json; charset=utf-8'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode({
        'question': question,
        'chat_history': chatHistory,
      });

    final response = await client.send(request);

    yield* response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
  }
}
