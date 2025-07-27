import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:score_ai_app/core/api/dio_client.dart';
final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  return JobsRepository(ref.watch(dioProvider));
});
class JobsRepository {
  final Dio _dio;
  JobsRepository(this._dio);
  Future<Map<String, dynamic>> uploadFile({
    File? mobileFile,
    Uint8List? webFileBytes,
    required String fileName,
  }) async {
    try {
      FormData formData;
      if (kIsWeb && webFileBytes != null) {
        String? contentType;
        if (fileName.toLowerCase().endsWith('.jpg') ||
            fileName.toLowerCase().endsWith('.jpeg')) {
          contentType = 'image/jpeg';
        } else if (fileName.toLowerCase().endsWith('.png')) {
          contentType = 'image/png';
        } else if (fileName.toLowerCase().endsWith('.pdf')) {
          contentType = 'application/pdf';
        }
        formData = FormData.fromMap({
          "file": MultipartFile.fromBytes(
            webFileBytes,
            filename: fileName,
            contentType:
                contentType != null ? MediaType.parse(contentType) : null,
          ),
        });
      } else if (!kIsWeb && mobileFile != null) {
        String? contentType;
        if (fileName.toLowerCase().endsWith('.jpg') ||
            fileName.toLowerCase().endsWith('.jpeg')) {
          contentType = 'image/jpeg';
        } else if (fileName.toLowerCase().endsWith('.png')) {
          contentType = 'image/png';
        } else if (fileName.toLowerCase().endsWith('.pdf')) {
          contentType = 'application/pdf';
        }
        formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(
            mobileFile.path,
            filename: fileName,
            contentType:
                contentType != null ? MediaType.parse(contentType) : null,
          ),
        });
      } else {
        throw Exception("Invalid file input for the platform.");
      }
      final response = await _dio.post('/analysis/solve', data: formData);
      return response.data;
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }
  Future<void> deleteJob(String jobId) async {
    try {
      await _dio.delete('/analysis/jobs/$jobId');
    } catch (e) {
      print('Error deleting job $jobId: $e');
      rethrow;
    }
  }
  Future<Map<String, dynamic>> deleteAllJobs() async {
    try {
      final response = await _dio.delete('/analysis/jobs');
      return response.data;
    } catch (e) {
      print('Error deleting all jobs: $e');
      rethrow;
    }
  }
  Future<List<Map<String, dynamic>>> getJobs() async {
    try {
      final response = await _dio.get('/analysis/jobs');
      if (response.data is List) {
        final data = response.data as List;
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        print('Unexpected response format: ${response.data.runtimeType}');
        return <Map<String, dynamic>>[];
      }
    } catch (e) {
      print('Error fetching jobs: $e');
      if (e.toString().contains('timeout') ||
          e.toString().contains('receive timeout')) {
        print(
            'Jobs request timed out - this might indicate too many completed jobs');
        return <Map<String, dynamic>>[];
      }
      return <Map<String, dynamic>>[];
    }
  }
}