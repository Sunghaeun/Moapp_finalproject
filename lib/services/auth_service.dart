import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 현재 사용자 가져오기
  User? get currentUser => _auth.currentUser;

  // 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 구글 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google 로그인 플로우 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // 사용자가 로그인 취소
        return null;
      }

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase 인증 자격증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 로그인
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google 로그인 오류: $e');
      rethrow;
    }
  }

  // 익명(게스트) 로그인
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('익명 로그인 오류: $e');
      rethrow;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('로그아웃 오류: $e');
      rethrow;
    }
  }

  // 계정 삭제 (익명 계정용)
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
    } catch (e) {
      print('계정 삭제 오류: $e');
      rethrow;
    }
  }
}