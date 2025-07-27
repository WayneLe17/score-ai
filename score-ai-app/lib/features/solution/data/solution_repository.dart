import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:score_ai_app/core/api/dio_client.dart';
final solutionRepositoryProvider = Provider.family<SolutionRepository, String>((ref, jobId) {
  return SolutionRepository(ref.watch(dioProvider), jobId);
});
class SolutionRepository {
  final Dio _dio;
  final String _jobId;
  SolutionRepository(this._dio, this._jobId);
  Future<Map<String, dynamic>> getSolution({String? cursor}) async {
    try {
      final response = await _dio.get(
        '/analysis/solve/$_jobId',
        queryParameters: {
          'page_size': 10,
          if (cursor != null) 'cursor': cursor,
        },
      );
      return response.data;
    } catch (e) {
      print('Error getting solution: $e');
      rethrow;
    }
  }
}