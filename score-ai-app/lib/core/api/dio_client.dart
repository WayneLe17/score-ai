import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final dioProvider = Provider<Dio>((ref) {
  final baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'https://api-hprsya2ljq-uc.a.run.app/';
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 2),
    sendTimeout: const Duration(seconds: 30),
  ));
  dio.interceptors.add(AuthInterceptor());
  dio.interceptors.add(RetryInterceptor());
  return dio;
});

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final idToken = await user.getIdToken(true);
        print('ID Token: $idToken');
        options.headers['Authorization'] = 'Bearer $idToken';
      } catch (e) {
        print('Error getting ID token: $e');
      }
    }
    super.onRequest(options, handler);
  }
}

class RetryInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.type == DioExceptionType.receiveTimeout &&
        err.requestOptions.path.contains('/analysis/jobs') &&
        (err.requestOptions.extra['retryCount'] ?? 0) < 2) {
      err.requestOptions.extra['retryCount'] =
          (err.requestOptions.extra['retryCount'] ?? 0) + 1;
      err.requestOptions.receiveTimeout = const Duration(minutes: 3);
      try {
        final response = await Dio().fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {}
    }
    super.onError(err, handler);
  }
}
