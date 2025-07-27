import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:score_ai_app/features/auth/data/auth_repository.dart';
import 'package:score_ai_app/features/auth/presentation/login_screen.dart';
import 'package:score_ai_app/features/home/presentation/home_screen.dart';
import 'package:score_ai_app/features/solution/presentation/solution_screen.dart';
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    refreshListenable: AuthStateChangeNotifier(ref),
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/solution/:jobId',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          final filename = state.uri.queryParameters['filename'] ?? 'Solution';
          return SolutionScreen(jobId: jobId, filename: filename);
        },
      ),
    ],
    redirect: (context, state) {
      final user = ref.read(authStateChangesProvider).value;
      final isLoggingIn = state.matchedLocation == '/login';
      if (user == null) {
        return isLoggingIn ? null : '/login';
      }
      if (isLoggingIn) {
        return '/home';
      }
      return null; 
    },
  );
});
class AuthStateChangeNotifier extends ChangeNotifier {
  AuthStateChangeNotifier(this._ref) {
    _ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
      notifyListeners();
    });
  }
  final Ref _ref;
}
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}