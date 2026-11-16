import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase 이메일/비밀번호 인증 + 사용자 프로필(Firestore `users/{uid}`) 관리
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  Future<void> signUp({
    required String nickname,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(nickname.trim());
      await _db.collection('users').doc(user.uid).set({
        'nickname': nickname.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'agreedToTerms': true,
      });
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  Future<void> signOut() => _auth.signOut();

  static String _messageFor(String code) {
    switch (code) {
      case 'invalid-email':
        return '이메일 형식이 올바르지 않아요.';
      case 'user-disabled':
        return '사용이 중지된 계정이에요.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 맞지 않아요.';
      case 'email-already-in-use':
        return '이미 가입된 이메일이에요.';
      case 'weak-password':
        return '비밀번호는 6자 이상으로 정해 주세요.';
      case 'too-many-requests':
        return '시도가 너무 많아요. 잠시 후 다시 시도해 주세요.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해 주세요.';
      default:
        return '문제가 생겼어요. 다시 시도해 주세요. ($code)';
    }
  }
}

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
