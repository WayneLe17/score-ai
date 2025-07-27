import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:score_ai_app/features/auth/data/auth_repository.dart';
final authControllerProvider =
    StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
class AuthController extends StateNotifier<bool> {
  final AuthRepository _authRepository;
  AuthController(this._authRepository) : super(false);
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      state = true;
      final result =
          await _authRepository.signInWithEmailAndPassword(email, password);
      state = false;
      return result != null;
    } on FirebaseAuthException catch (e) {
      state = false;
      throw _getAuthErrorMessage(e);
    } catch (e) {
      state = false;
      throw 'An unexpected error occurred. Please try again.';
    }
  }
  Future<bool> signUpWithEmailAndPassword(String email, String password) async {
    try {
      state = true;
      final result =
          await _authRepository.signUpWithEmailAndPassword(email, password);
      state = false;
      return result != null;
    } on FirebaseAuthException catch (e) {
      state = false;
      throw _getAuthErrorMessage(e);
    } catch (e) {
      state = false;
      throw 'An unexpected error occurred. Please try again.';
    }
  }
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      state = true;
      await _authRepository.sendPasswordResetEmail(email);
      state = false;
    } on FirebaseAuthException catch (e) {
      state = false;
      throw _getAuthErrorMessage(e);
    } catch (e) {
      state = false;
      throw 'An unexpected error occurred. Please try again.';
    }
  }
  Future<void> signOut() async {
    await _authRepository.signOut();
  }
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}